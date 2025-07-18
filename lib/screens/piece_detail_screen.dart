import 'package:flutter/material.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/screens/add_edit_piece_screen.dart';
import 'package:repertoire/widgets/detail_widgets/practice_tracking_card.dart';
import 'package:repertoire/widgets/detail_widgets/tag_groups_display.dart';
import 'package:repertoire/widgets/detail_widgets/media_display_list.dart';
import '../utils/app_logger.dart';

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

  @override
  void dispose() {
    AppLogger.log('PieceDetailScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('PieceDetailScreen: build called');
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Practice tracking updated.')),
                );
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
                  Navigator.of(context).pop();
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
            PracticeTrackingCard(
              musicPiece: _musicPiece,
              onMusicPieceChanged: (updatedPiece) {
                setState(() {
                  _musicPiece = updatedPiece;
                });
              },
            ),
            if (_musicPiece.tagGroups.isNotEmpty)
              TagGroupsDisplay(musicPiece: _musicPiece),
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
    );
  }
}