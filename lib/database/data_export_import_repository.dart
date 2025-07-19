// Core Dart imports
import 'dart:convert'; // For JSON encoding and decoding
import 'dart:io'; // For file system operations

// Package imports
import 'package:file_picker/file_picker.dart'; // For picking files from local storage
import 'package:path_provider/path_provider.dart'; // For accessing platform-specific file system paths

// Project-specific model imports
import '../models/music_piece.dart'; // Data model for a music piece
import '../models/tag.dart'; // Data model for a tag
import '../models/group.dart'; // Data model for a group

// Database and service imports
import './database_helper.dart'; // Helper for SQLite database operations
import '../utils/app_logger.dart'; // For logging

/// A repository class that handles data export and import operations.
/// This is extracted from MusicPieceRepository to reduce file size and improve organization.
class DataExportImportRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  /// Exports all music piece, tag, and group data to a JSON file.
  /// Allows the user to choose the save location.
  /// Returns the path of the saved file if successful, otherwise null.
  Future<String?> exportDataToJson() async {
    try {
      final musicPieces = await dbHelper.getMusicPieces();
      final tags = await dbHelper.getTags();
      final groups = await dbHelper.getGroups();

      // Combine all data into a single map.
      final data = {
        'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);

      // Get the application documents directory as a default save location.
      final directory = await getApplicationDocumentsDirectory();

      // Open a file picker dialog for the user to choose the save location and file name.
      final result = await FilePicker.platform.saveFile(
        fileName: 'repertoire_backup.json',
        initialDirectory: directory.path,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // If the user selected a file path, write the JSON string to it.
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        return result;
      }
      return null;
    } catch (e) {
      AppLogger.log('Error exporting data: $e');
      return null;
    }
  }

  /// Imports music piece, tag, and group data from a selected JSON file.
  /// Allows the user to pick a JSON file.
  /// Returns true if the import is successful, otherwise false.
  Future<bool> importDataFromJson() async {
    try {
      // Open a file picker dialog for the user to select a JSON file.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // If a file was selected and its path is valid.
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Extract data for music pieces, tags, and groups from the JSON.
        final List<dynamic> musicPiecesJson = data['musicPieces'] ?? [];
        final List<dynamic> tagsJson = data['tags'] ?? [];
        final List<dynamic> groupsJson = data['groups'] ?? [];

        // Insert or update music pieces in the database.
        for (var pieceJson in musicPiecesJson) {
          final piece = MusicPiece.fromJson(pieceJson);
          await dbHelper.insertMusicPiece(piece);
        }

        // Insert or update tags in the database.
        for (var tagJson in tagsJson) {
          final tag = Tag.fromJson(tagJson);
          await dbHelper.insertTag(tag);
        }

        // Insert or update groups in the database.
        for (var groupJson in groupsJson) {
          final group = Group.fromJson(groupJson);
          await dbHelper.insertGroup(group);
        }
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.log('Error importing data: $e');
      return false;
    }
  }
} 