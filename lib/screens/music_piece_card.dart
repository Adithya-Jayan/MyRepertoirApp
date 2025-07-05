import 'package:flutter/material.dart';
import '../models/music_piece.dart';

class MusicPieceCard extends StatelessWidget {
  final MusicPiece piece;
  final VoidCallback? onTap;

  const MusicPieceCard({super.key, required this.piece, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: SingleChildScrollView(
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
                  if (piece.orderedTags.isNotEmpty)
                    ...piece.orderedTags.expand((ot) => ot.tags.map((tag) => Chip(label: FittedBox(fit: BoxFit.scaleDown, child: Text(tag))))),
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
      ),
    );
  }
}