class MushafLine {
  final int surah;
  final int ayah;
  final String partText;
  final int partIndex;
  final int partsCount;
  final bool isLastPartOfAyah;
  final bool isFirstPartOfAyah;

  const MushafLine({
    required this.surah,
    required this.ayah,
    required this.partText,
    required this.partIndex,
    required this.partsCount,
    required this.isLastPartOfAyah,
    required this.isFirstPartOfAyah,
  });

  String get ayahKey => '$surah:$ayah';
}
