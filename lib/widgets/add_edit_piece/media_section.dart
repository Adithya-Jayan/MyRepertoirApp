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
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: musicPiece.mediaItems.length,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final item = musicPiece.mediaItems[index];
              return MediaSection(
                key: ValueKey(item.id),
                item: item,
                index: index,
                musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                musicPieceId: musicPiece.id,
                onUpdateMediaItem: (updatedItem) {
                  final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                  updatedMediaItems[index] = updatedItem;
                  onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
                },
                onDeleteMediaItem: (deletedItem) {
                  final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                  updatedMediaItems.removeWhere((element) => element.id == deletedItem.id);
                  
                  // Check if we need to clear the thumbnail
                  String? newThumbnailPath = musicPiece.thumbnailPath;
                  
                  if (deletedItem.type == MediaType.image) {
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
                  ));
                },
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
              final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
              final item = updatedMediaItems.removeAt(oldIndex);
              updatedMediaItems.insert(newIndex, item);
              onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
            },
          ),
      ],
    );
  }
} 