import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_notifier.dart';

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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _galleryColumns = (prefs.getInt('galleryColumns') ?? 1).toDouble();
    });
  }

  Future<void> _saveGalleryColumns(double value) async {
    print('PersonalizationSettingsScreen: Saving galleryColumns: ${value.toInt()}');
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
