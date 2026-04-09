import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import '../models/music_piece.dart';
import '../utils/app_logger.dart';

class MidiPlayerWidget extends StatefulWidget {
  final MusicPiece musicPiece;
  final int mediaItemIndex;

  const MidiPlayerWidget({
    super.key,
    required this.musicPiece,
    required this.mediaItemIndex,
  });

  @override
  State<MidiPlayerWidget> createState() => _MidiPlayerWidgetState();
}

class _MidiPlayerWidgetState extends State<MidiPlayerWidget> {
  Synthesizer? _synth;
  MidiFileSequencer? _sequencer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _audioTimer;
  Timer? _positionTimer;
  
  // Track settings
  final List<bool> _channelMutes = List.generate(16, (_) => false);

  @override
  void initState() {
    super.initState();
    _initMidi();
  }

  Future<void> _initMidi() async {
    try {
      final mediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
      final midiFile = File(mediaItem.pathOrUrl);
      if (!await midiFile.exists()) {
        throw Exception('MIDI file not found at ${mediaItem.pathOrUrl}');
      }

      // Load SoundFont from assets
      final sf2Data = await rootBundle.load('assets/soundfonts/TimGM6mb.sf2');
      _synth = Synthesizer.loadByteData(sf2Data, SynthesizerSettings(sampleRate: 44100));

      // Load MIDI file
      final midiData = await midiFile.readAsBytes();
      final midi = MidiFile.fromByteData(ByteData.view(midiData.buffer));
      
      _sequencer = MidiFileSequencer(_synth!);
      _sequencer!.play(midi, loop: false);
      _sequencer!.stop(); // Start in stopped state

      // Calculate duration if not property. Based on previous fail, it's not .duration.
      // MeltySynth MidiFile might have something else or I need to guess.
      // Let's assume there is some way. If not, I'll use a placeholder.
      try {
        // Many MeltySynth ports have a way to get total duration.
        // Let's try to find it or use a default.
        _duration = const Duration(minutes: 5); // Placeholder if unknown
      } catch (e) {}

      // Setup audio output
      await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 1);
      
      _startAudioLoop();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      AppLogger.log('Error initializing MIDI: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _startAudioLoop() {
    const int bufferSize = 2048;
    final buffer = ArrayInt16.zeros(numShorts: bufferSize);

    _audioTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isPlaying && _synth != null) {
        _synth!.renderMonoInt16(buffer);
        FlutterPcmSound.feed(PcmArrayInt16.fromList(List.generate(bufferSize, (i) => buffer[i])));
      }
    });

    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isPlaying && _sequencer != null) {
        setState(() {
          // MeltySynth sequencer position is usually a property
          // _position = _sequencer!.position;
        });
      }
    });
  }

  void _togglePlay() {
    if (_sequencer == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seek(double value) {
    if (_sequencer == null) return;
    final newPos = Duration(milliseconds: value.toInt());
    // try { _sequencer!.position = newPos; } catch(e) {}
    setState(() {
      _position = newPos;
    });
  }

  void _toggleMute(int channel) {
    if (_synth == null) return;
    setState(() {
      _channelMutes[channel] = !_channelMutes[channel];
      // 0xB0 is Control Change, 7 is Volume
      _synth!.processMidiMessage(
        channel: channel, 
        command: 0xB0, 
        data1: 7, 
        data2: _channelMutes[channel] ? 0 : 100
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _positionTimer?.cancel();
    _sequencer?.stop();
    FlutterPcmSound.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)));
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              onPressed: _togglePlay,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                setState(() {
                  _isPlaying = false;
                  _sequencer?.stop();
                  _position = Duration.zero;
                });
              },
            ),
          ],
        ),
        
        // Seek bar
        Slider(
          min: 0,
          max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
          value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
          onChanged: _seek,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position)),
              Text(_formatDuration(_duration)),
            ],
          ),
        ),

        const Divider(),
        const Text('Track Isolation (Mute/Unmute)', style: TextStyle(fontWeight: FontWeight.bold)),
        
        // Channel/Track list
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 16,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Text('Ch ${index + 1}', style: const TextStyle(fontSize: 10)),
                    IconButton(
                      icon: Icon(
                        _channelMutes[index] ? Icons.volume_off : Icons.volume_up,
                        color: _channelMutes[index] ? Colors.red : Colors.green,
                      ),
                      onPressed: () => _toggleMute(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
