import 'package:flutter/material.dart';

import '../models/mushaf_line_model.dart';
import 'mushaf_line_widget.dart';

class MushafPageWidget extends StatefulWidget {
  final List<MushafLine> lines;
  final Map<int, String> surahNames;
  final double maxPageWidth;
  final EdgeInsetsGeometry pagePadding;
  final double fontSize;
  final double lineHeight;

  const MushafPageWidget({
    super.key,
    required this.lines,
    required this.surahNames,
    this.maxPageWidth = 430,
    this.pagePadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    this.fontSize = 28,
    this.lineHeight = 1.8,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  static const double _lineSafetyPx = 10.0;

  int? _selectedSurah;
  int? _selectedAyah;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFDF6E3),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxPageWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lineStyle = TextStyle(
                fontFamily: 'KFGQPCWarshOthmanTahaFont',
                fontFamilyFallback: const [
                  'Scheherazade New',
                  'NotoNaskhArabic',
                ],
                fontSize: widget.fontSize,
                height: widget.lineHeight,
              );
              final visualLines = _packIntoVisualLines(
                source: widget.lines,
                maxWidth: constraints.maxWidth - 36 - _lineSafetyPx,
                textStyle: lineStyle,
              );

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFDF6E3),
                    padding: widget.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...(() {
                          final renderedHeaderSurahs = <int>{};
                          final children = <Widget>[];

                          for (var i = 0; i < visualLines.length; i++) {
                            final first = visualLines[i].first;
                            final shouldShowHeader =
                                first.ayah == 1 &&
                                !renderedHeaderSurahs.contains(first.surah);

                            if (shouldShowHeader) {
                              renderedHeaderSurahs.add(first.surah);
                              children.add(
                                _SurahHeaderCard(
                                  name:
                                      widget.surahNames[first.surah] ??
                                      'سورة ${_toEasternArabic(first.surah)}',
                                ),
                              );

                              if (first.surah != 9) {
                                children.add(
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4, bottom: 6),
                                    child: Text(
                                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'KFGQPCWarshOthmanTahaFont',
                                        fontFamilyFallback: [
                                          'Scheherazade New',
                                          'NotoNaskhArabic',
                                        ],
                                        fontSize: 26,
                                        height: 1.3,
                                        color: Color(0xFF7A5A00),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }

                            children.add(
                              MushafLineWidget(
                                segments: visualLines[i],
                                fontSize: widget.fontSize,
                                lineHeight: widget.lineHeight,
                                forceNaturalEnd: i == visualLines.length - 1,
                                highlighted: _isHighlightedLine(visualLines[i]),
                                onTap: () =>
                                    _toggleAyahSelection(visualLines[i].first),
                              ),
                            );
                          }

                          return children;
                        })(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isHighlighted(MushafLine line) {
    return _selectedSurah == line.surah && _selectedAyah == line.ayah;
  }

  bool _isHighlightedLine(List<MushafLine> lineSegments) {
    return lineSegments.any(_isHighlighted);
  }

  void _toggleAyahSelection(MushafLine line) {
    setState(() {
      if (_selectedSurah == line.surah && _selectedAyah == line.ayah) {
        _selectedSurah = null;
        _selectedAyah = null;
        return;
      }

      _selectedSurah = line.surah;
      _selectedAyah = line.ayah;
    });
  }

  String _toEasternArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  List<List<MushafLine>> _packIntoVisualLines({
    required List<MushafLine> source,
    required double maxWidth,
    required TextStyle textStyle,
  }) {
    if (source.isEmpty) {
      return const <List<MushafLine>>[];
    }

    final out = <List<MushafLine>>[];
    var current = <MushafLine>[];

    for (final seg in source) {
      if (current.isNotEmpty && _mustStartNewLine(current.last, seg)) {
        out.add(current);
        current = <MushafLine>[];
      }

      final candidate = <MushafLine>[...current, seg];
      final candidateWidth = _measurePackedLineWidth(candidate, textStyle);

      if (current.isNotEmpty && candidateWidth > maxWidth) {
        out.add(current);
        current = <MushafLine>[seg];
      } else {
        current = candidate;
      }
    }

    if (current.isNotEmpty) {
      out.add(current);
    }

    return out;
  }

  double _measurePackedLineWidth(List<MushafLine> segments, TextStyle style) {
    final text = segments
        .map((s) => s.partText)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final badgeCount = segments.where((s) => s.isLastPartOfAyah).length;
    return textPainter.width + (badgeCount * 34.0);
  }

  bool _mustStartNewLine(MushafLine previous, MushafLine next) {
    // Continuation part (partIndex > 0) must start on a new physical line.
    if (!next.isFirstPartOfAyah) {
      return true;
    }

    // Defensive fallback: same-ayah second segment also starts a new line.
    if (previous.surah == next.surah && previous.ayah == next.ayah) {
      return true;
    }

    return false;
  }
}

class _SurahHeaderCard extends StatelessWidget {
  final String name;

  const _SurahHeaderCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECD2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8960C), width: 1),
      ),
      child: Text(
        name,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: Color(0xFF704F00),
        ),
      ),
    );
  }
}
