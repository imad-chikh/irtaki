import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String surahName;
  final String juzLabel;

  const PageHeader({
    super.key,
    required this.surahName,
    required this.juzLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            juzLabel,
            style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 14),
          ),
          Text(
            surahName,
            style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 14),
          ),
        ],
      ),
    );
  }
}
