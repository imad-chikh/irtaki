cmake_minimum_required(VERSION 3.22.1)
project(whisper_jni_bridge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(WHISPER_CURL OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

add_subdirectory(whisper_cpp whisper_cpp_build)

add_library(
    whisper_jni
    SHARED
    whisper_jni.cpp
)

target_include_directories(
    whisper_jni
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/whisper_cpp/include
)

target_link_libraries(
    whisper_jni
    PRIVATE
    whisper
    log
    android
)
