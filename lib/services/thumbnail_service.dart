import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart' as fvp;

import '../utils/app_logger.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/media_storage_manager.dart';

class ThumbnailService {
  static Future<void> fetchAndSaveThumbnail(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return; // Cannot save to local files on web yet

    if (item.type == MediaType.mediaLink && item.pathOrUrl.isNotEmpty) {
      try {
        final metadata = await MetadataFetch.extract(item.pathOrUrl);
        final thumbnailUrl = metadata?.image;

        if (thumbnailUrl != null) {
          final response = await http.get(Uri.parse(thumbnailUrl));
          final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
          if (thumbnailDir != null) {
            if (!await thumbnailDir.exists()) {
              await thumbnailDir.create(recursive: true);
            }
            final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
            await thumbnailFile.writeAsBytes(response.bodyBytes);
          }
          // Do not mutate the passed MediaItem here; let callers update state immutably
        }
      } catch (e) {
        AppLogger.log('Error fetching or saving thumbnail: $e');
      }
    }
  }

  static Future<String?> getThumbnailPath(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return null;

    if ((item.type == MediaType.mediaLink || item.type == MediaType.localVideo) && item.pathOrUrl.isNotEmpty) {
      try {
        final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
        if (thumbnailDir != null) {
          final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
          if (await thumbnailFile.exists()) {
            return thumbnailFile.path;
          }
        }
      } catch (e) {
        AppLogger.log('Error getting thumbnail path: $e');
      }
    }
    return null;
  }

  static Future<String?> generateVideoThumbnail(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return null;
    if (item.type != MediaType.localVideo) return null;

    AppLogger.log('ThumbnailService: Generating video thumbnail for ${item.pathOrUrl}');
    
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(item.pathOrUrl));
      await controller.initialize();
      
      // Seek to 1 second (or 10% of duration) to avoid black frames at start
      final duration = controller.value.duration;
      final seekPos = duration.inSeconds > 1 ? const Duration(seconds: 1) : Duration.zero;
      await controller.seekTo(seekPos);
      
      // Small delay to ensure frame is loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Use fvp extension to take a snapshot
      final snapshot = await fvp.FVPControllerExtensions(controller).snapshot();
      
      if (snapshot != null) {
        final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
        if (thumbnailDir != null) {
          if (!await thumbnailDir.exists()) {
            await thumbnailDir.create(recursive: true);
          }
          final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
          await thumbnailFile.writeAsBytes(snapshot);
          AppLogger.log('ThumbnailService: Video thumbnail saved to ${thumbnailFile.path}');
          return thumbnailFile.path;
        }
      } else {
        AppLogger.log('ThumbnailService: Failed to take snapshot from video.');
      }
    } catch (e) {
      AppLogger.log('ThumbnailService: Error generating video thumbnail: $e');
    } finally {
      await controller?.dispose();
    }
    return null;
  }
}
