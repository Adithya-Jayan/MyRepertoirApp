import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';

class BasicDetailsSection extends StatelessWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: musicPiece.title,
          decoration: const InputDecoration(labelText: 'Title'),
          validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
          onChanged: onTitleChanged,
          onSaved: (value) => onTitleChanged(value!),
        ),
        TextFormField(
          initialValue: musicPiece.artistComposer,
          decoration: const InputDecoration(labelText: 'Artist/Composer'),
          onChanged: onArtistComposerChanged,
          onSaved: (value) => onArtistComposerChanged(value!),
        ),
      ],
    );
  }
}
