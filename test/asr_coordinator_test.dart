import 'package:flutter_test/flutter_test.dart';
import 'package:irtaki/features/ai/asr/asr_coordinator.dart';
import 'package:irtaki/features/ai/asr/asr_engine.dart';
import 'package:irtaki/features/ai/asr/asr_types.dart';

class _FakeEngine implements AsrEngine {
  final AsrEngineType type;
  final AsrStartOutcome startOutcome;
  final String? error;
  final AsrTranscriptResult? emitResult;
  bool _listening = false;

  _FakeEngine({
    required this.type,
    required this.startOutcome,
    this.error,
    this.emitResult,
  });

  @override
  AsrEngineType get engineType => type;

  @override
  bool get isListening => _listening;

  @override
  String? get lastError => error;

  @override
  Future<AsrStartOutcome> startListening({
    required void Function(AsrTranscriptResult p1) onResult,
  }) async {
    _listening = startOutcome == AsrStartOutcome.started;
    if (emitResult != null) {
      onResult(emitResult!);
    }
    return startOutcome;
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
  }

  @override
  Future<void> cancel() async {
    _listening = false;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('AsrCoordinator', () {
    test('uses whisper when whisper starts successfully', () async {
      final whisper = _FakeEngine(
        type: AsrEngineType.whisperLocal,
        startOutcome: AsrStartOutcome.started,
        emitResult: const AsrTranscriptResult(
          text: 'الحمد لله',
          isFinal: true,
          engineType: AsrEngineType.whisperLocal,
        ),
      );
      final fallback = _FakeEngine(
        type: AsrEngineType.nativeFallback,
        startOutcome: AsrStartOutcome.started,
      );
      final coordinator = AsrCoordinator(whisper: whisper, fallback: fallback);

      AsrTranscriptResult? captured;
      final outcome = await coordinator.startListening(
        onResult: (r) => captured = r,
      );

      expect(outcome, AsrStartOutcome.started);
      expect(captured, isNotNull);
      expect(captured!.engineType, AsrEngineType.whisperLocal);
      expect(captured!.fallbackUsed, isFalse);
      expect(coordinator.lastEngineUsed, AsrEngineType.whisperLocal);
    });

    test('falls back when whisper is unavailable', () async {
      final whisper = _FakeEngine(
        type: AsrEngineType.whisperLocal,
        startOutcome: AsrStartOutcome.unavailable,
        error: 'whisper unavailable',
      );
      final fallback = _FakeEngine(
        type: AsrEngineType.nativeFallback,
        startOutcome: AsrStartOutcome.started,
        emitResult: const AsrTranscriptResult(
          text: 'الرحمن الرحيم',
          isFinal: true,
          engineType: AsrEngineType.nativeFallback,
          fallbackUsed: true,
        ),
      );
      final coordinator = AsrCoordinator(whisper: whisper, fallback: fallback);

      AsrTranscriptResult? captured;
      final outcome = await coordinator.startListening(
        onResult: (r) => captured = r,
      );

      expect(outcome, AsrStartOutcome.started);
      expect(captured, isNotNull);
      expect(captured!.engineType, AsrEngineType.nativeFallback);
      expect(captured!.fallbackUsed, isTrue);
      expect(coordinator.lastEngineUsed, AsrEngineType.nativeFallback);
    });
  });
}
