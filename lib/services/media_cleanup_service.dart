import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';
import '../utils/app_logger.dart';
import '../utils/path_utils.dart';

/// Service for cleaning up unused media files in the app's storage.
///
/// This service identifies media files that are no longer referenced by any
/// music pieces and removes them to free up storage space.
class MediaCleanupService {
  final MusicPieceRepository _repository;

  MediaCleanupService(this._repository);

  /// Gets the app's media directory path
  Future<String> get _mediaDirectoryPath async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'media');
  }

  /// Scans for unused media files and returns information about them
  Future<MediaCleanupInfo> scanForUnusedMedia() async {
    AppLogger.log('Starting media cleanup scan...');
    
    final mediaDir = await _mediaDirectoryPath;
    final mediaDirectory = Directory(mediaDir);
    
    if (!await mediaDirectory.exists()) {
      AppLogger.log('Media directory does not exist, nothing to clean.');
      return MediaCleanupInfo(
        totalFilesFound: 0,
        unusedFilesFound: 0,
        totalSizeBytes: 0,
        unusedSizeBytes: 0,
        unusedFiles: [],
      );
    }

    // Get all music pieces to find referenced media files
    final musicPieces = await _repository.getMusicPieces();
    final Map<String, MusicPiece> pieceIdToPiece = { for (var p in musicPieces) p.id: p };

    // Collect all referenced media file paths
    // On Windows, paths are case-insensitive, so we normalize to lowercase for comparisons.
    final bool isWindows = Platform.isWindows;
    final Set<String> referencedFiles = <String>{};
    
    // Collect all referenced media file paths
    for (final piece in musicPieces) {
      for (final mediaItem in piece.mediaItems) {
        if (mediaItem.pathOrUrl.isNotEmpty) {
          final absolutePath = getAbsolutePath(mediaItem.pathOrUrl, mediaDir);
          if (await File(absolutePath).exists()) {
            final normalized = p.normalize(absolutePath);
            referencedFiles.add(isWindows ? normalized.toLowerCase() : normalized);
          }
        }
        // Also check thumbnail paths
        if (mediaItem.thumbnailPath != null &&
            mediaItem.thumbnailPath!.isNotEmpty) {
            final absolutePath = getAbsolutePath(mediaItem.thumbnailPath!, mediaDir);
            if (await File(absolutePath).exists()) {
              final normalized = p.normalize(absolutePath);
              referencedFiles.add(isWindows ? normalized.toLowerCase() : normalized);
            }
        }
      }
      // Check piece thumbnail
      if (piece.thumbnailPath != null &&
          piece.thumbnailPath!.isNotEmpty) {
          final absolutePath = getAbsolutePath(piece.thumbnailPath!, mediaDir);
          if (await File(absolutePath).exists()) {
            final normalized = p.normalize(absolutePath);
            referencedFiles.add(isWindows ? normalized.toLowerCase() : normalized);
          }
      }
    }

    AppLogger.log('Found ${referencedFiles.length} referenced media files');

    // Scan all files in media directory
    final List<File> allFiles = [];
    final List<UnusedFileInfo> unusedFiles = [];
    int totalSize = 0;
    int unusedSize = 0;

    await _scanDirectoryRecursively(mediaDirectory, allFiles);

    for (final file in allFiles) {
      final fileSize = await file.length();
      totalSize += fileSize;
      
      final normalizedFilePath = p.normalize(file.path);
      final checkPath = isWindows ? normalizedFilePath.toLowerCase() : normalizedFilePath;
      
      if (!referencedFiles.contains(checkPath)) {
        // Attempt to identify the piece by walking up the directory structure
        // Expected structure: .../media/<pieceId>/<optional_type>/<filename>
        String pieceName = 'Unknown Piece';
        String fileType = 'Unknown Type';
        
        try {
          final mediaDir = await _mediaDirectoryPath;
          final relativeToMedia = p.relative(normalizedFilePath, from: mediaDir);
          final pathParts = p.split(relativeToMedia);
          
          if (pathParts.isNotEmpty) {
            final pieceId = pathParts[0];
            final piece = pieceIdToPiece[pieceId];
            if (piece != null) {
              pieceName = piece.title;
            } else if (pieceId != 'thumbnails' && pieceId.length > 20) {
              // Looks like a UUID but not found in DB
              pieceName = 'Stray Piece (ID: ${pieceId.substring(0, 8)}...)';
            }
            
            if (pathParts.length > 1) {
              fileType = pathParts[pathParts.length - 2];
            }
          }
        } catch (e) {
          AppLogger.log('Error identifying piece for file ${file.path}: $e');
        }

        unusedFiles.add(UnusedFileInfo(
          pieceName: pieceName,
          fileType: fileType,
          filePath: normalizedFilePath,
        ));
        unusedSize += fileSize;
      }
    }

    final cleanupInfo = MediaCleanupInfo(
      totalFilesFound: allFiles.length,
      unusedFilesFound: unusedFiles.length,
      totalSizeBytes: totalSize,
      unusedSizeBytes: unusedSize,
      unusedFiles: unusedFiles,
    );

    AppLogger.log('Media cleanup scan completed:');
    AppLogger.log('  Total files: ${cleanupInfo.totalFilesFound}');
    AppLogger.log('  Unused files: ${cleanupInfo.unusedFilesFound}');
    AppLogger.log('  Total size: ${cleanupInfo.totalSizeFormatted}');
    AppLogger.log('  Unused size: ${cleanupInfo.unusedSizeFormatted}');

    return cleanupInfo;
  }

  /// Performs the actual cleanup by deleting unused media files.
  /// 
  /// An optional [MediaCleanupInfo] can be provided to avoid re-scanning,
  /// which helps prevent race conditions if files are modified between scan and purge.
  Future<MediaCleanupResult> performCleanup({MediaCleanupInfo? cleanupInfo}) async {
    AppLogger.log('Starting media cleanup...');
    
    // Always re-scan to get the most up-to-date state and avoid 'file not found' errors
    // if files were moved or deleted since the last scan.
    final info = await scanForUnusedMedia();
    
    if (info.unusedFiles.isEmpty) {
      AppLogger.log('No unused files to clean up.');
      return MediaCleanupResult(
        filesDeleted: 0,
        bytesFreed: 0,
        success: true,
        message: 'No unused files found to clean up.',
      );
    }

    int deletedCount = 0;
    int freedBytes = 0;
    List<String> errors = [];

    for (final unusedFileInfo in info.unusedFiles) {
      final normalizedPath = p.normalize(unusedFileInfo.filePath);
      final file = File(normalizedPath);
      
      try {
        if (await file.exists()) {
          int fileSize = 0;
          try {
            fileSize = await file.length();
          } catch (e) {
            AppLogger.log('Could not get size for file before deletion: $normalizedPath - $e');
          }

          try {
            await file.delete();
            deletedCount++;
            freedBytes += fileSize;
            AppLogger.log('Deleted unused file: $normalizedPath');
          } catch (e) {
            AppLogger.log('Failed to delete file $normalizedPath: $e');
            errors.add('Failed to delete ${p.basename(normalizedPath)}: $e');
          }
        } else {
          AppLogger.log('File disappeared before deletion: $normalizedPath');
          // Not adding to errors as it's technically gone now.
        }
      } catch (e) {
        AppLogger.log('Unexpected error processing file $normalizedPath: $e');
        errors.add('Error processing ${p.basename(normalizedPath)}: $e');
      }
    }

    // Clean up empty directories
    await _cleanupEmptyDirectories();

    final result = MediaCleanupResult(
      filesDeleted: deletedCount,
      bytesFreed: freedBytes,
      success: errors.isEmpty,
      message: errors.isEmpty 
        ? 'Successfully deleted $deletedCount unused files (${_formatBytes(freedBytes)} freed).'
        : 'Deleted $deletedCount files but encountered ${errors.length} errors.',
      errors: errors,
    );

    AppLogger.log('Media cleanup completed: ${result.message}');
    return result;
  }

  /// Recursively scans a directory for all files
  Future<void> _scanDirectoryRecursively(Directory directory, List<File> files) async {
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          files.add(entity);
        } else if (entity is Directory) {
          await _scanDirectoryRecursively(entity, files);
        }
      }
    } catch (e) {
      AppLogger.log('Error scanning directory ${directory.path}: $e');
    }
  }


  /// Removes empty directories after file cleanup
  Future<void> _cleanupEmptyDirectories() async {
    final mediaDir = await _mediaDirectoryPath;
    final mediaDirectory = Directory(mediaDir);
    
    if (!await mediaDirectory.exists()) return;

    try {
      await _removeEmptyDirectoriesRecursively(mediaDirectory);
    } catch (e) {
      AppLogger.log('Error cleaning up empty directories: $e');
    }
  }

  /// Recursively removes empty directories
  Future<void> _removeEmptyDirectoriesRecursively(Directory directory) async {
    try {
      final entities = await directory.list().toList();
      
      // First, recursively clean up subdirectories
      for (final entity in entities) {
        if (entity is Directory) {
          await _removeEmptyDirectoriesRecursively(entity);
        }
      }
      
      // Then check if this directory is now empty
      final remainingEntities = await directory.list().toList();
      if (remainingEntities.isEmpty) {
        await directory.delete();
        AppLogger.log('Removed empty directory: ${directory.path}');
      }
    } catch (e) {
      AppLogger.log('Error processing directory ${directory.path}: $e');
    }
  }

  /// Formats bytes into human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class UnusedFileInfo {
  final String pieceName;
  final String fileType;
  final String filePath;

  UnusedFileInfo({
    required this.pieceName,
    required this.fileType,
    required this.filePath,
  });
}

/// Information about media files that can be cleaned up
class MediaCleanupInfo {
  final int totalFilesFound;
  final int unusedFilesFound;
  final int totalSizeBytes;
  final int unusedSizeBytes;
  final List<UnusedFileInfo> unusedFiles;

  MediaCleanupInfo({
    required this.totalFilesFound,
    required this.unusedFilesFound,
    required this.totalSizeBytes,
    required this.unusedSizeBytes,
    required this.unusedFiles,
  });

  String get totalSizeFormatted => _formatBytes(totalSizeBytes);
  String get unusedSizeFormatted => _formatBytes(unusedSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of a media cleanup operation
class MediaCleanupResult {
  final int filesDeleted;
  final int bytesFreed;
  final bool success;
  final String message;
  final List<String> errors;

  MediaCleanupResult({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.success,
    required this.message,
    this.errors = const [],
  });

  String get freedSizeFormatted => _formatBytes(bytesFreed);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 