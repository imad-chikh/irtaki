class Surah {
  final int suraNo;
  final String suraNameEn;
  final String suraNameAr;
  final int versesCount;
  final int pageStart;
  final int juzStart;
  final bool hasBasmala;

  const Surah({
    required this.suraNo,
    required this.suraNameEn,
    required this.suraNameAr,
    required this.versesCount,
    required this.pageStart,
    required this.juzStart,
    required this.hasBasmala,
  });

  factory Surah.fromMap(Map<String, dynamic> m) => Surah(
    suraNo: int.parse(m['sura_no'].toString()),
    suraNameEn: m['sura_name_en'].toString(),
    suraNameAr: m['sura_name_ar'].toString(),
    versesCount: int.parse(m['verses_count'].toString()),
    pageStart: int.parse(m['page_start'].toString()),
    juzStart: int.parse(m['juz_start'].toString()),
    hasBasmala: m['has_basmala'].toString() == '1',
  );
}
