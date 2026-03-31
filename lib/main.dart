import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/ai/search/verse_search_index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  try {
    await VerseSearchIndex.instance.warmUp();
  } catch (_) {}

  runApp(const ProviderScope(child: QuranApp()));
}
