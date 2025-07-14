/// A [ChangeNotifier] that manages the application's theme mode.
///
/// It allows setting and loading the theme preference (System, Light, Dark)
/// and notifies its listeners when the theme changes.
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode; // The current theme mode of the application.

  /// Constructor for [ThemeNotifier].
  /// Initializes with a given [ThemeMode].
  ThemeNotifier(this._themeMode);

  /// Getter for the current [ThemeMode].
  ThemeMode get themeMode => _themeMode;

  /// Loads the saved theme preference from [SharedPreferences].
  ///
  /// If no preference is found, it defaults to [ThemeMode.system].
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themePreference = prefs.getString('appThemePreference') ?? 'System'; // Retrieve saved theme preference.
    _themeMode = _getThemeModeFromString(themePreference); // Convert string preference to ThemeMode.
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

  /// Converts a string representation of a theme to its [ThemeMode] enum value.
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

  /// Converts a [ThemeMode] enum value to its string representation.
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
