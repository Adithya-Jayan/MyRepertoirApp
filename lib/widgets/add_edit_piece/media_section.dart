import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import '../detail_widgets/media_section.dart';

/// A widget that displays and manages media items for a music piece.
class MediaSectionWidget extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final String musicPieceThumbnail;
  final String musicPieceId;
  final Function(MediaItem) onUpdateMediaItem;
  final Function(MediaItem) onDeleteMediaItem;
  final Function(String) onSetThumbnail;
  final Function(int, int) onReorderMediaItems;

  const MediaSectionWidget({
    super.key,
    required this.mediaItems,
    required this.musicPieceThumbnail,
    required this.musicPieceId,
    required this.onUpdateMediaItem,
    required this.onDeleteMediaItem,
    required this.onSetThumbnail,
    required this.onReorderMediaItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mediaItems.length,
          buildDefaultDragHandles: false,
          itemBuilder: (context, index) {
            final item = mediaItems[index];
            return MediaSection(
              key: ValueKey(item.id),
              item: item,
              index: index,
              musicPieceThumbnail: musicPieceThumbnail,
              musicPieceId: musicPieceId,
              onUpdateMediaItem: onUpdateMediaItem,
              onDeleteMediaItem: onDeleteMediaItem,
              onSetThumbnail: onSetThumbnail,
            );
          },
          onReorder: onReorderMediaItems,
        ),
      ],
    );
  }
} 