import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';

class FileScannerService {
  Future<List<MusicPiece>> scanDirectory(String directoryPath) async {
    final Directory directory = Directory(directoryPath);
    List<MusicPiece> scannedPieces = [];

    if (!await directory.exists()) {
      return [];
    }

    await for (var entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final file = entity;
        final fileName = p.basenameWithoutExtension(file.path);
        final fileExtension = p.extension(file.path).toLowerCase();

        MediaType? mediaType;
        if (['.pdf'].contains(fileExtension)) {
          mediaType = MediaType.pdf;
        } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(fileExtension)) {
          mediaType = MediaType.image;
        } else if (['.mp3', '.wav', '.flac'].contains(fileExtension)) {
          mediaType = MediaType.audio;
        } else if (['.mp4', '.mov', '.avi'].contains(fileExtension)) {
          mediaType = MediaType.videoLink; // Assuming local video files are treated as links for now
        } else if (['.md', '.txt'].contains(fileExtension)) {
          mediaType = MediaType.markdown;
        }

        if (mediaType != null) {
          // For simplicity, creating a new MusicPiece for each relevant file found.
          // In a real app, you might group files into existing MusicPieces
          // based on folder structure or metadata.
          final mediaItem = MediaItem(
            id: const Uuid().v4(),
            type: mediaType,
            pathOrUrl: file.path,
            title: fileName,
          );

          final musicPiece = MusicPiece(
            id: const Uuid().v4(),
            title: fileName, // Use filename as title for now
            artistComposer: 'Unknown', // Placeholder
            mediaItems: [mediaItem],
          );
          scannedPieces.add(musicPiece);
        }
      }
    }
    return scannedPieces;
  }
}