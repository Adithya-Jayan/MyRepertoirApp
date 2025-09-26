import 'dart:typed_data';
import 'package:flutter/services.dart';

class PitchShifter {
  static const MethodChannel _channel = MethodChannel('pitch_shifter');
  
  static Future<void> initialize({int sampleRate = 44100, int channels = 2}) async {
    await _channel.invokeMethod('initialize', {
      'sampleRate': sampleRate,
      'channels': channels,
    });
  }
  
  static Future<void> setPitch(double semitones) async {
    await _channel.invokeMethod('setPitch', {
      'semitones': semitones,
    });
  }

  static Future<int> process(ByteBuffer inputBuffer, ByteBuffer outputBuffer) async {
    final result = await _channel.invokeMethod('process', {
      'inputBuffer': inputBuffer,
      'outputBuffer': outputBuffer,
    });
    return result as int;
  }

  static Future<int> flushAndReceive(ByteBuffer outputBuffer) async {
    final result = await _channel.invokeMethod('flushAndReceive', {
      'outputBuffer': outputBuffer,
    });
    return result as int;
  }

  static Future<void> release() async {
    await _channel.invokeMethod('release');
  }
}

