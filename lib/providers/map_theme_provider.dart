import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_themes.dart';

const String _mapThemePrefsKey = 'map_theme';

class MapThemeNotifier extends StateNotifier<MapTheme> {
  MapThemeNotifier() : super(defaultMapTheme) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_mapThemePrefsKey);
    if (saved == null) return;
    for (final theme in MapTheme.values) {
      if (theme.name == saved) {
        state = theme;
        return;
      }
    }
  }

  Future<void> setTheme(MapTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapThemePrefsKey, theme.name);
  }
}

final mapThemeProvider =
    StateNotifierProvider<MapThemeNotifier, MapTheme>((ref) => MapThemeNotifier());
