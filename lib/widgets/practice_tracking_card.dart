import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';

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

  String _formatLastPracticeTime(DateTime? lastPracticeTime) {
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

  Future<void> _logPractice() async {
    setState(() {
      _musicPiece = _musicPiece.copyWith(
        lastPracticeTime: DateTime.now(),
        practiceCount: _musicPiece.practiceCount + 1,
      );
    });
    await _repository.updateMusicPiece(_musicPiece);
    widget.onMusicPieceChanged(_musicPiece);
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
            Text(
              'Practice Tracking',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SwitchListTile(
              title: const Text('Enable Practice Tracking'),
              value: _musicPiece.enablePracticeTracking,
              onChanged: (bool value) async {
                setState(() {
                  _musicPiece = _musicPiece.copyWith(enablePracticeTracking: value);
                });
                await _repository.updateMusicPiece(_musicPiece);
                widget.onMusicPieceChanged(_musicPiece);
              },
            ),
            if (_musicPiece.enablePracticeTracking)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatLastPracticeTime(_musicPiece.lastPracticeTime)),
                  Text('Practice Count: ${_musicPiece.practiceCount}'),
                  ElevatedButton(
                    onPressed: _logPractice,
                    child: const Text('Log Practice'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
