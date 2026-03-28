import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/quran_dao.dart';
import '../settings/settings_provider.dart';
import 'models/mushaf_line_model.dart';
import 'parsing/quran_json_parser.dart';
import 'widgets/mushaf_page_widget.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int initialPage;
  final int? initialSurah;

  const ReaderScreen({super.key, required this.initialPage, this.initialSurah});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const int _linesPerPage = 15;

  late PageController _pageController;
  late final Future<_ReaderPayload> _payloadFuture;
  bool _didInitialJump = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _payloadFuture = _loadPayload();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    // Arabic direction is RTL, so PageView should naturally swipe right-to-left.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/fihras'),
        ),
        title: const Text(
          'مصحف ورش',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: bookmark feature
            },
          ),
        ],
      ),
      body: FutureBuilder<_ReaderPayload>(
        future: _payloadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payload = snapshot.data;
          final lines = payload?.lines ?? const <MushafLine>[];
          final surahNames = payload?.surahNames ?? const <int, String>{};
          if (lines.isEmpty) {
            return const Center(child: Text('لا توجد بيانات للعرض'));
          }

          final totalPages = (lines.length / _linesPerPage).ceil();

          final targetInitialPage = _resolveInitialPage(lines, totalPages);
          _scheduleInitialJump(targetInitialPage);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              itemCount: totalPages,
              controller: _pageController,
              onPageChanged: (index) {
                final page = index + 1;
                ref.read(settingsNotifierProvider.notifier).setLastPage(page);
              },
              itemBuilder: (context, index) {
                final start = index * _linesPerPage;
                final end = ((index + 1) * _linesPerPage).clamp(
                  0,
                  lines.length,
                );
                final pageLines = lines.sublist(start, end);

                return MushafPageWidget(
                  lines: pageLines,
                  surahNames: surahNames,
                  fontSize: settings.fontSize,
                  lineHeight: 1.9,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<_ReaderPayload> _loadPayload() async {
    final raw = await rootBundle.loadString('assets/json/warsh_complet.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const _ReaderPayload(
        lines: <MushafLine>[],
        surahNames: <int, String>{},
      );
    }

    final lines = parseQuranJson(decoded);
    final surahs = await QuranDao().getAllSurahs();
    final surahNames = <int, String>{
      for (final s in surahs) s.suraNo: s.suraNameAr,
    };

    return _ReaderPayload(lines: lines, surahNames: surahNames);
  }

  int _resolveInitialPage(List<MushafLine> lines, int totalPages) {
    final fromRoute = widget.initialPage.clamp(1, totalPages);
    final surah = widget.initialSurah;
    if (surah == null) {
      return fromRoute;
    }

    final index = lines.indexWhere(
      (l) => l.surah == surah && l.ayah == 1 && l.isFirstPartOfAyah,
    );

    if (index < 0) {
      return fromRoute;
    }

    return ((index ~/ _linesPerPage) + 1).clamp(1, totalPages);
  }

  void _scheduleInitialJump(int targetPage) {
    if (_didInitialJump) {
      return;
    }

    final targetIndex = targetPage - 1;
    if (targetIndex == _pageController.initialPage) {
      _didInitialJump = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _pageController.jumpToPage(targetIndex);
      ref.read(settingsNotifierProvider.notifier).setLastPage(targetPage);
    });
    _didInitialJump = true;
  }
}

class _ReaderPayload {
  final List<MushafLine> lines;
  final Map<int, String> surahNames;

  const _ReaderPayload({required this.lines, required this.surahNames});
}
