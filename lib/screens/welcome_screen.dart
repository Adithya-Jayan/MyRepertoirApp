import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'color_scheme_screen.dart';
import '../utils/app_logger.dart';
import '../services/backup_restore_service.dart';
import '../database/music_piece_repository.dart';

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

      // Check for existing auto-backups
      await _checkForExistingBackups(result);
    }
  }

  Future<void> _checkForExistingBackups(String storagePath) async {
    final backupsDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
    if (await backupsDir.exists()) {
      final files = await backupsDir.list().toList();
      final zipFiles = files.where((f) => f.path.endsWith('.zip')).toList();
      
      if (zipFiles.isNotEmpty && mounted) {
        // Sort by modified date desc (newest first)
        zipFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        final latestBackup = zipFiles.first;
        
        await _showRestoreDialog(latestBackup.path);
      }
    }
  }

  Future<void> _showRestoreDialog(String latestBackupPath) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Existing Backup Found'),
        content: const Text(
          'An automatic backup was found in the selected storage folder. ' 
          'Would you like to restore it?\n\n' 
          'Note: This will replace any template data created during installation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Select Manually'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'restore'),
            child: const Text('Restore Latest'),
          ),
        ],
      ),
    );

    if (action == 'skip' || action == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final service = BackupRestoreService(MusicPieceRepository(), prefs);

    try {
      if (action == 'restore') {
         await service.restoreData(
           context: context, 
           filePath: latestBackupPath, 
           isFreshRestore: true,
           shouldPop: false // Don't pop WelcomeScreen
         );
      } else if (action == 'manual') {
         await service.restoreData(
           context: context, 
           isFreshRestore: true,
           shouldPop: false // Don't pop WelcomeScreen
         );
      }
    } catch (e) {
      AppLogger.log('WelcomeScreen: Restore error: $e');
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
    return SafeArea(
      child: Scaffold(
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
    ),
    );
  }
}