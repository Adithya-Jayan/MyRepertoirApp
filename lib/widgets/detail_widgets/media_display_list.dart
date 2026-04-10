import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/media_type.dart';

/// A widget that displays a reorderable list of media items associated with a music piece.
///
/// It allows reordering of media items and persists the new order to the database.
class MediaDisplayList extends StatefulWidget {
  final MusicPiece musicPiece;
  final Function(MusicPiece) onMusicPieceChanged;
  final bool allowReordering;

  const MediaDisplayList({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
    this.allowReordering = false,
  });

  @override
  State<MediaDisplayList> createState() => _MediaDisplayListState();
}

class _MediaDisplayListState extends State<MediaDisplayList> {
  late MusicPiece _musicPiece;
  final MusicPieceRepository _repository = MusicPieceRepository();

  @override
  void initState() {
    super.initState();
    _musicPiece = widget.musicPiece;
  }

  @override
  void didUpdateWidget(MediaDisplayList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicPiece != widget.musicPiece) {
      setState(() {
        _musicPiece = widget.musicPiece;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out thumbnails for the display list in view mode
    final visibleItemsIndices = _musicPiece.mediaItems
        .asMap()
        .entries
        .where((e) => e.value.type != MediaType.thumbnails)
        .map((e) => e.key)
        .toList();

    if (visibleItemsIndices.isEmpty) {
      return const SizedBox.shrink(); // Hide the entire widget if no visible media items
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.allowReordering
            ? ReorderableListView.builder(
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItemsIndices.length,
                itemBuilder: (context, index) {
                  final mediaIndex = visibleItemsIndices[index];
                  final item = _musicPiece.mediaItems[mediaIndex];
                  return Column( // Wrap in Column to add Divider below
                    key: ValueKey(item.id),
                    children: [
                      MediaDisplayWidget(
                        musicPiece: _musicPiece,
                        mediaItemIndex: mediaIndex,
                        isEditable: false,
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        onMediaItemChanged: (newItem) {
                          setState(() {
                            _musicPiece.mediaItems[mediaIndex] = newItem;
                          });
                          _repository.updateMusicPiece(_musicPiece);
                          widget.onMusicPieceChanged(_musicPiece);
                        },
                      ),
                      if (index < visibleItemsIndices.length - 1) // Add Divider if not the last visible item
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    
                    // Map visual indices back to original indices
                    final originalOldIndex = visibleItemsIndices[oldIndex];
                    final originalNewIndex = visibleItemsIndices[newIndex];
                    
                    final item = _musicPiece.mediaItems.removeAt(originalOldIndex);
                    _musicPiece.mediaItems.insert(originalNewIndex, item);
                    
                    _repository.updateMusicPiece(_musicPiece);
                    widget.onMusicPieceChanged(_musicPiece);
                  });
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItemsIndices.length,
                itemBuilder: (context, index) {
                  final mediaIndex = visibleItemsIndices[index];
                  final item = _musicPiece.mediaItems[mediaIndex];
                  return Column( // Wrap in Column to add Divider below
                    key: ValueKey(item.id),
                    children: [
                      MediaDisplayWidget(
                        musicPiece: _musicPiece,
                        mediaItemIndex: mediaIndex,
                        isEditable: false,
                        onMediaItemChanged: (newItem) {
                          setState(() {
                            _musicPiece.mediaItems[mediaIndex] = newItem;
                          });
                          _repository.updateMusicPiece(_musicPiece);
                          widget.onMusicPieceChanged(_musicPiece);
                        },
                      ),
                      if (index < visibleItemsIndices.length - 1) // Add Divider if not the last visible item
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  );
                },
              ),
      ],
    );
  }
}
