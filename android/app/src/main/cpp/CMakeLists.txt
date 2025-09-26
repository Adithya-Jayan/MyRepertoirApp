cmake_minimum_required(VERSION 3.10.2)

project("soundtouch_jni")

add_library(
    soundtouch
    SHARED
    IMPORTED
)

set_target_properties(
    soundtouch
    PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libsoundtouch.so
)

add_library(
    soundtouch_jni
    SHARED
    src/main/cpp/soundtouch_jni.cpp # This file will contain JNI functions
)

target_link_libraries(
    soundtouch_jni
    soundtouch
    log
)
