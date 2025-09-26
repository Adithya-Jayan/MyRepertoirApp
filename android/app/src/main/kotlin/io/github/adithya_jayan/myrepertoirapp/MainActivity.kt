package io.github.adithya_jayan.myrepertoirapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity: FlutterActivity() {
    companion object {
        init {
            System.loadLibrary("soundtouch")
        }
    }
    private val pitchShifter: RealtimePitchShifter = RealtimePitchShifter()
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pitch_shifter"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    val channels = call.argument<Int>("channels") ?: 2
                    pitchShifter.initializeAudio(sampleRate, channels)
                    result.success(null)
                }
                "setPitch" -> {
                    val semitones = call.argument<Double>("semitones")?.toFloat() ?: 0f
                    pitchShifter.setPitchShift(semitones)
                    result.success(null)
                }
                "process" -> {
                    val inputBuffer = call.argument<ByteBuffer>("inputBuffer")!!
                    val outputBuffer = call.argument<ByteBuffer>("outputBuffer")!!
                    inputBuffer.order(ByteOrder.nativeOrder())
                    outputBuffer.order(ByteOrder.nativeOrder())
                    val processedBytes = pitchShifter.process(inputBuffer, outputBuffer)
                    result.success(processedBytes)
                }
                "flushAndReceive" -> {
                    val outputBuffer = call.argument<ByteBuffer>("outputBuffer")!!
                    outputBuffer.order(ByteOrder.nativeOrder())
                    val flushedBytes = pitchShifter.flushAndReceive(outputBuffer)
                    result.success(flushedBytes)
                }
                "release" -> {
                    pitchShifter.release()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

