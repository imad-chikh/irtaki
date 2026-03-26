import 'package:flutter/material.dart';
import '../../../../core/models/verse.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/verse_number_badge.dart';

class VerseSegment extends StatelessWidget {
  final Verse verse;
  final int lineNumber;
  final bool showTajweed;
  final double fontSize;
  final VoidCallback onTap;

  const VerseSegment({
    super.key,
    required this.verse,
    required this.lineNumber,
    required this.showTajweed,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLastLine = lineNumber == verse.lineEnd;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.primaryTextDark
        : AppColors.primaryTextLight;

    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: verse.ayaText,
              style: TextStyle(
                fontFamily: 'me_quran',
                fontSize: fontSize,
                height: 2.2, // CRITICAL: room for diacritics
                color: textColor,
              ),
            ),
            // Show verse number badge inline at end of verse's last line
            if (isLastLine)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: VerseNumberBadge(number: verse.ayaNo),
                ),
              ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }
}
