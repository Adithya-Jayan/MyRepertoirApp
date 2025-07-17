import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/utils/app_logger.dart';

/// Initiates an automatic backup of music piece data if enabled by the user
/// and if the defined backup frequency interval has passed.
///
/// This function checks user preferences for auto-backup, determines if a backup
/// is due, fetches music piece data, serializes it to JSON, and saves it
/// to a designated auto-backup directory within the app's storage path.
/// It also manages the number of backup files, deleting older ones to
/// maintain a specified count.
Future<void> triggerAutoBackup() async {
  AppLogger.log('Checking auto-backup conditions.');
  // Obtain an instance of SharedPreferences to access user preferences.
  final prefs = await SharedPreferences.getInstance();
  // Check if auto-backup is enabled by the user (defaults to false if not set).
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
  AppLogger.log('Auto-backup enabled: $autoBackupEnabled');

  if (autoBackupEnabled) {
    // Retrieve the timestamp of the last auto-backup (defaults to 0 if not set).
    final lastBackupTimestamp = prefs.getInt('lastAutoBackupTimestamp') ?? 0;
    // Retrieve the auto-backup frequency in days (defaults to 7 days if not set).
    final autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
    // Get the current time in milliseconds since epoch.
    final now = DateTime.now().millisecondsSinceEpoch;

    AppLogger.log('Last backup timestamp: $lastBackupTimestamp');
    AppLogger.log('Auto-backup frequency (days): $autoBackupFrequency');
    AppLogger.log('Current time: $now');

    // Check if the time elapsed since the last backup exceeds the auto-backup frequency.
    // Frequency is converted from days to milliseconds.
    final requiredInterval = autoBackupFrequency * 24 * 60 * 60 * 1000;
    final timeElapsed = now - lastBackupTimestamp;
    AppLogger.log('Required interval (ms): $requiredInterval');
    AppLogger.log('Time elapsed since last backup (ms): $timeElapsed');

    if (timeElapsed > requiredInterval) {
      AppLogger.log('Auto-backup condition met. Triggering backup.');
      // Initialize MusicPieceRepository to fetch music piece data.
      final MusicPieceRepository repository = MusicPieceRepository();
      // Retrieve all music pieces from the database.
      final musicPieces = await repository.getMusicPieces();
      // Encode the list of music pieces into a JSON string.
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      // Format the current timestamp for use in the backup file name.
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      // Construct the backup file name.
      final fileName = 'music_repertoire_backup_$timestamp.json';

      // Retrieve the user-selected application storage path.
      final storagePath = prefs.getString('appStoragePath');
      if (storagePath != null) {
        // Define the directory for auto-backups within the storage path.
        final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
        // Create the auto-backup directory if it doesn't exist, including any necessary parent directories.
        if (!await autoBackupDir.exists()) {
          await autoBackupDir.create(recursive: true);
        }
        // Define the full path for the new backup file.
        final outputFile = File(p.join(autoBackupDir.path, fileName));
        // Write the JSON string content to the backup file.
        await outputFile.writeAsBytes(utf8.encode(jsonString));
        // Update the last auto-backup timestamp in SharedPreferences.
        await prefs.setInt('lastAutoBackupTimestamp', now);
        AppLogger.log('Updated lastAutoBackupTimestamp to: $now');

        // Retrieve the maximum number of auto-backup files to keep (defaults to 5).
        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        // Get a list of all files in the auto-backup directory.
        final files = await autoBackupDir.list().toList();
        // Sort files by their modification time to identify the oldest ones.
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        // If the number of backup files exceeds the allowed count, delete the oldest ones.
        if (files.length > autoBackupCount) {
          AppLogger.log('Number of auto-backup files (${files.length}) exceeds limit ($autoBackupCount). Deleting oldest.');
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            AppLogger.log('Deleting old auto-backup file: ${files[i].path}');
            await files[i].delete();
          }
        }
      } else {
        AppLogger.log('Storage path is null. Auto-backup skipped.');
      }
    } else {
      AppLogger.log('Auto-backup condition not met. Time elapsed: $timeElapsed, Required: $requiredInterval');
    }
  } else {
    AppLogger.log('Auto-backup is disabled in settings.');
  }
}