import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';
import 'library_screen.dart';

/// A screen for selecting the application's color scheme (theme mode).
///
/// This screen is part of the initial setup process and allows users to choose
/// between System Default, Light, or Dark themes.
class ColorSchemeScreen extends StatefulWidget {
  const ColorSchemeScreen({super.key});

  @override
  State<ColorSchemeScreen> createState() => _ColorSchemeScreenState();
}

/// The state class for [ColorSchemeScreen].
/// Manages the selected theme mode and applies it to the application.
class _ColorSchemeScreenState extends State<ColorSchemeScreen> {
  String _selectedTheme = 'System'; // Stores the currently selected theme option (System, Light, Dark).
  Color _selectedAccentColor = Colors.deepPurple; // Stores the currently selected accent color.

  @override
  void initState() {
    super.initState();
    _loadInitialAccentColor();
  }

  Future<void> _loadInitialAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final accentColorValue = prefs.getInt('appAccentColor') ?? _selectedAccentColor.value;
    if (!mounted) return;
    final currentContext = context;
    if (currentContext.mounted) {
      setState(() {
        _selectedAccentColor = Color(accentColorValue);
      });
    }
  }

  /// Sets the application's theme mode based on the user's selection.
  ///
  /// Updates the [ThemeNotifier] and the local state to reflect the new theme.
  void _setTheme(String theme) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false); // Get the ThemeNotifier instance.
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
    themeNotifier.setTheme(themeMode); // Apply the selected theme mode.
    setState(() {
      _selectedTheme = theme; // Update the local state to reflect the selected theme.
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
              const Text('Choose your accent color:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ThemeNotifier.availableAccentColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                      themeNotifier.setAccentColor(color);
                      if (!mounted) return;
                      final currentContext = context;
                      if (currentContext.mounted) {
                        setState(() {
                          _selectedAccentColor = color;
                        });
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAccentColor == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                  themeNotifier.setAccentColor(_selectedAccentColor);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasRunBefore', true);
                  if (!mounted) return;
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
