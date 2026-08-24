import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/detail_widgets/musicbrainz_search_dialog.dart';

import 'package:repertoire/l10n/l10n.dart';

class BasicDetailsSection extends StatefulWidget {
  final MusicPiece musicPiece;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistComposerChanged;
  final ValueChanged<int> onTransposeSemitonesChanged;
  final void Function(String title, String artist, Uint8List? coverArtBytes)
  onMusicBrainzResultApplied;
  final VoidCallback? onSaveRequested;

  const BasicDetailsSection({
    super.key,
    required this.musicPiece,
    required this.onTitleChanged,
    required this.onArtistComposerChanged,
    required this.onTransposeSemitonesChanged,
    required this.onMusicBrainzResultApplied,
    this.onSaveRequested,
  });

  @override
  State<BasicDetailsSection> createState() => _BasicDetailsSectionState();
}

class _BasicDetailsSectionState extends State<BasicDetailsSection> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late int _transposeSemitones;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.musicPiece.title);
    _artistController = TextEditingController(
      text: widget.musicPiece.artistComposer,
    );
    _transposeSemitones = widget.musicPiece.transposeSemitones;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
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

  Future<void> _showMusicBrainzSearch() async {
    final result = await showDialog<MusicBrainzPickResult>(
      context: context,
      builder: (dialogContext) => MusicBrainzSearchDialog(
        initialTitle: _titleController.text,
        initialArtist: _artistController.text,
      ),
    );
    if (result == null) return;

    _titleController.text = result.title;
    _artistController.text = result.artist;
    widget.onMusicBrainzResultApplied(
      result.title,
      result.artist,
      result.coverArtBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(labelText: context.l10n.title),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value!.isEmpty ? context.l10n.pleaseEnterATitle : null,
          onChanged: widget.onTitleChanged,
          onSaved: (value) => widget.onTitleChanged(value!),
        ),
        TextFormField(
          controller: _artistController,
          decoration: InputDecoration(labelText: context.l10n.artistComposer),
          textInputAction: TextInputAction.next,
          onChanged: widget.onArtistComposerChanged,
          onSaved: (value) => widget.onArtistComposerChanged(value!),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(context.l10n.searchMusicBrainz),
            onPressed: _showMusicBrainzSearch,
          ),
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
