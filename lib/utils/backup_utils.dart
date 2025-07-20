import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
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
Future<void> triggerAutoBackup({BuildContext? context}) async {
  AppLogger.log('BackupUtils: Checking auto-backup conditions.');
  // Obtain an instance of SharedPreferences to access user preferences.
  final prefs = await SharedPreferences.getInstance();
  // Check if auto-backup is enabled by the user (defaults to false if not set).
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
  AppLogger.log('BackupUtils: Auto-backup enabled: $autoBackupEnabled');

  if (autoBackupEnabled) {
    // Retrieve the timestamp of the last auto-backup (defaults to 0 if not set).
    final lastBackupTimestamp = prefs.getInt('lastAutoBackupTimestamp') ?? 0;
    // Retrieve the auto-backup frequency in days (defaults to 7 days if not set).
    final autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
    // Get the current time in milliseconds since epoch.
    final now = DateTime.now().millisecondsSinceEpoch;

    AppLogger.log('BackupUtils: Last backup timestamp: $lastBackupTimestamp');
    AppLogger.log('BackupUtils: Auto-backup frequency (days): $autoBackupFrequency');
    AppLogger.log('BackupUtils: Current time: $now');

    // Check if the time elapsed since the last backup exceeds the auto-backup frequency.
    // Frequency is converted from days to milliseconds.
    final requiredInterval = autoBackupFrequency * 24 * 60 * 60 * 1000;
    final timeElapsed = now - lastBackupTimestamp;
    AppLogger.log('BackupUtils: Required interval (ms): $requiredInterval');
    AppLogger.log('BackupUtils: Time elapsed since last backup (ms): $timeElapsed');

    if (timeElapsed > requiredInterval) {
      AppLogger.log('BackupUtils: Auto-backup condition met. Triggering backup.');
      
      // Show backup started banner
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-backup starting in a few seconds...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Delay backup creation by a few seconds to give app time to load
      await Future.delayed(const Duration(seconds: 3));
      
      try {
        // Use the BackupRestoreService for consistent backup format
        final backupService = BackupRestoreService(MusicPieceRepository(), prefs);
        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        
        // Trigger the automatic backup
        await backupService.triggerAutoBackup(autoBackupCount, context: context);
        
        // Update the last auto-backup timestamp in SharedPreferences.
        await prefs.setInt('lastAutoBackupTimestamp', now);
        AppLogger.log('BackupUtils: Updated lastAutoBackupTimestamp to: $now');
        AppLogger.log('BackupUtils: Auto-backup completed successfully.');
        
        // Show backup completed banner
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-backup completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        AppLogger.log('BackupUtils: Auto-backup failed: $e');
        
        // Show backup failed banner
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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