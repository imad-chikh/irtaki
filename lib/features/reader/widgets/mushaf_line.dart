import 'package:flutter/material.dart';

import '../../../../core/models/verse.dart';
import 'verse_segment.dart';

class MushafLine extends StatelessWidget {
  final int lineNumber;
  final List<Verse> verses;
  final bool showTajweed;
  final double fontSize;
  final void Function(Verse) onVerseTap;

  const MushafLine({
    super.key,
    required this.lineNumber,
    required this.verses,
    required this.showTajweed,
    required this.fontSize,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort verses by aya_no so RTL order is correct
    final sorted = [...verses]..sort((a, b) => a.ayaNo.compareTo(b.ayaNo));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: sorted.map((verse) {
            return Flexible(
              child: VerseSegment(
                verse: verse,
                lineNumber: lineNumber,
                showTajweed: showTajweed,
                fontSize: fontSize,
                onTap: () => onVerseTap(verse),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
