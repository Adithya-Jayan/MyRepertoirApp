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
  final bool isEditable;

  const MediaDisplayWidget({
    super.key,
    required this.mediaItem,
    this.musicPieceTitle,
    this.musicPieceArtist,
    this.trailing,
    this.onTitleChanged,
    this.isEditable = false,
  });

  @override
  State<MediaDisplayWidget> createState() => _MediaDisplayWidgetState();
}

class _MediaDisplayWidgetState extends State<MediaDisplayWidget> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  late FocusNode _focusNode;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    debugPrint('MediaDisplayWidgetState: initState');
    _currentTitle = widget.mediaItem.title;
    _titleController = TextEditingController(text: _currentTitle);
    _focusNode = FocusNode();
    
    
  }

  @override
  void didUpdateWidget(MediaDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('MediaDisplayWidgetState: didUpdateWidget');
    
    // Only update if we're not currently editing and the title actually changed
    if (!_isEditingTitle && widget.mediaItem.title != _currentTitle) {
      debugPrint('MediaDisplayWidgetState: Updating title from widget.mediaItem.title');
      _currentTitle = widget.mediaItem.title;
      _titleController.text = _currentTitle ?? '';
    }
  }

  @override
  void dispose() {
    debugPrint('MediaDisplayWidgetState: dispose');
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveTitle() {
    debugPrint('MediaDisplayWidgetState: _saveTitle');
    final newTitle = _titleController.text;
    setState(() {
      _isEditingTitle = false;
      _currentTitle = newTitle;
    });
    
    // Only call the callback if the title actually changed
    if (newTitle != widget.mediaItem.title) {
      debugPrint('MediaDisplayWidgetState: Title changed, calling onTitleChanged');
      widget.onTitleChanged?.call(newTitle);
    }
  }

  void _startEditing() {
    debugPrint('MediaDisplayWidgetState: _startEditing');
    setState(() {
      _isEditingTitle = true;
    });
    
    // Use a post-frame callback to ensure the widget is built before requesting focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) {
        debugPrint('MediaDisplayWidgetState: Requesting focus');
        _focusNode.requestFocus();
        // Select all text when starting to edit
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MediaDisplayWidgetState: build');
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
            height: 200,
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
                  color: Colors.red,
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
                  color: Colors.green,
                  size: 50.0,
                ),
              ),
            ),
          );
        } else if (uri.path.endsWith('.mp4') || uri.path.endsWith('.mov') || uri.path.endsWith('.avi') || uri.path.endsWith('.mkv')) {
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
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (newValue) {
                            _saveTitle();
                          },
                          onEditingComplete: () {
                            _saveTitle();
                          },
                        )
                      : (widget.isEditable
                          ? GestureDetector(
                              onDoubleTap: _startEditing,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  _currentTitle ?? widget.mediaItem.type.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Text(
                              _currentTitle ?? widget.mediaItem.type.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
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