import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'screens/library_screen.dart';
import 'screens/welcome_screen.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'utils/theme_notifier.dart'; // Import ThemeNotifier

import 'package:just_audio_background/just_audio_background.dart';

import 'package:path/path.dart' as p;
import 'dart:convert';
import 'database/music_piece_repository.dart';
import 'models/music_piece.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(ThemeMode.system), // Initial theme mode
      child: const MyApp(),
    ),
  );
  _triggerAutoBackup();
}

Future<void> _triggerAutoBackup() async {
  final prefs = await SharedPreferences.getInstance();
  final autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
  if (autoBackupEnabled) {
    final lastBackupTimestamp = prefs.getInt('lastAutoBackupTimestamp') ?? 0;
    final autoBackupFrequency = prefs.getInt('autoBackupFrequency') ?? 7;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastBackupTimestamp > autoBackupFrequency * 24 * 60 * 60 * 1000) {
      final MusicPieceRepository repository = MusicPieceRepository();
      final musicPieces = await repository.getMusicPieces();
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'music_repertoire_backup_$timestamp.json';

      final storagePath = prefs.getString('appStoragePath');
      if (storagePath != null) {
        final autoBackupDir = Directory(p.join(storagePath, 'Backups', 'Autobackups'));
        if (!await autoBackupDir.exists()) {
          await autoBackupDir.create(recursive: true);
        }
        final outputFile = File(p.join(autoBackupDir.path, fileName));
        await outputFile.writeAsBytes(utf8.encode(jsonString));
        await prefs.setInt('lastAutoBackupTimestamp', now);

        final autoBackupCount = prefs.getInt('autoBackupCount') ?? 5;
        final files = await autoBackupDir.list().toList();
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        if (files.length > autoBackupCount) {
          for (int i = 0; i < files.length - autoBackupCount; i++) {
            await files[i].delete();
          }
        }
      }
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _hasRunBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasRunBefore') ?? false;
  }

  @override
  void initState() {
    super.initState();
    // Load theme preference when the app starts
    Provider.of<ThemeNotifier>(context, listen: false).loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasRunBefore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            return MaterialApp(
              title: 'Music Repertoire',
              themeMode: themeNotifier.themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
                useMaterial3: true,
              ),
              home: snapshot.data == true ? const LibraryScreen() : const WelcomeScreen(),
            );
          },
        );
      },
    );
  }
}
