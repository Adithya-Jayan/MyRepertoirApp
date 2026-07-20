import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'color_scheme_screen.dart';
import 'library_screen.dart';
import '../utils/app_logger.dart';
import '../services/backup_restore_service.dart';
import '../database/music_piece_repository.dart';
import '../utils/permissions_utils.dart';
import 'package:path_provider/path_provider.dart';

import 'package:repertoire/l10n/l10n.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final isPlayStore = await isPlayStoreBuild();
        if (isPlayStore) {
          final appDocDir = await getApplicationDocumentsDirectory();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appStoragePath', appDocDir.path);
          await AppLogger.reinitialize();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ColorSchemeScreen(),
              ),
            );
          }
          return;
        }
        if (!mounted) return;
        await requestPermissions(context);
      }
    });
  }

  /// Opens a directory picker for the user to select a storage folder.
  ///
  /// The selected path is then saved to [SharedPreferences].
  Future<void> _selectStorageFolder() async {
    final result = await FilePicker.platform
        .getDirectoryPath(); // Open directory picker.
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'appStoragePath',
        result,
      ); // Save the selected path.

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
        zipFiles.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
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
        title: Text(context.l10n.existingBackupFound),
        content: Text(context.l10n.automaticBackupFoundMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: Text(context.l10n.skip),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: Text(context.l10n.selectManually),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'restore'),
            child: Text(context.l10n.restoreLatest),
          ),
        ],
      ),
    );

    if (action == 'skip' || action == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Added mounted check
    final service = BackupRestoreService(MusicPieceRepository(), prefs);

    bool restoreSuccess = false;
    try {
      if (action == 'restore') {
        if (!mounted) return; // Added mounted check
        restoreSuccess = await service.restoreData(
          context: context,
          filePath: latestBackupPath,
          isFreshRestore: true,
          shouldPop: false, // Don't pop WelcomeScreen
        );
      } else if (action == 'manual') {
        restoreSuccess = await service.restoreData(
          context: context,
          isFreshRestore: true,
          shouldPop: false, // Don't pop WelcomeScreen
        );
      }

      if (restoreSuccess && mounted) {
        // Skip setup screens and go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
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
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch, size: 80),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.l10n.welcome,
                    style: theme.textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context
                        .l10n
                        .letSGetYourRepertoireSetUpYouCanAlwaysChangeThese,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Text(
                    context.l10n.selectAFolderWhereTheAppWillStoreItsFiles,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _storagePath ?? context.l10n.noStorageLocationSet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: _selectStorageFolder,
                    child: Text(context.l10n.selectAFolder),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _storagePath != null
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ColorSchemeScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Text(context.l10n.next),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
