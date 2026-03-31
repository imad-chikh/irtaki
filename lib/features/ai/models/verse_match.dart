import '../../../core/models/verse.dart';

class VerseMatch {
  final Verse verse;
  final double score;
  final String matchedSnippet;

  const VerseMatch({
    required this.verse,
    required this.score,
    required this.matchedSnippet,
  });
}
