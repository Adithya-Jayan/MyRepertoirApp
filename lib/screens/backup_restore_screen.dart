import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up data...')) // Show a snackbar indicating backup in progress.
    );
    try {
      final musicPieces = await _repository.getMusicPieces(); // Fetch all music pieces.
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList()); // Convert music pieces to JSON string.
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()); // Generate a timestamp for the backup file name.
      final fileName = 'music_repertoire_backup_$timestamp.zip'; // Construct the backup file name.

      final prefs = await SharedPreferences.getInstance();
      final storagePath = prefs.getString('appStoragePath'); // Get the application's storage path.
      if (storagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage path not configured.')) // Show error if storage path is not set.
        );
        return;
      }

      final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups'); // Determine backup subdirectory.
      final backupDirectory = Directory(p.join(storagePath, backupSubDir)); // Construct the full backup directory path.
      if (!await backupDirectory.exists()) {
        await backupDirectory.create(recursive: true); // Create backup directory if it doesn't exist.
      }

      final encoder = ZipFileEncoder();
      final zipPath = p.join(backupDirectory.path, fileName);
      encoder.create(zipPath); // Create the zip file.

      // Add the JSON data as a file within the zip archive.
      final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
      encoder.addArchiveFile(jsonArchiveFile);

      final mediaDir = Directory(p.join(storagePath, 'media'));
      if (await mediaDir.exists()) {
        // Add the entire media directory to the zip archive.
        encoder.addDirectory(mediaDir, includeDirName: false);
      }

      encoder.close(); // Close the zip encoder.

      if (manual) {
        String? outputFile;
        if (Platform.isAndroid || Platform.isIOS) {
          // On mobile, we must pass the bytes to `saveFile`.
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            bytes: utf8.encode(jsonString),
          );
        } else {
          // Desktop logic with initial directory.
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            initialDirectory: backupDirectory.path,
            type: FileType.custom,
            allowedExtensions: ['zip'],
          );
        }

        if (outputFile != null) {
          final encoder = ZipFileEncoder();
          encoder.create(outputFile);
          final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
          encoder.addArchiveFile(jsonArchiveFile);

          final mediaDir = Directory(p.join(storagePath, 'media'));
          if (await mediaDir.exists()) {
            encoder.addDirectory(mediaDir, includeDirName: false);
          }
          encoder.close();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data backed up successfully!')) // Show success message for manual backup.
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup cancelled.')) // Show message if backup is cancelled.
          );
        }
      } else {
        // Automatic backup logic
        final encoder = ZipFileEncoder();
        final zipPath = p.join(backupDirectory.path, fileName);
        encoder.create(zipPath);
        final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
        encoder.addArchiveFile(jsonArchiveFile);

        final mediaDir = Directory(p.join(storagePath, 'media'));
        if (await mediaDir.exists()) {
          encoder.addDirectory(mediaDir, includeDirName: false);
        }
        encoder.close();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autobackup successful!')) // Show success message for automatic backup.
        );
      }
    } catch (e) {
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
    await _backupData(manual: false); // Perform an automatic backup.
    final prefs = await SharedPreferences.getInstance();
    final storagePath = prefs.getString('appStoragePath');
    if (storagePath != null) {
      final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
      if (await autoBackupDir.exists()) {
        final files = await autoBackupDir.list().toList(); // Get all files in the auto-backup directory.
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified)); // Sort files by modification time.
        if (files.length > _autoBackupCount) {
          for (int i = 0; i < files.length - _autoBackupCount; i++) {
            await files[i].delete(); // Delete older backup files if the count exceeds the limit.
          }
        }
      }
    }
  }

  Future<void> _restoreData() async {
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
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        initialDirectory: backupDir,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!); 
        final inputStream = InputFileStream(result.files.single.path!);
        final archive = ZipDecoder().decodeBuffer(inputStream);

        final jsonFile = archive.findFile('music_repertoire.json');
        if (jsonFile == null) {
          throw Exception('Invalid backup file: music_repertoire.json not found.');
        }

        final jsonString = utf8.decode(jsonFile.content);
        final List<dynamic> musicPiecesJson = jsonDecode(jsonString);
        final List<MusicPiece> restoredPieces = musicPiecesJson.map((e) => MusicPiece.fromJson(e)).toList();

        await _repository.deleteAllMusicPieces();
        for (var piece in restoredPieces) {
          await _repository.insertMusicPiece(piece);
        }

        final mediaDir = Directory(p.join(storagePath!, 'media'));
        if (await mediaDir.exists()) {
          await mediaDir.delete(recursive: true);
        }
        await mediaDir.create(recursive: true);

        for (final file in archive.files) {
          if (file.name.startsWith('media/')) {
            final filePath = p.join(storagePath, file.name);
            if (file.isFile) {
              final outputStream = OutputFileStream(filePath);
              outputStream.writeBytes(file.content);
              outputStream.close();
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore cancelled.'))
        );
      }
    } catch (e) {
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
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', selectedDirectory);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage folder updated to: $selectedDirectory')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder selection cancelled.')),
      );
    }
  }
}
