import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/quran_dao.dart';
import '../../core/models/surah.dart';

part 'fihras_provider.g.dart';

@riverpod
Future<List<Surah>> allSurahs(Ref ref) {
  return QuranDao().getAllSurahs();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() {
    return '';
  }

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Future<List<Surah>> filteredSurahs(Ref ref) async {
  final all = await ref.watch(allSurahsProvider.future);
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return all;

  final lowerQuery = query.toLowerCase();
  return all.where((s) {
    return s.suraNameAr.contains(query) ||
        s.suraNameEn.toLowerCase().contains(lowerQuery);
  }).toList();
}
