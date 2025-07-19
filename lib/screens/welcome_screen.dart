import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import 'color_scheme_screen.dart';
import '../utils/app_logger.dart';

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

  /// Opens a directory picker for the user to select a storage folder.
  ///
/// The selected path is then saved to [SharedPreferences].
  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(); // Open directory picker.
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', result); // Save the selected path.
      
      // Reinitialize the logger with the new storage path
      await AppLogger.reinitialize();
      
      setState(() {
        _storagePath = result; // Update the UI with the selected path.
      });
    }
  }

  @override
  void dispose() {
    AppLogger.log('WelcomeScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('WelcomeScreen: build called');
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
              ElevatedButton(
                onPressed: _storagePath != null
                    ? () {
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
