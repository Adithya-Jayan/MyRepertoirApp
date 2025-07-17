import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/utils/color_utils.dart';

class TagGroupsDisplay extends StatelessWidget {
  final MusicPiece musicPiece;

  const TagGroupsDisplay({super.key, required this.musicPiece});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tag Groups:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        ...musicPiece.tagGroups.map((tagGroup) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tagGroup.name}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tagGroup.tags.map((tag) {
                      final color = tagGroup.color != null ? Color(tagGroup.color!) : null;
                      return Chip(
                        label: Text(tag),
                        backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
