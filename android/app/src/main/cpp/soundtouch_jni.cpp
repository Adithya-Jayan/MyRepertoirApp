#include <jni.h>
#include <string>
#include <stddef.h> // For NULL
#include "SoundTouch.h"

using namespace soundtouch;

#include <jni.h>
#include <string>
#include <stddef.h> // For NULL
#include "SoundTouch.h"

using namespace soundtouch;

// Helper function to convert float to short (PCM 16-bit)
short floatToShort(float sample) {
    return (short) (sample * 32767.0f);
}

// Helper function to convert short (PCM 16-bit) to float
float shortToFloat(short sample) {
    return (float) sample / 32767.0f;
}

extern "C" JNIEXPORT jlong JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_createSoundTouch(
    JNIEnv *env, jobject /* this */, jint sampleRate, jint channels) {
    SoundTouch *soundTouch = new SoundTouch();
    soundTouch->setSampleRate(sampleRate);
    soundTouch->setChannels(channels);
    soundTouch->setSetting(SETTING_SEQUENCE_MS, 82);
    soundTouch->setSetting(SETTING_SEEKWINDOW_MS, 100);
    soundTouch->setSetting(SETTING_OVERLAP_MS, 20);
    return reinterpret_cast<jlong>(soundTouch);
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_destroySoundTouch(
    JNIEnv *env, jobject /* this */, jlong handle) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    delete soundTouch;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_setPitchSemiTones(
    JNIEnv *env, jobject /* this */, jlong handle, jfloat pitch) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    soundTouch->setPitchSemiTones(pitch);
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_putSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject samples, jint numSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jshort *samplesPtr = (jshort*)env->GetDirectBufferAddress(samples);

    // Convert short samples to float for SoundTouch
    float *floatSamples = new float[numSamples];
    for (int i = 0; i < numSamples; ++i) {
        floatSamples[i] = shortToFloat(samplesPtr[i]);
    }
    soundTouch->putSamples(floatSamples, numSamples);
    delete[] floatSamples;
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_receiveSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject output, jint maxSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jshort *outputPtr = (jshort*)env->GetDirectBufferAddress(output);

    // Receive float samples from SoundTouch
    float *floatOutput = new float[maxSamples];
    int received = soundTouch->receiveSamples(floatOutput, maxSamples);

    // Convert float samples to short for output
    for (int i = 0; i < received; ++i) {
        outputPtr[i] = floatToShort(floatOutput[i]);
    }
    delete[] floatOutput;
    return received;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_flush(
    JNIEnv *env, jobject /* this */, jlong handle) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    soundTouch->flush();
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_flushAndReceiveSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject output, jint maxSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jshort *outputPtr = (jshort*)env->GetDirectBufferAddress(output);

    // Receive float samples from SoundTouch
    float *floatOutput = new float[maxSamples];
    int received = soundTouch->flushAndReceive(floatOutput, maxSamples);

    // Convert float samples to short for output
    for (int i = 0; i < received; ++i) {
        outputPtr[i] = floatToShort(floatOutput[i]);
    }
    delete[] floatOutput;
    return received;
}


extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_destroySoundTouch(
    JNIEnv *env, jobject /* this */, jlong handle) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    delete soundTouch;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_setPitchSemiTones(
    JNIEnv *env, jobject /* this */, jlong handle, jfloat pitch) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    soundTouch->setPitchSemiTones(pitch);
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_putSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject samples, jint numSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jfloat *samplesPtr = (jfloat*)env->GetDirectBufferAddress(samples);
    soundTouch->putSamples(samplesPtr, numSamples);
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_receiveSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject output, jint maxSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jshort *outputPtr = (jshort*)env->GetDirectBufferAddress(output);

    // Receive float samples from SoundTouch
    float *floatOutput = new float[maxSamples];
    int received = soundTouch->receiveSamples(floatOutput, maxSamples);

    // Convert float samples to short for output
    for (int i = 0; i < received; ++i) {
        outputPtr[i] = floatToShort(floatOutput[i]);
    }
    delete[] floatOutput;
    return received;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_flush(
    JNIEnv *env, jobject /* this */, jlong handle) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    soundTouch->flush();
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_flushAndReceiveSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jobject output, jint maxSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jshort *outputPtr = (jshort*)env->GetDirectBufferAddress(output);

    // Receive float samples from SoundTouch
    float *floatOutput = new float[maxSamples];
    soundTouch->flush();
    int received = soundTouch->receiveSamples(floatOutput, maxSamples);

    // Convert float samples to short for output
    for (int i = 0; i < received; ++i) {
        outputPtr[i] = floatToShort(floatOutput[i]);
    }
    delete[] floatOutput;
    return received;
}

