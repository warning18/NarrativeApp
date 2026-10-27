// The first-launch intro, the user's own idea (a proposal, nothing of it is in
// the app; "version D" here because C is the text-led one, #537): the Great
// Shroud burning and vanishing over the ashen city, a zoom down through the
// smoke to the Blind Beggar, a die falling from the top of the frame, bouncing
// on the floor and rolling to the middle, turning slower and slower and
// stopping on a six, the title over it, then a slow fade to the choice of race
// and profession. Lore as Narrative has it: the Shroud was cut into six pieces
// long ago, so the burning is a vision of before and it leaves six embers, one
// falling toward Alster; the first shell lands only as the die stops. The city
// is the pixel painters of C; the banner, the six pieces, the die, the title
// and the tavern's front are the game's own widgets. With UX_SHOTS (a folder)
// set it saves intro-storyboard-d.png; UX_LAST is the picture of the real Race
// & Profession screen (see ux_intro_mock_test.dart).
//   UX_SHOTS=docs/ux-shots UX_LAST=<png> flutter test test/ux_intro_d_mock_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

const _bg = Color(0xFF0B0A0D);
const _cream = Color(0xFFEDE3C8);
const _ash = Color(0xFF9A93A6);
const _gold = Color(0xFFE2B890);
const _ember = Color(0xFFE0702A);
const _frameW = 210.0;
const _frameH = 373.0;

TextStyle _px(double size, {Color color = _cream, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);
TextStyle _serif(double size,
        {Color color = _cream, FontStyle style = FontStyle.normal}) =>
    TextStyle(
        fontFamily: 'Spectral', fontSize: size, color: color, fontStyle: style);

// ---------------------------------------------------------------------------
// The city in ashes (the painters of the text-led storyboard, C).
// ---------------------------------------------------------------------------

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

class _City extends CustomPainter {
  const _City(this.scene);
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
  bool shouldRepaint(_City old) => old.scene != scene;
}

/// Ash coming down: small grey flakes and a few embers, still.
class _Ash extends CustomPainter {
  const _Ash(this.salt);
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
  bool shouldRepaint(_Ash old) => false;
}

// ---------------------------------------------------------------------------
// New for this storyboard: fire, the white ships, the tavern floor.
// ---------------------------------------------------------------------------

/// Flames climbing from the foot of a banner (the bottom of the grid, between
/// columns [from] and [to]) up to [level] (0..1 of the grid's height).
class _Fire extends CustomPainter {
  const _Fire(this.level);
  final double level;
  static const double from = 6;
  static const double to = 64;
  static const int salt = 3;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    final base = _rows - 6.0;
    final top = _rows * (1 - level);
    for (var x = from; x < to; x += 1) {
      final i = x.floor();
      final tongue = (base - top) * (0.55 + 0.45 * _h(i, salt));
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
      g.px(from + _h(i, salt + 9) * (to - from), top - _h(i, salt + 10) * 30, 1,
          1, const Color(0xFFF0B050));
    }
  }

  @override
  bool shouldRepaint(_Fire old) => old.level != level;
}

/// The Inquisition's white sky ships, low over the roofs, their painted
/// sails burning like lamps.
class _SkyShips extends CustomPainter {
  const _SkyShips({required this.ships});
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
  bool shouldRepaint(_SkyShips old) => old.ships != ships;
}

/// The Blind Beggar's back room from above: planks, a pool of lamplight,
/// the corner of a table and the cage for the house's money.
class _Floor extends CustomPainter {
  const _Floor({this.flash = false});
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
  bool shouldRepaint(_Floor old) => old.flash != flash;
}

/// A die, the old bone one: [roll] is how far through a tumble it is (null
/// at rest), the front face showing [face].
Widget _die(double size, {double? roll, int face = 6}) => Die3D(
      faces: [
        for (var i = 0; i < 6; i++)
          DieCubeFace(
              glyph: Text('${i == 0 ? face : (face % 6) + 1 + i % 5}',
                  style: _px(size * 0.45,
                      color: const Color(0xFF3A2A1E), w: FontWeight.w600)),
              color: const Color(0xFFE8DDC0)),
      ],
      accent: _gold,
      size: size,
      skin: boneSkin,
      roll: roll == null ? null : AlwaysStoppedAnimation(roll),
      rolling: roll != null,
      still: roll == null,
    );

