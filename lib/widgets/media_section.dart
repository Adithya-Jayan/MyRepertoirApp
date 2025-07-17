import 'package:flutter/material.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/widgets/media_display_widget.dart';

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
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
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
