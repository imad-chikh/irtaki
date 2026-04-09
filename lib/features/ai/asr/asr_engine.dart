import 'package:flutter/foundation.dart';

import 'asr_types.dart';

abstract class AsrEngine {
  AsrEngineType get engineType;

  Future<AsrStartOutcome> startListening({
    required ValueChanged<AsrTranscriptResult> onResult,
  });

  Future<void> stopListening();
  Future<void> cancel();
  bool get isListening;
  String? get lastError;
  Future<void> dispose();
}
