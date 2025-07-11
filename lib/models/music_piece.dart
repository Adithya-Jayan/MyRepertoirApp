import 'dart:convert';
import './media_item.dart';
import './tag_group.dart';

class MusicPiece {
  String id;  // e.g., Uuid.v4()
  String title;
  String artistComposer;
  List<String> tags;
  DateTime? lastAccessed;
  bool isFavorite;
  DateTime? lastPracticeTime;  // nullable
  int practiceCount;
  bool enablePracticeTracking;
  String? googleDriveFileId;  // nullable, for main piece data sync
  List<MediaItem> mediaItems;  // List of associated media
  List<String> groupIds;
  List<TagGroup> tagGroups;
  String? thumbnailPath; // Path to the thumbnail image

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

  // Add toJson() and fromJson() methods for MusicPiece
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artistComposer': artistComposer,
        'tags': jsonEncode(tags),
        'lastAccessed': lastAccessed?.toIso8601String(),
        'isFavorite': isFavorite ? 1 : 0,
        'lastPracticeTime': lastPracticeTime?.toIso8601String(),
        'practiceCount': practiceCount,
        'enablePracticeTracking': enablePracticeTracking ? 1 : 0,
        'googleDriveFileId': googleDriveFileId,
        'mediaItems': jsonEncode(mediaItems.map((item) => item.toJson()).toList()),
        'groupIds': jsonEncode(groupIds),
        'tagGroups': jsonEncode(tagGroups.map((e) => e.toJson()).toList()),
        'thumbnailPath': thumbnailPath,
      };

  factory MusicPiece.fromJson(Map<String, dynamic> json) => MusicPiece(
        id: json['id'],
        title: json['title'],
        artistComposer: json['artistComposer'],
        tags: List<String>.from(jsonDecode(json['tags'] ?? '[]')),
        lastAccessed: json['lastAccessed'] != null
            ? DateTime.parse(json['lastAccessed'])
            : null,
        isFavorite: (json['isFavorite'] as int) == 1,
        lastPracticeTime: json['lastPracticeTime'] != null
            ? DateTime.parse(json['lastPracticeTime'])
            : null,
        practiceCount: json['practiceCount'] ?? 0,
        enablePracticeTracking: (json['enablePracticeTracking'] as int) == 1,
        googleDriveFileId: json['googleDriveFileId'],
        mediaItems: (jsonDecode(json['mediaItems'] ?? '[]') as List<dynamic>)
                .map((itemJson) =>
                    MediaItem.fromJson(itemJson as Map<String, dynamic>))
                .toList(),
        groupIds: List<String>.from(jsonDecode(json['groupIds'] ?? '[]')),
        tagGroups: (jsonDecode(json['tagGroups'] ?? '[]') as List<dynamic>)
            .map((e) => TagGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        thumbnailPath: json['thumbnailPath'],
      );

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
      thumbnailPath: thumbnailPath,
    );
  }
}
