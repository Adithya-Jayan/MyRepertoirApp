package io.github.adithya_jayan.myrepertoirapp

import java.nio.ByteBuffer
import java.nio.ByteOrder

class RealtimePitchShifter {
    private val pitchProcessor = PitchShiftProcessor()
    private var initialized = false

    fun initializeAudio(sampleRate: Int, channels: Int) {
        if (!initialized) {
            pitchProcessor.initialize(sampleRate, channels)
            initialized = true
        }
    }

    fun setPitchShift(semitones: Float) {
        if (initialized) {
            pitchProcessor.setPitch(semitones)
        }
    }

    fun process(inputBuffer: ByteBuffer, outputBuffer: ByteBuffer): Int {
        if (!initialized) return 0
        return pitchProcessor.processAudio(inputBuffer, outputBuffer)
    }

    fun flushAndReceive(outputBuffer: ByteBuffer): Int {
        if (!initialized) return 0
        return pitchProcessor.flushAndReceive(outputBuffer)
    }
    
    fun release() {
        if (initialized) {
            pitchProcessor.release()
            initialized = false
        }
    }
}

