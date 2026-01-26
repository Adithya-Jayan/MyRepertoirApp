import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart'; // Added this import
import 'package:repertoire/models/media_item.dart'; // Added for MediaItem
import 'package:repertoire/models/learning_progress_config.dart'; // Added import
import 'package:repertoire/widgets/learning_progress_widget.dart'; // Added import
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/audio_player_widget.dart';
import '../screens/video_player_widget.dart';
import 'dart:io';

class MediaDisplayWidget extends StatefulWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  final Widget? trailing;
  final Function(String)? onTitleChanged;
  final Function(MediaItem)? onMediaItemChanged; // Added callback
  final bool isEditable;
  final bool isTitleEditable;

  const MediaDisplayWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
    this.trailing,
    this.onTitleChanged,
    this.onMediaItemChanged,
    this.isEditable = false,
    this.isTitleEditable = false,
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
    _currentTitle = widget.musicPiece.mediaItems[widget.mediaItemIndex].title;
    _titleController = TextEditingController(text: _currentTitle);
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditingTitle) {
        setState(() {
          _isEditingTitle = false;
          _titleController.text = _currentTitle ?? ''; // Revert to original title
        });
      }
    });
  }

  @override
  void didUpdateWidget(MediaDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
    final oldMediaItem = oldWidget.musicPiece.mediaItems[oldWidget.mediaItemIndex];
    
    // Only update if we're not currently editing and the title actually changed
    if (!_isEditingTitle && newMediaItem.title != _currentTitle) {
      _currentTitle = newMediaItem.title;
      _titleController.text = _currentTitle ?? '';
    }
    
    // Force rebuild if thumbnail path changed
    if (oldMediaItem.thumbnailPath != newMediaItem.thumbnailPath) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final newTitle = _titleController.text;
    setState(() {
      _isEditingTitle = false;
      _currentTitle = newTitle;
    });
    
    // Only call the callback if the title actually changed
    if (newTitle != widget.musicPiece.mediaItems[widget.mediaItemIndex].title) {
      if (widget.onTitleChanged != null) {
        widget.onTitleChanged!(newTitle);
      } else if (widget.onMediaItemChanged != null) {
        final updatedItem = widget.musicPiece.mediaItems[widget.mediaItemIndex].copyWith(title: newTitle);
        widget.onMediaItemChanged!(updatedItem);
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditingTitle = true;
    });
    
    // Use a post-frame callback to ensure the widget is built before requesting focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
        // Select all text when starting to edit
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
      }
    });
  }

  Future<void> _shareMediaItem(MediaType type, String pathOrUrl, Rect? shareOrigin) async {
    try {
      ShareParams? params;
      
      switch (type) {
        case MediaType.mediaLink:
        case MediaType.markdown:
          // Share the link or markdown content as text
          params = ShareParams(
            text: pathOrUrl,
            sharePositionOrigin: shareOrigin,
          );
          break;
        case MediaType.audio:
        case MediaType.image:
        case MediaType.pdf:
        case MediaType.localVideo:
          // Verify file exists before sharing
          final file = File(pathOrUrl);
          if (await file.exists()) {
            params = ShareParams(
              files: [XFile(pathOrUrl)],
              sharePositionOrigin: shareOrigin,
            );
          } else {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('File not found to share.')),
               );
             }
             return;
          }
          break;
        default:
          return;
      }
      
      await SharePlus.instance.share(params);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];

    // Hide thumbnail widgets in non-editable (view) mode completely
    if (currentMediaItem.type == MediaType.thumbnails && !widget.isEditable) {
      return const SizedBox.shrink();
    }

    Widget content;

    switch (currentMediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: currentMediaItem.pathOrUrl);
        break;
      case MediaType.pdf:
        content = ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(pdfPath: currentMediaItem.pathOrUrl),
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
                builder: (context) => ImageViewerScreen(imagePath: currentMediaItem.pathOrUrl),
              ),
            );
          },
          child: SizedBox(
            height: 200,
            child: Image.file(
              File(currentMediaItem.pathOrUrl),
              fit: BoxFit.contain, // Maintain aspect ratio within the bounds
            ),
          ),
        );
        break;
      case MediaType.localVideo:
        if (widget.isEditable) {
          content = FutureBuilder<bool>(
            future: File(currentMediaItem.pathOrUrl).exists(),
            builder: (context, snapshot) {
              final fileExists = snapshot.data ?? false;
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: fileExists ? Colors.grey[100] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: fileExists ? Colors.grey[300]! : Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      fileExists ? Icons.video_file : Icons.error_outline,
                      color: fileExists ? Colors.blue[600] : Colors.red[600],
                      size: 32.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video File',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            fileExists 
                              ? 'File loaded'
                              : 'Video file not found',
                            style: TextStyle(
                              color: fileExists ? Colors.grey[600] : Colors.red[600],
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          content = VideoPlayerWidget(videoPath: currentMediaItem.pathOrUrl);
        }
        break;
      case MediaType.audio:
        if (widget.isEditable) {
          // In edit mode, show a simple file status instead of full audio player
          content = FutureBuilder<bool>(
            future: File(currentMediaItem.pathOrUrl).exists(),
            builder: (context, snapshot) {
              final fileExists = snapshot.data ?? false;
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: fileExists ? Colors.grey[100] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: fileExists ? Colors.grey[300]! : Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      fileExists ? Icons.audio_file : Icons.error_outline,
                      color: fileExists ? Colors.blue[600] : Colors.red[600],
                      size: 32.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Audio File',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            fileExists 
                              ? 'File loaded and ready for playback'
                              : 'Audio file not found',
                            style: TextStyle(
                              color: fileExists ? Colors.grey[600] : Colors.red[600],
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          // In view mode, use the full audio player
          content = AudioPlayerWidget(
            musicPiece: widget.musicPiece, // Pass the entire musicPiece
            mediaItemIndex: widget.mediaItemIndex, // Pass the index
          );
        }
        break;
      case MediaType.mediaLink:
        final Uri uri = Uri.parse(currentMediaItem.pathOrUrl);
        content = GestureDetector(
          onTap: () async {
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              throw 'Could not launch $uri';
            }
          },
          child: (currentMediaItem.thumbnailPath != null &&
                  currentMediaItem.thumbnailPath!.isNotEmpty &&
                  currentMediaItem.thumbnailPath != '')
              ? Image.file(
                  File(currentMediaItem.thumbnailPath!),
                  height: 200,
                  fit: BoxFit.contain,
                )
              : Container(
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
        break;
      case MediaType.learningProgress:
        final config = LearningProgressConfig.decode(currentMediaItem.pathOrUrl);
        content = LearningProgressWidget(
          config: config,
          isEditable: !widget.isEditable, // Can update progress only in View mode (not Edit Piece mode)
          onProgressChanged: (newProgress) {
            final newConfig = config.copyWith(current: newProgress);
            final updatedItem = currentMediaItem.copyWith(
              pathOrUrl: LearningProgressConfig.encode(newConfig),
            );
            widget.onMediaItemChanged?.call(updatedItem);
          },
        );
        break;
      case MediaType.thumbnails:
        content = GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(imagePath: currentMediaItem.pathOrUrl),
              ),
            );
          },
          child: SizedBox(
            height: 200,
            child: Image.file(
              File(currentMediaItem.pathOrUrl),
              fit: BoxFit.contain, // Maintain aspect ratio within the bounds
            ),
          ),
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align top to handle different content heights
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
                      : ((widget.isTitleEditable || widget.isEditable)
                          ? GestureDetector(
                              onDoubleTap: _startEditing,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _currentTitle ?? currentMediaItem.type.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Text(
                                      '(Double tap to edit)',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
                              _currentTitle ?? currentMediaItem.type.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                  const SizedBox(height: 8.0),
                  content,
                ],
              ),
            ),
            if (!widget.isEditable && currentMediaItem.type != MediaType.thumbnails && currentMediaItem.type != MediaType.learningProgress)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share',
                  onPressed: () {
                    final box = ctx.findRenderObject() as RenderBox?;
                    final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                    _shareMediaItem(currentMediaItem.type, currentMediaItem.pathOrUrl, rect);
                  },
                ),
              ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
