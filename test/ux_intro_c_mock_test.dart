// The first-launch intro, version C (a proposal, nothing of it is in the app):
// text first. One slow pan across Alster in ashes, with the story's own text
// written over it a line at a time, and far more of the city shown than the
// postcards of A and B: the chalked doors of Tallow Street, the proclamation
// on the well-head, the razor wire in the alley, the Inquisitors going in and
// out of the houses in pairs with lanterns, the bell, the scorched banners,
// the harbor with its stone giant and the white ships. The city is drawn in
// pixel art by a few painters (new); the clans' flags, the Shroud's six pieces
// and the title are the game's own widgets. With UX_SHOTS (a folder) set it
// saves intro-storyboard-c.png; UX_LAST is the picture of the real Race &
// Profession screen (see ux_intro_mock_test.dart).
//   UX_SHOTS=docs/ux-shots UX_LAST=<png> flutter test test/ux_intro_c_mock_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/pixel_banner.dart';

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
// The city in ashes: pixel painters on a 70 x 124 grid (3 logical px a cell).
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

/// A scorched banner: the game's own, darkened and sooted.
Widget _scorched(String id, double h) => SizedBox(
      width: h / 2,
      height: h,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.55, 0.05, 0.02, 0, 0, //
          0.05, 0.42, 0.02, 0, 0,
          0.04, 0.04, 0.38, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: FittedBox(child: PixelBanner(id: id, scale: 1)),
      ),
    );

// ---------------------------------------------------------------------------
// The text, the frames, the board.
// ---------------------------------------------------------------------------

/// Narrative's set A (Grim), English, as chosen; the other three are slots.
const _known = {
  1: 'Alster at dusk. The ash had already begun to fall.',
  2: 'The bell rang for the Inquisition. Nobody on Tallow Street looked up.',
  3: 'Every clan wanted the city. None of them wanted you in it.',
  4: 'Tonight it burns. First, decide who you are.',
};

class _Text extends StatelessWidget {
  const _Text({this.text, this.slot, this.big = false, this.top = false});
  final String? text;
  final String? slot;
  final bool big;
  final bool top;
  @override
  Widget build(BuildContext context) => Align(
        alignment: big
            ? Alignment.center
            : top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: big
              ? const EdgeInsets.symmetric(horizontal: 14)
              : EdgeInsets.zero,
          padding: EdgeInsets.fromLTRB(
              10, big ? 14 : (top ? 36 : 30), 10, big ? 14 : (top ? 8 : 16)),
          decoration: big
              ? BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(4))
              : const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xEE000000)])),
          child: text != null
              ? Text(text!,
                  textAlign: TextAlign.center,
                  style: _serif(big ? 15 : 13.5, style: FontStyle.italic))
              : Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      border: Border.all(color: _gold.withValues(alpha: 0.7))),
                  child: Text(slot!,
                      textAlign: TextAlign.center,
                      style:
                          _serif(11.5, color: _gold, style: FontStyle.italic)),
                ),
        ),
      );
}

class _Beat {
  const _Beat(this.time, this.title, this.how, this.scene, this.text,
      {this.short = false});
  final String time;
  final String title;
  final String how;
  final Widget scene;
  final Widget text;

  /// Part of the 15-second cut (lines 1 to 4 only).
  final bool short;
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
              b.text,
              Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: const Color(0xCC000000),
                    child: Text('$n', style: _px(13, color: _gold)),
                  )),
              if (b.short)
                Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: const Color(0xCC000000),
                      child: Text('15 s cut', style: _px(10.5, color: _gold)),
                    )),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(b.time, style: _px(13, color: _gold, w: FontWeight.w600)),
        Text(b.title, style: _serif(12.5)),
        const SizedBox(height: 2),
        Text(b.how, style: _serif(10.5, color: _ash)),
      ]),
    );

