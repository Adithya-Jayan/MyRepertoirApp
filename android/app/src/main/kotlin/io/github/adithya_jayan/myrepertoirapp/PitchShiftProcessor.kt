package io.github.adithya_jayan.myrepertoirapp

class PitchShiftProcessor {
    companion object {
        init {
            System.loadLibrary("soundtouch")
        }
    }
    
    private var soundTouchHandle: Long = 0
    
    external fun createSoundTouch(sampleRate: Int, channels: Int): Long
    external fun destroySoundTouch(handle: Long)
    external fun setPitchSemiTones(handle: Long, pitch: Float)
    external fun putSamples(handle: Long, samples: FloatArray, numSamples: Int)
    external fun receiveSamples(handle: Long, output: FloatArray, maxSamples: Int): Int
    external fun flush(handle: Long)
    
    fun initialize(sampleRate: Int, channels: Int = 2) {
        soundTouchHandle = createSoundTouch(sampleRate, channels)
    }
    
    fun setPitch(semitones: Float) {
        setPitchSemiTones(soundTouchHandle, semitones)
    }
    
    fun processAudio(input: FloatArray): FloatArray {
        putSamples(soundTouchHandle, input, input.size / 2) // stereo
        val output = FloatArray(input.size)
        val received = receiveSamples(soundTouchHandle, output, output.size / 2)
        return output.sliceArray(0 until received * 2)
    }
}
