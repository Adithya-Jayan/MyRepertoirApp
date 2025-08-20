import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:math'; // Import for pow function
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// A widget that provides audio playback functionality with speed and pitch control.
///
/// It uses `just_audio` for audio playback and `audio_service` for background
/// playback capabilities. It also saves and loads speed and pitch settings.
class AudioPlayerWidget extends StatefulWidget {
  final String audioPath; // The local path to the audio file.
  final String title; // The title of the audio track.
  final String artist; // The artist of the audio track.

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

/// The state class for [AudioPlayerWidget].
/// Manages the audio player, its state, and the speed/pitch controls.
class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player; // The audio player instance.
  double _speed = 1.0; // Current playback speed.
  double _pitch = 0.0; // Current pitch in half-step units.
  bool _isInitialized = false; // Whether the audio source was successfully initialized.
  bool _hasError = false; // Whether there was an error initializing the audio.

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer(); // Initialize the audio player.
    _loadSettings(); // Load saved speed and pitch settings.
    _initAudio(); // Initialize the audio source.
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('audio_speed') ?? 1.0;
      _pitch = prefs.getDouble('audio_pitch') ?? 0.0;
    });
    _player.setSpeed(_speed);
    _player.setPitch(pow(2, _pitch / 12.0).toDouble());
    _player.errorStream.listen((error) {
      AppLogger.log('AudioPlayerWidget: Error in player: $error');
    });
  }

  /// Saves the current speed and pitch settings to [SharedPreferences].
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('audio_speed', _speed); // Save current playback speed.
    prefs.setDouble('audio_pitch', _pitch); // Save current pitch setting.
  }

  /// Initializes the audio player with the provided audio path.
  ///
  /// Sets the audio source and provides metadata for background playback.
  Future<void> _initAudio() async {
    try {
      AppLogger.log('AudioPlayerWidget: Initializing audio with path: ${widget.audioPath}');
      
      // Check if file exists
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        AppLogger.log('AudioPlayerWidget: Audio file does not exist: ${widget.audioPath}');
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
        return;
      }
      
      AppLogger.log('AudioPlayerWidget: Audio file exists, size: ${await file.length()} bytes');
      
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(widget.audioPath),
          tag: MediaItem(
            id: widget.audioPath,
            album: "Music Repertoire",
            title: widget.title,
            artist: widget.artist,
            artUri: Uri.parse('https://example.com/albumart.jpg'), // Placeholder album art.
          ),
        ),
      );
      
      AppLogger.log('AudioPlayerWidget: Audio source set successfully');
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      AppLogger.log('AudioPlayerWidget: Error initializing audio: $e');
      
      // Check if it's a background service conflict
      if (e.toString().contains('just_audio_background supports only a single player instance')) {
        AppLogger.log('AudioPlayerWidget: Background service conflict detected, retrying without background service');
        // Try again without background service
        try {
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(widget.audioPath)),
          );
          AppLogger.log('AudioPlayerWidget: Audio source set successfully (without background service)');
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        } catch (retryError) {
          AppLogger.log('AudioPlayerWidget: Retry also failed: $retryError');
          setState(() {
            _hasError = true;
            _isInitialized = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _player.stop();
      _player.dispose();
    } catch (e) {
      AppLogger.log('AudioPlayerWidget: Error disposing player: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if audio failed to initialize
    if (_hasError) {
      return Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64.0,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Audio file not found',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Path: ${widget.audioPath}',
            style: const TextStyle(fontSize: 12.0, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Show loading state if not initialized yet
    if (!_isInitialized) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8.0),
          Text('Loading audio...'),
        ],
      );
    }

    return Column(
      children: [
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return const CircularProgressIndicator();
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: _player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: _player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => _player.seek(Duration.zero),
              );
            }
          },
        ),
        StreamBuilder<Duration?>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;
            final min = 0.0;
            final max = duration.inMilliseconds.toDouble();
            // Clamp the value to be within min and max
            final value = position.inMilliseconds.clamp(min, max).toDouble();
            return Slider(
              min: min,
              max: max,
              value: value,
              onChanged: (value) {
                _player.seek(Duration(milliseconds: value.toInt()));
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
                  min: 0.5,
                  max: 2.0,
                  value: _speed,
                  divisions: 15, // 0.5 to 2.0 in 0.1 increments
                  label: _speed.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _speed = value;
                      _player.setSpeed(_speed);
                    });
                    _saveSettings();
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
                  onChanged: (value) {
                    setState(() {
                      _pitch = value;
                      // Convert half-step units to pitch multiplier
                      final pitchMultiplier = pow(2, _pitch / 12.0).toDouble();
                      _player.setPitch(pitchMultiplier);
                    });
                    _saveSettings();
                  },
                ),
              ),
              Text(_getPitchDisplayString(_pitch)),
            ],
          ),
        ),
      ],
    );
  }

  String _getPitchDisplayString(double pitch) {
    if (pitch.round() == 0) {
      return "0";
    }
    if (pitch.round() == 12) {
      return "+1ve";
    }
    if (pitch.round() == -12) {
      return "-1ve";
    }
    if (pitch > 0) {
      return "+${pitch.round()}";
    } else {
      return "${pitch.round()}";
    }
  }
}
