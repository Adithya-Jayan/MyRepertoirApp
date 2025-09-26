package io.github.adithya_jayan.myrepertoirapp

import java.nio.ByteBuffer
import java.nio.ShortBuffer

class PitchShiftProcessor {
    companion object {
        init {
            System.loadLibrary("soundtouch")
        }
    }
    
    private var soundTouchHandle: Long = 0
    private var channels: Int = 0
    
    external fun createSoundTouch(sampleRate: Int, channels: Int): Long
    external fun destroySoundTouch(handle: Long)
    external fun setPitchSemiTones(handle: Long, pitch: Float)
    external fun putSamples(handle: Long, samples: ShortBuffer, numSamples: Int)
    external fun receiveSamples(handle: Long, output: ShortBuffer, maxSamples: Int): Int
    external fun flush(handle: Long)
    external fun flushAndReceiveSamples(handle: Long, output: ShortBuffer, maxSamples: Int): Int
    
    fun initialize(sampleRate: Int, channels: Int = 2) {
        soundTouchHandle = createSoundTouch(sampleRate, channels)
        this.channels = channels
    }
    
    fun setPitch(semitones: Float) {
        setPitchSemiTones(soundTouchHandle, semitones)
    }
    
    fun processAudio(input: ByteBuffer, output: ByteBuffer): Int {
        val inputShortBuffer = input.asShortBuffer()
        val outputShortBuffer = output.asShortBuffer()
        val numSamples = inputShortBuffer.remaining()
        putSamples(soundTouchHandle, inputShortBuffer, numSamples / this.channels) // numSamples is total shorts, SoundTouch expects per channel
        return receiveSamples(soundTouchHandle, outputShortBuffer, outputShortBuffer.remaining() / this.channels) * 2 // return bytes received (2 bytes per short)
    }

    fun flushAndReceive(output: ByteBuffer): Int {
        val outputShortBuffer = output.asShortBuffer()
        return flushAndReceiveSamples(soundTouchHandle, outputShortBuffer, outputShortBuffer.remaining() / this.channels) * 2 // return bytes received (2 bytes per short)
    }

    fun release() {
        destroySoundTouch(soundTouchHandle)
        soundTouchHandle = 0
    }
}

