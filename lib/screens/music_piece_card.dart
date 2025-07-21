import 'dart:io';

import 'package:flutter/material.dart';
import 'package:repertoire/utils/color_utils.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/utils/practice_indicator_utils.dart';
import '../models/music_piece.dart';

/// A widget that displays a single music piece as a card in a grid or list.
///
/// It shows the title, artist/composer, tags, and practice information.
/// It also supports selection state and tap/long press interactions.
class MusicPieceCard extends StatelessWidget {
  final MusicPiece piece; // The music piece data to display.
  final bool isSelected; // Whether the card is currently selected.
  final VoidCallback? onTap; // Callback function when the card is tapped.
  final VoidCallback? onLongPress; // Callback function when the card is long-pressed.

  const MusicPieceCard({
    super.key,
    required this.piece,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness; // Get current theme brightness.
    final colorScheme = Theme.of(context).colorScheme; // Get current color scheme.

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2) // Highlight border if selected.
              : BorderSide.none,
        ),
        color: isSelected ? colorScheme.primary.withAlpha(26) : null, // Apply a subtle background color if selected.
        child: InkWell(
          onTap: onTap, // Handle tap events.
          onLongPress: onLongPress, // Handle long press events.
          child: Stack(
            children: [
              if (piece.thumbnailPath != null && piece.thumbnailPath!.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(piece.thumbnailPath!), // Display thumbnail image if available.
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.log('MusicPieceCard: Error loading thumbnail for "${piece.title}": $error');
                        return Container(); // Return empty container on error
                      },
                    ),
                  ),
                ),
              if (piece.enablePracticeTracking)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: PracticeIndicatorUtils.getPracticeIndicatorColor(piece.lastPracticeTime),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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
                          style: Theme.of(context).textTheme.titleLarge, // Apply large title style.
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis.
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          piece.artistComposer,
                          style: Theme.of(context).textTheme.titleSmall, // Apply small title style.
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
                                backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null, // Adjust chip color based on theme brightness.
                              );
                            })),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          PracticeIndicatorUtils.formatLastPracticeTime(piece.lastPracticeTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
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
      ),
    );
  }
}