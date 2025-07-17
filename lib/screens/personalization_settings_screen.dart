import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_notifier.dart';
import '../utils/app_logger.dart';

/// A screen for managing personalization settings of the application.
///
/// This includes options for theme mode (system, light, dark) and the number
/// of columns to display in the music piece gallery.
class PersonalizationSettingsScreen extends StatefulWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  _PersonalizationSettingsScreenState createState() =>
      _PersonalizationSettingsScreenState();
}

class _PersonalizationSettingsScreenState
    extends State<PersonalizationSettingsScreen> {
  double _galleryColumns = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads the saved gallery column setting from [SharedPreferences].
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Retrieve the saved column count, defaulting to 1 if not found.
      _galleryColumns = (prefs.getInt('galleryColumns') ?? 1).toDouble();
    });
  }

  Future<void> _saveGalleryColumns(double value) async {
    AppLogger.log('PersonalizationSettingsScreen: Saving galleryColumns: ${value.toInt()}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('galleryColumns', value.toInt());
    setState(() {
      _galleryColumns = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeNotifier.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeNotifier.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeNotifier.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setTheme(value);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Accent Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: ThemeNotifier.availableAccentColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    themeNotifier.setAccentColor(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeNotifier.accentColor == color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Gallery Columns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Slider(
              value: _galleryColumns,
              min: 1,
              max: 10,
              divisions: 9,
              label: _galleryColumns.toInt().toString(),
              onChanged: (value) async {
                await _saveGalleryColumns(value);
                
              },
            ),
          ],
        ),
      ),
    );
  }
}
