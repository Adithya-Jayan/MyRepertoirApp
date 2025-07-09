import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/audio_player_widget.dart';
import '../screens/video_player_widget.dart';
import 'dart:io';

class MediaDisplayWidget extends StatelessWidget {
  final MediaItem mediaItem;
  final String? musicPieceTitle;
  final String? musicPieceArtist;
  final Widget? trailing;

  const MediaDisplayWidget({super.key, required this.mediaItem, this.musicPieceTitle, this.musicPieceArtist, this.trailing});

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (mediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: mediaItem.pathOrUrl);
        break;
      case MediaType.pdf:
        content = ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(pdfPath: mediaItem.pathOrUrl),
              ),
            );
          },
          child: const Text('View PDF'),
        );
        break;
      case MediaType.image:
        content = GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(imagePath: mediaItem.pathOrUrl),
              ),
            );
          },
          child: SizedBox(
            height: 200, // Fixed height for consistency
            child: Image.file(
              File(mediaItem.pathOrUrl),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
        break;
      case MediaType.audio:
        content = AudioPlayerWidget(
          audioPath: mediaItem.pathOrUrl,
          title: mediaItem.title ?? 'Unknown Title',
          artist: musicPieceArtist ?? 'Unknown Artist',
        );
        break;
      case MediaType.mediaLink:
        final Uri uri = Uri.parse(mediaItem.pathOrUrl);
        if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
          content = GestureDetector(
            onTap: () async {
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $uri';
              }
            },
            child: Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.red, // YouTube color
                  size: 50.0,
                ),
              ),
            ),
          );
        } else if (uri.host.contains('spotify.com')) {
          content = GestureDetector(
            onTap: () async {
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $uri';
              }
            },
            child: Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.green, // Spotify color
                  size: 50.0,
                ),
              ),
            ),
          );
        } else if (uri.path.endsWith('.mp4') || uri.path.endsWith('.mov') || uri.path.endsWith('.avi') || uri.path.endsWith('.mkv')) {
          // Assume it's a direct video link
          content = GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoPlayerWidget(videoPath: mediaItem.pathOrUrl),
                ),
              );
            },
            child: Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
          );
        } else {
          // General web link
          content = GestureDetector(
            onTap: () async {
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $uri';
              }
            },
            child: Container(
              height: 200,
              color: Colors.blueGrey,
              child: const Center(
                child: Icon(
                  Icons.link,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
          );
        }
        break;
      default:
        content = Text('Unsupported media type: ${mediaItem.type.name}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mediaItem.title ?? mediaItem.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  content,
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
