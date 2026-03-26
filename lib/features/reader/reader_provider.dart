import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/quran_dao.dart';
import '../../core/models/verse.dart';

part 'reader_provider.g.dart';

@riverpod
Future<List<Verse>> versesForPage(VersesForPageRef ref, int page) {
  return QuranDao().getVersesByPage(page);
}

@riverpod
Future<int> totalPages(TotalPagesRef ref) {
  return QuranDao().getTotalPages();
}

@riverpod
class CurrentPageNotifier extends _$CurrentPageNotifier {
  @override
  int build(int initialPage) {
    return initialPage;
  }

  void setPage(int page) {
    state = page;
  }
}
