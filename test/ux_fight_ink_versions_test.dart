// Three versions of the ink-wash combat screen (UX_SHOTS=<folder>), pictures
// only. The user's two constraints: the real chibi sprites, recoloured only
// (assets/visuals via make_ink_assets.py: near-black, cold greys, paper white,
// deep red on small parts), at the usual 2 dp per art pixel; and the real 3D
// dice (Die3D) with real face counts (a d6, a d8 and a d12), every face a
// skill glyph, the top face the rolled skill, the selected die listing all its
// faces in a strip under the dice.
//   A Panels: slanted comic panels, speed lines, the ink splash on the aimed foe.
//   B Scroll: one ink-wash ground from the fighters down to the dice tray, no
//             slants, brush-stroke dividers.
//   C Ink frame kit: every piece in its own brush frame, the ground faint.
// In all three: weakness mark B on the nameplate (a long name sends its marks
// under the plate, as v1.996/1.997), the matching-die hint with that die's
// face lit red, the turn bar, the skill cards in brush frames.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/game_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

import 'support/fonts.dart';

const String _art = 'docs/ux-shots/fight-proposals/art';
const String _spr = 'docs/ux-shots/fight-ink/assets';
const Color _black = Color(0xFF05060A);
const Color _paper = Color(0xFFEFEDE8);
const Color _grey = Color(0xFF9AA3A7);
const Color _dark = Color(0xFF202E37);
const Color _red = Color(0xFFC1121A);
const double _w = 360;
const double _h = 780;

/// Horizontal scale of the screen being drawn (1 at 360 wide).
double _k = 1;
double _x(double v) => v * _k;

final Map<String, ui.Image> _im = {};
final Map<String, Rect> _bb = {};

Future<void> _load(String key, String path, {bool bbox = false}) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final img = (await codec.getNextFrame()).image;
  _im[key] = img;
  if (bbox) {
    final data = (await img.toByteData())!;
    var x0 = img.width, y0 = img.height, x1 = 0, y1 = 0;
    for (var y = 0; y < img.height; y++) {
      for (var x = 0; x < img.width; x++) {
        if (data.getUint8((y * img.width + x) * 4 + 3) > 0) {
          x0 = math.min(x0, x);
          y0 = math.min(y0, y);
          x1 = math.max(x1, x + 1);
          y1 = math.max(y1, y + 1);
        }
      }
    }
    _bb[key] = Rect.fromLTRB(
        x0.toDouble(), y0.toDouble(), x1.toDouble(), y1.toDouble());
  }
}

class _Pic extends CustomPainter {
  _Pic(this.img, {this.src, this.flip = false, this.opacity = 1});
  final ui.Image img;
  final Rect? src;
  final bool flip;
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final s = src ?? Rect.fromLTWH(0, 0, img.width * 1.0, img.height * 1.0);
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
        img,
        s,
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false
          ..color = Color.fromRGBO(255, 255, 255, opacity));
  }

  @override
  bool shouldRepaint(_Pic old) => false;
}

Widget _pic(String key,
    {Rect? src, bool flip = false, double opacity = 1, double scale = 1}) {
  final img = _im[key]!;
  final s = src ?? Rect.fromLTWH(0, 0, img.width * 1.0, img.height * 1.0);
  return CustomPaint(
      size: Size(s.width * scale, s.height * scale),
      painter: _Pic(img, src: src, flip: flip, opacity: opacity));
}

/// A chibi standing with its feet at ([cx], [feetY]), 2 dp per art pixel.
Widget _chibi(String key, double cx, double feetY,
    {bool flip = false, double u = 2}) {
  final b = _bb[key]!;
  return Positioned(
      left: cx - b.width * u / 2,
      top: feetY - b.height * u,
      child: _pic(key, src: b, flip: flip, scale: u));
}

