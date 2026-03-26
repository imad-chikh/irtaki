import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PageFooter extends StatelessWidget {
  final int pageNumber;

  const PageFooter({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Center(
        child: Text(
          _toEasternArabic(pageNumber),
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 14,
            color: AppColors.gold,
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
