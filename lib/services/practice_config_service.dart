import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/practice_stage.dart';
import 'package:repertoire/l10n/app_localizations.dart';

class PracticeConfigService {
  static const String _stagesKey = 'practice_stages';
  static List<PracticeStage>? _cachedStages;

  static List<PracticeStage>? get cachedStages => _cachedStages;

  static void clearCache() {
    _cachedStages = null;
  }

  Future<List<PracticeStage>> loadStages() async {
    // If already cached, return it (optional: add a forceRefresh parameter if needed)
    // But we should probably refresh from disk to be safe, then update cache.
    // For now, let's read from disk to ensure freshness but update the cache.

    final prefs = await SharedPreferences.getInstance();
    final String? stagesJson = prefs.getString(_stagesKey);

    List<PracticeStage> stages;
    if (stagesJson != null) {
      // Load from new format
      final List<dynamic> decoded = jsonDecode(stagesJson);
      stages = decoded.map((e) => PracticeStage.fromJson(e)).toList();
    } else {
      // Migrate from old format
      stages = await _migrateFromOldSettings(prefs);
    }

    _cachedStages = stages;
    return stages;
  }

  Future<List<PracticeStage>> _migrateFromOldSettings(
    SharedPreferences prefs,
  ) async {
    final greenPeriod = prefs.getInt('greenPeriod') ?? 7;
    final greenToYellow = prefs.getInt('greenToYellowTransition') ?? 7;
    final yellowToRed = prefs.getInt('yellowToRedTransition') ?? 16;
    final redToBlack = prefs.getInt('redToBlackTransition') ?? 30;

    final uuid = const Uuid();
    final l10n = await _loadPlatformLocalizations();

    final stages = [
      PracticeStage(
        id: uuid.v4(),
        name: l10n.recentlyPracticed,
        colorValue: Colors.green.toARGB32(),
        holdDays: greenPeriod,
        transitionDays: greenToYellow,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: l10n.beenAWhile,
        colorValue: Colors.yellow.toARGB32(),
        holdDays: 0,
        transitionDays: yellowToRed,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: l10n.aLongWhile,
        colorValue: Colors.red.toARGB32(),
        holdDays: 0,
        transitionDays: redToBlack,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: l10n.beenTooLong,
        colorValue: Colors.black.toARGB32(),
        holdDays: 0,
        transitionDays: 0, // Last stage
      ),
    ];

    // Save immediately so next time we load fast
    await saveStages(stages);
    return stages;
  }

  Future<AppLocalizations> _loadPlatformLocalizations() {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final supportedLocales = AppLocalizations.supportedLocales;
    final exactMatch = supportedLocales.where(
      (locale) =>
          locale.languageCode == platformLocale.languageCode &&
          locale.countryCode == platformLocale.countryCode,
    );
    final languageMatch = supportedLocales.where(
      (locale) => locale.languageCode == platformLocale.languageCode,
    );
    final locale = exactMatch.isNotEmpty
        ? exactMatch.first
        : languageMatch.isNotEmpty
        ? languageMatch.first
        : supportedLocales.first;
    return AppLocalizations.delegate.load(locale);
  }

  Future<void> saveStages(List<PracticeStage> stages) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(stages.map((e) => e.toJson()).toList());
    await prefs.setString(_stagesKey, encoded);
  }
}
