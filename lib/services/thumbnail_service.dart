import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
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
            AppLogger.log('ThumbnailService: Link thumbnail saved to ${thumbnailFile.path} (${response.bodyBytes.length} bytes)');
          }
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
          // Check for both .jpg (web links) and .png (video frames)
          final jpgFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
          if (await jpgFile.exists()) return jpgFile.path;
          
          final pngFile = File(p.join(thumbnailDir.path, '${item.id}.png'));
          if (await pngFile.exists()) return pngFile.path;
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
      
      // Target a reasonable thumbnail size (e.g. max 720 width)
      double width = controller.value.size.width;
      double height = controller.value.size.height;
      const double maxDimension = 720.0;
      
      if (width > maxDimension || height > maxDimension) {
        final double scale = maxDimension / (width > height ? width : height);
        width *= scale;
        height *= scale;
      }
      
      final int iWidth = width.toInt();
      final int iHeight = height.toInt();
      
      if (iWidth <= 0 || iHeight <= 0) {
        AppLogger.log('ThumbnailService: Invalid calculated video size: $iWidth x $iHeight');
        return null;
      }

      // Seek to 1 second (or 10% of duration) to avoid black frames at start
      final duration = controller.value.duration;
      final seekPos = duration.inSeconds > 1 ? const Duration(seconds: 1) : Duration.zero;
      await controller.seekTo(seekPos);
      
      // Wait for seek to complete and frame to be ready
      await Future.delayed(const Duration(milliseconds: 1000));

      return await captureFrameFromController(controller, musicPieceId, item.id);
    } catch (e) {
      AppLogger.log('ThumbnailService: Error generating video thumbnail: $e');
    } finally {
      await controller?.dispose();
    }
    return null;
  }

  static Future<String?> captureFrameFromController(VideoPlayerController controller, String musicPieceId, String mediaItemId) async {
    if (kIsWeb) return null;
    if (!controller.value.isInitialized) return null;

    try {
      // Target a reasonable thumbnail size (e.g. max 720 width)
      double width = controller.value.size.width;
      double height = controller.value.size.height;
      const double maxDimension = 720.0;
      
      if (width > maxDimension || height > maxDimension) {
        final double scale = maxDimension / (width > height ? width : height);
        width *= scale;
        height *= scale;
      }
      
      final int iWidth = width.toInt();
      final int iHeight = height.toInt();
      
      if (iWidth <= 0 || iHeight <= 0) {
        AppLogger.log('ThumbnailService: Invalid video size for snapshot: $iWidth x $iHeight');
        return null;
      }

      // Use fvp extension to take a snapshot (returns raw pixel data)
      AppLogger.log('ThumbnailService: Requesting snapshot from active controller at $iWidth x $iHeight...');
      final rawPixels = await fvp.FVPControllerExtensions(controller).snapshot(
        width: iWidth,
        height: iHeight,
      );
      
      if (rawPixels != null && rawPixels.isNotEmpty) {
        AppLogger.log('ThumbnailService: Captured raw frame (${rawPixels.length} bytes). Encoding to PNG...');
        
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          rawPixels,
          iWidth,
          iHeight,
          ui.PixelFormat.rgba8888,
          (ui.Image img) => completer.complete(img),
        );
        
        final uiImage = await completer.future;
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          
          if (pngBytes.isEmpty) {
             AppLogger.log('ThumbnailService: Encoded PNG is empty!');
             return null;
          }

          final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
          if (thumbnailDir != null) {
            if (!await thumbnailDir.exists()) {
              await thumbnailDir.create(recursive: true);
            }
            // Use a unique filename if capturing manually to avoid cache issues, 
            // but for automatic generation we can stick to item ID.
            final fileName = 'thumb_${mediaItemId}_${DateTime.now().millisecondsSinceEpoch}.png';
            final thumbnailFile = File(p.join(thumbnailDir.path, fileName));
            await thumbnailFile.writeAsBytes(pngBytes);
            AppLogger.log('ThumbnailService: Captured frame saved to ${thumbnailFile.path}');
            return thumbnailFile.path;
          }
        }
      }
    } catch (e) {
      AppLogger.log('ThumbnailService: Error capturing frame: $e');
    }
    return null;
  }

}
