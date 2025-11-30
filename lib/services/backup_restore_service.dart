import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../database/music_piece_repository.dart';
import 'backup/backup_manager.dart';
import 'backup/restore_manager.dart';

class BackupRestoreService {
  final MusicPieceRepository _repository;
  final SharedPreferences prefs;
  late final BackupManager _backupManager;
  late final RestoreManager _restoreManager;

  BackupRestoreService(this._repository, this.prefs) {
    _backupManager = BackupManager(_repository, prefs);
    _restoreManager = RestoreManager(_repository, prefs);
  }

  /// Initiates a backup of application data (music pieces and media files).
  ///
  /// If `manual` is true, it prompts the user for a save location. Otherwise,
  /// it performs an automatic backup to a predefined location.
  Future<void> backupData({bool manual = true, ScaffoldMessengerState? messenger}) async {
    await _backupManager.performBackup(manual: manual, messenger: messenger);
  }

  /// Triggers an automatic backup process.
  ///
  /// This function calls `backupData` with `manual` set to false,
  /// and then manages the number of automatic backup files, deleting older ones
  /// if the count exceeds the configured limit.
  Future<void> triggerAutoBackup(int autoBackupCount, {ScaffoldMessengerState? messenger}) async {
    AppLogger.log('BackupRestoreService: Performing auto-backup. Retaining $autoBackupCount backups.');

    // Perform a backup
    await _backupManager.performBackup(manual: false, messenger: messenger);

    // Clean up old backups
    await _backupManager.cleanupOldBackups(autoBackupCount);
  }

  Future<bool> restoreData({BuildContext? context, String? filePath, bool isFreshRestore = false, bool shouldPop = true}) async {
    return await _restoreManager.performRestore(context: context, filePath: filePath, isFreshRestore: isFreshRestore, shouldPop: shouldPop);
  }
} 