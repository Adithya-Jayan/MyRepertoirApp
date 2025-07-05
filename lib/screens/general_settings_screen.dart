import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  String? _currentStoragePath;
  ThemeMode? _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStoragePath = prefs.getString('appStoragePath');
      final themePreference = prefs.getString('appThemePreference') ?? 'System';
      _selectedThemeMode = _getThemeModeFromString(themePreference);
    });
  }

  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', result);
      setState(() {
        _currentStoragePath = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage path updated.')),
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
