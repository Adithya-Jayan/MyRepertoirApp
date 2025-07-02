import './media_type.dart';

class MediaItem {
  String id;  // Unique ID for this media item
  MediaType type;
  String pathOrUrl;  // Local file path or external URL
  String? title;  // Optional title for the media item (e.g., 'Verse 1 Notes')
  String? description;  // Optional description
  String? googleDriveFileId; // Google Drive file ID if synced
  // Add other properties like file size, duration for audio/video, etc.

  MediaItem({
    required this.id,
    required this.type,
    required this.pathOrUrl,
    this.title,
    this.description,
    this.googleDriveFileId,
  });

  // Add toJson() and fromJson() methods for MediaItem
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'pathOrUrl': pathOrUrl,
        'title': title,
        'description': description,
        'googleDriveFileId': googleDriveFileId,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'],
        type: MediaType.values.firstWhere((e) => e.name == json['type']),
        pathOrUrl: json['pathOrUrl'],
        title: json['title'],
        description: json['description'],
        googleDriveFileId: json['googleDriveFileId'],
      );
}
