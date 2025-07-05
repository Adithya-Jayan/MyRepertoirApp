import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'screens/library_screen.dart';
import 'screens/welcome_screen.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'utils/theme_notifier.dart'; // Import ThemeNotifier

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(ThemeMode.system), // Initial theme mode
      child: const MyApp(),
    ),
  );
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
