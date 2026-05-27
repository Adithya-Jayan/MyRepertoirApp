import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/screens/add_edit_piece_screen.dart';
import 'package:repertoire/widgets/detail_widgets/practice_tracking_card.dart';
import 'package:repertoire/widgets/detail_widgets/tag_groups_display.dart';
import 'package:repertoire/widgets/detail_widgets/groups_display.dart';
import 'package:repertoire/widgets/detail_widgets/media_display_list.dart';
import 'package:repertoire/models/media_type.dart';
import '../utils/app_logger.dart';
import 'package:repertoire/widgets/detail_widgets/collapsible_section.dart';
import 'package:repertoire/services/section_state_service.dart';
import 'package:provider/provider.dart';

class PieceDetailScreen extends StatefulWidget {
  final MusicPiece musicPiece;

  const PieceDetailScreen({super.key, required this.musicPiece});

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  late MusicPiece _musicPiece;
  final MusicPieceRepository _repository = MusicPieceRepository();

  List<String> _getSectionKeys() {
    final keys = <String>[];
    if (_musicPiece.groupIds.isNotEmpty) {
      keys.add('groups_${_musicPiece.id}');
    }
    if (_musicPiece.enablePracticeTracking) {
      keys.add('practice_tracking_${_musicPiece.id}');
    }
    if (_musicPiece.tagGroups.isNotEmpty) {
      keys.add('tag_groups_${_musicPiece.id}');
    }
    for (final item in _musicPiece.mediaItems) {
      if (item.type != MediaType.thumbnails) {
        keys.add('media_item_${item.id}');
      }
    }
    return keys;
  }

  @override
  void initState() {
    super.initState();
    _musicPiece = widget.musicPiece;
    AppLogger.log('PieceDetailScreen: initState for piece: ${_musicPiece.title} (ID: ${_musicPiece.id})');
  }

  @override
  void dispose() {
    AppLogger.log('PieceDetailScreen: dispose called');
    super.dispose();
  }

  Widget _buildHeroHeader() {
    final theme = Theme.of(context);
    final hasThumbnail = _musicPiece.thumbnailPath != null && _musicPiece.thumbnailPath!.isNotEmpty;

    return Container(
      width: double.infinity,
      // Shadow moved to outer container WITHOUT clipping
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            if (hasThumbnail)
              Positioned.fill(
                // Scale slightly to hide any clear edge artifacts from the blur
                child: Transform.scale(
                  scale: 1.05,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Image.file(
                      File(_musicPiece.thumbnailPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: hasThumbnail
                    ? theme.colorScheme.surface.withValues(alpha: 0.6)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasThumbnail)
                    Hero(
                      tag: 'piece_thumb_${_musicPiece.id}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: FileImage(File(_musicPiece.thumbnailPath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  if (hasThumbnail) const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _musicPiece.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _musicPiece.artistComposer,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('PieceDetailScreen: build called for piece: ${_musicPiece.title}');
    final stateService = Provider.of<SectionStateService>(context);
    final sectionKeys = _getSectionKeys();
    final allExpanded = sectionKeys.every((key) => stateService.isExpanded(key));

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_musicPiece.title),
          actions: [
            IconButton(
              icon: Icon(allExpanded ? Icons.unfold_less : Icons.unfold_more),
              tooltip: allExpanded ? 'Fold All' : 'Show All',
              onPressed: () {
                stateService.toggleAll(sectionKeys, !allExpanded);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await Navigator.of(context).push<bool?>(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AddEditPieceScreen(musicPiece: _musicPiece),
                  ),
                );
                if (result == true) {
                  if (!mounted) return;
                  // Refresh the music piece data
                  try {
                    final updatedPiece = await _repository.getMusicPieceById(
                      _musicPiece.id,
                    );
                    if (updatedPiece != null) {
                      setState(() {
                        _musicPiece = updatedPiece;
                      });
                    }
                  } catch (e) {
                    AppLogger.log('Error refreshing music piece: $e');
                  }
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Music piece updated successfully.'),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Music Piece'),
                        content: const Text(
                          'Are you sure you want to delete this music piece?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirmDelete == true) {
                  await _repository.deleteMusicPiece(_musicPiece.id);
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 16.0),
              if (_musicPiece.groupIds.isNotEmpty)
                CollapsibleSection(
                  title: 'Groups',
                  persistenceKey: 'groups_${_musicPiece.id}',
                  child: GroupsDisplay(musicPiece: _musicPiece, showTitle: false),
                ),
              if (_musicPiece.enablePracticeTracking)
                CollapsibleSection(
                  title: 'Practice Tracking',
                  persistenceKey: 'practice_tracking_${_musicPiece.id}',
                  child: PracticeTrackingCard(
                    musicPiece: _musicPiece,
                    onMusicPieceChanged: (updatedPiece) {
                      setState(() {
                        _musicPiece = updatedPiece;
                      });
                    },
                    showTitle: false,
                    useCard: false,
                  ),
                ),
              if (_musicPiece.tagGroups.isNotEmpty)
                CollapsibleSection(
                  title: 'Tag Groups',
                  persistenceKey: 'tag_groups_${_musicPiece.id}',
                  child: TagGroupsDisplay(
                    musicPiece: _musicPiece,
                    showTitle: false,
                  ),
                ),

              // Only show spacing if there's a top section AND there is visible media to show below it
              if ((_musicPiece.enablePracticeTracking || _musicPiece.tagGroups.isNotEmpty || _musicPiece.groupIds.isNotEmpty) && 
                  _musicPiece.mediaItems.any((item) => item.type != MediaType.thumbnails)) ...[
                const SizedBox(height: 8.0),
              ],
              MediaDisplayList(
                musicPiece: _musicPiece,
                onMusicPieceChanged: (updatedPiece) {
                  setState(() {
                    _musicPiece = updatedPiece;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