/// A nine-slice of the brush frame: corners [ins] of the source drawn at
/// [dst] (so a smaller dst gives a thinner frame), sides stretched.
class _Nine extends CustomPainter {
  _Nine(this.img, this.dst);
  final ui.Image img;
  final double dst;
  @override
  void paint(Canvas canvas, Size s) {
    const ins = 24.0;
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final xs = [0.0, ins, iw - ins, iw];
    final ys = [0.0, ins, ih - ins, ih];
    final dx = [0.0, dst, s.width - dst, s.width];
    final dy = [0.0, dst, s.height - dst, s.height];
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 3; i++) {
        if (i == 1 && j == 1) continue;
        canvas.drawImageRect(
            img,
            Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
            Rect.fromLTRB(dx[i], dy[j], dx[i + 1], dy[j + 1]),
            p);
      }
    }
  }

  @override
  bool shouldRepaint(_Nine old) => false;
}

Widget _frame(double w, double h,
        {double inset = 12, Widget? child, double fill = 0.88}) =>
    SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        Positioned.fill(
            child: Container(color: _black.withValues(alpha: fill))),
        Positioned.fill(
            child: CustomPaint(painter: _Nine(_im['frame']!, inset))),
        if (child != null) Positioned.fill(child: child),
      ]),
    );

TextStyle _brush(double s, {Color color = _paper}) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: color);
TextStyle _sys(double s, {Color color = _grey}) => TextStyle(
    fontFamily: InkFonts.system, fontSize: s, height: 1.15, color: color);

// ---- the fight's data -----------------------------------------------------

class _Foe {
  const _Foe(this.id, this.name, this.hp, this.max, this.weak, this.resist);
  final String id;
  final String name;
  final int hp, max;
  final List<String> weak, resist;
}

const _heroes = [
  ('warrior', 'Edda', 41, 52),
  ('cleric', 'Liora', 30, 36),
  ('mage', 'Vess', 24, 28)
];

/// The dice: real counts, each face a real skill. The first face is the rolled one.
const _dice = [
  (
    'Edda',
    'warrior',
    'Light',
    [
      'radiant_judgment',
      'heavy_attack',
      'warrior_iron_stance',
      'shadow_step',
      'fireball',
      'second_wind',
    ]
  ),
  (
    'Liora',
    'cleric',
    'Fire',
    [
      'fireball',
      'cleric_prayer',
      'quick_heal',
      'celestial_ward',
      'cleric_purify',
      'radiant_judgment',
      'cleric_absolution',
      'edict_of_silence',
    ]
  ),
  (
    'Vess',
    'mage',
    'Void',
    [
      'void_blast',
      'mage_arcane_missile',
      'mage_rime_lance',
      'fireball',
      'mage_chain_lightning',
      'mage_glacial_ward',
      'mage_frost_nova',
      'void_blast',
      'mage_static_charge',
      'mage_teleport_strike',
      'frigid_grip',
      'mage_meteor',
    ]
  ),
];

const _cards = [
  ('radiant_judgment', 'Light', 'common'),
  ('fireball', 'Fire', 'rare'),
  ('cleric_absolution', 'Light', 'epic'),
];

IconData _icon(String e) => elementIcon(e);

// ---- the pieces -----------------------------------------------------------

Widget _mark(String e, {required bool weak, bool lit = false}) => Container(
      height: 15,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: _black,
        border: Border.all(color: weak ? _red : _grey, width: lit ? 2 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon(e), size: 11, color: _paper),
        const SizedBox(width: 1),
        Text(weak ? '×3' : '×½',
            style: TextStyle(
                fontFamily: InkFonts.prose,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                height: 1,
                color: weak ? _paper : _grey)),
      ]),
    );

Widget _bar(int hp, int max, double w, {Color color = _red}) => SizedBox(
      width: w,
      height: 5,
      child: Stack(children: [
        Container(color: const Color(0xFF2A2C34)),
        FractionallySizedBox(
            widthFactor: hp / max, child: Container(color: color)),
      ]),
    );

