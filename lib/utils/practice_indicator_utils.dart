import 'package:flutter/material.dart';
import '../services/practice_config_service.dart';

class PracticeIndicatorUtils {
  static Future<Color> getPracticeIndicatorColor(DateTime? lastPracticeTime) async {
    if (lastPracticeTime == null) {
      return Colors.black;
    }

    final service = PracticeConfigService();
    final stages = await service.loadStages();

    if (stages.isEmpty) {
        return Colors.black;
    }

    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final daysSincePractice = difference.inDays;

    int accumulatedDays = 0;

    for (int i = 0; i < stages.length; i++) {
      final stage = stages[i];
      
      // Hold Period Check
      final holdEnd = accumulatedDays + stage.holdDays;
      if (daysSincePractice <= holdEnd) {
        return stage.color;
      }

      // If last stage, we stay here forever
      if (i == stages.length - 1) {
        return stage.color;
      }
      
      // Transition Period Check
      final nextStage = stages[i + 1];
      final transitionEnd = holdEnd + stage.transitionDays;
      
      if (daysSincePractice <= transitionEnd) {
        return _calculateColor(
          daysSincePractice,
          holdEnd,
          transitionEnd,
          stage.color,
          nextStage.color
        );
      }

      accumulatedDays = transitionEnd;
    }

    return stages.last.color;
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
  /// This relies on the first stage being roughly "Recently practiced" etc.
  /// For full dynamic names, we'd need to return the stage name.
  static String getPracticeStatusDescription(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return "Never practiced";
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final daysSincePractice = difference.inDays;
    
    // Fallback static logic since this method is synchronous and unused.
    // If we needed it, we'd make it async.
    if (daysSincePractice <= 7) {
      return "Practiced recently";
    } else if (daysSincePractice <= 30) {
      return "Needs attention";
    } else {
      return "Long overdue";
    }
  }

  /// Formats the last practice time for display.
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