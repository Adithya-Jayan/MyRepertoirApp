import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/media_storage_manager.dart';

class ThumbnailService {
  static Future<void> fetchAndSaveThumbnail(MediaItem item, String musicPieceId) async {
    if (item.type == MediaType.mediaLink && item.pathOrUrl.isNotEmpty) {
      try {
        final metadata = await MetadataFetch.extract(item.pathOrUrl);
        final thumbnailUrl = metadata?.image;

        if (thumbnailUrl != null) {
          final response = await http.get(Uri.parse(thumbnailUrl));
          final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
          if (!await thumbnailDir.exists()) {
            await thumbnailDir.create(recursive: true);
          }
          final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
          await thumbnailFile.writeAsBytes(response.bodyBytes);
          // Do not mutate the passed MediaItem here; let callers update state immutably
        }
      } catch (e) {
        AppLogger.log('Error fetching or saving thumbnail: $e');
      }
    }
  }

  static Future<String?> getThumbnailPath(MediaItem item, String musicPieceId) async {
    if (item.type == MediaType.mediaLink && item.pathOrUrl.isNotEmpty) {
      try {
        final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
        final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
        if (await thumbnailFile.exists()) {
          return thumbnailFile.path;
        }
      } catch (e) {
        AppLogger.log('Error getting thumbnail path: $e');
      }
    }
    return null;
  }
}
