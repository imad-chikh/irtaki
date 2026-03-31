import '../models/recitation_feedback.dart';
import 'warsh_text_normalizer.dart';

class RecitationFeedbackAnalyzer {
  final WarshTextNormalizer _normalizer;

  RecitationFeedbackAnalyzer({WarshTextNormalizer? normalizer})
    : _normalizer = normalizer ?? WarshTextNormalizer();

  RecitationFeedbackResult analyze({
    required String expectedText,
    required String recitedText,
  }) {
    final expectedTokens = _normalizer.tokenize(expectedText);
    final heardTokens = _normalizer.tokenize(recitedText);

    if (expectedTokens.isEmpty) {
      return const RecitationFeedbackResult(tokens: [], score: 0);
    }

    final tokens = <RecitationTokenFeedback>[];
    var matched = 0;
    var heardIndex = 0;

    for (final expected in expectedTokens) {
      final foundAt = _findInWindow(heardTokens, expected, heardIndex);
      if (foundAt >= 0) {
        for (var i = heardIndex; i < foundAt; i++) {
          final uncertainHeard = heardTokens[i];
          tokens.add(
            RecitationTokenFeedback(
              expected: '',
              heard: uncertainHeard,
              status: RecitationTokenStatus.uncertain,
            ),
          );
        }

        tokens.add(
          RecitationTokenFeedback(
            expected: expected,
            heard: heardTokens[foundAt],
            status: RecitationTokenStatus.correct,
          ),
        );
        matched++;
        heardIndex = foundAt + 1;
        continue;
      }

      final substitute = heardIndex < heardTokens.length
          ? heardTokens[heardIndex]
          : '';
      final distance = substitute.isEmpty
          ? 99
          : _levenshtein(expected, substitute);

      final status = distance <= 1
          ? RecitationTokenStatus.uncertain
          : (substitute.isEmpty
                ? RecitationTokenStatus.missing
                : RecitationTokenStatus.mismatch);

      tokens.add(
        RecitationTokenFeedback(
          expected: expected,
          heard: substitute,
          status: status,
        ),
      );

      if (substitute.isNotEmpty) {
        heardIndex++;
      }
    }

    for (var i = heardIndex; i < heardTokens.length; i++) {
      tokens.add(
        RecitationTokenFeedback(
          expected: '',
          heard: heardTokens[i],
          status: RecitationTokenStatus.uncertain,
        ),
      );
    }

    final score = matched / expectedTokens.length;
    return RecitationFeedbackResult(tokens: tokens, score: score);
  }

  int _findInWindow(List<String> heardTokens, String expected, int start) {
    final end = (start + 3).clamp(0, heardTokens.length);
    for (var i = start; i < end; i++) {
      if (heardTokens[i] == expected) {
        return i;
      }
    }
    return -1;
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

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }

    return prev[b.length];
  }
}
