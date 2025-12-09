import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:repertoire/services/pitch_controllable_player.dart'; // Import the new player
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../models/music_piece.dart'; // Import MusicPiece
import '../models/bookmark.dart'; // Import Bookmark
import '../database/music_piece_repository.dart'; // Import MusicPieceRepository
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../models/media_type.dart'; // Used in _initAudio

class AudioPlayerWidget extends StatefulWidget {
  final MusicPiece musicPiece; // The music piece containing audio and bookmarks
  final int mediaItemIndex; // Index of the audio media item to play

  const AudioPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

/// The state class for [AudioPlayerWidget].
/// Manages the audio player, its state, and the speed/pitch controls.
class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final PitchControllablePlayer _player = PitchControllablePlayer(); // Use the new player
  double _speed = 1.0; // Current playback speed.
  double _pitch = 0.0; // Current pitch in half-step units.
  bool _isInitialized = false; // Whether the audio source was successfully initialized.
  String? _errorMessage; // Specific error message if initialization fails.
  List<Bookmark> _bookmarks = []; // List of bookmarks for the current audio.
  final MusicPieceRepository _repository = MusicPieceRepository(); // Repository for saving music piece.
  final Uuid _uuid = Uuid(); // For generating unique bookmark IDs.
  late Future<void> _playerInitFuture;

  @override
  void initState() {
    super.initState();
    _bookmarks = List.from(widget.musicPiece.bookmarks); // Initialize bookmarks from music piece.
    _playerInitFuture = _initializeSequence();
  }

  Future<void> _initializeSequence() async {
    await _player.initialize();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final speed = prefs.getDouble('audio_speed_${widget.musicPiece.id}') ?? 1.0;
    final pitch = prefs.getDouble('audio_pitch_${widget.musicPiece.id}') ?? 0.0;
    
    if (mounted) {
      setState(() {
        _speed = speed;
        _pitch = pitch;
      });
    }
    
    // Apply settings to the audio player
    try {
      await _player.setSpeed(_speed);
      await _player.setPitch(_pitch); // Directly set semitones
      AppLogger.log('AudioPlayerWidget: Settings loaded - Speed: $_speed, Pitch: $_pitch');
    } catch (e) {
      AppLogger.log('AudioPlayerWidget: Error applying settings: $e');
    }
  }

