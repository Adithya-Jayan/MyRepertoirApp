import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:repertoire/utils/theme_notifier.dart'; // Import ThemeNotifier to access availableAccentColors
import 'color_scheme_screen.dart';

/// The initial screen displayed to the user on their first launch of the application.
///
/// This screen guides the user through an initial setup process, including
/// selecting a storage folder for app files.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

/// The state class for [WelcomeScreen].
/// Manages the UI and logic for the initial setup process.
class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _storagePath; // Stores the selected storage path for app files.
  Color _selectedAccentColor = Colors.deepPurple; // Default accent color.

  /// Opens a directory picker for the user to select a storage folder.
  ///
  /// The selected path is then saved to [SharedPreferences].
  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(); // Open directory picker.
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', result); // Save the selected path.
      setState(() {
        _storagePath = result; // Update the UI with the selected path.
      });
    }
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
              const Icon(Icons.rocket_launch, size: 100), // Rocket launch icon for welcome.
              const SizedBox(height: 20),
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Welcome message.
              const SizedBox(height: 10),
              const Text('Let\'s set some things up first. You can change these settings later.'), // Introductory text.
              const SizedBox(height: 40),
              const Text('Select a folder where the app will store its files:'), // Instruction for folder selection.
              const SizedBox(height: 10),
              Text('Selected folder: ${_storagePath ?? 'No storage location set'}'), // Display selected folder path.
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectStorageFolder, // Button to trigger folder selection.
                child: const Text('Select a folder'),
              ),
              const SizedBox(height: 40),
              const Text('Choose your accent color:'), // Instruction for accent color selection.
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ThemeNotifier.availableAccentColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAccentColor = color;
                      });
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
                onPressed: _storagePath != null
                    ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('appAccentColor', _selectedAccentColor.value); // Save selected accent color.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ColorSchemeScreen()), // Navigate to ColorSchemeScreen.
                        );
                      }
                    : null, // Disable button if no storage path is selected.
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}