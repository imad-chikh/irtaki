enum AsrEngineType { whisperLocal, nativeFallback }

enum AsrStartOutcome { started, denied, deniedPermanently, unavailable, error }

class AsrTranscriptResult {
  final String text;
  final bool isFinal;
  final double? confidence;
  final AsrEngineType engineType;
  final int? durationMs;
  final bool fallbackUsed;

  const AsrTranscriptResult({
    required this.text,
    required this.isFinal,
    required this.engineType,
    this.confidence,
    this.durationMs,
    this.fallbackUsed = false,
  });
}
