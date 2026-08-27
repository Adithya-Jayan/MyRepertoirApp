import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repertoire/services/lrclib_service.dart';

void main() {
  group('LrcLibService', () {
    test('parses a well-formed response into a list of results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'trackName': 'Test Song',
              'artistName': 'Test Artist',
              'albumName': 'Test Album',
              'duration': 210.5,
              'plainLyrics': 'La la la',
            },
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(
        trackName: 'Test Song',
        artistName: 'Test Artist',
      );

      expect(results, hasLength(1));
      expect(results[0].trackName, 'Test Song');
      expect(results[0].artistName, 'Test Artist');
      expect(results[0].albumName, 'Test Album');
      expect(results[0].durationSeconds, 211);
      expect(results[0].plainLyrics, 'La la la');
    });

    test('includes entries with null plainLyrics', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'trackName': 'Instrumental',
              'artistName': 'Someone',
              'plainLyrics': null,
            },
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(
        trackName: 'Instrumental',
        artistName: 'Someone',
      );

      expect(results, hasLength(1));
      expect(results[0].plainLyrics, isNull);
    });

    test('skips entries missing trackName or artistName', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'artistName': 'No Track Name'},
            {'trackName': 'Valid', 'artistName': 'Valid Artist'},
          ]),
          200,
        );
      });
      final service = LrcLibService(client: mockClient);

      final results = await service.search(trackName: 'x', artistName: 'y');

      expect(results, hasLength(1));
      expect(results[0].trackName, 'Valid');
    });

    test('throws LrcLibException on non-200 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = LrcLibService(client: mockClient);

      expect(
        () => service.search(trackName: 'x', artistName: 'y'),
        throwsA(isA<LrcLibException>()),
      );
    });

    test('throws LrcLibException when response is not a JSON array', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'not an array'}), 200);
      });
      final service = LrcLibService(client: mockClient);

      expect(
        () => service.search(trackName: 'x', artistName: 'y'),
        throwsA(isA<LrcLibException>()),
      );
    });
  });
}
