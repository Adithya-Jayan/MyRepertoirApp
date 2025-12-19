import 'package:flutter/material.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart'; // Added this import
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/services/thumbnail_service.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/models/learning_progress_config.dart'; // Added
import 'package:repertoire/widgets/add_edit_piece/learning_progress_config_dialog.dart'; // Added
import 'dart:io';

/// A widget for displaying and editing a single MediaItem.
///
/// Allows users to modify the media item's title, path/URL, and set it as a thumbnail.
class MediaSection extends StatefulWidget {
  final MediaItem item;
  final int index;
  final String musicPieceThumbnail;
  final String musicPieceId;
  final Function(MediaItem) onUpdateMediaItem;
  final Function(MediaItem) onDeleteMediaItem;
  final Function(String) onSetThumbnail;
  final MusicPiece musicPiece; // Added this

  const MediaSection({
    super.key,
    required this.item,
    required this.index,
    required this.musicPieceThumbnail,
    required this.musicPieceId,
    required this.onUpdateMediaItem,
    required this.onDeleteMediaItem,
    required this.onSetThumbnail,
    required this.musicPiece,
  });

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  bool _isLoadingThumbnail = false;
  String? _currentThumbnailPath;

  @override
  void initState() {
    super.initState();
    _currentThumbnailPath = widget.item.thumbnailPath;
  }

