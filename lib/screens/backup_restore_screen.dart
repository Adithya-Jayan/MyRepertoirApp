import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';
import '../models/tag.dart'; // Import Tag model
import '../models/group.dart'; // Import Group model
import '../models/tag.dart'; // Import Tag model
import '../models/group.dart'; // Import Group model

import 'package:intl/intl.dart';

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
  final MusicPieceRepository _repository = MusicPieceRepository(); // Repository for music piece data operations.
  bool _autoBackupEnabled = false; // State variable to track if automatic backups are enabled.
  int _autoBackupFrequency = 7; // State variable for the frequency of automatic backups in days.
  int _autoBackupCount = 5; // State variable for the number of automatic backups to keep.

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSettings(); // Load the saved automatic backup settings when the screen initializes.
  }

  /// Loads the saved automatic backup settings from [SharedPreferences].
  Future<void> _loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false; // Load auto-backup enabled status.
      _autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7; // Load auto-backup frequency.
      _autoBackupCount = prefs.getInt('autoBackupCount') ?? 5; // Load auto-backup count.
    });
  }

  /// Saves the current automatic backup settings to [SharedPreferences].
  Future<void> _saveAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled); // Save auto-backup enabled status.
    await prefs.setInt('autoBackupFrequency', _autoBackupFrequency); // Save auto-backup frequency.
    await prefs.setInt('autoBackupCount', _autoBackupCount); // Save auto-backup count.
  }

  /// Initiates a backup of application data (music pieces and media files).
  ///
  /// If `manual` is true, it prompts the user for a save location. Otherwise,
  /// it performs an automatic backup to a predefined location.
  Future<void> _backupData({bool manual = true}) async {
    AppLogger.log('Initiating backup (manual: $manual).');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up data...')) // Show a snackbar indicating backup in progress.
    );
    try {
      final musicPieces = await _repository.getMusicPieces(); // Fetch all music pieces.
      final tags = await _repository.getTags(); // Fetch all tags.
      final groups = await _repository.getGroups(); // Fetch all groups.

      final data = {
        'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
      };
      final jsonString = jsonEncode(data); // Convert all data to JSON string.
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()); // Generate a timestamp for the backup file name.
      final fileName = 'music_repertoire_backup_$timestamp.zip'; // Construct the backup file name.

      final prefs = await SharedPreferences.getInstance();
      final storagePath = prefs.getString('appStoragePath'); // Get the application's storage path.
      if (storagePath == null) {
        AppLogger.log('Backup failed: Storage path not configured.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage path not configured.')) // Show error if storage path is not set.
        );
        return;
      }
      AppLogger.log('Storage path: $storagePath');

      final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups'); // Determine backup subdirectory.
      final backupDirectory = Directory(p.join(storagePath, backupSubDir)); // Construct the full backup directory path.
      AppLogger.log('Backup directory: ${backupDirectory.path}');
      if (!await backupDirectory.exists()) {
        AppLogger.log('Creating backup directory: ${backupDirectory.path}');
        await backupDirectory.create(recursive: true); // Create backup directory if it doesn't exist.
      }

      // Create a temporary directory for the zip file
      final tempDir = await getTemporaryDirectory();
      final tempZipPath = p.join(tempDir.path, fileName);
      AppLogger.log('Temporary zip path: $tempZipPath');

      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);
      AppLogger.log('Zip encoder created.');

      // Add the JSON data as a file within the zip archive.
      final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
      encoder.addArchiveFile(jsonArchiveFile);
      AppLogger.log('JSON data added to zip.');

      final mediaDir = Directory(p.join(storagePath, 'media'));
      if (await mediaDir.exists()) {
        AppLogger.log('Adding media directory to zip: ${mediaDir.path}');
        // Add the entire media directory to the zip archive.
        encoder.addDirectory(mediaDir, includeDirName: false);
      }

      encoder.close(); // Close the zip encoder.
      AppLogger.log('Zip encoder closed.');

      final zipBytes = await File(tempZipPath).readAsBytes(); // Read the complete zip file bytes
      AppLogger.log('Zip bytes read from temporary file.');

      if (manual) {
        AppLogger.log('Handling manual backup save.');
        String? outputFile;
        if (Platform.isAndroid || Platform.isIOS) {
          // On mobile, pass the bytes to `saveFile`. FilePicker handles the actual saving.
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            bytes: zipBytes,
            initialDirectory: backupDirectory.path, // Still try to set initial directory for mobile
          );
          AppLogger.log('FilePicker.saveFile (mobile) returned: $outputFile');
          // If outputFile is not null, it means the user selected a location and FilePicker saved the bytes.
          // No need to write again using dart:io.
          if (outputFile != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data backed up successfully!')) // Show success message for manual backup.
            );
            AppLogger.log('Manual backup successful.');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup cancelled.')) // Show message if backup is cancelled.
            );
            AppLogger.log('Manual backup cancelled by user.');
          }
        } else {
          // Desktop logic: FilePicker returns a path, then we write the bytes to it.
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            initialDirectory: backupDirectory.path,
            type: FileType.custom,
            allowedExtensions: ['zip'],
          );
          AppLogger.log('FilePicker.saveFile (desktop) returned: $outputFile');
          if (outputFile != null) {
            // Ensure the directory exists before writing the file for desktop
            final outputDirectory = Directory(p.dirname(outputFile));
            if (!await outputDirectory.exists()) {
              AppLogger.log('Creating output directory for desktop: ${outputDirectory.path}');
              await outputDirectory.create(recursive: true);
            }
            await File(outputFile).writeAsBytes(zipBytes); // Write the zip bytes to the chosen location
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data backed up successfully!')) // Show success message for manual backup.
            );
            AppLogger.log('Manual backup successful.');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup cancelled.')) // Show message if backup is cancelled.
            );
            AppLogger.log('Manual backup cancelled by user.');
          }
        }
      } else {
        AppLogger.log('Handling automatic backup save.');
        // Automatic backup logic
        final zipFile = File(p.join(backupDirectory.path, fileName));
        await zipFile.writeAsBytes(zipBytes); // Write the zip bytes to the auto-backup location

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autobackup successful!')) // Show success message for automatic backup.
        );
        AppLogger.log('Autobackup successful.');
      }

      // Clean up the temporary zip file
      AppLogger.log('Deleting temporary zip file: $tempZipPath');
      await File(tempZipPath).delete();
    } catch (e) {
      AppLogger.log('Backup failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')) // Show error message if backup fails.
      );
    }
  }

  /// Triggers an automatic backup process.
  ///
  /// This function calls `_backupData` with `manual` set to false,
  /// and then manages the number of automatic backup files, deleting older ones
  /// if the count exceeds the configured limit.
  Future<void> _triggerAutoBackup() async {
    AppLogger.log('Triggering automatic backup.');
    await _backupData(manual: false); // Perform an automatic backup.
    final prefs = await SharedPreferences.getInstance();
    final storagePath = prefs.getString('appStoragePath');
    if (storagePath != null) {
      final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
      if (await autoBackupDir.exists()) {
        AppLogger.log('Auto-backup directory exists: ${autoBackupDir.path}');
        final files = await autoBackupDir.list().toList(); // Get all files in the auto-backup directory.
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified)); // Sort files by modification time.
        AppLogger.log('Found ${files.length} auto-backup files.');
        if (files.length > _autoBackupCount) {
          AppLogger.log('Deleting old auto-backup files. Keeping ${_autoBackupCount}.');
          for (int i = 0; i < files.length - _autoBackupCount; i++) {
            AppLogger.log('Deleting: ${files[i].path}');
            await files[i].delete(); // Delete older backup files if the count exceeds the limit.
          }
        }
      }
    }
  }

  Future<void> _restoreData() async {
    AppLogger.log('Initiating data restore.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring data...'))
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final storagePath = prefs.getString('appStoragePath');
      String? backupDir;
      if (storagePath != null) {
        final backupsDir = Directory(p.join(storagePath, 'Backups'));
        if (await backupsDir.exists()) {
          backupDir = backupsDir.path;
          AppLogger.log('Default restore directory: ${backupDir}');
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        initialDirectory: backupDir,
      );
      AppLogger.log('FilePicker.pickFiles returned: ${result?.files.single.path}');

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!); 
        final inputStream = InputFileStream(result.files.single.path!); // Use InputFileStream for reading zip
        final archive = ZipDecoder().decodeBuffer(inputStream);
        AppLogger.log('Backup file decoded.');

        final jsonFile = archive.findFile('music_repertoire.json');
        if (jsonFile == null) {
          AppLogger.log('Restore failed: music_repertoire.json not found in backup.');
          throw Exception('Invalid backup file: music_repertoire.json not found.');
        }

        final jsonString = utf8.decode(jsonFile.content);
        final Map<String, dynamic> data = jsonDecode(jsonString);
        AppLogger.log('JSON data extracted from backup.');

        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];
        final List<dynamic> groupsJson = data['groups'] ?? [];

        // --- NEW LOGIC FOR GROUPS ---
        // 1. Store existing groups before clearing
        final List<Group> oldGroupsBeforeRestore = await _repository.getGroups();
        AppLogger.log('Fetched ${oldGroupsBeforeRestore.length} old groups before restore.');

        // Restore Music Pieces
        await _repository.deleteAllMusicPieces(); // Clear existing music pieces.
        AppLogger.log('Deleted all existing music pieces.');
        for (var pieceJson in musicPiecesJson) {
          final piece = MusicPiece.fromJson(pieceJson);
          await _repository.insertMusicPiece(piece);
        }
        AppLogger.log('Restored ${musicPiecesJson.length} music pieces.');

        // Restore Tags
        await _repository.deleteAllTags(); // Clear existing tags.
        AppLogger.log('Deleted all existing tags.');
        for (var tagJson in tagsJson) {
          final tag = Tag.fromJson(tagJson);
          await _repository.insertTag(tag);
        }
        AppLogger.log('Restored ${tagsJson.length} tags.');

        // Restore Groups from backup
        await _repository.deleteAllGroups(); // Clear existing groups.
        AppLogger.log('Deleted all existing groups.');
        for (var groupJson in groupsJson) {
          final group = Group.fromJson(groupJson);
          await _repository.createGroup(group); // Use createGroup which handles insert/replace
        }
        AppLogger.log('Restored ${groupsJson.length} groups from backup.');

        // 2. Re-add old groups that were not in the restored backup
        final List<Group> currentGroupsAfterRestore = await _repository.getGroups();
        final Set<String> currentGroupIds = currentGroupsAfterRestore.map((g) => g.id).toSet();
        AppLogger.log('Current groups after restore: ${currentGroupIds.length}');

        int nextOrder = currentGroupsAfterRestore.length; // Determine the starting order for new groups

        for (final oldGroup in oldGroupsBeforeRestore) {
          if (!currentGroupIds.contains(oldGroup.id)) {
            // This old group was not in the backup, re-add it
            final newOrder = nextOrder++;
            final groupToReAdd = oldGroup.copyWith(order: newOrder);
            await _repository.createGroup(groupToReAdd); // Re-add with updated order
            AppLogger.log('Re-added old group: ${groupToReAdd.name}');
          }
        }
        AppLogger.log('Finished re-adding old groups.');
        // --- END NEW LOGIC FOR GROUPS ---

        final mediaDir = Directory(p.join(storagePath!, 'media'));
        AppLogger.log('Media directory for restore: ${mediaDir.path}');
        if (await mediaDir.exists()) {
          AppLogger.log('Deleting existing media directory.');
          await mediaDir.delete(recursive: true);
        }
        AppLogger.log('Creating new media directory.');
        await mediaDir.create(recursive: true);

        for (final file in archive.files) {
          if (file.name.startsWith('media/')) {
            final filePath = p.join(storagePath, file.name);
            AppLogger.log('Extracting media file: ${file.name} to $filePath');
            if (file.isFile) {
              final outputStream = OutputFileStream(filePath);
              outputStream.writeBytes(file.content);
              outputStream.close();
            }
          }
        }
        AppLogger.log('Media files extracted.');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!'))
        );
        AppLogger.log('Data restored successfully.');
        if (mounted) {
          Navigator.of(context).pop(true); // Pop with true to indicate changes for refresh.
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore cancelled.'))
        );
        AppLogger.log('Restore cancelled by user.');
      }
    } catch (e) {
      AppLogger.log('Restore failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e'))
      );
    }
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
            onTap: () => _backupData(manual: true),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from Local Backup'),
            onTap: _restoreData,
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
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Trigger Autobackup Now'),
              onTap: _triggerAutoBackup,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changeStorageFolder() async {
    AppLogger.log('Attempting to change storage folder.');
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      AppLogger.log('Selected new storage directory: $selectedDirectory');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', selectedDirectory);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage folder updated to: $selectedDirectory')),
      );
      AppLogger.log('Storage folder updated successfully.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder selection cancelled.')),
      );
      AppLogger.log('Storage folder selection cancelled.');
    }
  }
}
