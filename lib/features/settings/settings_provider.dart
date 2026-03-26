import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

enum ReadingMode { page, scroll }

class Settings {
  final bool showTajweed;
  final double fontSize;
  final ReadingMode readingMode;
  final ThemeMode themeMode;
  final int lastReadPage;

  const Settings({
    this.showTajweed = false,
    this.fontSize = 22.0,
    this.readingMode = ReadingMode.page,
    this.themeMode = ThemeMode.system,
    this.lastReadPage = 1,
  });

  Settings copyWith({
    bool? showTajweed,
    double? fontSize,
    ReadingMode? readingMode,
    ThemeMode? themeMode,
    int? lastReadPage,
  }) => Settings(
    showTajweed: showTajweed ?? this.showTajweed,
    fontSize: fontSize ?? this.fontSize,
    readingMode: readingMode ?? this.readingMode,
    themeMode: themeMode ?? this.themeMode,
    lastReadPage: lastReadPage ?? this.lastReadPage,
  );
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  SharedPreferences? _prefs;

  @override
  Settings build() {
    _initPrefs();
    return const Settings();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs != null) {
      state = Settings(
        showTajweed: _prefs!.getBool('showTajweed') ?? false,
        fontSize: _prefs!.getDouble('fontSize') ?? 22.0,
        readingMode: ReadingMode.values[_prefs!.getInt('readingMode') ?? 0],
        themeMode: ThemeMode.values[_prefs!.getInt('themeMode') ?? 0],
        lastReadPage: _prefs!.getInt('lastReadPage') ?? 1,
      );
    }
  }

  Future<void> setTajweed(bool val) async {
    state = state.copyWith(showTajweed: val);
    await _prefs?.setBool('showTajweed', val);
  }

  Future<void> setFontSize(double val) async {
    state = state.copyWith(fontSize: val);
    await _prefs?.setDouble('fontSize', val);
  }

  Future<void> setReadingMode(ReadingMode val) async {
    state = state.copyWith(readingMode: val);
    await _prefs?.setInt('readingMode', val.index);
  }

  Future<void> setTheme(ThemeMode val) async {
    state = state.copyWith(themeMode: val);
    await _prefs?.setInt('themeMode', val.index);
  }

  Future<void> setLastPage(int val) async {
    state = state.copyWith(lastReadPage: val);
    await _prefs?.setInt('lastReadPage', val);
  }
}
