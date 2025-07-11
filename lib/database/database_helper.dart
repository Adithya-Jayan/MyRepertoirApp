import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../models/group.dart'; // Import the new Group model
import '../models/tag_group.dart'; // Import TagGroup model
import 'package:uuid/uuid.dart'; // Import Uuid for generating IDs
import '../utils/dummy_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('repertoire.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    final db = await openDatabase(
      path,
      version: 2, // Initial database version
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Placeholder for future migrations
    );

    // Check if the database is empty and insert dummy data if it is
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM music_pieces'));
      if (count == 0) {
        for (final piece in dummyMusicPieces) {
          await db.insert('music_pieces', piece.toJson());
        }
      }
    } catch (e) {
      // If the table doesn't exist, it means the database is corrupt or was not created correctly.
      // Re-create the database and insert initial data.
      await _createDB(db, 5); // Use the latest version
      for (final piece in dummyMusicPieces) {
        await db.insert('music_pieces', piece.toJson());
      }
    }

    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS music_pieces (
  id TEXT PRIMARY KEY,
  title TEXT,
  artistComposer TEXT,
  tags TEXT, -- Store as JSON string
  lastAccessed TEXT, -- ISO 8601 string
  isFavorite INTEGER, -- 0 or 1
  lastPracticeTime TEXT, -- ISO 8601 string
  practiceCount INTEGER,
  enablePracticeTracking INTEGER,
  googleDriveFileId TEXT,
  mediaItems TEXT, -- Store List<MediaItem> as JSON string
  groupIds TEXT DEFAULT '[]', -- New column for group IDs, default to empty JSON array
  tagGroups TEXT DEFAULT '[]', -- New column for tag groups, default to empty JSON array
  thumbnailPath TEXT -- New column for thumbnail path
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS tags (
  id TEXT PRIMARY KEY,
  name TEXT,
  color INTEGER,
  type TEXT
)
''');

    // New table for groups
    await db.execute('''
CREATE TABLE IF NOT EXISTS groups (
  id TEXT PRIMARY KEY,
  name TEXT,
  'order' INTEGER, -- 'order' is a keyword, so quote it
  isDefault INTEGER -- 0 or 1
)
''');
  }

  Future<void> insertMusicPiece(MusicPiece piece) async {
    final db = await instance.database;
    await db.insert('music_pieces', piece.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE music_pieces ADD COLUMN thumbnailPath TEXT;");
    }
  }

  Future<void> insertTag(Tag tag) async {
    final db = await instance.database;
    await db.insert('tags', tag.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // CRUD operations for Group
  Future<void> insertGroup(Group group) async {
    final db = await instance.database;
    await db.insert('groups', group.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MusicPiece>> getMusicPieces() async {
    final db = await instance.database;
    final result = await db.query('music_pieces');

    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    final db = await instance.database;
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

  Future<List<Tag>> getTags() async {
    final db = await instance.database;
    final result = await db.query('tags');

    return result.map((json) => Tag.fromJson(json)).toList();
  }

  Future<List<Group>> getGroups() async {
    final db = await instance.database;
    final result = await db.query('groups');
    return result.map((json) => Group.fromJson(json)).toList();
  }

  Future<int> updateMusicPiece(MusicPiece piece) async {
    final db = await instance.database;

    return await db.update(
      'music_pieces',
      piece.toJson(),
      where: 'id = ?',
      whereArgs: [piece.id],
    );
  }

  Future<int> updateTag(Tag tag) async {
    final db = await instance.database;

    return await db.update(
      'tags',
      tag.toJson(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<int> updateGroup(Group group) async {
    final db = await instance.database;
    return await db.update(
      'groups',
      group.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteMusicPiece(String id) async {
    final db = await instance.database;

    return await db.delete(
      'music_pieces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMusicPieces(List<String> ids) async {
    final db = await instance.database;
    if (ids.isEmpty) {
      return 0;
    }
    return await db.delete(
      'music_pieces',
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<int> deleteTag(String id) async {
    final db = await instance.database;

    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGroup(String id) async {
    final db = await instance.database;
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllMusicPieces() async {
    final db = await instance.database;
    await db.delete('music_pieces');
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
