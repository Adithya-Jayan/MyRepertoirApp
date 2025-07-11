import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';
import 'library_screen.dart';

class ColorSchemeScreen extends StatefulWidget {
  const ColorSchemeScreen({super.key});

  @override
  State<ColorSchemeScreen> createState() => _ColorSchemeScreenState();
}

class _ColorSchemeScreenState extends State<ColorSchemeScreen> {
  String _selectedTheme = 'System';

  void _setTheme(String theme) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    ThemeMode themeMode;
    switch (theme) {
      case 'Light':
        themeMode = ThemeMode.light;
        break;
      case 'Dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    themeNotifier.setTheme(themeMode);
    setState(() {
      _selectedTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, size: 100),
              const SizedBox(height: 20),
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              SegmentedButton<
                  String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'System', label: Text('System')),
                  ButtonSegment<String>(value: 'Light', label: Text('Light')),
                  ButtonSegment<String>(value: 'Dark', label: Text('Dark')),
                ],
                selected: <String>{_selectedTheme},
                onSelectionChanged: (Set<String> newSelection) {
                  _setTheme(newSelection.first);
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                  ThemeMode themeMode;
                  switch (_selectedTheme) {
                    case 'Light':
                      themeMode = ThemeMode.light;
                      break;
                    case 'Dark':
                      themeMode = ThemeMode.dark;
                      break;
                    default:
                      themeMode = ThemeMode.system;
                  }
                  themeNotifier.setTheme(themeMode);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasRunBefore', true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LibraryScreen()),
                  );
                },
                child: const Text('Start App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