  @override
  void didUpdateWidget(MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      setState(() {
        _currentThumbnailPath = widget.item.thumbnailPath;
      });
    }
  }

  Future<void> _fetchThumbnail() async {
    if (widget.item.pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL first')),
      );
      return;
    }

    AppLogger.log('MediaSection: Starting thumbnail fetch for URL: ${widget.item.pathOrUrl}');
    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      await ThumbnailService.fetchAndSaveThumbnail(widget.item, widget.musicPieceId);
      final thumbnailPath = await ThumbnailService.getThumbnailPath(widget.item, widget.musicPieceId);
      
      AppLogger.log('MediaSection: Thumbnail fetch completed, path: $thumbnailPath');
      
      if (mounted) {
        setState(() {
          _currentThumbnailPath = thumbnailPath;
          _isLoadingThumbnail = false;
        });
        
        // Defensive: ensure we never alter the media link URL when setting a thumbnail
        final updatedItem = widget.item.copyWith(
          thumbnailPath: thumbnailPath,
          pathOrUrl: widget.item.pathOrUrl,
        );
        widget.onUpdateMediaItem(updatedItem);
        
        AppLogger.log('Thumbnail fetched for media item: ${widget.item.title}');
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail fetched successfully!')),
        );
      }
    } catch (e) {
      AppLogger.log('Error fetching thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch thumbnail: $e')),
        );
      }
    }
  }

  void _removeThumbnail() {
    AppLogger.log('MediaSection: _removeThumbnail called for item: ${widget.item.title}');
    AppLogger.log('MediaSection: Current thumbnail path: "$_currentThumbnailPath"');
    AppLogger.log('MediaSection: Piece thumbnail: "${widget.musicPieceThumbnail}"');
    
    // Delete the thumbnail file if it exists
    if (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) {
      try {
        final file = File(_currentThumbnailPath!);
        if (file.existsSync()) {
          file.deleteSync();
          AppLogger.log('MediaSection: Deleted thumbnail file: $_currentThumbnailPath');
        }
      } catch (e) {
        AppLogger.log('Error deleting thumbnail file: $e');
      }
    }

    // If this thumbnail was set as the piece thumbnail, clear it first
    if (widget.musicPieceThumbnail == _currentThumbnailPath) {
      widget.onSetThumbnail('');
      AppLogger.log('MediaSection: Cleared piece thumbnail');
    }

    // Update the media item to remove the thumbnail path
    final updatedItem = widget.item.copyWith(thumbnailPath: '');
    widget.onUpdateMediaItem(updatedItem);
    AppLogger.log('MediaSection: Updated media item with empty thumbnail path');

    // Update local state
    setState(() {
      _currentThumbnailPath = '';
    });
    AppLogger.log('MediaSection: Updated local state, _currentThumbnailPath is now: "$_currentThumbnailPath"');

    AppLogger.log('Thumbnail removed for media item: ${widget.item.title}');
  }

  void _deleteMediaItem() {
    // Determine the effective thumbnail path being used
    final effectiveThumbnailPath = widget.item.type == MediaType.image
        ? widget.item.pathOrUrl
        : _currentThumbnailPath;

    // If this media item (or its thumbnail) is set as the piece thumbnail, clear it
    if (effectiveThumbnailPath != null && 
        effectiveThumbnailPath.isNotEmpty && 
        widget.musicPieceThumbnail == effectiveThumbnailPath) {
      widget.onSetThumbnail('');
      AppLogger.log('MediaSection: Cleared piece thumbnail because source media was deleted');
    }

    // Delete the thumbnail file if it exists
    if (_currentThumbnailPath != null) {
      try {
        final file = File(_currentThumbnailPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        AppLogger.log('Error deleting thumbnail file: $e');
      }
    }

    // Call the parent's delete method
    widget.onDeleteMediaItem(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('MediaSection: build called for item: ${widget.item.title}, _currentThumbnailPath: "$_currentThumbnailPath"');
    return Card(
      key: ValueKey(widget.item.id),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MediaDisplayWidget(
                    musicPiece: widget.musicPiece,
                    mediaItemIndex: widget.index,
                    isEditable: true, // Allow title editing
                    onTitleChanged: (newTitle) {
                      widget.onUpdateMediaItem(widget.item.copyWith(title: newTitle));
                    },
                    onMediaItemChanged: (newItem) {
                      widget.onUpdateMediaItem(newItem);
                    },
                  ),
                  // Thumbnail controls
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      // Get/Remove thumbnail button (for media links)
                      if (widget.item.type == MediaType.mediaLink)
                        _isLoadingThumbnail
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Fetching...'),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty)
                                    ? () => _removeThumbnail()
                                    : () => _fetchThumbnail(),
                                icon: Icon((_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) ? Icons.delete : Icons.image),
                                label: Text((_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) ? 'Remove Thumbnail' : 'Get Thumbnail'),
                                style: (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty)
                                    ? ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        foregroundColor: Colors.red[700],
                                      )
                                    : null,
                              ),
                      // Set as thumbnail switch
                      if (widget.item.type == MediaType.image || widget.item.type == MediaType.thumbnails || (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Set as thumbnail'),
                            Switch(
                              value: widget.musicPieceThumbnail == ((widget.item.type == MediaType.image || widget.item.type == MediaType.thumbnails) ? widget.item.pathOrUrl : _currentThumbnailPath),
                              onChanged: (value) {
                                widget.onSetThumbnail(value ? ((widget.item.type == MediaType.image || widget.item.type == MediaType.thumbnails) ? widget.item.pathOrUrl : _currentThumbnailPath!) : '');
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Display appropriate input field based on media type
                  if (widget.item.type == MediaType.learningProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure Progress Bar'),
                        onPressed: () async {
                           final currentConfig = LearningProgressConfig.decode(widget.item.pathOrUrl);
                           final newConfig = await showDialog<LearningProgressConfig>(
                              context: context,
                              builder: (context) => LearningProgressConfigDialog(initialConfig: currentConfig),
                           );
                           if (newConfig != null) {
                              widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: LearningProgressConfig.encode(newConfig)));
                           }
                        },
                      ),
                    )
                  else if (widget.item.type == MediaType.markdown)
                    TextFormField(
                      initialValue: widget.item.pathOrUrl,
                      decoration: const InputDecoration(
                        labelText: 'Markdown Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      onChanged: (value) => widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: value)),
                    )
                  else
                    TextFormField(
                      initialValue: widget.item.pathOrUrl,
                      decoration: const InputDecoration(labelText: 'Path or URL'),
                      onChanged: (value) => widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: value)),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle), // Drag handle for reordering.
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete), // Button to delete the media item.
                  onPressed: () => _deleteMediaItem(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}