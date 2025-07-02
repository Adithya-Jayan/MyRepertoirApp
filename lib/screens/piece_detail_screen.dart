import 'dart:io';
import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import './add_edit_piece_screen.dart';
import './pdf_viewer_screen.dart';
import './image_viewer_screen.dart';
import './audio_player_widget.dart';
import './video_player_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class PieceDetailScreen extends StatefulWidget {
  final MusicPiece musicPiece;

  const PieceDetailScreen({super.key, required this.musicPiece});

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  late MusicPiece _currentMusicPiece;

  @override
  void initState() {
    super.initState();
    _currentMusicPiece = widget.musicPiece;
  }

  void _logPractice() {
    setState(() {
      _currentMusicPiece.lastPracticeTime = DateTime.now();
      _currentMusicPiece.practiceCount++;
      // TODO: Update the music piece in the database
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMusicPiece.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedPiece = await Navigator.of(context).push<MusicPiece>(
                MaterialPageRoute(
                  builder: (context) => AddEditPieceScreen(musicPiece: _currentMusicPiece),
                ),
              );
              if (updatedPiece != null) {
                setState(() {
                  _currentMusicPiece = updatedPiece;
                });
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
              _currentMusicPiece.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _currentMusicPiece.artistComposer,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Core Attributes
            if (_currentMusicPiece.genre.isNotEmpty)
              Text('Genre: ${_currentMusicPiece.genre.join(', ')}'),
            if (_currentMusicPiece.instrumentation.isNotEmpty)
              Text('Instrumentation: ${_currentMusicPiece.instrumentation}'),
            if (_currentMusicPiece.difficulty.isNotEmpty)
              Text('Difficulty: ${_currentMusicPiece.difficulty}'),
            if (_currentMusicPiece.tags.isNotEmpty)
              Text('Tags: ${_currentMusicPiece.tags.join(', ')}'),
            const SizedBox(height: 20),

            // Practice Tracking UI
            Text('Practice Tracking', style: Theme.of(context).textTheme.headlineSmall),
            SwitchListTile(
              title: const Text('Enable Practice Tracking'),
              value: _currentMusicPiece.enablePracticeTracking,
              onChanged: (value) {
                setState(() {
                  _currentMusicPiece.enablePracticeTracking = value;
                  // TODO: Update in database
                });
              },
            ),
            if (_currentMusicPiece.enablePracticeTracking) ...[
              Text('Last Practice: ${_currentMusicPiece.lastPracticeTime != null ? _currentMusicPiece.lastPracticeTime!.toLocal().toString().split(' ')[0] : 'Never'}'),
              Text('Practice Count: ${_currentMusicPiece.practiceCount}'),
              FilledButton.tonal(
                onPressed: _logPractice,
                child: const Text('Log Practice'),
              ),
            ],
            const SizedBox(height: 20),

            // Dynamic Media Display
            Text('Media', style: Theme.of(context).textTheme.headlineSmall),
            if (_currentMusicPiece.mediaItems.isEmpty)
              const Text('No media attached.')
            else
              Column(
                children: _currentMusicPiece.mediaItems.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title ?? item.type.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          if (item.type == MediaType.image) GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ImageViewerScreen(imagePath: item.pathOrUrl),
                                ),
                              );
                            },
                            child: Image.file(File(item.pathOrUrl)),
                          ),
                          if (item.type == MediaType.pdf) ElevatedButton(onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(pdfPath: item.pathOrUrl),
                              ),
                            );
                          }, child: const Text('View PDF')),
                          if (item.type == MediaType.audio) AudioPlayerWidget(audioPath: item.pathOrUrl),
                          if (item.type == MediaType.videoLink) ElevatedButton(onPressed: () => _launchUrl(item.pathOrUrl), child: const Text('Open Video Link')),
                          if (item.type == MediaType.markdown) MarkdownBody(data: item.pathOrUrl),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}



