import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:uuid/uuid.dart'; // Added import
import '../../utils/app_logger.dart';

import '../../database/music_piece_repository.dart';
import '../../models/music_piece.dart';
import '../../models/tag.dart';
import '../../models/group.dart';
import '../../models/practice_log.dart';
import '../../models/media_item.dart';
import '../../models/media_type.dart';

class RestoreManager {
  final MusicPieceRepository _repository;
  final SharedPreferences prefs;

  RestoreManager(this._repository, this.prefs);

  /// Shows restore messages to the user
  void _showRestoreMessage(ScaffoldMessengerState? messenger, bool success, String message) {
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
    }
  }

  /// Extracts data from backup file
  Future<Map<String, dynamic>?> _extractBackupData(String backupFilePath) async {
    try {
      AppLogger.log('RestoreManager: Starting backup data extraction from: $backupFilePath');
      final inputStream = InputFileStream(backupFilePath);
      final archive = ZipDecoder().decodeBytes(inputStream.toUint8List());
      AppLogger.log('RestoreManager: Backup file decoded successfully. Archive contains ${archive.files.length} files');

      final jsonFile = archive.findFile('music_repertoire.json');
      if (jsonFile == null) {
        AppLogger.log('RestoreManager: ERROR - music_repertoire.json not found in backup');
        throw Exception('Invalid backup file: music_repertoire.json not found.');
      }

      final jsonString = utf8.decode(jsonFile.content);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      AppLogger.log('RestoreManager: JSON data extracted successfully. Keys: ${data.keys.join(', ')}');
      
      return data;
    } catch (e) {
      AppLogger.log('RestoreManager: Error extracting backup data: $e');
      rethrow;
    }
  }

  /// Restores music pieces from backup data with merge logic
  Future<void> _restoreMusicPieces(List<dynamic> musicPiecesJson, String storagePath, int? backupVersion) async {
    AppLogger.log('RestoreManager: Starting music pieces restore with merge logic. Count: ${musicPiecesJson.length}');
    
    // Get existing pieces for comparison
    final existingPieces = await _repository.getMusicPieces();
    final existingPieceIds = existingPieces.map((p) => p.id).toSet();
    AppLogger.log('RestoreManager: Found ${existingPieces.length} existing pieces');
    
    int insertedCount = 0;
    int updatedCount = 0;
    
    final appDir = await getApplicationDocumentsDirectory();
    final internalStoragePath = appDir.path;
    
    for (int i = 0; i < musicPiecesJson.length; i++) {
      final pieceJson = musicPiecesJson[i];
      try {
        final piece = backupVersion == 2
            ? MusicPiece.fromJsonForBackup(pieceJson, internalStoragePath)
            : MusicPiece.fromJson(pieceJson);

        AppLogger.log('RestoreManager: Processing piece ${i + 1}/${musicPiecesJson.length}: ${piece.title} (ID: ${piece.id})');
        
        if (existingPieceIds.contains(piece.id)) {
          // Piece exists - update it
          AppLogger.log('RestoreManager: Updating existing piece: ${piece.title}');
          await _repository.updateMusicPiece(piece);
          updatedCount++;
        } else {
          // Piece doesn't exist - insert it
          AppLogger.log('RestoreManager: Inserting new piece: ${piece.title}');
          await _repository.insertMusicPiece(piece);
          insertedCount++;
        }
      } catch (e) {
        AppLogger.log('RestoreManager: Error processing piece ${i + 1}: $e');
        rethrow;
      }
    }
    
    AppLogger.log('RestoreManager: Music pieces restore completed. Inserted: $insertedCount, Updated: $updatedCount');
  }

  

  /// Restores tags from backup data
  Future<void> _restoreTags(List<dynamic> tagsJson) async {
    AppLogger.log('RestoreManager: Starting tags restore. Count: ${tagsJson.length}');
    
    await _repository.deleteAllTags();
    AppLogger.log('RestoreManager: Deleted all existing tags');
    
    for (int i = 0; i < tagsJson.length; i++) {
      final tagJson = tagsJson[i];
      try {
        final tag = Tag.fromJson(tagJson);
        AppLogger.log('RestoreManager: Restoring tag ${i + 1}/${tagsJson.length}: ${tag.name} (ID: ${tag.id})');
        await _repository.insertTag(tag);
      } catch (e) {
        AppLogger.log('RestoreManager: Error restoring tag ${i + 1}: $e');
        rethrow;
      }
    }
    AppLogger.log('RestoreManager: Successfully restored ${tagsJson.length} tags');
  }

  /// Restores groups from backup data
  Future<void> _restoreGroups(List<dynamic> groupsJson) async {
    AppLogger.log('RestoreManager: Starting groups restore. Count: ${groupsJson.length}');
    
    final List<Group> oldGroupsBeforeRestore = await _repository.getGroups();
    AppLogger.log('RestoreManager: Found ${oldGroupsBeforeRestore.length} existing groups before restore');

    await _repository.deleteAllGroups();
    AppLogger.log('RestoreManager: Deleted all existing groups');
    
    // Restore groups from backup
    for (int i = 0; i < groupsJson.length; i++) {
      final groupJson = groupsJson[i];
      try {
        final group = Group.fromJson(groupJson);
        AppLogger.log('RestoreManager: Restoring group ${i + 1}/${groupsJson.length}: ${group.name} (ID: ${group.id})');
        await _repository.createGroup(group);
      } catch (e) {
        AppLogger.log('RestoreManager: Error restoring group ${i + 1}: $e');
        rethrow;
      }
    }
    AppLogger.log('RestoreManager: Successfully restored ${groupsJson.length} groups from backup');

    // Get current groups after restore
    final List<Group> currentGroupsAfterRestore = await _repository.getGroups();
    final Set<String> currentGroupIds = currentGroupsAfterRestore.map((g) => g.id).toSet();
    AppLogger.log('RestoreManager: Current groups after restore: ${currentGroupsAfterRestore.length}');

    // Re-add old groups that weren't in the backup
    int nextOrder = currentGroupsAfterRestore.length;
    int reAddedCount = 0;

    for (final oldGroup in oldGroupsBeforeRestore) {
      if (!currentGroupIds.contains(oldGroup.id)) {
        final newOrder = nextOrder++;
        final groupToReAdd = oldGroup.copyWith(order: newOrder);
        try {
          await _repository.createGroup(groupToReAdd);
          AppLogger.log('RestoreManager: Re-added old group: ${groupToReAdd.name} (ID: ${groupToReAdd.id}, new order: $newOrder)');
          reAddedCount++;
        } catch (e) {
          AppLogger.log('RestoreManager: Error re-adding old group ${oldGroup.name}: $e');
        }
      }
    }
    AppLogger.log('RestoreManager: Finished re-adding old groups. Re-added: $reAddedCount');
  }

  /// Updates media file paths in music pieces to reflect the new storage location.
  /// This function is backwards-compatible and handles older backup versions.
  Future<void> _updateMediaFilePaths(String storagePath) async {
    AppLogger.log(
        'RestoreManager: Starting media file path updates for storage path: $storagePath');

    final appDir = await getApplicationDocumentsDirectory();
    final allPieces = await _repository.getMusicPieces();
    int updatedPieces = 0;

    for (final piece in allPieces) {
      bool pieceUpdated = false;
      final updatedMediaItems = <MediaItem>[];

      for (final mediaItem in piece.mediaItems) {
        MediaItem updatedItem = mediaItem;

        // Only update paths for local files (not media links or markdown)
        if (mediaItem.type != MediaType.mediaLink &&
            mediaItem.type != MediaType.markdown &&
            mediaItem.type != MediaType.learningProgress &&
            mediaItem.pathOrUrl.isNotEmpty) {
          final oldPath = mediaItem.pathOrUrl;
          final newPath = _getCorrectedPath(oldPath, appDir.path);

          if (oldPath != newPath) {
            AppLogger.log(
                'RestoreManager: Updating media path for piece [33m${piece.title} [0m:');
            AppLogger.log('  Old path: $oldPath');
            AppLogger.log('  New path: $newPath');

            updatedItem = mediaItem.copyWith(pathOrUrl: newPath);
            pieceUpdated = true;
          }
        }
        // Update thumbnailPath for the media item if present and local
        if (mediaItem.thumbnailPath != null &&
            mediaItem.thumbnailPath!.isNotEmpty) {
          final oldThumbPath = mediaItem.thumbnailPath!;
          final newThumbPath = _getCorrectedPath(oldThumbPath, appDir.path);

          if (oldThumbPath != newThumbPath) {
            AppLogger.log(
                'RestoreManager: Updating media thumbnail path for piece [33m${piece.title} [0m:');
            AppLogger.log('  Old thumbnail path: $oldThumbPath');
            AppLogger.log('  New thumbnail path: $newThumbPath');
            updatedItem = updatedItem.copyWith(thumbnailPath: newThumbPath);
            pieceUpdated = true;
          }
        }

        updatedMediaItems.add(updatedItem);
      }

      // Update the piece's own thumbnailPath if present and local
      String? updatedPieceThumb = piece.thumbnailPath;
      if (piece.thumbnailPath != null && piece.thumbnailPath!.isNotEmpty) {
        final oldPieceThumbPath = piece.thumbnailPath!;
        final newPieceThumbPath =
            _getCorrectedPath(oldPieceThumbPath, appDir.path);

        if (oldPieceThumbPath != newPieceThumbPath) {
          AppLogger.log(
              'RestoreManager: Updating piece thumbnail path for piece [33m${piece.title} [0m:');
          AppLogger.log('  Old piece thumbnail path: $oldPieceThumbPath');
          AppLogger.log('  New piece thumbnail path: $newPieceThumbPath');
          updatedPieceThumb = newPieceThumbPath;
          pieceUpdated = true;
        }

        // Backward compatibility: Ensure a MediaType.thumbnails widget exists
        final hasThumbnailWidget = updatedMediaItems.any((item) => 
            item.type == MediaType.thumbnails && item.pathOrUrl == updatedPieceThumb
        );

        if (!hasThumbnailWidget && updatedPieceThumb != null) {
          AppLogger.log('RestoreManager: Creating missing thumbnail widget for piece ${piece.title}');
          
          // Logic to copy the file to create a dedicated thumbnail source
          String finalThumbnailPath = updatedPieceThumb;
          
          try {
            final pieceMediaDir = Directory(p.join(appDir.path, 'media', piece.id));
            if (!await pieceMediaDir.exists()) {
              await pieceMediaDir.create(recursive: true);
            }

            final sourceFile = File(updatedPieceThumb);
            if (await sourceFile.exists()) {
              final extension = p.extension(updatedPieceThumb);
              final newFileName = 'thumbnail_${const Uuid().v4()}$extension';
              final newFilePath = p.join(pieceMediaDir.path, newFileName);
              
              await sourceFile.copy(newFilePath);
              finalThumbnailPath = newFilePath;
              AppLogger.log('RestoreManager: Copied thumbnail to $newFilePath');
            } else {
               AppLogger.log('RestoreManager: Source thumbnail file not found: $updatedPieceThumb. Using existing path.');
            }
          } catch (e) {
             AppLogger.log('RestoreManager: Error copying thumbnail file: $e. Using existing path.');
          }

          updatedMediaItems.add(MediaItem(
            id: const Uuid().v4(),
            type: MediaType.thumbnails,
            pathOrUrl: finalThumbnailPath,
          ));
          
          // Update the piece thumbnail to point to the new dedicated file
          updatedPieceThumb = finalThumbnailPath;
          
          pieceUpdated = true;
        }
      }
      if (pieceUpdated) {
        final updatedPiece = piece.copyWith(
            mediaItems: updatedMediaItems, thumbnailPath: updatedPieceThumb);
        await _repository.updateMusicPiece(updatedPiece);
        updatedPieces++;
        AppLogger.log(
            'RestoreManager: Updated media and thumbnail paths for piece: ${piece.title}');
      }
    }

    AppLogger.log(
        'RestoreManager: Media file path updates completed. Updated pieces: $updatedPieces');
  }

  String _getCorrectedPath(String oldPath, String appDirPath) {
    // Normalize paths to handle mixed separators
    final normalizedOldPath = p.normalize(oldPath);
    final pathParts = normalizedOldPath.split(p.separator);

    // Find the 'media' directory, which is the root for all app media
    final mediaIndex = pathParts.lastIndexOf('media');

    if (mediaIndex != -1) {
      // The relative path starts from the 'media' directory
      final relativePath = pathParts.sublist(mediaIndex).join(p.separator);
      return p.join(appDirPath, relativePath);
    } else {
      // If 'media' is not found, this might be a very old backup format
      // or an invalid path. We'll try to extract the filename and join it
      // with the new path. This is a fallback.
      final fileName = p.basename(normalizedOldPath);
      AppLogger.log(
          'RestoreManager: "media" directory not found in path: $oldPath. Using fallback to filename: $fileName');
      // This is a guess, as we don't know the pieceId or media type.
      // The file might not be found, but it's better than crashing.
      return p.join(appDirPath, 'media',
          'unknown_piece', 'unknown_type', fileName);
    }
  }

  /// Restores practice logs from backup data
  Future<void> _restorePracticeLogs(List<dynamic> practiceLogsJson) async {
    AppLogger.log('RestoreManager: Starting practice logs restore. Count: ${practiceLogsJson.length}');
    
    await _repository.deleteAllPracticeLogs();
    AppLogger.log('RestoreManager: Deleted all existing practice logs');
    
    for (int i = 0; i < practiceLogsJson.length; i++) {
      final logJson = practiceLogsJson[i];
      try {
        final log = PracticeLog.fromJson(logJson);
        AppLogger.log('RestoreManager: Restoring practice log ${i + 1}/${practiceLogsJson.length}: ${log.musicPieceId} - ${log.timestamp}');
        await _repository.insertPracticeLog(log);
      } catch (e) {
        AppLogger.log('RestoreManager: Error restoring practice log ${i + 1}: $e');
        rethrow;
      }
    }
    AppLogger.log('RestoreManager: Successfully restored ${practiceLogsJson.length} practice logs from backup');
  }

  /// Recalculates practice tracking data for all music pieces after restore
  Future<void> _recalculatePracticeTracking() async {
    AppLogger.log('RestoreManager: Starting practice tracking recalculation');
    
    final allPieces = await _repository.getMusicPieces();
    int updatedPieces = 0;
    
    for (final piece in allPieces) {
      try {
        final practiceLogs = await _repository.getPracticeLogsForPiece(piece.id);
        AppLogger.log('RestoreManager: Piece ${piece.title} has ${practiceLogs.length} practice logs');
        
        if (practiceLogs.isEmpty) {
          // No practice logs, reset practice tracking
          final updatedPiece = piece.copyWithExplicit(
            lastPracticeTime: null,
            practiceCount: 0,
          );
          await _repository.updateMusicPiece(updatedPiece);
          AppLogger.log('RestoreManager: Reset practice tracking for piece ${piece.title}');
        } else {
          // Calculate new practice count and last practice time
          final practiceCount = practiceLogs.length;
          final lastPracticeTime = practiceLogs
              .map((log) => log.timestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          
          final updatedPiece = piece.copyWith(
            lastPracticeTime: lastPracticeTime,
            practiceCount: practiceCount,
          );
          await _repository.updateMusicPiece(updatedPiece);
          AppLogger.log('RestoreManager: Updated practice tracking for piece ${piece.title}: count=$practiceCount, lastTime=$lastPracticeTime');
        }
        updatedPieces++;
      } catch (e) {
        AppLogger.log('RestoreManager: Error updating practice tracking for piece ${piece.title}: $e');
      }
    }
    
    AppLogger.log('RestoreManager: Practice tracking recalculation completed. Updated pieces: $updatedPieces');
  }

  /// Restores media files from backup
  Future<void> _restoreMediaFiles(Archive archive, String storagePath) async {
    AppLogger.log('RestoreManager: Starting media files restore (with temp directory)');
    AppLogger.log('RestoreManager: Archive contains  [archive.files.length] total files');

    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    final tempMediaDir = Directory(p.join(appDir.path, 'media_temp'));

    // Clean up temp directory if it exists
    if (await tempMediaDir.exists()) {
      await tempMediaDir.delete(recursive: true);
    }
    await tempMediaDir.create(recursive: true);

    int extractedFiles = 0;
    for (final file in archive.files) {
      if (file.name.startsWith('media/')) {
        final tempFilePath = p.join(tempMediaDir.path, file.name.substring('media/'.length));
        AppLogger.log('RestoreManager: Extracting media file: ${file.name} to $tempFilePath');
        if (file.isFile) {
          try {
            final fileDir = Directory(p.dirname(tempFilePath));
            if (!await fileDir.exists()) {
              await fileDir.create(recursive: true);
            }
            final outputStream = OutputFileStream(tempFilePath);
            outputStream.writeBytes(file.content);
            outputStream.close();
            extractedFiles++;
            AppLogger.log('RestoreManager: Successfully extracted: ${file.name}');
          } catch (e) {
            AppLogger.log('RestoreManager: Error extracting file ${file.name}: $e');
          }
        }
      }
    }
    AppLogger.log('RestoreManager: Media files extraction to temp completed. Extracted: $extractedFiles files');

    // Now copy files from tempMediaDir to mediaDir, overwriting only files that exist in tempMediaDir
    final tempPieceDirs = tempMediaDir.listSync(recursive: false).whereType<Directory>();
    for (final tempPieceDir in tempPieceDirs) {
      final pieceId = p.basename(tempPieceDir.path);
      final destPieceDir = Directory(p.join(mediaDir.path, pieceId));
      if (!await destPieceDir.exists()) {
        await destPieceDir.create(recursive: true);
      }
      // Copy all files and subdirectories from tempPieceDir to destPieceDir
      await _copyDirectory(tempPieceDir, destPieceDir);
    }

    // Clean up temp directory
    await tempMediaDir.delete(recursive: true);
    AppLogger.log('RestoreManager: Temp media directory deleted after restore');
  }

  /// Helper to copy directory contents
  Future<void> _copyDirectory(Directory src, Directory dest) async {
    await for (var entity in src.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: src.path);
        final newFile = File(p.join(dest.path, relativePath));
        if (!await newFile.parent.exists()) {
          await newFile.parent.create(recursive: true);
        }
        await entity.copy(newFile.path);
      } else if (entity is Directory) {
        final newDir = Directory(p.join(dest.path, p.relative(entity.path, from: src.path)));
        if (!await newDir.exists()) {
          await newDir.create(recursive: true);
        }
      }
    }
  }

  /// Restores app settings from backup data
  Future<void> _restoreAppSettings(Map<String, dynamic>? appSettingsJson) async {
    if (appSettingsJson == null) {
      AppLogger.log('RestoreManager: No app settings found in backup, skipping settings restore');
      return;
    }

    AppLogger.log('RestoreManager: Restoring app settings from backup...');
    AppLogger.log('RestoreManager: Settings keys: ${appSettingsJson.keys.join(', ')}');
    
    // Theme and appearance settings
    if (appSettingsJson['appThemePreference'] != null) {
      await prefs.setString('appThemePreference', appSettingsJson['appThemePreference']);
      AppLogger.log('RestoreManager: Restored appThemePreference: ${appSettingsJson['appThemePreference']}');
    }
    if (appSettingsJson['appAccentColor'] != null) {
      await prefs.setInt('appAccentColor', appSettingsJson['appAccentColor']);
      AppLogger.log('RestoreManager: Restored appAccentColor: ${appSettingsJson['appAccentColor']}');
    }
    if (appSettingsJson['galleryColumns'] != null) {
      await prefs.setInt('galleryColumns', appSettingsJson['galleryColumns']);
      AppLogger.log('RestoreManager: Restored galleryColumns: ${appSettingsJson['galleryColumns']}');
    }
    if (appSettingsJson['thumbnailStyle'] != null) {
      await prefs.setString('thumbnailStyle', appSettingsJson['thumbnailStyle']);
      AppLogger.log('RestoreManager: Restored thumbnailStyle: ${appSettingsJson['thumbnailStyle']}');
    }
    if (appSettingsJson['showPracticeCount'] != null) {
      await prefs.setBool('showPracticeCount', appSettingsJson['showPracticeCount']);
      AppLogger.log('RestoreManager: Restored showPracticeCount: ${appSettingsJson['showPracticeCount']}');
    }
    if (appSettingsJson['showLastPracticed'] != null) {
      await prefs.setBool('showLastPracticed', appSettingsJson['showLastPracticed']);
      AppLogger.log('RestoreManager: Restored showLastPracticed: ${appSettingsJson['showLastPracticed']}');
    }
    if (appSettingsJson['showDotPatternBackground'] != null) {
      await prefs.setBool('showDotPatternBackground', appSettingsJson['showDotPatternBackground']);
      AppLogger.log('RestoreManager: Restored showDotPatternBackground: ${appSettingsJson['showDotPatternBackground']}');
    }
    
    // Backup settings
    if (appSettingsJson['autoBackupEnabled'] != null) {
      await prefs.setBool('autoBackupEnabled', appSettingsJson['autoBackupEnabled']);
      AppLogger.log('RestoreManager: Restored autoBackupEnabled: ${appSettingsJson['autoBackupEnabled']}');
    }
    if (appSettingsJson['autoBackupFrequency'] != null) {
      await prefs.setDouble('autoBackupFrequency', (appSettingsJson['autoBackupFrequency'] as num).toDouble());
      AppLogger.log('RestoreManager: Restored autoBackupFrequency: ${appSettingsJson['autoBackupFrequency']}');
    }
    if (appSettingsJson['autoBackupCount'] != null) {
      await prefs.setInt('autoBackupCount', appSettingsJson['autoBackupCount']);
      AppLogger.log('RestoreManager: Restored autoBackupCount: ${appSettingsJson['autoBackupCount']}');
    }
    if (appSettingsJson['lastAutoBackupTimestamp'] != null) {
      await prefs.setInt('lastAutoBackupTimestamp', appSettingsJson['lastAutoBackupTimestamp']);
      AppLogger.log('RestoreManager: Restored lastAutoBackupTimestamp: ${appSettingsJson['lastAutoBackupTimestamp']}');
    }
    
    // Storage and path settings
    if (appSettingsJson['appStoragePath'] != null) {
      await prefs.setString('appStoragePath', appSettingsJson['appStoragePath']);
      AppLogger.log('RestoreManager: Restored appStoragePath: ${appSettingsJson['appStoragePath']}');
      
      // Reinitialize the logger with the restored storage path
      await AppLogger.reinitialize();
      AppLogger.log('RestoreManager: Logger reinitialized with restored storage path');
    }
    
    // Library and sorting settings
    if (appSettingsJson['sortOption'] != null) {
      await prefs.setString('sortOption', appSettingsJson['sortOption']);
      AppLogger.log('RestoreManager: Restored sortOption: ${appSettingsJson['sortOption']}');
    }
    
    // Group visibility settings
    if (appSettingsJson['all_group_isHidden'] != null) {
      await prefs.setBool('all_group_isHidden', appSettingsJson['all_group_isHidden']);
      AppLogger.log('RestoreManager: Restored all_group_isHidden: ${appSettingsJson['all_group_isHidden']}');
    }
    if (appSettingsJson['ungrouped_group_isHidden'] != null) {
      await prefs.setBool('ungrouped_group_isHidden', appSettingsJson['ungrouped_group_isHidden']);
      AppLogger.log('RestoreManager: Restored ungrouped_group_isHidden: ${appSettingsJson['ungrouped_group_isHidden']}');
    }
    if (appSettingsJson['all_group_order'] != null) {
      await prefs.setInt('all_group_order', appSettingsJson['all_group_order']);
      AppLogger.log('RestoreManager: Restored all_group_order: ${appSettingsJson['all_group_order']}');
    }
    if (appSettingsJson['ungrouped_group_order'] != null) {
      await prefs.setInt('ungrouped_group_order', appSettingsJson['ungrouped_group_order']);
      AppLogger.log('RestoreManager: Restored ungrouped_group_order: ${appSettingsJson['ungrouped_group_order']}');
    }
    
    // Audio settings
    if (appSettingsJson['audio_speed'] != null) {
      await prefs.setDouble('audio_speed', appSettingsJson['audio_speed']);
      AppLogger.log('RestoreManager: Restored audio_speed: ${appSettingsJson['audio_speed']}');
    }
    if (appSettingsJson['audio_pitch'] != null) {
      await prefs.setDouble('audio_pitch', appSettingsJson['audio_pitch']);
      AppLogger.log('RestoreManager: Restored audio_pitch: ${appSettingsJson['audio_pitch']}');
    }

    // Practice settings
    if (appSettingsJson['practice_stages'] != null) {
      await prefs.setString('practice_stages', appSettingsJson['practice_stages']);
      AppLogger.log('RestoreManager: Restored practice_stages');
    }
    
    // App state settings
    if (appSettingsJson['hasRunBefore'] != null) {
      await prefs.setBool('hasRunBefore', appSettingsJson['hasRunBefore']);
      AppLogger.log('RestoreManager: Restored hasRunBefore: ${appSettingsJson['hasRunBefore']}');
    }
    
    // Debug settings
    if (appSettingsJson['debugLogsEnabled'] != null) {
      await prefs.setBool('debugLogsEnabled', appSettingsJson['debugLogsEnabled']);
      AppLogger.log('RestoreManager: Restored debugLogsEnabled: ${appSettingsJson['debugLogsEnabled']}');
    }
    
    AppLogger.log('RestoreManager: App settings restored successfully');
  }

  /// Performs the complete restore process
  Future<bool> performRestore({BuildContext? context, String? filePath, bool isFreshRestore = false, bool shouldPop = true}) async {
    AppLogger.log('RestoreManager: Initiating data restore');
    final messenger = context != null ? ScaffoldMessenger.of(context) : null;
    final navigator = context != null ? Navigator.of(context) : null;

    _showRestoreMessage(messenger, true, 'Restoring data...');
    
    try {
      final storagePath = prefs.getString('appStoragePath');
      AppLogger.log('RestoreManager: Storage path: $storagePath');
      
      String? backupPath = filePath;
      
      if (backupPath == null) {
        String? backupDir;
        if (storagePath != null) {
          final backupsDir = Directory(p.join(storagePath, 'Backups'));
          if (await backupsDir.exists()) {
            backupDir = backupsDir.path;
            AppLogger.log('RestoreManager: Default restore directory: $backupDir');
          }
        }

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          initialDirectory: backupDir,
        );
        AppLogger.log('RestoreManager: FilePicker.pickFiles returned: ${result?.files.single.path}');
        
        if (result != null && result.files.single.path != null) {
          backupPath = result.files.single.path!;
        }
      }

      if (backupPath != null) {
        _showRestoreMessage(messenger, true, 'Restore in progress...');
        
        if (isFreshRestore) {
          AppLogger.log('RestoreManager: Fresh restore detected. Clearing all existing music pieces.');
          await _repository.deleteAllMusicPieces();
        }

        final data = await _extractBackupData(backupPath);
        if (data == null) return false;

        if (storagePath == null) {
          _showRestoreMessage(messenger, false, 'Restore failed: Storage path not configured.');
          return false;
        }

        final int? backupVersion = data['backupVersion'] as int?;
        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];
        final List<dynamic> groupsJson = data['groups'] ?? [];
        final List<dynamic> practiceLogsJson = data['practiceLogs'] ?? [];
        final Map<String, dynamic>? appSettingsJson = data['appSettings'] as Map<String, dynamic>?;

        AppLogger.log('RestoreManager: Data extracted - Music pieces: ${musicPiecesJson.length}, Tags: ${tagsJson.length}, Groups: ${groupsJson.length}, Practice logs: ${practiceLogsJson.length}');

        await _restoreMusicPieces(musicPiecesJson, storagePath, backupVersion);
        await _updateMediaFilePaths(storagePath);
        await _restoreTags(tagsJson);
        await _restoreGroups(groupsJson);
        await _restorePracticeLogs(practiceLogsJson);
        await _recalculatePracticeTracking(); // Recalculate practice tracking after restoring practice logs
        await _restoreAppSettings(appSettingsJson);

        // Extract media files
        final inputStream = InputFileStream(backupPath);
        final archive = ZipDecoder().decodeBytes(inputStream.toUint8List());
        await _restoreMediaFiles(archive, storagePath);

        _showRestoreMessage(messenger, true, 'Data restored successfully!');
        AppLogger.log('RestoreManager: Data restored successfully');
        
        // Force a rebuild of the app to refresh all data
        if (shouldPop && navigator != null && navigator.context.mounted) {
          AppLogger.log('RestoreManager: Triggering app rebuild after restore');
          // This will cause the library screen to reload when navigated back to
          navigator.pop(true);
        }
        return true;
      } else {
        _showRestoreMessage(messenger, false, 'Restore cancelled.');
        AppLogger.log('RestoreManager: Restore cancelled by user');
        return false;
      }
    } catch (e) {
      AppLogger.log('RestoreManager: Restore failed: $e');
      _showRestoreMessage(messenger, false, 'Restore failed: $e');
      return false;
    }
  }
} 