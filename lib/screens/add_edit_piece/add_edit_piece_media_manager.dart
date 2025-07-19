import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/media_item.dart';
import '../../models/media_type.dart';
import '../../services/media_storage_manager.dart';
import '../../utils/app_logger.dart';

class AddEditPieceMediaManager {
  final String musicPieceId;
  final Function(List<MediaItem>) onMediaItemsChanged;

  AddEditPieceMediaManager({
    required this.musicPieceId,
    required this.onMediaItemsChanged,
  });

  Future<void> pickFile(MediaType type, List<MediaItem> currentMediaItems) async {
    FilePickerResult? result;
    
    switch (type) {
      case MediaType.image:
        result = await FilePicker.platform.pickFiles(type: FileType.image);
        break;
      case MediaType.pdf:
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom, 
          allowedExtensions: ['pdf']
        );
        break;
      case MediaType.audio:
        result = await FilePicker.platform.pickFiles(type: FileType.audio);
        break;
      case MediaType.markdown:
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom, 
          allowedExtensions: ['md', 'txt']
        );
        break;
      case MediaType.mediaLink:
        return; // Handled separately
    }

    if (result != null && result.files.single.path != null) {
      try {
        final newPath = await MediaStorageManager.copyMediaToLocal(
          result.files.single.path!, 
          musicPieceId, 
          type
        );
        
        final newMediaItems = List<MediaItem>.from(currentMediaItems);
        newMediaItems.add(MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: newPath,
        ));
        
        onMediaItemsChanged(newMediaItems);
      } catch (e) {
        AppLogger.log('Error copying file: $e');
        rethrow;
      }
    }
  }

  void addMediaItem(MediaType type, List<MediaItem> currentMediaItems) {
    if (type == MediaType.mediaLink || type == MediaType.markdown) {
      final newMediaItems = List<MediaItem>.from(currentMediaItems);
      newMediaItems.add(MediaItem(
        id: const Uuid().v4(),
        type: type,
        pathOrUrl: '',
      ));
      onMediaItemsChanged(newMediaItems);
    } else {
      pickFile(type, currentMediaItems);
    }
  }

  void updateMediaItem(MediaItem newItem, List<MediaItem> currentMediaItems) {
    final updatedMediaItems = List<MediaItem>.from(currentMediaItems);
    final index = updatedMediaItems.indexWhere((element) => element.id == newItem.id);
    if (index != -1) {
      updatedMediaItems[index] = newItem;
      onMediaItemsChanged(updatedMediaItems);
    }
  }

  Future<void> deleteMediaItem(MediaItem item, List<MediaItem> currentMediaItems) async {
    await MediaStorageManager.deleteLocalMediaFile(item.pathOrUrl);
    final updatedMediaItems = List<MediaItem>.from(currentMediaItems);
    updatedMediaItems.remove(item);
    onMediaItemsChanged(updatedMediaItems);
  }
} 