import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../models/group.dart'; // Import the new Group model
import './database_helper.dart';
import '../services/media_storage_manager.dart';

class MusicPieceRepository {
  final dbHelper = DatabaseHelper.instance;
  final Uuid uuid = Uuid();

  Future<void> insertMusicPiece(MusicPiece piece) async {
    await dbHelper.insertMusicPiece(piece);
  }

  Future<List<MusicPiece>> getMusicPieces({String? groupId}) async {
    final allPieces = await dbHelper.getMusicPieces();
    if (groupId == null || groupId.isEmpty) {
      return allPieces;
    } else {
      return allPieces.where((piece) => piece.groupIds.contains(groupId)).toList();
    }
  }

  Future<int> updateMusicPiece(MusicPiece piece) async {
    final result = await dbHelper.updateMusicPiece(piece);
    return result;
  }

  Future<int> deleteMusicPiece(String id) async {
    await MediaStorageManager.deletePieceMediaDirectory(id);
    final result = await dbHelper.deleteMusicPiece(id);
    return result;
  }

  Future<void> deleteMusicPieces(List<String> ids) async {
    for (final id in ids) {
      await MediaStorageManager.deletePieceMediaDirectory(id);
    }
    await dbHelper.deleteMusicPieces(ids);
  }

  Future<void> deleteAllMusicPieces() async {
    final allPieces = await dbHelper.getMusicPieces();
    for (final piece in allPieces) {
      await MediaStorageManager.deletePieceMediaDirectory(piece.id);
    }
    await dbHelper.deleteAllMusicPieces();
  }

  // Group Management Methods
  Future<void> createGroup(Group group) async {
    await dbHelper.insertGroup(group);
  }

  Future<List<Group>> getGroups() async {
    return await dbHelper.getGroups();
  }

  Future<int> updateGroup(Group group) async {
    return await dbHelper.updateGroup(group);
  }

  Future<int> deleteGroup(String id) async {
    // When a group is deleted, remove its ID from all music pieces
    final piecesToUpdate = await dbHelper.getMusicPieces();
    for (var piece in piecesToUpdate) {
      if (piece.groupIds.contains(id)) {
        piece.groupIds.remove(id);
        await dbHelper.updateMusicPiece(piece);
      }
    }
    return await dbHelper.deleteGroup(id);
  }

  Future<void> updateGroupMembershipForPieces(List<String> pieceIds, String groupId, bool shouldBeInGroup) async {
    final pieces = await dbHelper.getMusicPiecesByIds(pieceIds);
    for (final piece in pieces) {
      if (shouldBeInGroup) {
        if (!piece.groupIds.contains(groupId)) {
          piece.groupIds.add(groupId);
        }
      } else {
        piece.groupIds.remove(groupId);
      }
      await dbHelper.updateMusicPiece(piece);
    }
  }

  // Tag Management Methods
  Future<void> insertTag(Tag tag) async {
    await dbHelper.insertTag(tag);
  }

  Future<List<Tag>> getTags() async {
    return await dbHelper.getTags();
  }

  Future<int> deleteTag(String id) async {
    return await dbHelper.deleteTag(id);
  }

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

  Future<String?> exportDataToJson() async {
    try {
      final musicPieces = await dbHelper.getMusicPieces();
      final tags = await dbHelper.getTags();
      final groups = await dbHelper.getGroups();

      final data = {
        'musicPieces': musicPieces.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'groups': groups.map((e) => e.toJson()).toList(),
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
        final List<dynamic> groupsJson = data['groups'] ?? [];

        for (var pieceJson in musicPiecesJson) {
          final piece = MusicPiece.fromJson(pieceJson);
          await dbHelper.insertMusicPiece(piece); // Or update if exists
        }

        for (var tagJson in tagsJson) {
          final tag = Tag.fromJson(tagJson);
          await dbHelper.insertTag(tag); // Or update if exists
        }

        for (var groupJson in groupsJson) {
          final group = Group.fromJson(groupJson);
          await dbHelper.insertGroup(group); // Or update if exists
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  // Helper to ensure a default group exists
  Future<void> ensureDefaultGroupExists() async {
    final groups = await getGroups();
    if (!groups.any((group) => group.isDefault)) {
      final defaultGroup = Group(
        id: uuid.v4(),
        name: 'Default Group',
        order: 0,
        isDefault: true,
      );
      await createGroup(defaultGroup);
    }
  }
}
