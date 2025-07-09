import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/screens/add_edit_piece_screen.dart';
import 'package:repertoire/utils/color_utils.dart';
import 'package:repertoire/widgets/media_display_widget.dart';

class PieceDetailScreen extends StatefulWidget {
  final MusicPiece musicPiece;

  const PieceDetailScreen({super.key, required this.musicPiece});

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  late MusicPiece _musicPiece;
  final MusicPieceRepository _repository = MusicPieceRepository();

  @override
  void initState() {
    super.initState();
    _musicPiece = widget.musicPiece;
  }

  String _formatLastPracticeTime(DateTime? lastPracticeTime) {
    if (lastPracticeTime == null) {
      return 'Never practiced';
    }
    final now = DateTime.now();
    final difference = now.difference(lastPracticeTime);

    if (difference.inDays == 0) {
      return 'Last practiced: Today';
    } else if (difference.inDays == 1) {
      return 'Last practiced: Yesterday';
    } else if (difference.inDays < 30) {
      return 'Last practiced: ${difference.inDays} days ago';
    } else {
      return 'Last practiced: ${lastPracticeTime.toLocal().toString().split(' ')[0]}';
    }
  }

  Future<void> _logPractice() async {
    setState(() {
      _musicPiece = _musicPiece.copyWith(
        lastPracticeTime: DateTime.now(),
        practiceCount: _musicPiece.practiceCount + 1,
      );
    });
    await _repository.updateMusicPiece(_musicPiece);
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: Text(_musicPiece.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool?>(
                MaterialPageRoute(
                  builder: (context) => AddEditPieceScreen(musicPiece: _musicPiece),
                ),
              );
              if (result == true) {
                // Reload the music piece from the database to get the latest data
                final updatedPiece = (await _repository.getMusicPieces()).firstWhere((piece) => piece.id == _musicPiece.id);
                setState(() {
                  _musicPiece = updatedPiece;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Music Piece'),
                  content: const Text('Are you sure you want to delete this music piece?'),
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
                  Navigator.of(context).pop(); // Go back to previous screen after deletion
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
            Text(
              _musicPiece.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              _musicPiece.artistComposer,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),

            // Practice Tracking Section
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Tracking',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SwitchListTile(
                      title: const Text('Enable Practice Tracking'),
                      value: _musicPiece.enablePracticeTracking,
                      onChanged: (bool value) async {
                        setState(() {
                          _musicPiece = _musicPiece.copyWith(enablePracticeTracking: value);
                        });
                        await _repository.updateMusicPiece(_musicPiece);
                      },
                    ),
                    if (_musicPiece.enablePracticeTracking)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatLastPracticeTime(_musicPiece.lastPracticeTime)),
                          Text('Practice Count: ${_musicPiece.practiceCount}'),
                          ElevatedButton(
                            onPressed: _logPractice,
                            child: const Text('Log Practice'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Ordered Tags Section
            if (_musicPiece.tagGroups.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tag Groups:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ..._musicPiece.tagGroups.map((tagGroup) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tagGroup.name}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: tagGroup.tags.map((tag) {
                                final color = tagGroup.color != null ? Color(tagGroup.color!) : null;
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),

            // Media Section
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8.0),
                    ReorderableListView.builder(
                      buildDefaultDragHandles: false, // Disable default handles
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // to allow SingleChildScrollView to work
                      itemCount: _musicPiece.mediaItems.length,
                      itemBuilder: (context, index) {
                        final item = _musicPiece.mediaItems[index];
                        return MediaDisplayWidget(
                          key: ValueKey(item.id),
                          mediaItem: item,
                          musicPieceTitle: _musicPiece.title,
                          musicPieceArtist: _musicPiece.artistComposer,
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _musicPiece.mediaItems.removeAt(oldIndex);
                          _musicPiece.mediaItems.insert(newIndex, item);
                          // Persist the new order to the database
                          _repository.updateMusicPiece(_musicPiece);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}