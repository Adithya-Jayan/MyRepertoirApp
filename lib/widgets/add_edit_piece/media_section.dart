import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import '../detail_widgets/media_section.dart';

/// A widget that displays and manages media items for a music piece.
import 'package:repertoire/models/music_piece.dart'; // Add this import

class MediaSectionWidget extends StatelessWidget {
  final MusicPiece musicPiece; // New parameter
  final Function(MusicPiece) onMusicPieceChanged; // New parameter

  const MediaSectionWidget({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Separate regular media items and thumbnail items
    final regularItems = musicPiece.mediaItems.where((item) => item.type != MediaType.thumbnails).toList();
    final thumbnailItems = musicPiece.mediaItems.where((item) => item.type == MediaType.thumbnails).toList();

    void handleDelete(MediaItem deletedItem) {
      final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
      updatedMediaItems.removeWhere((element) => element.id == deletedItem.id);
      
      // Check if we need to clear the thumbnail
      String? newThumbnailPath = musicPiece.thumbnailPath;
      
      if (deletedItem.type == MediaType.image || deletedItem.type == MediaType.thumbnails) {
          if (musicPiece.thumbnailPath == deletedItem.pathOrUrl) {
            newThumbnailPath = null;
          }
      } else {
          if (deletedItem.thumbnailPath != null && musicPiece.thumbnailPath == deletedItem.thumbnailPath) {
            newThumbnailPath = null;
          }
      }
      
      onMusicPieceChanged(musicPiece.copyWith(
        mediaItems: updatedMediaItems,
        thumbnailPath: newThumbnailPath,
        clearThumbnail: newThumbnailPath == null,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        if (musicPiece.mediaItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Use the '+' sign to add media"),
            ),
          )
        else ...[
          if (regularItems.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regularItems.length,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final item = regularItems[index];
                // Find the index in the original list for updates
                final originalIndex = musicPiece.mediaItems.indexWhere((element) => element.id == item.id);

                return MediaSection(
                  key: ValueKey(item.id),
                  item: item,
                  index: index,
                  globalIndex: originalIndex,
                  musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                  musicPieceId: musicPiece.id,
                  onUpdateMediaItem: (updatedItem) {
                    final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                    if (originalIndex != -1) {
                      updatedMediaItems[originalIndex] = updatedItem;
                      onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
                    }
                  },
                  onDeleteMediaItem: handleDelete,
                  onSetThumbnail: (thumbnailPath) {
                    onMusicPieceChanged(musicPiece.copyWith(thumbnailPath: thumbnailPath));
                  },
                  musicPiece: musicPiece,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final newRegularItems = List<MediaItem>.from(regularItems);
                final item = newRegularItems.removeAt(oldIndex);
                newRegularItems.insert(newIndex, item);
                
                // Reconstruct the full list: newRegularItems + thumbnailItems
                // Note: This assumes thumbnails were at the end. If they were mixed, this forces them to end.
                // Which is desired behavior.
                final updatedMediaItems = [...newRegularItems, ...thumbnailItems];
                onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
              },
            ),
            
          if (thumbnailItems.isNotEmpty) ...[
             if (regularItems.isNotEmpty)
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8.0),
                 child: Divider(),
               ),
             const Padding(
               padding: EdgeInsets.only(bottom: 8.0),
               child: Text('Thumbnail Widget (Visible in Edit Mode only)', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey)),
             ),
             ...thumbnailItems.map((item) {
                final originalIndex = musicPiece.mediaItems.indexWhere((element) => element.id == item.id);
                return MediaSection(
                  key: ValueKey(item.id),
                  item: item,
                  index: -1, // Not used for reordering
                  globalIndex: originalIndex,
                  isReorderable: false,
                  musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                  musicPieceId: musicPiece.id,
                  onUpdateMediaItem: (updatedItem) {
                    final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                    if (originalIndex != -1) {
                      updatedMediaItems[originalIndex] = updatedItem;
                      onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
                    }
                  },
                  onDeleteMediaItem: handleDelete,
                  onSetThumbnail: (thumbnailPath) {
                    onMusicPieceChanged(musicPiece.copyWith(thumbnailPath: thumbnailPath));
                  },
                  musicPiece: musicPiece,
                );
             }),
          ],
        ],
      ],
    );
  }
} 