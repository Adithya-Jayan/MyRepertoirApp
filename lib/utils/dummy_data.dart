import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/ordered_tag.dart';
import 'package:uuid/uuid.dart';

final List<MusicPiece> dummyMusicPieces = [
  MusicPiece(
    id: const Uuid().v4(),
    title: 'Sonata No. 14 "Moonlight"',
    artistComposer: 'Ludwig van Beethoven',
    orderedTags: [
      OrderedTag(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Difficulty', tags: ['Advanced']),
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
    orderedTags: [
      OrderedTag(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Difficulty', tags: ['Intermediate']),
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
    orderedTags: [
      OrderedTag(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano']),
      OrderedTag(id: const Uuid().v4(), name: 'Difficulty', tags: ['Beginner']),
    ],
    tags: ['Classical'],
    mediaItems: [],
  ),
];