import 'package:just_audio/just_audio.dart';

class PitchControllablePlayer {
  final AudioPlayer _player = AudioPlayer();
  double _currentPitch = 0.0;


  AudioPlayer get player => _player;

  Future<void> initialize() async {}

  Future<void> setPitch(double semitones) async {
    // Temporarily disabled pitch shifting to fix loading issues
    _currentPitch = semitones;
  }

  double get pitch => _currentPitch;

  Future<void> setUrl(String url) async {
    await _player.setFilePath(url);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() async {
    await _player.stop();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> dispose() async {
    await _player.dispose();
  }
}

