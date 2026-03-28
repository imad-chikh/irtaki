import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/verse.dart';
import '../../../shared/verse_number_badge.dart';

/// Renders one physical Mushaf line as a single RTL-justified RichText.
/// Verses that END on this line get an inline verse-number badge.
class MushafLine extends StatelessWidget {
  final int lineNumber;
  final List<Verse> verses;
  final double fontSize;
  final void Function(Verse) onVerseTap;

  const MushafLine({
    super.key,
    required this.lineNumber,
    required this.verses,
    required this.fontSize,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.primaryTextDark
        : AppColors.primaryTextLight;

    // RTL Mushaf order: verses appear right → left by ayaNo ascending
    final sorted = [...verses]..sort((a, b) => a.ayaNo.compareTo(b.ayaNo));

    final spans = <InlineSpan>[];
    for (final verse in sorted) {
      // Tap recognizer for this verse fragment
      final recognizer = TapGestureRecognizer()
        ..onTap = () => onVerseTap(verse);

      spans.add(
        TextSpan(
          text: verse.ayaText,
          style: TextStyle(
            fontFamily: 'UthmaniWarsh',
            fontSize: fontSize,
            height: 1.9, // ← enough room for Warsh diacritics
            color: textColor,
          ),
          recognizer: recognizer,
        ),
      );

      // Inline verse-number badge at the end of the verse's last line
      if (verse.lineEnd == lineNumber) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: VerseNumberBadge(number: verse.ayaNo),
            ),
          ),
        );
      } else {
        // If the verse continues to the next line, just add a space separator
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
