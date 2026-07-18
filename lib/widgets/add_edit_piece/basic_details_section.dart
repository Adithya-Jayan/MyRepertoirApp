import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatelessWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;
  final VoidCallback? onSaveRequested;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
    this.onSaveRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: musicPiece.title,
          decoration: InputDecoration(labelText: context.l10n.title),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value!.isEmpty ? context.l10n.pleaseEnterATitle : null,
          onChanged: onTitleChanged,
          onSaved: (value) => onTitleChanged(value!),
        ),
        TextFormField(
          initialValue: musicPiece.artistComposer,
          decoration: InputDecoration(labelText: context.l10n.artistComposer),
          textInputAction: TextInputAction.done,
          onChanged: onArtistComposerChanged,
          onSaved: (value) => onArtistComposerChanged(value!),
          onFieldSubmitted: (_) => onSaveRequested?.call(),
        ),
      ],
    );
  }
}
