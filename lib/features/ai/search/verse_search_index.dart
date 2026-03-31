import '../../../core/database/quran_dao.dart';
import 'verse_matcher.dart';

class VerseSearchIndex {
  VerseSearchIndex._();

  static final VerseSearchIndex instance = VerseSearchIndex._();

  Future<VerseMatcher>? _matcherFuture;

  Future<void> warmUp() async {
    await getMatcher();
  }

  Future<VerseMatcher> getMatcher() {
    _matcherFuture ??= _build();
    return _matcherFuture!;
  }

  Future<VerseMatcher> _build() async {
    final verses = await QuranDao().getAllVerses();
    return VerseMatcher.fromVerses(verses);
  }
}
