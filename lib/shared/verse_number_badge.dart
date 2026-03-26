import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class VerseNumberBadge extends StatelessWidget {
  final int number;
  const VerseNumberBadge({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 26),
      painter: _BadgePainter(),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Text(
            _toEasternArabic(number),
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 9,
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

class _BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Cream fill
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = AppColors.verseCircleFill,
    );

    // Gold border — draw as an octagon for the authentic Mushaf look
    final borderPaint = Paint()
      ..color = AppColors.verseCircleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    const sides = 8;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * 3.14159265 / sides) - (3.14159265 / sides);
      final x = cx + r * 0.92 * cos(angle);
      final y = cy + r * 0.92 * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, borderPaint);

    // Outer thin circle
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
