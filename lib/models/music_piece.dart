import 'dart:convert'; // For JSON encoding and decoding
import './media_item.dart'; // Import for MediaItem model
import './tag_group.dart'; // Import for TagGroup model

/// Represents a single music piece in the repertoire.
///
/// This class holds all the details about a music piece, including its metadata,
/// practice tracking information, associated media, and organizational groups/tags.
class MusicPiece {
  String id; // Unique identifier for the music piece (e.g., Uuid.v4())
  String title; // Title of the music piece
  String artistComposer; // Artist or composer of the music piece
  List<String> tags; // List of tags associated with the piece
  DateTime? lastAccessed; // Timestamp of when the piece was last accessed
  bool isFavorite; // Indicates if the piece is marked as a favorite
  DateTime? lastPracticeTime; // Timestamp of the last practice session (nullable)
  int practiceCount; // Number of practice sessions recorded
  bool enablePracticeTracking; // Flag to enable/disable practice tracking for this piece
  String? googleDriveFileId; // Google Drive file ID for main piece data sync (nullable)
  List<MediaItem> mediaItems; // List of associated media items (sheet music, audio, etc.)
  List<String> groupIds; // List of group IDs this music piece belongs to
  List<TagGroup> tagGroups; // List of TagGroup objects associated with the piece
  String? thumbnailPath; // Path to the thumbnail image for the piece (nullable)

  /// Constructor for the MusicPiece class.
  MusicPiece({
    required this.id,
    required this.title,
    required this.artistComposer,
    this.tags = const [],
    this.lastAccessed,
    this.isFavorite = false,
    this.lastPracticeTime,
    this.practiceCount = 0,
    this.enablePracticeTracking = false,
    this.googleDriveFileId,
    this.mediaItems = const [],
    this.groupIds = const [],
    this.tagGroups = const [],
    this.thumbnailPath,
  });

  /// Converts a [MusicPiece] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artistComposer': artistComposer,
        'tags': jsonEncode(tags), // Encode list of strings to JSON string
        'lastAccessed': lastAccessed?.toIso8601String(), // Convert DateTime to ISO 8601 string
        'isFavorite': isFavorite ? 1 : 0, // Convert boolean to integer (0 or 1)
        'lastPracticeTime': lastPracticeTime?.toIso8601String(),
        'practiceCount': practiceCount,
        'enablePracticeTracking': enablePracticeTracking ? 1 : 0,
        'googleDriveFileId': googleDriveFileId,
        'mediaItems': jsonEncode(mediaItems.map((item) => item.toJson()).toList()), // Encode list of MediaItem to JSON string
        'groupIds': jsonEncode(groupIds), // Encode list of strings to JSON string
        'tagGroups': jsonEncode(tagGroups.map((e) => e.toJson()).toList()), // Encode list of TagGroup to JSON string
        'thumbnailPath': thumbnailPath,
      };

  /// Creates a [MusicPiece] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory MusicPiece.fromJson(Map<String, dynamic> json) => MusicPiece(
        id: json['id'],
        title: json['title'],
        artistComposer: json['artistComposer'],
        tags: List<String>.from(jsonDecode(json['tags'] ?? '[]')), // Decode JSON string to List<String>
        lastAccessed: json['lastAccessed'] != null
            ? DateTime.parse(json['lastAccessed']) // Parse ISO 8601 string to DateTime
            : null,
        isFavorite: (json['isFavorite'] as int) == 1, // Convert integer (0 or 1) to boolean
        lastPracticeTime: json['lastPracticeTime'] != null
            ? DateTime.parse(json['lastPracticeTime']) // Parse ISO 8601 string to DateTime
            : null,
        practiceCount: json['practiceCount'] ?? 0,
        enablePracticeTracking: (json['enablePracticeTracking'] as int) == 1,
        googleDriveFileId: json['googleDriveFileId'],
        mediaItems: (jsonDecode(json['mediaItems'] ?? '[]') as List<dynamic>)
                .map((itemJson) =>
                    MediaItem.fromJson(itemJson as Map<String, dynamic>)) // Decode JSON string to List<MediaItem>
                .toList(),
        groupIds: List<String>.from(jsonDecode(json['groupIds'] ?? '[]')), // Decode JSON string to List<String>
        tagGroups: (jsonDecode(json['tagGroups'] ?? '[]') as List<dynamic>)
            .map((e) => TagGroup.fromJson(e as Map<String, dynamic>))
            .toList(), // Decode JSON string to List<TagGroup>
        thumbnailPath: json['thumbnailPath'],
      );

  /// Creates a copy of this [MusicPiece] object with optional new values.
  ///
  /// This method is useful for immutably updating properties of a music piece.
  MusicPiece copyWith({
    String? id,
    String? title,
    String? artistComposer,
    List<String>? tags,
    DateTime? lastAccessed,
    bool? isFavorite,
    DateTime? lastPracticeTime,
    int? practiceCount,
    bool? enablePracticeTracking,
    String? googleDriveFileId,
    List<MediaItem>? mediaItems,
    List<String>? groupIds,
    List<TagGroup>? tagGroups,
    String? thumbnailPath,
  }) {
    return MusicPiece(
      id: id ?? this.id,
      title: title ?? this.title,
      artistComposer: artistComposer ?? this.artistComposer,
      tags: tags ?? this.tags,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPracticeTime: lastPracticeTime ?? this.lastPracticeTime,
      practiceCount: practiceCount ?? this.practiceCount,
      enablePracticeTracking: enablePracticeTracking ?? this.enablePracticeTracking,
      googleDriveFileId: googleDriveFileId ?? this.googleDriveFileId,
      mediaItems: mediaItems ?? this.mediaItems,
      groupIds: groupIds ?? this.groupIds,
      tagGroups: tagGroups ?? this.tagGroups,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
