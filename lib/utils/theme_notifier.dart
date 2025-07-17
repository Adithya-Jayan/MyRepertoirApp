import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ChangeNotifier] that manages the application's theme mode.
///
/// It allows setting and loading the theme preference (System, Light, Dark)
/// and notifies its listeners when the theme changes.
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode; // The current theme mode of the application.
  Color _accentColor; // The current accent color of the application.

  // Define a list of available accent colors.
  static const List<Color> availableAccentColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  /// Constructor for [ThemeNotifier].
  /// Initializes with a given [ThemeMode] and [accentColor].
  ThemeNotifier(this._themeMode, this._accentColor);

  /// Getter for the current [ThemeMode].
  ThemeMode get themeMode => _themeMode;

  /// Getter for the current accent color.
  Color get accentColor => _accentColor;

  /// Loads the saved theme preference and accent color from [SharedPreferences].
  ///
  /// If no preference is found, it defaults to [ThemeMode.system] and [Colors.deepPurple].
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themePreference = prefs.getString('appThemePreference') ?? 'System'; // Retrieve saved theme preference.
    final accentColorValue = prefs.getInt('appAccentColor') ?? Colors.deepPurple.value; // Retrieve saved accent color.

    _themeMode = _getThemeModeFromString(themePreference); // Convert string preference to ThemeMode.
    _accentColor = Color(accentColorValue); // Convert integer value to Color.
    notifyListeners(); // Notify listeners that the theme has changed.
  }

  /// Sets the application's theme mode.
  ///
  /// If the new theme mode is different from the current one, it updates
  /// the theme, notifies listeners, and saves the preference to [SharedPreferences].
  void setTheme(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode; // Update the theme mode.
      notifyListeners(); // Notify listeners of the change.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appThemePreference', _getStringFromThemeMode(themeMode)); // Save the new theme preference.
    }
  }

  /// Sets the application's accent color.
  ///
  /// If the new accent color is different from the current one, it updates
  /// the color, notifies listeners, and saves the preference to [SharedPreferences].
  void setAccentColor(Color color) async {
    if (_accentColor != color) {
      _accentColor = color; // Update the accent color.
      notifyListeners(); // Notify listeners of the change.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('appAccentColor', color.value); // Save the new accent color.
    }
  }

  /// Converts a string representation of a theme to its [ThemeMode] enum value.
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
        return ThemeMode.system;
    }
    return ThemeMode.system; // Add a default return statement
  }

  /// Converts a [ThemeMode] enum value to its string representation.
  String _getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}