import 'package:flutter_test/flutter_test.dart';
import 'package:irtaki/features/ai/search/warsh_text_normalizer.dart';

void main() {
  group('WarshTextNormalizer', () {
    final normalizer = WarshTextNormalizer();

    test('removes diacritics and warsh glyph marks', () {
      const input = 'اِ۬لْحَمْدُ لِلهِ رَبِّ اِ۬لْعَٰلَمِينَ ﰀ';
      expect(normalizer.normalize(input), 'الحمد لله رب العالمين');
    });

    test('normalizes alef and ya variants', () {
      const input = 'إِنَّ هَٰذَا عَلَى ٱلْهُدَىٰ';
      expect(normalizer.normalize(input), 'ان هذا علي الهدي');
    });
  });
}
