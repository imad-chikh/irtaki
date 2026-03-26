import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/surah.dart';

class OrnamentalNumber extends StatelessWidget {
  final int number;
  const OrnamentalNumber({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _SurahBadgePainter(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            _toEasternArabic(number),
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  static String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}

class _SurahBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = AppColors.verseCircleFill.withOpacity(0.5),
    );

    final borderPaint = Paint()
      ..color = AppColors.verseCircleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    const sides = 8;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / sides);
      final x = cx + r * 0.92 * math.cos(angle);
      final y = cy + r * 0.92 * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, borderPaint);

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.verseCircleBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahTile({super.key, required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppColors.primaryTextDark
        : AppColors.primaryTextLight;
    final secondaryTextColor = isDark
        ? AppColors.secondaryTextDark
        : AppColors.secondaryTextLight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              OrnamentalNumber(number: surah.suraNo),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.suraNameAr,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surah.suraNameEn,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_toEasternArabic(surah.versesCount)} آية',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}
