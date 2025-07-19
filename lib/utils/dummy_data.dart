import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/tag_group.dart';
import 'package:repertoire/utils/stable_id_generator.dart';


/// A list of pre-defined [MusicPiece] objects used for initial data population.
///
/// This data is inserted into the database when the application is first launched
/// or if the music_pieces table is found to be empty.
final List<MusicPiece> dummyMusicPieces = [
  MusicPiece(
    id: StableIdGenerator.generatePieceId('Sonata No. 14 "Moonlight"', 'Ludwig van Beethoven'),
    title: 'Sonata No. 14 "Moonlight"',
    artistComposer: 'Ludwig van Beethoven',
    tagGroups: [
      TagGroup(id: StableIdGenerator.generatePieceId('Genre', 'Classical'), name: 'Genre', tags: ['Classical', 'Romantic'], color: 0xFF64B5F6),
      TagGroup(id: StableIdGenerator.generatePieceId('Instrumentation', 'Piano'), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: StableIdGenerator.generatePieceId('Difficulty', 'Advanced'), name: 'Difficulty', tags: ['Advanced'], color: 0xFFFFB74D),
    ],
    tags: ['Romantic', 'Sonata', 'Template'],
    mediaItems: [
      MediaItem(
        id: StableIdGenerator.generateMediaItemId(
          StableIdGenerator.generatePieceId('Sonata No. 14 "Moonlight"', 'Ludwig van Beethoven'),
          'markdown',
          'practice_notes'
        ),
        type: MediaType.markdown,
        pathOrUrl: '''## Template Piece - Sonata No. 14 "Moonlight"

This is a **template piece** created to demonstrate the app's features. You can:

- **Edit this piece** to add your own music
- **Delete this piece** if you don't need it
- **Use it as a reference** for how to structure your music pieces

### Example Practice Notes
- Focus on the dynamics in the first movement
- The third movement should be played with intensity
- Pay attention to the pedal markings

### Features Demonstrated
- Multiple tag groups (Genre, Instrumentation, Difficulty)
- Practice notes in markdown format
- PDF attachment placeholder

Feel free to modify or delete this template piece!''',
      ),
      MediaItem(
        id: StableIdGenerator.generateMediaItemId(
          StableIdGenerator.generatePieceId('Sonata No. 14 "Moonlight"', 'Ludwig van Beethoven'),
          'pdf',
          'sheet_music'
        ),
        type: MediaType.pdf,
        pathOrUrl: '', // Dummy path
      ),
    ],
  ),
  MusicPiece(
    id: StableIdGenerator.generatePieceId('Clair de Lune', 'Claude Debussy'),
    title: 'Clair de Lune',
    artistComposer: 'Claude Debussy',
    tagGroups: [
      TagGroup(id: StableIdGenerator.generatePieceId('Genre', 'Classical'), name: 'Genre', tags: ['Classical', 'Impressionistic'], color: 0xFF64B5F6),
      TagGroup(id: StableIdGenerator.generatePieceId('Instrumentation', 'Piano'), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: StableIdGenerator.generatePieceId('Difficulty', 'Intermediate'), name: 'Difficulty', tags: ['Intermediate'], color: 0xFFFFB74D),
    ],
    tags: ['Impressionistic', 'Template'],
    mediaItems: [
      MediaItem(
        id: StableIdGenerator.generateMediaItemId(
          StableIdGenerator.generatePieceId('Clair de Lune', 'Claude Debussy'),
          'markdown',
          'performance_notes'
        ),
        type: MediaType.markdown,
        pathOrUrl: '''## Template Piece - Clair de Lune

This is a **template piece** created to demonstrate the app's features.

### Example Performance Notes
- Maintain a delicate touch throughout the piece
- Focus on the atmospheric quality
- Pay attention to the dynamic markings

### Features Demonstrated
- Single tag group with multiple tags
- Performance notes in markdown format
- Impressionistic style example

You can edit or delete this template piece as needed!''',
      ),
    ],
  ),
  MusicPiece(
    id: StableIdGenerator.generatePieceId('Für Elise', 'Ludwig van Beethoven'),
    title: 'Für Elise',
    artistComposer: 'Ludwig van Beethoven',
    tagGroups: [
      TagGroup(id: StableIdGenerator.generatePieceId('Genre', 'Classical'), name: 'Genre', tags: ['Classical', 'Romantic'], color: 0xFF64B5F6),
      TagGroup(id: StableIdGenerator.generatePieceId('Instrumentation', 'Piano'), name: 'Instrumentation', tags: ['Piano'], color: 0xFF81C784),
      TagGroup(id: StableIdGenerator.generatePieceId('Difficulty', 'Advanced'), name: 'Difficulty', tags: ['Advanced'], color: 0xFFFFB74D),
    ],
    tags: ['Classical', 'Template'],
    mediaItems: [
      MediaItem(
        id: StableIdGenerator.generateMediaItemId(
          StableIdGenerator.generatePieceId('Für Elise', 'Ludwig van Beethoven'),
          'markdown',
          'example_notes'
        ),
        type: MediaType.markdown,
        pathOrUrl: '''## Template Piece - Für Elise

This is a **template piece** created to demonstrate the app's features.

### Example Notes
- This piece demonstrates a music piece without any media attachments
- You can add your own media files (PDFs, audio, images, etc.)
- Practice tracking is available for all pieces

### Features Demonstrated
- Multiple tag groups
- No media attachments (clean slate)
- Classical piece example

Feel free to add your own media files or delete this template!''',
      ),
    ],
  ),
];
