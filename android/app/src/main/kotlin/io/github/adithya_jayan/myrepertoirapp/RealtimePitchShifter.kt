package io.github.adithya_jayan.myrepertoirapp

import android.media.AudioTrack
import android.media.AudioFormat
import android.media.AudioManager

class RealtimePitchShifter {
    private val pitchProcessor = PitchShiftProcessor()
    private lateinit var audioTrack: AudioTrack
    private var isProcessing = false
    
    fun initializeAudio(sampleRate: Int) {
        pitchProcessor.initialize(sampleRate, 2)
        
        val bufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_FLOAT
        )
        
        audioTrack = AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_FLOAT,
            bufferSize,
            AudioTrack.MODE_STREAM
        )
    }
    
    fun setPitchShift(semitones: Float) {
        pitchProcessor.setPitch(semitones)
    }
    
    fun processAudioBuffer(inputBuffer: FloatArray): FloatArray {
        return pitchProcessor.processAudio(inputBuffer)
    }
}
