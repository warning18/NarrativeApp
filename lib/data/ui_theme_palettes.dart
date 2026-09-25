import 'package:flutter/material.dart';

/// A small, deliberately restrained visual accent for one of the story
/// graph's settings (`context_taxonomy.ui_theme` in the DAG, exposed as
/// [StoryNode.uiTheme]) — lets the reading screen's prose card shift color
/// and type feel to match where the player currently is (the docks read
/// differently from the cathedral), layered on top of the player's own
/// chosen app palette (see `AppPalette`/`palette_provider.dart`) rather than
/// replacing it: only the story page's stitched edge, place tag and
/// header color change, never the app's chrome, nav bar, or other
/// screens. (The page no longer paints a card, so [ResolvedUiAccent.cardTint]
/// and [UiThemePalette.headerWeight] are kept for the tests and other
/// palettes but unused by the reading screen.)
///
/// Deliberately not every `ui_theme` value gets an entry — the rarer
/// settings (bridge, market, hovel, gate, prologue, battlements, each under
/// 5 nodes) read fine in the app's own default theme; [uiThemePaletteFor]
/// returns null for those, and callers fall back to their existing colors.
class UiThemePalette {
  const UiThemePalette({
    required this.accent,
    this.letterSpacing = 0.2,
    this.lineHeight = 1.55,
    this.headerWeight = FontWeight.w700,
  });

  /// The location's signature hue. Never used at full strength directly
  /// against text or backgrounds — callers blend it with the scheme's own
  /// contrast-correct colors (e.g. `Color.lerp(colorScheme.onSurface,
  /// accent, 0.7)`) so it stays legible in both light and dark mode and
  /// against any of the app's selectable base palettes.
  final Color accent;

  /// A subtle typographic personality knob: how tight or loose the prose
  /// reads. Most locations lean on the reading screen's own default; a few
  /// nudge it for pacing (tighter for the interrogation scenes, slower and
  /// heavier for the catacombs/sewers).
  final double letterSpacing;
  final double lineHeight;
  final FontWeight headerWeight;
}

const Map<String, UiThemePalette> uiThemePalettes = {
  // Cool, working-harbor steel-teal.
  'docks': UiThemePalette(accent: Color(0xFF3E7C8C)),
  // Warm antique gold, ceremonial weight.
  'cathedral': UiThemePalette(
    accent: Color(0xFFC9A227),
    letterSpacing: 0.4,
    headerWeight: FontWeight.w800,
  ),
  // Dried-blood red, clipped and urgent.
  'torture_chamber': UiThemePalette(
    accent: Color(0xFF9A2E2E),
    letterSpacing: 0.1,
    lineHeight: 1.48,
  ),
  // Soot and rust.
  'slums': UiThemePalette(accent: Color(0xFF8C6A4A)),
  // Cold bone-grey stone, slow and oppressive.
  'catacombs': UiThemePalette(
    accent: Color(0xFF6E7C76),
    lineHeight: 1.68,
  ),
  // Sickly, toxic olive.
  'sewers': UiThemePalette(
    accent: Color(0xFF6B7A3A),
    lineHeight: 1.68,
  ),
  // Warm parchment gold — quiet, reflective closure.
  'origin_ending': UiThemePalette(
    accent: Color(0xFFB89B72),
    letterSpacing: 0.3,
  ),
  // Soft dusk blue-grey — the calm after, distinct from origin_ending's
  // warmth.
  'epilogue': UiThemePalette(
    accent: Color(0xFF7C8CA0),
    letterSpacing: 0.3,
  ),
};

/// The palette for [uiTheme], or null to leave the reading screen's colors
/// exactly as they already are.
UiThemePalette? uiThemePaletteFor(String? uiTheme) => uiThemePalettes[uiTheme];

/// The colors [_StoryText] (`story_player_screen.dart`) paints with
/// (text and border; cardTint is no longer painted), once a [UiThemePalette]'s raw accent has been blended
/// against a real [ColorScheme].
class ResolvedUiAccent {
  const ResolvedUiAccent({
    required this.text,
    required this.border,
    required this.cardTint,
  });

  /// Header/divider color.
  final Color text;

  /// Card border color.
  final Color border;

  /// Card background tint (before the caller's own opacity is applied).
  final Color cardTint;
}

/// Resolves [palette] (or the absence of one) against [colorScheme] into
/// concrete colors. Pulled out as a pure function, separate from the
/// widget that paints with it, so the blending itself — the part most
/// likely to go wrong across the app's 7 selectable base palettes and both
/// light/dark mode — is unit-testable without pumping a widget tree.
///
/// A palette's [UiThemePalette.accent] is a raw hue, not a contrast-checked
/// color: blending it into the scheme's own onSurface/outlineVariant lets
/// it tint toward light in dark mode and toward dark in light mode, instead
/// of risking a gold-on-white or navy-on-black legibility miss. With no
/// palette, every field is just the scheme's own existing color, so the
/// card looks exactly as it did before this feature existed.
ResolvedUiAccent resolveUiAccent(
    ColorScheme colorScheme, UiThemePalette? palette) {
  if (palette == null) {
    return ResolvedUiAccent(
      text: colorScheme.primary,
      border: colorScheme.outlineVariant,
      cardTint: colorScheme.surfaceContainerHighest,
    );
  }
  return ResolvedUiAccent(
    text: Color.lerp(colorScheme.onSurface, palette.accent, 0.7)!,
    border: Color.lerp(colorScheme.outlineVariant, palette.accent, 0.5)!,
    // Once painted at ~35% opacity as the card's tint; the stitched page
    // no longer paints it.
    cardTint:
        Color.lerp(colorScheme.surfaceContainerHighest, palette.accent, 0.16)!,
  );
}
