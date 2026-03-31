import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/verse.dart';
import '../features/fihras/fihras_screen.dart';
import '../features/recitation/recitation_check_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    if (state.uri.toString() == '/') {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getInt('lastReadPage') ?? 1;
      if (lastPage > 1) {
        return '/reader/$lastPage';
      }
      return '/fihras';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const FihrasScreen(), // Just a placeholder, will redirect
    ),
    GoRoute(path: '/fihras', builder: (context, state) => const FihrasScreen()),
    GoRoute(
      path: '/reader/:page',
      builder: (context, state) {
        final pageStr = state.pathParameters['page'];
        final page = int.tryParse(pageStr ?? '1') ?? 1;
        final surahStr = state.uri.queryParameters['surah'];
        final initialSurah = int.tryParse(surahStr ?? '');
        return ReaderScreen(
          key: state.pageKey,
          initialPage: page,
          initialSurah: initialSurah,
        );
      },
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/recitation-check',
      builder: (context, state) {
        final verse = state.extra is Verse ? state.extra! as Verse : null;
        if (verse == null) {
          return const SearchScreen();
        }
        return RecitationCheckScreen(verse: verse);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
