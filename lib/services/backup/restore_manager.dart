import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
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
  void _showRestoreMessage(BuildContext? context, bool success, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      final archive = ZipDecoder().decodeBuffer(inputStream);
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
  Future<void> _restoreMusicPieces(List<dynamic> musicPiecesJson) async {
    AppLogger.log('RestoreManager: Starting music pieces restore with merge logic. Count: ${musicPiecesJson.length}');
    
    // Get existing pieces for comparison
    final existingPieces = await _repository.getMusicPieces();
    final existingPieceIds = existingPieces.map((p) => p.id).toSet();
    AppLogger.log('RestoreManager: Found ${existingPieces.length} existing pieces');
    
    int insertedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;
    
    for (int i = 0; i < musicPiecesJson.length; i++) {
      final pieceJson = musicPiecesJson[i];
      try {
        final piece = MusicPiece.fromJson(pieceJson);
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
    
    AppLogger.log('RestoreManager: Music pieces restore completed. Inserted: $insertedCount, Updated: $updatedCount, Skipped: $skippedCount');
  }

  /// Updates media file paths in music pieces to reflect the new storage location
  Future<void> _updateMediaFilePaths(String storagePath) async {
    AppLogger.log('RestoreManager: Starting media file path updates for storage path: $storagePath');
    
    final allPieces = await _repository.getMusicPieces();
    int updatedPieces = 0;
    
    for (final piece in allPieces) {
      bool pieceUpdated = false;
      final updatedMediaItems = <MediaItem>[];
      
      for (final mediaItem in piece.mediaItems) {
        MediaItem updatedItem = mediaItem;
        
        // Only update paths for local files (not media links)
        if (mediaItem.type != MediaType.mediaLink && mediaItem.pathOrUrl.isNotEmpty) {
          final oldPath = mediaItem.pathOrUrl;
          
          // Extract the relative path from the old path
          // Old path format: /path/to/storage/media/pieceId/type/filename
          // We need to extract: media/pieceId/type/filename
          final pathParts = oldPath.split(Platform.pathSeparator);
          final mediaIndex = pathParts.indexWhere((part) => part == 'media');
          
          if (mediaIndex != -1 && mediaIndex < pathParts.length - 1) {
            final relativePath = pathParts.sublist(mediaIndex).join(Platform.pathSeparator);
            final newPath = p.join(storagePath, relativePath);
            
            AppLogger.log('RestoreManager: Updating media path for piece ${piece.title}:');
            AppLogger.log('  Old path: $oldPath');
            AppLogger.log('  New path: $newPath');
            
            updatedItem = mediaItem.copyWith(pathOrUrl: newPath);
            pieceUpdated = true;
          } else {
            AppLogger.log('RestoreManager: Could not extract relative path from: $oldPath');
          }
        }
        
        updatedMediaItems.add(updatedItem);
      }
      
      if (pieceUpdated) {
        final updatedPiece = piece.copyWith(mediaItems: updatedMediaItems);
        await _repository.updateMusicPiece(updatedPiece);
        updatedPieces++;
        AppLogger.log('RestoreManager: Updated media paths for piece: ${piece.title}');
      }
    }
    
    AppLogger.log('RestoreManager: Media file path updates completed. Updated pieces: $updatedPieces');
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
    AppLogger.log('RestoreManager: Starting media files restore to: $storagePath');
    AppLogger.log('RestoreManager: Archive contains ${archive.files.length} total files');
    
    // Log all files in the archive for debugging
    for (int i = 0; i < archive.files.length; i++) {
      final file = archive.files[i];
      AppLogger.log('RestoreManager: Archive file ${i + 1}: ${file.name} (isFile: ${file.isFile}, size: ${file.content?.length ?? 0})');
    }
    
    final mediaDir = Directory(p.join(storagePath, 'media'));
    AppLogger.log('RestoreManager: Media directory for restore: ${mediaDir.path}');
    
    if (await mediaDir.exists()) {
      AppLogger.log('RestoreManager: Deleting existing media directory');
      await mediaDir.delete(recursive: true);
    }
    AppLogger.log('RestoreManager: Creating new media directory');
    await mediaDir.create(recursive: true);

    int extractedFiles = 0;
    for (final file in archive.files) {
      if (file.name.startsWith('media/')) {
        final filePath = p.join(storagePath, file.name);
        AppLogger.log('RestoreManager: Extracting media file: ${file.name} to $filePath');
        if (file.isFile) {
          try {
            // Ensure the directory exists before creating the file
            final fileDir = Directory(p.dirname(filePath));
            if (!await fileDir.exists()) {
              AppLogger.log('RestoreManager: Creating directory: ${fileDir.path}');
              await fileDir.create(recursive: true);
            }
            
            final outputStream = OutputFileStream(filePath);
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
    AppLogger.log('RestoreManager: Media files extraction completed. Extracted: $extractedFiles files');
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
    
    // Backup settings
    if (appSettingsJson['autoBackupEnabled'] != null) {
      await prefs.setBool('autoBackupEnabled', appSettingsJson['autoBackupEnabled']);
      AppLogger.log('RestoreManager: Restored autoBackupEnabled: ${appSettingsJson['autoBackupEnabled']}');
    }
    if (appSettingsJson['autoBackupFrequency'] != null) {
      await prefs.setInt('autoBackupFrequency', appSettingsJson['autoBackupFrequency']);
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
  Future<void> performRestore({BuildContext? context}) async {
    AppLogger.log('RestoreManager: Initiating data restore');
    if (context != null && !context.mounted) return;
    
    _showRestoreMessage(context, true, 'Restoring data...');
    
    try {
      final storagePath = prefs.getString('appStoragePath');
      AppLogger.log('RestoreManager: Storage path: $storagePath');
      
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
        final data = await _extractBackupData(result.files.single.path!);
        if (data == null) return;

        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];
        final List<dynamic> groupsJson = data['groups'] ?? [];
        final List<dynamic> practiceLogsJson = data['practiceLogs'] ?? [];
        final Map<String, dynamic>? appSettingsJson = data['appSettings'] as Map<String, dynamic>?;

        AppLogger.log('RestoreManager: Data extracted - Music pieces: ${musicPiecesJson.length}, Tags: ${tagsJson.length}, Groups: ${groupsJson.length}, Practice logs: ${practiceLogsJson.length}');

        await _restoreMusicPieces(musicPiecesJson);
        await _updateMediaFilePaths(storagePath!); // Update media file paths after restoring music pieces
        await _restoreTags(tagsJson);
        await _restoreGroups(groupsJson);
        await _restorePracticeLogs(practiceLogsJson);
        await _recalculatePracticeTracking(); // Recalculate practice tracking after restoring practice logs
        await _restoreAppSettings(appSettingsJson);

        // Extract media files
        final inputStream = InputFileStream(result.files.single.path!);
        final archive = ZipDecoder().decodeBuffer(inputStream);
        await _restoreMediaFiles(archive, storagePath!);

        _showRestoreMessage(context, true, 'Data restored successfully!');
        AppLogger.log('RestoreManager: Data restored successfully');
        
        // Force a rebuild of the app to refresh all data
        if (context != null && context.mounted) {
          AppLogger.log('RestoreManager: Triggering app rebuild after restore');
          // This will cause the library screen to reload when navigated back to
          Navigator.of(context).pop(true);
        }
      } else {
        _showRestoreMessage(context, false, 'Restore cancelled.');
        AppLogger.log('RestoreManager: Restore cancelled by user');
      }
    } catch (e) {
      AppLogger.log('RestoreManager: Restore failed: $e');
      _showRestoreMessage(context, false, 'Restore failed: $e');
    }
  }
} 