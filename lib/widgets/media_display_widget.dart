import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/learning_progress_config.dart';
import 'package:repertoire/widgets/learning_progress_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/audio_player_widget.dart';
import '../screens/video_player_widget.dart';
import '../screens/midi_player_widget.dart'
    if (dart.library.html) '../screens/midi_player_widget_web.dart';
import 'dart:io' as io;
import '../utils/app_logger.dart';
import 'package:repertoire/models/pdf_config.dart';

import 'package:repertoire/l10n/l10n.dart';

class MediaDisplayWidget extends StatefulWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  final Widget? trailing;
  final Function(MediaItem)? onMediaItemChanged;
  final Function(String)? onTitleChanged;
  final bool isEditable;
  final bool isTitleEditable;
  final bool showTitle;

  const MediaDisplayWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
    this.trailing,
    this.onMediaItemChanged,
    this.onTitleChanged,
    this.isEditable = false,
    this.isTitleEditable = false,
    this.showTitle = true,
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
          _titleController.text = _currentTitle ?? '';
        });
      }
    });
  }

  @override
  void didUpdateWidget(MediaDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
    if (!_isEditingTitle && newMediaItem.title != _currentTitle) {
      _currentTitle = newMediaItem.title;
      _titleController.text = _currentTitle ?? '';
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

    if (newTitle != widget.musicPiece.mediaItems[widget.mediaItemIndex].title) {
      if (widget.onTitleChanged != null) {
        widget.onTitleChanged!(newTitle);
      } else if (widget.onMediaItemChanged != null) {
        final updatedItem = widget.musicPiece.mediaItems[widget.mediaItemIndex]
            .copyWith(title: newTitle);
        widget.onMediaItemChanged!(updatedItem);
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditingTitle = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
      }
    });
  }

  Widget buildFileImage(
    String path, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
  }) {
    final file = io.File(path);
    return FutureBuilder<DateTime>(
      future: file.lastModified(),
      builder: (context, snapshot) {
        return Image.file(
          file,
          key: ValueKey(
            '${path}_${snapshot.data?.millisecondsSinceEpoch ?? 0}',
          ),
          height: height,
          width: width,
          fit: fit,
          // Limit the resolution in memory to prevent lag from huge images
          cacheWidth: 400,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.log(
              'MediaDisplayWidget: Error loading image file ($path): $error',
            );
            return Container(
              height: height ?? 200,
              width: width,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMediaItem =
        widget.musicPiece.mediaItems[widget.mediaItemIndex];

    if (currentMediaItem.type == MediaType.thumbnails && !widget.isEditable) {
      return const SizedBox.shrink();
    }

    Widget content;
    switch (currentMediaItem.type) {
      case MediaType.markdown:
        content = MarkdownBody(data: currentMediaItem.pathOrUrl);
        break;
      case MediaType.pdf:
        content = Center(
          child: FilledButton.icon(
            onPressed: () => _openMedia(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(context.l10n.viewPdf),
          ),
        );
        break;
      case MediaType.image:
      case MediaType.thumbnails:
        content = GestureDetector(
          onTap: () => _openMedia(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: kIsWeb
                  ? Image.network(currentMediaItem.pathOrUrl, fit: BoxFit.cover)
                  : buildFileImage(
                      currentMediaItem.pathOrUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        );
        break;
      case MediaType.localVideo:
        content = VideoPlayerWidget(
          musicPiece: widget.musicPiece,
          mediaItemIndex: widget.mediaItemIndex,
        );
        break;
      case MediaType.midi:
        content = MidiPlayerWidget(
          musicPiece: widget.musicPiece,
          mediaItemIndex: widget.mediaItemIndex,
          onMediaItemChanged: widget.onMediaItemChanged,
        );
        break;
      case MediaType.audio:
        if (widget.isEditable) {
          content = Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 40, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(context.l10n.audioFile, style: theme.textTheme.labelLarge),
              ],
            ),
          );
        } else {
          content = AudioPlayerWidget(
            musicPiece: widget.musicPiece,
            mediaItemIndex: widget.mediaItemIndex,
          );
        }
        break;
      case MediaType.mediaLink:
        final hasThumbnail =
            currentMediaItem.thumbnailPath != null &&
            currentMediaItem.thumbnailPath!.isNotEmpty;
        content = GestureDetector(
          onTap: () => _openMedia(context),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: hasThumbnail
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: kIsWeb
                        ? Image.network(
                            currentMediaItem.thumbnailPath!,
                            fit: BoxFit.cover,
                          )
                        : buildFileImage(
                            currentMediaItem.thumbnailPath!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 40, color: colorScheme.secondary),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.openLink,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
          ),
        );
        break;
      case MediaType.learningProgress:
        final config = LearningProgressConfig.decode(
          currentMediaItem.pathOrUrl,
        );
        content = LearningProgressWidget(
          config: config,
          isEditable: !widget.isEditable,
          onProgressChanged: (newProgress) {
            final newConfig = config.copyWith(current: newProgress);
            final updatedItem = currentMediaItem.copyWith(
              pathOrUrl: LearningProgressConfig.encode(newConfig),
            );
            widget.onMediaItemChanged?.call(updatedItem);
          },
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((widget.isEditable || widget.isTitleEditable) &&
            currentMediaItem.type != MediaType.thumbnails) ...[
          _isEditingTitle
              ? TextFormField(
                  controller: _titleController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    labelText: context.l10n.mediaName,
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _saveTitle(),
                )
              : InkWell(
                  onTap: _startEditing,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.renameMedia(
                              _currentTitle ??
                                  currentMediaItem.type.localizedName(
                                    context.l10n,
                                  ),
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.tapToEdit,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),
        ],
        content,
      ],
    );
  }

  void _openMedia(BuildContext context) {
    final currentMediaItem =
        widget.musicPiece.mediaItems[widget.mediaItemIndex];
    switch (currentMediaItem.type) {
      case MediaType.pdf:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfPath: currentMediaItem.pathOrUrl,
              config: PdfConfig.fromJson(currentMediaItem.configData ?? '{}'),
            ),
          ),
        );
        break;
      case MediaType.image:
      case MediaType.thumbnails:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ImageViewerScreen(imagePath: currentMediaItem.pathOrUrl),
          ),
        );
        break;
      case MediaType.localVideo:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerWidget(
              musicPiece: widget.musicPiece,
              mediaItemIndex: widget.mediaItemIndex,
            ),
          ),
        );
        break;
      case MediaType.audio:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AudioPlayerWidget(
              musicPiece: widget.musicPiece,
              mediaItemIndex: widget.mediaItemIndex,
            ),
          ),
        );
        break;
      case MediaType.midi:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MidiPlayerWidget(
              musicPiece: widget.musicPiece,
              mediaItemIndex: widget.mediaItemIndex,
              onMediaItemChanged: widget.onMediaItemChanged,
            ),
          ),
        );
        break;
      case MediaType.mediaLink:
        launchUrl(
          Uri.parse(currentMediaItem.pathOrUrl),
          mode: LaunchMode.externalApplication,
        );
        break;
      default:
        break;
    }
  }
}
