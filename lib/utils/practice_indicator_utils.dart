import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeIndicatorUtils {
  static Future<Color> getPracticeIndicatorColor(DateTime? lastPracticeTime) async {
    final prefs = await SharedPreferences.getInstance();
    final greenPeriod = prefs.getInt('greenPeriod') ?? 7;
    final greenToYellowTransition = prefs.getInt('greenToYellowTransition') ?? 7;
    final yellowToRedTransition = prefs.getInt('yellowToRedTransition') ?? 16;
    final redToBlackTransition = prefs.getInt('redToBlackTransition') ?? 30;

    if (lastPracticeTime == null) {
      return Colors.black;
    }

    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final daysSincePractice = difference.inDays;

    final greenEnd = greenPeriod;
    final yellowEnd = greenEnd + greenToYellowTransition;
    final redEnd = yellowEnd + yellowToRedTransition;
    final blackEnd = redEnd + redToBlackTransition;

    if (daysSincePractice <= greenEnd) {
      return Colors.green;
    } else if (daysSincePractice <= yellowEnd) {
      return _calculateColor(
          daysSincePractice, greenEnd, yellowEnd, Colors.green, Colors.yellow);
    } else if (daysSincePractice <= redEnd) {
      return _calculateColor(
          daysSincePractice, yellowEnd, redEnd, Colors.yellow, Colors.red);
    } else if (daysSincePractice <= blackEnd) {
      return _calculateColor(
          daysSincePractice, redEnd, blackEnd, Colors.red, Colors.black);
    } else {
      return Colors.black;
    }
  }

  static Color _calculateColor(int days, int periodStart, int periodEnd, Color startColor, Color endColor) {
    // Ensure we don't divide by zero
    if (periodEnd - periodStart <= 0) {
        return endColor;
    }
    // Calculate the progress within the current transition period
    double t = (days - periodStart) / (periodEnd - periodStart);
    t = t.clamp(0.0, 1.0); // Ensure t is within the valid range
    return Color.lerp(startColor, endColor, t)!;
  }

  /// Gets a human-readable description of the practice status.
  ///
  /// Returns strings like "Recently practiced", "Needs attention", etc.
  static String getPracticeStatusDescription(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return "Never practiced";
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final hoursSincePractice = difference.inHours;
    final daysSincePractice = difference.inDays;
    
    if (hoursSincePractice < 48) {
      return "Recently practiced";
    } else if (daysSincePractice <= 7) {
      return "Practiced this week";
    } else if (daysSincePractice <= 14) {
      return "Practiced recently";
    } else if (daysSincePractice <= 32) {
      return "Needs attention";
    } else {
      return "Long overdue";
    }
  }

  /// Formats the last practice time for display.
  ///
  /// Returns 'Never practiced' if [lastPracticeTime] is null.
  /// Otherwise, returns a human-readable string like 'Today', 'Yesterday',
  /// 'X days ago', or the date.
  static String formatLastPracticeTime(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return 'Never practiced';
    }
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);

    if (difference.inDays == 0) {
      return 'Last practiced: Today';
    } else if (difference.inDays == 1) {
      return 'Last practiced: Yesterday';
    } else if (difference.inDays < 30) {
      return 'Last practiced: ${difference.inDays} days ago';
    } else {
      return 'Last practiced: ${lastPracticeTime.toLocal().toString().split(' ')[0]}';
    }
  }
} 