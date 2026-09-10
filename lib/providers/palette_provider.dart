import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A curated set of seed-color palettes the player can pick from in
/// Settings. Each is rendered via [ColorScheme.fromSeed] so the whole
/// app's light theme derives consistently from a single accent color.
enum AppPalette {
  deepPurple,
  weatheredEarth,
  autumnMeadow,
  duskHorizon;

  Color get seedColor {
    switch (this) {
      case AppPalette.deepPurple:
        return Colors.deepPurple;
      case AppPalette.weatheredEarth:
        return const Color(0xFF7A3F41);
      case AppPalette.autumnMeadow:
        return const Color(0xFFBC6B3C);
      case AppPalette.duskHorizon:
        return const Color(0xFF4C4967);
    }
  }

  /// A short swatch of colors used to preview the palette in Settings.
  List<Color> get swatch {
    switch (this) {
      case AppPalette.deepPurple:
        return const [Color(0xFF6750A4), Color(0xFF9A82DB), Color(0xFFEADDFF)];
      case AppPalette.weatheredEarth:
        return const [Color(0xFF3D2C39), Color(0xFF9C4F41), Color(0xFFC88A5C)];
      case AppPalette.autumnMeadow:
        return const [Color(0xFF7B4238), Color(0xFFBC6B3C), Color(0xFFB7A94E)];
      case AppPalette.duskHorizon:
        return const [Color(0xFF1B3B5C), Color(0xFF8B6178), Color(0xFFFCA85C)];
    }
  }
}

const String _palettePrefsKey = 'app_palette';

class AppPaletteNotifier extends StateNotifier<AppPalette> {
  AppPaletteNotifier() : super(AppPalette.deepPurple) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_palettePrefsKey);
    final match = AppPalette.values.where((p) => p.name == saved);
    if (match.isNotEmpty) state = match.first;
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_palettePrefsKey, palette.name);
  }
}

final appPaletteProvider =
    StateNotifierProvider<AppPaletteNotifier, AppPalette>((ref) => AppPaletteNotifier());
