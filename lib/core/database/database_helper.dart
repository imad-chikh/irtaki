import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbAsset = 'assets/db/quran_warsh.db';
  static const _dbName = 'quran_warsh.db';
  static const _dbVersion = 1; // bump this when you ship a new DB file
  static Database? _instance;

  static Future<Database> get database async {
    _instance ??= await _init();
    return _instance!;
  }

  static Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    if (!await File(path).exists()) {
      await _copyAsset(path);
    } else {
      // Re-copy if app ships a newer DB version
      final db = await openDatabase(path, readOnly: true);
      final ver = await db.getVersion();
      final isValid = await _isDatabaseValid(db);
      await db.close();
      if (ver < _dbVersion || !isValid) {
        await File(path).delete();
        await _copyAsset(path);
      }
    }

    return openDatabase(path, readOnly: true);
  }

  static Future<bool> _isDatabaseValid(Database db) async {
    try {
      final pageRange = await db.rawQuery(
        'SELECT MIN(CAST(page AS INTEGER)) AS min_page, MAX(CAST(page AS INTEGER)) AS max_page FROM verses',
      );
      final minPage = int.tryParse(pageRange.first['min_page'].toString());
      final maxPage = int.tryParse(pageRange.first['max_page'].toString());
      if (minPage != 1 || maxPage != 604) {
        return false;
      }

      final distinctSurahs = await db.rawQuery(
        'SELECT COUNT(DISTINCT sura_no) AS cnt FROM verses',
      );
      final surahCount = int.tryParse(distinctSurahs.first['cnt'].toString());
      if (surahCount != 114) {
        return false;
      }

      // Known guardrails to catch broken imports seen in older DB builds.
      final surah2 = await db.rawQuery(
        'SELECT MIN(CAST(page AS INTEGER)) AS first_page FROM verses WHERE sura_no = 2',
      );
      final surah4 = await db.rawQuery(
        'SELECT MIN(CAST(page AS INTEGER)) AS first_page FROM verses WHERE sura_no = 4',
      );
      final s2 = int.tryParse(surah2.first['first_page'].toString());
      final s4 = int.tryParse(surah4.first['first_page'].toString());
      return s2 == 2 && s4 == 77;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _copyAsset(String targetPath) async {
    await Directory(dirname(targetPath)).create(recursive: true);
    final bytes = await rootBundle.load(_dbAsset);
    await File(targetPath).writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  }
}
