import 'dart:io';

import 'package:flutter/material.dart';
import 'package:repertoire/utils/color_utils.dart';
import '../models/music_piece.dart';

class MusicPieceCard extends StatelessWidget {
  final MusicPiece piece;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MusicPieceCard({
    super.key,
    required this.piece,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            if (piece.thumbnailPath != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(piece.thumbnailPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        piece.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        piece.artistComposer,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        if (piece.tagGroups.isNotEmpty)
                          ...piece.tagGroups.expand((tg) => tg.tags.map((tag) {
                            final color = tg.color != null ? Color(tg.color!) : null;
                            return Chip(
                              label: FittedBox(fit: BoxFit.scaleDown, child: Text(tag)),
                              backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
                            );
                          })),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (piece.lastPracticeTime != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Last practiced: ${piece.lastPracticeTime!.toLocal().toString().split('.')[0]}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (piece.practiceCount > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Practice count: ${piece.practiceCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}