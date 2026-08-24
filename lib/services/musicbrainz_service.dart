import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Thrown when a MusicBrainz search or Cover Art Archive lookup fails
/// (network error, non-200 status, or an unexpected response shape).
class MusicBrainzException implements Exception {
  final String message;
  MusicBrainzException(this.message);

  @override
  String toString() => message;
}

/// One search result: a MusicBrainz recording (song), paired with one of
/// its releases (album/single) to source cover art from. [mbid] is the
/// RELEASE's id — not the recording's — since that's what the Cover Art
/// Archive is keyed by.
class MusicBrainzResult {
  final String mbid;
  final String title;
  final String artist;
  final String releaseTitle;
  final String? date;

  MusicBrainzResult({
    required this.mbid,
    required this.title,
    required this.artist,
    required this.releaseTitle,
    this.date,
  });

  /// Returns null if the entry is missing a title, a usable artist
  /// credit, or any release to source cover art from — such entries are
  /// skipped rather than shown as a broken result.
  static MusicBrainzResult? fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String) return null;

    String? artist;
    final artistCredit = json['artist-credit'];
    if (artistCredit is List && artistCredit.isNotEmpty) {
      final first = artistCredit.first;
      if (first is Map<String, dynamic> && first['name'] is String) {
        artist = first['name'] as String;
      }
    }
    if (artist == null) return null;

    final releases = json['releases'];
    if (releases is! List || releases.isEmpty) return null;
    final firstRelease = releases.first;
    if (firstRelease is! Map<String, dynamic>) return null;

    final mbid = firstRelease['id'];
    final releaseTitle = firstRelease['title'];
    if (mbid is! String || releaseTitle is! String) return null;

    final date = firstRelease['date'];

    return MusicBrainzResult(
      mbid: mbid,
      title: title,
      artist: artist,
      releaseTitle: releaseTitle,
      date: date is String ? date : null,
    );
  }
}

/// Thin client for MusicBrainz's public, key-less recording search
/// (https://musicbrainz.org/ws/2/recording/) and the Cover Art Archive
/// (https://coverartarchive.org). Recordings are searched — rather than
/// releases — because a user searches by song title, and a song's release
/// (album/single) title is very often different from the song title
/// itself; a recording search still returns each match's associated
/// releases inline, so no extra lookup call is needed to get a
/// Cover-Art-Archive-usable release id.
class MusicBrainzService {
  final http.Client _client;

  MusicBrainzService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _searchUrl = 'https://musicbrainz.org/ws/2/recording/';
  static const String _coverArtBaseUrl =
      'https://coverartarchive.org/release';
  static const Map<String, String> _headers = {
    'User-Agent': 'Repertoire Music App (Flutter)',
  };

  Future<List<MusicBrainzResult>> search({
    required String title,
    required String artist,
  }) async {
    final cleanTitle = title.replaceAll('"', '');
    final cleanArtist = artist.replaceAll('"', '');
    final query = cleanArtist.isEmpty
        ? 'recording:"$cleanTitle"'
        : 'recording:"$cleanTitle" AND artist:"$cleanArtist"';

    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: {'query': query, 'fmt': 'json', 'limit': '10'},
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw MusicBrainzException('Connection failed');
    }

    if (response.statusCode != 200) {
      throw MusicBrainzException('Server error (${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw MusicBrainzException('Invalid response');
    }

    if (decoded is! Map<String, dynamic> || decoded['recordings'] is! List) {
      throw MusicBrainzException('Unexpected response format');
    }

    final results = <MusicBrainzResult>[];
    for (final entry in decoded['recordings'] as List) {
      if (entry is Map<String, dynamic>) {
        final parsed = MusicBrainzResult.fromJson(entry);
        if (parsed != null) results.add(parsed);
      }
    }
    return results;
  }

  Future<Uint8List?> fetchCoverArtBytes(String mbid) async {
    final uri = Uri.parse('$_coverArtBaseUrl/$mbid/front-250');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw MusicBrainzException('Connection failed');
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw MusicBrainzException('Server error (${response.statusCode})');
    }

    return response.bodyBytes;
  }
}
