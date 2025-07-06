import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/tag_group.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

final List<MusicPiece> dummyMusicPieces = [
  MusicPiece(
    id: const Uuid().v4(),
    title: 'Sonata No. 14 "Moonlight"',
    artistComposer: 'Ludwig van Beethoven',
    tagGroups: [
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Romantic'], color: Colors.blue[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: Colors.green[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Advanced'], color: Colors.orange[300]!.value),
    ],
    tags: ['Romantic', 'Sonata'],
    mediaItems: [
      MediaItem(
        id: const Uuid().v4(),
        type: MediaType.markdown,
        pathOrUrl: '''## Practice Notes
- Focus on the dynamics in the first movement.
- The third movement should be played with intensity.''',
      ),
      MediaItem(
        id: const Uuid().v4(),
        type: MediaType.pdf,
        pathOrUrl: '', // Dummy path
      ),
    ],
  ),
  MusicPiece(
    id: const Uuid().v4(),
    title: 'Clair de Lune',
    artistComposer: 'Claude Debussy',
    tagGroups: [
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Impressionistic'], color: Colors.blue[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: Colors.green[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Intermediate'], color: Colors.orange[300]!.value),
    ],
    tags: ['Impressionistic'],
    mediaItems: [
      MediaItem(
        id: const Uuid().v4(),
        type: MediaType.markdown,
        pathOrUrl: '''## Performance Notes
- Maintain a delicate touch throughout the piece.''',
      ),
    ],
  ),
  MusicPiece(
    id: const Uuid().v4(),
    title: 'Für Elise',
    artistComposer: 'Ludwig van Beethoven',
    tagGroups: [
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical'], color: Colors.blue[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: Colors.green[300]!.value),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Beginner'], color: Colors.orange[300]!.value),
    ],
    tags: ['Classical'],
    mediaItems: [],
  ),
];
