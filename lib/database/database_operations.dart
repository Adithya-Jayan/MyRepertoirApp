import 'package:sqflite/sqflite.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../models/group.dart';

class DatabaseOperations {
  final Database db;

  DatabaseOperations(this.db);

  // MusicPiece operations
  Future<void> insertMusicPiece(MusicPiece piece) async {
    await db.insert('music_pieces', piece.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MusicPiece>> getMusicPieces() async {
    final result = await db.query('music_pieces');
    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final result = await db.query(
      'music_pieces',
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  Future<int> updateMusicPiece(MusicPiece piece) async {
    return await db.update(
      'music_pieces',
      piece.toJson(),
      where: 'id = ?',
      whereArgs: [piece.id],
    );
  }

  Future<int> deleteMusicPiece(String id) async {
    return await db.delete(
      'music_pieces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMusicPieces(List<String> ids) async {
    if (ids.isEmpty) {
      return 0;
    }
    return await db.delete(
      'music_pieces',
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<void> deleteAllMusicPieces() async {
    await db.delete('music_pieces');
  }

  // Tag operations
  Future<void> insertTag(Tag tag) async {
    await db.insert('tags', tag.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Tag>> getTags() async {
    final result = await db.query('tags');
    return result.map((json) => Tag.fromJson(json)).toList();
  }

  Future<int> updateTag(Tag tag) async {
    return await db.update(
      'tags',
      tag.toJson(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<int> deleteTag(String id) async {
    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTags() async {
    await db.delete('tags');
  }

  // Group operations
  Future<void> insertGroup(Group group) async {
    await db.insert('groups', group.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Group>> getGroups() async {
    final result = await db.query('groups');
    return result.map((json) => Group.fromJson(json)).toList();
  }

  Future<int> updateGroup(Group group) async {
    return await db.update(
      'groups',
      group.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(String id) async {
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllGroups() async {
    await db.delete('groups');
  }
} 