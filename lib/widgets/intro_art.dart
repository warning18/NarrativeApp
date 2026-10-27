// The art of the first-launch intro (v1.582, docs/proposals/intro-animation-d.md):
// Alster in ashes drawn in pixel art on a 70 x 124 grid (the burning skyline
// and its smoke, the broken tower and its bell, Tallow Street with its
// chalked doors, the harbor with its stone giant and the white ships), the
// fire that climbs the Great Shroud, the Inquisition's white ships, the back
// room of the Blind Beggar, and the old bone die. Each painter is still: the
// intro (screens/intro_screen.dart) redraws it as its clock moves.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'die_3d.dart';
import 'die_skins.dart';
import 'pixel_banner.dart';

const Color _ember = Color(0xFFE0702A);
const Color _gold = Color(0xFFE2B890);

const _cols = 70;
const _rows = 124;

class _Grid {
  _Grid(this.canvas, Size size) : u = size.width / _cols;
  final Canvas canvas;
  final double u;
  void px(num x, num y, num w, num h, Color c) => canvas.drawRect(
      Rect.fromLTWH(x * u, y * u, w * u, h * u),
      Paint()
        ..color = c
        ..isAntiAlias = false);
}

double _h(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The sky at dusk with a city burning under it: ember at the horizon,
/// ash grey and a dim bruised violet above.
void _sky(_Grid g, {double horizon = 70}) {
  const bands = [
    Color(0xFF2A2430),
    Color(0xFF3A2D3A),
    Color(0xFF4F3338),
    Color(0xFF6B3A2F),
    Color(0xFF8E4A2A),
    Color(0xFFB8602A),
  ];
  final per = horizon / bands.length;
  for (var i = 0; i < bands.length; i++) {
    g.px(0, i * per, _cols, per + 1, bands[i]);
  }
  // A dim red sun behind the smoke.
  g.px(46, horizon - 14, 8, 8, const Color(0xFFB8452A));
  g.px(47, horizon - 15, 6, 10, const Color(0xFFB8452A));
}

/// Columns of smoke leaning with the wind.
void _smoke(_Grid g, List<(double, double)> cols) {
  for (final (x, base) in cols) {
    for (var i = 0; i < 26; i++) {
      final w = 4 + i * 0.5;
      final cx = x + i * 0.55 + math.sin(i * 0.7) * 1.2;
      final a = (0.55 - i * 0.018).clamp(0.08, 0.55);
      g.px(cx - w / 2, base - i * 2.2, w, 2.4,
          const Color(0xFF2B2830).withValues(alpha: a));
    }
  }
}

/// A ruined skyline: jagged broken tops, empty window holes, a few embers
/// still lit in them.
void _skyline(_Grid g,
    {required double base,
    required Color fill,
    required int salt,
    double minH = 6,
    double maxH = 20,
    bool embers = false}) {
  var x = -2.0;
  var i = 0;
  while (x < _cols) {
    final w = 4 + _h(i, salt) * 6;
    final h = minH + _h(i, salt + 1) * (maxH - minH);
    g.px(x, base - h, w, h + 40, fill);
    // Broken top: a step or two missing.
    final cut = (_h(i, salt + 2) * 3).floor();
    if (cut > 0) {
      g.px(x + w - cut * 1.5, base - h, cut * 1.5, 2, _bgSky(g, base - h));
    }
    // Chimney stump.
    if (_h(i, salt + 3) > 0.6) g.px(x + 1, base - h - 2, 1.5, 2, fill);
    if (embers && _h(i, salt + 4) > 0.45) {
      g.px(x + w / 2, base - h * 0.55, 1.5, 1.5, _ember);
      if (_h(i, salt + 5) > 0.5) {
        g.px(x + 1, base - h * 0.3, 1, 1, const Color(0xFFF0B050));
      }
    }
    x += w - 0.5;
    i++;
  }
}

Color _bgSky(_Grid g, double y) => const Color(0xFF6B3A2F);

/// The Inquisition chapel's tower, broken at the top, the bell still hanging
/// in its arch, the roof beside it burnt to its rafters.
void _tower(_Grid g, {double x = 30, double base = 96}) {
  const stone = Color(0xFF2A262E);
  const lit = Color(0xFF3A353F);
  const dark = Color(0xFF17151B);
  g.px(x, base - 44, 14, 44, stone);
  g.px(x, base - 44, 3, 44, lit);
  // The break at the top.
  g.px(x + 10, base - 48, 4, 4, stone);
  g.px(x + 4, base - 46, 6, 2, stone);
  g.px(x + 1, base - 50, 3, 4, stone);
  // The arch and the bell in it.
  g.px(x + 4, base - 38, 6, 8, dark);
  g.px(x + 5, base - 40, 4, 2, dark);
  g.px(x + 6, base - 37, 2, 5, const Color(0xFFB9803A));
  g.px(x + 5, base - 33, 4, 2, const Color(0xFFB9803A));
  g.px(x + 6.5, base - 31, 1, 1.5, const Color(0xFF6B4520));
  // A crack and the soot above the arch.
  for (var i = 0; i < 9; i++) {
    g.px(x + 8 - (i % 3), base - 28 + i * 2, 1, 2, dark);
  }
  g.px(x + 3, base - 41, 8, 2, const Color(0xFF0F0D12));
  // The roof beside it: rafters against the glow.
  for (var i = 0; i < 6; i++) {
    g.px(x - 14 + i * 2.2, base - 22 + i * 1.2, 1, 12 - i, dark);
  }
  g.px(x - 16, base - 10, 16, 10, stone);
  g.px(x - 14, base - 8, 3, 4, dark);
  g.px(x - 9, base - 8, 3, 4, const Color(0xFFB8602A));
}

/// Tallow Street at the foot: ash-grey cobbles with drifts, doors chalked
/// white above the latch, a proclamation on the well-head, the razor wire in
/// the mouth of an alley, and the family house with its lamp.
void _street(_Grid g, {double kerb = 84}) {
  const wall = Color(0xFF3A3340);
  const wall2 = Color(0xFF453D4B);
  const dark = Color(0xFF111015);
  const chalk = Color(0xFFF4EEDC);
  // The houses, shuttered, burnt at the corners.
  for (var i = 0; i < 4; i++) {
    final x = -2.0 + i * 19;
    final top = kerb - 34 + (i.isEven ? 0 : 4);
    g.px(x, top, 17, kerb - top, i.isEven ? wall : wall2);
    // Roof, with a hole.
    g.px(x - 1, top - 3, 19, 3, dark);
    if (i != 2) g.px(x + 5, top - 3, 5, 3, const Color(0xFF8E4A2A));
    // Windows: dark, one lit by a lantern inside.
    g.px(x + 3, top + 6, 3, 5, dark);
    g.px(x + 11, top + 6, 3, 5, i == 2 ? const Color(0xFFF2C070) : dark);
    // The door, and the white chalk above the latch.
    g.px(x + 7, kerb - 13, 4, 13, dark);
    g.px(x + 6.5, kerb - 17, 5, 1.6, chalk);
    g.px(x + 8.2, kerb - 19, 1.6, 5, chalk);
    // The glow of the fires on the roof's edge.
    g.px(x - 1, top - 3, 19, 0.8, const Color(0xFFB8602A));
  }
  // The cobbles and the ash drifts.
  g.px(0, kerb, _cols, _rows - kerb, const Color(0xFF2E2A33));
  for (var r = 0; r < 14; r++) {
    for (var c = 0; c < _cols; c += 4) {
      final o = (r.isEven ? 0 : 2);
      g.px(
          c + o,
          kerb + 1 + r * 2.6,
          3,
          1.6,
          _h(c + r * 7, 3) > 0.5
              ? const Color(0xFF38343E)
              : const Color(0xFF282430));
    }
  }
  for (var i = 0; i < 9; i++) {
    final x = _h(i, 11) * 62;
    g.px(x, kerb + 2 + _h(i, 12) * 28, 7 + _h(i, 13) * 6, 1.6,
        const Color(0xFF6A646E));
  }
  // The razor wire across an alley mouth, low.
  for (var i = 0; i < 16; i++) {
    g.px(2 + i * 1.1, kerb + 6 + math.sin(i * 1.3) * 0.9, 1, 1,
        const Color(0xFFB8B2BC));
  }
  // The well-head with its proclamation, the paper nailed to it.
  g.px(46, kerb + 3, 12, 8, const Color(0xFF3A353F));
  g.px(47, kerb + 1, 10, 3, const Color(0xFF2A262E));
  g.px(49, kerb + 4, 6, 5, const Color(0xFFE8DDC0));
  for (var i = 0; i < 3; i++) {
    g.px(50, kerb + 5 + i * 1.4, 4, 0.6, const Color(0xFF3A2A1E));
  }
  // A lamp post with its flame.
  g.px(61, kerb - 18, 1, 22, dark);
  g.px(59.5, kerb - 21, 4, 3, const Color(0xFF3A353F));
  g.px(60.6, kerb - 20, 1.8, 2, const Color(0xFFF2C070));
}

/// Two Inquisitors with a lantern, small and dark, going in at a door.
void _inquisitors(_Grid g, double x, double y) {
  const dark = Color(0xFF0A090D);
  for (final dx in const [0.0, 5.0]) {
    g.px(x + dx, y - 12, 3.4, 9, dark);
    g.px(x + dx - 0.6, y - 15, 4.6, 3, dark);
    g.px(x + dx + 0.6, y - 17, 2.2, 2, dark);
    g.px(x + dx, y - 3, 3.4, 3, dark);
  }
  g.px(x + 9, y - 9, 1.2, 4, dark);
  g.px(x + 8.4, y - 6, 2.6, 2.6, const Color(0xFFF2C070));
  g.px(x + 7.4, y - 7, 4.6, 5, const Color(0x33F2C070));
}

/// The harbor: black water that takes the fires' red, the stone giant
/// kneeling in it, the white ships beyond.
void _harbor(_Grid g, {double horizon = 66}) {
  g.px(0, horizon, _cols, _rows - horizon, const Color(0xFF16141A));
  for (var r = 0; r < 20; r++) {
    for (var i = 0; i < 6; i++) {
      final x = _h(r * 9 + i, 21) * 66;
      g.px(
          x,
          horizon + 2 + r * 2.6,
          3 + _h(i + r, 22) * 6,
          0.9,
          Color.lerp(const Color(0xFF3A1F22), const Color(0xFF8E4A2A),
              (1 - r / 20) * 0.9)!);
    }
  }
  // The giant: a vast shoulder and a head against the glow, half in the
  // water, the stone worn and a little green.
  const stone = Color(0xFF2B292F);
  const stone2 = Color(0xFF3A383F);
  g.px(8, horizon - 22, 30, 24, stone);
  g.px(12, horizon - 30, 18, 10, stone);
  g.px(16, horizon - 38, 10, 10, stone);
  g.px(17, horizon - 37, 3, 8, stone2);
  g.px(19, horizon - 32, 2, 1.4, const Color(0xFF16141A));
  g.px(23, horizon - 32, 2, 1.4, const Color(0xFF16141A));
  g.px(30, horizon - 26, 10, 4, stone);
  g.px(8, horizon - 10, 4, 12, stone2);
  // The white ships, far off, sails like teeth.
  for (var i = 0; i < 4; i++) {
    final x = 36 + i * 8 + (i.isOdd ? 2 : 0);
    final y = horizon - 4 + (i.isOdd ? 2 : 0);
    g.px(x, y - 9, 0.8, 9, const Color(0xFF8A8590));
    for (var k = 0; k < 7; k++) {
      g.px(x + 0.8, y - 9 + k, 1 + k * 0.45, 1, const Color(0xFFEDE6DC));
    }
    g.px(x - 2, y, 7, 1.4, const Color(0xFFD8D0C4));
  }
  // Burnt pier posts with a flame on one.
  for (var i = 0; i < 5; i++) {
    g.px(2 + i * 4, horizon + 14, 1.2, 8, const Color(0xFF0E0D12));
  }
  g.px(14.2, horizon + 12, 1.4, 2, _ember);
  g.px(14.6, horizon + 11, 0.8, 1.4, const Color(0xFFF0B050));
}

class IntroCity extends CustomPainter {
  const IntroCity(this.scene);
  final String scene;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    switch (scene) {
      case 'smoke':
        _sky(g);
        _smoke(g, const [(12, 76), (34, 74), (54, 76)]);
        _skyline(g,
            base: 80,
            fill: const Color(0xFF3A3040),
            salt: 1,
            minH: 4,
            maxH: 11);
        _skyline(g,
            base: 92,
            fill: const Color(0xFF26212B),
            salt: 5,
            minH: 8,
            maxH: 22,
            embers: true);
        g.px(0, 92, _cols, 40, const Color(0xFF121014));
      case 'tower':
        _sky(g);
        _smoke(g, const [(60, 80)]);
        _skyline(g,
            base: 84,
            fill: const Color(0xFF2C2530),
            salt: 3,
            minH: 5,
            maxH: 14);
        _tower(g);
        g.px(0, 96, _cols, 40, const Color(0xFF16141A));
        _skyline(g,
            base: 110,
            fill: const Color(0xFF0F0E12),
            salt: 9,
            minH: 6,
            maxH: 14,
            embers: true);
      case 'street':
        _sky(g, horizon: 50);
        _street(g);
        _inquisitors(g, 20, 96);
        _inquisitors(g, 40, 104);
      case 'harbor':
        _sky(g, horizon: 66);
        _smoke(g, const [(8, 66), (60, 66)]);
        _harbor(g);
    }
  }

  @override
  bool shouldRepaint(IntroCity old) => old.scene != scene;
}

