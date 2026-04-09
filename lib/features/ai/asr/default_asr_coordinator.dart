import 'asr_coordinator.dart';
import 'native_stt_asr_engine.dart';
import 'whisper_local_asr_engine.dart';

AsrCoordinator createDefaultAsrCoordinator() {
  return AsrCoordinator(
    whisper: WhisperLocalAsrEngine(),
    fallback: NativeSttAsrEngine(),
  );
}
