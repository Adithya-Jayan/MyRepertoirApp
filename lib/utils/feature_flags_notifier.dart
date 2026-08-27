import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the opt-in "skill-specific" features (transpose field, lyrics
/// search, MusicBrainz search) that are hidden from the default UI so the
/// app stays uncluttered for performers who don't need them.
///
/// All flags default to false: Repertoire is a universal tool for many
/// kinds of performers, so music-specific tooling must be enabled explicitly
/// rather than shown by default.
class FeatureFlagsNotifier with ChangeNotifier {
  static const transposeFieldKey = 'feature_transpose_field_enabled';
  static const lyricsSearchKey = 'feature_lyrics_search_enabled';
  static const musicBrainzSearchKey = 'feature_musicbrainz_search_enabled';

  bool _transposeFieldEnabled = false;
  bool _lyricsSearchEnabled = false;
  bool _musicBrainzSearchEnabled = false;

  bool get transposeFieldEnabled => _transposeFieldEnabled;
  bool get lyricsSearchEnabled => _lyricsSearchEnabled;
  bool get musicBrainzSearchEnabled => _musicBrainzSearchEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _transposeFieldEnabled = prefs.getBool(transposeFieldKey) ?? false;
    _lyricsSearchEnabled = prefs.getBool(lyricsSearchKey) ?? false;
    _musicBrainzSearchEnabled = prefs.getBool(musicBrainzSearchKey) ?? false;
    notifyListeners();
  }

  Future<void> setTransposeFieldEnabled(bool value) async {
    if (_transposeFieldEnabled == value) return;
    _transposeFieldEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(transposeFieldKey, value);
  }

  Future<void> setLyricsSearchEnabled(bool value) async {
    if (_lyricsSearchEnabled == value) return;
    _lyricsSearchEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(lyricsSearchKey, value);
  }

  Future<void> setMusicBrainzSearchEnabled(bool value) async {
    if (_musicBrainzSearchEnabled == value) return;
    _musicBrainzSearchEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(musicBrainzSearchKey, value);
  }
}