/// Ash coming down: small grey flakes and a few embers, still.
class IntroAsh extends CustomPainter {
  const IntroAsh(this.salt);
  final int salt;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    for (var i = 0; i < 70; i++) {
      final ember = _h(i, salt + 40) > 0.93;
      g.px(
          _h(i, salt) * _cols,
          _h(i, salt + 1) * _rows,
          ember ? 1 : 0.9,
          ember ? 1 : 0.9,
          ember
              ? const Color(0xFFF0B050)
              : const Color(0xFFB8B2BC)
                  .withValues(alpha: 0.35 + _h(i, 3) * 0.4));
    }
  }

  @override
  bool shouldRepaint(IntroAsh old) => false;
}

// ---------------------------------------------------------------------------
// New for this storyboard: fire, the white ships, the tavern floor.
// ---------------------------------------------------------------------------

/// Flames climbing from the foot of a banner (the bottom of the grid, between
/// columns [from] and [to]) up to [level] (0..1 of the grid's height).
class IntroFire extends CustomPainter {
  const IntroFire(this.level, {this.flicker = 3});
  final double level;

  /// The flames' shape (changed every few frames, the fire flickers).
  final int flicker;
  static const double from = 6;
  static const double to = 64;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    final base = _rows - 6.0;
    final top = _rows * (1 - level);
    for (var x = from; x < to; x += 1) {
      final i = x.floor();
      final tongue = (base - top) * (0.55 + 0.45 * _h(i, flicker));
      final y0 = base - tongue;
      // From the dark red root to the yellow tip.
      final steps = (tongue / 2.2).ceil();
      for (var k = 0; k < steps; k++) {
        final t = k / steps;
        final c = Color.lerp(
            const Color(0xFF7A1E14), const Color(0xFFF6C050), 1 - t * 1.0)!;
        g.px(x, base - k * 2.2 - 2.2, 1.2, 2.2, c);
      }
      g.px(x, y0 - 1.5, 1.2, 1.5, const Color(0xFFFFE9A0));
    }
    // Sparks.
    for (var i = 0; i < 26; i++) {
      g.px(from + _h(i, flicker + 9) * (to - from),
          top - _h(i, flicker + 10) * 30, 1, 1, const Color(0xFFF0B050));
    }
  }

  @override
  bool shouldRepaint(IntroFire old) =>
      old.level != level || old.flicker != flicker;
}

