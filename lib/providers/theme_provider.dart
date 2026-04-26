import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _themeKey = 'themeMode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_themeKey, defaultValue: 'system') as String;
    state = _fromString(saved);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, mode.name);
  }

  ThemeMode _fromString(String s) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == s,
      orElse: () => ThemeMode.system,
    );
  }
}
