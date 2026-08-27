import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../models/media_item.dart';
import '../../models/media_type.dart';
import '../../models/learning_progress_config.dart'; // Import config
import '../../services/media_storage_manager.dart';
import '../../utils/app_logger.dart';

class AddEditPieceMediaManager {
  final String musicPieceId;
  final Function(List<MediaItem>) onMediaItemsChanged;

  AddEditPieceMediaManager({
    required this.musicPieceId,
    required this.onMediaItemsChanged,
  });

  Future<List<String>> pickFile(
    MediaType type,
    List<MediaItem> currentMediaItems,
  ) async {
    FilePickerResult? result;

    switch (type) {
      case MediaType.image:
      case MediaType.thumbnails:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
        );
        break;
      case MediaType.pdf:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        break;
      case MediaType.audio:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: [
            'mp3',
            'wav',
            'm4a',
            'flac',
            'ogg',
            'mid',
            'midi',
          ],
        );
        break;
      case MediaType.localVideo:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
        );
        break;
      case MediaType.midi:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['mid', 'midi'],
        );
        break;
      case MediaType.markdown:
        result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['md', 'txt'],
        );
        break;
      case MediaType.mediaLink:
      case MediaType.learningProgress: // Handled separately
      case MediaType.lyrics: // Handled separately (inline text, no file picker)
        return [];
    }

    final List<String> skippedFiles = [];

    if (result != null && result.files.isNotEmpty) {
      try {
        final newMediaItems = List<MediaItem>.from(currentMediaItems);
        
        // We iterate through all selected files
        for (final file in result.files) {
          if (file.path == null) continue;
          
          MediaType finalType = type;
          final ext = p.extension(file.path!).toLowerCase();
          
          if (type == MediaType.audio) {
            if (ext == '.mid' || ext == '.midi') {
              finalType = MediaType.midi;
            } else if (!['.mp3', '.wav', '.m4a', '.flac', '.ogg'].contains(ext)) {
              skippedFiles.add(file.name);
              continue;
            }
          } else if (type == MediaType.pdf && ext != '.pdf') {
            skippedFiles.add(file.name);
            continue;
          } else if (type == MediaType.midi && !['.mid', '.midi'].contains(ext)) {
            skippedFiles.add(file.name);
            continue;
          } else if (type == MediaType.localVideo && !['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
            skippedFiles.add(file.name);
            continue;
          }

          final newPath = await MediaStorageManager.copyMediaToLocal(
            file.path!,
            musicPieceId,
            finalType,
          );

          newMediaItems.insert(
            0,
            MediaItem(id: const Uuid().v4(), type: finalType, pathOrUrl: newPath),
          );
        }

        if (newMediaItems.length != currentMediaItems.length) {
          onMediaItemsChanged(newMediaItems);
        }
      } catch (e) {
        AppLogger.log('Error copying files: $e');
        rethrow;
      }
    }
    
    return skippedFiles;
  }

  Future<List<String>> addMediaItem(
    MediaType type,
    List<MediaItem> currentMediaItems, {
    String? configData,
    String? defaultTitle,
  }) async {
    final newMediaItems = List<MediaItem>.from(currentMediaItems);
    if (type == MediaType.mediaLink ||
        type == MediaType.markdown ||
        type == MediaType.lyrics) {
      newMediaItems.add(
        MediaItem(id: const Uuid().v4(), type: type, pathOrUrl: ''),
      );
      onMediaItemsChanged(newMediaItems);
      return [];
    } else if (type == MediaType.learningProgress) {
      newMediaItems.add(
        MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl:
              configData ??
              LearningProgressConfig.encode(
                LearningProgressConfig(type: LearningProgressType.percentage),
              ),
          title: defaultTitle,
        ),
      );
      onMediaItemsChanged(newMediaItems);
      return [];
    } else {
      return await pickFile(type, newMediaItems);
    }
  }

  void updateMediaItem(MediaItem newItem, List<MediaItem> currentMediaItems) {
    final updatedMediaItems = List<MediaItem>.from(currentMediaItems);
    final index = updatedMediaItems.indexWhere(
      (element) => element.id == newItem.id,
    );
    if (index != -1) {
      updatedMediaItems[index] = newItem;
      onMediaItemsChanged(updatedMediaItems);
    }
  }

  Future<void> deleteMediaItem(
    MediaItem item,
    List<MediaItem> currentMediaItems,
  ) async {
    await MediaStorageManager.deleteLocalMediaFile(item.pathOrUrl);
    final updatedMediaItems = List<MediaItem>.from(currentMediaItems);
    updatedMediaItems.remove(item);
    onMediaItemsChanged(updatedMediaItems);
  }
}
