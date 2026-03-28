import '../models/mushaf_line_model.dart';

List<MushafLine> parseQuranJson(List<dynamic> json) {
  final lines = <MushafLine>[];

  for (final item in json) {
    if (item is! Map<String, dynamic>) {
      continue;
    }

    final surah = (item['surah'] as num?)?.toInt();
    final ayah = (item['ayah'] as num?)?.toInt();
    final parts = item['parts'];

    if (surah == null || ayah == null || parts is! List) {
      continue;
    }

    final sanitizedParts = parts
        .map((e) => e?.toString() ?? '')
        .map((text) => text.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);

    for (var i = 0; i < sanitizedParts.length; i++) {
      lines.add(
        MushafLine(
          surah: surah,
          ayah: ayah,
          partText: sanitizedParts[i],
          partIndex: i,
          partsCount: sanitizedParts.length,
          isLastPartOfAyah: i == sanitizedParts.length - 1,
          isFirstPartOfAyah: i == 0,
        ),
      );
    }
  }

  return lines;
}
