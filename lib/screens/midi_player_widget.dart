import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:dart_midi_pro/dart_midi_pro.dart' as midi_parser;
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/bookmark.dart';
import '../database/music_piece_repository.dart';
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
  MidiFile? _meltyMidi;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _audioTimer;
  Timer? _positionTimer;
  
  // Track settings
  final List<bool> _channelMutes = List.generate(16, (_) => false);
  final List<bool> _activeChannels = List.generate(16, (_) => false);

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

  Duration _calculateMidiDuration(midi_parser.MidiFile midiFile) {
    try {
      final int division = midiFile.header.ticksPerBeat ?? 480;
      
      int maxTick = 0;
      int currentTempo = 500000; // Default: 120 BPM

      for (var track in midiFile.tracks) {
        int trackTick = 0;
        for (var event in track) {
          trackTick += event.deltaTime;
          if (event is midi_parser.SetTempoEvent) {
             currentTempo = event.microsecondsPerBeat;
          }
        }
        if (trackTick > maxTick) maxTick = trackTick;
      }

      return Duration(microseconds: (maxTick * (currentTempo / division)).round());
    } catch (e) {
      AppLogger.log('Error calculating duration: $e');
      return const Duration(minutes: 5);
    }
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
      
      // For synthesis (MeltySynth)
      _meltyMidi = MidiFile.fromByteData(ByteData.view(midiData.buffer));
      
      // For metadata (dart_midi_pro)
      final parsedMidi = midi_parser.MidiParser().parseMidiFromBuffer(midiData);
      
      _sequencer = MidiFileSequencer(_synth!);
      
      // Calculate duration and identify active channels
      _duration = _calculateMidiDuration(parsedMidi);
      
      for (var track in parsedMidi.tracks) {
        for (var event in track) {
          if (event is midi_parser.NoteOnEvent && event.velocity > 0) {
            _activeChannels[event.channel] = true;
          }
        }
      }

      // Prepare the sequencer but don't call stop() which can reset it
      _sequencer!.play(_meltyMidi!, loop: false);
      // We keep it "playing" internally at position 0, our timer handles actual render output

      // Setup audio output
      await FlutterPcmSound.setup(sampleRate: 44100, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(8192);
      
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
      // CC 123: All Notes Off, CC 120: All Sound Off
      _synth!.processMidiMessage(channel: i, command: 0xB0, data1: 120, data2: 0);
      _synth!.processMidiMessage(channel: i, command: 0xB0, data1: 123, data2: 0);
    }
  }

  void _startAudioLoop() {
    // 44100 Hz = 44.1 samples per ms. 2048 / 44.1 = ~46ms.
    // Feed slightly faster than needed to prevent underruns.
    const int bufferSize = 2048;
    final buffer = ArrayInt16.zeros(numShorts: bufferSize);

    _audioTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isPlaying && _sequencer != null) {
        _sequencer!.renderMonoInt16(buffer);
        final int16List = Int16List(bufferSize);
        for(int i=0; i<bufferSize; i++) {
          int16List[i] = buffer[i];
        }
        FlutterPcmSound.feed(PcmArrayInt16.fromList(int16List));
      }
    });

    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isPlaying && _sequencer != null) {
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

  void _togglePlay() async {
    if (_sequencer == null) return;
    
    if (!_isPlaying) {
      // If we are at the start or end, ensure play() is called
      if (_position == Duration.zero || _position >= _duration) {
        _sequencer!.play(_meltyMidi!, loop: false);
      }
      await FlutterPcmSound.play();
    } else {
      await FlutterPcmSound.pause();
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seek(double value) {
    if (_sequencer == null || _meltyMidi == null) return;
    
    final targetPos = Duration(milliseconds: value.toInt());
    final wasPlaying = _isPlaying;
    
    setState(() { _isPlaying = false; });
    
    // Stop resets to 0
    _sequencer!.stop();
    _clearSynthSounds();
    _sequencer!.play(_meltyMidi!, loop: false);
    
    final originalSpeed = _sequencer!.speed;
    _sequencer!.speed = 1000.0;
    
    const int skipChunkSize = 1024;
    final dummyBuffer = ArrayInt16.zeros(numShorts: skipChunkSize);
    
    // Skip to target
    int safety = 0;
    while (_sequencer!.position < targetPos && safety < 10000) {
      _sequencer!.renderMonoInt16(dummyBuffer);
      safety++;
    }
    
    _sequencer!.speed = originalSpeed;
    _clearSynthSounds(); // Kill all notes triggered during the fast-forward

    setState(() {
      _position = _sequencer!.position;
      _isPlaying = wasPlaying;
    });
  }

  void _toggleMute(int channel) {
    if (_synth == null) return;
    setState(() {
      _channelMutes[channel] = !_channelMutes[channel];
      // CC 7 is main volume.
      _synth!.processMidiMessage(
        channel: channel, 
        command: 0xB0, 
        data1: 7, 
        data2: _channelMutes[channel] ? 0 : 127
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Bookmark Management Methods
  Future<void> _addBookmark() async {
    if (!_isInitialized) return;
    
    final currentMediaId = widget.musicPiece.mediaItems[widget.mediaItemIndex].id;
    final currentPosition = _position;
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
    AppLogger.log('MidiPlayerWidget: Bookmarks saved for ${widget.musicPiece.title}');
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
                  _clearSynthSounds();
                  FlutterPcmSound.stop();
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
                child: ListTile(
                  title: Text(bookmark.name),
                  subtitle: Text(_formatDuration(bookmark.timestamp)),
                  onTap: () => _seekToBookmark(bookmark.timestamp),
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
              );
            },
          ),

        if (activeChannelIndices.isNotEmpty) ...[
          const Divider(),
          const Text('Track Isolation (Mute/Unmute)', style: TextStyle(fontWeight: FontWeight.bold)),
          
          // Channel/Track list
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeChannelIndices.length,
              itemBuilder: (context, index) {
                final channelIndex = activeChannelIndices[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    children: [
                      Text('Ch ${channelIndex + 1}', style: const TextStyle(fontSize: 10)),
                      IconButton(
                        icon: Icon(
                          _channelMutes[channelIndex] ? Icons.volume_off : Icons.volume_up,
                          color: _channelMutes[channelIndex] ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleMute(channelIndex),
                      ),
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
