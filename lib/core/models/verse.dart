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
    id: int.parse(m['id'].toString()),
    juz: int.parse(m['juz'].toString()),
    page: int.parse(m['page'].toString()),
    suraNo: int.parse(m['sura_no'].toString()),
    suraNameEn: m['sura_name_en'].toString(),
    suraNameAr: m['sura_name_ar'].toString(),
    lineStart: int.parse(m['line_start'].toString()),
    lineEnd: int.parse(m['line_end'].toString()),
    ayaNo: int.parse(m['aya_no'].toString()),
    ayaText: m['aya_text'].toString(),
  );

  // Number of lines this verse spans
  int get lineSpan => lineEnd - lineStart + 1;

  String get verseRef => '$suraNameAr • الآية ${_toEasternArabic(ayaNo)}';

  static String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}
