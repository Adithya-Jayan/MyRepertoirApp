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
    // Simple discrete color ranges for better predictability
    if (hoursSincePractice <= 72) {
      // 48-72 hours: Light yellow
      return Colors.yellow.shade100;
    } else if (hoursSincePractice <= 168) {
      // 3-7 days: Yellow
      return Colors.yellow;
    } else if (hoursSincePractice <= 336) {
      // 8-14 days: Orange
      return Colors.orange;
    } else {
      // 15+ days: Red
      return Colors.red;
    }
  }
  
  /// Performs logarithmic interpolation between two values.
  ///
  /// Returns a value between 0 and 1 representing the position on a logarithmic scale.
  static double _logInterpolate(double value, double min, double max) {
    if (value <= min) return 0.0;
    if (value >= max) return 1.0;
    
    // Use logarithmic interpolation for smoother transition
    final logMin = log(min);
    final logMax = log(max);
    final logValue = log(value);
    
    return (logValue - logMin) / (logMax - logMin);
  }
  
  /// Natural logarithm function.
  static double log(double x) {
    return x <= 0 ? 0 : math.log(x);
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


} 