/// A skewed black nameplate. A short name carries its marks on the plate; a
/// long one sends them to a row under it (the v1.996 rule).
Widget _plate(_Foe f,
    {required double width,
    bool aimed = false,
    String? matching,
    double skew = 0.2}) {
  final marks = [
    for (final e in f.weak) _mark(e, weak: true, lit: e == matching),
    for (final e in f.resist) _mark(e, weak: false),
  ];
  final long = f.name.length > 16 || width < 130;
  return SizedBox(
    width: width,
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            transform: Matrix4.skewX(-skew),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
              decoration: BoxDecoration(
                color: _black,
                border: Border(
                    left: BorderSide(color: aimed ? _red : _paper, width: 3),
                    bottom: BorderSide(color: aimed ? _red : _grey, width: 1)),
              ),
              child: Transform(
                transform: Matrix4.skewX(skew),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(f.name,
                                maxLines: 1, style: _brush(12.5)))),
                    if (!long)
                      for (final m in marks)
                        Padding(
                            padding: const EdgeInsets.only(left: 3), child: m),
                  ]),
                  const SizedBox(height: 3),
                  _bar(f.hp, f.max, width),
                ]),
              ),
            ),
          ),
          if (long)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 6),
              child: Row(children: [
                for (final m in marks)
                  Padding(padding: const EdgeInsets.only(right: 3), child: m),
              ]),
            ),
        ]),
  );
}

Widget _heroPlate(String name, int hp, int max,
        {bool turn = false, double width = 96, double skew = 0.2}) =>
    Transform(
      transform: Matrix4.skewX(-skew),
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
        decoration: BoxDecoration(
          color: _black,
          border: Border(
              left: BorderSide(color: turn ? _red : _paper, width: 3),
              bottom: BorderSide(color: turn ? _red : _grey, width: 1)),
        ),
        child: Transform(
          transform: Matrix4.skewX(skew),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(name, style: _brush(12.5))),
            const SizedBox(height: 3),
            _bar(hp, max, width),
          ]),
        ),
      ),
    );

Widget _head(String key, {bool now = false, int? order}) =>
    Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: _black,
          shape: BoxShape.circle,
          border: Border.all(color: now ? _red : _grey, width: now ? 3 : 1.5),
        ),
        child: ClipOval(
            child: CustomPaint(
                painter: _Pic(_im[key]!,
                    src: Rect.fromLTWH(_bb[key]!.left, _bb[key]!.top,
                        _bb[key]!.width, _bb[key]!.width)))),
      ),
      if (order != null)
        Positioned(
            left: -2,
            bottom: -2,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                color: now ? _red : _dark,
                child: Text('$order', style: _sys(8, color: _paper)))),
    ]);

Widget _turnBar() => Row(children: [
      Text('TURN', style: _sys(9)),
      const SizedBox(width: 6),
      _head('warrior', now: true, order: 1),
      _head('white_soldier', order: 2),
      _head('cleric', order: 3),
      _head('inquisition_warden', order: 4),
      _head('mage', order: 5),
      _head('void_sovereign', order: 6),
    ]);

Widget _title(String sov) => Stack(children: [
      Positioned(
          left: 14, top: 8, child: Text('Fight: $sov', style: _brush(21))),
      Positioned(
          left: 14, top: 36, child: Text('The rift · Round 2', style: _sys(9))),
      Positioned(left: 14, top: 54, child: _turnBar()),
    ]);

// ---- the dice -------------------------------------------------------------

const _skin =
    DieSkin('Ink', Color(0xFF0B0C14), Color(0xFFB7C0C4), DiePattern.none);
const _skinLit = DieSkin('Ink', Color(0xFF0B0C14), Color(0xFFC1121A),
    DiePattern.none, Color(0xFFC1121A));

Widget _glyph(String skill, double size, {bool lit = false}) => lit
    ? SkillPixelIcon(skill, size: size)
    : ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 20, //
          0.33, 0.33, 0.33, 0, 20,
          0.33, 0.33, 0.33, 0, 24,
          0, 0, 0, 1, 0,
        ]),
        child: SkillPixelIcon(skill, size: size));

