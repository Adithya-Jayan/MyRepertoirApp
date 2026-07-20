import 'package:flutter/material.dart';
import '../models/music_piece.dart';

import '../models/media_item.dart';

import 'package:repertoire/l10n/l10n.dart';

class MidiPlayerWidget extends StatelessWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;
  final Function(MediaItem)? onMediaItemChanged;

  const MidiPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
    this.onMediaItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            SizedBox(height: 8),
            Text(
              context.l10n.midiPlaybackIsNotSupportedOnWeb,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              context
                  .l10n
                  .pleaseUseTheAndroidWindowsOrLinuxVersionForMidiSupport,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
