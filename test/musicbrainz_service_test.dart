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
              'recordings': [
                {
                  'id': 'recording-mbid-not-used-for-cover-art',
                  'title': 'La fine',
                  'artist-credit': [
                    {'name': 'Tiziano Ferro'},
                  ],
                  'releases': [
                    {
                      'id': 'release-abc-123',
                      'title': 'TZN: The Best of Tiziano Ferro',
                      'date': '2012-05-04',
                    },
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(
          title: 'La fine',
          artist: 'Tiziano Ferro',
        );

        expect(results, hasLength(1));
        expect(results[0].mbid, 'release-abc-123');
        expect(results[0].title, 'La fine');
        expect(results[0].artist, 'Tiziano Ferro');
        expect(results[0].releaseTitle, 'TZN: The Best of Tiziano Ferro');
        expect(results[0].date, '2012-05-04');
      });

      test('skips entries missing title', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'recordings': [
                {
                  'artist-credit': [
                    {'name': 'Someone'},
                  ],
                  'releases': [
                    {'id': 'r1', 'title': 'Some Release'},
                  ],
                },
                {
                  'id': 'rec-2',
                  'title': 'Valid',
                  'artist-credit': [
                    {'name': 'Valid Artist'},
                  ],
                  'releases': [
                    {'id': 'r2', 'title': 'Valid Release'},
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
              'recordings': [
                {
                  'id': 'no-artist',
                  'title': 'No Artist',
                  'artist-credit': [],
                  'releases': [
                    {'id': 'r1', 'title': 'Some Release'},
                  ],
                },
              ],
            }),
            200,
          );
        });
        final service = MusicBrainzService(client: mockClient);

        final results = await service.search(title: 'x', artist: 'y');

        expect(results, isEmpty);
      });

      test('skips entries with no releases (nothing to fetch cover art for)', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'recordings': [
                {
                  'id': 'no-release',
                  'title': 'No Release',
                  'artist-credit': [
                    {'name': 'Someone'},
                  ],
                  'releases': [],
                },
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
        'throws MusicBrainzException when response has no recordings array',
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
