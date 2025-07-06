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

  Future<void> _backupData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up data...'))
    );
    try {
      final musicPieces = await _repository.getMusicPieces();
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'music_repertoire_backup_$timestamp.json';

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
        // Desktop logic remains the same.
        String? outputFile = await FilePicker.platform.saveFile(
          fileName: fileName,
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

  Future<void> _restoreData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring data...'))
    );
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
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
            onTap: _backupData,
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