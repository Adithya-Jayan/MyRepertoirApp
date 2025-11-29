import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/utils/practice_indicator_utils.dart';
import '../../screens/practice_logs_screen.dart';

/// A card widget to display and manage practice tracking for a music piece.
///
/// Allows enabling/disabling practice tracking, logging practice sessions,
/// and viewing last practice time and practice count.
class PracticeTrackingCard extends StatefulWidget {
  final MusicPiece musicPiece;
  final Function(MusicPiece) onMusicPieceChanged;

  const PracticeTrackingCard({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
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
      await _repository.logPracticeSession(_musicPiece.id);
      
      // Refresh the music piece data
      final updatedPiece = await _repository.getMusicPieceById(_musicPiece.id);
      if (updatedPiece != null) {
        setState(() {
          _musicPiece = updatedPiece;
        });
        widget.onMusicPieceChanged(_musicPiece);
      }
    } catch (e) {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Practice Tracking',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Switch(
                            value: _musicPiece.enablePracticeTracking,
                            onChanged: (bool value) async {
                              setState(() {
                                _musicPiece = _musicPiece.copyWith(enablePracticeTracking: value);
                              });
                              await _repository.updateMusicPiece(_musicPiece);
                              widget.onMusicPieceChanged(_musicPiece);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),            if (_musicPiece.enablePracticeTracking)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PracticeIndicatorUtils.formatLastPracticeTime(_musicPiece.lastPracticeTime)),
                  Text('Practice Count: ${_musicPiece.practiceCount}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _logPractice,
                          child: const Text('Log Practice'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PracticeLogsScreen(
                                  musicPiece: _musicPiece,
                                ),
                              ),
                            );
                            // Refresh data when returning from practice logs screen
                            await _refreshMusicPieceData();
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('View Logs'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}