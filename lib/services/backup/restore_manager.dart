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
      final inputStream = InputFileStream(backupFilePath);
      final archive = ZipDecoder().decodeBuffer(inputStream);
      AppLogger.log('Backup file decoded.');

      final jsonFile = archive.findFile('music_repertoire.json');
      if (jsonFile == null) {
        AppLogger.log('Restore failed: music_repertoire.json not found in backup.');
        throw Exception('Invalid backup file: music_repertoire.json not found.');
      }

      final jsonString = utf8.decode(jsonFile.content);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      AppLogger.log('JSON data extracted from backup.');
      
      return data;
    } catch (e) {
      AppLogger.log('Error extracting backup data: $e');
      rethrow;
    }
  }

  /// Restores music pieces from backup data
  Future<void> _restoreMusicPieces(List<dynamic> musicPiecesJson) async {
    await _repository.deleteAllMusicPieces();
    AppLogger.log('Deleted all existing music pieces.');
    
    for (var pieceJson in musicPiecesJson) {
      final piece = MusicPiece.fromJson(pieceJson);
      await _repository.insertMusicPiece(piece);
    }
    AppLogger.log('Restored ${musicPiecesJson.length} music pieces.');
  }

  /// Restores tags from backup data
  Future<void> _restoreTags(List<dynamic> tagsJson) async {
    await _repository.deleteAllTags();
    AppLogger.log('Deleted all existing tags.');
    
    for (var tagJson in tagsJson) {
      final tag = Tag.fromJson(tagJson);
      await _repository.insertTag(tag);
    }
    AppLogger.log('Restored ${tagsJson.length} tags.');
  }

  /// Restores groups from backup data
  Future<void> _restoreGroups(List<dynamic> groupsJson) async {
    final List<Group> oldGroupsBeforeRestore = await _repository.getGroups();
    AppLogger.log('Fetched ${oldGroupsBeforeRestore.length} old groups before restore.');

    await _repository.deleteAllGroups();
    AppLogger.log('Deleted all existing groups.');
    
    for (var groupJson in groupsJson) {
      final group = Group.fromJson(groupJson);
      await _repository.createGroup(group);
    }
    AppLogger.log('Restored ${groupsJson.length} groups from backup.');

    final List<Group> currentGroupsAfterRestore = await _repository.getGroups();
    final Set<String> currentGroupIds = currentGroupsAfterRestore.map((g) => g.id).toSet();
    AppLogger.log('Current groups after restore: ${currentGroupIds.length}');

    int nextOrder = currentGroupsAfterRestore.length;

    for (final oldGroup in oldGroupsBeforeRestore) {
      if (!currentGroupIds.contains(oldGroup.id)) {
        final newOrder = nextOrder++;
        final groupToReAdd = oldGroup.copyWith(order: newOrder);
        await _repository.createGroup(groupToReAdd);
        AppLogger.log('Re-added old group: ${groupToReAdd.name}');
      }
    }
    AppLogger.log('Finished re-adding old groups.');
  }

  /// Restores practice logs from backup data
  Future<void> _restorePracticeLogs(List<dynamic> practiceLogsJson) async {
    await _repository.deleteAllPracticeLogs();
    AppLogger.log('Deleted all existing practice logs.');
    
    for (var logJson in practiceLogsJson) {
      final log = PracticeLog.fromJson(logJson);
      await _repository.insertPracticeLog(log);
    }
    AppLogger.log('Restored ${practiceLogsJson.length} practice logs from backup.');
  }

  /// Restores media files from backup
  Future<void> _restoreMediaFiles(Archive archive, String storagePath) async {
    final mediaDir = Directory(p.join(storagePath, 'media'));
    AppLogger.log('Media directory for restore: ${mediaDir.path}');
    
    if (await mediaDir.exists()) {
      AppLogger.log('Deleting existing media directory.');
      await mediaDir.delete(recursive: true);
    }
    AppLogger.log('Creating new media directory.');
    await mediaDir.create(recursive: true);

    for (final file in archive.files) {
      if (file.name.startsWith('media/')) {
        final filePath = p.join(storagePath, file.name);
        AppLogger.log('Extracting media file: ${file.name} to $filePath');
        if (file.isFile) {
          final outputStream = OutputFileStream(filePath);
          outputStream.writeBytes(file.content);
          outputStream.close();
        }
      }
    }
    AppLogger.log('Media files extracted.');
  }

  /// Restores app settings from backup data
  Future<void> _restoreAppSettings(Map<String, dynamic>? appSettingsJson) async {
    if (appSettingsJson == null) {
      AppLogger.log('No app settings found in backup, skipping settings restore.');
      return;
    }

    AppLogger.log('Restoring app settings from backup...');
    
    // Theme and appearance settings
    if (appSettingsJson['appThemePreference'] != null) {
      await prefs.setString('appThemePreference', appSettingsJson['appThemePreference']);
    }
    if (appSettingsJson['appAccentColor'] != null) {
      await prefs.setInt('appAccentColor', appSettingsJson['appAccentColor']);
    }
    if (appSettingsJson['galleryColumns'] != null) {
      await prefs.setInt('galleryColumns', appSettingsJson['galleryColumns']);
    }
    
    // Backup settings
    if (appSettingsJson['autoBackupEnabled'] != null) {
      await prefs.setBool('autoBackupEnabled', appSettingsJson['autoBackupEnabled']);
    }
    if (appSettingsJson['autoBackupFrequency'] != null) {
      await prefs.setInt('autoBackupFrequency', appSettingsJson['autoBackupFrequency']);
    }
    if (appSettingsJson['autoBackupCount'] != null) {
      await prefs.setInt('autoBackupCount', appSettingsJson['autoBackupCount']);
    }
    if (appSettingsJson['lastAutoBackupTimestamp'] != null) {
      await prefs.setInt('lastAutoBackupTimestamp', appSettingsJson['lastAutoBackupTimestamp']);
    }
    
    // Storage and path settings
    if (appSettingsJson['appStoragePath'] != null) {
      await prefs.setString('appStoragePath', appSettingsJson['appStoragePath']);
    }
    
    // Library and sorting settings
    if (appSettingsJson['sortOption'] != null) {
      await prefs.setString('sortOption', appSettingsJson['sortOption']);
    }
    
    // Group visibility settings
    if (appSettingsJson['all_group_isHidden'] != null) {
      await prefs.setBool('all_group_isHidden', appSettingsJson['all_group_isHidden']);
    }
    if (appSettingsJson['ungrouped_group_isHidden'] != null) {
      await prefs.setBool('ungrouped_group_isHidden', appSettingsJson['ungrouped_group_isHidden']);
    }
    if (appSettingsJson['all_group_order'] != null) {
      await prefs.setInt('all_group_order', appSettingsJson['all_group_order']);
    }
    if (appSettingsJson['ungrouped_group_order'] != null) {
      await prefs.setInt('ungrouped_group_order', appSettingsJson['ungrouped_group_order']);
    }
    
    // Audio settings
    if (appSettingsJson['audio_speed'] != null) {
      await prefs.setDouble('audio_speed', appSettingsJson['audio_speed']);
    }
    if (appSettingsJson['audio_pitch'] != null) {
      await prefs.setDouble('audio_pitch', appSettingsJson['audio_pitch']);
    }
    
    // App state settings
    if (appSettingsJson['hasRunBefore'] != null) {
      await prefs.setBool('hasRunBefore', appSettingsJson['hasRunBefore']);
    }
    
    // Debug settings
    if (appSettingsJson['debugLogsEnabled'] != null) {
      await prefs.setBool('debugLogsEnabled', appSettingsJson['debugLogsEnabled']);
    }
    
    AppLogger.log('App settings restored successfully.');
  }

  /// Performs the complete restore process
  Future<void> performRestore({BuildContext? context}) async {
    AppLogger.log('Initiating data restore.');
    if (context != null && !context.mounted) return;
    
    _showRestoreMessage(context, true, 'Restoring data...');
    
    try {
      final storagePath = prefs.getString('appStoragePath');
      String? backupDir;
      if (storagePath != null) {
        final backupsDir = Directory(p.join(storagePath, 'Backups'));
        if (await backupsDir.exists()) {
          backupDir = backupsDir.path;
          AppLogger.log('Default restore directory: ${backupDir}');
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        initialDirectory: backupDir,
      );
      AppLogger.log('FilePicker.pickFiles returned: ${result?.files.single.path}');

      if (result != null && result.files.single.path != null) {
        final data = await _extractBackupData(result.files.single.path!);
        if (data == null) return;

        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];
        final List<dynamic> groupsJson = data['groups'] ?? [];
        final List<dynamic> practiceLogsJson = data['practiceLogs'] ?? [];
        final Map<String, dynamic>? appSettingsJson = data['appSettings'] as Map<String, dynamic>?;

        await _restoreMusicPieces(musicPiecesJson);
        await _restoreTags(tagsJson);
        await _restoreGroups(groupsJson);
        await _restorePracticeLogs(practiceLogsJson);
        await _restoreAppSettings(appSettingsJson);

        // Extract media files
        final inputStream = InputFileStream(result.files.single.path!);
        final archive = ZipDecoder().decodeBuffer(inputStream);
        await _restoreMediaFiles(archive, storagePath!);

        _showRestoreMessage(context, true, 'Data restored successfully!');
        AppLogger.log('Data restored successfully.');
      } else {
        _showRestoreMessage(context, false, 'Restore cancelled.');
        AppLogger.log('Restore cancelled by user.');
      }
    } catch (e) {
      AppLogger.log('Restore failed: $e');
      _showRestoreMessage(context, false, 'Restore failed: $e');
    }
  }
} 