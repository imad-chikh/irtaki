import 'package:flutter_test/flutter_test.dart';
import 'package:irtaki/core/models/verse.dart';
import 'package:irtaki/features/ai/search/verse_matcher.dart';

void main() {
  group('VerseMatcher', () {
    final verses = [
      const Verse(
        id: 1,
        juz: 1,
        page: 1,
        suraNo: 1,
        suraNameEn: 'Al-Fatihah',
        suraNameAr: 'الفاتحة',
        lineStart: 1,
        lineEnd: 1,
        ayaNo: 1,
        ayaText: 'الحمد لله رب العالمين',
      ),
      const Verse(
        id: 2,
        juz: 1,
        page: 1,
        suraNo: 1,
        suraNameEn: 'Al-Fatihah',
        suraNameAr: 'الفاتحة',
        lineStart: 1,
        lineEnd: 1,
        ayaNo: 2,
        ayaText: 'الرحمن الرحيم',
      ),
    ];

    test('returns best ranked verse for exact query', () {
      final matcher = VerseMatcher.fromVerses(verses);
      final matches = matcher.match('الحمد لله رب العالمين');

      expect(matches, isNotEmpty);
      expect(matches.first.verse.ayaNo, 1);
      expect(matches.first.score, greaterThan(0.8));
    });

    test('still matches partially noisy query', () {
      final matcher = VerseMatcher.fromVerses(verses);
      final matches = matcher.match('الحمد لله رب');

      expect(matches, isNotEmpty);
      expect(matches.first.verse.ayaNo, 1);
    });
  });
}
