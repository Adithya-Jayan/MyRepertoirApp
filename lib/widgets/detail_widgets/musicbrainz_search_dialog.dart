import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:repertoire/l10n/l10n.dart';
import 'package:repertoire/services/musicbrainz_service.dart';

/// Result of picking a MusicBrainz search result: the release's title and
/// artist, plus its cover art bytes (null if this release has no cover art
/// in the Cover Art Archive).
class MusicBrainzPickResult {
  final String title;
  final String artist;
  final Uint8List? coverArtBytes;

  MusicBrainzPickResult({
    required this.title,
    required this.artist,
    this.coverArtBytes,
  });
}

/// A dialog that searches MusicBrainz for a release and, on selection,
/// fetches that release's cover art from the Cover Art Archive.
///
/// Pops with a [MusicBrainzPickResult], or `null` if dismissed without a
/// selection.
class MusicBrainzSearchDialog extends StatefulWidget {
  final String initialTitle;
  final String initialArtist;
  final MusicBrainzService? service;

  const MusicBrainzSearchDialog({
    super.key,
    required this.initialTitle,
    required this.initialArtist,
    this.service,
  });

  @override
  State<MusicBrainzSearchDialog> createState() =>
      _MusicBrainzSearchDialogState();
}

class _MusicBrainzSearchDialogState extends State<MusicBrainzSearchDialog> {
  late final MusicBrainzService _service;
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;

  bool _isSearching = false;
  String? _errorMessage;
  VoidCallback? _retryAction;
  List<MusicBrainzResult>? _results;
  String? _fetchingMbid;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MusicBrainzService();
    _titleController = TextEditingController(text: widget.initialTitle);
    _artistController = TextEditingController(text: widget.initialArtist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _fetchingMbid != null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _retryAction = null;
      _results = null;
    });

    try {
      final results = await _service.search(
        title: title,
        artist: _artistController.text.trim(),
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
        _retryAction = _search;
      });
    }
  }

  Future<void> _pick(MusicBrainzResult result) async {
    setState(() {
      _fetchingMbid = result.mbid;
      _errorMessage = null;
      _retryAction = null;
    });

    try {
      final coverArtBytes = await _service.fetchCoverArtBytes(result.mbid);
      if (!mounted) return;
      Navigator.of(context).pop(
        MusicBrainzPickResult(
          title: result.title,
          artist: result.artist,
          coverArtBytes: coverArtBytes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchingMbid = null;
        _errorMessage = e.toString();
        _retryAction = () => _pick(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleController.text.trim();
    return AlertDialog(
      title: Text(context.l10n.searchMusicBrainzDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: context.l10n.title),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: context.l10n.artistComposer,
              ),
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(context.l10n.searchMusicBrainz),
              onPressed: (_isSearching || _fetchingMbid != null || title.isEmpty) ? null : _search,
            ),
            const SizedBox(height: 12),
            if (_isSearching) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) ...[
              Text(
                context.l10n.musicBrainzSearchError(_errorMessage!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _retryAction,
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
                          final isFetching = _fetchingMbid == result.mbid;
                          final subtitleParts = <String>[
                            result.artist,
                            if (result.date != null) result.date!,
                          ];
                          return ListTile(
                            enabled: _fetchingMbid == null,
                            title: Text(result.title),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: isFetching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                            onTap: _fetchingMbid == null
                                ? () => _pick(result)
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
