import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';

class PitchControllablePlayer {
  static final PitchControllablePlayer _instance = PitchControllablePlayer._internal();
  factory PitchControllablePlayer() => _instance;
  
  PitchControllablePlayer._internal();

  static AudioPlayerHandler? _handler;
  
  AudioPlayer get player {
    if (_handler == null) throw Exception("PitchControllablePlayer not initialized. Call initialize() first.");
    return _handler!.player;
  }

  Future<void> initialize() async {
    if (_handler == null) {
      _handler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.repertoire.audio',
          androidNotificationChannelName: 'Repertoire Audio',
          androidNotificationOngoing: true,
        ),
      );
    }
  }

  Future<void> setPitch(double semitones) async {
    if (_handler == null) return;
    final pitchMultiplier = pow(2.0, semitones / 12.0).toDouble();
    await _handler!.player.setPitch(pitchMultiplier);
  }

  Future<void> setUrl(String url, {String? title, String? artist}) async {
    if (_handler == null) return;
    await _handler!.setUrl(url);
    
    // Update notification info
    final item = MediaItem(
      id: url,
      title: title ?? url.split('/').last,
      artist: artist,
      // Duration might not be available yet, but just_audio updates it in the stream
    );
    await _handler!.updateMediaItem(item);
  }

  Future<void> play() async => _handler?.play();
  Future<void> pause() async => _handler?.pause();
  Future<void> stop() async => _handler?.stop();

  Stream<PlayerState> get playerStateStream => _handler?.player.playerStateStream ?? Stream.empty();
  Stream<Duration?> get durationStream => _handler?.player.durationStream ?? Stream.empty();
  Stream<Duration> get positionStream => _handler?.player.positionStream ?? Stream.empty();

  Future<void> dispose() async {
    await stop();
  }
}