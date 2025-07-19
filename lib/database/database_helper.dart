// Core Dart and Flutter imports
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// Project-specific imports
import '../models/music_piece.dart';
import '../models/tag.dart';
import '../models/group.dart';
import 'database_schema.dart';
import 'database_operations.dart';

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
      version: 4, // Current database version
      onCreate: (db, version) async {
        await DatabaseSchema.createTables(db, version);
        await DatabaseSchema.insertDummyData(db);
      },
      onUpgrade: DatabaseSchema.upgradeDatabase,
      onOpen: DatabaseSchema.performCleanup,
    );

    return db;
  }

  /// Gets a DatabaseOperations instance for performing CRUD operations.
  Future<DatabaseOperations> get operations async {
    final db = await database;
    return DatabaseOperations(db);
  }

  /// Inserts a new MusicPiece into the database or replaces an existing one if the ID matches.
  Future<void> insertMusicPiece(MusicPiece piece) async {
    final ops = await operations;
    await ops.insertMusicPiece(piece);
  }

  /// Inserts a new Tag into the database or replaces an existing one if the ID matches.
  Future<void> insertTag(Tag tag) async {
    final ops = await operations;
    await ops.insertTag(tag);
  }

  /// Inserts a new Group into the database or replaces an existing one if the ID matches.
  Future<void> insertGroup(Group group) async {
    final ops = await operations;
    await ops.insertGroup(group);
  }

  /// Retrieves all MusicPiece objects from the database.
  Future<List<MusicPiece>> getMusicPieces() async {
    final ops = await operations;
    return await ops.getMusicPieces();
  }

  /// Retrieves MusicPiece objects from the database based on a list of IDs.
  Future<List<MusicPiece>> getMusicPiecesByIds(List<String> ids) async {
    final ops = await operations;
    return await ops.getMusicPiecesByIds(ids);
  }

  /// Retrieves all Tag objects from the database.
  Future<List<Tag>> getTags() async {
    final ops = await operations;
    return await ops.getTags();
  }

  /// Retrieves all Group objects from the database.
  Future<List<Group>> getGroups() async {
    final ops = await operations;
    return await ops.getGroups();
  }

  /// Updates an existing MusicPiece in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateMusicPiece(MusicPiece piece) async {
    final ops = await operations;
    return await ops.updateMusicPiece(piece);
  }

  /// Updates an existing Tag in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateTag(Tag tag) async {
    final ops = await operations;
    return await ops.updateTag(tag);
  }

  /// Updates an existing Group in the database.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> updateGroup(Group group) async {
    final ops = await operations;
    return await ops.updateGroup(group);
  }

  /// Deletes a MusicPiece from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteMusicPiece(String id) async {
    final ops = await operations;
    return await ops.deleteMusicPiece(id);
  }

  /// Deletes multiple MusicPiece objects from the database by their IDs.
  /// Returns the number of rows affected.
  Future<int> deleteMusicPieces(List<String> ids) async {
    final ops = await operations;
    return await ops.deleteMusicPieces(ids);
  }

  /// Deletes a Tag from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteTag(String id) async {
    final ops = await operations;
    return await ops.deleteTag(id);
  }

  /// Deletes a Group from the database by its ID.
  /// Returns the number of rows affected (should be 1 if successful).
  Future<int> deleteGroup(String id) async {
    final ops = await operations;
    return await ops.deleteGroup(id);
  }

  /// Deletes all MusicPiece objects from the database.
  Future<void> deleteAllMusicPieces() async {
    final ops = await operations;
    await ops.deleteAllMusicPieces();
  }

  /// Deletes all Tag objects from the database.
  Future<void> deleteAllTags() async {
    final ops = await operations;
    await ops.deleteAllTags();
  }

  /// Deletes all Group objects from the database.
  Future<void> deleteAllGroups() async {
    final ops = await operations;
    await ops.deleteAllGroups();
  }

  /// Closes the database connection.
  Future close() async {
    final db = await database;
    db.close();
  }
}
