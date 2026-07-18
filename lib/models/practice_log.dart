import 'package:intl/intl.dart';
import 'package:repertoire/l10n/app_localizations.dart';

/// Represents a single practice session log entry.
///
/// This class holds information about individual practice sessions,
/// including when they occurred and optional notes about the practice.
class PracticeLog {
  String id; // Unique identifier for the practice log entry
  String musicPieceId; // ID of the music piece this practice session belongs to
  DateTime timestamp; // When the practice session occurred
  String? notes; // Optional notes about the practice session
  int
  durationMinutes; // Duration of the practice session in minutes (optional, defaults to 0)

  /// Constructor for the PracticeLog class.
  PracticeLog({
    required this.id,
    required this.musicPieceId,
    required this.timestamp,
    this.notes,
    this.durationMinutes = 0,
  });

  /// Converts a [PracticeLog] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
    'id': id,
    'musicPieceId': musicPieceId,
    'timestamp': timestamp.toIso8601String(),
    'notes': notes,
    'durationMinutes': durationMinutes,
  };

  /// Creates a [PracticeLog] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory PracticeLog.fromJson(Map<String, dynamic> json) => PracticeLog(
    id: json['id'],
    musicPieceId: json['musicPieceId'],
    timestamp: DateTime.parse(json['timestamp']),
    notes: json['notes'],
    durationMinutes: json['durationMinutes'] ?? 0,
  );

  /// Creates a copy of this [PracticeLog] object with optional new values.
  ///
  /// This method is useful for immutably updating properties of a practice log.
  PracticeLog copyWith({
    String? id,
    String? musicPieceId,
    DateTime? timestamp,
    String? notes,
    int? durationMinutes,
  }) {
    return PracticeLog(
      id: id ?? this.id,
      musicPieceId: musicPieceId ?? this.musicPieceId,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  /// Formats the timestamp for display.
  ///
  /// Returns a human-readable string like 'Today at 2:30 PM', 'Yesterday at 3:15 PM',
  /// or the full date and time.
  String formattedTimestamp(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final localTimestamp = timestamp.toLocal();
    final formattedTime = DateFormat.jm(l10n.localeName).format(localTimestamp);

    if (logDate == today) {
      return l10n.todayAt(formattedTime);
    } else if (logDate == yesterday) {
      return l10n.yesterdayAt(formattedTime);
    } else {
      return DateFormat.yMd(l10n.localeName).add_jm().format(localTimestamp);
    }
  }

  /// Gets the duration as a formatted string.
  ///
  /// Returns 'No duration recorded' if duration is 0, otherwise returns
  /// the duration in a human-readable format.
  String formattedDuration(AppLocalizations l10n) {
    if (durationMinutes == 0) {
      return l10n.noDurationRecorded;
    } else if (durationMinutes < 60) {
      return l10n.durationMinutes(durationMinutes);
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return l10n.durationHours(hours);
      } else {
        return l10n.durationHoursMinutes(hours, minutes);
      }
    }
  }
}