/// The real 3D die with its real face count; the first face is the rolled one,
/// lit red when it is the matching element.
Widget _die3d((String, String, String, List<String>) d,
    {double size = 60, bool lit = false}) {
  final skills = d.$4;
  DieCubeFace face(int i) => DieCubeFace(
      glyph: _glyph(skills[i % skills.length], 30, lit: lit && i == 0),
      color: lit && i == 0 ? _red : const Color(0xFF8B9BA0));
  final shape = dieShapeOf(skills.length);
  return Die3D(
    faces: [for (var i = 0; i < 6; i++) face(i)],
    facets: shape == DieShape.d6
        ? null
        : [for (var i = 0; i < skills.length; i++) face(i)],
    accent: _grey,
    size: size,
    shape: shape,
    skin: lit ? _skinLit : _skin,
    still: true,
    element: 'None',
  );
}

Widget _dieCell((String, String, String, List<String>) d, double cell,
        {bool selected = false, bool matches = false, double size = 58}) =>
    SizedBox(
      width: cell,
      height: 112,
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (selected)
              Positioned(
                  top: 0,
                  child: Container(
                      width: cell - 8,
                      height: 82,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: matches ? _red : _paper, width: 2)))),
            Positioned(top: 8, child: _die3d(d, size: size, lit: matches)),
            if (matches)
              Positioned(
                  top: -4, right: 6, child: _mark(d.$3, weak: true, lit: true)),
            Positioned(
                bottom: 0,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    color: _black.withValues(alpha: 0.88),
                    child: Text('${d.$1} · d${d.$4.length} · ${d.$3}',
                        style: _sys(9, color: _paper)))),
          ]),
    );

/// The selected die's faces, listed: every face a skill, the rolled one lit.
Widget _faceStrip((String, String, String, List<String>) d, double width,
    {bool bg = true}) {
  final n = d.$4.length;
  final chip = math.min(30.0, (width - 16 - (n - 1) * 3) / n);
  return Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
    color: bg ? _black.withValues(alpha: 0.85) : null,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < n; i++)
        Container(
          width: chip,
          height: chip,
          margin: EdgeInsets.only(right: i == n - 1 ? 0 : 3),
          decoration: BoxDecoration(
            color: _dark,
            border: Border.all(
                color: i == 0 ? _red : _grey.withValues(alpha: 0.6),
                width: i == 0 ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: _glyph(d.$4[i], chip - 6, lit: i == 0),
        ),
    ]),
  );
}

Widget _hint(String sov, double width) => Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
      child: Row(children: [
        const Icon(Icons.wb_sunny, size: 12, color: _red),
        const SizedBox(width: 6),
        Expanded(
            child: Text('Your Light die hits $sov ×3: it is weak to Light.',
                maxLines: 2,
                style: const TextStyle(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    height: 1.15,
                    color: _paper))),
      ]),
    );

// ---- the cards ------------------------------------------------------------

Widget _card((String, String, String) c,
    {bool lit = false, double w = 100, double h = 116}) {
  final (id, element, rarity) = c;
  final pips = switch (rarity) { 'epic' => 3, 'rare' => 2, _ => 1 };
  return _frame(
    w,
    h,
    inset: 12,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icon(element), size: 11, color: lit ? _red : _grey),
          const SizedBox(width: 4),
          for (var i = 0; i < pips; i++)
            Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 2),
                color: lit ? _red : _grey),
        ]),
        const SizedBox(height: 2),
        _glyph(id, 36, lit: lit),
        const SizedBox(height: 3),
        for (final word in skillDisplayName(id).split(' '))
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(word, maxLines: 1, style: _brush(10.5))),
      ]),
    ),
  );
}

Widget _hand(
        {double top = 652,
        double left = 8,
        double gap = 6,
        double w = 100,
        double h = 116}) =>
    Positioned(
      left: left,
      top: top,
      child: Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Stack(children: [
            _card(_cards[i], lit: i == 0, w: w, h: h),
            if (i == 0)
              Positioned.fill(
                  child: IgnorePointer(
                      child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              border: Border.all(color: _red, width: 2))))),
          ]),
          SizedBox(width: gap),
        ],
      ]),
    );

