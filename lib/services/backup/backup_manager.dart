import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import '../../utils/app_logger.dart';

import '../../database/music_piece_repository.dart';
import '../../models/music_piece.dart';
import '../../models/tag.dart';
import '../../models/group.dart';

import 'package:intl/intl.dart';

class BackupManager {
  final MusicPieceRepository _repository;
  final SharedPreferences prefs;

  BackupManager(this._repository, this.prefs);

  /// Creates backup data from the database
  Future<Map<String, dynamic>> _createBackupData() async {
    final musicPieces = await _repository.getMusicPieces();
    final tags = await _repository.getTags();
    final groups = await _repository.getGroups();
    final practiceLogs = await _repository.getAllPracticeLogs();

    // Collect all app settings from SharedPreferences
    final appSettings = await _collectAppSettings();

    return {
      'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'groups': groups.map((e) => e.toJson()).toList(),
      'practiceLogs': practiceLogs.map((e) => e.toJson()).toList(),
      'appSettings': appSettings,
    };
  }

  /// Collects all app settings from SharedPreferences
  Future<Map<String, dynamic>> _collectAppSettings() async {
    final settings = <String, dynamic>{};
    
    // Theme and appearance settings
    settings['appThemePreference'] = prefs.getString('appThemePreference');
    settings['appAccentColor'] = prefs.getInt('appAccentColor');
    settings['galleryColumns'] = prefs.getInt('galleryColumns');
    
    // Backup settings
    settings['autoBackupEnabled'] = prefs.getBool('autoBackupEnabled');
    settings['autoBackupFrequency'] = prefs.getInt('autoBackupFrequency');
    settings['autoBackupCount'] = prefs.getInt('autoBackupCount');
    settings['lastAutoBackupTimestamp'] = prefs.getInt('lastAutoBackupTimestamp');
    
    // Storage and path settings
    settings['appStoragePath'] = prefs.getString('appStoragePath');
    
    // Library and sorting settings
    settings['sortOption'] = prefs.getString('sortOption');
    
    // Group visibility settings
    settings['all_group_isHidden'] = prefs.getBool('all_group_isHidden');
    settings['ungrouped_group_isHidden'] = prefs.getBool('ungrouped_group_isHidden');
    settings['all_group_order'] = prefs.getInt('all_group_order');
    settings['ungrouped_group_order'] = prefs.getInt('ungrouped_group_order');
    
    // Audio settings
    settings['audio_speed'] = prefs.getDouble('audio_speed');
    settings['audio_pitch'] = prefs.getDouble('audio_pitch');
    
    // App state settings
    settings['hasRunBefore'] = prefs.getBool('hasRunBefore');
    
    // Debug settings
    settings['debugLogsEnabled'] = prefs.getBool('debugLogsEnabled');
    
    AppLogger.log('Collected ${settings.length} app settings for backup');
    return settings;
  }

  /// Creates a zip file with backup data
  Future<Uint8List> _createBackupZip(Map<String, dynamic> data, String storagePath) async {
    final jsonString = jsonEncode(data);
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = 'music_repertoire_backup_$timestamp.zip';

    final tempDir = await getTemporaryDirectory();
    final tempZipPath = p.join(tempDir.path, fileName);
    AppLogger.log('Temporary zip path: $tempZipPath');

    // Create archive using the archive package directly
    final archive = Archive();
    
    // Add JSON data
    final jsonBytes = utf8.encode(jsonString);
    final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonBytes.length, jsonBytes);
    archive.addFile(jsonArchiveFile);
    AppLogger.log('JSON data added to archive (${jsonBytes.length} bytes)');

    // Add media files to archive
    final mediaDir = Directory(p.join(storagePath, 'media'));
    if (await mediaDir.exists()) {
      AppLogger.log('Adding media directory to archive: ${mediaDir.path}');
      await _addMediaFilesToArchive(archive, mediaDir, storagePath);
    } else {
      AppLogger.log('Media directory does not exist: ${mediaDir.path}');
    }

    // Encode the archive to zip format
    final zipBytes = ZipEncoder().encode(archive);
    AppLogger.log('Archive encoded to zip format (${zipBytes?.length ?? 0} bytes)');

