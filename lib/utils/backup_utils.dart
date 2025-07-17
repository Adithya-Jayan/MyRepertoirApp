import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/utils/app_logger.dart';

Future<void> triggerAutoBackup() async {
  AppLogger.log('Checking auto-backup conditions.');
  final prefs = await SharedPreferences.getInstance();
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
  AppLogger.log('Auto-backup enabled: $autoBackupEnabled');

  if (autoBackupEnabled) {
    final lastBackupTimestamp = prefs.getInt('lastAutoBackupTimestamp') ?? 0;
    final autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
    final now = DateTime.now().millisecondsSinceEpoch;

    AppLogger.log('Last backup timestamp: $lastBackupTimestamp');
    AppLogger.log('Auto-backup frequency (days): $autoBackupFrequency');
    AppLogger.log('Current time: $now');

    final requiredInterval = autoBackupFrequency * 24 * 60 * 60 * 1000;
    final timeElapsed = now - lastBackupTimestamp;
    AppLogger.log('Required interval (ms): $requiredInterval');
    AppLogger.log('Time elapsed since last backup (ms): $timeElapsed');

    if (timeElapsed > requiredInterval) {
      AppLogger.log('Auto-backup condition met. Triggering backup.');
      final MusicPieceRepository repository = MusicPieceRepository();
      final musicPieces = await repository.getMusicPieces();
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'music_repertoire_backup_$timestamp.json';

      final storagePath = prefs.getString('appStoragePath');
      if (storagePath != null) {
        final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
        if (!await autoBackupDir.exists()) {
          await autoBackupDir.create(recursive: true);
        }
        final outputFile = File(p.join(autoBackupDir.path, fileName));
        await outputFile.writeAsBytes(utf8.encode(jsonString));
        await prefs.setInt('lastAutoBackupTimestamp', now);
        AppLogger.log('Updated lastAutoBackupTimestamp to: $now');

        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        final files = await autoBackupDir.list().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

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
