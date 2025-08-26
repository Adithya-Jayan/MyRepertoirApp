package io.github.adithya_jayan.myrepertoirapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        init {
            System.loadLibrary("soundtouch")
        }
    }
    private lateinit var pitchShifter: RealtimePitchShifter
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pitch_shifter"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    pitchShifter = RealtimePitchShifter()
                    pitchShifter.initializeAudio(sampleRate)
                    result.success(null)
                }
                "setPitch" -> {
                    val semitones = call.argument<Double>("semitones")?.toFloat() ?: 0f
                    pitchShifter.setPitchShift(semitones)
                    result.success(null)
                }
            }
        }
    }
}

