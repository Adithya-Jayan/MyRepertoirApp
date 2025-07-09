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

class MediaDisplayWidget extends StatefulWidget {
  final MediaItem mediaItem;
  final String? musicPieceTitle;
  final String? musicPieceArtist;
  final Widget? trailing;
  final Function(String)? onTitleChanged;
  final bool isEditable; // Added isEditable property

  const MediaDisplayWidget({
    super.key,
    required this.mediaItem,
    this.musicPieceTitle,
    this.musicPieceArtist,
    this.trailing,
    this.onTitleChanged,
    this.isEditable = false, // Default to false
  });

  @override
  State<MediaDisplayWidget> createState() => _MediaDisplayWidgetState();
}

class _MediaDisplayWidgetState extends State<MediaDisplayWidget> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mediaItem.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (widget.mediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: widget.mediaItem.pathOrUrl);
        break;
      case MediaType.pdf:
        content = ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(pdfPath: widget.mediaItem.pathOrUrl),
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
                builder: (context) => ImageViewerScreen(imagePath: widget.mediaItem.pathOrUrl),
              ),
            );
          },
          child: SizedBox(
            height: 200, // Fixed height for consistency
            child: Image.file(
              File(widget.mediaItem.pathOrUrl),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
        break;
      case MediaType.audio:
        content = AudioPlayerWidget(
          audioPath: widget.mediaItem.pathOrUrl,
          title: widget.mediaItem.title ?? 'Unknown Title',
          artist: widget.musicPieceArtist ?? 'Unknown Artist',
        );
        break;
      case MediaType.mediaLink:
        final Uri uri = Uri.parse(widget.mediaItem.pathOrUrl);
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
                  builder: (context) => VideoPlayerWidget(videoPath: widget.mediaItem.pathOrUrl),
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
        content = Text('Unsupported media type: ${widget.mediaItem.type.name}');
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
                  _isEditingTitle
                      ? TextFormField(
                          controller: _titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onFieldSubmitted: (newValue) {
                            setState(() {
                              _isEditingTitle = false;
                              widget.onTitleChanged?.call(newValue);
                            });
                          },
                          onTapOutside: (event) {
                            setState(() {
                              _isEditingTitle = false;
                              widget.onTitleChanged?.call(_titleController.text);
                            });
                          },
                        )
                      : (widget.isEditable // Use widget.isEditable here
                          ? GestureDetector(
                              onDoubleTap: () {
                                setState(() {
                                  _isEditingTitle = true;
                                });
                              },
                              child: Text(widget.mediaItem.title ?? widget.mediaItem.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            )
                          : Text(widget.mediaItem.title ?? widget.mediaItem.type.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8.0),
                  content,
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
