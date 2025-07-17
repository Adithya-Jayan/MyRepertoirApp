import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/tag.dart';
import 'package:repertoire/models/media_type.dart';

void main() {
  group('MediaType', () {
    test('should have correct values', () {
      expect(MediaType.values, [
        MediaType.markdown,
        MediaType.pdf,
        MediaType.image,
        MediaType.audio,
        MediaType.mediaLink,
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
      final json = {
        'id': 'mp1',
        'title': 'Test Piece',
        'artistComposer': 'Test Artist',
        
        'tags': ['Study', 'Practice'],
        'lastAccessed': DateTime.now().toIso8601String(),
        'isFavorite': true,
        'lastPracticeTime': DateTime.now().toIso8601String(),
        'practiceCount': 5,
        'enablePracticeTracking': true,
        'googleDriveFileId': 'gdrive123',
        'mediaItems': [
          {
            'id': 'mi1',
            'type': 'pdf',
            'pathOrUrl': '/path/to/score.pdf',
            'title': 'Score',
          }
        ],
      };
      final musicPiece = MusicPiece.fromJson(json);

      expect(musicPiece.id, 'mp1');
      expect(musicPiece.title, 'Test Piece');
      expect(musicPiece.artistComposer, 'Test Artist');
      
      
      
      expect(musicPiece.tags, ['Study', 'Practice']);
      expect(musicPiece.lastAccessed, isA<DateTime>());
      expect(musicPiece.isFavorite, true);
      expect(musicPiece.lastPracticeTime, isA<DateTime>());
      expect(musicPiece.practiceCount, 5);
      expect(musicPiece.enablePracticeTracking, true);
      expect(musicPiece.googleDriveFileId, 'gdrive123');
      expect(musicPiece.mediaItems.length, 1);
      expect(musicPiece.mediaItems[0].id, 'mi1');
    });

    test('toJson should convert MusicPiece to JSON correctly', () {
      final musicPiece = MusicPiece(
        id: 'mp1',
        title: 'Test Piece',
        artistComposer: 'Test Artist',
        
        tags: ['Study', 'Practice'],
        lastAccessed: DateTime.now(),
        isFavorite: true,
        lastPracticeTime: DateTime.now(),
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
      expect(json['genre'], ['Classical', 'Piano']);
      expect(json['instrumentation'], 'Piano');
      expect(json['difficulty'], 'Easy');
      expect(json['tags'], ['Study', 'Practice']);
      expect(json['lastAccessed'], isA<String>());
      expect(json['isFavorite'], true);
      expect(json['lastPracticeTime'], isA<String>());
      expect(json['practiceCount'], 5);
      expect(json['enablePracticeTracking'], true);
      expect(json['googleDriveFileId'], 'gdrive123');
      expect(json['mediaItems'], isA<List>());
      expect(json['mediaItems'][0]['id'], 'mi1');
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
