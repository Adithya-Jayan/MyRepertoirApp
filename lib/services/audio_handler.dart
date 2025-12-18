import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/app_logger.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = List<MediaItem>.from(queue.value);
      if (index != null && index < newQueue.length) {
        final oldMediaItem = newQueue[index];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        newQueue[index] = newMediaItem;
        queue.add(newQueue);
        mediaItem.add(newMediaItem);
      } else {
        // If queue is empty or index invalid, just update current mediaItem if it exists
        final current = mediaItem.value;
        if (current != null) {
           mediaItem.add(current.copyWith(duration: duration));
        }
      }
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  // Used to access the underlying player for pitch control
  AudioPlayer get player => _player;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setUrl(String url) async {
    try {
      await _player.setFilePath(url);
    } catch (e) {
      AppLogger.log('AudioPlayerHandler: setFilePath failed: $e. Trying setUrl with URI.');
      // Fallback for non-file URLs or if setFilePath fails
      // Ensure we convert file path to proper URI if it's a file path
      try {
        final uri = Uri.file(url).toString();
        await _player.setUrl(uri);
      } catch (e2) {
         // If that also fails, try raw url (maybe it was already a web URL)
         AppLogger.log('AudioPlayerHandler: setUrl(Uri) failed: $e2. Trying raw setUrl.');
         await _player.setUrl(url);
      }
    }
  }
  
  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  /// Transform just_audio events into audio_service states
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }
}
