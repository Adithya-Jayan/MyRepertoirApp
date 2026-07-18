import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:repertoire/l10n/app_localizations.dart';
import '../services/practice_config_service.dart';
import '../models/practice_stage.dart';

class PracticeIndicatorUtils {
  static Color? getPracticeIndicatorColorSync(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return Colors.black;
    }

    final stages = PracticeConfigService.cachedStages;
    if (stages == null || stages.isEmpty) {
      return null;
    }

    return _calculateColorForStages(lastPracticeTime, stages);
  }

  static Future<Color> getPracticeIndicatorColor(
    DateTime? lastPracticeTime,
  ) async {
    if (lastPracticeTime == null) {
      return Colors.black;
    }

    if (PracticeConfigService.cachedStages != null) {
      final color = getPracticeIndicatorColorSync(lastPracticeTime);
      if (color != null) return color;
    }

    final service = PracticeConfigService();
    final stages = await service.loadStages();

    if (stages.isEmpty) {
      return Colors.black;
    }

    return _calculateColorForStages(lastPracticeTime, stages);
  }

  static Color _calculateColorForStages(
    DateTime lastPracticeTime,
    List<PracticeStage> stages,
  ) {
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
          nextStage.color,
        );
      }

      accumulatedDays = transitionEnd;
    }

    return stages.last.color;
  }

  static Color _calculateColor(
    int days,
    int periodStart,
    int periodEnd,
    Color startColor,
    Color endColor,
  ) {
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
  static String getPracticeStatusDescription(
    DateTime? lastPracticeTime,
    AppLocalizations l10n,
  ) {
    if (lastPracticeTime == null) {
      return l10n.neverPracticed;
    }

    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final daysSincePractice = difference.inDays;

    // Fallback static logic since this method is synchronous and unused.
    // If we needed it, we'd make it async.
    if (daysSincePractice <= 7) {
      return l10n.practicedRecently;
    } else if (daysSincePractice <= 30) {
      return l10n.needsAttention;
    } else {
      return l10n.longOverdue;
    }
  }

  /// Formats the last practice time for display.
  static String formatLastPracticeTime(
    DateTime? lastPracticeTime,
    AppLocalizations l10n,
  ) {
    if (lastPracticeTime == null) {
      return l10n.neverPracticed;
    }
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);

    if (difference.inDays == 0) {
      return l10n.lastPracticedToday;
    } else if (difference.inDays == 1) {
      return l10n.lastPracticedYesterday;
    } else if (difference.inDays < 30) {
      return l10n.lastPracticedDaysAgo(difference.inDays);
    } else {
      final formattedDate = DateFormat.yMd(
        l10n.localeName,
      ).format(lastPracticeTime.toLocal());
      return l10n.lastPracticedAt(formattedDate);
    }
  }
}
