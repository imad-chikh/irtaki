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
      await db.close();
      if (ver < _dbVersion) {
        await File(path).delete();
        await _copyAsset(path);
      }
    }

    return openDatabase(path, readOnly: true);
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
