import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../settings/settings_provider.dart';
import 'reader_provider.dart';
import 'widgets/mushaf_page.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const ReaderScreen({super.key, required this.initialPage});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPagesAsync = ref.watch(totalPagesProvider);
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
      body: totalPagesAsync.when(
        data: (totalPages) {
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
                final page = index + 1;
                final versesAsync = ref.watch(versesForPageProvider(page));

                return versesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (verses) {
                    return MushafPage(
                      pageNumber: page,
                      verses: verses,
                      showTajweed: settings.showTajweed,
                      fontSize: settings.fontSize,
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