    if (zipBytes != null) {
      return Uint8List.fromList(zipBytes);
    } else {
      throw Exception('Failed to create zip archive');
    }
  }

  /// Recursively adds media files to the archive
  Future<void> _addMediaFilesToArchive(Archive archive, Directory dir, String basePath) async {
    AppLogger.log('Scanning directory: ${dir.path}');
    
    try {
      final entities = await dir.list().toList();
      int fileCount = 0;
      
      for (final entity in entities) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: basePath);
          AppLogger.log('Adding file to archive: $relativePath');
          
          try {
            final bytes = await entity.readAsBytes();
            final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
            archive.addFile(archiveFile);
            fileCount++;
            AppLogger.log('Successfully added file: $relativePath (${bytes.length} bytes)');
          } catch (e) {
            AppLogger.log('Error reading file ${entity.path}: $e');
          }
        } else if (entity is Directory) {
          // Recursively add subdirectories
          await _addMediaFilesToArchive(archive, entity, basePath);
        }
      }
      
      AppLogger.log('Added $fileCount files from directory: ${dir.path}');
    } catch (e) {
      AppLogger.log('Error scanning directory ${dir.path}: $e');
    }
  }

  /// Saves backup file to the specified location
  Future<String?> _saveBackupFile(Uint8List zipBytes, String backupDirectory, bool manual, BuildContext? context) async {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = 'music_repertoire_backup_$timestamp.zip';

    if (manual) {
      AppLogger.log('Handling manual backup save.');
      String? outputFile;
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, we can't control the initial directory, so we'll save to the app's documents directory
        // and let the user move it if needed
        final appDocDir = await getApplicationDocumentsDirectory();
        final defaultPath = p.join(appDocDir.path, fileName);
        AppLogger.log('Mobile platform detected, using default path: $defaultPath');
        
        outputFile = await FilePicker.platform.saveFile(
          fileName: fileName,
          bytes: zipBytes,
        );
        AppLogger.log('FilePicker.saveFile (mobile) returned: $outputFile');
      } else {
        outputFile = await FilePicker.platform.saveFile(
          fileName: fileName,
          initialDirectory: backupDirectory,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        AppLogger.log('FilePicker.saveFile (desktop) returned: $outputFile');
        if (outputFile != null) {
          final outputDirectory = Directory(p.dirname(outputFile));
          if (!await outputDirectory.exists()) {
            AppLogger.log('Creating output directory for desktop: ${outputDirectory.path}');
            await outputDirectory.create(recursive: true);
          }
          await File(outputFile).writeAsBytes(zipBytes);
        }
      }
      return outputFile;
    } else {
      AppLogger.log('Handling automatic backup save.');
      final zipFile = File(p.join(backupDirectory, fileName));
      await zipFile.writeAsBytes(zipBytes);
      return zipFile.path;
    }
  }

  /// Shows appropriate success/failure messages
  void _showBackupMessage(BuildContext? context, bool success, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
    }
  }

  /// Performs the complete backup process
  Future<void> performBackup({bool manual = true, BuildContext? context}) async {
    AppLogger.log('Initiating backup (manual: $manual).');
    if (context != null && !context.mounted) return;
    
    // Show progress message for both manual and auto-backup
    _showBackupMessage(context, true, manual ? 'Backing up data...' : 'Creating auto-backup...');
    
    try {
      final storagePath = prefs.getString('appStoragePath');
      if (storagePath == null) {
        AppLogger.log('Backup failed: Storage path not configured.');
        _showBackupMessage(context, false, 'Backup failed: Storage path not configured.');
        return;
      }
      AppLogger.log('Storage path: $storagePath');

      final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups');
      final backupDirectory = Directory(p.join(storagePath, backupSubDir));
      AppLogger.log('Backup directory: ${backupDirectory.path}');
      if (!await backupDirectory.exists()) {
        AppLogger.log('Creating backup directory: ${backupDirectory.path}');
        await backupDirectory.create(recursive: true);
      }

      final data = await _createBackupData();
      final zipBytes = await _createBackupZip(data, storagePath);
      final outputFile = await _saveBackupFile(zipBytes, backupDirectory.path, manual, context);

      if (outputFile != null) {
        _showBackupMessage(context, true, manual ? 'Data backed up successfully!' : 'Autobackup successful!');
        AppLogger.log(manual ? 'Manual backup successful.' : 'Autobackup successful.');
      } else {
        _showBackupMessage(context, false, 'Backup cancelled.');
        AppLogger.log('Backup cancelled by user.');
      }
    } catch (e) {
      AppLogger.log('Backup failed: $e');
      _showBackupMessage(context, false, 'Backup failed: $e');
    }
  }

  /// Manages automatic backup file cleanup
  Future<void> cleanupOldBackups(int autoBackupCount) async {
    final storagePath = prefs.getString('appStoragePath');
    if (storagePath != null) {
      final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
      if (await autoBackupDir.exists()) {
        AppLogger.log('Auto-backup directory exists: ${autoBackupDir.path}');
        final files = await autoBackupDir.list().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        AppLogger.log('Found ${files.length} auto-backup files.');
        if (files.length > autoBackupCount) {
          AppLogger.log('Deleting old auto-backup files. Keeping ${autoBackupCount}.');
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            AppLogger.log('Deleting: ${files[i].path}');
            await files[i].delete();
          }
        }
      }
    }
  }
} 