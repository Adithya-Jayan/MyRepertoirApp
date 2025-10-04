import 'package:flutter/material.dart';
import 'package:repertoire/screens/about_screen.dart';
import 'package:repertoire/screens/help_screen.dart';

import 'package:repertoire/screens/group_management_screen.dart'; // New import
import 'package:repertoire/screens/backup_restore_screen.dart';
import 'package:repertoire/screens/advanced_settings_screen.dart';
import 'package:repertoire/utils/app_logger.dart';

import 'package:repertoire/screens/functionality_settings_screen.dart';
import 'package:repertoire/screens/personalization_settings_screen.dart';

/// A screen that displays various settings options for the application.
///
/// This screen provides navigation to different sub-settings screens like
/// Group Management, Personalization, Backup & Restore, About, and Help.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// The state class for [SettingsScreen].
/// Builds the UI for the settings menu and handles navigation to sub-settings screens.
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void dispose() {
    AppLogger.log('SettingsScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('SettingsScreen: build called');
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Settings'), // Title of the settings screen.
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open), // Icon for the Groups setting.
            title: const Text('Groups'), // Title for the Groups setting.
            onTap: () async {
              AppLogger.log('Navigating to Group Management screen.');
              // Navigate to GroupManagementScreen and wait for any changes.
              final bool? changesMade = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const GroupManagementScreen()),
              );
              if (!mounted) return;
              // If changes were made in GroupManagementScreen, pop this screen with true to indicate changes.
              if (changesMade == true) {
                AppLogger.log('SettingsScreen: Received changesMade=true from GroupManagementScreen.');
                if (!mounted) return;
                final currentContext = context;
                Navigator.of(currentContext).pop(true);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette), // Icon for the Personalization setting.
            title: const Text('Personalization'), // Title for the Personalization setting.
            onTap: () async {
              AppLogger.log('Navigating to Personalization Settings screen.');
              // Navigate to PersonalizationSettingsScreen and wait for any changes.
              final bool? changesMade = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const PersonalizationSettingsScreen()),
              );
              if (!mounted) return;
              if (changesMade == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved.')),
                );
                // Return true to indicate changes were made
                Navigator.of(context).pop(true);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Functionality'),
            onTap: () {
              AppLogger.log('Navigating to Functionality Settings screen.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FunctionalitySettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'), // Title for the Backup & Restore setting.
            onTap: () {
              AppLogger.log('Navigating to Backup & Restore screen.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('Advanced Settings'),
            onTap: () {
              AppLogger.log('Navigating to Advanced Settings screen.');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdvancedSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info), // Icon for the About setting.
            title: const Text('About'), // Title for the About setting.
            onTap: () {
              AppLogger.log('Navigating to About screen.');
              // Navigate to AboutScreen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help), // Icon for the Help setting.
            title: const Text('Help'), // Title for the Help setting.
            onTap: () {
              AppLogger.log('Navigating to Help screen.');
              // Navigate to HelpScreen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    ),
    );
  }
}
