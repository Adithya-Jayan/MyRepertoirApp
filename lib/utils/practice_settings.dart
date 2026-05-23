import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for managing practice-related settings.
class PracticeSettings {
  static const String _showPracticeTimeStatsKey = 'show_practice_time_stats';
  static const String _showPracticeNotesKey = 'show_practice_notes';

  /// Gets whether practice time statistics should be shown.
  /// Defaults to false (only practice count is shown by default).
  static Future<bool> getShowPracticeTimeStats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showPracticeTimeStatsKey) ?? false;
  }

  /// Sets whether practice time statistics should be shown.
  static Future<void> setShowPracticeTimeStats(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPracticeTimeStatsKey, value);
  }

  /// Gets whether practice notes should be shown.
  /// Defaults to false.
  static Future<bool> getShowPracticeNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showPracticeNotesKey) ?? false;
  }

  /// Sets whether practice notes should be shown.
  static Future<void> setShowPracticeNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPracticeNotesKey, value);
  }
}
 