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
          final color = tagGroup.color != null ? Color(tagGroup.color!) : null;
          final backgroundColor = color != null 
              ? adjustColorForBrightness(color, brightness) 
              : Theme.of(context).colorScheme.primaryContainer;
          
          // Determine text color based on background brightness for readability
          final textColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
              ? Colors.black
              : Colors.white;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    tagGroup.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0), // Align text vertically with the label
                    child: Text(
                      tagGroup.tags.join(', '),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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