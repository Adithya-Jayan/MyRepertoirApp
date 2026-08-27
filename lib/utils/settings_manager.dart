
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

  /// Loads the hideEmptyGroups setting.
  bool loadHideEmptyGroups() {
    return prefs.getBool('hideEmptyGroups') ?? false;
  }

  /// Saves the hideEmptyGroups setting.
  Future<void> saveHideEmptyGroups(bool value) async {
    await prefs.setBool('hideEmptyGroups', value);
    AppLogger.log('SettingsManager: hideEmptyGroups saved: $value');
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

  /// Loads quick filters from SharedPreferences.
  Map<String, Map<String, dynamic>> loadQuickFilters() {
    final quickFiltersJson = prefs.getString('quickFilters');
    if (quickFiltersJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(quickFiltersJson);
        final Map<String, Map<String, dynamic>> result = {};

        decoded.forEach((name, options) {
          if (options is Map<String, dynamic>) {
            final Map<String, dynamic> processedOptions = Map<String, dynamic>.from(options);
            // Specially handle orderedTags to ensure correct types
            if (processedOptions.containsKey('orderedTags')) {
              final Map<String, dynamic> rawTags = processedOptions['orderedTags'];
              final Map<String, List<String>> orderedTags = {};
              rawTags.forEach((key, value) {
                if (value is List) {
                  orderedTags[key] = List<String>.from(value);
                }
              });
              processedOptions['orderedTags'] = orderedTags;
            }
            result[name] = processedOptions;
          }
        });

        AppLogger.log('SettingsManager: ${result.length} quick filters loaded');
        return result;
      } catch (e) {
        AppLogger.log('SettingsManager: Error decoding quick filters: $e');
      }
    }
    return {};
  }

  /// Saves quick filters to SharedPreferences.
  Future<void> saveQuickFilters(Map<String, Map<String, dynamic>> quickFilters) async {
    try {
      final jsonStr = jsonEncode(quickFilters);
      await prefs.setString('quickFilters', jsonStr);
      AppLogger.log('SettingsManager: Quick filters saved');
    } catch (e) {
      AppLogger.log('SettingsManager: Error encoding quick filters: $e');
    }
  }

  /// Renames a tag group key inside an `orderedTags` map.
  ///
  /// Pure helper used for active filters and saved quick filters.
  static Map<String, List<String>> renameTagGroupInOrderedTags(
    Map<String, List<String>> orderedTags,
    String oldName,
    String newName,
  ) {
    if (oldName == newName || !orderedTags.containsKey(oldName)) {
      return orderedTags;
    }

    final result = <String, List<String>>{};
    orderedTags.forEach((key, tags) {
      if (key == oldName) return;
      result[key] = List<String>.from(tags);
    });

    final oldTags = List<String>.from(orderedTags[oldName]!);
    if (result.containsKey(newName)) {
      final merged = List<String>.from(result[newName]!);
      for (final tag in oldTags) {
        if (!merged.contains(tag)) merged.add(tag);
      }
      result[newName] = merged;
    } else {
      result[newName] = oldTags;
    }
    return result;
  }

  /// Renames a tag value inside a specific group in an `orderedTags` map.
  static Map<String, List<String>> renameTagInOrderedTags(
    Map<String, List<String>> orderedTags,
    String groupName,
    String oldTagName,
    String newTagName,
  ) {
    if (oldTagName == newTagName || !orderedTags.containsKey(groupName)) {
      return orderedTags;
    }

    final result = <String, List<String>>{};
    orderedTags.forEach((key, tags) {
      if (key != groupName) {
        result[key] = List<String>.from(tags);
        return;
      }
      final updated = <String>[];
      for (final tag in tags) {
        final next = tag == oldTagName ? newTagName : tag;
        if (!updated.contains(next)) updated.add(next);
      }
      result[key] = updated;
    });
    return result;
  }

  /// Applies a tag-group rename to a single filter-options map.
  static Map<String, dynamic> renameTagGroupInFilterOptions(
    Map<String, dynamic> filterOptions,
    String oldName,
    String newName,
  ) {
    final copy = Map<String, dynamic>.from(filterOptions);
    final orderedTags = _extractOrderedTags(copy);
    if (orderedTags == null) return copy;
    copy['orderedTags'] =
        renameTagGroupInOrderedTags(orderedTags, oldName, newName);
    return copy;
  }

  /// Applies a tag rename to a single filter-options map.
  static Map<String, dynamic> renameTagInFilterOptions(
    Map<String, dynamic> filterOptions,
    String groupName,
    String oldTagName,
    String newTagName,
  ) {
    final copy = Map<String, dynamic>.from(filterOptions);
    final orderedTags = _extractOrderedTags(copy);
    if (orderedTags == null) return copy;
    copy['orderedTags'] = renameTagInOrderedTags(
      orderedTags,
      groupName,
      oldTagName,
      newTagName,
    );
    return copy;
  }

  static Map<String, List<String>>? _extractOrderedTags(
    Map<String, dynamic> filterOptions,
  ) {
    final raw = filterOptions['orderedTags'];
    if (raw is! Map) return null;
    final orderedTags = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        orderedTags[key.toString()] = List<String>.from(value);
      }
    });
    return orderedTags;
  }

  /// Updates persisted filter options and quick filters after a tag group rename.
  Future<void> syncTagGroupRenameInFilters(
    String oldName,
    String newName,
  ) async {
    if (oldName == newName) return;

    final filterOptions = loadFilterOptions();
    await saveFilterOptions(
      renameTagGroupInFilterOptions(filterOptions, oldName, newName),
    );

    final quickFilters = loadQuickFilters();
    if (quickFilters.isEmpty) return;

    final updated = <String, Map<String, dynamic>>{};
    quickFilters.forEach((name, options) {
      updated[name] =
          renameTagGroupInFilterOptions(options, oldName, newName);
    });
    await saveQuickFilters(updated);
    AppLogger.log(
      'SettingsManager: Synced tag group rename "$oldName" -> "$newName" in filters',
    );
  }

  /// Updates persisted filter options and quick filters after a tag rename.
  Future<void> syncTagRenameInFilters(
    String groupName,
    String oldTagName,
    String newTagName,
  ) async {
    if (oldTagName == newTagName) return;

    final filterOptions = loadFilterOptions();
    await saveFilterOptions(
      renameTagInFilterOptions(
        filterOptions,
        groupName,
        oldTagName,
        newTagName,
      ),
    );

    final quickFilters = loadQuickFilters();
    if (quickFilters.isEmpty) return;

    final updated = <String, Map<String, dynamic>>{};
    quickFilters.forEach((name, options) {
      updated[name] = renameTagInFilterOptions(
        options,
        groupName,
        oldTagName,
        newTagName,
      );
    });
    await saveQuickFilters(updated);
    AppLogger.log(
      'SettingsManager: Synced tag rename "$oldTagName" -> "$newTagName" '
      'in group "$groupName" in filters',
    );
  }
}
 