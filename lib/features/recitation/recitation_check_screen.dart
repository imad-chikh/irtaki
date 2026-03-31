import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/models/verse.dart';
import '../ai/models/recitation_feedback.dart';
import '../ai/search/recitation_feedback_analyzer.dart';
import '../ai/services/native_arabic_stt_service.dart';
import '../ai/services/speech_recognition_service.dart';

enum _RecitationState { idle, listening, processing, error }

class RecitationCheckScreen extends StatefulWidget {
  final Verse verse;

  const RecitationCheckScreen({super.key, required this.verse});

  @override
  State<RecitationCheckScreen> createState() => _RecitationCheckScreenState();
}

class _RecitationCheckScreenState extends State<RecitationCheckScreen> {
  final NativeArabicSttService _sttService = NativeArabicSttService();
  final RecitationFeedbackAnalyzer _analyzer = RecitationFeedbackAnalyzer();

  _RecitationState _state = _RecitationState.idle;
  String _transcript = '';
  String? _error;
  bool _canOpenSettings = false;
  RecitationFeedbackResult? _feedback;

  @override
  void dispose() {
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = _feedback == null
        ? '—'
        : '${(_feedback!.score * 100).toStringAsFixed(0)}%';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اختبار التلاوة',
          style: TextStyle(fontFamily: 'NotoNaskhArabic'),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'الآية المستهدفة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.verse.ayaText,
              style: const TextStyle(
                fontFamily: 'UthmaniWarsh',
                fontSize: 28,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.verse.verseRef,
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 28),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _state == _RecitationState.listening
                      ? _stopRecitation
                      : _startRecitation,
                  icon: Icon(
                    _state == _RecitationState.listening
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_outlined,
                  ),
                  label: Text(
                    _state == _RecitationState.listening
                        ? 'إيقاف التسجيل'
                        : 'ابدأ التلاوة',
                  ),
                ),
                const SizedBox(width: 12),
                Text('النتيجة: $scoreText'),
              ],
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  if (_canOpenSettings)
                    TextButton(
                      onPressed: openAppSettings,
                      child: const Text('فتح الإعدادات'),
                    ),
                ],
              ),
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'النص الملتقط',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_transcript),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              const Text(
                'تفصيل المطابقة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: _feedback!.tokens.map(_buildTokenChip).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChip(RecitationTokenFeedback token) {
    Color color;
    switch (token.status) {
      case RecitationTokenStatus.correct:
        color = Colors.green.shade100;
        break;
      case RecitationTokenStatus.missing:
        color = Colors.red.shade100;
        break;
      case RecitationTokenStatus.mismatch:
        color = Colors.red.shade200;
        break;
      case RecitationTokenStatus.uncertain:
        color = Colors.orange.shade100;
        break;
    }

    final text = token.expected.isEmpty
        ? '(${token.heard})'
        : token.heard.isEmpty
        ? '${token.expected} (ناقص)'
        : '${token.expected} ← ${token.heard}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }

  Future<void> _startRecitation() async {
    setState(() {
      _state = _RecitationState.listening;
      _error = null;
      _canOpenSettings = false;
      _feedback = null;
      _transcript = '';
    });

    final start = await _sttService.startListening(
      onResult: (result) {
        if (!mounted) {
          return;
        }
        setState(() {
          _transcript = result.transcript;
        });

        if (result.isFinal) {
          _analyzeRecitation(result.transcript);
        }
      },
    );

    if (start != SpeechStartOutcome.started) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _RecitationState.error;
        _error = _resolveSpeechError(start, _sttService.lastError);
        _canOpenSettings = start == SpeechStartOutcome.deniedPermanently;
      });
    }
  }

  Future<void> _stopRecitation() async {
    await _sttService.stopListening();
    if (_transcript.trim().isNotEmpty) {
      _analyzeRecitation(_transcript);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _RecitationState.idle;
    });
  }

  void _analyzeRecitation(String transcript) {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _RecitationState.processing;
    });

    final feedback = _analyzer.analyze(
      expectedText: widget.verse.ayaText,
      recitedText: transcript,
    );

    setState(() {
      _feedback = feedback;
      _state = _RecitationState.idle;
    });
  }

  String _resolveSpeechError(SpeechStartOutcome outcome, String? nativeError) {
    switch (outcome) {
      case SpeechStartOutcome.denied:
        return nativeError ?? 'تم رفض إذن الميكروفون.';
      case SpeechStartOutcome.deniedPermanently:
        return nativeError ??
            'تم رفض إذن الميكروفون بشكل دائم. فعّل الإذن من إعدادات النظام.';
      case SpeechStartOutcome.unavailable:
        return nativeError ??
            'ميزة التعرّف الصوتي غير متاحة. تأكد من تفعيل/تنزيل اللغة العربية للتعرّف الصوتي في إعدادات النظام.';
      case SpeechStartOutcome.error:
        return nativeError ?? 'حدث خطأ غير متوقع في التعرف الصوتي.';
      case SpeechStartOutcome.started:
        return '';
    }
  }
}
