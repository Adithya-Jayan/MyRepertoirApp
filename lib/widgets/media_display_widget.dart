import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/audio_player_widget.dart';
import '../screens/video_player_widget.dart';
import '../screens/midi_player_widget.dart'
    if (dart.library.html) '../screens/midi_player_widget_web.dart';
import 'dart:io' as io;
import 'package:repertoire/models/pdf_config.dart';

class MediaDisplayWidget extends StatefulWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  final Widget? trailing;
  final Function(MediaItem)? onMediaItemChanged;
  final Function(String)? onTitleChanged; // Added back for compatibility
  final bool isEditable;
  final bool showTitle;

  const MediaDisplayWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
    this.trailing,
    this.onMediaItemChanged,
    this.onTitleChanged,
    this.isEditable = false,
    this.showTitle = true,
  });

  @override
  State<MediaDisplayWidget> createState() => _MediaDisplayWidgetState();
}

class _MediaDisplayWidgetState extends State<MediaDisplayWidget> {
  Future<void> _shareMediaItem(MediaType type, String pathOrUrl, Rect? shareOrigin) async {
    try {
      ShareParams? params;
      
      switch (type) {
        case MediaType.mediaLink:
        case MediaType.markdown:
          params = ShareParams(
            text: pathOrUrl,
            sharePositionOrigin: shareOrigin,
          );
          break;
        case MediaType.audio:
        case MediaType.image:
        case MediaType.pdf:
        case MediaType.localVideo:
        case MediaType.midi:
          if (kIsWeb) {
             params = ShareParams(
               text: pathOrUrl,
               sharePositionOrigin: shareOrigin,
             );
          } else {
            final file = io.File(pathOrUrl);
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

  void _deleteMediaItem(BuildContext context, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Deletion is typically handled by the parent list widget.
      // In the piece detail view, deletion is a secondary action.
      // The parent should be notified to update the music piece.
      // For now, we print a log as the deletion callback in this card is ambiguous.
      debugPrint('Deletion requested for media at index $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];

    if (currentMediaItem.type == MediaType.thumbnails && !widget.isEditable) {
      return const SizedBox.shrink();
    }

    IconData getMediaTypeIcon(MediaType type) {
      switch (type) {
        case MediaType.pdf: return Icons.picture_as_pdf_outlined;
        case MediaType.audio: return Icons.audiotrack_outlined;
        case MediaType.localVideo: return Icons.videocam_outlined;
        case MediaType.mediaLink: return Icons.link_rounded;
        case MediaType.image: return Icons.image_outlined;
        case MediaType.markdown: return Icons.notes_rounded;
        case MediaType.midi: return Icons.music_note_outlined;
        case MediaType.learningProgress: return Icons.trending_up_rounded;
        default: return Icons.insert_drive_file_outlined;
      }
    }

    final bool showActions = !widget.isEditable && 
                            currentMediaItem.type != MediaType.thumbnails;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMedia(context),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    getMediaTypeIcon(currentMediaItem.type),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMediaItem.title ?? currentMediaItem.type.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentMediaItem.type.toString().split('.').last.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActions)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'share') {
                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                        final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                        _shareMediaItem(currentMediaItem.type, currentMediaItem.pathOrUrl, rect);
                      } else if (value == 'delete') {
                        _deleteMediaItem(context, widget.mediaItemIndex);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share_outlined, size: 20),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMedia(BuildContext context) {
    final currentMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
    
    switch (currentMediaItem.type) {
      case MediaType.pdf:
        final pdfConfig = PdfConfig.fromJson(currentMediaItem.configData ?? '{}');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfPath: currentMediaItem.pathOrUrl,
              config: pdfConfig,
            ),
          ),
        );
        break;
      case MediaType.image:
      case MediaType.thumbnails:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(imagePath: currentMediaItem.pathOrUrl),
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
        launchUrl(Uri.parse(currentMediaItem.pathOrUrl), mode: LaunchMode.externalApplication);
        break;
      default:
        break;
    }
  }
}
