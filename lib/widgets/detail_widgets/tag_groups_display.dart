import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/utils/color_utils.dart';

class TagGroupsDisplay extends StatelessWidget {
  final MusicPiece musicPiece;
  final bool showTitle;

  const TagGroupsDisplay({
    super.key, 
    required this.musicPiece,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Brightness brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Tags & Categories',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
        ],
        ...musicPiece.tagGroups.map((tagGroup) {
          final color = tagGroup.color != null ? Color(tagGroup.color!) : null;
          final tagGroupColor = color != null 
              ? adjustColorForBrightness(color, brightness) 
              : colorScheme.primaryContainer;
          
          final onTagGroupColor = ThemeData.estimateBrightnessForColor(tagGroupColor) == Brightness.light
              ? Colors.black87
              : Colors.white;

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: tagGroupColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    tagGroup.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onTagGroupColor,
                    ),
                  ),
                ),
                ...tagGroup.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
