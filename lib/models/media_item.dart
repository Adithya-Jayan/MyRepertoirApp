import './media_type.dart'; // Import for MediaType enum
import '../utils/path_utils.dart';

/// Represents a single media attachment associated with a music piece.
///
/// This class defines the structure for various types of media,
/// such as PDF files, audio files, video links, or markdown notes.
class MediaItem {
  String id; // Unique ID for this media item
  MediaType type; // The type of media (e.g., PDF, Audio, VideoLink)
  String pathOrUrl; // Local file path or external URL of the media
  String? title; // Optional title for the media item (e.g., 'Verse 1 Notes')
  String? description; // Optional description of the media content
  String? googleDriveFileId; // Google Drive file ID if the media is synced to Drive (nullable)
  String? thumbnailPath; // Local path to the thumbnail for video links

  /// Constructor for the MediaItem class.
  MediaItem({
    required this.id,
    required this.type,
    required this.pathOrUrl,
    this.title,
    this.description,
    this.googleDriveFileId,
    this.thumbnailPath,
  });

  /// Converts a [MediaItem] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name, // Store the enum name as a string
        'pathOrUrl': pathOrUrl,
        'title': title,
        'description': description,
        'googleDriveFileId': googleDriveFileId,
        'thumbnailPath': thumbnailPath,
      };

  /// Creates a [MediaItem] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'],
        type: MediaType.values.firstWhere((e) => e.name == json['type']), // Convert string back to MediaType enum
        pathOrUrl: json['pathOrUrl'],
        title: json['title'],
        description: json['description'],
        googleDriveFileId: json['googleDriveFileId'],
        thumbnailPath: json['thumbnailPath'],
      );

  /// Converts a [MediaItem] object into a JSON-compatible Map for backup.
  Map<String, dynamic> toJsonForBackup(String storagePath) => {
        'id': id,
        'type': type.name,
        'pathOrUrl': getRelativePath(pathOrUrl, storagePath),
        'title': title,
        'description': description,
        'googleDriveFileId': googleDriveFileId,
        'thumbnailPath': thumbnailPath != null ? getRelativePath(thumbnailPath!, storagePath) : null,
      };

  /// Creates a [MediaItem] object from a JSON-compatible Map for backup.
  factory MediaItem.fromJsonForBackup(Map<String, dynamic> json, String storagePath) => MediaItem(
        id: json['id'],
        type: MediaType.values.firstWhere((e) => e.name == json['type']),
        pathOrUrl: getAbsolutePath(json['pathOrUrl'], storagePath),
        title: json['title'],
        description: json['description'],
        googleDriveFileId: json['googleDriveFileId'],
        thumbnailPath: json['thumbnailPath'] != null ? getAbsolutePath(json['thumbnailPath'], storagePath) : null,
      );

  MediaItem copyWith({
    String? id,
    MediaType? type,
    String? pathOrUrl,
    String? title,
    String? description,
    String? googleDriveFileId,
    String? thumbnailPath,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      pathOrUrl: pathOrUrl ?? this.pathOrUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      googleDriveFileId: googleDriveFileId ?? this.googleDriveFileId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
