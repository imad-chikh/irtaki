import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'asr_engine.dart';
import 'asr_types.dart';

class WhisperLocalAsrEngine implements AsrEngine {
  static const _baseUrl = String.fromEnvironment(
    'WHISPER_API_BASE_URL',
    defaultValue: 'https://itsimad-irtaki-quran-whisper.hf.space',
  );
  static const _maxAudioSeconds = 8;

  final AudioRecorder _recorder;
  String? _lastError;
  bool _isListening = false;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  Timer? _maxDurationTimer;
  Timer? _silenceTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;
  ValueChanged<AsrTranscriptResult>? _resultListener;
  bool _speechDetected = false;
  bool _isFinalizing = false;

  WhisperLocalAsrEngine({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  @override
  AsrEngineType get engineType => AsrEngineType.whisperLocal;

  @override
  String? get lastError => _lastError;

  @override
  bool get isListening => _isListening;

  @override
  Future<AsrStartOutcome> startListening({
    required ValueChanged<AsrTranscriptResult> onResult,
  }) async {
    _lastError = null;
    _resultListener = onResult;
    _log('startListening invoked');

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _lastError =
          'Voice search with Whisper backend is available on mobile only.';
      _log('unsupported platform: $defaultTargetPlatform');
      return AsrStartOutcome.unavailable;
    }

    final hasPermission = await _ensureMicPermission();
    if (hasPermission != AsrStartOutcome.started) {
      _log('microphone permission outcome: $hasPermission');
      return hasPermission;
    }

    final available = await _isBackendAvailable();
    if (!available) {
      _log('backend unavailable: $_lastError');
      return AsrStartOutcome.unavailable;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(
      tempDir.path,
      'whisper_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    _recordingPath = filePath;
    _recordingStartedAt = DateTime.now();
    _isFinalizing = false;
    _speechDetected = false;
    _isListening = true;
    _log('recording started: $filePath');

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: filePath,
      );
    } catch (e) {
      _isListening = false;
      _lastError = 'Failed to start local audio recording: $e';
      _log('recorder start failed: $e');
      return AsrStartOutcome.error;
    }

    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen(_onAmplitude);

    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(
      const Duration(seconds: _maxAudioSeconds),
      _finalizeTranscription,
    );

    return AsrStartOutcome.started;
  }

  @override
  Future<void> stopListening() {
    _log('stopListening requested');
    return _finalizeTranscription();
  }

  @override
  Future<void> cancel() async {
    _log('cancel requested');
    _maxDurationTimer?.cancel();
    _silenceTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _isListening = false;
    _isFinalizing = false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    _log('dispose requested');
    await cancel();
    await _recorder.dispose();
  }

  void _onAmplitude(Amplitude amp) {
    if (!_isListening || _isFinalizing) {
      return;
    }

    final db = amp.current;
    final isSpeech = db > -38.0;
    if (isSpeech) {
      _speechDetected = true;
      _silenceTimer?.cancel();
      _silenceTimer = null;
      return;
    }

    if (_speechDetected && _silenceTimer == null) {
      _silenceTimer = Timer(
        const Duration(milliseconds: 1200),
        _finalizeTranscription,
      );
    }
  }

  Future<void> _finalizeTranscription() async {
    if (_isFinalizing || !_isListening) {
      _log(
        'finalize skipped isFinalizing=$_isFinalizing isListening=$_isListening',
      );
      return;
    }
    _log('finalizing transcription');
    _isFinalizing = true;
    _maxDurationTimer?.cancel();
    _silenceTimer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    final path = _recordingPath;
    _recordingPath = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}

    _isListening = false;
    _log('recording stopped, file path: $path');

    if (path == null || !File(path).existsSync()) {
      _lastError = 'No audio recording captured for Whisper transcription.';
      _log('no audio file found for transcription');
      _isFinalizing = false;
      return;
    }

    final transcribeResult = await _transcribeAudio(audioPath: path);

    final text = (transcribeResult['text'] as String?)?.trim() ?? '';
    final confidence = _toDouble(transcribeResult['confidence']);
    final durationMs =
        (transcribeResult['durationMs'] as num?)?.toInt() ??
        DateTime.now()
            .difference(_recordingStartedAt ?? DateTime.now())
            .inMilliseconds;

    if (text.isNotEmpty) {
      _log(
        'transcription success: textLength=${text.length}, durationMs=$durationMs, confidence=$confidence',
      );
      _resultListener?.call(
        AsrTranscriptResult(
          text: text,
          isFinal: true,
          confidence: confidence,
          engineType: AsrEngineType.whisperLocal,
          durationMs: durationMs,
          fallbackUsed: false,
        ),
      );
    } else {
      _log('transcription returned empty text');
    }
    _isFinalizing = false;
  }

