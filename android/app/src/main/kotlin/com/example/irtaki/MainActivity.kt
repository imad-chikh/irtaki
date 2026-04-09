package com.example.irtaki

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import java.io.File
import java.util.Locale
import java.util.concurrent.Executors
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val whisperChannelName = "irtaki/whisper_local"
    private val whisperExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, whisperChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        val modelPath = call.argument<String>("modelPath")
                        result.success(WhisperLocalBridge.isAvailable(modelPath))
                    }

                    "transcribe" -> {
                        handleTranscribe(call, result)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun handleTranscribe(call: MethodCall, result: MethodChannel.Result) {
        val audioPath = call.argument<String>("audioPath")
        val modelPath = call.argument<String>("modelPath")
        val language = call.argument<String>("language") ?: "ar"
        val prompt = call.argument<String>("prompt") ?: ""
        val maxAudioSec = call.argument<Int>("maxAudioSec") ?: 8
        val temperature = call.argument<Double>("temperature") ?: 0.0

        if (audioPath.isNullOrBlank() || modelPath.isNullOrBlank()) {
            result.success(
                mapOf(
                    "text" to "",
                    "error" to "Missing audioPath/modelPath for Whisper transcription.",
                    "durationMs" to 0,
                )
            )
            return
        }

        whisperExecutor.execute {
            val output = runCatching {
                WhisperLocalBridge.transcribe(
                    audioPath = audioPath,
                    modelPath = modelPath,
                    language = language,
                    prompt = prompt,
                    maxAudioSec = maxAudioSec,
                    temperature = temperature
                )
            }.getOrElse { e ->
                mapOf(
                    "text" to "",
                    "error" to "Whisper transcription failure: ${e.message}",
                    "durationMs" to 0,
                )
            }

            mainHandler.post {
                result.success(output)
            }
        }
    }
}

object WhisperLocalBridge {
    private val nativeLoaded: Boolean by lazy {
        try {
            System.loadLibrary("whisper_jni")
            true
        } catch (_: Throwable) {
            false
        }
    }

    fun isAvailable(modelPath: String?): Boolean {
        if (modelPath.isNullOrBlank()) return false
        val modelExists = File(modelPath).exists()
        return nativeLoaded && modelExists && nativeIsAvailable(modelPath)
    }

    fun transcribe(
        audioPath: String,
        modelPath: String,
        language: String,
        prompt: String,
        maxAudioSec: Int,
        temperature: Double,
    ): Map<String, Any?> {
        if (!isAvailable(modelPath)) {
            return mapOf(
                "text" to "",
                "error" to "Whisper runtime/model unavailable on Android build.",
                "durationMs" to 0,
            )
        }

        val startedAt = System.currentTimeMillis()
        val text = runCatching {
            nativeTranscribe(
                modelPath = modelPath,
                audioPath = audioPath,
                language = language.lowercase(Locale.ROOT),
                prompt = prompt,
                maxAudioSec = maxAudioSec,
                temperature = temperature.toFloat(),
            )
        }.getOrNull()

        val duration = (System.currentTimeMillis() - startedAt).toInt()
        val cleaned = (text ?: "").trim()

        if (cleaned.isEmpty()) {
            return mapOf(
                "text" to "",
                "error" to "Whisper produced empty transcription.",
                "durationMs" to duration,
                "confidence" to null,
            )
        }

        return mapOf(
            "text" to cleaned,
            "durationMs" to duration,
            "confidence" to null,
            "error" to "",
        )
    }

    @JvmStatic
    private external fun nativeIsAvailable(modelPath: String): Boolean

    @JvmStatic
    private external fun nativeTranscribe(
        modelPath: String,
        audioPath: String,
        language: String,
        prompt: String,
        maxAudioSec: Int,
        temperature: Float,
    ): String?
}
