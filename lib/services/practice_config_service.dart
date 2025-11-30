import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/practice_stage.dart';

class PracticeConfigService {
  static const String _stagesKey = 'practice_stages';

  Future<List<PracticeStage>> loadStages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stagesJson = prefs.getString(_stagesKey);

    if (stagesJson != null) {
      // Load from new format
      final List<dynamic> decoded = jsonDecode(stagesJson);
      return decoded.map((e) => PracticeStage.fromJson(e)).toList();
    } else {
      // Migrate from old format
      return _migrateFromOldSettings(prefs);
    }
  }

  Future<List<PracticeStage>> _migrateFromOldSettings(SharedPreferences prefs) async {
    final greenPeriod = prefs.getInt('greenPeriod') ?? 7;
    final greenToYellow = prefs.getInt('greenToYellowTransition') ?? 7;
    final yellowToRed = prefs.getInt('yellowToRedTransition') ?? 16;
    final redToBlack = prefs.getInt('redToBlackTransition') ?? 30;

    final uuid = const Uuid();

    final stages = [
      PracticeStage(
        id: uuid.v4(),
        name: 'Recently practiced',
        colorValue: Colors.green.toARGB32(),
        holdDays: greenPeriod,
        transitionDays: greenToYellow,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: 'Been a while',
        colorValue: Colors.yellow.toARGB32(),
        holdDays: 0,
        transitionDays: yellowToRed,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: 'A long while',
        colorValue: Colors.red.toARGB32(),
        holdDays: 0,
        transitionDays: redToBlack,
      ),
      PracticeStage(
        id: uuid.v4(),
        name: 'Been too long',
        colorValue: Colors.black.toARGB32(),
        holdDays: 0,
        transitionDays: 0, // Last stage
      ),
    ];

    // Save immediately so next time we load fast
    await saveStages(stages);
    return stages;
  }

  Future<void> saveStages(List<PracticeStage> stages) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(stages.map((e) => e.toJson()).toList());
    await prefs.setString(_stagesKey, encoded);
  }
}
