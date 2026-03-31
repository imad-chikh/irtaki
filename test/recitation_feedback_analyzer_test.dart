import 'package:flutter_test/flutter_test.dart';
import 'package:irtaki/features/ai/models/recitation_feedback.dart';
import 'package:irtaki/features/ai/search/recitation_feedback_analyzer.dart';

void main() {
  group('RecitationFeedbackAnalyzer', () {
    final analyzer = RecitationFeedbackAnalyzer();

    test('marks fully correct recitation with high score', () {
      final result = analyzer.analyze(
        expectedText: 'الحمد لله رب العالمين',
        recitedText: 'الحمد لله رب العالمين',
      );

      expect(result.score, 1);
      expect(
        result.tokens.every((t) => t.status == RecitationTokenStatus.correct),
        isTrue,
      );
    });

    test('marks missing tokens conservatively', () {
      final result = analyzer.analyze(
        expectedText: 'الحمد لله رب العالمين',
        recitedText: 'الحمد لله',
      );

      expect(result.score, lessThan(1));
      expect(
        result.tokens.any((t) => t.status == RecitationTokenStatus.missing),
        isTrue,
      );
    });
  });
}
