import 'package:flutter/material.dart';

// Warsh-specific tajweed color map (different rules from Hafs)
class TajweedColors {
  static const map = {
    'ghunnah': Color(0xFF00A550),
    'idgham': Color(0xFF00A550),
    'idgham_ghunnah': Color(0xFF00A550),
    'ikhfa': Color(0xFF4CAF50),
    'ikhfa_shafawi': Color(0xFF4CAF50),
    'idgham_shafawi': Color(0xFF00A550),
    'iqlab': Color(0xFFFF5722),
    'qalqalah': Color(0xFF9C27B0),
    'madd_normal': Color(0xFF2196F3),
    'madd_lazim': Color(0xFF1565C0),
    'madd_muttasil': Color(0xFF0288D1),
    'madd_munfasil': Color(0xFF039BE5),
    'laam_shamsiyya': Color(0xFFE53935),
    'hamzat_wasl': Color(0xFF795548),
    'silent': Color(0xFF9E9E9E),
    // Warsh-specific
    'leen': Color(0xFF00BCD4), // cyan — leen madds unique to Warsh
    'tasheel': Color(0xFFFF9800), // amber — tasheel al-hamza
    'ibdal': Color(0xFFFF9800), // amber — ibdal al-hamza
    'naql': Color(0xFFE91E63), // pink  — naql al-haraka
    'sakt': Color(0xFF607D8B), // blue-grey — sakt
  };

  static Color forRule(String? rule) => rule != null
      ? (map[rule] ?? const Color(0xFF1C1C1E))
      : const Color(0xFF1C1C1E);
}
