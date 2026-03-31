import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/verse.dart';
import '../../../shared/verse_number_badge.dart';
import 'page_footer.dart';
import 'page_header.dart';
import 'surah_banner.dart';
import 'verse_bottom_sheet.dart';

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final List<Verse> verses;
  final bool showTajweed;
  final double fontSize;
  final int? selectedVerseId;
  final ValueChanged<int> onVerseSelected;

  const MushafPage({
    super.key,
    required this.pageNumber,
    required this.verses,
    required this.showTajweed,
    required this.fontSize,
    required this.selectedVerseId,
    required this.onVerseSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) return const SizedBox.expand();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstVerse = verses.first;
    final juzLabel = 'الجزء ${_ar(firstVerse.juz)}';

    // ── De-duplicate: DB query returns verses sorted by line_start,aya_no.
    // Each verse appears once. This list is the ground truth for the page.
    final pageVerses = _deduplicate(verses);

    // ── Detect surah headers needed on this page ─────────────────────────────
    //    A surah banner is needed whenever aya_no == 1 appears.
    final Set<int> surahBannerAyaIds = {};
    for (final v in pageVerses) {
      if (v.ayaNo == 1) surahBannerAyaIds.add(v.id);
    }

    return Container(
      color: isDark ? AppColors.pageDark : AppColors.pageLight,
      child: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────────
          PageHeader(surahName: firstVerse.suraNameAr, juzLabel: juzLabel),

          // ── Page body ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: _buildBody(context, pageVerses, surahBannerAyaIds),
            ),
          ),

          // ── Bottom bar ─────────────────────────────────────────────────────
          PageFooter(pageNumber: pageNumber),
        ],
      ),
    );
  }

  // ── Lay out banners + a single flowing Text.rich per "surah section" ────────
  Widget _buildBody(
    BuildContext context,
    List<Verse> pageVerses,
    Set<int> surahBannerAyaIds,
  ) {
    // Split page into sections separated by surah start banners
    final sections = <_PageSection>[];
    var currentSpans = <Verse>[];
    String? currentHeader;
    bool? currentHasBasmala;

    for (final verse in pageVerses) {
      if (surahBannerAyaIds.contains(verse.id)) {
        // Save previous section
        if (currentSpans.isNotEmpty || currentHeader != null) {
          sections.add(
            _PageSection(
              headerName: currentHeader,
              hasBasmala: currentHasBasmala ?? false,
              verses: List.from(currentSpans),
            ),
          );
        }
        currentSpans = [];
        currentHeader = verse.suraNameAr;
        currentHasBasmala = verse.suraNo != 9;
      }
      currentSpans.add(verse);
    }
    // Final section
    sections.add(
      _PageSection(
        headerName: currentHeader,
        hasBasmala: currentHasBasmala ?? false,
        verses: currentSpans,
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in sections) ...[
            if (section.headerName != null)
              SurahBanner(
                surahName: section.headerName!,
                hasBasmala: section.hasBasmala,
              ),
            if (section.verses.isNotEmpty)
              _buildFlowingText(context, section.verses),
          ],
        ],
      ),
    );
  }

  /// A single RTL-justified Text.rich containing all verse text in order.
  /// This mirrors a real Mushaf: words flow continuously, verse numbers inline.
  Widget _buildFlowingText(BuildContext context, List<Verse> sectionVerses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.primaryTextDark
        : AppColors.primaryTextLight;
    final selectedBg = isDark
        ? const Color(0x334D90FE)
        : const Color(0x33E8C84A);

    final spans = <InlineSpan>[];

    for (final verse in sectionVerses) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _onVerseTap(context, verse);
      final isSelected = selectedVerseId == verse.id;

      spans.add(
        TextSpan(
          // Strip Arabic Presentation Form waqf/pause markers (U+FC00–U+FDFF)
          // These only render correctly in a Warsh-variant Quran font.
          text: _cleanText(verse.ayaText),
          style: TextStyle(
            fontFamily: 'UthmaniWarsh',
            fontSize: fontSize,
            height: 1.85,
            color: textColor,
            backgroundColor: isSelected ? selectedBg : null,
          ),
          recognizer: recognizer,
        ),
      );

      // Inline verse-number badge after each verse
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: VerseNumberBadge(number: verse.ayaNo),
          ),
        ),
      );

      spans.add(const TextSpan(text: ' '));
    }

    return Center(
      child: Text.rich(
        TextSpan(children: spans),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }

  Future<void> _onVerseTap(BuildContext context, Verse verse) async {
    onVerseSelected(verse.id);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseBottomSheet(verse: verse),
    );
    onVerseSelected(-1);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Remove Arabic Presentation Form characters (U+FB50–U+FDFF) that are
  /// Waqf/pause marks in Tanzil Warsh encoding. They render correctly only
  /// in a Warsh-variant Quran font; strip until full glyph coverage is available.
  static String _cleanText(String raw) {
    return raw.replaceAll(RegExp('[\uFB50-\uFDFF\uFE70-\uFEFF]'), '').trim();
  }

  static List<Verse> _deduplicate(List<Verse> verses) {
    final seen = <int>{};
    return verses.where((v) => seen.add(v.id)).toList();
  }

  static String _ar(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _PageSection {
  final String? headerName;
  final bool hasBasmala;
  final List<Verse> verses;
  const _PageSection({
    required this.headerName,
    required this.hasBasmala,
    required this.verses,
  });
}
