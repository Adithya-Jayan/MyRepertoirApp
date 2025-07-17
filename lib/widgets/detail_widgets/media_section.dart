import 'package:flutter/material.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/widgets/media_display_widget.dart';

/// A widget for displaying and editing a single MediaItem.
///
/// Allows users to modify the media item's title, path/URL, and set it as a thumbnail.
class MediaSection extends StatelessWidget {
  final MediaItem item;
  final int index;
  final String musicPieceThumbnail;
  final Function(MediaItem) onUpdateMediaItem;
  final Function(MediaItem) onDeleteMediaItem;
  final Function(String) onSetThumbnail;

  const MediaSection({
    super.key,
    required this.item,
    required this.index,
    required this.musicPieceThumbnail,
    required this.onUpdateMediaItem,
    required this.onDeleteMediaItem,
    required this.onSetThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(item.id),
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
                    mediaItem: item,
                    onTitleChanged: (newTitle) {
                      onUpdateMediaItem(item.copyWith(title: newTitle));
                    },
                    isEditable: true,
                  ),
                  // Display thumbnail switch only for images or media links with thumbnails
                  if (item.type == MediaType.image || (item.type == MediaType.mediaLink && item.thumbnailPath != null))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Set as thumbnail'),
                        Switch(
                          value: musicPieceThumbnail == (item.type == MediaType.image ? item.pathOrUrl : item.thumbnailPath),
                          onChanged: (value) {
                            onSetThumbnail(value ? (item.type == MediaType.image ? item.pathOrUrl : item.thumbnailPath!) : '');
                          },
                        ),
                      ],
                    ),
                  // Display appropriate input field based on media type
                  if (item.type == MediaType.markdown)
                    TextFormField(
                      initialValue: item.pathOrUrl,
                      decoration: const InputDecoration(
                        labelText: 'Markdown Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      onChanged: (value) => onUpdateMediaItem(item.copyWith(pathOrUrl: value)),
                    )
                  else
                    TextFormField(
                      initialValue: item.pathOrUrl,
                      decoration: const InputDecoration(labelText: 'Path or URL'),
                      onChanged: (value) => onUpdateMediaItem(item.copyWith(pathOrUrl: value)),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle), // Drag handle for reordering.
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete), // Button to delete the media item.
                  onPressed: () => onDeleteMediaItem(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}