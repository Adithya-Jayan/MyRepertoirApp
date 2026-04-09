import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../database/music_piece_repository.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/media_storage_manager.dart';
import '../utils/app_logger.dart';

class ShareHandlerService {
  StreamSubscription? _intentDataStreamSubscription;
  final MusicPieceRepository _repository = MusicPieceRepository();
  bool _isHandling = false;

  // Static notifier to signal data changes to other parts of the app (e.g., LibraryScreen)
  static final ValueNotifier<bool> dataChangeNotifier = ValueNotifier(false);

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
    if (_isHandling) {
      AppLogger.log('ShareHandlerService: Already handling a share intent. Skipping.');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      // If context is null, the app might still be initializing. 
      // We wait a bit and try again, but only for initial media which might trigger very early.
      AppLogger.log('ShareHandlerService: Navigator context is null. Retrying in 1 second...');
      await Future.delayed(const Duration(seconds: 1));
      if (navigatorKey.currentContext == null) return;
    }

    _isHandling = true;
    try {
      if (files.isEmpty) return;

      // Filter out items that are essentially empty (sometimes happens with text shares)
      final validFiles = files.where((f) => f.path.isNotEmpty || (f.type == SharedMediaType.text || f.type == SharedMediaType.url)).toList();

      if (validFiles.isEmpty) return;

      // Show dialog to select music piece or create new
      final dynamic selectionResult = await _showMusicPieceSelectionDialog(navigatorKey);
      if (selectionResult == null) return;

      bool anySuccess = false;
      MusicPiece? currentPiece;

      if (selectionResult is MusicPiece) {
        // Adding to existing piece
        // Re-fetch piece to ensure we have latest version
        currentPiece = await _repository.getMusicPieceById(selectionResult.id);
        if (currentPiece == null) {
          _showError(navigatorKey, 'Selected piece no longer exists.');
          return;
        }
      } else if (selectionResult == 'create_new') {
        // Creating a new piece
        final String? newTitle = await _showNewPieceTitleDialog(navigatorKey);
        if (newTitle == null || newTitle.trim().isEmpty) return;

        currentPiece = MusicPiece(
          id: const Uuid().v4(),
          title: newTitle.trim(),
          artistComposer: 'Unknown Artist',
          lastAccessed: DateTime.now(),
        );
      }

      if (currentPiece == null) return;

      // Refresh context check
      if (navigatorKey.currentContext == null || !navigatorKey.currentContext!.mounted) return;
      final mountedContext = navigatorKey.currentContext!;

      List<MediaItem> newItems = [];

      for (var file in validFiles) {
        try {
          final MediaType? type = _mapSharedTypeToMediaType(file);
          if (type == null) {
             AppLogger.log('ShareHandlerService: Unsupported shared file type: ${file.type} for path: ${file.path}');
             continue;
          }

          String pathOrUrl = file.path;
          
          // Handling for Text/URL
          if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
             pathOrUrl = file.path;
          } else if (type == MediaType.markdown) {
             // For markdown files, we read the content instead of copying the file
             try {
               final fileObj = File(file.path);
               if (await fileObj.exists()) {
                 pathOrUrl = await fileObj.readAsString();
               }
             } catch (e) {
               AppLogger.log('Error reading markdown file: $e');
               // Fallback to path if reading fails (though widget might not show it)
               pathOrUrl = file.path;
             }
          } else {
             // It's a binary file, we need to copy it
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
            title: (file.type == SharedMediaType.text || file.type == SharedMediaType.url) 
                ? 'Shared Link/Text' 
                : (file.path.isNotEmpty ? path.basename(file.path) : 'Shared Media'), 
          );

          newItems.add(newMediaItem);
          anySuccess = true;
        } catch (e) {
          AppLogger.log('Error processing shared file: $e');
          _showError(navigatorKey, 'Error adding media: $e');
        }
      }

      if (anySuccess) {
        final updatedMediaItems = List<MediaItem>.from(currentPiece.mediaItems)..addAll(newItems);
        currentPiece = currentPiece.copyWith(mediaItems: updatedMediaItems);

        if (selectionResult == 'create_new') {
          await _repository.insertMusicPiece(currentPiece);
        } else {
          await _repository.updateMusicPiece(currentPiece);
        }
        
        // Notify listeners (like LibraryScreen) that data has changed
        dataChangeNotifier.value = !dataChangeNotifier.value;
        
        if (mountedContext.mounted) {
          ScaffoldMessenger.of(mountedContext).showSnackBar(
            SnackBar(content: Text(selectionResult == 'create_new' 
              ? 'New piece "${currentPiece.title}" created with shared media'
              : 'Media added to "${currentPiece.title}"'))
          );
        }
      }
    } finally {
      _isHandling = false;
    }
  }

  void _showError(GlobalKey<NavigatorState> navigatorKey, String message) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  MediaType? _mapSharedTypeToMediaType(SharedMediaFile file) {
    switch (file.type) {
      case SharedMediaType.image:
        return MediaType.image;
      case SharedMediaType.video:
        return MediaType.localVideo;
      case SharedMediaType.file:
        final ext = path.extension(file.path).toLowerCase();
        if (ext == '.pdf') return MediaType.pdf;
        if (ext == '.md' || ext == '.txt') return MediaType.markdown;
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

  Future<dynamic> _showMusicPieceSelectionDialog(GlobalKey<NavigatorState> navigatorKey) async {
    final pieces = await _repository.getMusicPieces();
    pieces.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return null;

    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return _MusicPieceSelectionDialog(pieces: pieces);
      },
    );
  }

  Future<String?> _showNewPieceTitleDialog(GlobalKey<NavigatorState> navigatorKey) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return null;

    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Piece Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter title for the new piece'),
          autofocus: true,
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
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
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.blue),
              title: const Text('Create New Piece', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop('create_new');
              },
            ),
            const Divider(),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Existing Piece',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterPieces,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _filteredPieces.isEmpty && _searchController.text.isNotEmpty
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
