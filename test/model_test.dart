import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/tag.dart';
import 'package:repertoire/models/media_type.dart';
import 'dart:convert';

void main() {
  group('MediaType', () {
    test('should have correct values', () {
      expect(MediaType.values, [
        MediaType.markdown,
        MediaType.pdf,
        MediaType.image,
        MediaType.audio,
        MediaType.mediaLink,
        MediaType.thumbnails,
        MediaType.learningProgress,
        MediaType.localVideo,
        MediaType.midi,
        MediaType.lyrics,
      ]);
    });
  });

  group('MediaItem', () {
    test('fromJson should create a valid MediaItem from JSON', () {
      final json = {
        'id': '123',
        'type': 'pdf',
        'pathOrUrl': '/path/to/file.pdf',
        'title': 'My PDF',
        'description': 'A test PDF',
      };
      final mediaItem = MediaItem.fromJson(json);

      expect(mediaItem.id, '123');
      expect(mediaItem.type, MediaType.pdf);
      expect(mediaItem.pathOrUrl, '/path/to/file.pdf');
      expect(mediaItem.title, 'My PDF');
      expect(mediaItem.description, 'A test PDF');
    });

    test('toJson should convert MediaItem to JSON correctly', () {
      final mediaItem = MediaItem(
        id: '123',
        type: MediaType.image,
        pathOrUrl: 'http://example.com/image.png',
        title: 'My Image',
        description: 'A test image',
      );
      final json = mediaItem.toJson();

      expect(json['id'], '123');
      expect(json['type'], 'image');
      expect(json['pathOrUrl'], 'http://example.com/image.png');
      expect(json['title'], 'My Image');
      expect(json['description'], 'A test image');
    });
  });

  group('MusicPiece', () {
    test('fromJson should create a valid MusicPiece from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': 'mp1',
        'title': 'Test Piece',
        'artistComposer': 'Test Artist',
        'tags': jsonEncode(['Study', 'Practice']),
        'lastAccessed': now.toIso8601String(),
        'isFavorite': 1,
        'lastPracticeTime': now.toIso8601String(),
        'practiceCount': 5,
        'enablePracticeTracking': 1,
        'googleDriveFileId': 'gdrive123',
        'mediaItems': jsonEncode([
          {
            'id': 'mi1',
            'type': 'pdf',
            'pathOrUrl': '/path/to/score.pdf',
            'title': 'Score',
          }
        ]),
        'groupIds': jsonEncode([]),
        'tagGroups': jsonEncode([]),
        'bookmarks': jsonEncode([]),
      };
      final musicPiece = MusicPiece.fromJson(json);

      expect(musicPiece.id, 'mp1');
      expect(musicPiece.title, 'Test Piece');
      expect(musicPiece.artistComposer, 'Test Artist');
      expect(musicPiece.tags, ['Study', 'Practice']);
      expect(musicPiece.lastAccessed!.toIso8601String(), now.toIso8601String());
      expect(musicPiece.isFavorite, true);
      expect(musicPiece.lastPracticeTime!.toIso8601String(), now.toIso8601String());
      expect(musicPiece.practiceCount, 5);
      expect(musicPiece.enablePracticeTracking, true);
      expect(musicPiece.googleDriveFileId, 'gdrive123');
      expect(musicPiece.mediaItems.length, 1);
      expect(musicPiece.mediaItems[0].id, 'mi1');
    });

    test('toJson should convert MusicPiece to JSON correctly', () {
      final now = DateTime.now();
      final musicPiece = MusicPiece(
        id: 'mp1',
        title: 'Test Piece',
        artistComposer: 'Test Artist',
        tags: ['Study', 'Practice'],
        lastAccessed: now,
        isFavorite: true,
        lastPracticeTime: now,
        practiceCount: 5,
        enablePracticeTracking: true,
        googleDriveFileId: 'gdrive123',
        mediaItems: [
          MediaItem(
            id: 'mi1',
            type: MediaType.pdf,
            pathOrUrl: '/path/to/score.pdf',
            title: 'Score',
          )
        ],
      );
      final json = musicPiece.toJson();

      expect(json['id'], 'mp1');
      expect(json['title'], 'Test Piece');
      expect(json['artistComposer'], 'Test Artist');
      expect(jsonDecode(json['tags']), ['Study', 'Practice']);
      expect(json['lastAccessed'], now.toIso8601String());
      expect(json['isFavorite'], 1);
      expect(json['lastPracticeTime'], now.toIso8601String());
      expect(json['practiceCount'], 5);
      expect(json['enablePracticeTracking'], 1);
      expect(json['googleDriveFileId'], 'gdrive123');
      expect(jsonDecode(json['mediaItems']), isA<List>());
      expect(jsonDecode(json['mediaItems'])[0]['id'], 'mi1');
    });

    test('transposeSemitones defaults to 0 when absent from JSON', () {
      final json = {
        'id': 'mp1',
        'title': 'Test Piece',
        'artistComposer': 'Test Artist',
        'tags': jsonEncode([]),
        'isFavorite': 0,
        'practiceCount': 0,
        'enablePracticeTracking': 0,
        'mediaItems': jsonEncode([]),
        'groupIds': jsonEncode([]),
        'tagGroups': jsonEncode([]),
        'bookmarks': jsonEncode([]),
      };
      final musicPiece = MusicPiece.fromJson(json);
      expect(musicPiece.transposeSemitones, 0);
    });

    test('transposeSemitones round-trips through toJson/fromJson', () {
      final musicPiece = MusicPiece(
        id: 'mp1',
        title: 'Test Piece',
        artistComposer: 'Test Artist',
        transposeSemitones: -3,
      );

      final json = musicPiece.toJson();
      expect(json['transposeSemitones'], -3);

      final roundTripped = MusicPiece.fromJson(json);
      expect(roundTripped.transposeSemitones, -3);
    });

    test('MediaItem with type lyrics keeps pathOrUrl as inline text through backup round-trip', () {
      final item = MediaItem(
        id: 'lyr1',
        type: MediaType.lyrics,
        pathOrUrl: 'Line one\nLine two',
      );

      final json = item.toJsonForBackup('/some/storage/path');
      expect(json['pathOrUrl'], 'Line one\nLine two');

      final roundTripped = MediaItem.fromJsonForBackup(json, '/some/storage/path');
      expect(roundTripped.pathOrUrl, 'Line one\nLine two');
    });
  });

  group('Tag', () {
    test('fromJson should create a valid Tag from JSON', () {
      final json = {
        'id': 'tag1',
        'name': 'Classical',
        'color': 123456,
        'type': 'genre',
      };
      final tag = Tag.fromJson(json);

      expect(tag.id, 'tag1');
      expect(tag.name, 'Classical');
      expect(tag.color, 123456);
      expect(tag.type, 'genre');
    });

    test('toJson should convert Tag to JSON correctly', () {
      final tag = Tag(
        id: 'tag1',
        name: 'Classical',
        color: 123456,
        type: 'genre',
      );
      final json = tag.toJson();

      expect(json['id'], 'tag1');
      expect(json['name'], 'Classical');
      expect(json['color'], 123456);
      expect(json['type'], 'genre');
    });
  });
}
