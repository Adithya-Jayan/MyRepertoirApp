import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:pdfrx/pdfrx.dart';

import '../utils/app_logger.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/media_storage_manager.dart';

class ThumbnailService {
  static Future<String?> fetchAndSaveThumbnail(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return null; // Cannot save to local files on web yet

    if (item.type == MediaType.mediaLink && item.pathOrUrl.isNotEmpty) {
      try {
        String? thumbnailUrl;
        
        // Specific handling for YouTube
        thumbnailUrl = _getYouTubeThumbnailUrl(item.pathOrUrl);
        
        if (thumbnailUrl == null) {
          // Fallback to metadata_fetch with a custom request to avoid being blocked
          final response = await http.get(Uri.parse(item.pathOrUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36'
          });
          
          if (response.statusCode == 200) {
            final document = MetadataFetch.responseToDocument(response);
            final metadata = MetadataParser.parse(document);
            thumbnailUrl = metadata.image;
          } else {
            // Try one more time with default extract if custom fails
            final metadata = await MetadataFetch.extract(item.pathOrUrl);
            thumbnailUrl = metadata?.image;
          }
        }

        if (thumbnailUrl != null) {
          final response = await http.get(Uri.parse(thumbnailUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36'
          });
          
          if (response.statusCode == 200) {
            final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
            if (thumbnailDir != null) {
              if (!await thumbnailDir.exists()) {
                await thumbnailDir.create(recursive: true);
              }
              final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
              await thumbnailFile.writeAsBytes(response.bodyBytes);
              AppLogger.log('ThumbnailService: Link thumbnail saved to ${thumbnailFile.path} (${response.bodyBytes.length} bytes)');
              return thumbnailFile.path;
            }
          } else {
             AppLogger.log('ThumbnailService: Failed to download thumbnail from $thumbnailUrl, status: ${response.statusCode}');
          }
        }
      } catch (e) {
        AppLogger.log('Error fetching or saving thumbnail: $e');
      }
    }
    return null;
  }

  static String? _getYouTubeThumbnailUrl(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final Match? match = regExp.firstMatch(url);
    if (match != null && match.group(7)!.length == 11) {
      final videoId = match.group(7);
      // mqdefault (320x180) is 16:9 and doesn't have baked-in black bars like hqdefault.
      return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    }
    return null;
  }

  static Future<String?> getThumbnailPath(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return null;

    if ((item.type == MediaType.mediaLink || item.type == MediaType.localVideo || item.type == MediaType.pdf) && item.pathOrUrl.isNotEmpty) {
      try {
        final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
        if (thumbnailDir != null) {
          // Check for both .jpg and .png
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

  static Future<String?> generatePdfThumbnail(MediaItem item, String musicPieceId) async {
    if (kIsWeb) return null;
    if (item.type != MediaType.pdf) return null;

    AppLogger.log('ThumbnailService: Generating PDF thumbnail for ${item.pathOrUrl}');
    
    PdfDocument? document;
    try {
      await pdfrxFlutterInitialize();
      document = await PdfDocument.openFile(item.pathOrUrl);
      if (document.pages.isEmpty) return null;

      final page = document.pages[0];
      
      // Render page to image bytes
      final pageImage = await page.render(
        width: page.width.toInt() * 2, // Double for better quality
        height: page.height.toInt() * 2,
      );

      if (pageImage != null) {
        final flutterImage = await pageImage.createImage();
        final byteData = await flutterImage.toByteData(format: ui.ImageByteFormat.png);
        
        flutterImage.dispose();
        pageImage.dispose(); // important to dispose PdfImage!

        if (byteData != null) {
          final thumbnailDir = await MediaStorageManager.getPieceMediaDirectory(musicPieceId, MediaType.thumbnails);
          if (thumbnailDir != null) {
            if (!await thumbnailDir.exists()) {
              await thumbnailDir.create(recursive: true);
            }
            final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
            await thumbnailFile.writeAsBytes(byteData.buffer.asUint8List());
            AppLogger.log('ThumbnailService: PDF thumbnail saved to ${thumbnailFile.path}');
            return thumbnailFile.path;
          }
        }
      }
    } catch (e) {
      AppLogger.log('ThumbnailService: Error generating PDF thumbnail: $e');
    } finally {
      await document?.dispose();
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

