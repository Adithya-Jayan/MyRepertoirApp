// Core Dart imports
import 'dart:convert'; // For JSON encoding and decoding
import 'dart:io'; // For file system operations

// Package imports
import 'package:uuid/uuid.dart'; // For generating unique identifiers

// Project-specific model imports
import '../models/music_piece.dart'; // Data model for a music piece
import '../models/tag.dart'; // Data model for a tag
import '../models/group.dart'; // Data model for a group
import '../models/practice_log.dart'; // Data model for practice logs
import '../models/tag_group.dart'; // Data model for tag groups

// Database and service imports
import './database_helper.dart'; // Helper for SQLite database operations
import '../services/media_storage_manager.dart'; // Manages storage of media files
import '../utils/app_logger.dart'; // For logging
import './practice_log_repository.dart'; // Practice log operations
import './data_export_import_repository.dart'; // Data export/import operations

/// A repository class that acts as an abstraction layer for data operations
/// related to MusicPiece, Tag, Group, and PracticeLog objects.
/// It interacts with the DatabaseHelper and MediaStorageManager to perform
/// CRUD operations and manage associated media files.
class MusicPieceRepository {
  /// Instance of DatabaseHelper for database interactions.
  final dbHelper = DatabaseHelper.instance;

  /// UUID generator for creating unique IDs.
  final Uuid uuid = Uuid();

  /// Practice log repository for practice log operations.
  late final PracticeLogRepository _practiceLogRepository;

  /// Data export/import repository for data operations.
  final DataExportImportRepository _dataExportImportRepository = DataExportImportRepository();

  MusicPieceRepository() {
    _practiceLogRepository = PracticeLogRepository(this);
  }

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
    AppLogger.log('getMusicPieceById: Retrieving piece $id');
    final pieces = await dbHelper.getMusicPiecesByIds([id]);
    final piece = pieces.isNotEmpty ? pieces.first : null;
    AppLogger.log('getMusicPieceById: Retrieved piece - lastPracticeTime: ${piece?.lastPracticeTime}, practiceCount: ${piece?.practiceCount}');
    return piece;
  }

  /// Retrieves [MusicPiece] objects by their IDs.
  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    return await dbHelper.getMusicPiecesByIds(ids);
  }

  /// Updates an existing [MusicPiece] in the database.
  /// Returns the number of rows affected.
  Future<int> updateMusicPiece(MusicPiece piece) async {
    AppLogger.log('updateMusicPiece: Updating piece ${piece.id} - lastPracticeTime: ${piece.lastPracticeTime}, practiceCount: ${piece.practiceCount}');
    final result = await dbHelper.updateMusicPiece(piece);
    AppLogger.log('updateMusicPiece: Update result: $result rows affected');
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

  // PracticeLog operations - delegated to PracticeLogRepository
  /// Inserts a new [PracticeLog] into the database.
  Future<void> insertPracticeLog(PracticeLog log) async {
    await _practiceLogRepository.insertPracticeLog(log);
  }

  /// Retrieves all [PracticeLog] objects for a specific music piece.
  Future<List<PracticeLog>> getPracticeLogsForPiece(String musicPieceId) async {
    return await _practiceLogRepository.getPracticeLogsForPiece(musicPieceId);
  }

  /// Retrieves all [PracticeLog] objects from the database.
  Future<List<PracticeLog>> getAllPracticeLogs() async {
    return await _practiceLogRepository.getAllPracticeLogs();
  }

  /// Deletes a [PracticeLog] from the database by its ID.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLog(String id) async {
    await _practiceLogRepository.deletePracticeLog(id);
  }

  /// Deletes all [PracticeLog] objects for a specific music piece.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLogsForPiece(String musicPieceId) async {
    await _practiceLogRepository.deletePracticeLogsForPiece(musicPieceId);
  }

  /// Deletes all [PracticeLog] objects from the database.
  /// Also updates all music pieces' practice tracking data.
  Future<void> deleteAllPracticeLogs() async {
    await _practiceLogRepository.deleteAllPracticeLogs();
  }

  /// Updates a practice log and recalculates the music piece's practice tracking.
  Future<void> updatePracticeLog(PracticeLog log) async {
    await _practiceLogRepository.updatePracticeLog(log);
  }

  /// Logs a practice session for a music piece.
  /// Creates a new practice log entry and updates the music piece's practice tracking.
  Future<void> logPracticeSession(String musicPieceId, {String? notes, int durationMinutes = 0, DateTime? timestamp}) async {
    await _practiceLogRepository.logPracticeSession(musicPieceId, notes: notes, durationMinutes: durationMinutes, timestamp: timestamp);
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
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('music_pieces', columns: ['tagGroups']);

    final Map<String, Set<String>> uniqueTagGroups = {};

    for (var map in maps) {
      if (map['tagGroups'] != null) {
        final List<dynamic> tagGroupMaps = jsonDecode(map['tagGroups']);
        for (var tgMap in tagGroupMaps) {
          final tagGroup = TagGroup.fromJson(tgMap);
          uniqueTagGroups.putIfAbsent(tagGroup.name, () => <String>{});
          for (var tag in tagGroup.tags) {
            uniqueTagGroups[tagGroup.name]!.add(tag);
          }
        }
      }
    }

    return uniqueTagGroups.map((key, value) => MapEntry(key, value.toList()));
  }

  Future<int?> getMostCommonColorForTagGroup(String groupName) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('music_pieces', columns: ['tagGroups']);

    final Map<int, int> colorCounts = {};

    for (var map in maps) {
      if (map['tagGroups'] != null) {
        final List<dynamic> tagGroupMaps = jsonDecode(map['tagGroups']);
        for (var tgMap in tagGroupMaps) {
          final tagGroup = TagGroup.fromJson(tgMap);
          if (tagGroup.name == groupName && tagGroup.color != null) {
            colorCounts[tagGroup.color!] = (colorCounts[tagGroup.color!] ?? 0) + 1;
          }
        }
      }
    }

    if (colorCounts.isEmpty) {
      return null;
    }

    int? mostCommonColor;
    int maxCount = 0;
    colorCounts.forEach((color, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonColor = color;
      }
    });

    return mostCommonColor;
  }

  /// Exports all music piece, tag, and group data to a JSON file.
  /// Allows the user to choose the save location.
  /// Returns the path of the saved file if successful, otherwise null.
  Future<String?> exportDataToJson() async {
    return await _dataExportImportRepository.exportDataToJson();
  }

  /// Imports music piece, tag, and group data from a selected JSON file.
  /// Allows the user to pick a JSON file.
  /// Returns true if the import is successful, otherwise false.
  Future<bool> importDataFromJson() async {
    return await _dataExportImportRepository.importDataFromJson();
  }
}