Widget _strike({double left = 262, double top = 624, double skew = 0.2}) =>
    Positioned(
        left: left,
        top: top,
        child: Transform(
          transform: Matrix4.skewX(-skew),
          child: Container(
            width: 92,
            height: 32,
            alignment: Alignment.center,
            color: _red,
            child: Transform(
                transform: Matrix4.skewX(skew),
                child: Text('Strike ×3', style: _brush(15))),
          ),
        ));

// ---- decor: speed lines, ragged brush strokes ------------------------------

class _SpeedLines extends CustomPainter {
  _SpeedLines(this.at);
  final Offset at;
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final r0 = 40 + rnd.nextDouble() * 36;
      final r1 = r0 + 36 + rnd.nextDouble() * 130;
      final p = Paint()
        ..strokeCap = StrokeCap.square
        ..strokeWidth = i % 9 == 0 ? 3 : 1
        ..color = (i % 11 == 0 ? _red : _paper).withValues(alpha: 0.65);
      canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * r0,
          at + Offset(math.cos(a), math.sin(a)) * r1, p);
    }
  }

  @override
  bool shouldRepaint(_SpeedLines old) => false;
}

/// A ragged horizontal brush stroke, ink on the ground.
class _Stroke extends CustomPainter {
  _Stroke(this.seed);
  final int seed;
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final top = <Offset>[], bottom = <Offset>[];
    for (var x = 0.0; x <= size.width; x += 6) {
      final edge = (x < 24 || x > size.width - 24) ? 3 : 0;
      top.add(Offset(x, rnd.nextDouble() * 3 + edge));
      bottom.add(Offset(x, size.height - rnd.nextDouble() * 4 - edge));
    }
    final path = Path()..addPolygon([...top, ...bottom.reversed], true);
    canvas.drawPath(path, Paint()..color = _black);
    // a few dry-brush hairlines through the stroke
    final line = Paint()
      ..color = _paper.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.25 + 0.15 * i) + rnd.nextDouble() * 2;
      final x0 = rnd.nextDouble() * size.width * 0.3;
      canvas.drawLine(Offset(x0, y),
          Offset(x0 + size.width * (0.3 + rnd.nextDouble() * 0.4), y), line);
    }
  }

  @override
  bool shouldRepaint(_Stroke old) => false;
}

class _PanelClipper extends CustomClipper<Path> {
  _PanelClipper(this.pts);
  final List<Offset> pts;
  @override
  Path getClip(Size size) => Path()..addPolygon(pts, true);
  @override
  bool shouldReclip(_PanelClipper old) => false;
}

class _PanelBorder extends CustomPainter {
  _PanelBorder(this.pts);
  final List<Offset> pts;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeJoin = StrokeJoin.miter
          ..color = _black);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.miter
          ..color = _paper.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_PanelBorder old) => false;
}

// ---- the three versions ---------------------------------------------------

List<_Foe> _foes(Map<String, dynamic> enemies) {
  _Foe foe(String id, int hp, int max) => _Foe(
      id,
      (enemies[id] as Map)['enemyName'] as String,
      hp,
      max,
      [for (final e in (enemies[id] as Map)['weakTo'] as List) '$e'],
      [for (final e in (enemies[id] as Map)['resists'] as List) '$e']);
  return [
    foe('inquisition_warden', 22, 22),
    foe('void_sovereign', 86, 86),
    foe('white_soldier', 11, 16)
  ];
}

