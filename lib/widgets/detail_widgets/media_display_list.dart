import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/database/music_piece_repository.dart';

/// A widget that displays a reorderable list of media items associated with a music piece.
///
/// It allows reordering of media items and persists the new order to the database.
class MediaDisplayList extends StatefulWidget {
  final MusicPiece musicPiece;
  final Function(MusicPiece) onMusicPieceChanged;

  const MediaDisplayList({
    super.key,
    required this.musicPiece,
    required this.onMusicPieceChanged,
  });

  @override
  State<MediaDisplayList> createState() => _MediaDisplayListState();
}

class _MediaDisplayListState extends State<MediaDisplayList> {
  late MusicPiece _musicPiece;
  final MusicPieceRepository _repository = MusicPieceRepository();

  @override
  void initState() {
    super.initState();
    _musicPiece = widget.musicPiece;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            ReorderableListView.builder(
              buildDefaultDragHandles: false, // Disable default handles
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // to allow SingleChildScrollView to work
              itemCount: _musicPiece.mediaItems.length,
              itemBuilder: (context, index) {
                final item = _musicPiece.mediaItems[index];
                return MediaDisplayWidget(
                  key: ValueKey(item.id),
                  mediaItem: item,
                  musicPieceTitle: _musicPiece.title,
                  musicPieceArtist: _musicPiece.artistComposer,
                  isEditable: false,
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _musicPiece.mediaItems.removeAt(oldIndex);
                  _musicPiece.mediaItems.insert(newIndex, item);
                  // Persist the new order to the database
                  _repository.updateMusicPiece(_musicPiece);
                  widget.onMusicPieceChanged(_musicPiece);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}