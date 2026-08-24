import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when a lrclib.net search fails (network error, non-200 status,
/// or a response that isn't the JSON array the API is documented to return).
class LrcLibException implements Exception {
  final String message;
  LrcLibException(this.message);

  @override
  String toString() => message;
}

/// One search result from lrclib.net.
class LrcLibResult {
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? durationSeconds;
  final String? plainLyrics;

  LrcLibResult({
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.durationSeconds,
    this.plainLyrics,
  });

  /// Returns null if the entry is missing a track or artist name — such
  /// entries are skipped rather than shown as a broken result.
  static LrcLibResult? fromJson(Map<String, dynamic> json) {
    final trackName = json['trackName'];
    final artistName = json['artistName'];
    if (trackName is! String || artistName is! String) return null;

    final duration = json['duration'];
    final albumName = json['albumName'];
    final plainLyrics = json['plainLyrics'];

    return LrcLibResult(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName is String ? albumName : null,
      durationSeconds: duration is num ? duration.round() : null,
      plainLyrics: plainLyrics is String ? plainLyrics : null,
    );
  }
}

/// Thin client for lrclib.net's public, key-less search API
/// (https://lrclib.net/api/search).
class LrcLibService {
  final http.Client _client;

  LrcLibService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://lrclib.net/api/search';

  Future<List<LrcLibResult>> search({
    required String trackName,
    required String artistName,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'track_name': trackName,
        if (artistName.isNotEmpty) 'artist_name': artistName,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'Repertoire Music App (Flutter)'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw LrcLibException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw LrcLibException(
        'lrclib.net returned status ${response.statusCode}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw LrcLibException('Invalid response from lrclib.net');
    }

    if (decoded is! List) {
      throw LrcLibException('Unexpected response format from lrclib.net');
    }

    final results = <LrcLibResult>[];
    for (final entry in decoded) {
      if (entry is Map<String, dynamic>) {
        final parsed = LrcLibResult.fromJson(entry);
        if (parsed != null) results.add(parsed);
      }
    }
    return results;
  }
}
