import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/utils/theme_notifier.dart';
import 'package:repertoire/services/audio_player_service.dart'; // Added this import

import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/utils/backup_utils.dart';
import 'package:repertoire/utils/permissions_utils.dart';
import 'package:repertoire/utils/practice_indicator_utils.dart';
import 'package:repertoire/screens/library_screen.dart';
import 'package:repertoire/screens/welcome_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  // Runs the Flutter application.
  // ChangeNotifierProvider is used here to provide ThemeNotifier to the widget tree,
  // allowing theme changes to be managed and listened to by various widgets.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(ThemeMode.system, Colors.deepPurple),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerService(),
          lazy: false, // Initialize immediately
        ),
      ],
      child: const MyApp(),
    ),
  );

  // Note: Auto-backup is now triggered in MyApp after initialization
  // triggerAutoBackup();
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
  /// Asynchronously checks if the app has been launched before and if the storage path is set.
  ///
  /// This is determined by the presence of a 'hasRunBefore' flag and a valid 'appStoragePath'
  /// in SharedPreferences.
  Future<bool> _isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRunBefore = prefs.getBool('hasRunBefore') ?? false;
    final storagePath = prefs.getString('appStoragePath');
    return hasRunBefore && storagePath != null && storagePath.isNotEmpty;
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
      if (!mounted) return;
      Provider.of<ThemeNotifier>(context, listen: false).loadTheme();
      
      // Trigger auto-backup after app is fully initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppLogger.log('MyApp: Triggering auto-backup after initialization');
          // Use a delay to ensure the app is fully loaded before checking auto-backup
          Future.delayed(const Duration(seconds: 2), () {
            triggerAutoBackup(context: navigatorKey.currentContext);
          });
        }
      });
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
      future: _isSetupComplete(),
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
              navigatorKey: navigatorKey, // Use global navigator key
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
              
            
            home: (snapshot.data ?? false)
                  ? const LibraryScreen()
                  : const WelcomeScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}