/// The Inquisition's white sky ships, low over the roofs, their painted
/// sails burning like lamps.
class IntroSkyShips extends CustomPainter {
  const IntroSkyShips({required this.ships});
  final List<(double, double, double)> ships;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    for (final (x, y, s) in ships) {
      // Hull.
      g.px(x, y + 7 * s, 16 * s, 3 * s, const Color(0xFFD8D0C4));
      g.px(x + 1 * s, y + 10 * s, 14 * s, 1.5 * s, const Color(0xFF8A8590));
      g.px(x + 7 * s, y - 9 * s, 0.8 * s, 16 * s, const Color(0xFF8A8590));
      // Sails with signs that burn like lamps.
      for (var k = 0; k < 9; k++) {
        g.px(x + 8 * s, y - 8 * s + k * 1.4 * s, (1 + k * 0.6) * s, 1.4 * s,
            const Color(0xFFEDE6DC));
        g.px(x + 7 * s - k * 0.4 * s, y - 6 * s + k * 1.3 * s,
            (1 + k * 0.4) * s, 1.3 * s, const Color(0xFFD8D0C4));
      }
      for (var k = 0; k < 4; k++) {
        g.px(x + (9 + k) * s, y - (2 - k * 1.1) * s, 2 * s, 1.6 * s, _ember);
        g.px(x + (9 + k) * s, y - (2 - k * 1.1) * s, 1 * s, 0.9 * s,
            const Color(0xFFFFE9A0));
      }
      g.px(x - 1 * s, y - 2 * s, 20 * s, 14 * s, const Color(0x22F0B050));
    }
  }

  @override
  bool shouldRepaint(IntroSkyShips old) => old.ships != ships;
}

