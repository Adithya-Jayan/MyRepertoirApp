import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SectionStateService extends ChangeNotifier {
  static const String _prefix = 'section_expanded_';
  
  static final SectionStateService _instance = SectionStateService._internal();
  factory SectionStateService() => _instance;
  SectionStateService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  bool isExpanded(String key, {bool defaultValue = true}) {
    if (!_initialized) return defaultValue;
    return _prefs.getBool('$_prefix$key') ?? defaultValue;
  }

  Future<void> setExpanded(String key, bool expanded) async {
    if (!_initialized) await init();
    await _prefs.setBool('$_prefix$key', expanded);
    notifyListeners();
  }

  Future<void> toggleAll(List<String> keys, bool expand) async {
    if (!_initialized) await init();
    for (final key in keys) {
      await _prefs.setBool('$_prefix$key', expand);
    }
    notifyListeners();
  }
}
