import '../../../core/models/verse.dart';
import '../models/verse_match.dart';
import 'warsh_text_normalizer.dart';

class VerseMatcher {
  final WarshTextNormalizer _normalizer;
  final List<_IndexedVerse> _index;

  VerseMatcher._(this._normalizer, this._index);

  factory VerseMatcher.fromVerses(List<Verse> verses) {
    final normalizer = WarshTextNormalizer();
    final index = verses
        .map((v) {
          final normalized = normalizer.normalize(v.ayaText);
          final tokens = normalizer.tokenize(normalized).toSet();
          return _IndexedVerse(
            verse: v,
            normalizedText: normalized,
            tokens: tokens,
          );
        })
        .where((x) => x.normalizedText.isNotEmpty)
        .toList(growable: false);

    return VerseMatcher._(normalizer, index);
  }

  List<VerseMatch> match(String query, {int limit = 5}) {
    final normalizedQuery = _normalizer.normalize(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final queryTokens = _normalizer.tokenize(normalizedQuery).toSet();
    final scored = <VerseMatch>[];

    for (final entry in _index) {
      final score = _score(normalizedQuery, queryTokens, entry);
      if (score < 0.30) {
        continue;
      }
      scored.add(
        VerseMatch(
          verse: entry.verse,
          score: score,
          matchedSnippet: _buildSnippet(entry.verse.ayaText),
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.length > limit) {
      return scored.sublist(0, limit);
    }
    return scored;
  }

  double _score(
    String normalizedQuery,
    Set<String> queryTokens,
    _IndexedVerse entry,
  ) {
    final tokenOverlap = queryTokens.isEmpty
        ? 0.0
        : queryTokens.intersection(entry.tokens).length / queryTokens.length;

    final maxLen = normalizedQuery.length > entry.normalizedText.length
        ? normalizedQuery.length
        : entry.normalizedText.length;

    final distance = _levenshtein(normalizedQuery, entry.normalizedText);
    final distanceScore = maxLen == 0 ? 0.0 : (1.0 - (distance / maxLen));

    return (0.65 * tokenOverlap) + (0.35 * distanceScore);
  }

  String _buildSnippet(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 80) {
      return clean;
    }
    return '${clean.substring(0, 80)}…';
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        var best = deletion;
        if (insertion < best) {
          best = insertion;
        }
        if (substitution < best) {
          best = substitution;
        }
        current[j] = best;
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }
}

class _IndexedVerse {
  final Verse verse;
  final String normalizedText;
  final Set<String> tokens;

  const _IndexedVerse({
    required this.verse,
    required this.normalizedText,
    required this.tokens,
  });
}
