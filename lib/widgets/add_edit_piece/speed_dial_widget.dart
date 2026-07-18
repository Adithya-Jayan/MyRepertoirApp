import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/media_type.dart';
import 'package:repertoire/l10n/l10n.dart';

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
    final List<SpeedDialChild> dialChildren = [
      SpeedDialChild(
        child: const Icon(Icons.photo_size_select_actual),
        label: context.l10n.thumbnail,
        onTap: hasThumbnail ? null : () => onAddMediaItem(MediaType.thumbnails),
        backgroundColor: hasThumbnail ? Colors.grey : null,
        labelStyle: hasThumbnail ? const TextStyle(color: Colors.grey) : null,
      ),
      SpeedDialChild(
        child: const Icon(Icons.text_fields),
        label: context.l10n.markdownText,
        onTap: () => onAddMediaItem(MediaType.markdown),
      ),
      SpeedDialChild(
        child: const Icon(Icons.picture_as_pdf),
        label: context.l10n.pdf,
        onTap: () => onAddMediaItem(MediaType.pdf),
      ),
      SpeedDialChild(
        child: const Icon(Icons.image),
        label: context.l10n.image,
        onTap: () => onAddMediaItem(MediaType.image),
      ),
      SpeedDialChild(
        child: const Icon(Icons.audiotrack),
        label: context.l10n.audioMidi,
        onTap: () => onAddMediaItem(
          MediaType.audio,
        ), // Default to audio, picker will handle both
      ),
      SpeedDialChild(
        child: const Icon(Icons.video_library),
        label: context.l10n.link,
        onTap: () => onAddMediaItem(MediaType.mediaLink),
      ),
      SpeedDialChild(
        child: const Icon(Icons.movie_creation),
        label: context.l10n.localVideo,
        onTap: () => onAddMediaItem(MediaType.localVideo),
      ),
      SpeedDialChild(
        child: const Icon(Icons.bar_chart),
        label: context.l10n.learningProgress,
        onTap: () => onAddMediaItem(MediaType.learningProgress),
      ),
    ];

    // Sort children alphabetically by label
    dialChildren.sort((a, b) => (a.label ?? '').compareTo(b.label ?? ''));

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: dialChildren,
    );
  }
}
