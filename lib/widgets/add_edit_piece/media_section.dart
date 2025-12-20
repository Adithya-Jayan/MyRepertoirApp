import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import '../detail_widgets/media_section.dart';
import 'package:repertoire/models/music_piece.dart'; // Add this import
import '../../utils/app_logger.dart';

class MediaSectionWidget extends StatelessWidget {
  final MusicPiece musicPiece; // New parameter
  final Function(MusicPiece) onMusicPieceChanged; // New parameter

  const MediaSectionWidget({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Separate regular media items and thumbnail items
    final regularItems = musicPiece.mediaItems.where((item) => item.type != MediaType.thumbnails).toList();
    final thumbnailItems = musicPiece.mediaItems.where((item) => item.type == MediaType.thumbnails).toList();

    void handleDelete(MediaItem deletedItem) {
      final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
      updatedMediaItems.removeWhere((element) => element.id == deletedItem.id);
      
      // Check if we need to clear the thumbnail
      String? newThumbnailPath = musicPiece.thumbnailPath;
      
      if (deletedItem.type == MediaType.image || deletedItem.type == MediaType.thumbnails) {
          if (musicPiece.thumbnailPath == deletedItem.pathOrUrl) {
            newThumbnailPath = null;
          }
      } else {
          if (deletedItem.thumbnailPath != null && musicPiece.thumbnailPath == deletedItem.thumbnailPath) {
            newThumbnailPath = null;
          }
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

      // Check if this path is already from a thumbnail widget
      final isFromThumbnailWidget = musicPiece.mediaItems.any((item) => 
        item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath
      );

      if (isFromThumbnailWidget) {
        // Just set the path
        onMusicPieceChanged(musicPiece.copyWith(thumbnailPath: thumbnailPath));
        return;
      }

      // Copy the file to create a dedicated thumbnail source
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final pieceMediaDir = Directory(p.join(appDir.path, 'media', musicPiece.id));
        if (!await pieceMediaDir.exists()) {
          await pieceMediaDir.create(recursive: true);
        }

        final extension = p.extension(thumbnailPath);
        final newFileName = 'thumbnail_${const Uuid().v4()}$extension';
        final newFilePath = p.join(pieceMediaDir.path, newFileName);

        final sourceFile = File(thumbnailPath);
        if (await sourceFile.exists()) {
          await sourceFile.copy(newFilePath);
          AppLogger.log('MediaSectionWidget: Copied thumbnail to $newFilePath');

          // Create or update thumbnail widget
          final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
          final existingThumbnailIndex = updatedMediaItems.indexWhere((item) => item.type == MediaType.thumbnails);

          if (existingThumbnailIndex != -1) {
            // Update existing
            final oldItem = updatedMediaItems[existingThumbnailIndex];
            updatedMediaItems[existingThumbnailIndex] = oldItem.copyWith(pathOrUrl: newFilePath);
            // Optional: Clean up old file if it was different?
          } else {
            // Create new
            updatedMediaItems.add(MediaItem(
              id: const Uuid().v4(),
              type: MediaType.thumbnails,
              pathOrUrl: newFilePath,
            ));
          }

          onMusicPieceChanged(musicPiece.copyWith(
            mediaItems: updatedMediaItems,
            thumbnailPath: newFilePath,
          ));
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

                return MediaSection(
                  key: ValueKey(item.id),
                  item: item,
                  index: index,
                  globalIndex: originalIndex,
                  musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                  musicPieceId: musicPiece.id,
                  onUpdateMediaItem: (updatedItem) {
                    final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                    if (originalIndex != -1) {
                      final oldItem = updatedMediaItems[originalIndex];
                      updatedMediaItems[originalIndex] = updatedItem;
                      
                      String? newPieceThumbnail = musicPiece.thumbnailPath;
                      
                      // If the piece thumbnail was pointing to the old item's path
                      if ((oldItem.type == MediaType.thumbnails || oldItem.type == MediaType.image) && 
                          musicPiece.thumbnailPath == oldItem.pathOrUrl) {
                          newPieceThumbnail = updatedItem.pathOrUrl;
                      } else if (oldItem.thumbnailPath != null && musicPiece.thumbnailPath == oldItem.thumbnailPath) {
                          newPieceThumbnail = updatedItem.thumbnailPath;
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
                return MediaSection(
                  key: ValueKey(item.id),
                  item: item,
                  index: -1, // Not used for reordering
                  globalIndex: originalIndex,
                  isReorderable: false,
                  musicPieceThumbnail: musicPiece.thumbnailPath ?? '',
                  musicPieceId: musicPiece.id,
                  onUpdateMediaItem: (updatedItem) {
                    final updatedMediaItems = List<MediaItem>.from(musicPiece.mediaItems);
                    if (originalIndex != -1) {
                      final oldItem = updatedMediaItems[originalIndex];
                      updatedMediaItems[originalIndex] = updatedItem;
                      
                      String? newPieceThumbnail = musicPiece.thumbnailPath;
                      
                      // If the piece thumbnail was pointing to the old item's path
                      if ((oldItem.type == MediaType.thumbnails || oldItem.type == MediaType.image) && 
                          musicPiece.thumbnailPath == oldItem.pathOrUrl) {
                          newPieceThumbnail = updatedItem.pathOrUrl;
                      } else if (oldItem.thumbnailPath != null && musicPiece.thumbnailPath == oldItem.thumbnailPath) {
                          newPieceThumbnail = updatedItem.thumbnailPath;
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
                );
             }),
          ],
        ],
      ],
    );
  }
} 