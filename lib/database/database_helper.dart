// Core Dart and Flutter imports
import 'dart:convert'; // For JSON encoding and decoding
import 'package:path/path.dart'; // For joining and normalizing paths
import 'package:sqflite/sqflite.dart'; // SQLite database plugin for Flutter
import 'package:path_provider/path_provider.dart'; // For accessing platform-specific file system paths

// Project-specific model imports
import '../models/music_piece.dart'; // Data model for a music piece
import '../models/tag.dart'; // Data model for a tag
import '../models/group.dart'; // Data model for a group
import '../models/tag_group.dart'; // Data model for a tag group

// Utility imports
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../utils/dummy_data.dart'; // For initial dummy data insertion

/// A singleton helper class for managing the SQLite database.
/// Provides methods for database initialization, table creation, and CRUD operations
/// for MusicPiece, Tag, and Group objects.
class DatabaseHelper {
  /// Singleton instance of DatabaseHelper.
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Private constructor for the singleton pattern.
  DatabaseHelper._init();

  /// Static database instance, initialized once.
  static Database? _database;

  /// Getter for the database instance.
  /// Initializes the database if it hasn't been initialized yet.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('repertoire.db');
    return _database!;
  }

  /// Initializes the database.
  /// Opens the database, creates tables if they don't exist, and handles upgrades.
  Future<Database> _initDB(String filePath) async {
    // Get the application's documents directory for storing the database file.
    final dbPath = await getApplicationDocumentsDirectory();
    // Join the directory path and the database file name.
    final path = join(dbPath.path, filePath);

    // Open the database.
    final db = await openDatabase(
      path,
      version: 2, // Current database version
      onCreate: _createDB, // Callback for creating tables when the database is first created
      onUpgrade: _onUpgrade, // Callback for handling database schema upgrades
    );

    // Check if the music_pieces table is empty and insert dummy data if it is.
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM music_pieces'));
      if (count == 0) {
        for (final piece in dummyMusicPieces) {
          await db.insert('music_pieces', piece.toJson());
        }
      }
    } catch (e) {
      // If the table doesn't exist (e.g., first run or corrupted DB),
      // re-create the database and insert initial data.
      await _createDB(db, 5); // Use the latest version for creation
      for (final piece in dummyMusicPieces) {
        await db.insert('music_pieces', piece.toJson());
      }
    }

    return db;
  }

  /// Creates the database tables.
  /// This method is called when the database is first created.
  Future _createDB(Database db, int version) async {
    // Create the music_pieces table.
    await db.execute('''
CREATE TABLE IF NOT EXISTS music_pieces (
  id TEXT PRIMARY KEY,
  title TEXT,
  artistComposer TEXT,
  tags TEXT, -- Stored as JSON string
  lastAccessed TEXT, -- Stored as ISO 8601 string
  isFavorite INTEGER, -- Stored as 0 for false, 1 for true
  lastPracticeTime TEXT, -- Stored as ISO 8601 string
  practiceCount INTEGER,
  enablePracticeTracking INTEGER,
  googleDriveFileId TEXT,
  mediaItems TEXT, -- Stored as JSON string of List<MediaItem>
  groupIds TEXT DEFAULT '[]', -- New column for group IDs, default to empty JSON array
  tagGroups TEXT DEFAULT '[]', -- New column for tag groups, default to empty JSON array
  thumbnailPath TEXT -- New column for thumbnail path
)
''');

    // Create the tags table.
    await db.execute('''
CREATE TABLE IF NOT EXISTS tags (
  id TEXT PRIMARY KEY,
  name TEXT,
  color INTEGER,
  type TEXT
)
''');

    // Create the groups table.
    await db.execute('''
CREATE TABLE IF NOT EXISTS groups (
  id TEXT PRIMARY KEY,
  name TEXT,
  'order' INTEGER, -- 'order' is a SQL keyword, so it's quoted
  isDefault INTEGER -- Stored as 0 for false, 1 for true
)
''');
  }

  /// Inserts a new MusicPiece into the database or replaces an existing one if the ID matches.
  Future<void> insertMusicPiece(MusicPiece piece) async {
    final db = await instance.database;
    await db.insert('music_pieces', piece.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Handles database schema upgrades.
  /// This method is called when the database version changes.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example upgrade: Add 'thumbnailPath' column if upgrading from version < 2.
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE music_pieces ADD COLUMN thumbnailPath TEXT;");
    }
  }

  /// Inserts a new Tag into the database or replaces an existing one if the ID matches.
  Future<void> insertTag(Tag tag) async {
    final db = await instance.database;
    await db.insert('tags', tag.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Inserts a new Group into the database or replaces an existing one if the ID matches.
  Future<void> insertGroup(Group group) async {
    final db = await instance.database;
    await db.insert('groups', group.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves all MusicPiece objects from the database.
  Future<List<MusicPiece>> getMusicPieces() async {
    final db = await instance.database;
    final result = await db.query('music_pieces');

    // Convert the query result (List<Map<String, dynamic>>) to List<MusicPiece>.
    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  /// Retrieves MusicPiece objects from the database based on a list of IDs.
  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    final db = await instance.database;
    if (ids.isEmpty) {
      return []; // Return an empty list if no IDs are provided.
    }
    final result = await db.query(
      'music_pieces',
      where: 'id IN (${ids.map((_) => '?').join(',')})', // SQL IN clause for multiple IDs
      whereArgs: ids, // Arguments for the WHERE clause
    );

    // Convert the query result to List<MusicPiece>.
    return result.map((json) => MusicPiece.fromJson(json)).toList();
  }

  /// Retrieves all Tag objects from the database.
  Future<List<Tag>> getTags() async {
    final db = await instance.database;
    final result = await db.query('tags');

    // Convert the query result to List<Tag>.
    return result.map((json) => Tag.fromJson(json)).toList();
  }

  /// Retrieves all Group objects from the database.
  Future<List<Group>> getGroups() async {
    final db = await instance.database;
    final result = await db.query('groups');
    // Convert the query result to List<Group>.
    return result.map((json) => Group.fromJson(json)).toList();
  }

  /// Updates an existing MusicPiece in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateMusicPiece(MusicPiece piece) async {
    final db = await instance.database;

    return await db.update(
      'music_pieces',
      piece.toJson(),
      where: 'id = ?',
      whereArgs: [piece.id],
    );
  }

  /// Updates an existing Tag in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateTag(Tag tag) async {
    final db = await instance.database;

    return await db.update(
      'tags',
      tag.toJson(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// Updates an existing Group in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateGroup(Group group) async {
    final db = await instance.database;
    return await db.update(
      'groups',
      group.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// Deletes a MusicPiece from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteMusicPiece(String id) async {
    final db = await instance.database;

    return await db.delete(
      'music_pieces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes multiple MusicPiece objects from the database by their IDs.
  /// Returns the number of rows affected.
  Future<int> deleteMusicPieces(List<String> ids) async {
    final db = await instance.database;
    if (ids.isEmpty) {
      return 0; // No pieces to delete if the list is empty.
    }
    return await db.delete(
      'music_pieces',
      where: 'id IN (${ids.map((_) => '?').join(',')})', // SQL IN clause for multiple IDs
      whereArgs: ids, // Arguments for the WHERE clause
    );
  }

  /// Deletes a Tag from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteTag(String id) async {
    final db = await instance.database;

    return await db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a Group from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteGroup(String id) async {
    final db = await instance.database;
    return await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all MusicPiece objects from the database.
  Future<void> deleteAllMusicPieces() async {
    final db = await instance.database;
    await db.delete('music_pieces');
  }

  /// Deletes all Tag objects from the database.
  Future<void> deleteAllTags() async {
    final db = await instance.database;
    await db.delete('tags');
  }

  /// Deletes all Group objects from the database.
  Future<void> deleteAllGroups() async {
    final db = await instance.database;
    await db.delete('groups');
  }

  /// Closes the database connection.
  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
