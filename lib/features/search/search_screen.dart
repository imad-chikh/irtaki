import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/database/quran_dao.dart';
import '../../core/models/verse.dart';
import '../ai/models/verse_match.dart';
import '../ai/search/verse_matcher.dart';
import '../ai/search/verse_search_index.dart';
import '../ai/services/native_arabic_stt_service.dart';
import '../ai/services/speech_recognition_service.dart';
import '../settings/settings_provider.dart';

enum _VoiceStatus { idle, listening, processing, error }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final NativeArabicSttService _sttService = NativeArabicSttService();
  List<Verse> _results = [];
  List<VerseMatch> _rankedMatches = [];
  bool _isLoading = false;
  _VoiceStatus _voiceStatus = _VoiceStatus.idle;
  String _transcript = '';
  String? _voiceError;
  bool _canOpenSettings = false;
  VerseMatcher? _matcher;
  Future<VerseMatcher>? _matcherFuture;
  bool _hasFinalizedCurrentListening = false;

  bool get _isVoiceSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _matcherFuture = VerseSearchIndex.instance.getMatcher();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _rankedMatches = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _voiceStatus = _VoiceStatus.idle;
      _voiceError = null;
      _canOpenSettings = false;
    });

    final results = await QuranDao().search(trimmed);
    List<VerseMatch> fallbackMatches = const [];
    if (results.isEmpty) {
      final matcher = await _getMatcher();
      fallbackMatches = matcher.match(trimmed, limit: 20);
    }

    final merged = <Verse>[...results, ...fallbackMatches.map((m) => m.verse)];
    final uniqueById = <int, Verse>{};
    for (final verse in merged) {
      uniqueById[verse.id] = verse;
    }

    setState(() {
      _results = uniqueById.values.toList(growable: false);
      _rankedMatches = [];
      _isLoading = false;
      if (_results.isEmpty) {
        _voiceError = 'لا توجد نتائج مطابقة.';
      }
    });
  }

  Future<void> _startVoiceSearch() async {
    _hasFinalizedCurrentListening = false;
    setState(() {
      _voiceStatus = _VoiceStatus.listening;
      _voiceError = null;
      _transcript = '';
    });

    final start = await _sttService.startListening(
      onResult: (result) async {
        if (!mounted) {
          return;
        }

        setState(() {
          _transcript = result.transcript;
        });

        if (result.isFinal && !_hasFinalizedCurrentListening) {
          _hasFinalizedCurrentListening = true;
          await _runAiMatch(result.transcript);
        }
      },
    );

    if (start != SpeechStartOutcome.started) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = _VoiceStatus.error;
        _voiceError = _resolveSpeechError(start, _sttService.lastError);
        _canOpenSettings = start == SpeechStartOutcome.deniedPermanently;
      });
    }
  }

  Future<void> _stopVoiceSearch() async {
    await _sttService.stopListening();
    if (_transcript.trim().isNotEmpty && !_hasFinalizedCurrentListening) {
      _hasFinalizedCurrentListening = true;
      await _runAiMatch(_transcript);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus = _VoiceStatus.idle;
    });
  }

  Future<void> _runAiMatch(String transcript) async {
    final query = transcript.trim();
    if (query.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = _VoiceStatus.error;
        _voiceError = 'لم يتم التقاط نص واضح.';
        _canOpenSettings = false;
      });
      return;
    }

    setState(() {
      _voiceStatus = _VoiceStatus.processing;
      _voiceError = null;
      _canOpenSettings = false;
      _queryController.text = query;
    });

    final matcher = await _getMatcher();
    final matches = matcher.match(query, limit: 5);

    if (!mounted) {
      return;
    }

    setState(() {
      _rankedMatches = matches;
      _results = [];
      _voiceStatus = _VoiceStatus.idle;
      if (matches.isEmpty) {
        _voiceError = 'لا توجد نتائج مطابقة كافية.';
      }
    });
  }

  Future<VerseMatcher> _getMatcher() async {
    if (_matcher != null) {
      return _matcher!;
    }
    _matcherFuture ??= VerseSearchIndex.instance.getMatcher();
    _matcher = await _matcherFuture!;
    return _matcher!;
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
            'ميزة البحث الصوتي غير متاحة. تأكد من تفعيل/تنزيل اللغة العربية للتعرّف الصوتي في إعدادات النظام.';
      case SpeechStartOutcome.error:
        return nativeError ?? 'حدث خطأ غير متوقع في التعرف الصوتي.';
      case SpeechStartOutcome.started:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث في القرآن...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_isVoiceSupported)
            IconButton(
              icon: Icon(
                _voiceStatus == _VoiceStatus.listening
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none_outlined,
              ),
              onPressed: _voiceStatus == _VoiceStatus.processing
                  ? null
                  : () {
                      if (_voiceStatus == _VoiceStatus.listening) {
                        _stopVoiceSearch();
                      } else {
                        _startVoiceSearch();
                      }
                    },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_queryController.text),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (_voiceStatus == _VoiceStatus.listening ||
                _voiceStatus == _VoiceStatus.processing)
              Container(
                width: double.infinity,
                color: Colors.blueGrey.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _voiceStatus == _VoiceStatus.listening
                      ? 'جاري الاستماع...'
                      : 'جاري مطابقة الآيات...',
                ),
              ),
            if (_transcript.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.teal.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text('النص الملتقط: $_transcript'),
              ),
            if (_voiceError != null && _voiceError!.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.red.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _voiceError!,
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
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResultsList(settings.fontSize, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(double fontSize, BuildContext context) {
    if (_rankedMatches.isNotEmpty) {
      return ListView.separated(
        itemCount: _rankedMatches.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final match = _rankedMatches[index];
          return ListTile(
            onTap: () => context.push('/reader/${match.verse.page}'),
            title: Text(
              match.matchedSnippet,
              style: TextStyle(
                fontFamily: 'UthmaniWarsh',
                fontSize: fontSize * 0.8,
                height: 2.0,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${match.verse.verseRef} - صفحة ${match.verse.page} - ${(match.score * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            trailing: _isVoiceSupported
                ? IconButton(
                    icon: const Icon(Icons.record_voice_over_outlined),
                    tooltip: 'اختبار التلاوة',
                    onPressed: () =>
                        context.push('/recitation-check', extra: match.verse),
                  )
                : null,
          );
        },
      );
    }

    if (_results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final verse = _results[index];
        return ListTile(
          onTap: () => context.push('/reader/${verse.page}'),
          title: Text(
            verse.ayaText,
            style: TextStyle(
              fontFamily: 'UthmaniWarsh',
              fontSize: fontSize * 0.8,
              height: 2.0,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${verse.verseRef} - صفحة ${verse.page}',
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          trailing: _isVoiceSupported
              ? IconButton(
                  icon: const Icon(Icons.record_voice_over_outlined),
                  tooltip: 'اختبار التلاوة',
                  onPressed: () =>
                      context.push('/recitation-check', extra: verse),
                )
              : null,
        );
      },
    );
  }
}
