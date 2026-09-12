import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_themes.dart';

const String _mapThemePrefsKey = 'map_theme';

/// The player's manual map-theme override, or null to automatically match
/// the excursion flavor to each story node's own [StoryNode.uiTheme] (see
/// [mapThemeForUiTheme]) — the default, so a fresh install never needs one
/// global setting to fit every chapter's very different scenery.
class MapThemeNotifier extends StateNotifier<MapTheme?> {
  MapThemeNotifier() : super(null) {
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

  /// Pass null to switch back to automatically matching the story.
  Future<void> setTheme(MapTheme? theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    if (theme == null) {
      await prefs.remove(_mapThemePrefsKey);
    } else {
      await prefs.setString(_mapThemePrefsKey, theme.name);
    }
  }
}

final mapThemeProvider =
    StateNotifierProvider<MapThemeNotifier, MapTheme?>((ref) => MapThemeNotifier());
