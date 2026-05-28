import 'package:flutter/material.dart';
import 'package:repertoire/models/media_item.dart';
import 'package:repertoire/models/media_type.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import 'package:repertoire/services/thumbnail_service.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/models/learning_progress_config.dart';
import 'package:repertoire/widgets/add_edit_piece/learning_progress_config_dialog.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:repertoire/models/midi_track_config.dart';
import 'package:repertoire/widgets/add_edit_piece/midi_track_config_dialog.dart';
import 'package:repertoire/models/pdf_config.dart';
import 'package:repertoire/widgets/add_edit_piece/pdf_config_dialog.dart';

/// A widget for displaying and editing a single MediaItem.
///
/// Allows users to modify the media item's title, path/URL, and set it as a thumbnail.
class MediaSection extends StatefulWidget {
  final MediaItem item;
  final int index;
  final int globalIndex;
  final String musicPieceThumbnail;
  final String musicPieceId;
  final Function(MediaItem) onUpdateMediaItem;
  final Function(MediaItem) onDeleteMediaItem;
  final Function(String) onSetThumbnail;
  final MusicPiece musicPiece;
  final bool isReorderable;
  final bool showExternalDelete;
  final bool isTitleEditable;
  final bool isPathEditable;

  const MediaSection({
    super.key,
    required this.item,
    required this.index,
    required this.globalIndex,
    required this.musicPieceThumbnail,
    required this.musicPieceId,
    required this.onUpdateMediaItem,
    required this.onDeleteMediaItem,
    required this.onSetThumbnail,
    required this.musicPiece,
    this.isReorderable = true,
    this.showExternalDelete = true,
    this.isTitleEditable = true,
    this.isPathEditable = true,
  });

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  bool _isLoadingThumbnail = false;
  String? _currentThumbnailPath;

  @override
  void initState() {
    super.initState();
    _currentThumbnailPath = widget.item.thumbnailPath;
  }

