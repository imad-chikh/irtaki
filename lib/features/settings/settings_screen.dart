import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildSectionHeader('المصحف'),
            ListTile(
              title: const Text('حجم الخط'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: settings.fontSize,
                          min: 18,
                          max: 32,
                          divisions: 14,
                          onChanged: notifier.setFontSize,
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: 'UthmaniWarsh',
                        fontSize: settings.fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('طريقة القراءة'),
              trailing: SegmentedButton<ReadingMode>(
                segments: const [
                  ButtonSegment(
                    value: ReadingMode.page,
                    label: Text('صفحة بصفحة'),
                  ),
                  ButtonSegment(
                    value: ReadingMode.scroll,
                    label: Text('تمرير مستمر'),
                  ),
                ],
                selected: {settings.readingMode},
                onSelectionChanged: (set) => notifier.setReadingMode(set.first),
              ),
            ),
            const Divider(),
            _buildSectionHeader('أحكام التجويد'),
            SwitchListTile(
              title: const Text('إظهار ألوان التجويد'),
              subtitle: const Text('أحكام ورش تختلف عن حفص'),
              value: settings.showTajweed,
              onChanged: notifier.setTajweed,
            ),
            if (settings.showTajweed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 12,
                  children: [
                    _buildColorLegend(const Color(0xFF00A550), 'غنة والإدغام'),
                    _buildColorLegend(const Color(0xFF4CAF50), 'إخفاء'),
                    _buildColorLegend(const Color(0xFF2196F3), 'المدود'),
                    _buildColorLegend(const Color(0xFF9C27B0), 'قلقلة'),
                    _buildColorLegend(const Color(0xFFFF9800), 'تسهيل'),
                    _buildColorLegend(const Color(0xFFE91E63), 'نقل'),
                  ],
                ),
              ),
            ],
            const Divider(),
            _buildSectionHeader('المظهر'),
            ListTile(
              title: const Text('المظهر'),
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                  ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (set) => notifier.setTheme(set.first),
              ),
            ),
            const Divider(),
            _buildSectionHeader('عن التطبيق'),
            const ListTile(title: Text('رواية'), trailing: Text('ورش عن نافع')),
            const ListTile(
              title: Text('مصدر النص'),
              trailing: Text('tanzil.net'),
            ),
            const ListTile(title: Text('الإصدار'), trailing: Text('1.0.0')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildColorLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
