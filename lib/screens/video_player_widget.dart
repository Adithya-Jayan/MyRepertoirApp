import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VideoPlayerController? controller;
  final bool isFullscreen;

  const VideoPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
    this.controller,
    this.isFullscreen = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _controllerIsLocal = false;
  List<Bookmark> _bookmarks = [];
  final MusicPieceRepository _repository = MusicPieceRepository();
  final Uuid _uuid = const Uuid();
  double _playbackSpeed = 1.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _bookmarks = widget.musicPiece.bookmarks.where((b) => b.mediaItemId == currentMediaId).toList();
    _bookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _initializePlayer() async {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInitialized = true;
      _playbackSpeed = _controller.value.playbackSpeed;
    } else {
      _controllerIsLocal = true;
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
    }
    
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _disableWakelock();
    if (_controllerIsLocal) {
      _controller.dispose();
    }
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
    final latestPiece = await _repository.getMusicPieceById(widget.musicPiece.id);
    if (latestPiece == null) return;

    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    final otherBookmarks = latestPiece.bookmarks.where((b) => b.mediaItemId != currentMediaId).toList();
    final allBookmarks = [...otherBookmarks, ..._bookmarks];
    
    final updatedMusicPiece = latestPiece.copyWith(bookmarks: allBookmarks);
    await _repository.updateMusicPiece(updatedMusicPiece);
  }

  void _toggleFullscreen() {
    if (widget.isFullscreen) {
      Navigator.of(context).pop();
    } else {
      // Hide system UI for true fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerWidget(
            musicPiece: widget.musicPiece,
            mediaItemIndex: widget.mediaItemIndex,
            controller: _controller,
            isFullscreen: true,
          ),
        ),
      ).then((_) {
        // Restore system UI when back
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      });
    }
  }

  Widget _buildBookmarksList({bool isDrawer = false}) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No bookmarks added yet',
            style: TextStyle(color: isDrawer ? Colors.white70 : Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: !isDrawer,
      physics: isDrawer ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
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
          child: ListTile(
            title: Text(bookmark.name, style: TextStyle(color: isDrawer ? Colors.white : null)),
            subtitle: Text(_formatDuration(bookmark.timestamp), style: TextStyle(color: isDrawer ? Colors.white70 : null)),
            onTap: () {
              _controller.seekTo(bookmark.timestamp);
              if (isDrawer) Navigator.of(context).pop();
            },
            onLongPress: () async {
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
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Rename')),
                  ],
                ),
              );
              if (newName != null && newName.isNotEmpty) {
                _renameBookmark(bookmark.id, newName);
              }
            },
            trailing: IconButton(
              icon: Icon(Icons.delete, color: isDrawer ? Colors.white54 : null),
              onPressed: () => _removeBookmark(bookmark.id),
            ),
          ),
        );
      },
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

    Widget videoPlayer = Stack(
      alignment: Alignment.bottomCenter,
      children: [
        VideoPlayer(_controller),
        _ControlsOverlay(
          controller: _controller,
          isFullscreen: widget.isFullscreen,
          onToggleFullscreen: _toggleFullscreen,
          onOpenBookmarks: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          playbackSpeed: _playbackSpeed,
          onSpeedChanged: (speed) {
            setState(() {
              _playbackSpeed = speed;
              _controller.setPlaybackSpeed(speed);
            });
          },
        ),
      ],
    );

    if (widget.isFullscreen) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        endDrawer: Drawer(
          backgroundColor: Colors.black87,
          child: SafeArea(
            child: Column(
              children: [
                const ListTile(
                  title: Text('Bookmarks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Divider(color: Colors.white24),
                Expanded(child: _buildBookmarksList(isDrawer: true)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _addBookmark,
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Add Bookmark'),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: videoPlayer,
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: videoPlayer,
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

        // Add Bookmark Button (Inline)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: _addBookmark,
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Add Bookmark'),
          ),
        ),

        // Bookmarks List (Inline)
        _buildBookmarksList(),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onOpenBookmarks,
    required this.playbackSpeed,
    required this.onSpeedChanged,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onOpenBookmarks;
  final double playbackSpeed;
  final Function(double) onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Tap to play/pause
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        
        // Semi-transparent background when paused
        if (!controller.value.isPlaying)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 80.0),
            ),
          ),

        // Top Controls
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                if (isFullscreen)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onToggleFullscreen,
                  ),
                const Spacer(),
                // Speed Control
                PopupMenuButton<double>(
                  initialValue: playbackSpeed,
                  tooltip: 'Playback Speed',
                  onSelected: onSpeedChanged,
                  itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                      .map((speed) => PopupMenuItem(value: speed, child: Text('${speed}x')))
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text('${playbackSpeed}x', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                // Bookmarks Menu (only in fullscreen)
                if (isFullscreen)
                  IconButton(
                    icon: const Icon(Icons.bookmarks, color: Colors.white),
                    onPressed: onOpenBookmarks,
                  ),
                IconButton(
                  icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                  onPressed: onToggleFullscreen,
                ),
              ],
            ),
          ),
        ),

        // Center / Bottom Controls (Skip and Progress)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
             padding: const EdgeInsets.only(bottom: 8.0),
             decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFullscreen)
                  VideoProgressIndicator(controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.blue)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_5, color: Colors.white),
                      onPressed: () {
                        final newPos = controller.value.position - const Duration(seconds: 5);
                        controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      iconSize: 40,
                      onPressed: () {
                        controller.value.isPlaying ? controller.pause() : controller.play();
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.forward_5, color: Colors.white),
                      onPressed: () {
                        final newPos = controller.value.position + const Duration(seconds: 5);
                        controller.seekTo(newPos > controller.value.duration ? controller.value.duration : newPos);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}