  @override
  void didUpdateWidget(MediaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.thumbnailPath != widget.item.thumbnailPath) {
      setState(() {
        _currentThumbnailPath = widget.item.thumbnailPath;
      });
    }
  }

  Future<void> _fetchThumbnail() async {
    if (widget.item.pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL is empty')),
      );
      return;
    }

    AppLogger.log('MediaSection: Fetching thumbnail for URL: ${widget.item.pathOrUrl}');
    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      final thumbnailPath = await ThumbnailService.fetchAndSaveThumbnail(widget.item, widget.musicPieceId);
      
      if (thumbnailPath != null && mounted) {
        setState(() {
          _currentThumbnailPath = thumbnailPath;
          _isLoadingThumbnail = false;
        });
        
        final updatedItem = widget.item.copyWith(thumbnailPath: thumbnailPath);
        widget.onUpdateMediaItem(updatedItem);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail fetched successfully!')),
        );
      } else if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch thumbnail.')),
        );
      }
    } catch (e) {
      AppLogger.log('Error fetching thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching thumbnail: $e')),
        );
      }
    }
  }

  Future<void> _generateVideoThumbnail() async {
    if (widget.item.pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video file path is empty')),
      );
      return;
    }

    AppLogger.log('MediaSection: Generating thumbnail for video: ${widget.item.pathOrUrl}');
    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      final thumbnailPath = await ThumbnailService.generateVideoThumbnail(widget.item, widget.musicPieceId);
      
      if (thumbnailPath != null && mounted) {
        setState(() {
          _currentThumbnailPath = thumbnailPath;
          _isLoadingThumbnail = false;
        });
        
        final updatedItem = widget.item.copyWith(thumbnailPath: thumbnailPath);
        widget.onUpdateMediaItem(updatedItem);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video thumbnail generated successfully!')),
        );
      } else if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate video thumbnail.')),
        );
      }
    } catch (e) {
      AppLogger.log('Error generating video thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating thumbnail: $e')),
        );
      }
    }
  }

  void _removeThumbnail() {
    AppLogger.log('MediaSection: _removeThumbnail called for item: ${widget.item.title}');
    
    if (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) {
      try {
        final file = File(_currentThumbnailPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        AppLogger.log('Error deleting thumbnail file: $e');
      }
    }

    if (widget.musicPieceThumbnail == _currentThumbnailPath) {
      widget.onSetThumbnail('');
    }

    final updatedItem = widget.item.copyWith(thumbnailPath: '');
    widget.onUpdateMediaItem(updatedItem);

    setState(() {
      _currentThumbnailPath = '';
    });
  }

  void _deleteMediaItem() {
    if (_currentThumbnailPath != null) {
      try {
        final file = File(_currentThumbnailPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        AppLogger.log('Error deleting thumbnail file: $e');
      }
    }
    widget.onDeleteMediaItem(widget.item);
  }

  Future<void> _pickAndChangeImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        
        final appDir = await getApplicationDocumentsDirectory();
        final pieceMediaDir = Directory(p.join(appDir.path, 'media', widget.musicPieceId));
        if (!await pieceMediaDir.exists()) {
          await pieceMediaDir.create(recursive: true);
        }
        
        final extension = p.extension(sourcePath);
        final newFileName = 'thumbnail_${const Uuid().v4()}$extension';
        final newFilePath = p.join(pieceMediaDir.path, newFileName);
        
        await File(sourcePath).copy(newFilePath);
        
        final updatedItem = widget.item.copyWith(pathOrUrl: newFilePath);
        widget.onUpdateMediaItem(updatedItem);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image updated successfully')),
          );
        }
      }
    } catch (e) {
      AppLogger.log('MediaSection: Error changing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('MediaSection: build called for item: ${widget.item.title}, _currentThumbnailPath: "$_currentThumbnailPath"');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section: Title & Renaming
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: MediaDisplayWidget(
            musicPiece: widget.musicPiece,
            mediaItemIndex: widget.globalIndex,
            isEditable: widget.isTitleEditable, // Use the new flag
            onTitleChanged: (newTitle) {
              widget.onUpdateMediaItem(widget.item.copyWith(title: newTitle));
            },
            onMediaItemChanged: (newItem) {
              widget.onUpdateMediaItem(newItem);
            },
          ),
        ),
        
        if (widget.isPathEditable) ...[ // Wrap path section with flag check
          const SizedBox(height: 12),
          
          // Middle Section: Content Configuration
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.item.type == MediaType.learningProgress)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Progress Bar'),
                    onPressed: () async {
                       final currentConfig = LearningProgressConfig.decode(widget.item.pathOrUrl);
                       final newConfig = await showDialog<LearningProgressConfig>(
                          context: context,
                          builder: (context) => LearningProgressConfigDialog(initialConfig: currentConfig),
                       );
                       if (newConfig != null) {
                          widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: LearningProgressConfig.encode(newConfig)));
                       }
                    },
                  )
                else if (widget.item.type == MediaType.midi)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure MIDI Tracks'),
                    onPressed: () async {
                       final currentConfig = MidiTrackConfig.fromJson(widget.item.configData ?? '{}');
                       final newConfig = await showDialog<MidiTrackConfig>(
                          context: context,
                          builder: (context) => MidiTrackConfigDialog(
                            midiPath: widget.item.pathOrUrl,
                            initialConfig: currentConfig,
                          ),
                       );
                       if (newConfig != null) {
                          widget.onUpdateMediaItem(widget.item.copyWith(configData: newConfig.toJson()));
                       }
                    },
                  )
                else if (widget.item.type == MediaType.pdf)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Auto Scroll'),
                    onPressed: () async {
                       final currentConfig = PdfConfig.fromJson(widget.item.configData ?? '{}');
                       final newConfig = await showDialog<PdfConfig>(
                          context: context,
                          builder: (context) => PdfConfigDialog(initialConfig: currentConfig),
                       );
                       if (newConfig != null) {
                          widget.onUpdateMediaItem(widget.item.copyWith(configData: newConfig.toJson()));
                       }
                    },
                  )
                else if (widget.item.type == MediaType.markdown)
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: const InputDecoration(
                      labelText: 'Markdown Content',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 5,
                    onChanged: (value) => widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: value)),
                  )
                else
                  TextFormField(
                    initialValue: widget.item.pathOrUrl,
                    decoration: const InputDecoration(
                      labelText: 'Path or URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => widget.onUpdateMediaItem(widget.item.copyWith(pathOrUrl: value)),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Bottom Section: Secondary Actions (Thumbnails)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (widget.item.type == MediaType.mediaLink || widget.item.type == MediaType.localVideo)
                _isLoadingThumbnail
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Fetching...', style: TextStyle(fontSize: 12)),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty)
                            ? () => _removeThumbnail()
                            : () => widget.item.type == MediaType.mediaLink ? _fetchThumbnail() : _generateVideoThumbnail(),
                        icon: Icon((_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) ? Icons.delete : Icons.image, size: 18),
                        label: Text(
                          (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty) ? 'Remove Thumbnail' : (widget.item.type == MediaType.mediaLink ? 'Get link thumbnail' : 'Get video thumbnail'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty)
                            ? OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(color: Colors.red[200]!),
                              )
                            : null,
                      ),
              if (widget.item.type == MediaType.thumbnails)
                OutlinedButton.icon(
                  onPressed: _pickAndChangeImage,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Change Image', style: TextStyle(fontSize: 12)),
                ),
              if ((widget.item.type == MediaType.image || widget.item.type == MediaType.localVideo || (_currentThumbnailPath != null && _currentThumbnailPath!.isNotEmpty)) && widget.item.type != MediaType.thumbnails)
                OutlinedButton.icon(
                  onPressed: () {
                    final isCurrentlyThumbnail = widget.musicPieceThumbnail.isNotEmpty && 
                           (widget.musicPieceThumbnail == widget.item.pathOrUrl || 
                            widget.musicPieceThumbnail == _currentThumbnailPath);
                    
                    if (isCurrentlyThumbnail) {
                      widget.onSetThumbnail('');
                    } else {
                      String? path;
                      if (widget.item.type == MediaType.image) {
                        path = widget.item.pathOrUrl;
                      } else if (widget.item.type == MediaType.localVideo || widget.item.type == MediaType.mediaLink) {
                        path = _currentThumbnailPath;
                      }
                      
                      if (path != null && path.isNotEmpty) {
                        widget.onSetThumbnail(path);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please generate a thumbnail first.')),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    (widget.musicPieceThumbnail.isNotEmpty && 
                     (widget.musicPieceThumbnail == widget.item.pathOrUrl || 
                      widget.musicPieceThumbnail == _currentThumbnailPath))
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                  ),
                  label: Text(
                    (widget.musicPieceThumbnail.isNotEmpty && 
                     (widget.musicPieceThumbnail == widget.item.pathOrUrl || 
                      widget.musicPieceThumbnail == _currentThumbnailPath))
                        ? 'Is Piece Thumbnail'
                        : 'Set as Piece Thumbnail',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: (widget.musicPieceThumbnail.isNotEmpty && 
                          (widget.musicPieceThumbnail == widget.item.pathOrUrl || 
                           widget.musicPieceThumbnail == _currentThumbnailPath))
                      ? OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[800],
                          side: BorderSide(color: Colors.amber[200]!),
                        )
                      : null,
                ),
            ],
          ),
        ),

        if (widget.showExternalDelete) ...[
          const Divider(height: 24),
          Row(
            children: [
              if (widget.isReorderable)
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.delete, size: 20),
                label: const Text('Delete Item'),
                onPressed: () => _deleteMediaItem(),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
