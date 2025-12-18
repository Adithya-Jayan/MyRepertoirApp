import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/database/music_piece_repository.dart';

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
    if (_musicPiece.mediaItems.isEmpty) {
      return const SizedBox.shrink(); // Hide the entire widget if no media items
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media title removed
        // Divider below title removed
        widget.allowReordering
            ? ReorderableListView.builder(
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _musicPiece.mediaItems.length,
                itemBuilder: (context, index) {
                  final item = _musicPiece.mediaItems[index];
                  return Column( // Wrap in Column to add Divider below
                    key: ValueKey(item.id),
                    children: [
                      MediaDisplayWidget(
                        musicPiece: _musicPiece,
                        mediaItemIndex: index,
                        isEditable: false,
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        onMediaItemChanged: (newItem) {
                          setState(() {
                            _musicPiece.mediaItems[index] = newItem;
                          });
                          _repository.updateMusicPiece(_musicPiece);
                          widget.onMusicPieceChanged(_musicPiece);
                        },
                      ),
                      if (index < _musicPiece.mediaItems.length - 1) // Add Divider if not the last item
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _musicPiece.mediaItems.removeAt(oldIndex);
                    _musicPiece.mediaItems.insert(newIndex, item);
                    _repository.updateMusicPiece(_musicPiece);
                    widget.onMusicPieceChanged(_musicPiece);
                  });
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _musicPiece.mediaItems.length,
                itemBuilder: (context, index) {
                  final item = _musicPiece.mediaItems[index];
                  return Column( // Wrap in Column to add Divider below
                    key: ValueKey(item.id),
                    children: [
                      MediaDisplayWidget(
                        musicPiece: _musicPiece,
                        mediaItemIndex: index,
                        isEditable: false,
                        onMediaItemChanged: (newItem) {
                          setState(() {
                            _musicPiece.mediaItems[index] = newItem;
                          });
                          _repository.updateMusicPiece(_musicPiece);
                          widget.onMusicPieceChanged(_musicPiece);
                        },
                      ),
                      if (index < _musicPiece.mediaItems.length - 1) // Add Divider if not the last item
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  );
                },
              ),
      ],
    );
  }
}