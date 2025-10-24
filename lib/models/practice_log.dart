/// Represents a single practice session log entry.
///
/// This class holds information about individual practice sessions,
/// including when they occurred and optional notes about the practice.
class PracticeLog {
  String id; // Unique identifier for the practice log entry
  String musicPieceId; // ID of the music piece this practice session belongs to
  DateTime timestamp; // When the practice session occurred
  String? notes; // Optional notes about the practice session
  int durationMinutes; // Duration of the practice session in minutes (optional, defaults to 0)

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
  String get formattedTimestamp {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDate == today) {
      return 'Today at ${_formatTime(timestamp)}';
    } else if (logDate == yesterday) {
      return 'Yesterday at ${_formatTime(timestamp)}';
    } else {
      return timestamp.toLocal().toString().split('.')[0];
    }
  }

  /// Formats time in 12-hour format with AM/PM.
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Gets the duration as a formatted string.
  ///
  /// Returns 'No duration recorded' if duration is 0, otherwise returns
  /// the duration in a human-readable format.
  String get formattedDuration {
    if (durationMinutes == 0) {
      return 'No duration recorded';
    } else if (durationMinutes < 60) {
      return '$durationMinutes minutes';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $minutes minutes';
      }
    }
  }
} 