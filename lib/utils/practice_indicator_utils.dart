import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility class for calculating practice indicator colors based on practice recency.
///
/// Uses a logarithmic scale where:
/// - Green: Less than 48 hours (2 days)
/// - Yellow to Red: 48 hours to 32 days (logarithmic transition)
/// - Black: More than 32 days or never practiced
class PracticeIndicatorUtils {
  /// The threshold for green color (48 hours = 2 days)
  static const int greenThresholdHours = 48;
  
  /// The threshold for black color (32 days)
  static const int blackThresholdDays = 32;
  
  /// Calculates the color for the practice indicator based on last practice time.
  ///
  /// Returns:
  /// - [Colors.green] if practiced within 48 hours
  /// - A color between yellow and red for 48 hours to 32 days (logarithmic)
  /// - [Colors.black] if more than 32 days or never practiced
  static Color getPracticeIndicatorColor(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return Colors.black;
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);
    final hoursSincePractice = difference.inHours;
    final daysSincePractice = difference.inDays;
    
    // Green if practiced within 48 hours
    if (hoursSincePractice < greenThresholdHours) {
      return Colors.green;
    }
    
    // Black if more than 32 days
    if (daysSincePractice > blackThresholdDays) {
      return Colors.black;
    }
    
    // Simple discrete color ranges for better predictability
    return _calculateLogarithmicColor(hoursSincePractice);
  }
  
  /// Calculates a color using a simpler, more predictable scale.
  ///
  /// Uses discrete ranges for better visual feedback:
  /// - 48-72 hours: Light yellow
  /// - 3-7 days: Yellow
  /// - 8-14 days: Orange
  /// - 15-31 days: Red
  static Color _calculateLogarithmicColor(int hoursSincePractice) {
    // Smooth gradient: green (48h) -> yellow (192h) -> red (336h)
    const int minHours = 48;
    const int midHours = 192; // 8 days
    const int maxHours = 336; // 14 days
    if (hoursSincePractice <= minHours) return Colors.green;
    if (hoursSincePractice >= maxHours) return Colors.red;

    if (hoursSincePractice <= midHours) {
      // Green to yellow
      double t = (hoursSincePractice - minHours) / (midHours - minHours);
      return Color.lerp(Colors.green, Colors.yellow, t)!;
    } else {
      // Yellow to red
      double t = (hoursSincePractice - midHours) / (maxHours - midHours);
      return Color.lerp(Colors.yellow, Colors.red, t)!;
    }
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
    
    if (hoursSincePractice < greenThresholdHours) {
      return "Recently practiced";
    } else if (daysSincePractice <= 7) {
      return "Practiced this week";
    } else if (daysSincePractice <= 14) {
      return "Practiced recently";
    } else if (daysSincePractice <= blackThresholdDays) {
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