import 'package:flutter/material.dart';
import '../../models/music_piece.dart';
import '../../models/practice_log.dart';
import '../../utils/practice_indicator_utils.dart';

import 'package:repertoire/l10n/l10n.dart';

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

    final logsWithDurationCount = practiceLogs
        .where((log) => log.durationMinutes > 0)
        .length;

    final averageDuration = logsWithDurationCount > 0
        ? totalDuration / logsWithDurationCount
        : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.practiceSummary,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryItem(
                    label: context.l10n.totalSessions,
                    value: '${musicPiece.practiceCount}',
                    icon: Icons.music_note,
                  ),
                ),
                if (showTimeStats) ...[
                  Expanded(
                    child: SummaryItem(
                      label: context.l10n.totalTime,
                      value: _formatDuration(context, totalDuration),
                      icon: Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: SummaryItem(
                      label: context.l10n.averageTime,
                      value: _formatDuration(context, averageDuration.round()),
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
                  PracticeIndicatorUtils.formatLastPracticeTime(
                    musicPiece.lastPracticeTime,
                    context.l10n,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes < 60) return context.l10n.durationMinutes(minutes);
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return context.l10n.durationHours(hours);
    }
    return context.l10n.durationHoursMinutes(hours, remainingMinutes);
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
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
