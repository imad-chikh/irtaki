import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_service.dart';

class NativeArabicSttService implements SpeechRecognitionService {
  final SpeechToText _speech = SpeechToText();
  String? _lastError;

  @override
  String? get lastError => _lastError;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<SpeechStartOutcome> startListening({
    required ValueChanged<SpeechRecognitionResult> onResult,
  }) async {
    _lastError = null;

    if (kIsWeb) {
      _lastError = 'Voice search is not enabled on web.';
      return SpeechStartOutcome.unavailable;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      _lastError = 'Voice search is available on Android and iOS only.';
      return SpeechStartOutcome.unavailable;
    }

    final micOutcome = await _ensurePermission(
      permission: Permission.microphone,
      deniedMessage: 'Microphone permission denied.',
      deniedPermanentlyMessage: 'Microphone permission is permanently denied.',
    );
    if (micOutcome != SpeechStartOutcome.started) {
      return micOutcome;
    }

    if (platform == TargetPlatform.iOS) {
      final speechOutcome = await _ensurePermission(
        permission: Permission.speech,
        deniedMessage: 'Speech recognition permission denied.',
        deniedPermanentlyMessage:
            'Speech recognition permission is permanently denied.',
      );
      if (speechOutcome != SpeechStartOutcome.started) {
        return speechOutcome;
      }
    }

    final initialized = await _speech.initialize(
      onError: _onError,
      onStatus: (_) {},
      debugLogging: false,
    );

    if (!initialized) {
      _lastError = 'Speech recognition is unavailable on this device.';
      return SpeechStartOutcome.unavailable;
    }

    final localeId = await _resolveArabicLocale();
    if (localeId == null) {
      _lastError =
          'Arabic speech locale is not available on this device. Enable/Install Arabic language in system speech settings.';
      return SpeechStartOutcome.unavailable;
    }

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        onDevice: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (value) {
        onResult(
          SpeechRecognitionResult(
            transcript: value.recognizedWords,
            isFinal: value.finalResult,
            confidence: value.confidence,
          ),
        );
      },
    );

    return SpeechStartOutcome.started;
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
  }

  @override
  Future<void> cancel() async {
    await _speech.cancel();
  }

  @override
  Future<void> dispose() async {
    await _speech.cancel();
  }

  void _onError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
  }

  Future<String?> _resolveArabicLocale() async {
    final locales = await _speech.locales();

    final localeIds = locales.map((l) => l.localeId).toList(growable: false);
    final normalizedMap = <String, String>{
      for (final id in localeIds) _normalizeLocaleId(id): id,
    };

    const preferred = [
      'ar-DZ',
      'ar-MA',
      'ar-TN',
      'ar-SA',
      'ar-EG',
      'ar-AE',
      'ar',
    ];

    for (final candidate in preferred) {
      final hit = normalizedMap[_normalizeLocaleId(candidate)];
      if (hit != null) {
        return hit;
      }
    }

    for (final id in localeIds) {
      if (id.toLowerCase().startsWith('ar')) {
        return id;
      }
    }

    return null;
  }

  String _normalizeLocaleId(String id) => id.replaceAll('_', '-').toLowerCase();

  Future<SpeechStartOutcome> _ensurePermission({
    required Permission permission,
    required String deniedMessage,
    required String deniedPermanentlyMessage,
  }) async {
    final status = await permission.status;
    if (status.isGranted) {
      return SpeechStartOutcome.started;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      _lastError = deniedPermanentlyMessage;
      return SpeechStartOutcome.deniedPermanently;
    }

    final requested = await permission.request();
    if (requested.isGranted) {
      return SpeechStartOutcome.started;
    }
    if (requested.isPermanentlyDenied || requested.isRestricted) {
      _lastError = deniedPermanentlyMessage;
      return SpeechStartOutcome.deniedPermanently;
    }

    _lastError = deniedMessage;
    return SpeechStartOutcome.denied;
  }
}