Widget _scene(String scene, int salt, [List<Widget> over = const []]) =>
    Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _City(scene)),
      ...over,
      CustomPaint(painter: _Ash(salt)),
    ]);

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final last = Platform.environment['UX_LAST'];
  if (shots == null) {
    test('intro storyboard C is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('storyboard C', (tester) async {
    await tester.runAsync(_loadFonts);
    ui.Image? lastImage;
    if (last != null && File(last).existsSync()) {
      lastImage = await tester.runAsync(() async {
        final codec =
            await ui.instantiateImageCodec(File(last).readAsBytesSync());
        return (await codec.getNextFrame()).image;
      });
    }

    const slotA =
        'LINE A · Narrative · about 20 words\nTallow Street the night it was made to kneel: every door chalked white, the houses emptied, the Inquisitors going in and out in pairs with lanterns.';
    const slotB =
        'LINE B · Narrative · about 20 words\nThe Inquisition’s edict on the well-head, the ink still wet; its banners hung over the square.';
    const slotC =
        'LINE C · Narrative · about 20 words\nThe harbor: the stone giant kneeling in the black water, and the white ships coming in.';

    final beats = <_Beat>[
      _Beat(
          '0.0 – 4.0 s',
          'Black, the line, the first slide',
          'Line 1 writes itself in white on black; the burning sky fades up behind it and the camera starts to slide right over the skyline: smoke, roofs with no rafters, embers in the windows.',
          Stack(fit: StackFit.expand, children: [
            _scene('smoke', 1),
            const ColoredBox(color: Color(0x99000000)),
          ]),
          const _Text(
              text: 'Alster at dusk. The ash had already begun to fall.',
              big: true),
          short: true),
      _Beat(
          '4.0 – 7.5 s',
          'The bell',
          'The broken tower, the bell still hanging in its arch, the roof beside it burnt to its rafters. Line 2.',
          _scene('tower', 12),
          const _Text(
              text:
                  'The bell rang for the Inquisition. Nobody on Tallow Street looked up.'),
          short: true),
      _Beat(
          '7.5 – 11.0 s',
          'Tallow Street',
          'Down to the street: doors chalked white, the razor wire in an alley, the proclamation on the well-head, Inquisitors going in with lanterns.',
          _scene('street', 19),
          const _Text(slot: slotA, top: true)),
      _Beat(
          '11.0 – 14.5 s',
          'The edict and the banners',
          'The proclamation close up, and the Inquisition’s banners scorched on their poles over the square.',
          _scene('street', 25, [
            Align(
                alignment: const Alignment(0, -0.55),
                child: FittedBox(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _scorched('clan_dominion', 80)),
                    ]))),
          ]),
          const _Text(slot: slotB)),
      _Beat(
          '14.5 – 18.0 s',
          'The harbor',
          'The stone giant kneeling in the black water that takes the fires’ red; the white ships coming in beyond it.',
          _scene('harbor', 31),
          const _Text(slot: slotC, top: true)),
      _Beat(
          '18.0 – 21.0 s',
          'The clans, smouldering',
          'The thirteen clans’ flags on the roofs, scorched, one lit after another; the last slot, dark, is the player’s own. Line 3.',
          _scene('tower', 37, [
            Align(
                alignment: const Alignment(0, -0.35),
                child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      for (final id in clanBannerFactionIds)
                        if (clanBannerId(id) != null) _scorched('clan_$id', 46),
                      SizedBox(
                          width: 23,
                          height: 46,
                          child: FittedBox(
                              child: PixelBanner(
                                  id: titleBannerId, scale: 1, found: false))),
                    ])),
          ]),
          const _Text(
              text:
                  'Every clan wanted the city. None of them wanted you in it.'),
          short: true),
      _Beat(
          '21.0 – 23.0 s',
          'The title, and the Shroud',
          'Black: the Shroud small above the title, torn into its six pieces (one faintly lit: yours to restore). The still frame with reduced motion.',
          Container(
              color: Colors.black,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (final (i, id) in shroudPieceIds.indexed)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SizedBox(
                                width: 28,
                                height: 56,
                                child: Opacity(
                                    opacity: i == 0 ? 0.55 : 1,
                                    child: FittedBox(
                                        child: PixelBanner(
                                            id: id,
                                            scale: 1,
                                            found: i == 0))))),
                    ]),
                    const SizedBox(height: 18),
                    Text('The Grey Shroud',
                        textAlign: TextAlign.center,
                        style: _px(27, w: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                            'A tale of dice, debts and a shroud that should not exist',
                            textAlign: TextAlign.center,
                            style: _serif(12,
                                color: _ash, style: FontStyle.italic))),
                  ])),
          const SizedBox.shrink(),
          short: true),
      _Beat(
          '23.0 – 25.0 s',
          'On to the choice',
          'The title melts into the real Race & Profession screen; line 4 holds there while the player picks.',
          lastImage == null
              ? const ColoredBox(color: Color(0xFFF3EAD7))
              : RawImage(
                  image: lastImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter),
          const _Text(text: 'Tonight it burns. First, decide who you are.'),
          short: true),
    ];
    expect(_known.length, 4);

    const spans = [4.0, 3.5, 3.5, 3.5, 3.5, 3.0, 2.0, 2.0];
    final total = spans.fold<double>(0, (a, b) => a + b);
    const boardW = 4 * (_frameW + 16) + 16;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 1400);
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
                  'Intro · version C: the city in ashes, told in text (${total.toStringAsFixed(0)} s)',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'Text first: the story’s own lines write themselves over one slow pan across Alster burnt to ash, shown in far more detail than the postcards of A and B. Lines 1 to 4 are Narrative’s set A; the three boxed slots (A, B, C) are for new lines. Plays once, a tap skips, replayable from Settings. The 15 s cut is lines 1 to 4 only.',
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
                  '0 s · ${total.toStringAsFixed(0)} s — each line holds about 3.5 s, long enough to read. The 15 s cut is frames 1, 2, 6, 7, 8 (the lines, a longer pause on each).',
                  style: _serif(11.5, color: _ash)),
              const SizedBox(height: 16),
              Text('What it is made of', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              chip(
                  'Reused as it is: the clans\u2019 banners, scorched with a colour filter (4, 6), the Shroud\u2019s six torn pieces and the title\u2019s words (7), the story\u2019s typewriter for every line, the real Race & Profession screen (8), the reduced-motion check.'),
              chip(
                  'New: the city in ashes, drawn in pixel art by four small painters: the burning skyline with its smoke (1), the broken tower and bell (2, 6), Tallow Street with its chalked doors, wire, well-head edict and Inquisitors (3, 4), the harbor with the giant and the white ships (5); a slow pan across them with the ash falling over all; one intro screen and its tap-to-skip; a \u201cseen\u201d flag and a Replay row in Settings; the lines.',
                  c: const Color(0xFFE08A6A)),
              chip(
                  'Build: about two days, one PR of about 700 lines and a test (the beats in order, a tap skips, reduced motion shows the title). The painters are the cost; no new art files. Lines A, B, C and the 15 s cut are the decisions.',
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
      File('$shots/intro-storyboard-c.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
