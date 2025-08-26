import 'package:flutter/services.dart';

class PitchShifter {
  static const MethodChannel _channel = MethodChannel('pitch_shifter');
  
  static Future<void> initialize({int sampleRate = 44100}) async {
    await _channel.invokeMethod('initialize', {
      'sampleRate': sampleRate,
    });
  }
  
  static Future<void> setPitch(double semitones) async {
    await _channel.invokeMethod('setPitch', {
      'semitones': semitones,
    });
  }
}