Widget _screenA(List<_Foe> foes) {
  const p1 = [
    Offset(0, 100),
    Offset(360, 100),
    Offset(360, 296),
    Offset(0, 326)
  ];
  const p2 = [
    Offset(0, 340),
    Offset(360, 310),
    Offset(360, 470),
    Offset(0, 470)
  ];
  const p3 = [
    Offset(0, 482),
    Offset(360, 482),
    Offset(360, 620),
    Offset(0, 620)
  ];
  Widget panel(List<Offset> pts, double bgDy, List<Widget> scene) =>
      Stack(children: [
        ClipPath(
            clipper: _PanelClipper(pts),
            child: Stack(children: [
              Positioned(left: 0, top: bgDy, child: _pic('bg')),
              ...scene,
            ])),
        CustomPaint(size: const Size(_w, _h), painter: _PanelBorder(pts)),
      ]);
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _title(foes[1].name),
    panel(p1, -30, [
      // the ink splash sits behind the aimed foe, the speed lines over all
      Positioned(
          left: 190 - 64, top: 292 - 124 - 6, child: _pic('hit', opacity: 0.9)),
      _chibi('inquisition_warden', 62, 300),
      _chibi('void_sovereign', 190, 282),
      _chibi('white_soldier', 300, 296),
      Positioned.fill(
          child: CustomPaint(painter: _SpeedLines(const Offset(190, 226)))),
      Positioned(left: 8, top: 108, child: _plate(foes[0], width: 108)),
      Positioned(
          left: 124,
          top: 108,
          child: _plate(foes[1], width: 116, aimed: true, matching: 'Light')),
      Positioned(left: 246, top: 108, child: _plate(foes[2], width: 106)),
    ]),
    panel(p2, 30, [
      _chibi('warrior', 62, 434),
      _chibi('cleric', 180, 426),
      _chibi('mage', 298, 418),
      Positioned(
          left: 14, top: 438, child: _heroPlate('Edda', 41, 52, turn: true)),
      Positioned(left: 132, top: 430, child: _heroPlate('Liora', 30, 36)),
      Positioned(left: 250, top: 422, child: _heroPlate('Vess', 24, 28)),
    ]),
    panel(p3, 0, [
      Positioned(
          left: 4,
          top: 502,
          child:
              _dieCell(_dice[0], 112, selected: true, matches: true, size: 52)),
      Positioned(left: 124, top: 496, child: _dieCell(_dice[1], 112, size: 52)),
      Positioned(left: 244, top: 496, child: _dieCell(_dice[2], 112, size: 52)),
    ]),
    Positioned(left: 0, top: 624, child: _faceStrip(_dice[0], _w)),
    Positioned(left: 0, top: 654, child: _hint(foes[1].name, _w - 108)),
    _hand(top: 682, h: 96),
    _strike(top: 654, left: 256),
  ]);
}

Widget _screenB(List<_Foe> foes) {
  // One ink-wash ground from the fighters down into the tray; brush strokes
  // divide it; no slants.
  Widget stroke(double top, int seed) => Positioned(
      left: _x(0),
      top: top,
      child: SizedBox(
          width: _w, height: 14, child: CustomPaint(painter: _Stroke(seed))));
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _title(foes[1].name),
    Positioned(
        left: _x(0),
        top: 96,
        child: SizedBox(
            width: _w * _k,
            height: 560,
            child: ClipRect(
                child: Stack(children: [
              Positioned(left: 0, top: -30, child: _pic('bg')),
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [
                    0,
                    0.08,
                    0.9,
                    1
                  ],
                              colors: [
                    _black,
                    _black.withValues(alpha: 0),
                    _black.withValues(alpha: 0),
                    _black
                  ])))),
            ])))),
    _chibi('inquisition_warden', _x(64), 290),
    _chibi('void_sovereign', _x(180), 292),
    _chibi('white_soldier', _x(292), 294),
    Positioned(
        left: _x(8), top: 102, child: _plate(foes[0], width: _x(108), skew: 0)),
    Positioned(
        left: _x(124),
        top: 102,
        child: _plate(foes[1],
            width: _x(112), aimed: true, matching: 'Light', skew: 0)),
    Positioned(
        left: _x(244),
        top: 102,
        child: _plate(foes[2], width: _x(108), skew: 0)),
    stroke(300, 3),
    _chibi('warrior', _x(62), 424),
    _chibi('cleric', _x(180), 420),
    _chibi('mage', _x(292), 416),
    Positioned(
        left: _x(14),
        top: 428,
        child: _heroPlate('Edda', 41, 52, turn: true, skew: 0, width: _x(94))),
    Positioned(
        left: _x(130),
        top: 424,
        child: _heroPlate('Liora', 30, 36, skew: 0, width: _x(94))),
    Positioned(
        left: _x(244),
        top: 420,
        child: _heroPlate('Vess', 24, 28, skew: 0, width: _x(94))),
    stroke(466, 5),
    Positioned(
        left: _x(4),
        top: 478,
        child: _dieCell(_dice[0], _x(112),
            selected: true, matches: true, size: 52)),
    Positioned(
        left: _x(124), top: 478, child: _dieCell(_dice[1], _x(112), size: 52)),
    Positioned(
        left: _x(244), top: 478, child: _dieCell(_dice[2], _x(112), size: 52)),
    Positioned(left: _x(0), top: 590, child: _faceStrip(_dice[0], _w * _k)),
    Positioned(
        left: _x(0), top: 624, child: _hint(foes[1].name, _w * _k - 108)),
    stroke(656, 9),
    _hand(top: 672, h: 104, w: _k == 1 ? 100 : 97),
    _strike(top: 626, left: _x(256), skew: 0),
  ]);
}

