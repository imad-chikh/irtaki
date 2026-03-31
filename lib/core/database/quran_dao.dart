import 'package:sqflite/sqflite.dart';

import '../models/surah.dart';
import '../models/verse.dart';
import 'database_helper.dart';

class QuranDao {
  Future<Database> get _db => DatabaseHelper.database;

  // All 114 surahs (for Fihras screen)
  Future<List<Surah>> getAllSurahs() async {
    final db = await _db;
    final rows = await db.query('surahs', orderBy: 'sura_no ASC');
    return rows.map(Surah.fromMap).toList();
  }

  // Surah by number
  Future<Surah> getSurah(int suraNo) async {
    final db = await _db;
    final rows = await db.query(
      'surahs',
      where: 'sura_no = ?',
      whereArgs: [suraNo],
    );
    return Surah.fromMap(rows.first);
  }

  // All verses on a given page — THIS IS THE PRIMARY READER QUERY
  // Returns verses ordered by their line_start, which matches Mushaf order
  Future<List<Verse>> getVersesByPage(int page) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM verses WHERE CAST(page AS INTEGER) = ? ORDER BY line_start ASC, aya_no ASC',
      [page],
    );
    return rows.map(Verse.fromMap).toList();
  }

  // All verses of a surah (for surah-mode reading)
  Future<List<Verse>> getVersesBySura(int suraNo) async {
    final db = await _db;
    final rows = await db.query(
      'verses',
      where: 'sura_no = ?',
      whereArgs: [suraNo],
      orderBy: 'aya_no ASC',
    );
    return rows.map(Verse.fromMap).toList();
  }

  // Total number of pages in this Warsh mushaf
  Future<int> getTotalPages() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT MAX(CAST(page AS INTEGER)) as max_page FROM verses',
    );
    return int.parse(result.first['max_page'].toString());
  }

  // Which page does a surah start on?
  Future<int> getPageForSura(int suraNo) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT MIN(CAST(page AS INTEGER)) as first_page FROM verses WHERE sura_no = ?',
      [suraNo],
    );

    final firstPage = result.first['first_page'];
    if (firstPage != null) {
      return int.parse(firstPage.toString());
    }

    // Fallback to surahs table metadata if verse rows are unexpectedly missing.
    final surah = await getSurah(suraNo);
    return surah.pageStart;
  }

  // Search
  Future<List<Verse>> search(String query) async {
    final db = await _db;
    final rows = await db.query(
      'verses',
      where: 'aya_text LIKE ?',
      whereArgs: ['%$query%'],
    );
    return rows.map(Verse.fromMap).toList();
  }
}
