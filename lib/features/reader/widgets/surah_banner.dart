import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class SurahBanner extends StatelessWidget {
  final String surahName;
  final bool hasBasmala;

  const SurahBanner({
    super.key,
    required this.surahName,
    required this.hasBasmala,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            border: Border.all(color: AppColors.verseCircleBorder),
          ),
          child: Center(
            child: Text(
              surahName,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (hasBasmala)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                style: TextStyle(fontFamily: 'me_quran', fontSize: 22),
              ),
            ),
          ),
      ],
    );
  }
}
