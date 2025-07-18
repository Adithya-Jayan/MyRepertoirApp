import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/tag_group.dart';
import 'package:uuid/uuid.dart';


/// A list of pre-defined [MusicPiece] objects used for initial data population.
///
/// This data is inserted into the database when the application is first launched
/// or if the music_pieces table is found to be empty.
final List<MusicPiece> dummyMusicPieces = [
  MusicPiece(
    id: const Uuid().v4(),
    title: 'Sonata No. 14 "Moonlight"',
    artistComposer: 'Ludwig van Beethoven',
    tagGroups: [
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Romantic'], color: 0xFF64B5F6),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Advanced'], color: 0xFFFFB74D),
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
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Impressionistic'], color: 0xFF64B5F6),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Intermediate'], color: 0xFFFFB74D),
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
      TagGroup(id: const Uuid().v4(), name: 'Genre', tags: ['Classical', 'Romantic'], color: 0xFF64B5F6),
      TagGroup(id: const Uuid().v4(), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: const Uuid().v4(), name: 'Difficulty', tags: ['Advanced'], color: 0xFFFFB74D),
    ],
    tags: ['Classical'],
    mediaItems: [],
  ),
];
