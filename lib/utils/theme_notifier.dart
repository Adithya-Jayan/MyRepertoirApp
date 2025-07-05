import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themePreference = prefs.getString('appThemePreference') ?? 'System';
    _themeMode = _getThemeModeFromString(themePreference);
    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appThemePreference', _getStringFromThemeMode(themeMode));
    }
  }

  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }
}
