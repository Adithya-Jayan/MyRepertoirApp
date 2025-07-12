import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';

import 'package:intl/intl.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  bool _autoBackupEnabled = false;
  int _autoBackupFrequency = 7;
  int _autoBackupCount = 5;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSettings();
  }

  Future<void> _loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
      _autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
      _autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
    });
  }

  Future<void> _saveAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
    await prefs.setInt('autoBackupFrequency', _autoBackupFrequency);
    await prefs.setInt('autoBackupCount', _autoBackupCount);
  }

  Future<void> _backupData({bool manual = true}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up data...'))
    );
    try {
      final musicPieces = await _repository.getMusicPieces();
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'music_repertoire_backup_$timestamp.json';

      final prefs = await SharedPreferences.getInstance();
      final storagePath = prefs.getString('appStoragePath');
      String? backupDir;
      if (storagePath != null) {
        final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups');
        final backupDirectory = Directory(p.join(storagePath, backupSubDir));
        if (!await backupDirectory.exists()) {
          await backupDirectory.create(recursive: true);
        }
        backupDir = backupDirectory.path;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, we must pass the bytes to `saveFile`.
        await FilePicker.platform.saveFile(
          fileName: fileName,
          bytes: utf8.encode(jsonString),
        );
        // We can't reliably detect cancellation, so we'll just show a success message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data backed up successfully!'))
        );
      } else {
        // Desktop logic with initial directory.
        String? outputFile = await FilePicker.platform.saveFile(
          fileName: fileName,
          initialDirectory: backupDir,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(utf8.encode(jsonString));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data backed up successfully!'))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup cancelled.'))
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e'))
      );
    }
  }

  Future<void> _triggerAutoBackup() async {
    await _backupData(manual: false);
    final prefs = await SharedPreferences.getInstance();
    final storagePath = prefs.getString('appStoragePath');
    if (storagePath != null) {
      final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
      if (await autoBackupDir.exists()) {
        final files = await autoBackupDir.list().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        if (files.length > _autoBackupCount) {
          for (int i = 0; i < files.length - _autoBackupCount; i++) {
            await files[i].delete();
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
        allowedExtensions: ['json'],
        initialDirectory: backupDir,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!); 
        final jsonBytes = await file.readAsBytes();
        final jsonString = utf8.decode(jsonBytes);
        final List<dynamic> musicPiecesJson = jsonDecode(jsonString);
        final List<MusicPiece> restoredPieces = musicPiecesJson.map((e) => MusicPiece.fromJson(e)).toList();

        // await _repository.deleteAllMusicPieces();
        for (var piece in restoredPieces) {
          // Download associated media files from Google Drive if googleDriveFileId is present
          for (var mediaItem in piece.mediaItems) {
            if (mediaItem.googleDriveFileId != null && mediaItem.googleDriveFileId!.isNotEmpty) {
              final appDocDir = await getApplicationDocumentsDirectory();
              final mediaDir = Directory(p.join(appDocDir.path, 'repertoire_media'));
              if (!await mediaDir.exists()) {
                await mediaDir.create(recursive: true);
              }
              final localFilePath = p.join(mediaDir.path, p.basename(mediaItem.pathOrUrl));
              // await _googleDriveService.downloadFileFromDrive(mediaItem.googleDriveFileId!, localFilePath);
              mediaItem.pathOrUrl = localFilePath; // Update local path
            }
          }
          await _repository.insertMusicPiece(piece);
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
