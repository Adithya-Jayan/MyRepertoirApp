import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/utils/practice_indicator_utils.dart';
import 'package:repertoire/utils/practice_settings.dart';
import 'package:repertoire/utils/app_logger.dart';
import '../../screens/practice_logs_screen.dart';
import '../practice_logs/practice_log_dialog.dart';

/// A card widget to display and manage practice tracking for a music piece.
///
/// Allows enabling/disabling practice tracking, logging practice sessions,
/// and viewing last practice time and practice count.
class PracticeTrackingCard extends StatefulWidget {
  final MusicPiece musicPiece;
  final Function(MusicPiece) onMusicPieceChanged;
  final bool showTitle;
  final bool useCard;

  const PracticeTrackingCard({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
    this.showTitle = true,
    this.useCard = true,
  });

  @override
  State<PracticeTrackingCard> createState() => _PracticeTrackingCardState();
}

class _PracticeTrackingCardState extends State<PracticeTrackingCard> {
  late MusicPiece _musicPiece;
  final MusicPieceRepository _repository = MusicPieceRepository();

  @override
  void initState() {
    super.initState();
    _musicPiece = widget.musicPiece;
  }

  @override
  void didUpdateWidget(PracticeTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicPiece.id != widget.musicPiece.id) {
      _musicPiece = widget.musicPiece;
    }
  }

  /// Refreshes the music piece data from the database.
  Future<void> _refreshMusicPieceData() async {
    try {
      final updatedPiece = await _repository.getMusicPieceById(_musicPiece.id);
      if (updatedPiece != null && mounted) {
        setState(() {
          _musicPiece = updatedPiece;
        });
        widget.onMusicPieceChanged(_musicPiece);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Logs a practice session for the current music piece.
  ///
  /// Creates a new practice log entry and updates the music piece's practice tracking.
  Future<void> _logPractice() async {
    try {
      final showTimeStats = await PracticeSettings.getShowPracticeTimeStats();
      final showNotes = await PracticeSettings.getShowPracticeNotes();

      if (showTimeStats || showNotes) {
        if (!mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => PracticeLogDialog(
            showTimeStats: showTimeStats,
            showNotes: showNotes,
          ),
        );

        if (result != null) {
          await _repository.logPracticeSession(
            _musicPiece.id,
            notes: result['notes'],
            durationMinutes: result['durationMinutes'],
            timestamp: result['timestamp'],
          );
        } else {
          return; // User cancelled
        }
      } else {
        await _repository.logPracticeSession(_musicPiece.id);
      }
      
      // Refresh the music piece data
      final updatedPiece = await _repository.getMusicPieceById(_musicPiece.id);
      if (updatedPiece != null) {
        setState(() {
          _musicPiece = updatedPiece;
        });
        widget.onMusicPieceChanged(_musicPiece);
      }
    } catch (e) {
      AppLogger.log('Error logging practice session: $e');
      // Fallback to old method if practice logs are not available
      setState(() {
        _musicPiece = _musicPiece.copyWith(
          lastPracticeTime: DateTime.now(),
          practiceCount: _musicPiece.practiceCount + 1,
        );
      });
      await _repository.updateMusicPiece(_musicPiece);
      widget.onMusicPieceChanged(_musicPiece);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildStatTile(String label, String value, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: colorScheme.secondary),
              const SizedBox(height: 8.0),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            'Practice Tracking',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
        ],
        Row(
          children: [
            buildStatTile(
              'Last Practiced',
              PracticeIndicatorUtils.formatLastPracticeTime(_musicPiece.lastPracticeTime),
              Icons.calendar_today,
            ),
            const SizedBox(width: 12),
            buildStatTile(
              'Total Sessions',
              _musicPiece.practiceCount.toString(),
              Icons.repeat,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _logPractice,
                icon: const Icon(Icons.add_task),
                label: const Text('Log Practice'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PracticeLogsScreen(
                        musicPiece: _musicPiece,
                      ),
                    ),
                  );
                  await _refreshMusicPieceData();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.history),
              ),
            ),
          ],
        ),
      ],
    );

    if (widget.useCard) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      );
    }

    return content;
  }
}
