import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:dart_midi_pro/dart_midi_pro.dart' as midi_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/bookmark.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';

/// Global controller to ensure only one MIDI player is active at a time.
class MidiPlayerController {
  static final MidiPlayerController _instance = MidiPlayerController._internal();
  factory MidiPlayerController() => _instance;
  MidiPlayerController._internal();

  String? _activePlayerId;

  void setActive(String id) {
    _activePlayerId = id;
  }

  bool isActive(String id) => _activePlayerId == id;
}

class MidiNote {
  final int pitch;
  final double startTimeSeconds;
  final double durationSeconds;
  final int channel;

  MidiNote({
    required this.pitch,
    required this.startTimeSeconds,
    required this.durationSeconds,
    required this.channel,
  });
}

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
  MidiFile? _meltyMidi;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isScrubbing = false;
  bool _wasPlayingBeforeScrub = false;
  String? _errorMessage;
  final String _playerId = const Uuid().v4();
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _audioTimer;
  Timer? _positionTimer;
  
  // Track settings
  final List<bool> _channelMutes = List.generate(16, (_) => false);
  final List<bool> _activeChannels = List.generate(16, (_) => false);
  List<MidiNote> _extractedNotes = [];

  // Bookmark settings
  List<Bookmark> _bookmarks = [];
  final MusicPieceRepository _repository = MusicPieceRepository();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    _bookmarks = widget.musicPiece.bookmarks.where((b) => b.mediaItemId == currentMediaId || b.mediaItemId == null).toList();
    _initMidi();
  }

  // Improved duration calculation that accounts for tempo changes
  Duration _calculateMidiDuration(midi_parser.MidiFile midiFile) {
    try {
      final int division = midiFile.header.ticksPerBeat ?? 480;
      
      // Collect all tempo events
      final List<dynamic> tempoEvents = [];
      for (var track in midiFile.tracks) {
        int absTick = 0;
        for (var event in track) {
          absTick += event.deltaTime;
          if (event is midi_parser.SetTempoEvent) {
            tempoEvents.add({'tick': absTick, 'event': event});
          }
        }
      }
      tempoEvents.sort((a, b) => (a['tick'] as int).compareTo(b['tick'] as int));

      // Find the absolute maximum tick across all tracks
      int maxTick = 0;
      for (var track in midiFile.tracks) {
        int trackTick = 0;
        for (var event in track) {
          trackTick += event.deltaTime;
        }
        if (trackTick > maxTick) maxTick = trackTick;
      }

      double totalSeconds = 0;
      int lastTick = 0;
      int currentMicrosecondsPerBeat = 500000; // Default 120 BPM

      for (var entry in tempoEvents) {
        final int tick = entry['tick'];
        final int delta = tick - lastTick;
        totalSeconds += (delta * currentMicrosecondsPerBeat) / (division * 1000000);
        lastTick = tick;
        currentMicrosecondsPerBeat = (entry['event'] as midi_parser.SetTempoEvent).microsecondsPerBeat;
      }

      // Add remaining time until maxTick
      if (maxTick > lastTick) {
        totalSeconds += ((maxTick - lastTick) * currentMicrosecondsPerBeat) / (division * 1000000);
      }

      return Duration(milliseconds: (totalSeconds * 1000).round());
    } catch (e) {
      AppLogger.log('Error calculating duration: $e');
      return const Duration(minutes: 5);
    }
  }

  List<MidiNote> _extractNotes(midi_parser.MidiFile midiFile) {
    final List<MidiNote> notes = [];
    final int division = midiFile.header.ticksPerBeat ?? 480;
    
    // Merge events from all tracks to handle tempo correctly
    final List<dynamic> allEvents = [];
    for (var track in midiFile.tracks) {
      int absoluteTick = 0;
      for (var event in track) {
        absoluteTick += event.deltaTime;
        allEvents.add({'tick': absoluteTick, 'event': event});
      }
    }
    allEvents.sort((a, b) => (a['tick'] as int).compareTo(b['tick'] as int));

    int lastTick = 0;
    double currentTimeSeconds = 0;
    int currentTempo = 500000;
    final Map<String, double> pendingNoteStarts = {};

    for (var entry in allEvents) {
      final int tick = entry['tick'];
      final dynamic event = entry['event'];
      
      // Update time using delta from last event globally
      currentTimeSeconds += (tick - lastTick) * (currentTempo / division) / 1000000;
      lastTick = tick;

      if (event is midi_parser.SetTempoEvent) {
        currentTempo = event.microsecondsPerBeat;
      } else if (event is midi_parser.NoteOnEvent) {
        final key = '${event.channel}_${event.noteNumber}';
        if (event.velocity > 0) {
          pendingNoteStarts[key] = currentTimeSeconds;
        } else {
          if (pendingNoteStarts.containsKey(key)) {
            final start = pendingNoteStarts.remove(key)!;
            notes.add(MidiNote(
              pitch: event.noteNumber,
              startTimeSeconds: start,
              durationSeconds: currentTimeSeconds - start,
              channel: event.channel,
            ));
          }
        }
      } else if (event is midi_parser.NoteOffEvent) {
        final key = '${event.channel}_${event.noteNumber}';
        if (pendingNoteStarts.containsKey(key)) {
          final start = pendingNoteStarts.remove(key)!;
          notes.add(MidiNote(
            pitch: event.noteNumber,
            startTimeSeconds: start,
            durationSeconds: currentTimeSeconds - start,
            channel: event.channel,
          ));
        }
      }
    }
    return notes..sort((a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds));
  }

  Future<void> _initMidi() async {
    try {
      final mediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
      final midiFile = File(mediaItem.pathOrUrl);
      if (!await midiFile.exists()) {
        throw Exception('MIDI file not found at ${mediaItem.pathOrUrl}');
      }

      _synth = Synthesizer.loadByteData(await rootBundle.load('assets/soundfonts/TimGM6mb.sf2'), SynthesizerSettings(sampleRate: 44100));

      // Load saved mute states
      final prefs = await SharedPreferences.getInstance();
      final muteStatesJson = prefs.getString('midi_mutes_${mediaItem.id}');
      if (muteStatesJson != null) {
        final List<dynamic> decoded = jsonDecode(muteStatesJson);
        for (int i = 0; i < 16 && i < decoded.length; i++) {
          _channelMutes[i] = decoded[i] as bool;
          _synth!.processMidiMessage(channel: i, command: 0xB0, data1: 7, data2: _channelMutes[i] ? 0 : 127);
        }
      }

      final midiData = await midiFile.readAsBytes();
      _meltyMidi = MidiFile.fromByteData(ByteData.view(midiData.buffer));
      final parsedMidi = midi_parser.MidiParser().parseMidiFromBuffer(midiData);
      
      _sequencer = MidiFileSequencer(_synth!);
      _duration = _calculateMidiDuration(parsedMidi);
      _extractedNotes = _extractNotes(parsedMidi);
      
      for (var note in _extractedNotes) {
        _activeChannels[note.channel] = true;
      }

      _sequencer!.play(_meltyMidi!, loop: false);

      await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(4096);
      
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

  void _clearSynthSounds() {
    if (_synth == null) return;
    for (int i = 0; i < 16; i++) {
      _synth!.processMidiMessage(channel: i, command: 0xB0, data1: 120, data2: 0);
      _synth!.processMidiMessage(channel: i, command: 0xB0, data1: 123, data2: 0);
    }
  }

  void _startAudioLoop() {
    const int bufferSize = 1024;
    final buffer = ArrayInt16.zeros(numShorts: bufferSize);

    _audioTimer = Timer.periodic(const Duration(milliseconds: 23), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isPlaying && !_isScrubbing && _sequencer != null && MidiPlayerController().isActive(_playerId)) {
        _sequencer!.renderMonoInt16(buffer);
        final int16List = Int16List(bufferSize);
        for(int i=0; i<bufferSize; i++) {
          int16List[i] = buffer[i];
        }
        FlutterPcmSound.feed(PcmArrayInt16.fromList(int16List));
      } else if (_isPlaying && !MidiPlayerController().isActive(_playerId)) {
        // Another player took over. Stop rendering but DON'T pause the global engine.
        _stopLocally();
      }
    });

    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPlaying && !_isScrubbing && _sequencer != null) {
        setState(() {
          _position = _sequencer!.position;
          if (_position >= _duration) {
            _isPlaying = false;
            FlutterPcmSound.pause();
            _position = Duration.zero;
            _sequencer!.stop();
            _clearSynthSounds();
          }
        });
      }
    });
  }

  void _stopLocally() {
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
    _clearSynthSounds();
  }

  void _togglePlay() async {
    if (_sequencer == null) return;
    
    if (!_isPlaying) {
      // Clear any stale audio from previous players
      await FlutterPcmSound.clear();
      MidiPlayerController().setActive(_playerId);
      
      if (_position == Duration.zero || _position >= _duration) {
        _sequencer!.play(_meltyMidi!, loop: false);
      }
      await FlutterPcmSound.play();
    } else {
      // Only pause the hardware if we are still the active owner
      if (MidiPlayerController().isActive(_playerId)) {
        await FlutterPcmSound.pause();
      }
      _clearSynthSounds();
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _seek(double value) {
    if (_sequencer == null || _meltyMidi == null) return;
    
    final targetPos = Duration(milliseconds: value.toInt());
    AppLogger.log('MIDI Seek: Target ${targetPos.inMilliseconds}ms');
    
    _sequencer!.stop();
    _clearSynthSounds();
    _sequencer!.play(_meltyMidi!, loop: false);
    
    final originalSpeed = _sequencer!.speed;
    _sequencer!.speed = 1000.0;
    
    // Smaller chunk size for better precision during seeking
    const int seekChunkSize = 512; 
    final dummyBuffer = ArrayInt16.zeros(numShorts: seekChunkSize);
    
    int safety = 0;
    // We render until sequencer position catches up to targetPos
    while (_sequencer!.position < targetPos && safety < 100000) {
      _sequencer!.renderMonoInt16(dummyBuffer);
      safety++;
    }
    
    AppLogger.log('MIDI Seek Done: Final ${_sequencer!.position.inMilliseconds}ms (safety: $safety)');
    
    _sequencer!.speed = originalSpeed;
    _clearSynthSounds();

    setState(() {
      _position = _sequencer!.position;
    });
  }

  void _toggleMute(int channel) async {
    if (_synth == null) return;
    setState(() {
      _channelMutes[channel] = !_channelMutes[channel];
      _synth!.processMidiMessage(
        channel: channel, 
        command: 0xB0, 
        data1: 7, 
        data2: _channelMutes[channel] ? 0 : 127
      );
    });

    final prefs = await SharedPreferences.getInstance();
    final mediaItem = widget.musicPiece.mediaItems[widget.mediaItemIndex];
    await prefs.setString('midi_mutes_${mediaItem.id}', jsonEncode(_channelMutes));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _addBookmark() async {
    if (!_isInitialized) return;
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    final newBookmark = Bookmark(
      id: _uuid.v4(),
      timestamp: _position,
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

  void _seekToBookmark(Duration timestamp) {
    _seek(timestamp.inMilliseconds.toDouble());
  }

  Future<void> _saveBookmarks() async {
    final latestPiece = await _repository.getMusicPieceById(widget.musicPiece.id);
    if (latestPiece == null) return;
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    final otherBookmarks = latestPiece.bookmarks.where((b) => 
      b.mediaItemId != currentMediaId && b.mediaItemId != null
    ).toList();
    final allBookmarks = [...otherBookmarks, ..._bookmarks];
    final updatedMusicPiece = latestPiece.copyWith(bookmarks: allBookmarks);
    await _repository.updateMusicPiece(updatedMusicPiece);
  }

  @override
  void dispose() {
    _saveBookmarks();
    _audioTimer?.cancel();
    _positionTimer?.cancel();
    _sequencer?.stop();
    _clearSynthSounds();
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

    final activeChannelIndices = <int>[];
    for (int i = 0; i < 16; i++) {
      if (_activeChannels[i]) activeChannelIndices.add(i);
    }

    return Column(
      children: [
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRect(
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: MidiVisualizerPainter(
                notes: _extractedNotes,
                currentPosition: _position,
                channelMutes: _channelMutes,
              ),
            ),
          ),
        ),

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
                  _clearSynthSounds();
                  FlutterPcmSound.stop();
                  _position = Duration.zero;
                });
              },
            ),
          ],
        ),
        
        Slider(
          min: 0,
          max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
          value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
          onChangeStart: (value) {
            _wasPlayingBeforeScrub = _isPlaying;
            if (_isPlaying) {
              FlutterPcmSound.pause();
              _clearSynthSounds();
            }
            setState(() {
              _isScrubbing = true;
            });
          },
          onChanged: (value) {
            setState(() {
              _position = Duration(milliseconds: value.toInt());
            });
          },
          onChangeEnd: (value) {
            _seek(value);
            setState(() {
              _isScrubbing = false;
              if (_wasPlayingBeforeScrub) {
                FlutterPcmSound.play();
              }
            });
          },
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: _addBookmark,
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Add Bookmark'),
          ),
        ),

        if (_bookmarks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = _bookmarks[index];
              return ListTile(
                title: Text(bookmark.name),
                subtitle: Text(_formatDuration(bookmark.timestamp)),
                onTap: () => _seekToBookmark(bookmark.timestamp),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeBookmark(bookmark.id),
                ),
              );
            },
          ),

        if (activeChannelIndices.isNotEmpty) ...[
          const Divider(),
          const Text('Track Isolation', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeChannelIndices.length,
              itemBuilder: (context, index) {
                final ch = activeChannelIndices[index];
                final channelColor = Colors.accents[ch % Colors.accents.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text('Ch ${ch + 1}', style: const TextStyle(fontSize: 10)),
                      IconButton(
                        icon: Icon(_channelMutes[ch] ? Icons.volume_off : Icons.volume_up),
                        color: _channelMutes[ch] ? Colors.grey : channelColor,
                        onPressed: () => _toggleMute(ch),
                      ),
                      Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: channelColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class MidiVisualizerPainter extends CustomPainter {
  final List<MidiNote> notes;
  final Duration currentPosition;
  final List<bool> channelMutes;

  MidiVisualizerPainter({
    required this.notes,
    required this.currentPosition,
    required this.channelMutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double windowSeconds = 4.0;
    const double playheadX = 60.0;
    final double pixelsPerSecond = (size.width - playheadX) / (windowSeconds - 1.0);
    
    final currentSec = currentPosition.inMilliseconds / 1000.0;
    
    int minPitch = 127;
    int maxPitch = 0;
    for (var n in notes) {
      if (n.pitch < minPitch) minPitch = n.pitch;
      if (n.pitch > maxPitch) maxPitch = n.pitch;
    }
    if (maxPitch <= minPitch) { minPitch = 40; maxPitch = 80; }
    final pitchRange = (maxPitch - minPitch).toDouble() + 10.0;

    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      Paint()..color = Colors.red.withValues(alpha: 0.5)..strokeWidth = 2,
    );

    for (final note in notes) {
      final relativeStart = note.startTimeSeconds - currentSec;
      final relativeEnd = relativeStart + note.durationSeconds;

      if (relativeEnd < -1.0 || relativeStart > windowSeconds) continue;

      final x = playheadX + (relativeStart * pixelsPerSecond);
      final w = note.durationSeconds * pixelsPerSecond;
      
      final y = size.height - ((note.pitch - minPitch + 5) / pitchRange * size.height);
      const h = 8.0;

      paint.color = Colors.accents[note.channel % Colors.accents.length].withValues(
        alpha: channelMutes[note.channel] ? 0.1 : 0.8
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, max(w, 4.0), h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MidiVisualizerPainter oldDelegate) {
    return oldDelegate.currentPosition != currentPosition || oldDelegate.channelMutes != channelMutes;
  }
}
