import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../services/google_drive_service.dart';
import './database_helper.dart';

class MusicPieceRepository {
  final dbHelper = DatabaseHelper.instance;
  final driveService = GoogleDriveService();

  Future<void> insertMusicPiece(MusicPiece piece, {bool syncToDrive = false}) async {
    await dbHelper.insertMusicPiece(piece);
    if (syncToDrive) {
      // In a real app, you'd serialize the piece to JSON and upload it.
      // For now, this is a placeholder.
      print('Syncing new piece to Google Drive...');
      // await driveService.uploadFile(...);
    }
  }

  Future<List<MusicPiece>> getMusicPieces({bool syncFromDrive = false}) async {
    if (syncFromDrive) {
      print('Syncing from Google Drive...');
      // Here you would fetch data from Drive, compare with local, and update.
      // For now, just fetching from local.
    }
    return await dbHelper.getMusicPieces();
  }

  Future<int> updateMusicPiece(MusicPiece piece, {bool syncToDrive = false}) async {
    final result = await dbHelper.updateMusicPiece(piece);
    if (syncToDrive) {
      print('Syncing updated piece to Google Drive...');
      // await driveService.updateFile(...);
    }
    return result;
  }

  Future<int> deleteMusicPiece(String id, {bool syncToDrive = false}) async {
    final result = await dbHelper.deleteMusicPiece(id);
    if (syncToDrive) {
      print('Deleting piece from Google Drive...');
    }
    return result;
  }

  Future<void> deleteAllMusicPieces() async {
    await dbHelper.deleteAllMusicPieces();
  }

  // Placeholder for a more complex sync operation
  Future<void> syncWithDrive() async {
    print('Performing a full sync with Google Drive...');
    // 1. Fetch all files from Drive app folder
    // 2. Fetch all pieces from local DB
    // 3. Compare and resolve conflicts (e.g., based on timestamps)
    // 4. Upload new/updated local pieces
    // 5. Download new/updated remote pieces
  }

  Future<String?> exportDataToJson() async {
    try {
      final musicPieces = await dbHelper.getMusicPieces();
      final tags = await dbHelper.getTags();

      final data = {
        'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/repertoire_backup.json';

      final result = await FilePicker.platform.saveFile(
        fileName: 'repertoire_backup.json',
        initialDirectory: directory.path,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        return result;
      }
      return null;
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }

  Future<bool> importDataFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];

        for (var pieceJson in musicPiecesJson) {
          final piece = MusicPiece.fromJson(pieceJson);
          await dbHelper.insertMusicPiece(piece); // Or update if exists
        }

        for (var tagJson in tagsJson) {
          final tag = Tag.fromJson(tagJson);
          await dbHelper.insertTag(tag); // Or update if exists
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}
