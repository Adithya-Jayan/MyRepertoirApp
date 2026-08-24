import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:repertoire/models/music_piece.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatefulWidget {
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
  State<BasicDetailsSection> createState() => _BasicDetailsSectionState();
}

class _BasicDetailsSectionState extends State<BasicDetailsSection> {
  late int _transposeSemitones;

  @override
  void initState() {
    super.initState();
    _transposeSemitones = widget.musicPiece.transposeSemitones;
  }

  String _formatSemitones(int value) => value > 0 ? '+$value' : '$value';

  Future<void> _showTransposePicker() async {
    int pendingValue = _transposeSemitones;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.transposeSemitones),
        content: StatefulBuilder(
          builder: (context, setDialogState) => NumberPicker(
            value: pendingValue,
            minValue: -24,
            maxValue: 24,
            textMapper: (value) => _formatSemitones(int.parse(value)),
            onChanged: (value) =>
                setDialogState(() => pendingValue = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(pendingValue),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null && result != _transposeSemitones) {
      setState(() => _transposeSemitones = result);
      widget.onTransposeSemitonesChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: widget.musicPiece.title,
          decoration: InputDecoration(labelText: context.l10n.title),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value!.isEmpty ? context.l10n.pleaseEnterATitle : null,
          onChanged: widget.onTitleChanged,
          onSaved: (value) => widget.onTitleChanged(value!),
        ),
        TextFormField(
          initialValue: widget.musicPiece.artistComposer,
          decoration: InputDecoration(labelText: context.l10n.artistComposer),
          textInputAction: TextInputAction.next,
          onChanged: widget.onArtistComposerChanged,
          onSaved: (value) => widget.onArtistComposerChanged(value!),
        ),
        InkWell(
          onTap: _showTransposePicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.transposeSemitones,
            ),
            child: Text(_formatSemitones(_transposeSemitones)),
          ),
        ),
      ],
    );
  }
}
