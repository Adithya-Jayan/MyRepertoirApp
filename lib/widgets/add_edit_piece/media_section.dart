import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import '../detail_widgets/media_section.dart';
import 'package:repertoire/models/music_piece.dart'; // Add this import
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../utils/app_logger.dart';
import './highlightable_widget.dart';

class MediaSectionWidget extends StatelessWidget {
  final MusicPiece musicPiece; // New parameter
  final Function(MusicPiece) onMusicPieceChanged; // New parameter
  final String? newlyAddedId;
  final VoidCallback? onHighlightComplete;
  final Map<String, GlobalKey> itemKeys;
  final Function(String)? onThumbnailSet; // New callback

  const MediaSectionWidget({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
    this.newlyAddedId,
    this.onHighlightComplete,
    required this.itemKeys,
    this.onThumbnailSet,
  });

  @override
  Widget build(BuildContext context) {
    // Separate regular media items and thumbnail items
    final regularItems = musicPiece.mediaItems.where((item) => item.type != MediaType.thumbnails).toList();
    final thumbnailItems = musicPiece.mediaItems.where((item) => item.type == MediaType.thumbnails).toList();

    void handleDelete(MediaItem deletedItem) {
      final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
      updatedMediaItems.removeWhere((element) => element.id == deletedItem.id);
      
      // Check if we need to clear the thumbnail. 
      // Only clear if the authoritative Thumbnail Widget itself is deleted.
      String? newThumbnailPath = musicPiece.thumbnailPath;
      if (deletedItem.type == MediaType.thumbnails && musicPiece.thumbnailPath == deletedItem.pathOrUrl) {
          newThumbnailPath = null;
      }
      
      onMusicPieceChanged(musicPiece.copyWith(
        mediaItems: updatedMediaItems,
        thumbnailPath: newThumbnailPath,
        clearThumbnail: newThumbnailPath == null,
      ));
    }

    Future<void> handleSetThumbnail(String thumbnailPath) async {
      if (thumbnailPath.isEmpty) {
        onMusicPieceChanged(musicPiece.copyWith(thumbnailPath: null, clearThumbnail: true));
        return;
      }

      String? thumbnailId;

      // Check if this path is already from a thumbnail widget
      final isFromThumbnailWidget = musicPiece.mediaItems.any((item) => 
        item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath
      );

      if (isFromThumbnailWidget) {
        // Just set the path
        final widgetId = musicPiece.mediaItems.firstWhere((item) => 
          item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath
        ).id;
        onMusicPieceChanged(musicPiece.copyWith(thumbnailPath: thumbnailPath));
        onThumbnailSet?.call(widgetId);
        return;
      }

      // Copy and compress the file to create a dedicated thumbnail source
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final pieceMediaDir = Directory(p.join(appDir.path, 'media', musicPiece.id));
        if (!await pieceMediaDir.exists()) {
          await pieceMediaDir.create(recursive: true);
        }

        // Force .jpg extension for the compressed file
        final newFileName = 'thumbnail_${const Uuid().v4()}.jpg';
        final newFilePath = p.join(pieceMediaDir.path, newFileName);

        final sourceFile = File(thumbnailPath);
        if (await sourceFile.exists()) {
          // Compress and resize the image to a maximum of 1024px.
          // This prevents memory lag from huge original images.
          final result = await FlutterImageCompress.compressAndGetFile(
            sourceFile.absolute.path,
            newFilePath,
            quality: 85,
            minWidth: 1024,
            minHeight: 1024,
            format: CompressFormat.jpeg,
          );

          if (result != null) {
            final compressedFilePath = result.path;
            AppLogger.log('MediaSectionWidget: Compressed thumbnail to $compressedFilePath');

            // Create or update thumbnail widget
            final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
            final existingThumbnailIndex = updatedMediaItems.indexWhere((item) => item.type == MediaType.thumbnails);

            if (existingThumbnailIndex != -1) {
              // Update existing
              final oldItem = updatedMediaItems[existingThumbnailIndex];
              updatedMediaItems[existingThumbnailIndex] = oldItem.copyWith(pathOrUrl: compressedFilePath);
              thumbnailId = oldItem.id;
            } else {
              // Create new
              thumbnailId = const Uuid().v4();
              updatedMediaItems.add(MediaItem(
                id: thumbnailId,
                type: MediaType.thumbnails,
                pathOrUrl: compressedFilePath,
              ));
            }

            onMusicPieceChanged(musicPiece.copyWith(
              mediaItems: updatedMediaItems,
              thumbnailPath: compressedFilePath,
            ));
            onThumbnailSet?.call(thumbnailId);
          } else {
            AppLogger.log('MediaSectionWidget: Compression failed for $thumbnailPath');
          }
        } else {
          AppLogger.log('MediaSectionWidget: Source thumbnail file not found: $thumbnailPath');
        }
      } catch (e) {
        AppLogger.log('MediaSectionWidget: Error setting thumbnail: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        if (musicPiece.mediaItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Use the '+' sign to add media"),
            ),
          )
        else ...[
          if (regularItems.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regularItems.length,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final item = regularItems[index];
                // Find the index in the original list for updates
                final originalIndex = musicPiece.mediaItems.indexWhere((element) => element.id == item.id);
                final itemKey = itemKeys.putIfAbsent(item.id, () => GlobalKey());

                return HighlightableWidget(
                  key: ValueKey(item.id),
                  isHighlighted: newlyAddedId == item.id,
                  onHighlightComplete: onHighlightComplete,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side: Management Rail (Reorder & Delete)
                          Container(
                            width: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: Border(
                                right: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Icon(Icons.drag_handle, color: Colors.grey),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => handleDelete(item),
                                  tooltip: 'Delete media item',
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          
                          // Right side: Content Area
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: MediaSection(
                                key: itemKey,
                                item: item,
                                index: index,
                                globalIndex: originalIndex,
                                musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                                musicPieceId: musicPiece.id,
                                isReorderable: false, // Handled by outer rail
                                showExternalDelete: false, // Handled by outer rail
                                onUpdateMediaItem: (updatedItem) {
                                  final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                                  if (originalIndex != -1) {
                                    updatedMediaItems[originalIndex] = updatedItem;
                                    
                                    String? newPieceThumbnail = musicPiece.thumbnailPath;
                                    if (updatedItem.type == MediaType.thumbnails) {
                                        newPieceThumbnail = updatedItem.pathOrUrl;
                                    }

                                    onMusicPieceChanged(musicPiece.copyWith(
                                        mediaItems: updatedMediaItems,
                                        thumbnailPath: newPieceThumbnail
                                    ));
                                  }
                                },
                                onDeleteMediaItem: handleDelete,
                                onSetThumbnail: handleSetThumbnail,
                                musicPiece: musicPiece,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final newRegularItems = List<MediaItem>.from(regularItems);
                final item = newRegularItems.removeAt(oldIndex);
                newRegularItems.insert(newIndex, item);
                
                // Reconstruct the full list: newRegularItems + thumbnailItems
                // Note: This assumes thumbnails were at the end. If they were mixed, this forces them to end.
                // Which is desired behavior.
                final updatedMediaItems = [...newRegularItems, ...thumbnailItems];
                onMusicPieceChanged(musicPiece.copyWith(mediaItems: updatedMediaItems));
              },
            ),
            
          if (thumbnailItems.isNotEmpty) ...[
             if (regularItems.isNotEmpty)
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8.0),
                 child: Divider(),
               ),
             const Padding(
               padding: EdgeInsets.only(bottom: 8.0),
               child: Text('Thumbnail Widget (Visible in Edit Mode only)', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey)),
             ),
             ...thumbnailItems.map((item) {
                final originalIndex = musicPiece.mediaItems.indexWhere((element) => element.id == item.id);
                final itemKey = itemKeys.putIfAbsent(item.id, () => GlobalKey());

                return HighlightableWidget(
                  key: ValueKey(item.id),
                  isHighlighted: newlyAddedId == item.id,
                  onHighlightComplete: onHighlightComplete,
                  child: MediaSection(
                    key: itemKey,
                    item: item,
                    index: -1, // Not used for reordering
                    globalIndex: originalIndex,
                    isReorderable: false,
                    musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                    musicPieceId: musicPiece.id,
                    onUpdateMediaItem: (updatedItem) {
                      final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                      if (originalIndex != -1) {
                        updatedMediaItems[originalIndex] = updatedItem;
                        
                        String? newPieceThumbnail = musicPiece.thumbnailPath;
                        
                        // If it's a dedicated thumbnail widget, it is the authoritative source.
                        // Sync unconditionally.
                        if (updatedItem.type == MediaType.thumbnails) {
                            newPieceThumbnail = updatedItem.pathOrUrl;
                        }

                        onMusicPieceChanged(musicPiece.copyWith(
                            mediaItems: updatedMediaItems,
                            thumbnailPath: newPieceThumbnail
                        ));
                      }
                    },
                    onDeleteMediaItem: handleDelete,
                    onSetThumbnail: handleSetThumbnail,
                    musicPiece: musicPiece,
                  ),
                );
             }),
          ],
        ],
      ],
    );
  }
}
