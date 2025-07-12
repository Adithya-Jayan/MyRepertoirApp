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
      final fileName = 'music_repertoire_backup_$timestamp.zip';

      final prefs = await SharedPreferences.getInstance();
      final storagePath = prefs.getString('appStoragePath');
      if (storagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage path not configured.'))
        );
        return;
      }

      final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups');
      final backupDirectory = Directory(p.join(storagePath, backupSubDir));
      if (!await backupDirectory.exists()) {
        await backupDirectory.create(recursive: true);
      }

      final encoder = ZipFileEncoder();
      final zipPath = p.join(backupDirectory.path, fileName);
      encoder.create(zipPath);

      // Add the JSON data as a file within the zip archive
      final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
      encoder.addArchiveFile(jsonArchiveFile);

      final mediaDir = Directory(p.join(storagePath, 'media'));
      if (await mediaDir.exists()) {
        // Add the entire media directory to the zip archive
        encoder.addDirectory(mediaDir, includeDirName: false);
      }

      encoder.close();

      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data backed up successfully!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autobackup successful!'))
        );
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
