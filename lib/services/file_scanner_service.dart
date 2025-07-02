import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/media_item.dart';
import '../models/music_piece.dart';
import 'package:uuid/uuid.dart';

class FileScannerService {
  Future<List<MusicPiece>> scanDirectoryForMusicPieces() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // User canceled the picker
      return [];
    }

    List<MusicPiece> scannedPieces = [];
    final directory = Directory(selectedDirectory);

    await for (var entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final file = entity;
        final fileName = p.basenameWithoutExtension(file.path);
        final fileExtension = p.extension(file.path).toLowerCase();

        MediaType? mediaType;
        if (['.pdf'].contains(fileExtension)) {
          mediaType = MediaType.pdf;
        } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(fileExtension)) {
          mediaType = MediaType.image;
        } else if (['.mp3', '.wav', '.flac', '.aac'].contains(fileExtension)) {
          mediaType = MediaType.audio;
        } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(fileExtension)) {
          mediaType = MediaType.videoLink; // Assuming video files are treated as links for now
        } else if (['.md', '.txt'].contains(fileExtension)) {
          mediaType = MediaType.markdown;
        }

        if (mediaType != null) {
          final mediaItem = MediaItem(
            id: const Uuid().v4(),
            type: mediaType,
            pathOrUrl: file.path,
            title: fileName,
          );

          // For simplicity, creating a new MusicPiece for each file found.
          // In a real app, you'd have more sophisticated logic to group related files.
          scannedPieces.add(MusicPiece(
            id: const Uuid().v4(),
            title: fileName,
            artistComposer: 'Unknown', // Placeholder
            mediaItems: [mediaItem],
          ));
        }
      }
    }
    return scannedPieces;
  }
}
