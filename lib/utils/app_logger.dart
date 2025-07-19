import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class AppLogger {
  static bool _debugLogsEnabled = false;
  static File? _logFile;
  static const String _logFileName = 'app_debug.log';
  static const String _debugLogsEnabledKey = 'debugLogsEnabled';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _debugLogsEnabled = prefs.getBool(_debugLogsEnabledKey) ?? true; // Enable by default for testing

    try {
      // Try to use the user-selected storage path first
      final appStoragePath = prefs.getString('appStoragePath');
      if (appStoragePath != null && appStoragePath.isNotEmpty) {
        final logsDirectory = Directory(p.join(appStoragePath, 'logs'));
        if (!await logsDirectory.exists()) {
          await logsDirectory.create(recursive: true);
        }
        _logFile = File(p.join(logsDirectory.path, _logFileName));
        debugPrint('AppLogger: Using user storage path for logs: ${_logFile!.path}');
      } else {
        // Fallback to application documents directory if no storage path is set
        final directory = await getApplicationDocumentsDirectory();
        _logFile = File(p.join(directory.path, _logFileName));
        debugPrint('AppLogger: Using fallback path for logs: ${_logFile!.path}');
      }
      
      // Ensure the log file exists
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('AppLogger: Error initializing log file: $e');
      _logFile = null; // Disable file logging if initialization fails
    }
  }

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';

    // Always print to console if debug logs are enabled
    if (_debugLogsEnabled) {
      debugPrint(logMessage);
    }

    // Write to file if debug logs are enabled and log file is available
    if (_debugLogsEnabled && _logFile != null) {
      try {
        _logFile!.writeAsStringSync('$logMessage\n', mode: FileMode.append);
      } catch (e) {
        debugPrint('Error writing to log file: $e');
      }
    }
  }

  static Future<void> setDebugLogsEnabled(bool enabled) async {
    _debugLogsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugLogsEnabledKey, enabled);
    log('Debug logs ${enabled ? 'enabled' : 'disabled'}.');
  }

  static bool get debugLogsEnabled => _debugLogsEnabled;

  /// Reinitializes the logger with the current storage path
  /// This should be called when the app storage path changes
  static Future<void> reinitialize() async {
    log('Reinitializing logger with new storage path');
    await init();
  }
}