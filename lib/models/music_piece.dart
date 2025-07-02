import './media_item.dart';

class MusicPiece {
  String id;  // e.g., Uuid.v4()
  String title;
  String artistComposer;
  List<String> genre;  // or String
  String instrumentation;
  String difficulty;  // or Enum
  List<String> tags;
  DateTime? lastAccessed;
  bool isFavorite;
  DateTime? lastPracticeTime;  // nullable
  int practiceCount;
  bool enablePracticeTracking;
  String? googleDriveFileId;  // nullable, for main piece data sync
  List<MediaItem> mediaItems;  // List of associated media

  MusicPiece({
    required this.id,
    required this.title,
    required this.artistComposer,
    this.genre = const [],
    this.instrumentation = '',
    this.difficulty = '',
    this.tags = const [],
    this.lastAccessed,
    this.isFavorite = false,
    this.lastPracticeTime,
    this.practiceCount = 0,
    this.enablePracticeTracking = false,
    this.googleDriveFileId,
    this.mediaItems = const [],
  });

  // Add toJson() and fromJson() methods for MusicPiece
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artistComposer': artistComposer,
        'genre': genre,
        'instrumentation': instrumentation,
        'difficulty': difficulty,
        'tags': tags,
        'lastAccessed': lastAccessed?.toIso8601String(),
        'isFavorite': isFavorite,
        'lastPracticeTime': lastPracticeTime?.toIso8601String(),
        'practiceCount': practiceCount,
        'enablePracticeTracking': enablePracticeTracking,
        'googleDriveFileId': googleDriveFileId,
        'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
      };

  factory MusicPiece.fromJson(Map<String, dynamic> json) => MusicPiece(
        id: json['id'],
        title: json['title'],
        artistComposer: json['artistComposer'],
        genre: List<String>.from(json['genre'] ?? []),
        instrumentation: json['instrumentation'] ?? '',
        difficulty: json['difficulty'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        lastAccessed: json['lastAccessed'] != null
            ? DateTime.parse(json['lastAccessed'])
            : null,
        isFavorite: json['isFavorite'] ?? false,
        lastPracticeTime: json['lastPracticeTime'] != null
            ? DateTime.parse(json['lastPracticeTime'])
            : null,
        practiceCount: json['practiceCount'] ?? 0,
        enablePracticeTracking: json['enablePracticeTracking'] ?? false,
        googleDriveFileId: json['googleDriveFileId'],
        mediaItems: (json['mediaItems'] as List<dynamic>?)
                ?.map((itemJson) =>
                    MediaItem.fromJson(itemJson as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
