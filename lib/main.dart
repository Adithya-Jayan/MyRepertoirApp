import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/library_screen.dart';
import 'screens/welcome_screen.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'utils/theme_notifier.dart';

import 'package:just_audio_background/just_audio_background.dart';

import 'utils/app_logger.dart';
import 'utils/backup_utils.dart';
import 'utils/permissions_utils.dart';

/// Main entry point of the application.
/// Initializes Flutter, sets up platform-specific database factories,
/// initializes background audio services, and starts the app.
Future<void> main() async {
  // Ensures that Flutter widgets are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.init(); // Initialize the logger
  AppLogger.log('App started.');

  await requestPermissions();


  // Initialize sqflite for desktop platforms (Windows, Linux, macOS).
  // This allows the app to use SQLite databases on these platforms.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize just_audio_background for seamless background audio playback.
  // Configures the Android notification channel for media controls.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true, // Keeps the notification ongoing
  );

  // Runs the Flutter application.
  // ChangeNotifierProvider is used here to provide ThemeNotifier to the widget tree,
  // allowing theme changes to be managed and listened to by various widgets.
  runApp(
    ChangeNotifierProvider(
      // Initializes ThemeNotifier with the system's current theme mode and a default accent color.
      create: (_) => ThemeNotifier(ThemeMode.system, Colors.deepPurple),
      child: const MyApp(),
    ),
  );

  // Triggers an automatic backup process after the app starts.
  triggerAutoBackup();
}

/// The root widget of the application.
///
/// This is a StatefulWidget to manage the asynchronous check for
/// whether the app has been run before, which determines the initial screen.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// The state class for the MyApp widget.
/// Manages the logic for determining the initial screen (Welcome or Library)
/// and loading the user's theme preference.
class _MyAppState extends State<MyApp> {
  /// Asynchronously checks if the app has been launched before.
  ///
  /// This is determined by the presence of a 'hasRunBefore' flag in
  /// SharedPreferences.
  Future<bool> _hasRunBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasRunBefore') ?? false;
  }

  Future<void> _setInitialDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRunBefore = prefs.getBool('hasRunBefore') ?? false;
    if (!hasRunBefore) {
      await prefs.setInt('galleryColumns', 2);
      await prefs.setBool('all_group_isHidden', true);
      await prefs.setBool('hasRunBefore', true);
    }
  }

  @override
  void initState() {
    super.initState();
    _setInitialDefaults().then((_) {
      Provider.of<ThemeNotifier>(context, listen: false).loadTheme();
    });
  }

  @override
  void dispose() {
    AppLogger.log('MyApp: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('MyApp: build called');
    // FutureBuilder is used to asynchronously determine the initial screen
    // based on whether the app has been run before.
    return FutureBuilder<bool>(
      future: _hasRunBefore(),
      builder: (context, snapshot) {
        // While waiting for the _hasRunBefore() future to complete,
        // display a circular progress indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Once the future completes, build the MaterialApp.
        // Consumer listens to changes in ThemeNotifier and rebuilds
        // the MaterialApp with the updated theme.
        return Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            return MaterialApp(
              title: 'Music Repertoire', // Title of the application
              themeMode: themeNotifier.themeMode, // Current theme mode (light, dark, system)
              // Defines the light theme for the application.
              theme: ThemeData(
                // Generates a color scheme based on the selected accent color.
                colorScheme: ColorScheme.fromSeed(seedColor: themeNotifier.accentColor),
                useMaterial3: true, // Enables Material 3 design features
              ),
              // Defines the dark theme for the application.
              darkTheme: ThemeData(
                // Generates a dark color scheme based on the selected accent color.
                colorScheme: ColorScheme.fromSeed(seedColor: themeNotifier.accentColor, brightness: Brightness.dark),
                useMaterial3: true, // Enables Material 3 design features
              ),
              // Sets the home screen based on whether the app has run before.
              // If true, navigate to LibraryScreen; otherwise, navigate to WelcomeScreen.
              home: snapshot.data == true ? const LibraryScreen() : const WelcomeScreen(),
            );
          },
        );
      },
    );
  }
}