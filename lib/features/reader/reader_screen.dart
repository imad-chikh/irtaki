import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/quran_dao.dart';
import '../settings/settings_provider.dart';
import 'reader_provider.dart';
import 'widgets/mushaf_page.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int initialPage;
  final int? initialSurah;
  final int? initialVerseId;

  const ReaderScreen({
    super.key,
    required this.initialPage,
    this.initialSurah,
    this.initialVerseId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  late final Future<int> _initialTargetPageFuture;
  final Map<int, int> _selectedVerseByPage = <int, int>{};
  bool _didInitialJump = false;
  Timer? _initialHighlightTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _initialTargetPageFuture = _resolveInitialPage();
  }

  @override
  void dispose() {
    _initialHighlightTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

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
      body: ref
          .watch(totalPagesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (totalPages) => FutureBuilder<int>(
              future: _initialTargetPageFuture,
              builder: (context, initialPageSnapshot) {
                final targetInitialPage = initialPageSnapshot.data?.clamp(
                  1,
                  totalPages,
                );
                if (targetInitialPage != null) {
                  _scheduleInitialJump(targetInitialPage);
                }

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageView.builder(
                    itemCount: totalPages,
                    controller: _pageController,
                    onPageChanged: (index) {
                      final page = index + 1;
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setLastPage(page);
                    },
                    itemBuilder: (context, index) {
                      final page = index + 1;
                      final versesAsync = ref.watch(
                        versesForPageProvider(page),
                      );

                      return versesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (verses) => MushafPage(
                          pageNumber: page,
                          verses: verses,
                          showTajweed: settings.showTajweed,
                          fontSize: settings.fontSize,
                          selectedVerseId: _selectedVerseByPage[page],
                          onVerseSelected: (verseId) {
                            setState(() {
                              if (verseId < 0) {
                                _selectedVerseByPage.remove(page);
                              } else {
                                _selectedVerseByPage[page] = verseId;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
    );
  }

  Future<int> _resolveInitialPage() async {
    final fromRoute = widget.initialPage;
    final surah = widget.initialSurah;
    if (surah == null) {
      return fromRoute;
    }

    try {
      return await QuranDao().getPageForSura(surah);
    } catch (_) {
      return fromRoute;
    }
  }

  void _scheduleInitialJump(int targetPage) {
    if (_didInitialJump) {
      return;
    }
    _didInitialJump = true;

    final targetIndex = targetPage - 1;
    if (targetIndex == _pageController.initialPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _applyInitialVerseHighlight(targetPage);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _pageController.jumpToPage(targetIndex);
      ref.read(settingsNotifierProvider.notifier).setLastPage(targetPage);
      _applyInitialVerseHighlight(targetPage);
    });
  }

  void _applyInitialVerseHighlight(int page) {
    final verseId = widget.initialVerseId;
    if (verseId == null) {
      return;
    }

    setState(() {
      _selectedVerseByPage[page] = verseId;
    });

    _initialHighlightTimer?.cancel();
    _initialHighlightTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      if (_selectedVerseByPage[page] != verseId) {
        return;
      }
      setState(() {
        _selectedVerseByPage.remove(page);
      });
    });
  }
}