  Future<AsrStartOutcome> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return AsrStartOutcome.started;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      _lastError = 'Microphone permission is permanently denied.';
      return AsrStartOutcome.deniedPermanently;
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted) {
      return AsrStartOutcome.started;
    }
    if (requested.isPermanentlyDenied || requested.isRestricted) {
      _lastError = 'Microphone permission is permanently denied.';
      return AsrStartOutcome.deniedPermanently;
    }

    _lastError = 'Microphone permission denied.';
    return AsrStartOutcome.denied;
  }

  Future<bool> _isBackendAvailable() async {
    final uri = _resolveBackendUri();
    _log('checking backend connectivity: ${uri.origin}');
    try {
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(milliseconds: 1500),
      );
      socket.destroy();
      _log('backend connectivity check succeeded: ${uri.origin}');
      return true;
    } catch (e) {
      _lastError =
          'Cannot reach Whisper backend at ${uri.origin}. '
          'Pass --dart-define=WHISPER_API_BASE_URL=<your-backend-url> to override the default endpoint. '
          'Details: $e';
      _log('backend connectivity check failed: $e');
      return false;
    }
  }

  Future<Map<String, Object?>> _transcribeAudio({
    required String audioPath,
  }) async {
    final uri = _resolveBackendUri();
    _log('transcribe request start: $uri, file=${p.basename(audioPath)}');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            audioPath,
            filename: p.basename(audioPath),
          ),
        );

      final streamed = await request.send().timeout(
        const Duration(seconds: _maxAudioSeconds + 6),
      );
      final body = await streamed.stream.bytesToString();
      _log(
        'transcribe response status=${streamed.statusCode}, bodyLength=${body.length}',
      );

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        _lastError =
            'Whisper backend returned ${streamed.statusCode}: ${body.trim()}';
        _log('transcribe non-2xx response');
        return const {};
      }

      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        _lastError = 'Whisper backend returned invalid JSON payload.';
        _log('transcribe invalid JSON structure');
        return const {};
      }

      return decoded.map<String, Object?>((key, value) => MapEntry(key, value));
    } on SocketException catch (e) {
      _lastError =
          'Whisper backend closed the connection while uploading audio. '
          'Check backend logs and ensure /transcribe returns JSON for every request. '
          'Details: $e';
      _log('transcribe socket failure: $e');
      return const {};
    } catch (e) {
      _lastError = 'Whisper transcription failed: $e';
      _log('transcribe request failed: $e');
      return const {};
    }
  }

  Uri _resolveBackendUri() {
    if (_baseUrl.trim().isNotEmpty) {
      final uri = Uri.parse(_baseUrl).resolve('/transcribe');
      _log('resolved backend URI from dart-define: $uri');
      return uri;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      const uri = 'http://10.0.2.2:8000/transcribe';
      _log('resolved backend URI from Android default: $uri');
      return Uri.parse(uri);
    }

    const uri = 'http://127.0.0.1:8000/transcribe';
    _log('resolved backend URI from localhost default: $uri');
    return Uri.parse(uri);
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WhisperLocalAsrEngine] $message');
    }
  }
}
