import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_notifier.dart';
import '../utils/locale_notifier.dart';
import '../utils/app_logger.dart';

import 'package:repertoire/l10n/l10n.dart';

/// A screen for managing personalization settings of the application.
///
/// This includes options for theme mode (system, light, dark) and the number
/// of columns to display in the music piece gallery.
class PersonalizationSettingsScreen extends StatefulWidget {
  const PersonalizationSettingsScreen({super.key});

  @override
  State<PersonalizationSettingsScreen> createState() =>
      PersonalizationSettingsScreenState();
}

class PersonalizationSettingsScreenState
    extends State<PersonalizationSettingsScreen> {
  double _galleryColumns = 1;
  bool _hideEmptyGroups = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads settings from [SharedPreferences].
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int defaultColumns;
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      defaultColumns = 4;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      defaultColumns = 6;
    } else {
      defaultColumns = 2;
    }
    setState(() {
      _galleryColumns = (prefs.getInt('galleryColumns') ?? defaultColumns)
          .toDouble();
      _hideEmptyGroups = prefs.getBool('hideEmptyGroups') ?? false;
    });
  }

  Future<void> _saveGalleryColumns(double value) async {
    AppLogger.log(
      'PersonalizationSettingsScreen: Saving galleryColumns: ${value.toInt()}',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('galleryColumns', value.toInt());
    if (!mounted) return;
    setState(() {
      _galleryColumns = value;
    });
  }

  Future<void> _saveHideEmptyGroups(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideEmptyGroups', value);
    if (!mounted) return;
    setState(() {
      _hideEmptyGroups = value;
    });
  }

  Widget _buildLanguageName(Locale locale) {
    return Localizations.override(
      context: context,
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Builder(
        builder: (localizedContext) => Text(localizedContext.l10n.languageName),
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.log('PersonalizationSettingsScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('PersonalizationSettingsScreen: build called');
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final localeNotifier = Provider.of<LocaleNotifier>(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.personalization),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            children: [
              _buildCategoryHeader(
                theme,
                context.l10n.appLanguage,
                Icons.language_outlined,
              ),
              _buildSettingsCard([
                RadioGroup<String>(
                  groupValue: localeNotifier.preference,
                  onChanged: (preference) {
                    if (preference != null) {
                      localeNotifier.setLocale(
                        localeNotifier.localeForPreference(preference),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(context.l10n.systemDefault),
                        value: LocaleNotifier.systemPreference,
                      ),
                      ...localeNotifier.supportedLocales.map(
                        (locale) => RadioListTile<String>(
                          title: _buildLanguageName(locale),
                          value: locale.toLanguageTag(),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.appTheme,
                Icons.palette_outlined,
              ),
              _buildSettingsCard([
                Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 16.0),
                  child: Text(
                    context.l10n.themeMode,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioGroup<ThemeMode>(
                  groupValue: themeNotifier.themeMode,
                  onChanged: (v) {
                    if (v != null) themeNotifier.setTheme(v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text(context.l10n.systemDefault),
                        value: ThemeMode.system,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(context.l10n.light),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(context.l10n.dark),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 12.0),
                  child: Text(
                    context.l10n.accentColor,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: ThemeNotifier.availableAccentColors.map((color) {
                      return GestureDetector(
                        onTap: () => themeNotifier.setAccentColor(color),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeNotifier.accentColor == color
                                  ? theme.colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: [
                              if (themeNotifier.accentColor == color)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile(
                  title: Text(context.l10n.useOledBlack),
                  subtitle: Text(context.l10n.trueBlackBackgroundInDarkMode),
                  value: themeNotifier.useOledBlack,
                  onChanged: (v) => themeNotifier.setUseOledBlack(v),
                ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.galleryLayout,
                Icons.grid_view_outlined,
              ),
              _buildSettingsCard([
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.columns,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_galleryColumns.toInt()}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _galleryColumns,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (v) => _saveGalleryColumns(v),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    context.l10n.thumbnailStyle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioGroup<ThumbnailStyle>(
                  groupValue: themeNotifier.thumbnailStyle,
                  onChanged: (v) {
                    if (v != null) themeNotifier.setThumbnailStyle(v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThumbnailStyle>(
                        title: Text(context.l10n.outlineText),
                        value: ThumbnailStyle.outline,
                      ),
                      RadioListTile<ThumbnailStyle>(
                        title: Text(context.l10n.gradientOverlay),
                        value: ThumbnailStyle.gradient,
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.displayOptions,
                Icons.visibility_outlined,
              ),
              _buildSettingsCard([
                SwitchListTile(
                  title: Text(context.l10n.showPracticeCount),
                  value: themeNotifier.showPracticeCount,
                  onChanged: (v) => themeNotifier.setShowPracticeCount(v),
                ),
                SwitchListTile(
                  title: Text(context.l10n.showLastPracticed),
                  value: themeNotifier.showLastPracticed,
                  onChanged: (v) => themeNotifier.setShowLastPracticed(v),
                ),
                SwitchListTile(
                  title: Text(context.l10n.hideEmptyGroups),
                  subtitle: Text(
                    context.l10n.doNotShowGroupsWithNoMatchingPieces,
                  ),
                  value: _hideEmptyGroups,
                  onChanged: (v) => _saveHideEmptyGroups(v),
                ),
                SwitchListTile(
                  title: Text(context.l10n.showDotPattern),
                  value: themeNotifier.showDotPatternBackground,
                  onChanged: (v) =>
                      themeNotifier.setShowDotPatternBackground(v),
                ),
                SwitchListTile(
                  title: Text(context.l10n.showGradientBackground),
                  value: themeNotifier.showGradientBackground,
                  onChanged: (v) => themeNotifier.setShowGradientBackground(v),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
