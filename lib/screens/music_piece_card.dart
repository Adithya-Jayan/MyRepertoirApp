import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:repertoire/utils/color_utils.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/utils/practice_indicator_utils.dart';
import 'package:repertoire/utils/theme_notifier.dart'; // Import ThemeNotifier
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
    final themeNotifier = Provider.of<ThemeNotifier>(context); // Retrieve ThemeNotifier
    final Brightness brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasThumbnail = piece.thumbnailPath != null && piece.thumbnailPath!.isNotEmpty;
    final ThumbnailStyle thumbnailStyle = themeNotifier.thumbnailStyle;

    Widget textWithOutline(String text, TextStyle? style) {
      if (hasThumbnail && thumbnailStyle == ThumbnailStyle.outline) {
        return Stack(
          children: <Widget>[
            // Stroked text as border.
            Text(
              text,
              style: style?.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            // Solid text as fill.
            Text(
              text,
              style: style,
            ),
          ],
        );
      } else {
        return Text(text, style: style);
      }
    }

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        color: isSelected ? colorScheme.primary.withAlpha(26) : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              if (hasThumbnail)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(piece.thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.log('MusicPieceCard: Error loading thumbnail for "${piece.title}": $error');
                        return Container();
                      },
                    ),
                  ),
                ),
              if (hasThumbnail && thumbnailStyle == ThumbnailStyle.gradient)
                 Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                            (brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (piece.enablePracticeTracking)
                        Align(
                          alignment: Alignment.topRight,
                          child: FutureBuilder<Color>(
                            future: PracticeIndicatorUtils.getPracticeIndicatorColor(piece.lastPracticeTime),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  decoration: BoxDecoration(
                                    color: snapshot.data,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: textWithOutline(
                          piece.title,
                          Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: textWithOutline(
                          piece.artistComposer,
                          Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final minChips = 2;
                          final spacing = 8.0;
                          final maxChipWidth = (constraints.maxWidth - (minChips - 1) * spacing) / minChips;
                          final tagWidgets = <Widget>[];
                          if (piece.tagGroups.isNotEmpty) {
                            for (final tg in piece.tagGroups) {
                              for (final tag in tg.tags) {
                                final color = tg.color != null ? Color(tg.color!) : null;
                                tagWidgets.add(
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: maxChipWidth),
                                    child: Chip(
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          tag,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                          return Wrap(
                            spacing: spacing,
                            runSpacing: 4.0,
                            children: tagWidgets,
                          );
                        },
                      ),
                      const SizedBox(height: 8.0),
                      if (piece.enablePracticeTracking && themeNotifier.showLastPracticed)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: textWithOutline(
                            PracticeIndicatorUtils.formatLastPracticeTime(piece.lastPracticeTime),
                            Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (piece.enablePracticeTracking && themeNotifier.showPracticeCount)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: textWithOutline(
                            'Practice count: ${piece.practiceCount}',
                            Theme.of(context).textTheme.bodySmall,
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