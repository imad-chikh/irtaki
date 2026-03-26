import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/verse.dart';
import '../../../../core/constants/app_colors.dart';

class VerseBottomSheet extends StatelessWidget {
  final Verse verse;

  const VerseBottomSheet({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              verse.verseRef,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse.ayaText,
                style: const TextStyle(
                  fontFamily: 'me_quran',
                  fontSize: 24,
                  height: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.copy,
                  label: 'نسخ',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: verse.ayaText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الآية')),
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: 'مشاركة',
                  onTap: () {
                    // TODO: Implement share
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
