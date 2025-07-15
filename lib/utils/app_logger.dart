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
    _debugLogsEnabled = prefs.getBool(_debugLogsEnabledKey) ?? false;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File(p.join(directory.path, _logFileName));
      // Ensure the log file exists
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
    } catch (e) {
      print('Error initializing log file: $e');
      _logFile = null; // Disable file logging if initialization fails
    }
  }

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';

    // Always print to console if debug logs are enabled
    if (_debugLogsEnabled) {
      print(logMessage);
    }

    // Write to file if debug logs are enabled and log file is available
    if (_debugLogsEnabled && _logFile != null) {
      try {
        _logFile!.writeAsStringSync('$logMessage\n', mode: FileMode.append);
      } catch (e) {
        print('Error writing to log file: $e');
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
}