Widget _slot(double left, double top, double w, double h, List<Widget> kids) =>
    Positioned(
        left: left,
        top: top,
        child: SizedBox(
            width: w,
            height: h,
            child:
                Stack(children: [_frame(w, h, inset: 8, fill: 0.7), ...kids])));

Widget _screenC(List<_Foe> foes) {
  // Every piece in its own brush frame, the ground faint behind.
  const sw = 112.0;
  const xs = [6.0, 124.0, 242.0];
  Widget foeSlot(int i) => _slot(xs[i], 96, sw, 176, [
        _chibi(foes[i].id, sw / 2, 172),
        Positioned(
            left: 8,
            top: 10,
            child: _plate(foes[i],
                width: sw - 16, aimed: i == 1, matching: 'Light')),
      ]);
  Widget heroSlot(int i) => _slot(xs[i], 278, sw, 150, [
        _chibi(_heroes[i].$1, sw / 2, 100),
        Positioned(
            left: 8,
            top: 106,
            child: _heroPlate(_heroes[i].$2, _heroes[i].$3, _heroes[i].$4,
                turn: i == 0, width: sw - 22)),
      ]);
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    Positioned(
        left: 0,
        top: 96,
        child: SizedBox(
            width: _w,
            height: 560,
            child: ClipRect(
                child: Stack(children: [
              Positioned(left: 0, top: -30, child: _pic('bg', opacity: 0.28))
            ])))),
    _title(foes[1].name),
    for (var i = 0; i < 3; i++) foeSlot(i),
    for (var i = 0; i < 3; i++) heroSlot(i),
    for (var i = 0; i < 3; i++)
      _slot(xs[i], 434, sw, 112, [
        Positioned(
            left: 0,
            right: 0,
            top: 2,
            child: Center(
                child: _dieCell(_dice[i], sw - 8,
                    selected: i == 0, matches: i == 0, size: 50))),
      ]),
    _slot(6, 552, 348, 40, [
      Positioned.fill(
          child: Center(child: _faceStrip(_dice[0], 340, bg: false)))
    ]),
    Positioned(left: 0, top: 600, child: _hint(foes[1].name, _w - 108)),
    _hand(top: 640, left: 6, gap: 8, w: 108, h: 116),
    _strike(top: 598, left: 256),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('three ink fight screens', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(() async {
      await _load('bg', '$_art/ink_background.png');
      await _load('frame', '$_art/ink_frame.png');
      await _load('hit', '$_art/ink_hit.png');
      for (final n in [
        'void_sovereign',
        'inquisition_warden',
        'white_soldier',
        'warrior',
        'cleric',
        'mage'
      ]) {
        await _load(n, '$_spr/$n.png', bbox: true);
      }
    });
    final foes = _foes(enemies);
    for (final (name, build, width) in [
      ('ink-a-panels', _screenA, 360.0),
      ('ink-b-scroll', _screenB, 360.0),
      ('ink-b-scroll-320', _screenB, 320.0),
      ('ink-c-frames', _screenC, 360.0),
    ]) {
      _k = width / 360;
      final key = GlobalKey();
      tester.view.physicalSize = Size(width, _h);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark)),
          home: Scaffold(
              backgroundColor: _black,
              body: SizedBox(width: width, height: _h, child: build(foes))),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
