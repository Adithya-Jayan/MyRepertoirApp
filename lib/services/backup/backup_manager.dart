import 'dart:convert';
import 'dart:io';
import 'dart:isolate'; // Import Isolate
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';

import '../../utils/app_logger.dart';
import '../../database/music_piece_repository.dart';


import 'package:intl/intl.dart';

class BackupManager {
  final MusicPieceRepository _repository;
  final SharedPreferences prefs;

  BackupManager(this._repository, this.prefs);

  /// Creates backup data from the database
  Future<Map<String, dynamic>> _createBackupData(String storagePath) async {
    final musicPieces = await _repository.getMusicPieces();
    final tags = await _repository.getTags();
    final groups = await _repository.getGroups();
    final practiceLogs = await _repository.getAllPracticeLogs();

    // Collect all app settings from SharedPreferences
    final appSettings = await _collectAppSettings();

    return {
      'backupVersion': 2,
      'musicPieces': musicPieces.map((e) => e.toJsonForBackup(storagePath)).toList(),
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
    settings['thumbnailStyle'] = prefs.getString('thumbnailStyle');
    settings['showPracticeCount'] = prefs.getBool('showPracticeCount');
    settings['showLastPracticed'] = prefs.getBool('showLastPracticed');
    settings['showDotPatternBackground'] = prefs.getBool('showDotPatternBackground');
    
    // Backup settings
    settings['autoBackupEnabled'] = prefs.getBool('autoBackupEnabled');
    settings['autoBackupFrequency'] = prefs.getDouble('autoBackupFrequency');
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
    
    // Practice settings
    settings['practice_stages'] = prefs.getString('practice_stages');
    
    // App state settings
    settings['hasRunBefore'] = prefs.getBool('hasRunBefore');
    
    // Debug settings
    settings['debugLogsEnabled'] = prefs.getBool('debugLogsEnabled');
    
    AppLogger.log('Collected ${settings.length} app settings for backup');
    return settings;
  }

  // --- Static Methods for Isolate execution ---

  /// Creates a zip file with backup data (Run in Isolate)
  static Future<Uint8List> _createBackupZipTask(Map<String, dynamic> data, bool manual, String appDocPath) async {
    final jsonString = jsonEncode(data);
    
    // Create archive using the archive package directly
    final archive = Archive();
    
    // Add JSON data
    final jsonBytes = utf8.encode(jsonString);
    final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonBytes.length, jsonBytes);
    archive.addFile(jsonArchiveFile);

    // Create and add README file
    final readmeContent = await _staticCreateReadmeContent(data);
    final readmeBytes = utf8.encode(readmeContent);
    final readmeArchiveFile = ArchiveFile('README.txt', readmeBytes.length, readmeBytes);
    archive.addFile(readmeArchiveFile);

    // Add media files to archive
    final mediaDir = Directory(p.join(appDocPath, 'media'));
    if (await mediaDir.exists()) {
      await _staticAddMediaFilesToArchive(archive, mediaDir, appDocPath);
    }

    // Encode the archive to zip format
    final zipBytes = ZipEncoder().encode(archive);

    return Uint8List.fromList(zipBytes);
  }

  /// Creates README content (Static for Isolate)
  static Future<String> _staticCreateReadmeContent(Map<String, dynamic> data) async {
    final musicPieces = data['musicPieces'] as List<dynamic>;
    
    final buffer = StringBuffer();
    buffer.writeln('Hi there! Looks like you\'ve decided to explore the backup file manually :D');
    buffer.writeln('This is how the backup files are structured:');
    buffer.writeln('  music_repertoire.json - Contains all your music pieces, tags, groups, and settings');
    buffer.writeln('  media/ - Contains all your media files (sheet music, audio, images, etc.)');
    buffer.writeln('');
    buffer.writeln('The mapping for the pieces are as follows:');
    buffer.writeln('  <piece_id> : piece_title');
    
    for (final piece in musicPieces) {
      final pieceId = piece['id'] as String;
      final pieceTitle = piece['title'] as String;
      buffer.writeln('  $pieceId : $pieceTitle');
    }
    
    buffer.writeln('');
    buffer.writeln('Each piece_id in the media folder corresponds to a folder containing all media files for that piece.');
    buffer.writeln('The music_repertoire.json file contains all the metadata and relationships between pieces, tags, and groups.');
    buffer.writeln('');
    buffer.writeln('Happy exploring! 🎵');
    
    return buffer.toString();
  }

  /// Recursively adds media files to the archive (Static for Isolate)
  static Future<void> _staticAddMediaFilesToArchive(Archive archive, Directory dir, String basePath) async {
    try {
      final entities = await dir.list().toList();
      
      for (final entity in entities) {
        if (entity is File) {
          final relativePath = p.relative(entity.path, from: basePath);
          
          try {
            final bytes = await entity.readAsBytes();
            final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
            archive.addFile(archiveFile);
          } catch (e) {
            // Ignore error inside isolate
          }
        } else if (entity is Directory) {
          // Recursively add subdirectories
          await _staticAddMediaFilesToArchive(archive, entity, basePath);
        }
      }
    } catch (e) {
      // Ignore error inside isolate
    }
  }

  /// Saves backup file to the specified location
  Future<String?> _saveBackupFile(Uint8List zipBytes, String backupDirectory, bool manual) async {
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = manual ? 'music_repertoire_backup_$timestamp.zip' : 'auto_backup_$timestamp.zip';

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
  void _showBackupMessage(ScaffoldMessengerState? messenger, bool success, String message) {
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
    }
  }

  /// Performs the complete backup process
  Future<void> performBackup({bool manual = true, ScaffoldMessengerState? messenger}) async {
    AppLogger.log('Initiating backup (manual: $manual).');
    
    // Show progress message for both manual and auto-backup
    _showBackupMessage(messenger, true, manual ? 'Backing up data...' : 'Creating auto-backup...');
    
    try {
      final storagePath = prefs.getString('appStoragePath');
      if (storagePath == null) {
        AppLogger.log('Backup failed: Storage path not configured.');
        _showBackupMessage(messenger, false, 'Backup failed: Storage path not configured.');
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

      final data = await _createBackupData(storagePath);
      
      // Get App Documents Directory for Media files
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Run compression in isolate to prevent UI freeze
      AppLogger.log('Starting backup compression in background isolate...');
      final zipBytes = await Isolate.run(() => _createBackupZipTask(data, manual, appDocDir.path));
      AppLogger.log('Backup compression completed.');
      
      final outputFile = await _saveBackupFile(zipBytes, backupDirectory.path, manual);

      if (outputFile != null) {
        // Only show success banner for manual backup, not for auto-backup (handled in backup_utils)
        if (manual) {
          _showBackupMessage(messenger, true, 'Data backed up successfully!');
        }
        AppLogger.log(manual ? 'Manual backup successful.' : 'Autobackup successful.');
      } else {
        _showBackupMessage(messenger, false, 'Backup cancelled.');
        AppLogger.log('Backup cancelled by user.');
      }
    } catch (e) {
      AppLogger.log('Backup failed: $e');
      _showBackupMessage(messenger, false, 'Backup failed: $e');
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
          AppLogger.log('Deleting old auto-backup files. Keeping $autoBackupCount.');
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            AppLogger.log('Deleting: ${files[i].path}');
            await files[i].delete();
          }
        }
      }
    }
  }
} 