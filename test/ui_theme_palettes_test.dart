// Unit coverage for ui_theme_palettes.dart's lookup table and color-blend
// logic -- the location-based accent theming behind _StoryText in
// story_player_screen.dart. The blending is the part most likely to go
// wrong across the app's 7 selectable base palettes and both light/dark
// mode, so it's pulled out as a pure function specifically to be testable
// without pumping a widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ui_theme_palettes.dart';

void main() {
  group('uiThemePaletteFor', () {
    test('known locations resolve to a palette', () {
      expect(uiThemePaletteFor('docks'), isNotNull);
      expect(uiThemePaletteFor('cathedral'), isNotNull);
      expect(uiThemePaletteFor('torture_chamber'), isNotNull);
      expect(uiThemePaletteFor('slums'), isNotNull);
      expect(uiThemePaletteFor('catacombs'), isNotNull);
      expect(uiThemePaletteFor('sewers'), isNotNull);
      expect(uiThemePaletteFor('origin_ending'), isNotNull);
      expect(uiThemePaletteFor('epilogue'), isNotNull);
    });

    test('deliberately-unthemed rare locations fall back to null', () {
      // These settings have too few nodes (under 5 each) to be worth a
      // distinct identity -- they should read in the app's own theme.
      for (final uiTheme in [
        'bridge',
        'market',
        'hovel',
        'gate',
        'prologue',
        'battlements',
      ]) {
        expect(uiThemePaletteFor(uiTheme), isNull, reason: uiTheme);
      }
    });

    test('an unknown or null ui_theme falls back to null', () {
      expect(uiThemePaletteFor(null), isNull);
      expect(uiThemePaletteFor('nonsense_theme'), isNull);
      expect(uiThemePaletteFor(''), isNull);
    });
  });

  group('resolveUiAccent', () {
    // A representative light and dark scheme, matching how main.dart
    // actually builds ColorScheme.fromSeed for each ThemeMode.
    final lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple, brightness: Brightness.light);
    final darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple, brightness: Brightness.dark);

    test(
        'with no palette, every field is exactly the scheme\'s own color '
        '-- the card looks unchanged from before this feature existed', () {
      for (final scheme in [lightScheme, darkScheme]) {
        final accent = resolveUiAccent(scheme, null);
        expect(accent.text, scheme.primary);
        expect(accent.border, scheme.outlineVariant);
        expect(accent.cardTint, scheme.surfaceContainerHighest);
      }
    });

    test(
        'with a palette, every field visibly shifts toward its accent hue, '
        'in both light and dark mode', () {
      const palette = UiThemePalette(accent: Color(0xFFC9A227)); // cathedral
      for (final scheme in [lightScheme, darkScheme]) {
        final accent = resolveUiAccent(scheme, palette);
        expect(accent.text, isNot(scheme.primary));
        expect(accent.border, isNot(scheme.outlineVariant));
        expect(accent.cardTint, isNot(scheme.surfaceContainerHighest));
      }
    });

    test(
        'the resolved text color stays legible in both directions: '
        'lighter than onSurface in dark mode, darker in light mode', () {
      const palette = UiThemePalette(accent: Color(0xFFC9A227));

      final darkAccent = resolveUiAccent(darkScheme, palette);
      // Dark mode's onSurface is near-white; blending toward a mid-tone
      // gold should darken it somewhat, but it must stay well clear of
      // black -- otherwise the header would vanish against a dark card.
      expect(darkAccent.text.computeLuminance(), greaterThan(0.2));

      final lightAccent = resolveUiAccent(lightScheme, palette);
      // Light mode's onSurface is near-black; the same blend should stay
      // well clear of white so the header doesn't wash out against a
      // light card.
      expect(lightAccent.text.computeLuminance(), lessThan(0.8));
    });
  });
}
