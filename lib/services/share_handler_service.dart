import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/media_storage_manager.dart';
import '../utils/app_logger.dart';

class ShareHandlerService {
  StreamSubscription? _intentDataStreamSubscription;
  final MusicPieceRepository _repository = MusicPieceRepository();

  void init(GlobalKey<NavigatorState> navigatorKey) {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(navigatorKey, value);
      }
    }, onError: (err) {
      AppLogger.log("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app when the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(navigatorKey, value);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }

  Future<void> _handleSharedFiles(GlobalKey<NavigatorState> navigatorKey, List<SharedMediaFile> files) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (files.isEmpty) return;

    // Filter out items that are essentially empty (sometimes happens with text shares)
    final validFiles = files.where((f) => f.path.isNotEmpty || (f.type == SharedMediaType.text || f.type == SharedMediaType.url)).toList();

    if (validFiles.isEmpty) return;

    // Show dialog to select music piece
    final MusicPiece? selectedPiece = await _showMusicPieceSelectionDialog(navigatorKey);
    if (selectedPiece == null) return;

    bool anySuccess = false;
    MusicPiece currentPiece = selectedPiece; // Keep track of updates

    // Re-fetch piece to ensure we have latest version (especially if coming from background)
    final freshPiece = await _repository.getMusicPieceById(selectedPiece.id);
    if (freshPiece != null) {
      currentPiece = freshPiece;
    }

    // Refresh context check
    if (navigatorKey.currentContext == null || !navigatorKey.currentContext!.mounted) return;
    final mountedContext = navigatorKey.currentContext!;

    for (var file in validFiles) {
      try {
        final MediaType? type = _mapSharedTypeToMediaType(file);
        if (type == null) continue;

        String pathOrUrl = file.path;
        
        // Handling for Text/URL
        if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
           // file.path contains the text/url
           pathOrUrl = file.path;
           // Basic heuristic
           if (pathOrUrl.startsWith('http')) {
             // likely URL
           } 
        } else {
           // It's a file, we need to copy it
           pathOrUrl = await MediaStorageManager.copyMediaToLocal(
              file.path, 
              currentPiece.id, 
              type
            );
        }

        final newMediaItem = MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: pathOrUrl,
          title: file.type == SharedMediaType.text || file.type == SharedMediaType.url ? 'Shared Link/Text' : null, 
        );

        final updatedMediaItems = List<MediaItem>.from(currentPiece.mediaItems)..add(newMediaItem);
        currentPiece = currentPiece.copyWith(mediaItems: updatedMediaItems);
        anySuccess = true;
      } catch (e) {
        AppLogger.log('Error processing shared file: $e');
        if (mountedContext.mounted) {
           ScaffoldMessenger.of(mountedContext).showSnackBar(SnackBar(content: Text('Error adding media: $e')));
        }
      }
    }

    if (anySuccess) {
      await _repository.updateMusicPiece(currentPiece);
      if (mountedContext.mounted) {
        ScaffoldMessenger.of(mountedContext).showSnackBar(SnackBar(content: Text('Media added to "${currentPiece.title}"')));
      }
    }
  }

  MediaType? _mapSharedTypeToMediaType(SharedMediaFile file) {
    switch (file.type) {
      case SharedMediaType.image:
        return MediaType.image;
      case SharedMediaType.video:
        return MediaType.localVideo;
      case SharedMediaType.file:
        if (file.path.toLowerCase().endsWith('.pdf')) return MediaType.pdf;
        if (file.path.toLowerCase().endsWith('.md')) return MediaType.markdown;
        if (file.path.toLowerCase().endsWith('.txt')) return MediaType.markdown;
        return null; 
      case SharedMediaType.text:
         if (Uri.tryParse(file.path)?.hasAbsolutePath ?? false) {
            return MediaType.mediaLink;
         }
         return MediaType.markdown;
      case SharedMediaType.url:
         return MediaType.mediaLink;
    }
  }

  Future<MusicPiece?> _showMusicPieceSelectionDialog(GlobalKey<NavigatorState> navigatorKey) async {
    final pieces = await _repository.getMusicPieces();
    pieces.sort((a, b) => a.title.compareTo(b.title));

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return null;

    return showDialog<MusicPiece>(
      context: context,
      builder: (BuildContext context) {
        return _MusicPieceSelectionDialog(pieces: pieces);
      },
    );
  }
}

class _MusicPieceSelectionDialog extends StatefulWidget {
  final List<MusicPiece> pieces;

  const _MusicPieceSelectionDialog({required this.pieces});

  @override
  State<_MusicPieceSelectionDialog> createState() => _MusicPieceSelectionDialogState();
}

class _MusicPieceSelectionDialogState extends State<_MusicPieceSelectionDialog> {
  List<MusicPiece> _filteredPieces = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPieces = widget.pieces;
  }

  void _filterPieces(String query) {
    setState(() {
      _filteredPieces = widget.pieces
          .where((piece) => piece.title.toLowerCase().contains(query.toLowerCase()) || 
                            piece.artistComposer.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Repertoire'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Piece',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterPieces,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _filteredPieces.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No pieces found.'),
                )
              : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredPieces.length,
                itemBuilder: (context, index) {
                  final piece = _filteredPieces[index];
                  return ListTile(
                    title: Text(piece.title),
                    subtitle: Text(piece.artistComposer),
                    onTap: () {
                      Navigator.of(context).pop(piece);
                    },
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
