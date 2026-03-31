class WarshTextNormalizer {
  static final RegExp _arabicDiacritics = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D4-\u08FF]',
  );

  static final RegExp _warshGlyphs = RegExp(r'[\uF000-\uF8FF]');
  static final RegExp _nonArabic = RegExp(r'[^\u0600-\u06FF\s]');
  static final RegExp _extraSpaces = RegExp(r'\s+');

  String normalize(String input) {
    var text = input;

    text = text.replaceAll(_warshGlyphs, ' ');
    text = text.replaceAll(_arabicDiacritics, '');

    text = text
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٲ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ء', '');

    text = text.replaceAll(_nonArabic, ' ');
    text = text.replaceAll(_extraSpaces, ' ').trim();

    return text;
  }

  List<String> tokenize(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return const [];
    }
    return normalized.split(' ');
  }
}
