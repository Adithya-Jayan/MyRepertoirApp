import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/media_type.dart';

/// A widget that displays a speed dial for adding different types of media items.
class SpeedDialWidget extends StatelessWidget {
  final Function(MediaType) onAddMediaItem;
  final bool hasThumbnail;

  const SpeedDialWidget({
    super.key,
    required this.onAddMediaItem,
    this.hasThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.photo_size_select_actual),
          label: 'Thumbnail',
          onTap: hasThumbnail ? null : () => onAddMediaItem(MediaType.thumbnails),
          backgroundColor: hasThumbnail ? Colors.grey : null,
          labelStyle: hasThumbnail ? const TextStyle(color: Colors.grey) : null,
        ),
        SpeedDialChild(
          child: const Icon(Icons.text_fields),
          label: 'Markdown Text',
          onTap: () => onAddMediaItem(MediaType.markdown),
        ),
        SpeedDialChild(
          child: const Icon(Icons.picture_as_pdf),
          label: 'PDF',
          onTap: () => onAddMediaItem(MediaType.pdf),
        ),
        SpeedDialChild(
          child: const Icon(Icons.image),
          label: 'Image',
          onTap: () => onAddMediaItem(MediaType.image),
        ),
        SpeedDialChild(
          child: const Icon(Icons.audiotrack),
          label: 'Audio',
          onTap: () => onAddMediaItem(MediaType.audio),
        ),
        SpeedDialChild(
          child: const Icon(Icons.video_library),
          label: 'Link',
          onTap: () => onAddMediaItem(MediaType.mediaLink),
        ),
        SpeedDialChild(
          child: const Icon(Icons.movie_creation),
          label: 'Local Video',
          onTap: () => onAddMediaItem(MediaType.localVideo),
        ),
        SpeedDialChild(
          child: const Icon(Icons.bar_chart),
          label: 'Learning Progress',
          onTap: () => onAddMediaItem(MediaType.learningProgress),
        ),
      ],
    );
  }
} 