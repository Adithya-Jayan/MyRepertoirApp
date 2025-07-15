// Core Flutter and Material Design imports
import 'package:flutter/material.dart';
// For persistent key-value storage (e.g., user preferences, first-run flag)
import 'package:shared_preferences/shared_preferences.dart';
// State management solution for managing and providing data to widgets
import 'package:provider/provider.dart';
// Screen displaying the main music repertoire library
import 'screens/library_screen.dart';
// Initial welcome and setup screen for first-time users
import 'screens/welcome_screen.dart';
// Dart's I/O library for file system operations (e.g., checking platform)
import 'dart:io';

// FFI (Foreign Function Interface) support for sqflite on desktop platforms
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Custom notifier for managing and providing theme changes throughout the app
import 'utils/theme_notifier.dart';

// For background audio playback and media controls
import 'package:just_audio_background/just_audio_background.dart';

// Path manipulation utilities for joining and normalizing paths
import 'package:path/path.dart' as p;
// For encoding and decoding JSON data
import 'dart:convert';
// Repository for handling CRUD operations related to MusicPiece objects
import 'database/music_piece_repository.dart';
// Data model for a single music piece
import 'models/music_piece.dart';
// For internationalization, specifically date and time formatting
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/app_logger.dart';

/// Main entry point of the application.
/// Initializes Flutter, sets up platform-specific database factories,
/// initializes background audio services, and starts the app.
Future<void> main() async {
  // Ensures that Flutter widgets are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.init(); // Initialize the logger
  AppLogger.log('App started.');

  await _requestPermissions();


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
  _triggerAutoBackup();
}

/// Initiates an automatic backup of music piece data if enabled by the user
/// and if the defined backup frequency interval has passed.
///
/// This function checks user preferences for auto-backup, determines if a backup
/// is due, fetches music piece data, serializes it to JSON, and saves it
/// to a designated auto-backup directory within the app's storage path.
/// It also manages the number of backup files, deleting older ones to
/// maintain a specified count.
Future<void> _triggerAutoBackup() async {
  // Obtain an instance of SharedPreferences to access user preferences.
  final prefs = await SharedPreferences.getInstance();
  // Check if auto-backup is enabled by the user (defaults to false if not set).
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;

  if (autoBackupEnabled) {
    // Retrieve the timestamp of the last auto-backup (defaults to 0 if not set).
    final lastBackupTimestamp = prefs.getInt('lastAutoBackupTimestamp') ?? 0;
    // Retrieve the auto-backup frequency in days (defaults to 7 days if not set).
    final autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
    // Get the current time in milliseconds since epoch.
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if the time elapsed since the last backup exceeds the auto-backup frequency.
    // Frequency is converted from days to milliseconds.
    if (now - lastBackupTimestamp > autoBackupFrequency * 24 * 60 * 60 * 1000) {
      // Initialize MusicPieceRepository to fetch music piece data.
      final MusicPieceRepository repository = MusicPieceRepository();
      // Retrieve all music pieces from the database.
      final musicPieces = await repository.getMusicPieces();
      // Encode the list of music pieces into a JSON string.
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      // Format the current timestamp for use in the backup file name.
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      // Construct the backup file name.
      final fileName = 'music_repertoire_backup_$timestamp.json';

      // Retrieve the user-selected application storage path.
      final storagePath = prefs.getString('appStoragePath');
      if (storagePath != null) {
        // Define the directory for auto-backups within the storage path.
        final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
        // Create the auto-backup directory if it doesn't exist, including any necessary parent directories.
        if (!await autoBackupDir.exists()) {
          await autoBackupDir.create(recursive: true);
        }
        // Define the full path for the new backup file.
        final outputFile = File(p.join(autoBackupDir.path, fileName));
        // Write the JSON string content to the backup file.
        await outputFile.writeAsBytes(utf8.encode(jsonString));
        // Update the last auto-backup timestamp in SharedPreferences.
        await prefs.setInt('lastAutoBackupTimestamp', now);

        // Retrieve the maximum number of auto-backup files to keep (defaults to 5).
        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        // Get a list of all files in the auto-backup directory.
        final files = await autoBackupDir.list().toList();
        // Sort files by their modification time to identify the oldest ones.
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        // If the number of backup files exceeds the allowed count, delete the oldest ones.
        if (files.length > autoBackupCount) {
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            await files[i].delete();
          }
        }
      }
    }
  }
}

/// Requests necessary permissions for the application.
/// Handles storage permissions for Android and iOS.
Future<void> _requestPermissions() async {
  print("Attempting to request permissions...");
  if (Platform.isAndroid) {
    print("Platform is Android.");
    var status = await Permission.manageExternalStorage.status;
    print("Current Manage External Storage status: $status");
    if (!status.isGranted) {
      AppLogger.log("Requesting Manage External Storage permission...");
      status = await Permission.manageExternalStorage.request();
      AppLogger.log("New Manage External Storage status after request: $status");
      if (!status.isGranted) {
        AppLogger.log("Manage External Storage permission denied by user.");
        // You might want to show a dialog or navigate to app settings
      }
    } else {
      AppLogger.log("Manage External Storage permission already granted.");
    }
  } else if (Platform.isIOS) {
    AppLogger.log("Platform is iOS.");
    var status = await Permission.photos.status;
    AppLogger.log("Current Photos permission status: $status");
    if (!status.isGranted) {
      AppLogger.log("Requesting Photos permission...");
      status = await Permission.photos.request();
      AppLogger.log("New Photos permission status after request: $status");
      if (!status.isGranted) {
        AppLogger.log("Photos permission denied by user.");
      }
    } else {
      AppLogger.log("Photos permission already granted.");
    }
  }
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

  @override
  void initState() {
    super.initState();
    // Load the user's saved theme preference when the app starts.
    // listen: false is used because we only need to call a method on ThemeNotifier,
    // not rebuild the widget when ThemeNotifier changes.
    Provider.of<ThemeNotifier>(context, listen: false).loadTheme();
  }

  @override
  Widget build(BuildContext context) {
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
