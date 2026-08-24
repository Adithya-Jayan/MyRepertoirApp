import 'package:flutter/material.dart';
import 'package:repertoire/l10n/l10n.dart';
import 'package:repertoire/services/lrclib_service.dart';

/// A dialog that searches lrclib.net for a track's lyrics.
///
/// Pops with the plain-text lyrics of the result the user picks, or `null`
/// if the dialog is dismissed without a selection.
class LyricsSearchDialog extends StatefulWidget {
  final String initialTrackName;
  final String initialArtistName;
  final LrcLibService? service;

  const LyricsSearchDialog({
    super.key,
    required this.initialTrackName,
    required this.initialArtistName,
    this.service,
  });

  @override
  State<LyricsSearchDialog> createState() => _LyricsSearchDialogState();
}

class _LyricsSearchDialogState extends State<LyricsSearchDialog> {
  late final LrcLibService _service;
  late final TextEditingController _trackController;
  late final TextEditingController _artistController;

  bool _isSearching = false;
  String? _errorMessage;
  List<LrcLibResult>? _results;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LrcLibService();
    _trackController = TextEditingController(text: widget.initialTrackName);
    _artistController = TextEditingController(text: widget.initialArtistName);
  }

  @override
  void dispose() {
    _trackController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final trackName = _trackController.text.trim();
    if (trackName.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _results = null;
    });

    try {
      final results = await _service.search(
        trackName: trackName,
        artistName: _artistController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final trackName = _trackController.text.trim();
    return AlertDialog(
      title: Text(context.l10n.searchLyricsDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _trackController,
              decoration: InputDecoration(
                labelText: context.l10n.trackNameLabel,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: context.l10n.artistNameLabel,
              ),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(context.l10n.searchLyrics),
              onPressed: (_isSearching || trackName.isEmpty) ? null : _search,
            ),
            const SizedBox(height: 12),
            if (_isSearching)
              const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) ...[
              Text(
                context.l10n.lyricsSearchError(_errorMessage!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _search,
                child: Text(context.l10n.retry),
              ),
            ],
            if (_results != null)
              Flexible(
                child: _results!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(context.l10n.noLyricsFound),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _results!.length,
                        itemBuilder: (context, index) {
                          final result = _results![index];
                          final hasLyrics = result.plainLyrics != null;
                          final duration = result.durationSeconds;
                          final subtitleParts = <String>[
                            result.artistName,
                            if (result.albumName != null) result.albumName!,
                            if (duration != null) _formatDuration(duration),
                          ];
                          return ListTile(
                            enabled: hasLyrics,
                            title: Text(result.trackName),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: hasLyrics
                                ? null
                                : Text(
                                    context.l10n.noLyricsAvailable,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                            onTap: hasLyrics
                                ? () => Navigator.of(
                                    context,
                                  ).pop(result.plainLyrics)
                                : null,
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
