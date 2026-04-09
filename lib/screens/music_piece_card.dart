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
  final bool isListView; // Whether the card is displayed in a list view (compact).
  final int galleryColumns; // Current number of gallery columns
  final VoidCallback? onTap; // Callback function when the card is tapped.
  final VoidCallback? onLongPress; // Callback function when the card is long-pressed.

  const MusicPieceCard({
    super.key,
    required this.piece,
    this.isSelected = false,
    this.isListView = false,
    this.galleryColumns = 2,
    this.onTap,
    this.onLongPress,
  });

  Widget _buildTagChip(dynamic tg, String tag, Brightness brightness, {double scale = 1.0}) {
    final color = tg.color != null ? Color(tg.color!) : null;
    Widget chip = Chip(
      label: Text(
        tag,
        style: TextStyle(fontSize: 10 * scale),
      ),
      backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 0),
    );

    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        alignment: Alignment.centerLeft,
        child: chip,
      );
    }
    return chip;
  }

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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // Solid text as fill.
            Text(
              text,
              style: style,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        );
      } else {
        return Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
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
                      gaplessPlayback: true,
                      cacheWidth: isListView ? 800 : 300,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: isListView ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    if (piece.enablePracticeTracking)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(bottom: 4.0),
                          decoration: BoxDecoration(
                            color: PracticeIndicatorUtils.getPracticeIndicatorColorSync(piece.lastPracticeTime) ?? Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    textWithOutline(
                      piece.title,
                      Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4.0),
                    textWithOutline(
                      piece.artistComposer,
                      Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8.0),
                    if (piece.tagGroups.isNotEmpty)
                      isListView
                          ? Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              clipBehavior: Clip.antiAlias,
                              children: [
                                for (final tg in piece.tagGroups)
                                  for (final tag in tg.tags)
                                    _buildTagChip(tg, tag, brightness),
                              ],
                            )
                          : galleryColumns <= 4
                              ? SizedBox(
                                  height: 32, // Fixed height for chips row
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (final tg in piece.tagGroups)
                                          for (final tag in tg.tags)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4.0),
                                              child: _buildTagChip(tg, tag, brightness, scale: galleryColumns > 2 ? 0.8 : 1.0),
                                            ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Icon(
                                    Icons.label_outline, 
                                    size: 14, 
                                    color: (brightness == Brightness.dark ? Colors.white70 : Colors.black54)
                                  ),
                                ), // Show indicator icon when tags are hidden due to density
                    if (isListView)
                      const SizedBox(height: 8.0)
                    else
                      const Spacer(), // Push bottom text down if space allows
                    if (piece.enablePracticeTracking && themeNotifier.showLastPracticed)
                      textWithOutline(
                        PracticeIndicatorUtils.formatLastPracticeTime(piece.lastPracticeTime),
                        Theme.of(context).textTheme.bodySmall,
                      ),
                    if (piece.enablePracticeTracking && themeNotifier.showPracticeCount)
                      textWithOutline(
                        'Practice count: ${piece.practiceCount}',
                        Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}