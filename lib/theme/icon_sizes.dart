// The icon sizes of the game (v1.905): one scale, in logical pixels, so the
// pixel icons (16 art pixels across) land on whole multiples (1x, 2x, 3x,
// 4x) and never smear, and the Material glyphs beside them match.
//
//   inline  12  a tiny mark inside a tag or a badge (Material glyphs only)
//   s16     16  the strip, chips, list rows, small marks
//   s32     32  the nav bar, slots, nodes, headers, item and skill icons
//   s48     48  big marks (3x)
//   s64     64  the largest icon art (4x)
//
// No 14, 18, 20, 22, 26, 28 and so on: ask for one of these.
abstract final class IconSize {
  static const double inline = 12;
  static const double s16 = 16;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  /// The scale's size nearest to [v] (used where a size comes from a
  /// computation, and by the guard test that no literal is off the scale).
  static double snap(double v) {
    if (v <= 12) return inline;
    if (v < 22) return s16;
    if (v < 40) return s32;
    if (v < 56) return s48;
    return (v / 16).round() * 16.0;
  }
}
