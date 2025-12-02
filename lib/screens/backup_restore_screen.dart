import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart' as utils;
import '../database/music_piece_repository.dart';
import '../services/backup_restore_service.dart';
import '../utils/backup_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;

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
  double _autoBackupFrequency = 7.0;
  int _autoBackupCount = 5;
  String _currentStoragePath = '';
  bool _isInitializing = true;
  String? _initializationError;

  // Controllers to prevent TextField rebuilds
  late TextEditingController _frequencyController;
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _frequencyController = TextEditingController();
    _countController = TextEditingController();
    _initializeServiceAndSettings();
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _initializeServiceAndSettings() async {
    try {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });

      final prefs = await SharedPreferences.getInstance();
      _backupRestoreService = BackupRestoreService(MusicPieceRepository(), prefs);
      
      await _loadAutoBackupSettings();
      
      setState(() {
        _currentStoragePath = prefs.getString('appStoragePath') ?? _getDefaultStoragePath();
        _isInitializing = false;
      });
      
      utils.AppLogger.log('BackupRestoreScreen: Initialization completed successfully');
    } catch (e) {
      utils.AppLogger.log('BackupRestoreScreen: Initialization error: $e');
      setState(() {
        _initializationError = e.toString();
        _isInitializing = false;
      });
    }
  }

  /// Gets the default storage path based on platform
  String _getDefaultStoragePath() {
    if (kIsWeb) {
      return 'Browser Downloads';
    } else if (Platform.isWindows) {
      return 'Documents/RepertoireApp';
    } else if (Platform.isAndroid) {
      return 'Internal Storage/RepertoireApp';
    } else if (Platform.isIOS) {
      return 'App Documents';
    } else if (Platform.isMacOS) {
      return 'Documents/RepertoireApp';
    } else if (Platform.isLinux) {
      return 'Home/RepertoireApp';
    }
    return 'Not set';
  }

  /// Loads the saved automatic backup settings from [SharedPreferences].
  Future<void> _loadAutoBackupSettings() async {
    final prefs = _backupRestoreService.prefs;
    
    _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
    _autoBackupFrequency = prefs.getDouble('autoBackupFrequency') ?? 7.0;
    _autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;

    // Update controllers with current values
    _frequencyController.text = _autoBackupFrequency.toString();
    _countController.text = _autoBackupCount.toString();
  }

  /// Saves the current automatic backup settings to [SharedPreferences].
  Future<void> _saveAutoBackupSettings() async {
    try {
      await _backupRestoreService.prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
      await _backupRestoreService.prefs.setDouble('autoBackupFrequency', _autoBackupFrequency);
      await _backupRestoreService.prefs.setInt('autoBackupCount', _autoBackupCount);
      utils.AppLogger.log('BackupRestoreScreen: Auto backup settings saved');
    } catch (e) {
      utils.AppLogger.log('BackupRestoreScreen: Error saving auto backup settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Backup & Restore'),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing backup settings...'),
          ],
        ),
      );
    }

    if (_initializationError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Failed to initialize backup settings'),
            const SizedBox(height: 8),
            Text(_initializationError!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeServiceAndSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildBackupRestoreSection(),
        const SizedBox(height: 16),
        _buildStorageSection(),
        const SizedBox(height: 16),
        _buildAutoBackupSection(),
      ],
    );
  }

  Widget _buildBackupRestoreSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Manual Backup & Restore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Local Backup'),
            subtitle: const Text('Create a backup of all your data'),
            onTap: () async {
              try {
                await _backupRestoreService.backupData(manual: true, messenger: ScaffoldMessenger.of(context));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup failed: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from Local Backup'),
            subtitle: const Text('Restore data from a previous backup'),
            onTap: () async {
              try {
                utils.AppLogger.log('BackupRestoreScreen: Starting restore process');
                await _backupRestoreService.restoreData(context: context);
                if (mounted) {
                  utils.AppLogger.log('BackupRestoreScreen: Restore completed, navigating back with refresh flag');
                  Navigator.of(context).pop(true); // Pass true to indicate data was restored
                }
              } catch (e) {
                utils.AppLogger.log('BackupRestoreScreen: Restore error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Storage Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Change Storage Folder'),
            subtitle: Text(_currentStoragePath),
            onTap: _canChangeStorageFolder() ? _changeStorageFolder : null,
            trailing: _canChangeStorageFolder() 
                ? const Icon(Icons.arrow_forward_ios) 
                : const Icon(Icons.info_outline, color: Colors.grey),
          ),
          if (!_canChangeStorageFolder())
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Storage folder selection not available on this platform',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Automatic Backups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Automatic Backups'),
            subtitle: const Text('Automatically create backups at regular intervals'),
            value: _autoBackupEnabled,
            onChanged: (value) {
              setState(() {
                _autoBackupEnabled = value;
              });
              _saveAutoBackupSettings();
            },
          ),
          if (_autoBackupEnabled) ...[
            const Divider(height: 1),
            ListTile(
              title: const Text('Backup Frequency (days)'),
              subtitle: const Text('How often to create automatic backups'),
              trailing: SizedBox(
                width: 80,
                child: TextField(
                  controller: _frequencyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onSubmitted: (value) {
                    final newValue = double.tryParse(value);
                    if (newValue != null && newValue > 0) {
                      _autoBackupFrequency = newValue;
                      _saveAutoBackupSettings();
                    } else {
                      _frequencyController.text = _autoBackupFrequency.toString();
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Number of Backups to Keep'),
              subtitle: const Text('Maximum number of automatic backups to retain'),
              trailing: SizedBox(
                width: 60,
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onSubmitted: (value) {
                    final newValue = int.tryParse(value);
                    if (newValue != null && newValue > 0) {
                      _autoBackupCount = newValue;
                      _saveAutoBackupSettings();
                    } else {
                      _countController.text = _autoBackupCount.toString();
                    }
                  },
                ),
              ),
            ),
            FutureBuilder<Duration?>(
              future: getTimeSinceLastAutoBackup(),
              builder: (context, snapshot) {
                String timeSinceLastBackup = 'Never';
                Color? textColor;
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  timeSinceLastBackup = 'Loading...';
                } else if (snapshot.hasError) {
                  timeSinceLastBackup = 'Error loading';
                  textColor = Colors.red;
                } else if (snapshot.hasData && snapshot.data != null) {
                  final duration = snapshot.data!;
                  if (duration.inDays > 0) {
                    timeSinceLastBackup = '${duration.inDays} days ago';
                    if (duration.inDays > _autoBackupFrequency) {
                      textColor = Colors.orange;
                    }
                  } else if (duration.inHours > 0) {
                    timeSinceLastBackup = '${duration.inHours} hours ago';
                  } else if (duration.inMinutes > 0) {
                    timeSinceLastBackup = '${duration.inMinutes} minutes ago';
                  } else {
                    timeSinceLastBackup = 'Just now';
                    textColor = Colors.green;
                  }
                }
                
                return ListTile(
                  title: const Text('Last Automatic Backup'),
                  subtitle: Text(
                    timeSinceLastBackup,
                    style: TextStyle(color: textColor),
                  ),
                  leading: const Icon(Icons.access_time),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Run Auto-backup Now'),
              subtitle: const Text('Manually trigger an automatic backup'),
              onTap: () async {
                try {
                  await _backupRestoreService.triggerAutoBackup(_autoBackupCount, messenger: ScaffoldMessenger.of(context));
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auto-backup failed: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Check if storage folder can be changed on this platform
  bool _canChangeStorageFolder() {
    return !kIsWeb && (Platform.isWindows || Platform.isAndroid || Platform.isMacOS || Platform.isLinux);
  }

  Future<void> _changeStorageFolder() async {
    if (!_canChangeStorageFolder()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage folder selection not available on this platform')),
      );
      return;
    }

    try {
      utils.AppLogger.log('Attempting to change storage folder.');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Opening folder selector...'),
            ],
          ),
        ),
      );

      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (selectedDirectory != null) {
        utils.AppLogger.log('Selected new storage directory: $selectedDirectory');
        await _backupRestoreService.prefs.setString('appStoragePath', selectedDirectory);
        
        // Reinitialize the logger with the new storage path
        await utils.AppLogger.reinitialize();
        
        setState(() {
          _currentStoragePath = selectedDirectory;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage folder updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        utils.AppLogger.log('Storage folder updated successfully.');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder selection cancelled')),
          );
        }
        utils.AppLogger.log('Storage folder selection cancelled.');
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      
      utils.AppLogger.log('Error changing storage folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing storage folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}