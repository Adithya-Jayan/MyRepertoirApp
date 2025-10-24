import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

import 'package:repertoire/services/pitch_shifter.dart';
import '../../utils/app_logger.dart';


// Helper function to generate a WAV header with unknown length
Uint8List _generateWavHeader(int sampleRate, int channels) {
  final byteData = ByteData(44); // WAV header is 44 bytes

  // RIFF chunk
  byteData.setUint32(0, 0x46464952, Endian.little); // "RIFF"
  byteData.setUint32(4, 0xFFFFFFFF, Endian.little); // ChunkSize (unknown length)
  byteData.setUint32(8, 0x45564157, Endian.little); // "WAVE"

  // fmt chunk
  byteData.setUint32(12, 0x20746D66, Endian.little); // "fmt "
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
  byteData.setUint16(22, channels, Endian.little); // NumChannels
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(28, sampleRate * channels * 2, Endian.little); // ByteRate
  byteData.setUint16(32, channels * 2, Endian.little); // BlockAlign
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16-bit PCM)

  // data chunk
  byteData.setUint32(36, 0x61746164, Endian.little); // "data"
  byteData.setUint32(40, 0xFFFFFFFF, Endian.little); // Subchunk2Size (unknown length)

  return byteData.buffer.asUint8List();
}

class SoundTouchAudioSource extends StreamAudioSource {
  final Stream<List<int>> Function() streamProvider;
  final int sampleRate;
  final int channels;
  final int bufferSize;

  SoundTouchAudioSource({
    required this.streamProvider,
    required this.sampleRate,
    required this.channels,
    required this.bufferSize,
    super.tag,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final inputStream = streamProvider();

    // Initialize SoundTouch for this stream
    await PitchShifter.initialize(sampleRate: sampleRate, channels: channels);

    final wavHeader = _generateWavHeader(sampleRate, channels);

    return StreamAudioResponse(
      sourceLength: null, // Unknown length as it's a stream
      contentLength: null, // Unknown length
      offset: 0,
      contentType: 'audio/wav', // Indicate WAV audio
      stream: _byteStreamToSoundTouchStream(inputStream, wavHeader),
    );
  }

  Stream<Uint8List> _byteStreamToSoundTouchStream(Stream<List<int>> inputStream, Uint8List wavHeader) async* {
    final inputBufferList = <int>[];
    final targetBufferSize = bufferSize;

    yield wavHeader; // Prepend the WAV header

    try {
      await for (var chunk in inputStream) {
        inputBufferList.addAll(chunk);

        // Process complete buffers
        while (inputBufferList.length >= targetBufferSize) {
          final processBuffer = Uint8List.fromList(inputBufferList.take(targetBufferSize).toList());
          inputBufferList.removeRange(0, targetBufferSize);

          final outputByteBuffer = Uint8List(bufferSize * 2); // 2 bytes per short
          final processedBytes = await PitchShifter.process(processBuffer.buffer, outputByteBuffer.buffer);

          if (processedBytes > 0) {
            AppLogger.log('SoundTouchAudioSource: Yielding processed bytes: $processedBytes');
            yield outputByteBuffer.sublist(0, processedBytes);
          }
        }
      }

      // Process remaining bytes
      if (inputBufferList.isNotEmpty) {
        final processBuffer = Uint8List.fromList(inputBufferList);
        final outputByteBuffer = Uint8List(bufferSize * 2);
        final processedBytes = await PitchShifter.process(processBuffer.buffer, outputByteBuffer.buffer);

        if (processedBytes > 0) {
          AppLogger.log('SoundTouchAudioSource: Yielding remaining processed bytes: $processedBytes');
          yield outputByteBuffer.sublist(0, processedBytes);
        }
      }

      // Flush
      final outputByteBuffer = Uint8List(bufferSize * 2);
      final flushedBytes = await PitchShifter.flushAndReceive(outputByteBuffer.buffer);
      if (flushedBytes > 0) {
        AppLogger.log('SoundTouchAudioSource: Yielding flushed bytes: $flushedBytes');
        yield outputByteBuffer.sublist(0, flushedBytes);
      }
    } finally {
      AppLogger.log('SoundTouchAudioSource: Releasing PitchShifter resources.');
      await PitchShifter.release();
    }
  }
}
