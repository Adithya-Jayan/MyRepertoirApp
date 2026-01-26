import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/bookmark.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';

/// A widget that provides video playback functionality with advanced controls.
class VideoPlayerWidget extends StatefulWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  const VideoPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  List<Bookmark> _bookmarks = [];
  final MusicPieceRepository _repository = MusicPieceRepository();
  final Uuid _uuid = const Uuid();
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _enableWakelock();
    _initializeBookmarks();
    _initializePlayer();
  }

  void _enableWakelock() {
    WakelockPlus.enable();
  }

  void _disableWakelock() {
    WakelockPlus.disable();
  }

  void _initializeBookmarks() {
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    // Filter bookmarks for this specific media item
    _bookmarks = widget.musicPiece.bookmarks.where((b) => b.mediaItemId == currentMediaId).toList();
    _bookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _initializePlayer() async {
    final videoPath = widget.musicPiece.mediaItems[widget.mediaItemIndex].pathOrUrl;
    
    if (videoPath.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
    } else {
      _controller = VideoPlayerController.file(File(videoPath));
    }

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.log('Error initializing video player: $e');
    }
    
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disableWakelock();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _addBookmark() async {
    if (!_controller.value.isInitialized) return;
    
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    final currentPosition = _controller.value.position;
    
    final newBookmark = Bookmark(
      id: _uuid.v4(),
      timestamp: currentPosition,
      name: 'Bookmark ${_bookmarks.length + 1}',
      mediaItemId: currentMediaId,
    );

    setState(() {
      _bookmarks.add(newBookmark);
      _bookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    await _saveBookmarks();
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    setState(() {
      _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    });
    await _saveBookmarks();
  }

  Future<void> _renameBookmark(String bookmarkId, String newName) async {
    setState(() {
      final index = _bookmarks.indexWhere((bookmark) => bookmark.id == bookmarkId);
      if (index != -1) {
        _bookmarks[index] = _bookmarks[index].copyWith(name: newName);
      }
    });
    await _saveBookmarks();
  }

  Future<void> _saveBookmarks() async {
    // Fetch latest piece to avoid overwriting other widgets' changes
    final latestPiece = await _repository.getMusicPieceById(widget.musicPiece.id);
    if (latestPiece == null) return;

    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    
    // Get bookmarks that do NOT belong to this video file (preserve them)
    // We are managing bookmarks with (id == current). Video player doesn't manage legacy (null) bookmarks by default unless we decide so.
    // In initState we did: _bookmarks = widget.musicPiece.bookmarks.where((b) => b.mediaItemId == currentMediaId).toList();
    // So we ONLY manage our specific ones.
    // So "others" are (id != current).
    final otherBookmarks = latestPiece.bookmarks.where((b) => b.mediaItemId != currentMediaId).toList();
    
    // Combine with current bookmarks
    final allBookmarks = [...otherBookmarks, ..._bookmarks];
    
    // Update piece
    final updatedMusicPiece = latestPiece.copyWith(bookmarks: allBookmarks);
    await _repository.updateMusicPiece(updatedMusicPiece);
  }

  void _toggleFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: VideoPlayerWidget(
                musicPiece: widget.musicPiece,
                mediaItemIndex: widget.mediaItemIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _ControlsOverlay(
                controller: _controller,
                onToggleFullscreen: _toggleFullscreen,
              ),
            ],
          ),
        ),
        
        // Progress Slider
        Column(
          children: [
            Slider(
              value: _controller.value.position.inMilliseconds.toDouble(),
              min: 0.0,
              max: _controller.value.duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _controller.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_controller.value.position)),
                  Text(_formatDuration(_controller.value.duration)),
                ],
              ),
            ),
          ],
        ),

        // Controls Row (Skip, Play/Pause, Speed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               IconButton(
                icon: const Icon(Icons.replay_5),
                onPressed: () {
                  final newPos = _controller.value.position - const Duration(seconds: 5);
                  _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48.0,
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_5),
                onPressed: () {
                  final newPos = _controller.value.position + const Duration(seconds: 5);
                  final duration = _controller.value.duration;
                  _controller.seekTo(newPos > duration ? duration : newPos);
                },
              ),
              // Speed Button
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                icon: Row(
                  children: [
                    const Icon(Icons.speed),
                    Text('${_playbackSpeed}x', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                onSelected: (speed) {
                  setState(() {
                    _playbackSpeed = speed;
                    _controller.setPlaybackSpeed(speed);
                  });
                },
                itemBuilder: (context) => [
                  0.5, 0.75, 1.0, 1.25, 1.5, 2.0
                ].map((speed) => PopupMenuItem(
                  value: speed,
                  child: Text('${speed}x'),
                )).toList(),
              ),
            ],
          ),
        ),

        // Add Bookmark Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: _addBookmark,
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Add Bookmark'),
          ),
        ),

        // Bookmarks List
        if (_bookmarks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = _bookmarks[index];
              return Dismissible(
                key: Key(bookmark.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeBookmark(bookmark.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${bookmark.name} dismissed')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: GestureDetector(
                  onDoubleTap: () async {
                    final controller = TextEditingController(text: bookmark.name);
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Rename Bookmark'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          onSubmitted: (value) => Navigator.of(context).pop(value),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(controller.text),
                            child: const Text('Rename'),
                          ),
                        ],
                      ),
                    );
                    if (newName != null && newName.isNotEmpty && newName != bookmark.name) {
                      _renameBookmark(bookmark.id, newName);
                    }
                  },
                  child: ListTile(
                    title: Text(bookmark.name),
                    subtitle: Text(_formatDuration(bookmark.timestamp)),
                    onTap: () => _controller.seekTo(bookmark.timestamp),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeBookmark(bookmark.id),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.onToggleFullscreen,
  });

  final VideoPlayerController controller;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : const ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: onToggleFullscreen,
          ),
        ),
      ],
    );
  }
}
