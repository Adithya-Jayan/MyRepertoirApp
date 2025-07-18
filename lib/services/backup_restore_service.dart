import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import '../utils/app_logger.dart';

import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../models/group.dart';

import 'package:intl/intl.dart';

class BackupRestoreService {
  final MusicPieceRepository _repository;
  final SharedPreferences prefs;

  BackupRestoreService(this._repository, this.prefs);

  /// Initiates a backup of application data (music pieces and media files).
  ///
  /// If `manual` is true, it prompts the user for a save location. Otherwise,
  /// it performs an automatic backup to a predefined location.
  Future<void> backupData({bool manual = true, BuildContext? context}) async {
    AppLogger.log('Initiating backup (manual: $manual).');
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up data...'))
      );
    }
    try {
      final musicPieces = await _repository.getMusicPieces();
      final tags = await _repository.getTags();
      final groups = await _repository.getGroups();

      final data = {
        'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
      };
      final jsonString = jsonEncode(data);
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'music_repertoire_backup_$timestamp.zip';

      final storagePath = _prefs.getString('appStoragePath');
      if (storagePath == null) {
        AppLogger.log('Backup failed: Storage path not configured.');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage path not configured.'))
          );
        }
        return;
      }
      AppLogger.log('Storage path: $storagePath');

      final backupSubDir = manual ? p.join('Backups', 'ManualBackups') : p.join('Backups', 'Autobackups');
      final backupDirectory = Directory(p.join(storagePath, backupSubDir));
      AppLogger.log('Backup directory: ${backupDirectory.path}');
      if (!await backupDirectory.exists()) {
        AppLogger.log('Creating backup directory: ${backupDirectory.path}');
        await backupDirectory.create(recursive: true);
      }

      final tempDir = await getTemporaryDirectory();
      final tempZipPath = p.join(tempDir.path, fileName);
      AppLogger.log('Temporary zip path: $tempZipPath');

      final encoder = ZipFileEncoder();
      encoder.create(tempZipPath);
      AppLogger.log('Zip encoder created.');

      final jsonArchiveFile = ArchiveFile('music_repertoire.json', jsonString.length, utf8.encode(jsonString));
      encoder.addArchiveFile(jsonArchiveFile);
      AppLogger.log('JSON data added to zip.');

      final mediaDir = Directory(p.join(storagePath, 'media'));
      if (await mediaDir.exists()) {
        AppLogger.log('Adding media directory to zip: ${mediaDir.path}');
        encoder.addDirectory(mediaDir, includeDirName: false);
      }

      encoder.close();
      AppLogger.log('Zip encoder closed.');

      final zipBytes = await File(tempZipPath).readAsBytes();
      AppLogger.log('Zip bytes read from temporary file.');

      if (manual) {
        AppLogger.log('Handling manual backup save.');
        String? outputFile;
        if (Platform.isAndroid || Platform.isIOS) {
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            bytes: zipBytes,
            initialDirectory: backupDirectory.path,
          );
          AppLogger.log('FilePicker.saveFile (mobile) returned: $outputFile');
          if (outputFile != null) {
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data backed up successfully!'))
              );
            }
            AppLogger.log('Manual backup successful.');
          } else {
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup cancelled.'))
              );
            }
            AppLogger.log('Manual backup cancelled by user.');
          }
        } else {
          outputFile = await FilePicker.platform.saveFile(
            fileName: fileName,
            initialDirectory: backupDirectory.path,
            type: FileType.custom,
            allowedExtensions: ['zip'],
          );
          AppLogger.log('FilePicker.saveFile (desktop) returned: $outputFile');
          if (outputFile != null) {
            final outputDirectory = Directory(p.dirname(outputFile));
            if (!await outputDirectory.exists()) {
              AppLogger.log('Creating output directory for desktop: ${outputDirectory.path}');
              await outputDirectory.create(recursive: true);
            }
            await File(outputFile).writeAsBytes(zipBytes);
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data backed up successfully!'))
              );
            }
            AppLogger.log('Manual backup successful.');
          } else {
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup cancelled.'))
              );
            }
            AppLogger.log('Manual backup cancelled by user.');
          }
        }
      } else {
        AppLogger.log('Handling automatic backup save.');
        final zipFile = File(p.join(backupDirectory.path, fileName));
        await zipFile.writeAsBytes(zipBytes);

        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autobackup successful!'))
          );
        }
        AppLogger.log('Autobackup successful.');
      }

      AppLogger.log('Deleting temporary zip file: $tempZipPath');
      await File(tempZipPath).delete();
    } catch (e) {
      AppLogger.log('Backup failed: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'))
        );
      }
    }
  }

  /// Triggers an automatic backup process.
  ///
  /// This function calls `_backupData` with `manual` set to false,
  /// and then manages the number of automatic backup files, deleting older ones
  /// if the count exceeds the configured limit.
  Future<void> triggerAutoBackup(int autoBackupCount, {BuildContext? context}) async {
    AppLogger.log('Triggering automatic backup.');
    await backupData(manual: false, context: context);
    final storagePath = prefs.getString('appStoragePath');
    if (storagePath != null) {
      final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
      if (await autoBackupDir.exists()) {
        AppLogger.log('Auto-backup directory exists: ${autoBackupDir.path}');
        final files = await autoBackupDir.list().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        AppLogger.log('Found ${files.length} auto-backup files.');
        if (files.length > autoBackupCount) {
          AppLogger.log('Deleting old auto-backup files. Keeping ${autoBackupCount}.');
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            AppLogger.log('Deleting: ${files[i].path}');
            await files[i].delete();
          }
        }
      }
    }
  }

  Future<void> restoreData({BuildContext? context}) async {
    AppLogger.log('Initiating data restore.');
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring data...'))
      );
    }
    try {
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

        final List<Group> oldGroupsBeforeRestore = await _repository.getGroups();
        AppLogger.log('Fetched ${oldGroupsBeforeRestore.length} old groups before restore.');

        await _repository.deleteAllMusicPieces();
        AppLogger.log('Deleted all existing music pieces.');
        for (var pieceJson in musicPiecesJson) {
          final piece = MusicPiece.fromJson(pieceJson);
          await _repository.insertMusicPiece(piece);
        }
        AppLogger.log('Restored ${musicPiecesJson.length} music pieces.');

        await _repository.deleteAllTags();
        AppLogger.log('Deleted all existing tags.');
        for (var tagJson in tagsJson) {
          final tag = Tag.fromJson(tagJson);
          await _repository.insertTag(tag);
        }
        AppLogger.log('Restored ${tagsJson.length} tags.');

        await _repository.deleteAllGroups();
        AppLogger.log('Deleted all existing groups.');
        for (var groupJson in groupsJson) {
          final group = Group.fromJson(groupJson);
          await _repository.createGroup(group);
        }
        AppLogger.log('Restored ${groupsJson.length} groups from backup.');

        final List<Group> currentGroupsAfterRestore = await _repository.getGroups();
        final Set<String> currentGroupIds = currentGroupsAfterRestore.map((g) => g.id).toSet();
        AppLogger.log('Current groups after restore: ${currentGroupIds.length}');

        int nextOrder = currentGroupsAfterRestore.length;

        for (final oldGroup in oldGroupsBeforeRestore) {
          if (!currentGroupIds.contains(oldGroup.id)) {
            final newOrder = nextOrder++;
            final groupToReAdd = oldGroup.copyWith(order: newOrder);
            await _repository.createGroup(groupToReAdd);
            AppLogger.log('Re-added old group: ${groupToReAdd.name}');
          }
        }
        AppLogger.log('Finished re-adding old groups.');

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

        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully!'))
          );
        }
        AppLogger.log('Data restored successfully.');
      } else {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore cancelled.'))
          );
        }
        AppLogger.log('Restore cancelled by user.');
      }
    } catch (e) {
      AppLogger.log('Restore failed: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'))
        );
      }
    }
  }
}
