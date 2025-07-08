import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

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
  double _pitch = 1.0; // Represents pitch multiplier, 1.0 is original pitch

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
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
                  min: 0.5,
                  max: 2.0,
                  value: _pitch,
                  divisions: 30, // 0.5 to 2.0 in 0.05 increments
                  label: _pitch.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      _pitch = value;
                      // just_audio's setPitch takes a double, where 1.0 is original pitch.
                      // We can map half-steps to a pitch multiplier.
                      // A common approximation is 2^(half_steps/12)
                      // For simplicity, we'll directly use the slider value as pitch multiplier.
                      _player.setPitch(_pitch);
                    });
                  },
                ),
              ),
              Text('${_pitch.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
    );
  }
}
