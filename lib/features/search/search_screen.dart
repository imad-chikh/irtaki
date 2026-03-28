import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/quran_dao.dart';
import '../../core/models/verse.dart';
import '../settings/settings_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<Verse> _results = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await QuranDao().search(query);

    setState(() {
      _results = results;
      _isLoading = false;
    });
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_queryController.text),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
            ? const Center(child: Text('لا توجد نتائج'))
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final verse = _results[index];
                  return ListTile(
                    onTap: () {
                      context.push('/reader/${verse.page}');
                    },
                    title: Text(
                      verse.ayaText,
                      style: TextStyle(
                        fontFamily: 'UthmaniWarsh',
                        fontSize: settings.fontSize * 0.8,
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
                  );
                },
              ),
      ),
    );
  }
}
