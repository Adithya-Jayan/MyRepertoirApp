import 'package:flutter/material.dart';
import 'package:repertoire/screens/about_screen.dart';
import 'package:repertoire/screens/help_screen.dart';

import 'package:repertoire/screens/group_management_screen.dart'; // New import
import 'package:repertoire/screens/tag_group_management_screen.dart'; // New import
import 'package:repertoire/screens/backup_restore_screen.dart';
import 'package:repertoire/screens/advanced_settings_screen.dart';
import 'package:repertoire/utils/app_logger.dart';

import 'package:repertoire/screens/functionality_settings_screen.dart';
import 'package:repertoire/screens/personalization_settings_screen.dart';

import 'package:repertoire/l10n/l10n.dart';

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
  bool _changesMade = false;

  @override
  void dispose() {
    AppLogger.log('SettingsScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('SettingsScreen: build called');
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changesMade);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.settings)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            children: [
              _buildCategoryHeader(
                theme,
                context.l10n.contentAndDisplay,
                Icons.dashboard_customize_outlined,
              ),
              _buildSettingsCard([
                _buildSettingsTile(
                  context,
                  icon: Icons.folder_open,
                  title: context.l10n.groups,
                  subtitle: context.l10n.manageAndReorderGroups,
                  onTap: () async {
                    final bool? changes = await Navigator.of(context)
                        .push<bool?>(
                          MaterialPageRoute(
                            builder: (context) => const GroupManagementScreen(),
                          ),
                        );
                    if (changes == true) _markChanges();
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.label_outline,
                  title: context.l10n.tagging,
                  subtitle: context.l10n.bulkEditTagGroupsAndColors,
                  onTap: () async {
                    final bool? changes = await Navigator.of(context)
                        .push<bool?>(
                          MaterialPageRoute(
                            builder: (context) =>
                                const TagGroupManagementScreen(),
                          ),
                        );
                    if (changes == true) _markChanges();
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: context.l10n.personalization,
                  subtitle: context.l10n.themeColorsAndLayout,
                  onTap: () async {
                    final bool? changes = await Navigator.of(context)
                        .push<bool?>(
                          MaterialPageRoute(
                            builder: (context) =>
                                const PersonalizationSettingsScreen(),
                          ),
                        );
                    if (changes == true) _markChanges();
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.tune_outlined,
                  title: context.l10n.functionality,
                  subtitle: context.l10n.practiceStagesAndStatistics,
                  onTap: () async {
                    final bool? changes = await Navigator.of(context)
                        .push<bool?>(
                          MaterialPageRoute(
                            builder: (context) =>
                                const FunctionalitySettingsScreen(),
                          ),
                        );
                    if (changes == true) _markChanges();
                  },
                ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.systemAndMaintenance,
                Icons.settings_outlined,
              ),
              _buildSettingsCard([
                _buildSettingsTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: context.l10n.backupAndRestore,
                  subtitle: context.l10n.protectAndSyncYourData,
                  onTap: () async {
                    final bool? changes = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BackupRestoreScreen(),
                      ),
                    );
                    if (changes == true) _markChanges();
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.settings_applications_outlined,
                  title: context.l10n.advancedSettings,
                  subtitle: context.l10n.loggingAndDeveloperOptions,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdvancedSettingsScreen(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.information,
                Icons.info_outline,
              ),
              _buildSettingsCard([
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outlined,
                  title: context.l10n.about,
                  subtitle: context.l10n.versionAndContributorInfo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: context.l10n.help,
                  subtitle: context.l10n.guidesAndTroubleshooting,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _markChanges() {
    if (!mounted) return;
    setState(() {
      _changesMade = true;
    });
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
