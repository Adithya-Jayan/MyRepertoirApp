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
  Future<void> backupData({bool manual = true, BuildContext? context}) async {
    await _backupManager.performBackup(manual: manual, context: context);
  }

  /// Triggers an automatic backup process.
  ///
  /// This function calls `backupData` with `manual` set to false,
  /// and then manages the number of automatic backup files, deleting older ones
  /// if the count exceeds the configured limit.
  Future<void> triggerAutoBackup(int autoBackupCount, {BuildContext? context}) async {
    AppLogger.log('Triggering automatic backup.');
    await backupData(manual: false, context: context);
    await _backupManager.cleanupOldBackups(autoBackupCount);
  }

  Future<void> restoreData({BuildContext? context}) async {
    await _restoreManager.performRestore(context: context);
  }
} 