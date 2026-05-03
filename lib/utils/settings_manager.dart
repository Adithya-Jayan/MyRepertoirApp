
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// A utility class that manages application settings.
/// This is extracted from LibraryScreenNotifier to reduce file size and improve organization.
class SettingsManager {
  late SharedPreferences prefs;
  final ValueNotifier<int> galleryColumnsNotifier;

  SettingsManager(this.galleryColumnsNotifier);

  /// Initializes the settings manager by loading SharedPreferences.
  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// Loads gallery columns setting from SharedPreferences.
  Future<void> loadGalleryColumns() async {
    AppLogger.log('SettingsManager: loadGalleryColumns called');
    int defaultColumns;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      defaultColumns = 4;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      defaultColumns = 6;
    } else {
      defaultColumns = 2;
    }
    final loadedColumns = prefs.getInt('galleryColumns') ?? defaultColumns;
    AppLogger.log('SettingsManager: Setting galleryColumns from ${galleryColumnsNotifier.value} to $loadedColumns');
    galleryColumnsNotifier.value = loadedColumns;
    AppLogger.log('SettingsManager: galleryColumns updated to: ${galleryColumnsNotifier.value}');
  }

  /// Saves gallery columns setting to SharedPreferences.
  Future<void> saveGalleryColumns(int columns) async {
    await prefs.setInt('galleryColumns', columns);
    galleryColumnsNotifier.value = columns;
    AppLogger.log('SettingsManager: galleryColumns saved: $columns');
  }

  /// Loads group order settings from SharedPreferences.
  Map<String, dynamic> loadGroupOrderSettings() {
    final allGroupOrder = prefs.getInt('all_group_order') ?? -2;
    final allGroupIsHidden = prefs.getBool('all_group_isHidden') ?? true;
    final ungroupedGroupOrder = prefs.getInt('ungrouped_group_order') ?? -1;
    final ungroupedGroupIsHidden = prefs.getBool('ungrouped_group_isHidden') ?? false;

    return {
      'allGroupOrder': allGroupOrder,
      'allGroupIsHidden': allGroupIsHidden,
      'ungroupedGroupOrder': ungroupedGroupOrder,
      'ungroupedGroupIsHidden': ungroupedGroupIsHidden,
    };
  }

  /// Saves group order settings to SharedPreferences.
  Future<void> saveGroupOrderSettings(Map<String, dynamic> settings) async {
    await prefs.setInt('all_group_order', settings['allGroupOrder']);
    await prefs.setBool('all_group_isHidden', settings['allGroupIsHidden']);
    await prefs.setInt('ungrouped_group_order', settings['ungroupedGroupOrder']);
    await prefs.setBool('ungrouped_group_isHidden', settings['ungroupedGroupIsHidden']);
    AppLogger.log('SettingsManager: Group order settings saved');
  }

  /// Loads sort option setting from SharedPreferences.
  String loadSortOption() {
    return prefs.getString('sortOption') ?? 'alphabetical_asc';
  }

  /// Saves sort option setting to SharedPreferences.
  Future<void> saveSortOption(String sortOption) async {
    await prefs.setString('sortOption', sortOption);
    AppLogger.log('SettingsManager: Sort option saved: $sortOption');
  }

  /// Loads filter options from SharedPreferences.
  Map<String, dynamic> loadFilterOptions() {
    final filterJson = prefs.getString('filterOptions');
    if (filterJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(filterJson);

        // Specially handle orderedTags to ensure correct types
        if (decoded.containsKey('orderedTags')) {
          final Map<String, dynamic> rawTags = decoded['orderedTags'];
          final Map<String, List<String>> orderedTags = {};
          rawTags.forEach((key, value) {
            if (value is List) {
              orderedTags[key] = List<String>.from(value);
            }
          });
          decoded['orderedTags'] = orderedTags;
        }

        AppLogger.log('SettingsManager: Filter options loaded');
        return decoded;
      } catch (e) {
        AppLogger.log('SettingsManager: Error decoding filter options: $e');
      }
    }
    return {'orderedTags': <String, List<String>>{}};
  }

  /// Saves filter options to SharedPreferences.
  Future<void> saveFilterOptions(Map<String, dynamic> filterOptions) async {
    try {
      final jsonStr = jsonEncode(filterOptions);
      await prefs.setString('filterOptions', jsonStr);
      AppLogger.log('SettingsManager: Filter options saved');
    } catch (e) {
      AppLogger.log('SettingsManager: Error encoding filter options: $e');
    }
  }
}
 