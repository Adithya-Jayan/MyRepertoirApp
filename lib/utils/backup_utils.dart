
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/services/backup_restore_service.dart';
import 'package:flutter/material.dart';

/// Initiates an automatic backup of music piece data if enabled by the user
/// and if the defined backup frequency interval has passed.
///
/// This function checks user preferences for auto-backup, determines if a backup
/// is due, and uses the BackupRestoreService to perform the backup.
/// It also manages the number of backup files, deleting older ones to
/// maintain a specified count.
Future<DateTime?> _getLatestBackupDateFromFilenames(List<File> backupFiles) async {
  final regex = RegExp(r'auto_backup_(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})');
  DateTime? latest;
  for (final file in backupFiles) {
    final match = regex.firstMatch(p.basename(file.path));
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      final dt = DateTime(year, month, day, hour, minute, second);
      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
      }
    }
  }
  return latest;
}

Future<void> triggerAutoBackup({ScaffoldMessengerState? messenger}) async {
  AppLogger.log('BackupUtils: Checking auto-backup conditions.');
  final prefs = await SharedPreferences.getInstance();
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
  AppLogger.log('BackupUtils: Auto-backup enabled: $autoBackupEnabled');



  if (autoBackupEnabled) {
    final appStoragePath = prefs.getString('appStoragePath');
    if (appStoragePath == null || appStoragePath.isEmpty) {
      AppLogger.log('BackupUtils: ERROR: appStoragePath is not set. Cannot perform auto-backup.');
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Auto-backup failed: Storage path not configured.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    final backupDir = p.join(appStoragePath, 'Backups', 'Autobackups');
    AppLogger.log('BackupUtils: Using auto-backup directory: $backupDir');
    bool noBackupFiles = false;
    DateTime? lastBackupTime;
    final directory = Directory(backupDir);
    if (await directory.exists()) {
      final files = await directory.list().toList();
      AppLogger.log('BackupUtils: Files found in auto-backup directory:');
      for (final f in files) {
        AppLogger.log('  - ${f.path}');
      }
      final backupFiles = files.where((entity) =>
        entity is File &&
        entity.path.endsWith('.zip') &&
        p.basename(entity.path).startsWith('auto_backup_')
      ).cast<File>().toList();
      AppLogger.log('BackupUtils: Files matching auto_backup_*.zip:');
      for (final f in backupFiles) {
        AppLogger.log('  - ${f.path}');
      }
      if (backupFiles.isEmpty) {
        noBackupFiles = true;
      } else {
        // Use the date in the filename, not file modification time
        lastBackupTime = await _getLatestBackupDateFromFilenames(backupFiles);
        AppLogger.log('BackupUtils: Latest backup date from filename: $lastBackupTime');
      }
    } else {
      AppLogger.log('BackupUtils: Auto-backup directory does not exist.');
      noBackupFiles = true;
    }

    final autoBackupFrequency = prefs.getDouble('autoBackupFrequency') ?? 7.0;
    final now = DateTime.now();
    // Support fractional days by converting to hours
    final requiredInterval = Duration(minutes: (autoBackupFrequency * 24 * 60).round());
    Duration? timeElapsed;
    if (lastBackupTime != null) {
      timeElapsed = now.difference(lastBackupTime);
    }
    AppLogger.log('BackupUtils: Last backup file time (from filename): $lastBackupTime');
    AppLogger.log('BackupUtils: Auto-backup frequency (days): $autoBackupFrequency');
    AppLogger.log('BackupUtils: Current time: $now');
    AppLogger.log('BackupUtils: Required interval: $requiredInterval');
    AppLogger.log('BackupUtils: Time elapsed since last backup: $timeElapsed');
    AppLogger.log('BackupUtils: No backup files present: $noBackupFiles');

    // For warning: check if SharedPreferences timestamp exists but no file is found
    final lastBackupTimestampPrefs = prefs.getInt('lastAutoBackupTimestamp');
    if (noBackupFiles && lastBackupTimestampPrefs != null && lastBackupTimestampPrefs > 0) {
      final lastPrefsDate = DateTime.fromMillisecondsSinceEpoch(lastBackupTimestampPrefs);
      AppLogger.log('BackupUtils: WARNING: lastAutoBackupTimestamp in prefs is $lastPrefsDate, but no backup file found. Triggering new backup.');
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Warning: Last backup file missing (expected at $lastPrefsDate). Creating new backup.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // Decide if backup is needed
    final shouldBackup = noBackupFiles || (timeElapsed != null && timeElapsed > requiredInterval);
    if (shouldBackup) {
      AppLogger.log('BackupUtils: Auto-backup condition met (no backups or interval exceeded). Triggering backup.');
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Auto-backup starting in a few seconds...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 3));
      try {
        final backupService = BackupRestoreService(MusicPieceRepository(), prefs);
        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        await backupService.triggerAutoBackup(autoBackupCount, messenger: messenger);
        // Update the lastAutoBackupTimestamp in prefs for user info/warning only
        await prefs.setInt('lastAutoBackupTimestamp', now.millisecondsSinceEpoch);
        AppLogger.log('BackupUtils: Updated lastAutoBackupTimestamp to: ${now.millisecondsSinceEpoch}');
        AppLogger.log('BackupUtils: Auto-backup completed successfully.');
        if (messenger != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Auto-backup completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        AppLogger.log('BackupUtils: Auto-backup failed: $e');
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Auto-backup failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      AppLogger.log('BackupUtils: Auto-backup condition not met. Time elapsed: $timeElapsed, Required: $requiredInterval');
    }
  } else {
    AppLogger.log('BackupUtils: Auto-backup is disabled in settings.');
  }
}

/// Gets the time since last auto-backup by parsing the backup folder files
/// This provides more accurate information than relying on saved timestamps
Future<Duration?> getTimeSinceLastAutoBackup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final appStoragePath = prefs.getString('appStoragePath');
    if (appStoragePath == null || appStoragePath.isEmpty) {
      AppLogger.log('BackupUtils: No appStoragePath configured');
      return null;
    }
    final backupDir = p.join(appStoragePath, 'Backups', 'Autobackups');
    final directory = Directory(backupDir);
    if (!await directory.exists()) {
      AppLogger.log('BackupUtils: Auto-backup directory does not exist: $backupDir');
      return null;
    }
    final files = await directory.list().toList();
    final backupFiles = files.where((entity) =>
      entity is File &&
      entity.path.endsWith('.zip') &&
      p.basename(entity.path).startsWith('auto_backup_')
    ).cast<File>().toList();
    if (backupFiles.isEmpty) {
      AppLogger.log('BackupUtils: No auto-backup files found');
      return null;
    }
    final lastBackupTime = await _getLatestBackupDateFromFilenames(backupFiles);
    final now = DateTime.now();
    AppLogger.log('BackupUtils: Last auto-backup file (from filename): $lastBackupTime');
    return now.difference(lastBackupTime!);
  } catch (e) {
    AppLogger.log('BackupUtils: Error getting time since last auto-backup: $e');
    return null;
  }
}

/// Gets the last auto-backup timestamp from file names for best accuracy
Future<DateTime?> getLastAutoBackupTimestamp() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final appStoragePath = prefs.getString('appStoragePath');
    
    if (appStoragePath == null || appStoragePath.isEmpty) {
      return null;
    }
    
    final directory = Directory(p.join(appStoragePath, 'Backups', 'Autobackups'));
    if (!await directory.exists()) {
      return null;
    }
    
    // Get all files in the backup directory
    final files = await directory.list().toList();
    final backupFiles = files.where((entity) => 
      entity is File && 
      entity.path.endsWith('.zip') &&
      p.basename(entity.path).startsWith('auto_backup_')
    ).cast<File>().toList();
    
    if (backupFiles.isEmpty) {
      return null;
    }
    
    // Sort files by modification time (newest first)
    backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    final lastBackupFile = backupFiles.first;
    return await lastBackupFile.lastModified();
  } catch (e) {
    AppLogger.log('BackupUtils: Error getting last auto-backup timestamp: $e');
    return null;
  }
}