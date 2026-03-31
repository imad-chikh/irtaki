import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/quran_dao.dart';
import 'fihras_provider.dart';
import 'widgets/surah_tile.dart';

class FihrasScreen extends ConsumerStatefulWidget {
  const FihrasScreen({super.key});

  @override
  ConsumerState<FihrasScreen> createState() => _FihrasScreenState();
}

class _FihrasScreenState extends ConsumerState<FihrasScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(filteredSurahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن سورة...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).setQuery(val);
                },
              )
            : const Text(
                'فهرس السور',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).setQuery('');
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: surahsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (surahs) {
            if (surahs.isEmpty) {
              return const Center(child: Text('لا توجد نتائج'));
            }
            return ListView.separated(
              itemCount: surahs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return SurahTile(
                  surah: surah,
                  onTap: () async {
                    final page = await QuranDao().getPageForSura(surah.suraNo);
                    if (!context.mounted) {
                      return;
                    }
                    context.push('/reader/$page');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
