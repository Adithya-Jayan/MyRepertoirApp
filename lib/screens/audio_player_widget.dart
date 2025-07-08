import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:math'; // Import for pow function
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String title;
  final String artist;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  double _speed = 1.0;
  double _pitch = 0.0; // Represents pitch in half-step units, 0.0 is original pitch

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadSettings();
    _initAudio();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('audio_speed') ?? 1.0;
      _pitch = prefs.getDouble('audio_pitch') ?? 0.0;
    });
    _player.setSpeed(_speed);
    _player.setPitch(pow(2, _pitch / 12.0).toDouble());
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('audio_speed', _speed);
    prefs.setDouble('audio_pitch', _pitch);
  }

  Future<void> _initAudio() async {
    

    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(widget.audioPath),
        tag: MediaItem(
          id: widget.audioPath,
          album: "Music Repertoire",
          title: widget.title,
          artist: widget.artist,
          artUri: Uri.parse('https://example.com/albumart.jpg'), // Placeholder
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            return Slider(
              min: 0.0,
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds.toDouble(),
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
