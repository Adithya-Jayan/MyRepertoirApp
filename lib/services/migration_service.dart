import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/music_piece_repository.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../utils/app_logger.dart';

class MigrationService {
  final MusicPieceRepository _repository;
  final SharedPreferences _prefs;

  MigrationService(this._repository, this._prefs);

  static const String _migrationKeyThumbnailWidgets = 'migration_thumbnail_widgets_created';

  /// Runs all pending data migrations.
  Future<void> runMigrations() async {
    AppLogger.log('MigrationService: Checking for pending migrations...');
    
    await _migrateThumbnailWidgets();
    
    AppLogger.log('MigrationService: All checks completed.');
  }

  /// Ensures that any MusicPiece with a thumbnailPath has a corresponding MediaType.thumbnails widget.
  Future<void> _migrateThumbnailWidgets() async {
    // Check if this migration has already run
    final hasRun = _prefs.getBool(_migrationKeyThumbnailWidgets) ?? false;
    if (hasRun) {
      AppLogger.log('MigrationService: Thumbnail widgets migration already applied. Skipping.');
      return;
    }

    AppLogger.log('MigrationService: Running thumbnail widgets migration...');
    try {
      final allPieces = await _repository.getMusicPieces();
      int updatedCount = 0;
      
      // Get app directory for file operations
      final appDir = await getApplicationDocumentsDirectory();

      for (final piece in allPieces) {
        if (piece.thumbnailPath != null && piece.thumbnailPath!.isNotEmpty) {
          final thumbnailPath = piece.thumbnailPath!;
          
          // Check if a corresponding MediaType.thumbnails widget exists
          int thumbnailWidgetIndex = piece.mediaItems.indexWhere((item) => 
            item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath
          );
          
          bool needsMigration = false;
          
          if (thumbnailWidgetIndex == -1) {
            // No thumbnail widget exists at all
            needsMigration = true;
          } else {
            // Widget exists, but check if it shares a path with another item (e.g. the original image or a media link's thumbnail)
            // This indicates it's not a dedicated file and needs to be split
            final isShared = piece.mediaItems.any((item) {
              // Skip the thumbnail widget itself when checking for sharing
              if (item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath) {
                return false;
              }
              
              // Check if the path is used as a primary path (images) or a secondary thumbnail path (media links)
              return item.pathOrUrl == thumbnailPath || item.thumbnailPath == thumbnailPath;
            });
            
            if (isShared) {
               AppLogger.log('MigrationService: Found shared thumbnail widget for piece: ${piece.title}. Migrating to dedicated file.');
               needsMigration = true;
            }
          }

          if (needsMigration) {
            if (thumbnailWidgetIndex == -1) {
               AppLogger.log('MigrationService: Creating missing thumbnail widget for piece: ${piece.title}');
            }
            
            // Logic to copy the file, mimicking MediaSectionWidget.handleSetThumbnail
            String finalThumbnailPath = thumbnailPath;
            
            try {
              final pieceMediaDir = Directory(p.join(appDir.path, 'media', piece.id));
              if (!await pieceMediaDir.exists()) {
                await pieceMediaDir.create(recursive: true);
              }

              // Handle potential URL encoding in legacy paths (e.g. %20 for spaces)
              String sourcePath = thumbnailPath;
              File sourceFile = File(sourcePath);
              
              if (!await sourceFile.exists()) {
                final decodedPath = Uri.decodeFull(thumbnailPath);
                if (decodedPath != thumbnailPath) {
                  final decodedFile = File(decodedPath);
                  if (await decodedFile.exists()) {
                    AppLogger.log('MigrationService: Found source file after decoding path: $decodedPath');
                    sourcePath = decodedPath;
                    sourceFile = decodedFile;
                  }
                }
              }

              if (await sourceFile.exists()) {
                final extension = p.extension(sourcePath); // Use sourcePath for extension to avoid %20
                final newFileName = 'thumbnail_${const Uuid().v4()}$extension';
                final newFilePath = p.join(pieceMediaDir.path, newFileName);
                
                await sourceFile.copy(newFilePath);
                finalThumbnailPath = newFilePath;
                AppLogger.log('MigrationService: Copied thumbnail to $newFilePath');
              } else {
                 AppLogger.log('MigrationService: Source thumbnail file not found: $thumbnailPath (checked decoded: $sourcePath). Using existing path.');
              }
            } catch (e) {
               AppLogger.log('MigrationService: Error copying thumbnail file: $e. Using existing path.');
            }

            // Create updated list of media items
            final updatedMediaItems = List<MediaItem>.from(piece.mediaItems);

            if (thumbnailWidgetIndex != -1) {
                // Update existing shared widget to point to new dedicated file
                final oldItem = updatedMediaItems[thumbnailWidgetIndex];
                updatedMediaItems[thumbnailWidgetIndex] = oldItem.copyWith(pathOrUrl: finalThumbnailPath);
            } else {
                // Create new widget
                final newThumbnailItem = MediaItem(
                  id: const Uuid().v4(),
                  type: MediaType.thumbnails,
                  pathOrUrl: finalThumbnailPath,
                );
                updatedMediaItems.add(newThumbnailItem);
            }

            // Update the piece - also update the piece's thumbnailPath to the new copied file
            // so that if the original is deleted, the piece still has its thumbnail.
            final updatedPiece = piece.copyWith(
              mediaItems: updatedMediaItems,
              thumbnailPath: finalThumbnailPath
            );
            
            await _repository.updateMusicPiece(updatedPiece);
            updatedCount++;
          }
        }
      }

      // Mark migration as done
      await _prefs.setBool(_migrationKeyThumbnailWidgets, true);
      AppLogger.log('MigrationService: Thumbnail widgets migration completed. Updated $updatedCount pieces.');
      
    } catch (e) {
      AppLogger.log('MigrationService: Error running thumbnail widgets migration: $e');
      // Do not mark as done so it retries next time
    }
  }
}
