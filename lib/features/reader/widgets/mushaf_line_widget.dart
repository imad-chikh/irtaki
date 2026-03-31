import 'package:flutter/material.dart';

import '../../../shared/verse_number_badge.dart';

class MushafLine {
  final String partText;
  final int ayah;
  final bool isLastPartOfAyah;

  const MushafLine({
    required this.partText,
    required this.ayah,
    required this.isLastPartOfAyah,
  });
}

class MushafLineWidget extends StatelessWidget {
  static const _tatweel = '\u0640';
  static const _defaultLineBg = Colors.transparent;

  final List<MushafLine> segments;
  final double fontSize;
  final double lineHeight;
  final bool highlighted;
  final VoidCallback? onTap;
  final String fontFamily;
  final bool forceNaturalEnd;

  const MushafLineWidget({
    super.key,
    required this.segments,
    this.fontSize = 28,
    this.lineHeight = 1.8,
    this.highlighted = false,
    this.onTap,
    this.fontFamily = 'KFGQPCWarshOthmanTahaFont',
    this.forceNaturalEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Scheherazade New', 'NotoNaskhArabic'],
      fontSize: fontSize,
      height: lineHeight,
      color: const Color(0xFF1F1A14),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final badgesCount = segments.where((s) => s.isLastPartOfAyah).length;
        final reservedForBadges = badgesCount * 34.0;
        final availableWidth = (constraints.maxWidth - reservedForBadges).clamp(
          0.0,
          double.infinity,
        );

        final rawLineText = _composeRawLineText();
        final endWithAyahEnd = segments.last.isLastPartOfAyah;
        final shouldNatural = forceNaturalEnd || endWithAyahEnd;

        final displayText = shouldNatural
            ? rawLineText
            : _justifyWithKashida(
                text: rawLineText,
                targetWidth: availableWidth,
                textStyle: textStyle,
              );

        final textPieces = _splitByWords(displayText);
        var cursor = 0;

        final spans = <InlineSpan>[];
        for (var i = 0; i < segments.length; i++) {
          final seg = segments[i];
          final words = _splitByWords(seg.partText);
          final take = words.length;
          final segWords = cursor + take <= textPieces.length
              ? textPieces.sublist(cursor, cursor + take)
              : words;
          cursor += take;

          spans.add(TextSpan(text: '${segWords.join(' ')} ', style: textStyle));

          if (seg.isLastPartOfAyah) {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, left: 2),
                  child: VerseNumberBadge(number: seg.ayah),
                ),
              ),
            );
            spans.add(const TextSpan(text: ' '));
          }
        }

        return Material(
          color: highlighted ? const Color(0xFFF3E8C5) : _defaultLineBg,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(
                TextSpan(children: spans),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        );
      },
    );
  }

  String _composeRawLineText() {
    return segments
        .map((s) => s.partText)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _splitByWords(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) {
      return const <String>[];
    }
    return t.split(' ');
  }

  String _justifyWithKashida({
    required String text,
    required double targetWidth,
    required TextStyle textStyle,
  }) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    const epsilon = 0.8;

    final words = normalized.split(' ');
    if (words.length <= 1) {
      return normalized;
    }

    final currentWidth = _measureWidth(normalized, textStyle);
    if (currentWidth >= targetWidth - epsilon) {
      return normalized;
    }

    final kashidaWidth = _measureWidth(_tatweel, textStyle);
    if (kashidaWidth <= 0) {
      return normalized;
    }

    final needed = ((targetWidth - currentWidth) / kashidaWidth).floor();
    if (needed <= 0) {
      return normalized;
    }

    final distribution = List<int>.filled(words.length, 0);
    final capacities = words
        .map((w) => KashidaCalculator.getAvailableKashidaCount(w))
        .toList(growable: false);

    var remaining = needed;
    while (remaining > 0) {
      var changed = false;
      for (var i = 0; i < words.length && remaining > 0; i++) {
        final cap = capacities[i];
        if (cap <= 0) {
          continue;
        }

        // Keep elongation natural and avoid over-stretching one word.
        final maxForWord = cap * 2;
        if (distribution[i] >= maxForWord) {
          continue;
        }

        distribution[i] += 1;
        remaining -= 1;
        changed = true;
      }

      if (!changed) {
        break;
      }
    }

    final outWords = <String>[];
    for (var i = 0; i < words.length; i++) {
      outWords.add(
        KashidaCalculator.addKashidasToWord(words[i], distribution[i]),
      );
    }

    final candidate = outWords.join(' ');
    final candidateWidth = _measureWidth(candidate, textStyle);
    if (candidateWidth > targetWidth + epsilon) {
      return normalized;
    }

    return candidate;
  }

  double _measureWidth(String text, TextStyle textStyle) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return painter.width;
  }
}

class KashidaCalculator {
  static const _tatweel = '\u0640';
  static final RegExp _arabicLetters = RegExp(r'[\u0621-\u064A]');
  static const Set<String> _nonStretchable = {
    'ا',
    'أ',
    'إ',
    'آ',
    'د',
    'ذ',
    'ر',
    'ز',
    'و',
    'ؤ',
    'ء',
    'ى',
  };

  static int getAvailableKashidaCount(String word) {
    final candidates = _candidatePositions(word);
    return candidates.length;
  }

  static String addKashidasToWord(String word, int count) {
    if (count <= 0) {
      return word;
    }

    final positions = _candidatePositions(word);
    if (positions.isEmpty) {
      return word;
    }

    final chars = word.split('');
    final insertions = List<int>.filled(chars.length + 1, 0);

    for (var i = 0; i < count; i++) {
      final pos = positions[i % positions.length];
      insertions[pos + 1] += 1;
    }

    final out = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      out.write(chars[i]);
      final repeats = insertions[i + 1];
      for (var j = 0; j < repeats; j++) {
        out.write(_tatweel);
      }
    }
    return out.toString();
  }

  static List<int> _candidatePositions(String word) {
    final chars = word.split('');
    if (chars.length < 2) {
      return const [];
    }

    final positions = <int>[];
    for (var i = 0; i < chars.length - 1; i++) {
      final current = chars[i];
      final next = chars[i + 1];
      if (!_arabicLetters.hasMatch(current) || !_arabicLetters.hasMatch(next)) {
        continue;
      }
      if (_nonStretchable.contains(current)) {
        continue;
      }
      positions.add(i);
    }
    return positions;
  }
}
