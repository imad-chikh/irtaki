import 'package:flutter/foundation.dart';

import 'asr_engine.dart';
import 'asr_types.dart';

class AsrCoordinator implements AsrEngine {
  final AsrEngine whisper;
  final AsrEngine fallback;

  AsrEngine? _activeEngine;
  AsrEngineType? _lastEngineUsed;
  String? _lastError;

  AsrCoordinator({required this.whisper, required this.fallback});

  AsrEngineType? get lastEngineUsed => _lastEngineUsed;

  @override
  AsrEngineType get engineType =>
      _activeEngine?.engineType ?? AsrEngineType.whisperLocal;

  @override
  String? get lastError => _lastError ?? _activeEngine?.lastError;

  @override
  bool get isListening => (_activeEngine?.isListening ?? false);

  @override
  Future<AsrStartOutcome> startListening({
    required ValueChanged<AsrTranscriptResult> onResult,
  }) async {
    _lastError = null;

    final whisperOutcome = await whisper.startListening(
      onResult: (result) {
        _lastEngineUsed = AsrEngineType.whisperLocal;
        onResult(
          AsrTranscriptResult(
            text: result.text,
            isFinal: result.isFinal,
            confidence: result.confidence,
            engineType: AsrEngineType.whisperLocal,
            durationMs: result.durationMs,
            fallbackUsed: false,
          ),
        );
      },
    );

    if (whisperOutcome == AsrStartOutcome.started) {
      _activeEngine = whisper;
      _lastEngineUsed = AsrEngineType.whisperLocal;
      return AsrStartOutcome.started;
    }

    final whisperError = whisper.lastError;

    final fallbackOutcome = await fallback.startListening(
      onResult: (result) {
        _lastEngineUsed = AsrEngineType.nativeFallback;
        onResult(
          AsrTranscriptResult(
            text: result.text,
            isFinal: result.isFinal,
            confidence: result.confidence,
            engineType: AsrEngineType.nativeFallback,
            durationMs: result.durationMs,
            fallbackUsed: true,
          ),
        );
      },
    );

    if (fallbackOutcome == AsrStartOutcome.started) {
      _activeEngine = fallback;
      _lastEngineUsed = AsrEngineType.nativeFallback;
      _lastError = whisperError;
      return AsrStartOutcome.started;
    }

    _lastError = [
      if (whisperError != null && whisperError.trim().isNotEmpty) whisperError,
      if (fallback.lastError != null && fallback.lastError!.trim().isNotEmpty)
        fallback.lastError!,
    ].join(' | ');

    return fallbackOutcome;
  }

  @override
  Future<void> stopListening() async {
    final current = _activeEngine;
    if (current != null) {
      await current.stopListening();
      return;
    }
    await whisper.stopListening();
    await fallback.stopListening();
  }

  @override
  Future<void> cancel() async {
    final current = _activeEngine;
    if (current != null) {
      await current.cancel();
      return;
    }
    await whisper.cancel();
    await fallback.cancel();
  }

  @override
  Future<void> dispose() async {
    await whisper.dispose();
    await fallback.dispose();
  }
}
