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
import '../models/practice_log.dart'; // Data model for practice logs

// Database and service imports
import './database_helper.dart'; // Helper for SQLite database operations
import '../services/media_storage_manager.dart'; // Manages storage of media files
import '../utils/app_logger.dart'; // For logging

/// A repository class that acts as an abstraction layer for data operations
/// related to MusicPiece, Tag, Group, and PracticeLog objects.
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

  /// Retrieves a single [MusicPiece] by its [id].
  Future<MusicPiece?> getMusicPieceById(String id) async {
    final allPieces = await dbHelper.getMusicPieces();
    try {
      return allPieces.firstWhere((piece) => piece.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retrieves [MusicPiece] objects by their IDs.
  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    return await dbHelper.getMusicPiecesByIds(ids);
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

  /// Inserts a new [Tag] into the database.
  Future<void> insertTag(Tag tag) async {
    await dbHelper.insertTag(tag);
  }

  /// Retrieves all [Tag] objects from the database.
  Future<List<Tag>> getTags() async {
    return await dbHelper.getTags();
  }

  /// Updates an existing [Tag] in the database.
  Future<void> updateTag(Tag tag) async {
    await dbHelper.updateTag(tag);
  }

  /// Deletes a [Tag] from the database by its ID.
  Future<void> deleteTag(String id) async {
    await dbHelper.deleteTag(id);
  }

  /// Deletes all [Tag] objects from the database.
  Future<void> deleteAllTags() async {
    await dbHelper.deleteAllTags();
  }

  /// Inserts a new [Group] into the database.
  Future<void> insertGroup(Group group) async {
    await dbHelper.insertGroup(group);
  }

  /// Retrieves all [Group] objects from the database.
  Future<List<Group>> getGroups() async {
    return await dbHelper.getGroups();
  }

  /// Updates an existing [Group] in the database.
  Future<void> updateGroup(Group group) async {
    await dbHelper.updateGroup(group);
  }

  /// Deletes a [Group] from the database by its ID.
  Future<void> deleteGroup(String id) async {
    await dbHelper.deleteGroup(id);
  }

  /// Deletes all [Group] objects from the database.
  Future<void> deleteAllGroups() async {
    await dbHelper.deleteAllGroups();
  }

  /// Creates a new group with the given name and order.
  Future<void> createGroup(Group group) async {
    await insertGroup(group);
  }

  // PracticeLog operations
  /// Inserts a new [PracticeLog] into the database.
  Future<void> insertPracticeLog(PracticeLog log) async {
    await dbHelper.insertPracticeLog(log);
  }

  /// Retrieves all [PracticeLog] objects for a specific music piece.
  Future<List<PracticeLog>> getPracticeLogsForPiece(String musicPieceId) async {
    return await dbHelper.getPracticeLogsForPiece(musicPieceId);
  }

  /// Retrieves all [PracticeLog] objects from the database.
  Future<List<PracticeLog>> getAllPracticeLogs() async {
    return await dbHelper.getAllPracticeLogs();
  }



  /// Deletes a [PracticeLog] from the database by its ID.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLog(String id) async {
    // Get the practice log to find the music piece ID
    final allLogs = await getAllPracticeLogs();
    final logToDelete = allLogs.firstWhere((log) => log.id == id);
    final musicPieceId = logToDelete.musicPieceId;
    
    // Delete the practice log
    await dbHelper.deletePracticeLog(id);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(musicPieceId);
  }

  /// Deletes all [PracticeLog] objects for a specific music piece.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLogsForPiece(String musicPieceId) async {
    await dbHelper.deletePracticeLogsForPiece(musicPieceId);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(musicPieceId);
  }

  /// Deletes all [PracticeLog] objects from the database.
  /// Also updates all music pieces' practice tracking data.
  Future<void> deleteAllPracticeLogs() async {
    await dbHelper.deleteAllPracticeLogs();
    
    // Update all music pieces to reset their practice tracking
    final allPieces = await getMusicPieces();
    for (final piece in allPieces) {
      final updatedPiece = piece.copyWith(
        lastPracticeTime: null,
        practiceCount: 0,
      );
      await updateMusicPiece(updatedPiece);
    }
  }

  /// Updates a practice log and recalculates the music piece's practice tracking.
  Future<void> updatePracticeLog(PracticeLog log) async {
    await dbHelper.updatePracticeLog(log);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(log.musicPieceId);
  }

  /// Helper method to recalculate and update a music piece's practice tracking
  /// based on its remaining practice logs.
  Future<void> _updateMusicPiecePracticeTracking(String musicPieceId) async {
    // Get the current practice logs for this piece
    final practiceLogs = await getPracticeLogsForPiece(musicPieceId);
    
    // Get the music piece
    final piece = (await getMusicPiecesByIds([musicPieceId])).first;
    
    if (practiceLogs.isEmpty) {
      // No practice logs left, reset practice tracking
      final updatedPiece = piece.copyWith(
        lastPracticeTime: null,
        practiceCount: 0,
      );
      await updateMusicPiece(updatedPiece);
    } else {
      // Calculate new practice count and last practice time
      final practiceCount = practiceLogs.length;
      final lastPracticeTime = practiceLogs
          .map((log) => log.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      
      final updatedPiece = piece.copyWith(
        lastPracticeTime: lastPracticeTime,
        practiceCount: practiceCount,
      );
      await updateMusicPiece(updatedPiece);
    }
  }

  /// Logs a practice session for a music piece.
  /// Creates a new practice log entry and updates the music piece's practice tracking.
  Future<void> logPracticeSession(String musicPieceId, {String? notes, int durationMinutes = 0}) async {
    final log = PracticeLog(
      id: uuid.v4(),
      musicPieceId: musicPieceId,
      timestamp: DateTime.now(),
      notes: notes,
      durationMinutes: durationMinutes,
    );
    
    await insertPracticeLog(log);
    
    // Update the music piece's practice tracking
    final piece = (await getMusicPiecesByIds([musicPieceId])).first;
    final updatedPiece = piece.copyWith(
      lastPracticeTime: log.timestamp,
      practiceCount: piece.practiceCount + 1,
    );
    await updateMusicPiece(updatedPiece);
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
