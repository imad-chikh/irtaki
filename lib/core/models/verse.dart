class Verse {
  final int id;
  final int juz;
  final int page;
  final int suraNo;
  final String suraNameEn;
  final String suraNameAr;
  final int
  lineStart; // ← KEY: first physical line this verse occupies on the page
  final int
  lineEnd; // ← KEY: last physical line this verse occupies on the page
  final int ayaNo;
  final String ayaText;

  const Verse({
    required this.id,
    required this.juz,
    required this.page,
    required this.suraNo,
    required this.suraNameEn,
    required this.suraNameAr,
    required this.lineStart,
    required this.lineEnd,
    required this.ayaNo,
    required this.ayaText,
  });

  factory Verse.fromMap(Map<String, dynamic> m) => Verse(
    id: _parseIntField(m, 'id'),
    juz: _parseIntField(m, 'juz'),
    page: _parseIntField(m, 'page'),
    suraNo: _parseIntField(m, 'sura_no'),
    suraNameEn: m['sura_name_en'].toString(),
    suraNameAr: m['sura_name_ar'].toString(),
    lineStart: _parseIntField(m, 'line_start'),
    lineEnd: _parseIntField(m, 'line_end'),
    ayaNo: _parseIntField(m, 'aya_no'),
    ayaText: m['aya_text'].toString(),
  );

  // Number of lines this verse spans
  int get lineSpan => lineEnd - lineStart + 1;

  String get verseRef => '$suraNameAr • الآية ${_toEasternArabic(ayaNo)}';

  static String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  static int _parseIntField(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    final raw = value?.toString() ?? '';
    final direct = int.tryParse(raw);
    if (direct != null) {
      return direct;
    }

    // Handle legacy/page-range values like "85-86" by taking the first number.
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match != null) {
      return int.parse(match.group(0)!);
    }

    throw FormatException('Invalid integer value for "$key": $raw');
  }
}
