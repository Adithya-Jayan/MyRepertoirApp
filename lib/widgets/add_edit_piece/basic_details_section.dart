import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatelessWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;
  final ValueChanged<int> onTransposeSemitonesChanged;
  final VoidCallback? onSaveRequested;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
    required this.onTransposeSemitonesChanged,
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
          textInputAction: TextInputAction.next,
          onChanged: onArtistComposerChanged,
          onSaved: (value) => onArtistComposerChanged(value!),
        ),
        TextFormField(
          initialValue: musicPiece.transposeSemitones == 0
              ? ''
              : musicPiece.transposeSemitones.toString(),
          decoration: InputDecoration(
            labelText: context.l10n.transposeSemitones,
            hintText: context.l10n.transposeSemitonesHint,
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          textInputAction: TextInputAction.done,
          onChanged: (value) =>
              onTransposeSemitonesChanged(int.tryParse(value) ?? 0),
          onSaved: (value) =>
              onTransposeSemitonesChanged(int.tryParse(value ?? '') ?? 0),
          onFieldSubmitted: (_) => onSaveRequested?.call(),
        ),
      ],
    );
  }
}
