import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart' as utils;
import '../database/music_piece_repository.dart';
import '../services/backup_restore_service.dart';
import '../utils/backup_utils.dart';
import 'package:file_picker/file_picker.dart';

/// A screen for managing backup and restore operations of the application data.
///
/// This includes options for manual backup/restore, and configuring automatic backups.
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

/// The state class for [BackupRestoreScreen].
/// Manages the UI and logic for backup and restore functionalities.
class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late BackupRestoreService _backupRestoreService;
  bool _autoBackupEnabled = false;
  int _autoBackupFrequency = 7;
  int _autoBackupCount = 5;

  @override
  void initState() {
    super.initState();
    _initializeServiceAndSettings();
  }

  Future<void> _initializeServiceAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _backupRestoreService = BackupRestoreService(MusicPieceRepository(), prefs);
    _loadAutoBackupSettings();
  }

  /// Loads the saved automatic backup settings from [SharedPreferences].
  void _loadAutoBackupSettings() {
    setState(() {
      _autoBackupEnabled = _backupRestoreService.prefs.getBool('autoBackupEnabled') ?? false;
      _autoBackupFrequency = _backupRestoreService.prefs.getInt('autoBackupFrequency') ?? 7;
      _autoBackupCount = _backupRestoreService.prefs.getInt('autoBackupCount') ?? 5;
    });
  }

  /// Saves the current automatic backup settings to [SharedPreferences].
  Future<void> _saveAutoBackupSettings() async {
    await _backupRestoreService.prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
    await _backupRestoreService.prefs.setInt('autoBackupFrequency', _autoBackupFrequency);
    await _backupRestoreService.prefs.setInt('autoBackupCount', _autoBackupCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Local Backup'),
            onTap: () => _backupRestoreService.backupData(manual: true, context: context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from Local Backup'),
            onTap: () async {
              utils.AppLogger.log('BackupRestoreScreen: Starting restore process');
              await _backupRestoreService.restoreData(context: context);
              if (mounted) {
                utils.AppLogger.log('BackupRestoreScreen: Restore completed, navigating back with refresh flag');
                final currentContext = context;
                Navigator.of(currentContext).pop(true); // Pass true to indicate data was restored
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Change Storage Folder'),
            onTap: _changeStorageFolder,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Automatic Backups'),
            value: _autoBackupEnabled,
            onChanged: (value) {
              setState(() {
                _autoBackupEnabled = value;
              });
              _saveAutoBackupSettings();
            },
          ),
          if (_autoBackupEnabled) ...[
            ListTile(
              title: const Text('Backup Frequency (days)'),
              trailing: SizedBox(
                width: 50,
                child: TextField(
                  controller: TextEditingController(text: _autoBackupFrequency.toString()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _autoBackupFrequency = int.tryParse(value) ?? 7;
                    _saveAutoBackupSettings();
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Number of Backups to Keep'),
              trailing: SizedBox(
                width: 50,
                child: TextField(
                  controller: TextEditingController(text: _autoBackupCount.toString()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _autoBackupCount = int.tryParse(value) ?? 5;
                    _saveAutoBackupSettings();
                  },
                ),
              ),
            ),
            FutureBuilder<Duration?>(
              future: getTimeSinceLastAutoBackup(),
              builder: (context, snapshot) {
                String timeSinceLastBackup = 'Unknown';
                if (snapshot.hasData && snapshot.data != null) {
                  final duration = snapshot.data!;
                  if (duration.inDays > 0) {
                    timeSinceLastBackup = '${duration.inDays} days ago';
                  } else if (duration.inHours > 0) {
                    timeSinceLastBackup = '${duration.inHours} hours ago';
                  } else if (duration.inMinutes > 0) {
                    timeSinceLastBackup = '${duration.inMinutes} minutes ago';
                  } else {
                    timeSinceLastBackup = 'Just now';
                  }
                } else if (snapshot.hasError) {
                  timeSinceLastBackup = 'Error loading';
                }
                
                return ListTile(
                  title: const Text('Time Since Last Auto-Backup'),
                  subtitle: Text(timeSinceLastBackup),
                  leading: const Icon(Icons.access_time),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Trigger Autobackup Now'),
              onTap: () => _backupRestoreService.triggerAutoBackup(_autoBackupCount, context: context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changeStorageFolder() async {
    utils.AppLogger.log('Attempting to change storage folder.');
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      utils.AppLogger.log('Selected new storage directory: $selectedDirectory');
      await _backupRestoreService.prefs.setString('appStoragePath', selectedDirectory);
      
      // Reinitialize the logger with the new storage path
      await utils.AppLogger.reinitialize();
      
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Storage folder updated to: $selectedDirectory')),
      );
      utils.AppLogger.log('Storage folder updated successfully.');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder selection cancelled.')),
      );
      utils.AppLogger.log('Storage folder selection cancelled.');
    }
  }
}
