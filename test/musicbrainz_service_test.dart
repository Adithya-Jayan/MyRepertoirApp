import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repertoire/services/musicbrainz_service.dart';

void main() {
  group('MusicBrainzService', () {
    group('search', () {
      test('parses a well-formed response into a list of results', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {
                  'id': 'abc-123',
                  'title': 'A Night at the Opera',
                  'date': '1975-11-21',
                  'artist-credit': [
                    {'name': 'Queen'},
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
        );

        expect(results, hasLength(1));
        expect(results[0].mbid, 'abc-123');
        expect(results[0].title, 'A Night at the Opera');
        expect(results[0].artist, 'Queen');
        expect(results[0].date, '1975-11-21');
      });

      test('skips entries missing id or title', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {
                  'title': 'No ID',
                  'artist-credit': [
                    {'name': 'Someone'},
                  ],
                },
                {
                  'id': 'valid-1',
                  'title': 'Valid',
                  'artist-credit': [
                    {'name': 'Valid Artist'},
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(title: 'x', artist: 'y');

        expect(results, hasLength(1));
        expect(results[0].title, 'Valid');
      });

      test('skips entries with empty or missing artist-credit', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'releases': [
                {'id': 'no-artist', 'title': 'No Artist', 'artist-credit': []},
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(title: 'x', artist: 'y');

        expect(results, isEmpty);
      });

      test('throws MusicBrainzException on non-200 status', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });
        final service = MusicBrainzService(client: mockClient);

        expect(
          () => service.search(title: 'x', artist: 'y'),
          throwsA(isA<MusicBrainzException>()),
        );
      });

      test(
        'throws MusicBrainzException when response has no releases array',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response(jsonEncode({'error': 'nope'}), 200);
          });
          final service = MusicBrainzService(client: mockClient);

          expect(
            () => service.search(title: 'x', artist: 'y'),
            throwsA(isA<MusicBrainzException>()),
          );
        },
      );
    });

    group('fetchCoverArtBytes', () {
      test('returns bytes on 200', () async {
        final mockClient = MockClient((request) async {
          return http.Response.bytes([1, 2, 3, 4], 200);
        });
        final service = MusicBrainzService(client: mockClient);

        final bytes = await service.fetchCoverArtBytes('abc-123');

        expect(bytes, [1, 2, 3, 4]);
      });

      test('returns null on 404 (no cover art)', () async {
        final mockClient = MockClient((request) async {
          return http.Response('', 404);
        });
        final service = MusicBrainzService(client: mockClient);

        final bytes = await service.fetchCoverArtBytes('abc-123');

        expect(bytes, isNull);
      });

      test('throws MusicBrainzException on server error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });
        final service = MusicBrainzService(client: mockClient);

        expect(
          () => service.fetchCoverArtBytes('abc-123'),
          throwsA(isA<MusicBrainzException>()),
        );
      });
    });
  });
}