Widget _scene(String scene, int salt, [List<Widget> over = const []]) =>
    Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _City(scene)),
      ...over,
      CustomPaint(painter: _Ash(salt)),
    ]);

// ---------------------------------------------------------------------------
// The frames and the board.
// ---------------------------------------------------------------------------

/// Narrative's set A (Grim), English, unchanged.
const _lines = {
  1: 'Alster at dusk. The ash had already begun to fall.',
  2: 'The bell rang for the Inquisition. Nobody on Tallow Street looked up.',
  3: 'Every clan wanted the city. None of them wanted you in it.',
  4: 'Tonight it burns. First, decide who you are.',
};

class _LineSlot extends StatelessWidget {
  const _LineSlot(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xDD000000)])),
          child: Text(text,
              textAlign: TextAlign.center,
              style: _serif(13.5, style: FontStyle.italic)),
        ),
      );
}

class _Beat {
  const _Beat(this.time, this.title, this.how, this.move, this.scene,
      {this.line, this.isNew = ''});
  final String time;
  final String title;
  final String how;
  final String move;
  final Widget scene;
  final int? line;
  final String isNew;
}

Widget _frame(int n, _Beat b) => SizedBox(
      width: _frameW,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: _frameW,
          height: _frameH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: Colors.black, child: b.scene),
              if (b.line != null) _LineSlot(_lines[b.line!]!),
              Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: const Color(0xCC000000),
                    child: Text('$n', style: _px(13, color: _gold)),
                  )),
              if (b.move.isNotEmpty)
                Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: const Color(0xCC000000),
                      child: Text(b.move, style: _px(11, color: _gold)),
                    )),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(b.time, style: _px(13, color: _gold, w: FontWeight.w600)),
        Text(b.title, style: _serif(12.5)),
        const SizedBox(height: 2),
        Text(b.how, style: _serif(10.5, color: _ash)),
        if (b.isNew.isNotEmpty)
          Text('new: ${b.isNew}',
              style: _px(10.5, color: const Color(0xFFE08A6A))),
      ]),
    );

Widget _title() => Column(mainAxisSize: MainAxisSize.min, children: [
      Text('The Grey Shroud',
          textAlign: TextAlign.center, style: _px(27, w: FontWeight.w600)),
      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
              'A tale of dice, debts and a shroud that should not exist',
              textAlign: TextAlign.center,
              style: _serif(12, color: _ash, style: FontStyle.italic))),
    ]);

