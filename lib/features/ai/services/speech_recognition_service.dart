import 'package:flutter/foundation.dart';

enum SpeechStartOutcome {
  started,
  denied,
  deniedPermanently,
  unavailable,
  error,
}

class SpeechRecognitionResult {
  final String transcript;
  final bool isFinal;
  final double confidence;

  const SpeechRecognitionResult({
    required this.transcript,
    required this.isFinal,
    required this.confidence,
  });
}

abstract class SpeechRecognitionService {
  Future<SpeechStartOutcome> startListening({
    required ValueChanged<SpeechRecognitionResult> onResult,
  });

  Future<void> stopListening();
  Future<void> cancel();
  bool get isListening;
  String? get lastError;
  Future<void> dispose();
}
