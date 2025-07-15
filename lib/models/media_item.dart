import './media_type.dart'; // Import for MediaType enum

/// Represents a single media attachment associated with a music piece.
///
/// This class defines the structure for various types of media,
/// such as PDF sheet music, audio recordings, video links, or markdown notes.
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
}
