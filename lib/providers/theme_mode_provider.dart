import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModePrefsKey = 'app_theme_mode';

class _ThemeModeNotifier extends StateNotifier<ThemeMode> {
  _ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModePrefsKey);
    final match = ThemeMode.values.where((m) => m.name == saved);
    if (match.isNotEmpty) state = match.first;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }
}

/// Light / dark / follow-system theme preference; persisted via
/// [SharedPreferences]. Defaults to following the device setting.
final themeModeProvider = StateNotifierProvider<_ThemeModeNotifier, ThemeMode>(
    (ref) => _ThemeModeNotifier());
