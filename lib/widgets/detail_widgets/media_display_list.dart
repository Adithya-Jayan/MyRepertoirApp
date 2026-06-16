import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/widgets/detail_widgets/collapsible_section.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:repertoire/models/media_item.dart';

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

  Future<void> _shareMediaItem(MediaItem item, Rect? shareOrigin) async {
    try {
      ShareParams? params;
      switch (item.type) {
        case MediaType.mediaLink:
        case MediaType.markdown:
          params = ShareParams(text: item.pathOrUrl, sharePositionOrigin: shareOrigin);
          break;
        case MediaType.audio:
        case MediaType.image:
        case MediaType.pdf:
        case MediaType.localVideo:
        case MediaType.midi:
          if (kIsWeb) {
             params = ShareParams(text: item.pathOrUrl, sharePositionOrigin: shareOrigin);
          } else {
            final file = io.File(item.pathOrUrl);
            if (await file.exists()) {
              params = ShareParams(files: [XFile(item.pathOrUrl)], sharePositionOrigin: shareOrigin);
            } else {
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found to share.')));
               }
               return;
            }
          }
          break;
        default: return;
      }
      await SharePlus.instance.share(params);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
    }
  }

  Widget _buildPieceActions(MediaItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) async {
        if (value == 'share') {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
          await _shareMediaItem(item, rect);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share_outlined, size: 20),
            title: Text('Share'),
            dense: true,
          ),
        ),
      ],
    );
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

    return widget.allowReordering
        ? ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleItemsIndices.length,
            itemBuilder: (context, index) {
              final mediaIndex = visibleItemsIndices[index];
              final item = _musicPiece.mediaItems[mediaIndex];
              return CollapsibleSection(
                key: ValueKey(item.id),
                title: item.title ?? item.type.name,
                persistenceKey: 'media_item_${item.id}',
                trailing: _buildPieceActions(item),
                child: MediaDisplayWidget(
                  musicPiece: _musicPiece,
                  mediaItemIndex: mediaIndex,
                  isEditable: false,
                  showTitle: false,
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
        : Column(
            children: visibleItemsIndices.map((index) {
              final mediaIndex = index;
              final item = _musicPiece.mediaItems[mediaIndex];
              return CollapsibleSection(
                key: ValueKey(item.id),
                title: item.title ?? item.type.name,
                persistenceKey: 'media_item_${item.id}',
                trailing: _buildPieceActions(item),
                child: MediaDisplayWidget(
                  musicPiece: _musicPiece,
                  mediaItemIndex: mediaIndex,
                  isEditable: false,
                  showTitle: false,
                  onMediaItemChanged: (newItem) {
                    setState(() {
                      _musicPiece.mediaItems[mediaIndex] = newItem;
                    });
                    _repository.updateMusicPiece(_musicPiece);
                    widget.onMusicPieceChanged(_musicPiece);
                  },
                ),
              );
            }).toList(),
          );
  }
}
