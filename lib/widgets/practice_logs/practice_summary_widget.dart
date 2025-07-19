import 'package:flutter/material.dart';
import '../../models/music_piece.dart';
import '../../models/practice_log.dart';

/// A widget that displays practice summary statistics for a music piece.
class PracticeSummaryWidget extends StatelessWidget {
  final MusicPiece musicPiece;
  final List<PracticeLog> practiceLogs;
  final bool showTimeStats;

  const PracticeSummaryWidget({
    super.key,
    required this.musicPiece,
    required this.practiceLogs,
    required this.showTimeStats,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = practiceLogs.fold<int>(
      0,
      (sum, log) => sum + log.durationMinutes,
    );
    
    final averageDuration = practiceLogs.isNotEmpty 
        ? totalDuration / practiceLogs.length 
        : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryItem(
                    label: 'Total Sessions',
                    value: '${musicPiece.practiceCount}',
                    icon: Icons.music_note,
                  ),
                ),
                if (showTimeStats) ...[
                  Expanded(
                    child: SummaryItem(
                      label: 'Total Time',
                      value: _formatDuration(totalDuration),
                      icon: Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: SummaryItem(
                      label: 'Average Time',
                      value: _formatDuration(averageDuration.round()),
                      icon: Icons.av_timer,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text(
                  musicPiece.lastPracticeTime != null
                    ? 'Last practiced: ${musicPiece.lastPracticeTime!.toLocal().toString().split('.')[0]}'
                    : 'Never practiced',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }
}

/// A widget that displays a summary item with an icon, label, and value.
class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const SummaryItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 