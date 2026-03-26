import 'package:flutter/material.dart';
import '../../../../core/models/verse.dart';
import '../../../../core/constants/app_colors.dart';
import 'mushaf_line.dart';
import 'page_header.dart';
import 'page_footer.dart';
import 'surah_banner.dart';
import 'verse_bottom_sheet.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final List<Verse> verses;
  final bool showTajweed;
  final double fontSize;

  const MushafPage({
    super.key,
    required this.pageNumber,
    required this.verses,
    required this.showTajweed,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) return const SizedBox.shrink();

    final firstVerse = verses.first;
    final juzLabel = 'الجزء ${_toEasternArabic(firstVerse.juz)}';

    // ── Group verse fragments by physical line number ──────────────────────
    final Map<int, List<Verse>> lineMap = {};
    for (final verse in verses) {
      for (int line = verse.lineStart; line <= verse.lineEnd; line++) {
        lineMap.putIfAbsent(line, () => []).add(verse);
      }
    }
    final sortedLines = lineMap.keys.toList()..sort();

    // ── Detect surah changes on this page (for Basmala banners) ───────────
    final suraChanges = <int>{};
    if (verses.length > 1) {
      for (int i = 1; i < verses.length; i++) {
        if (verses[i].suraNo != verses[i - 1].suraNo) {
          suraChanges.add(verses[i].suraNo);
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.pageDark : AppColors.pageLight,
      child: Column(
        children: [
          // ── Page header ─────────────────────────────────────────────────
          PageHeader(surahName: firstVerse.suraNameAr, juzLabel: juzLabel),

          // ── Page content ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildLines(
                  context,
                  sortedLines,
                  lineMap,
                  suraChanges,
                  firstVerse,
                ),
              ),
            ),
          ),

          // ── Page footer ─────────────────────────────────────────────────
          PageFooter(pageNumber: pageNumber),
        ],
      ),
    );
  }

  List<Widget> _buildLines(
    BuildContext context,
    List<int> sortedLines,
    Map<int, List<Verse>> lineMap,
    Set<int> suraChanges,
    Verse firstVerse,
  ) {
    final widgets = <Widget>[];

    // If page is starting with Basmala
    if (firstVerse.ayaNo == 1 && sortedLines.isNotEmpty) {
      widgets.add(
        SurahBanner(
          surahName: firstVerse.suraNameAr,
          hasBasmala: firstVerse.suraNo != 9,
        ),
      );
    }

    for (final lineNum in sortedLines) {
      final lineVerses = lineMap[lineNum]!;

      // Insert surah banner BEFORE this line if a new surah starts here
      for (final v in lineVerses) {
        if (suraChanges.contains(v.suraNo) && v.lineStart == lineNum) {
          widgets.add(
            SurahBanner(surahName: v.suraNameAr, hasBasmala: v.suraNo != 9),
          );
        }
      }

      widgets.add(
        MushafLine(
          lineNumber: lineNum,
          verses: lineVerses,
          showTajweed: showTajweed,
          fontSize: fontSize,
          onVerseTap: (verse) => _showVerseSheet(context, verse),
        ),
      );
    }

    return widgets;
  }

  void _showVerseSheet(BuildContext context, Verse verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseBottomSheet(verse: verse),
    );
  }

  static String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}
