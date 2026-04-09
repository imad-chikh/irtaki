#include <jni.h>

#include <algorithm>
#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

#include "whisper.h"

namespace {

struct WavData {
    int sample_rate = 0;
    int channels = 0;
    std::vector<float> mono_f32;
};

bool file_exists(const std::string & path) {
    std::ifstream f(path, std::ios::binary);
    return f.good();
}

uint32_t read_u32(std::ifstream & in) {
    uint8_t b[4];
    in.read(reinterpret_cast<char *>(b), 4);
    return static_cast<uint32_t>(b[0]) |
           (static_cast<uint32_t>(b[1]) << 8) |
           (static_cast<uint32_t>(b[2]) << 16) |
           (static_cast<uint32_t>(b[3]) << 24);
}

uint16_t read_u16(std::ifstream & in) {
    uint8_t b[2];
    in.read(reinterpret_cast<char *>(b), 2);
    return static_cast<uint16_t>(b[0]) |
           (static_cast<uint16_t>(b[1]) << 8);
}

bool load_wav_pcm16(const std::string & path, WavData & out) {
    std::ifstream in(path, std::ios::binary);
    if (!in.good()) {
        return false;
    }

    char riff[4] = {};
    char wave[4] = {};
    in.read(riff, 4);
    (void) read_u32(in);
    in.read(wave, 4);
    if (std::string(riff, 4) != "RIFF" || std::string(wave, 4) != "WAVE") {
        return false;
    }

    bool fmt_found = false;
    bool data_found = false;
    uint16_t audio_format = 0;
    uint16_t channels = 0;
    uint32_t sample_rate = 0;
    std::vector<int16_t> pcm16;

    while (in.good() && (!fmt_found || !data_found)) {
        char chunk_id[4] = {};
        if (!in.read(chunk_id, 4)) {
            break;
        }
        const uint32_t chunk_size = read_u32(in);
        const std::string id(chunk_id, 4);

        if (id == "fmt ") {
            fmt_found = true;
            audio_format = read_u16(in);
            channels = read_u16(in);
            sample_rate = read_u32(in);
            (void) read_u32(in); // byte rate
            (void) read_u16(in); // block align
            const uint16_t bits_per_sample = read_u16(in);
            if (chunk_size > 16) {
                in.seekg(chunk_size - 16, std::ios::cur);
            }
            if (audio_format != 1 || bits_per_sample != 16) {
                return false;
            }
        } else if (id == "data") {
            data_found = true;
            const size_t sample_count = chunk_size / sizeof(int16_t);
            pcm16.resize(sample_count);
            in.read(reinterpret_cast<char *>(pcm16.data()), chunk_size);
        } else {
            in.seekg(chunk_size, std::ios::cur);
        }
    }

    if (!fmt_found || !data_found || channels == 0 || sample_rate == 0 || pcm16.empty()) {
        return false;
    }

    out.sample_rate = static_cast<int>(sample_rate);
    out.channels = static_cast<int>(channels);

    const size_t frames = pcm16.size() / channels;
    out.mono_f32.resize(frames);
    for (size_t i = 0; i < frames; ++i) {
        float mono = 0.0f;
        for (uint16_t ch = 0; ch < channels; ++ch) {
            mono += static_cast<float>(pcm16[i * channels + ch]) / 32768.0f;
        }
        mono /= static_cast<float>(channels);
        out.mono_f32[i] = mono;
    }

    return true;
}

std::vector<float> resample_linear_16k(const std::vector<float> & in, int src_rate) {
    if (src_rate == 16000 || in.empty()) {
        return in;
    }
    const double ratio = 16000.0 / static_cast<double>(src_rate);
    const size_t out_size = static_cast<size_t>(in.size() * ratio);
    std::vector<float> out(out_size);
    for (size_t i = 0; i < out_size; ++i) {
        const double src_pos = static_cast<double>(i) / ratio;
        const size_t x0 = static_cast<size_t>(src_pos);
        const size_t x1 = std::min(x0 + 1, in.size() - 1);
        const float t = static_cast<float>(src_pos - static_cast<double>(x0));
        out[i] = in[x0] * (1.0f - t) + in[x1] * t;
    }
    return out;
}

std::string jstring_to_std(JNIEnv * env, jstring js) {
    if (js == nullptr) {
        return {};
    }
    const char * c = env->GetStringUTFChars(js, nullptr);
    if (c == nullptr) {
        return {};
    }
    std::string out(c);
    env->ReleaseStringUTFChars(js, c);
    return out;
}

} // namespace

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_irtaki_WhisperLocalBridge_nativeIsAvailable(
    JNIEnv * env,
    jclass /*clazz*/,
    jstring modelPath
) {
    const std::string model = jstring_to_std(env, modelPath);
    return file_exists(model) ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_irtaki_WhisperLocalBridge_nativeTranscribe(
    JNIEnv * env,
    jclass /*clazz*/,
    jstring modelPath,
    jstring audioPath,
    jstring language,
    jstring prompt,
    jint maxAudioSec,
    jfloat temperature
) {
    const std::string model = jstring_to_std(env, modelPath);
    const std::string audio = jstring_to_std(env, audioPath);
    const std::string lang = jstring_to_std(env, language);
    const std::string init_prompt = jstring_to_std(env, prompt);

    if (!file_exists(model) || !file_exists(audio)) {
        return env->NewStringUTF("");
    }

    WavData wav;
    if (!load_wav_pcm16(audio, wav)) {
        return env->NewStringUTF("");
    }

    std::vector<float> pcm = resample_linear_16k(wav.mono_f32, wav.sample_rate);
    const int max_samples = std::max(1, static_cast<int>(maxAudioSec)) * 16000;
    if (static_cast<int>(pcm.size()) > max_samples) {
        pcm.resize(max_samples);
    }

    auto cparams = whisper_context_default_params();
    struct whisper_context * ctx = whisper_init_from_file_with_params(model.c_str(), cparams);
    if (ctx == nullptr) {
        return env->NewStringUTF("");
    }

    auto params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress = false;
    params.print_realtime = false;
    params.print_special = false;
    params.print_timestamps = false;
    params.translate = false;
    params.no_context = true;
    params.single_segment = false;
    params.max_len = 0;
    params.n_threads = 4;
    params.temperature = temperature;
    params.language = lang.empty() ? "ar" : lang.c_str();
    params.initial_prompt = init_prompt.empty() ? nullptr : init_prompt.c_str();

    const int rc = whisper_full(ctx, params, pcm.data(), static_cast<int>(pcm.size()));
    if (rc != 0) {
        whisper_free(ctx);
        return env->NewStringUTF("");
    }

    std::string out;
    const int n = whisper_full_n_segments(ctx);
    for (int i = 0; i < n; ++i) {
        const char * s = whisper_full_get_segment_text(ctx, i);
        if (s != nullptr) {
            out += s;
        }
    }

    whisper_free(ctx);
    return env->NewStringUTF(out.c_str());
}
