import 'package:flutter/foundation.dart';

import '../services/native_arabic_stt_service.dart';
import '../services/speech_recognition_service.dart';
import 'asr_engine.dart';
import 'asr_types.dart';

class NativeSttAsrEngine implements AsrEngine {
  final NativeArabicSttService _native;

  NativeSttAsrEngine({NativeArabicSttService? native})
    : _native = native ?? NativeArabicSttService();

  @override
  AsrEngineType get engineType => AsrEngineType.nativeFallback;

  @override
  String? get lastError => _native.lastError;

  @override
  bool get isListening => _native.isListening;

  @override
  Future<AsrStartOutcome> startListening({
    required ValueChanged<AsrTranscriptResult> onResult,
  }) async {
    final outcome = await _native.startListening(
      onResult: (result) {
        onResult(
          AsrTranscriptResult(
            text: result.transcript,
            isFinal: result.isFinal,
            confidence: result.confidence,
            engineType: AsrEngineType.nativeFallback,
            fallbackUsed: true,
          ),
        );
      },
    );

    return _mapOutcome(outcome);
  }

  @override
  Future<void> stopListening() => _native.stopListening();

  @override
  Future<void> cancel() => _native.cancel();

  @override
  Future<void> dispose() => _native.dispose();

  AsrStartOutcome _mapOutcome(SpeechStartOutcome outcome) {
    switch (outcome) {
      case SpeechStartOutcome.started:
        return AsrStartOutcome.started;
      case SpeechStartOutcome.denied:
        return AsrStartOutcome.denied;
      case SpeechStartOutcome.deniedPermanently:
        return AsrStartOutcome.deniedPermanently;
      case SpeechStartOutcome.unavailable:
        return AsrStartOutcome.unavailable;
      case SpeechStartOutcome.error:
        return AsrStartOutcome.error;
    }
  }
}
