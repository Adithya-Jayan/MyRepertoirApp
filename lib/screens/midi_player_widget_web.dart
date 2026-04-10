import 'package:flutter/material.dart';
import '../models/music_piece.dart';

class MidiPlayerWidget extends StatelessWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  const MidiPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            SizedBox(height: 8),
            Text(
              'MIDI playback is not supported on Web.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Please use the Android, Windows, or Linux version for MIDI support.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
