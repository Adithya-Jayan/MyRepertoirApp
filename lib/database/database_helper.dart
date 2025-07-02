import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_piece.dart';
import '../models/tag.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE music_pieces (
  id TEXT PRIMARY KEY,
  title TEXT,
  artistComposer TEXT,
  genre TEXT, -- Store as JSON string, e.g., '[Classical, Piano]'
  instrumentation TEXT,
  difficulty TEXT,
  tags TEXT, -- Store as JSON string
  lastAccessed TEXT, -- ISO 8601 string
  isFavorite INTEGER, -- 0 or 1
  lastPracticeTime TEXT, -- ISO 8601 string
  practiceCount INTEGER,
  enablePracticeTracking INTEGER,
  googleDriveFileId TEXT,
  mediaItems TEXT -- Store List<MediaItem> as JSON string
)
''');

    await db.execute('''
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT,
  color INTEGER,
  type TEXT
)
''');
  }

  Future<void> insertMusicPiece(MusicPiece piece) async {
    final db = await instance.database;
    await db.insert('music_pieces', piece.toJson());
  }

  Future<void> insertTag(Tag tag) async {
    final db = await instance.database;
    await db.insert('tags', tag.toJson());
  }

  Future<List<MusicPiece>> getMusicPieces() async {
    final db = await instance.database;
    final result = await db.query('music_pieces');

    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  Future<List<Tag>> getTags() async {
    final db = await instance.database;
    final result = await db.query('tags');

    return result.map((json) => Tag.fromJson(json)).toList();
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

  Future<int> deleteMusicPiece(String id) async {
    final db = await instance.database;

    return await db.delete(
      'music_pieces',
      where: 'id = ?',
      whereArgs: [id],
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

  Future<void> deleteAllMusicPieces() async {
    final db = await instance.database;
    await db.delete('music_pieces');
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
