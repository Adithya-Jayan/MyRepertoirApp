import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import './piece_detail_screen.dart';

import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../models/media_type.dart';
import './piece_detail_screen.dart';

class MusicPieceCard extends StatelessWidget {
  final MusicPiece piece;

  const MusicPieceCard({super.key, required this.piece});

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.pdf:
        return Icons.picture_as_pdf;
      case MediaType.image:
        return Icons.image;
      case MediaType.audio:
        return Icons.audio_file;
      case MediaType.videoLink:
        return Icons.video_library;
      case MediaType.markdown:
        return Icons.description;
      default:
        return Icons.music_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryMediaIcon = piece.mediaItems.isNotEmpty
        ? _getMediaIcon(piece.mediaItems.first.type)
        : Icons.music_note;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PieceDetailScreen(musicPiece: piece),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(primaryMediaIcon, size: 40.0, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      piece.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      piece.artistComposer,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (piece.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          piece.tags.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
