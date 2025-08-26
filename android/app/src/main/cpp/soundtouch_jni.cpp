#include <jni.h>
#include <string>
#include "SoundTouch.h"

using namespace soundtouch;

extern "C" JNIEXPORT jlong JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_createSoundTouch(
    JNIEnv *env, jobject /* this */, jint sampleRate, jint channels) {
    SoundTouch *soundTouch = new SoundTouch();
    soundTouch->setSampleRate(sampleRate);
    soundTouch->setChannels(channels);
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
    JNIEnv *env, jobject /* this */, jlong handle, jfloatArray samples, jint numSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jfloat *samplesPtr = env->GetFloatArrayElements(samples, NULL);
    soundTouch->putSamples(samplesPtr, numSamples);
    env->ReleaseFloatArrayElements(samples, samplesPtr, 0);
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_receiveSamples(
    JNIEnv *env, jobject /* this */, jlong handle, jfloatArray output, jint maxSamples) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    jfloat *outputPtr = env->GetFloatArrayElements(output, NULL);
    int received = soundTouch->receiveSamples(outputPtr, maxSamples);
    env->ReleaseFloatArrayElements(output, outputPtr, 0);
    return received;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_adithya_1jayan_myrepertoirapp_PitchShiftProcessor_flush(
    JNIEnv *env, jobject /* this */, jlong handle) {
    SoundTouch *soundTouch = reinterpret_cast<SoundTouch *>(handle);
    soundTouch->flush();
}
