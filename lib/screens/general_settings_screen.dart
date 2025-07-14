import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';

/// A screen for managing general application settings.
///
/// This includes options for selecting the application's storage folder
/// and choosing the overall app theme (light, dark, or system default).
class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

/// The state class for [GeneralSettingsScreen].
/// Manages the UI and logic for general application settings.
class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  String? _currentStoragePath; // Stores the currently selected application storage path.
  ThemeMode? _selectedThemeMode; // Stores the currently selected theme mode.

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load initial settings when the screen initializes.
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStoragePath = prefs.getString('appStoragePath');
      final themePreference = prefs.getString('appThemePreference') ?? 'System';
      _selectedThemeMode = _getThemeModeFromString(themePreference);
    });
  }

  /// Opens a directory picker for the user to select a new storage folder.
  ///
  /// If a directory is selected, its path is saved to [SharedPreferences]
  /// and the UI is updated to reflect the new path.
  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(); // Open the directory picker.
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', result); // Save the newly selected storage path.
      setState(() {
        _currentStoragePath = result; // Update the state to display the new path.
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage path updated.')), // Show a confirmation message.
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Storage Folder'),
            subtitle: Text(_currentStoragePath ?? 'Not set'),
            trailing: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _selectStorageFolder,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('App Theme'),
            subtitle: Text(_getStringFromThemeMode(_selectedThemeMode ?? ThemeMode.system)),
            trailing: DropdownButton<ThemeMode>(
              value: _selectedThemeMode ?? ThemeMode.system,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  Provider.of<ThemeNotifier>(context, listen: false).setTheme(newValue);
                  setState(() {
                    _selectedThemeMode = newValue;
                  });
                }
              },
              items: const <ThemeMode>[
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ].map<DropdownMenuItem<ThemeMode>>((ThemeMode value) {
                return DropdownMenuItem<ThemeMode>(
                  value: value,
                  child: Text(_getStringFromThemeMode(value)),
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Some theme changes may require an app restart to take full effect.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
