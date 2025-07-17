// Core Dart imports
import 'dart:convert'; // For JSON encoding and decoding
import 'dart:io'; // For file system operations

// Package imports
import 'package:file_picker/file_picker.dart'; // For picking files from local storage
import 'package:path_provider/path_provider.dart'; // For accessing platform-specific file system paths
import 'package:uuid/uuid.dart'; // For generating unique identifiers

// Project-specific model imports
import '../models/music_piece.dart'; // Data model for a music piece
import '../models/tag.dart'; // Data model for a tag
import '../models/group.dart'; // Data model for a group

// Database and service imports
import './database_helper.dart'; // Helper for SQLite database operations
import '../services/media_storage_manager.dart'; // Manages storage of media files
import '../utils/app_logger.dart'; // For logging

/// A repository class that acts as an abstraction layer for data operations
/// related to MusicPiece, Tag, and Group objects.
/// It interacts with the DatabaseHelper and MediaStorageManager to perform
/// CRUD operations and manage associated media files.
class MusicPieceRepository {
  /// Instance of DatabaseHelper for database interactions.
  final dbHelper = DatabaseHelper.instance;

  /// UUID generator for creating unique IDs.
  final Uuid uuid = Uuid();

  /// Inserts a new [MusicPiece] into the database.
  Future<void> insertMusicPiece(MusicPiece piece) async {
    await dbHelper.insertMusicPiece(piece);
  }

  /// Retrieves a list of [MusicPiece] objects from the database.
  /// Optionally filters by a [groupId] to get pieces belonging to a specific group.
  /// If [groupId] is 'ungrouped_group', it returns pieces not associated with any group.
  Future<List<MusicPiece>> getMusicPieces({String? groupId}) async {
    final allPieces = await dbHelper.getMusicPieces();
    if (groupId == null || groupId.isEmpty || groupId == 'all_group') {
      return allPieces;
    } else if (groupId == 'ungrouped_group') {
      return allPieces.where((piece) => piece.groupIds.isEmpty).toList();
    } else {
      return allPieces.where((piece) => piece.groupIds.contains(groupId)).toList();
    }
  }

  /// Updates an existing [MusicPiece] in the database.
  /// Returns the number of rows affected.
  Future<int> updateMusicPiece(MusicPiece piece) async {
    final result = await dbHelper.updateMusicPiece(piece);
    return result;
  }

  /// Deletes a [MusicPiece] from the database by its [id].
  /// Also deletes the associated media directory for the music piece.
  /// Returns the number of rows affected.
  Future<int> deleteMusicPiece(String id) async {
    await MediaStorageManager.deletePieceMediaDirectory(id);
    final result = await dbHelper.deleteMusicPiece(id);
    return result;
  }

  /// Deletes multiple [MusicPiece] objects from the database by their [ids].
  /// Also deletes associated media directories for each music piece.
  Future<void> deleteMusicPieces(List<String> ids) async {
    for (final id in ids) {
      await MediaStorageManager.deletePieceMediaDirectory(id);
    }
    await dbHelper.deleteMusicPieces(ids);
  }

  /// Deletes all [MusicPiece] objects from the database.
  /// Also deletes all associated media directories.
  Future<void> deleteAllMusicPieces() async {
    final allPieces = await dbHelper.getMusicPieces();
    for (final piece in allPieces) {
      await MediaStorageManager.deletePieceMediaDirectory(piece.id);
    }
    await dbHelper.deleteAllMusicPieces();
  }

  /// Group Management Methods

  /// Creates a new [Group] in the database.
  Future<void> createGroup(Group group) async {
    await dbHelper.insertGroup(group);
  }

  /// Retrieves a list of all [Group] objects from the database.
  /// Excludes hidden groups unless [includeHidden] is true.
  Future<List<Group>> getGroups({bool includeHidden = true}) async {
    final groups = await dbHelper.getGroups();
    return groups;
  }

  /// Updates an existing [Group] in the database.
  /// Returns the number of rows affected.
  Future<int> updateGroup(Group group) async {
    return await dbHelper.updateGroup(group);
  }

  /// Deletes a [Group] from the database by its [id].
  /// When a group is deleted, its ID is removed from all music pieces
  /// that were associated with it.
  Future<int> deleteGroup(String id) async {
    // Retrieve all music pieces to update their group memberships.
    final piecesToUpdate = await dbHelper.getMusicPieces();
    for (var piece in piecesToUpdate) {
      // If a piece belongs to the deleted group, remove the group ID.
      if (piece.groupIds.contains(id)) {
        piece.groupIds.remove(id);
        await dbHelper.updateMusicPiece(piece);
      }
    }
    // Finally, delete the group from the database.
    return await dbHelper.deleteGroup(id);
  }

  /// Updates the group membership for a list of [MusicPiece] objects.
  /// [pieceIds]: The IDs of the music pieces to update.
  /// [groupId]: The ID of the group to add/remove.
  /// [shouldBeInGroup]: True to add pieces to the group, false to remove them.
  Future<void> updateGroupMembershipForPieces(List<String> pieceIds, String groupId, bool shouldBeInGroup) async {
    final pieces = await dbHelper.getMusicPiecesByIds(pieceIds);
    for (final piece in pieces) {
      if (shouldBeInGroup) {
        // Add the group ID if it's not already present.
        if (!piece.groupIds.contains(groupId)) {
          piece.groupIds.add(groupId);
        }
      } else {
        // Remove the group ID.
        piece.groupIds.remove(groupId);
      }
      await dbHelper.updateMusicPiece(piece);
    }
  }

  /// Tag Management Methods

  /// Inserts a new [Tag] into the database.
  Future<void> insertTag(Tag tag) async {
    await dbHelper.insertTag(tag);
  }

  /// Retrieves a list of all [Tag] objects from the database.
  Future<List<Tag>> getTags() async {
    return await dbHelper.getTags();
  }

  /// Deletes a [Tag] from the database by its [id].
  /// Returns the number of rows affected.
  Future<int> deleteTag(String id) async {
    return await dbHelper.deleteTag(id);
  }

  /// Deletes all [Tag] objects from the database.
  Future<void> deleteAllTags() async {
    await dbHelper.deleteAllTags();
  }

  /// Deletes all [Group] objects from the database.
  Future<void> deleteAllGroups() async {
    await dbHelper.deleteAllGroups();
  }

  /// Retrieves all unique tag groups and their associated tags from all music pieces.
  /// Returns a map where keys are tag group names and values are sorted lists of tags.
  Future<Map<String, List<String>>> getAllUniqueTagGroups() async {
    final allPieces = await dbHelper.getMusicPieces();
    final Map<String, Set<String>> uniqueTags = {};

    for (var piece in allPieces) {
      for (var tagGroup in piece.tagGroups) {
        if (!uniqueTags.containsKey(tagGroup.name)) {
          uniqueTags[tagGroup.name] = {};
        }
        uniqueTags[tagGroup.name]!.addAll(tagGroup.tags);
      }
    }

    final Map<String, List<String>> result = {};
    uniqueTags.forEach((key, value) {
      final sortedTags = value.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      result[key] = sortedTags;
    });

    return result;
  }

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
      // This filePath is not directly used for saving via FilePicker, but can be for reference.
      

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
