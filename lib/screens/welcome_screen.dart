import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'color_scheme_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _storagePath;

  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appStoragePath', result);
      setState(() {
        _storagePath = result;
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
              const Icon(Icons.rocket_launch, size: 100),
              const SizedBox(height: 20),
              const Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Let\'s set some things up first. You can change these settings later.'),
              const SizedBox(height: 40),
              const Text('Select a folder where the app will store its files:'),
              const SizedBox(height: 10),
              Text('Selected folder: ${_storagePath ?? 'No storage location set'}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectStorageFolder,
                child: const Text('Select a folder'),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _storagePath != null
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ColorSchemeScreen()),
                        );
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
