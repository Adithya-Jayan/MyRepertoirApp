import 'package:just_audio/just_audio.dart';
import 'package:repertoire/services/pitch_shifter.dart';

class PitchControllablePlayer {
  final AudioPlayer _player = AudioPlayer();
  double _currentPitch = 0.0;
  
  AudioPlayer get player => _player;
  
  Future<void> initialize() async {
    await PitchShifter.initialize();
  }
  
  Future<void> setPitch(double semitones) async {
    _currentPitch = semitones;
    await PitchShifter.setPitch(semitones);
  }
  
  double get pitch => _currentPitch;
  
  // Wrapper methods for just_audio
  Future<void> setUrl(String url) => _player.setUrl(url);
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
}
