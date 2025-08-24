import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:repertoire/utils/app_logger.dart';

class AudioPlayerService extends ChangeNotifier {
  ja.AudioPlayer? _player;
  String? _currentAudioId;
  double _currentPitch = 1.0; // Track current pitch (1.0 = normal)
  double _currentSpeed = 1.0; // Track current speed (1.0 = normal)

  ja.AudioPlayer get player {
    _player ??= ja.AudioPlayer();
    return _player!;
  }

  String? get currentAudioId => _currentAudioId;
  double get currentPitch => _currentPitch;
  double get currentSpeed => _currentSpeed;

  /// Stream getters to listen to player state changes
  Stream<ja.PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<double> get speedStream => player.speedStream;

  Future<void> loadAndPlay(String audioPath, String audioId) async {
    try {
      if (_currentAudioId != audioId) {
        // If a different audio is playing, stop it first
        if (_player != null && _player!.playing) {
          await _player!.stop();
        }
        _currentAudioId = audioId;
        await player.setAudioSource(ja.AudioSource.uri(Uri.parse(audioPath)));
        
        // Restore pitch and speed settings for new audio
        await _applyPitchAndSpeed();
      }
      await player.play();
      AppLogger.log('AudioPlayerService: Playing audio: $audioPath (ID: $audioId)');
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error loading or playing audio: $e');
      _currentAudioId = null;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> play() async {
    try {
      await player.play();
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await player.pause();
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error pausing audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await player.stop();
      _currentAudioId = null;
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error stopping audio: $e');
    }
  }

  /// Set pitch (0.5 - 2.0 range recommended)
  Future<void> setPitch(double pitch) async {
    try {
      // Clamp pitch to reasonable range
      pitch = pitch.clamp(0.25, 4.0);
      _currentPitch = pitch;
      
      if (_player != null) {
        await _applyPitchAndSpeed();
      }
      
      AppLogger.log('AudioPlayerService: Pitch set to: $pitch');
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error setting pitch: $e');
      rethrow;
    }
  }

  /// Set playback speed (0.5 - 2.0 range recommended)
  Future<void> setSpeed(double speed) async {
    try {
      // Clamp speed to reasonable range
      speed = speed.clamp(0.25, 4.0);
      _currentSpeed = speed;
      
      if (_player != null) {
        await player.setSpeed(speed);
      }
      
      AppLogger.log('AudioPlayerService: Speed set to: $speed');
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error setting speed: $e');
      rethrow;
    }
  }

  /// Apply both pitch and speed settings
  Future<void> _applyPitchAndSpeed() async {
    try {
      // Apply speed and pitch settings
      await player.setSpeed(_currentSpeed);
      await player.setPitch(_currentPitch);
      
      AppLogger.log('AudioPlayerService: Applied speed: $_currentSpeed, pitch: $_currentPitch');
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error applying pitch/speed: $e');
    }
  }

  /// Reset pitch and speed to normal values
  Future<void> resetPitchAndSpeed() async {
    await setPitch(1.0);
    await setSpeed(1.0);
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      await player.seek(position);
      notifyListeners();
    } catch (e) {
      AppLogger.log('AudioPlayerService: Error seeking: $e');
    }
  }

  /// Get current position
  Duration get currentPosition => player.position;

  /// Get total duration
  Duration? get totalDuration => player.duration;

  /// Check if currently playing
  bool get isPlaying => player.playing;

  /// Get current player state
  ja.PlayerState get playerState => player.playerState;

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
    super.dispose();
  }
}