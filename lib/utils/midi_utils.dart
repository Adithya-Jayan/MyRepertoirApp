import 'dart:io';
import 'package:dart_midi_pro/dart_midi_pro.dart' as midi_parser;

class MidiUtils {
  static Future<Map<int, String>> getChannelNames(String filePath) async {
    final Map<int, String> channelNames = {};
    try {
      final file = File(filePath);
      if (!await file.exists()) return {};
      
      final midiData = await file.readAsBytes();
      final parsedMidi = midi_parser.MidiParser().parseMidiFromBuffer(midiData);

      for (var track in parsedMidi.tracks) {
        String? trackName;
        final Set<int> usedChannels = {};

        for (var event in track) {
          if (event is midi_parser.TrackNameEvent) {
            trackName = event.text;
          } else if (event is midi_parser.NoteOnEvent) {
            usedChannels.add(event.channel);
          } else if (event is midi_parser.NoteOffEvent) {
            usedChannels.add(event.channel);
          }
        }

        if (trackName != null && usedChannels.isNotEmpty) {
          for (var ch in usedChannels) {
            if (!channelNames.containsKey(ch)) {
              channelNames[ch] = trackName;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return channelNames;
  }

  static Future<List<int>> getActiveChannels(String filePath) async {
    final Set<int> activeChannels = {};
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];
      
      final midiData = await file.readAsBytes();
      final parsedMidi = midi_parser.MidiParser().parseMidiFromBuffer(midiData);

      for (var track in parsedMidi.tracks) {
        for (var event in track) {
          if (event is midi_parser.NoteOnEvent) {
            activeChannels.add(event.channel);
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    final list = activeChannels.toList()..sort();
    return list;
  }
}
