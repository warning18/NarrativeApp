import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/stitched_ink.dart';

/// A curated set of palettes the player can pick from in Settings.
/// [stitchedInk], the default, is the palette the app's look was drawn in
/// (see `theme/stitched_ink.dart`); the others are rendered via
/// [ColorScheme.fromSeed] so the whole app derives consistently from a
/// single accent color. All of them share the same type and shapes.
enum AppPalette {
  stitchedInk,
  deepPurple,
  weatheredEarth,
  autumnMeadow,
  duskHorizon,
  auroraDusk,
  roseNoir,
  mistSlate;

  /// This palette's colour scheme in [brightness].
  ColorScheme schemeFor(Brightness brightness) => this == stitchedInk
      ? stitchedInkScheme(brightness)
      : ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

  Color get seedColor {
    switch (this) {
      case AppPalette.stitchedInk:
        return const Color(0xFFF2C14E);
      case AppPalette.deepPurple:
        return Colors.deepPurple;
      case AppPalette.weatheredEarth:
        return const Color(0xFF7A3F41);
      case AppPalette.autumnMeadow:
        return const Color(0xFFBC6B3C);
      case AppPalette.duskHorizon:
        return const Color(0xFF4C4967);
      case AppPalette.auroraDusk:
        return const Color(0xFF166E7A);
      case AppPalette.roseNoir:
        return const Color(0xFFD03791);
      case AppPalette.mistSlate:
        return const Color(0xFF565A75);
    }
  }

  /// A short swatch of colors used to preview the palette in Settings.
  List<Color> get swatch {
    switch (this) {
      case AppPalette.stitchedInk:
        return const [Color(0xFFF2C14E), Color(0xFFA987EA), Color(0xFF4FB0B0)];
      case AppPalette.deepPurple:
        return const [Color(0xFF6750A4), Color(0xFF9A82DB), Color(0xFFEADDFF)];
      case AppPalette.weatheredEarth:
        return const [Color(0xFF3D2C39), Color(0xFF9C4F41), Color(0xFFC88A5C)];
      case AppPalette.autumnMeadow:
        return const [Color(0xFF7B4238), Color(0xFFBC6B3C), Color(0xFFB7A94E)];
      case AppPalette.duskHorizon:
        return const [Color(0xFF1B3B5C), Color(0xFF8B6178), Color(0xFFFCA85C)];
      case AppPalette.auroraDusk:
        return const [Color(0xFF166E7A), Color(0xFF52C33F), Color(0xFFFCF660)];
      case AppPalette.roseNoir:
        return const [Color(0xFF452459), Color(0xFFD03791), Color(0xFFFE6C90)];
      case AppPalette.mistSlate:
        return const [Color(0xFF0F0F1B), Color(0xFF565A75), Color(0xFFC6B7BE)];
    }
  }
}

const String _palettePrefsKey = 'app_palette';

class AppPaletteNotifier extends StateNotifier<AppPalette> {
  AppPaletteNotifier() : super(AppPalette.stitchedInk) {
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
    StateNotifierProvider<AppPaletteNotifier, AppPalette>(
        (ref) => AppPaletteNotifier());
