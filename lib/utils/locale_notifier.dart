import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's language independently from the system locale.
class LocaleNotifier with ChangeNotifier {
  static const preferenceKey = 'appLanguagePreference';
  static const systemPreference = 'system';

  final List<Locale> supportedLocales;
  Locale? _locale;

  LocaleNotifier({
    required Iterable<Locale> supportedLocales,
    Locale? initialLocale,
  }) : supportedLocales = List.unmodifiable(supportedLocales),
       _locale = initialLocale;

  /// A null locale lets Flutter follow the platform language.
  Locale? get locale => _locale;

  String get preference => _locale?.toLanguageTag() ?? systemPreference;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getString(preferenceKey);
    final savedLocale =
        savedPreference == null || savedPreference == systemPreference
        ? null
        : _findSupportedLocale(savedPreference);

    if (_locale != savedLocale) {
      _locale = savedLocale;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    final supportedLocale = locale == null
        ? null
        : _findSupportedLocale(locale.toLanguageTag());
    if (locale != null && supportedLocale == null) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }
    if (_locale == supportedLocale) return;

    _locale = supportedLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, preference);
  }

  Locale? localeForPreference(String preference) {
    if (preference == systemPreference) return null;
    return _findSupportedLocale(preference);
  }

  Locale? _findSupportedLocale(String value) {
    final normalizedValue = value.replaceAll('_', '-').toLowerCase();
    for (final locale in supportedLocales) {
      if (locale.toLanguageTag().toLowerCase() == normalizedValue) {
        return locale;
      }
    }
    return null;
  }
}