/// A piece of the Shroud as an ember: dim cloth, lit at its edge, a glow.
Widget _emberPiece(String id, double h, {double tilt = 0}) => Transform.rotate(
      angle: tilt,
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: _ember.withValues(alpha: 0.75),
              blurRadius: 10,
              spreadRadius: 1),
        ]),
        child: SizedBox(
          width: h / 2,
          height: h,
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

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final last = Platform.environment['UX_LAST'];
  if (shots == null) {
    test('intro storyboard D is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('storyboard D', (tester) async {
    await tester.runAsync(_loadFonts);
    ui.Image? lastImage;
    if (last != null && File(last).existsSync()) {
      lastImage = await tester.runAsync(() async {
        final codec =
            await ui.instantiateImageCodec(File(last).readAsBytesSync());
        return (await codec.getNextFrame()).image;
      });
    }

    final beats = <_Beat>[
      _Beat(
          '0.0 – 2.5 s',
          'The Great Shroud, burning',
          'The grey banner fills the frame over the ash-sky city; fire climbs it from the foot. Line 1 writes itself.',
          'zoom out',
          Stack(fit: StackFit.expand, children: [
            _scene('smoke', 1),
            const ColoredBox(color: Color(0xB3000000)),
            Align(
                alignment: const Alignment(0, -0.1),
                child: SizedBox(
                    height: 300,
                    child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.7, 0.05, 0.02, 0, 0, //
                          0.05, 0.55, 0.02, 0, 0,
                          0.04, 0.04, 0.5, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                        child: FittedBox(
                            child: PixelBanner(id: titleBannerId, scale: 1))))),
            const CustomPaint(painter: _Fire(0.55)),
            CustomPaint(painter: _Ash(11)),
          ]),
          line: 1,
          isNew: 'the fire (one painter)'),
      _Beat(
          '2.5 – 4.5 s',
          'It burns away: six embers',
          'The cloth comes apart into six embers the wind lifts; one falls toward Alster. The city behind it comes up, ash and smoke. It was cut into six long ago: the burning is a vision of before.',
          'pan down',
          _scene('smoke', 7, [
            for (final (i, p) in const [
              (0, Offset(34, 40)),
              (1, Offset(98, 28)),
              (2, Offset(150, 64)),
              (3, Offset(62, 98)),
              (4, Offset(128, 112)),
            ])
              Positioned(
                  left: p.dx,
                  top: p.dy,
                  child:
                      _emberPiece(shroudPieceIds[i], 30, tilt: (i - 2) * 0.35)),
            // The sixth, falling toward the roofs, with its trail.
            for (var k = 0; k < 7; k++)
              Positioned(
                  left: 88 + k * 3.0,
                  top: 168 + k * 15.0,
                  child: Container(
                      width: 3,
                      height: 3,
                      color: _ember.withValues(alpha: 0.9 - k * 0.12))),
            Positioned(
                left: 104,
                top: 266,
                child: _emberPiece(shroudPieceIds[5], 34, tilt: 0.5)),
          ])),
      _Beat(
          '4.5 – 6.5 s',
          'The city on alert',
          'Calm streets, chalked doors, Inquisitors with lanterns, the bell; the white ships still far off. No shell yet. Line 2.',
          'push in',
          _scene('street', 19, [
            const CustomPaint(
                painter: _SkyShips(ships: [(4, 18, 0.55), (44, 10, 0.4)])),
          ]),
          line: 2),
      _Beat(
          '6.5 – 8.5 s',
          'Down through the smoke to the Blind Beggar',
          'The camera pushes down to the tavern on Tallow Street: the lamp in its window, the chalk on its door. Line 3 begins.',
          'push in',
          Stack(fit: StackFit.expand, children: [
            ClipRect(
                child: Transform.scale(
                    scale: 1.7,
                    alignment: const Alignment(-0.1, 0.35),
                    child: const StreetViewScene(
                        kind: 'tavern',
                        name: 'The Blind Beggar',
                        phase: DayPhase.dusk,
                        sky: WeatherKind.ash,
                        party: false))),
            Align(
                alignment: Alignment.topCenter,
                child: Container(
                    height: 140,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xEE2B2830), Color(0x002B2830)])))),
            CustomPaint(painter: _Ash(23)),
          ]),
          line: 3),
      _Beat(
          '8.5 – 10.5 s',
          'The die falls',
          'Inside: the old bone die drops from the top of the frame, bounces once on the floor and rolls toward the middle (its ghosts show the path).',
          'hold',
          Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _Floor()),
            Align(
                alignment: const Alignment(-0.15, -0.85),
                child: Opacity(opacity: 0.35, child: _die(46, roll: 0.15))),
            Align(
                alignment: const Alignment(0.0, -0.1),
                child: Opacity(opacity: 0.45, child: _die(52, roll: 0.35))),
            Align(
                alignment: const Alignment(0.2, 0.2),
                child: Opacity(opacity: 0.6, child: _die(60, roll: 0.55))),
            Align(
                alignment: const Alignment(0.1, 0.35),
                child: _die(66, roll: 0.72)),
          ]),
          isNew:
              'the interior floor (one painter) and the bounce (a path and an ease)'),
      _Beat(
          '10.5 – 12.0 s',
          'It turns, slower, and stops on a six',
          'The tumble eases out (the die’s own roll); it comes to rest, a six face up. As it stops the first shell lands outside and its light crosses the room.',
          'hold',
          Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _Floor(flash: true)),
            Align(
                alignment: const Alignment(0, 0.05),
                child: _die(86, roll: 0.97)),
          ])),
      _Beat(
          '12.0 – 13.5 s',
          'The title over the die',
          'The title rises over the resting die and holds a beat. This is the still frame with reduced motion.',
          'hold',
          Stack(fit: StackFit.expand, children: [
            const CustomPaint(painter: _Floor()),
            Align(alignment: const Alignment(0, 0.35), child: _die(86)),
            Align(alignment: const Alignment(0, -0.62), child: _title()),
          ])),
      _Beat(
          '13.5 – 15.0 s',
          'Fade to the choice',
          'The room fades slowly into the real Race & Profession screen. Line 4 comes in after the title, as it fades.',
          'fade',
          lastImage == null
              ? const ColoredBox(color: Color(0xFFF3EAD7))
              : RawImage(
                  image: lastImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter),
          line: 4),
    ];

    const spans = [2.5, 2.0, 2.0, 2.0, 2.0, 1.5, 1.5, 1.5];
    final total = spans.fold<double>(0, (a, b) => a + b);
    const boardW = 4 * (_frameW + 16) + 16;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 1560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget chip(String t, {Color c = _cream}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(t, style: _serif(12, color: c)));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            color: _bg,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Intro · version D: the burning Shroud, the die, the title (${total.toStringAsFixed(0)} s)',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'The user’s own idea. The Great Shroud burns and vanishes over the ashen city, the camera pushes down to the Blind Beggar, the old bone die falls, bounces, rolls to the middle, slows and stops on a six, the title rises over it, and the room fades into the choice of race and profession. The four set A lines are unchanged and in the same order (1, 2, 3, 4). Plays once, a tap skips, reduced motion shows frame 7, replayable from Settings.',
                  style: _serif(12.5, color: _ash)),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 14, children: [
                for (var i = 0; i < beats.length; i++) _frame(i + 1, beats[i]),
              ]),
              const SizedBox(height: 12),
              Text('Timing', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Row(children: [
                  for (var i = 0; i < spans.length; i++)
                    Expanded(
                      flex: (spans[i] * 10).round(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        color: Color.lerp(
                            const Color(0xFF3A3642), _gold, i / spans.length),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: _px(13, color: Colors.black)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                  '0 s · ${total.toStringAsFixed(0)} s — lines at 0.3, 4.8, 6.8 and 13.8 s; optional sounds: a low bell on frame 3, the die’s clatter on frame 5, a distant boom on frame 6.',
                  style: _serif(11.5, color: _ash)),
              const SizedBox(height: 16),
              Text('What it is made of', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              chip(
                  'Reused as it is: the grey banner and the six pieces of the Shroud as the character screen draws them (1, 2), the street-view kit at dusk with ash for the Blind Beggar’s front (4), the bone die (5, 6, 7, 8: Die3D with its skin, tumbling and at rest), the title’s words (7), the story’s typewriter for the lines, the real Race & Profession screen (8), the reduced-motion check.'),
              chip(
                  'New: the fire (1), the six embers and the one falling (2), the white ships far off (3) and the shell\u2019s flash across the room (6): one painter each, the city in ashes (1 to 3: the four small painters of C), the tavern’s floor (5 to 7: one painter), the bounce and the slow-down (a path and an ease on the die, 5 and 6), the zoom between frames, one intro screen with tap-to-skip, a “seen” flag and a Replay row in Settings.',
                  c: const Color(0xFFE08A6A)),
              chip(
                  'Cost: about two days, one PR of about 750 lines and a test: dearer than A (a day) and B (a day and a half) because of the fire, the ships and the die’s path; the die and the title are the cheap, strong part, and a short version (frames 5 to 8 only: the die, the title, the fade, with lines 3 and 4) is about half a day.',
                  c: _ash),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/intro-storyboard-d.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(math.max(1, total), greaterThan(0));
  });
}
