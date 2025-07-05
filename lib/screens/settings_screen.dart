import 'package:flutter/material.dart';
import 'package:repertoire/screens/about_screen.dart';
import 'package:repertoire/screens/help_screen.dart';
import 'package:repertoire/screens/general_settings_screen.dart';
import 'package:repertoire/screens/group_management_screen.dart'; // New import
import 'package:repertoire/screens/backup_restore_screen.dart';

import 'package:repertoire/screens/personalization_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Groups'),
            onTap: () async {
              final bool? changesMade = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const GroupManagementScreen()),
              );
              if (changesMade == true) {
                print('SettingsScreen: Received changesMade=true from GroupManagementScreen.');
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Personalization'),
            onTap: () async {
              final bool? changesMade = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const PersonalizationSettingsScreen()),
              );
              if (changesMade == true) {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Backup & Restore'),
            onTap: () async {
              final bool? changesMade = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
              );
              if (changesMade == true) {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