  /// Saves the current speed and pitch settings to [SharedPreferences].
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_speed_${widget.musicPiece.id}', _speed); // Save current playback speed.
    await prefs.setDouble('audio_pitch_${widget.musicPiece.id}', _pitch); // Save current pitch setting.
    AppLogger.log('AudioPlayerWidget: Settings saved - Speed: $_speed, Pitch: $_pitch');
  }

  /// Initializes the audio player with the provided audio path.
  Future<void> _initAudio() async { // Removed audioPlayerService parameter
    try {
      final audioMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
      if (audioMediaItem.type != MediaType.audio) {
        throw Exception('Media item at index ${widget.mediaItemIndex} is not an audio type.');
      }

      final audioPath = audioMediaItem.pathOrUrl;
      
      AppLogger.log('AudioPlayerWidget: Initializing audio with path: $audioPath');

      // Validate file path for special characters that might cause issues
      if (audioPath.contains('*') || audioPath.contains('?') || audioPath.contains('<') || audioPath.contains('>')) {
        AppLogger.log('AudioPlayerWidget: Warning - File path contains special characters that may cause issues');
      }

      // Check if file exists
      final file = File(audioPath);
      if (!await file.exists()) {
        AppLogger.log('AudioPlayerWidget: Audio file does not exist: $audioPath');
        setState(() {
          _errorMessage = 'Audio file does not exist';
          _isInitialized = false;
        });
        return;
      }

      AppLogger.log('AudioPlayerWidget: Audio file exists, size: ${await file.length()} bytes');

      if (!mounted) return;

      // Load and play the audio with error handling for threading issues
      await _player.setUrl(
        audioPath,
        title: widget.musicPiece.title,
      ); // Use setUrl from PitchControllablePlayer
      
      if (!mounted) return;
      
      await _player.play();

      // Small delay to allow the player to stabilize (helps with threading issues)
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      // Apply current speed and pitch settings after loading
      await _player.setSpeed(_speed);
      await _player.setPitch(_pitch); // Directly set semitones

      AppLogger.log('AudioPlayerWidget: Audio initialized successfully');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      AppLogger.log('AudioPlayerWidget: Error initializing audio: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing audio: $e';
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveBookmarks(); // Save bookmarks when the widget is disposed.
    // We stop playback when leaving this screen
    _player.stop(); 
    // PitchControllablePlayer.dispose also calls stop() but keeps the handler alive for the session
    _player.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioMediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];

    return FutureBuilder<void>(
      future: _playerInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error initializing player: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Show error state if audio failed to initialize
        if (_errorMessage != null) {
          return Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64.0,
              ),
              const SizedBox(height: 8.0),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Path: ${audioMediaItem.pathOrUrl}',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<ja.PlayerState>(
              stream: _player.playerStateStream, // Use new player's stream
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;

                // Debug logging to help identify the issue
                AppLogger.log('AudioPlayerWidget: PlayerState - processing: $processingState, playing: $playing');

                // Define the main control button based on state
                Widget mainButton;
                if (processingState == ja.ProcessingState.loading ||
                    processingState == ja.ProcessingState.buffering) {
                  mainButton = const SizedBox(
                    width: 80.0,
                    height: 80.0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (processingState == ja.ProcessingState.completed) {
                  mainButton = IconButton(
                    icon: const Icon(Icons.replay),
                    iconSize: 64.0,
                    onPressed: () => _player.player.seek(Duration.zero),
                  );
                } else if (playing == true) {
                  mainButton = IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 64.0,
                    onPressed: _player.pause,
                  );
                } else {
                  mainButton = IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 64.0,
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        if (!_isInitialized) {
                          await _initAudio();
                        } else {
                          await _player.play();
                        }
                      } catch (e) {
                        AppLogger.log('AudioPlayerWidget: Error in play button: $e');
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error playing audio: $e')),
                        );
                      }
                    },
                  );
                }

                // Return the Row with Skip buttons and Main button
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind 5s Button
                    IconButton(
                      icon: const Icon(Icons.replay_5), // Using generic replay icon
                      iconSize: 32.0,
                      tooltip: 'Rewind 5s',
                      onPressed: () {
                        final current = _player.player.position;
                        final newPos = current - const Duration(seconds: 5);
                        _player.player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    const SizedBox(width: 16), // Spacing
                    mainButton,
                    const SizedBox(width: 16), // Spacing
                    // Forward 5s Button
                    IconButton(
                      icon: const Icon(Icons.forward_5), // Using generic forward icon
                      iconSize: 32.0,
                      tooltip: 'Forward 5s',
                      onPressed: () {
                        final current = _player.player.position;
                        final duration = _player.player.duration ?? Duration.zero;
                        final newPos = current + const Duration(seconds: 5);
                        _player.player.seek(newPos > duration ? duration : newPos);
                      },
                    ),
                  ],
                );
              },
            ),
            
            // Position/Duration Slider
            StreamBuilder<Duration?>( // Changed to Duration?
              stream: _player.durationStream, // Use new player's duration stream
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream, // Use new player's position stream
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final min = 0.0;
                    final max = duration.inMilliseconds.toDouble();
                    final value = position.inMilliseconds.clamp(min, max).toDouble();
                    
                    return Column(
                      children: [
                        Slider(
                          min: min,
                          max: max > 0 ? max : 1.0, // Prevent division by zero
                          value: max > 0 ? value : 0.0,
                          onChanged: max > 0 ? (value) {
                            _player.player.seek(Duration(milliseconds: value.toInt())); // Use new player's seek
                          } : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            
            // Speed Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Speed:'),
                  Expanded(
                    child: Slider(
                      min: 0.2,
                      max: 2.5,
                      value: _speed,
                      divisions: 23, // 0.2 to 2.5 in 0.1 increments
                      label: _speed.toStringAsFixed(1),
                      onChanged: (value) async {
                        setState(() {
                          _speed = value;
                        });
                        await _player.setSpeed(value); // Use new player's setSpeed
                        await _saveSettings();
                      },
                    ),
                  ),
                  Text('${_speed.toStringAsFixed(1)}x'),
                ],
              ),
            ),
            
            // Pitch Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Pitch:'),
                  Expanded(
                    child: Slider(
                      min: -12.0, // One octave down
                      max: 12.0, // One octave up
                      value: _pitch,
                      divisions: 24,
                      label: _getPitchDisplayString(_pitch),
                      onChanged: (value) async {
                        setState(() {
                          _pitch = value;
                        });
                        await _player.setPitch(value);
                        await _saveSettings();
                      },
                    ),
                  ),
                  Text(_getPitchDisplayString(_pitch)),
                ],
              ),
            ),
            
            // Reset Controls Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _speed = 1.0;
                    _pitch = 0.0;
                  });
                  await _player.setSpeed(1.0); // Use new player's setSpeed
                  await _player.setPitch(0.0); // Use new player's setPitch
                  await _saveSettings();
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset Controls'),
              ),
            ),
            
            // Add Bookmark Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        onTap: () => _seekToBookmark(bookmark.timestamp),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete bookmark',
                          onPressed: () {
                            _removeBookmark(bookmark.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${bookmark.name} deleted')),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  String _getPitchDisplayString(double semitones) {
    if (semitones == 0) return 'Normal';
    return '${semitones > 0 ? '+' : ''}${semitones.round()} st';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Bookmark Management Methods
  Future<void> _addBookmark() async {
    // Guard: ensure audio is loaded before adding a bookmark
    if (!_isInitialized || _player.player.duration == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio not loaded yet. Please wait.')),
        );
      }
    	return;
    }
    final currentPosition = _player.player.position; // Use new player's position
    final newBookmark = Bookmark(
      id: _uuid.v4(),
      timestamp: currentPosition,
      name: 'Bookmark ${_bookmarks.length + 1}',
    );

    setState(() {
      _bookmarks.add(newBookmark);
      _bookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Keep sorted
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

  void _seekToBookmark(Duration timestamp) {
    _player.player.seek(timestamp); // Use new player's seek
  }

  Future<void> _saveBookmarks() async {
    final updatedMusicPiece = widget.musicPiece.copyWith(bookmarks: _bookmarks);
    await _repository.updateMusicPiece(updatedMusicPiece);
    AppLogger.log('AudioPlayerWidget: Bookmarks saved for ${widget.musicPiece.title}');
  }
}