/// The Blind Beggar's back room from above: planks, a pool of lamplight,
/// the corner of a table and the cage for the house's money.
class IntroFloor extends CustomPainter {
  const IntroFloor({this.flash = false});
  final bool flash;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    g.px(0, 0, _cols, _rows, const Color(0xFF241A14));
    for (var x = 0; x < _cols; x += 9) {
      g.px(x + 0.5, 0, 8, _rows,
          _h(x, 5) > 0.5 ? const Color(0xFF2E2118) : const Color(0xFF2A1E16));
    }
    for (var y = 12; y < _rows; y += 21) {
      g.px(0, y, _cols, 0.6, const Color(0xFF16100C));
    }
    // The tables' edges and the cage.
    g.px(0, 0, 14, 28, const Color(0xFF3A2A1E));
    g.px(56, 8, 14, 30, const Color(0xFF3A2A1E));
    for (var i = 0; i < 6; i++) {
      g.px(58 + i * 2, 12, 0.7, 22, const Color(0xFF7A6A50));
    }
    g.px(57, 12, 12, 0.8, const Color(0xFF7A6A50));
    g.px(57, 33, 12, 0.8, const Color(0xFF7A6A50));
    // A mug and a candle on the table.
    g.px(4, 8, 3, 4, const Color(0xFF8A7A60));
    g.px(9, 14, 1, 3, const Color(0xFFEDE3C8));
    g.px(9, 12.5, 1, 1.5, const Color(0xFFF6C050));
    // The pool of lamplight and the dark round it.
    final c = Offset(size.width / 2, size.height * 0.55);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(c, size.width * 0.95,
              [const Color(0x00000000), const Color(0xEE000000)], [0.25, 1]));
    canvas.drawCircle(
        c,
        size.width * 0.55,
        Paint()
          ..shader = ui.Gradient.radial(c, size.width * 0.55,
              [const Color(0x44F2B860), const Color(0x00F2B860)]));
    if (flash) {
      // The first shell lands outside: its light through the window.
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = ui.Gradient.linear(
                Offset.zero,
                Offset(0, size.height * 0.5),
                [const Color(0x99FFC070), const Color(0x00FFC070)]));
    }
  }

  @override
  bool shouldRepaint(IntroFloor old) => old.flash != flash;
}

