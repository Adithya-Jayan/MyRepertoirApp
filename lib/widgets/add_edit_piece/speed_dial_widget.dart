import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/media_type.dart';

/// A widget that displays a speed dial for adding different types of media items.
class SpeedDialWidget extends StatelessWidget {
  final Function(MediaType) onAddMediaItem;

  const SpeedDialWidget({
    super.key,
    required this.onAddMediaItem,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
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
          child: const Icon(Icons.bar_chart),
          label: 'Learning Progress',
          onTap: () => onAddMediaItem(MediaType.learningProgress),
        ),
      ],
    );
  }
} 