import 'package:sqflite/sqflite.dart';
import '../utils/dummy_data.dart';

class DatabaseSchema {
  /// Creates the database tables.
  /// This method is called when the database is first created.
  static Future<void> createTables(Database db, int version) async {
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
  isHidden INTEGER DEFAULT 0 -- New column for hidden status, default to 0 (false)
)
''');
  }

  /// Handles database schema upgrades.
  /// This method is called when the database version changes.
  static Future<void> upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE music_pieces ADD COLUMN thumbnailPath TEXT;");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE groups ADD COLUMN isHidden INTEGER DEFAULT 0;");
    }
    if (oldVersion < 4) {
      // Remove isDefault column if it exists
      // This is a more complex migration, often requiring a temp table
      // For simplicity, we'll just drop and recreate if it's a fresh install
      // or handle it in the Group model's fromJson for existing data.
      // If isDefault column exists, it will be ignored by the new Group model.
    }
  }

  /// Inserts initial dummy data into the database.
  static Future<void> insertDummyData(Database db) async {
    // Insert dummy data only if the database is newly created and the music_pieces table is empty
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM music_pieces'));
    if (count == 0) {
      for (final piece in dummyMusicPieces) {
        await db.insert('music_pieces', piece.toJson());
      }
    }
  }

  /// Performs one-time cleanup operations when the database is opened.
  static Future<void> performCleanup(Database db) async {
    // One-time cleanup: remove any old 'Default Group' entries
    await db.delete('groups', where: 'name = ?', whereArgs: ['Default Group']);
  }
} 