/// A die, the old bone one: [roll] is how far through a tumble it is (null
/// at rest), the front face showing [face].
Widget introDie(double size, {double? roll, int face = 6}) => Die3D(
      faces: [
        for (var i = 0; i < 6; i++)
          DieCubeFace(
              glyph: Text('${i == 0 ? face : (face % 6) + 1 + i % 5}',
                  style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A2A1E))),
              color: const Color(0xFFE8DDC0)),
      ],
      accent: _gold,
      size: size,
      skin: boneSkin,
      roll: roll == null ? null : AlwaysStoppedAnimation(roll),
      rolling: roll != null,
      still: roll == null,
    );

/// A piece of the Shroud as an ember: dim cloth lit at its edge, with a glow.
class IntroEmber extends StatelessWidget {
  const IntroEmber(
      {super.key, required this.id, required this.height, this.tilt = 0});

  final String id;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt,
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                color: _ember.withValues(alpha: 0.75),
                blurRadius: 10,
                spreadRadius: 1),
          ]),
          child: SizedBox(
            width: height / 2,
            height: height,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.9, 0.2, 0.0, 0, 30, //
                0.1, 0.55, 0.0, 0, 6,
                0.05, 0.05, 0.3, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: FittedBox(child: PixelBanner(id: id, scale: 1)),
            ),
          ),
        ),
      );
}
