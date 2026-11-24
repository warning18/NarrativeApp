// The Tower in ink-wash version A (UX_SHOTS=<folder>), pictures only: every
// screen the player meets in the Tower, drawn at 360 wide (720x1560).
// The user's rules: the original chibi sprites, recoloured only (the
// make_ink_assets.py greys, deep red only on small parts); real 3D skill dice
// (Die3D) with a face strip; the ink palette, red kept to what matters (health,
// your turn, the aimed foe, a x3, the lit die, the one button that goes on);
// slanted comic panels where they help and not on the text-heavy screens.
// The Tower's own plates are recoloured into the ink greys as PLACEHOLDERS
// (docs/ux-shots/tower-ink/make_tower_ink.py); every picture that uses one
// is marked. Mock only: no rule or number is Core's to change.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/game_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

import 'support/fonts.dart';

const String _art = 'docs/ux-shots/fight-proposals/art';
const String _spr = 'docs/ux-shots/fight-ink/assets';
const String _tw = 'docs/ux-shots/tower-ink/assets';
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

/// The dice: real counts, each face a real skill. The first face is the rolled one.
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

Widget _hint(String sov, double width, [String element = 'Light']) => Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
      child: Row(children: [
        Icon(_icon(element), size: 12, color: _red),
        const SizedBox(width: 6),
        Expanded(
            child: Text(
                'Your $element die hits $sov ×3: it is weak to $element.',
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
        double h = 116,
        List<(String, String, String)> cards = _cards}) =>
    Positioned(
      left: left,
      top: top,
      child: Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Stack(children: [
            _card(cards[i], lit: i == 0, w: w, h: h),
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

// ---- the Tower's pieces ---------------------------------------------------

String _t(String key, [Map<String, String> r = const {}]) {
  var s = trFor(AppLanguage.en, key);
  r.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

TextStyle _prose(double s,
        {Color color = _paper, bool italic = false, bool bold = false}) =>
    TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: s,
        height: 1.3,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

Widget _at(double l, double t, Widget c) =>
    Positioned(left: l, top: t, child: c);

/// A skewed brush button; the one that goes on is red.
Widget _btn(String text,
        {bool red = false, double w = 180, double h = 34, bool dim = false}) =>
    Transform(
      transform: Matrix4.skewX(-0.2),
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: red ? _red : _black,
          border: Border.all(
              color: red ? _red : (dim ? _grey.withValues(alpha: 0.4) : _paper),
              width: 1.5),
        ),
        child: Transform(
            transform: Matrix4.skewX(0.2),
            child: Text(text,
                style: _brush(14, color: dim ? _grey : _paper),
                textAlign: TextAlign.center)),
      ),
    );

/// A black text panel with a paper hairline and a slanted title tab.
Widget _tPanel(double l, double t, double w, double h,
        {String? title, bool red = false, List<Widget> kids = const []}) =>
    Positioned(
      left: l,
      top: t,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      color: _black.withValues(alpha: 0.9),
                      border: Border.all(
                          color: red ? _red : _paper.withValues(alpha: 0.7),
                          width: red ? 2 : 1)))),
          if (title != null)
            Positioned(
                left: -4,
                top: -10,
                child: Transform(
                    transform: Matrix4.skewX(-0.2),
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 2, 12, 3),
                        color: red ? _red : _dark,
                        child: Transform(
                            transform: Matrix4.skewX(0.2),
                            child: Text(title, style: _brush(12.5)))))),
          ...kids,
        ]),
      ),
    );

/// A slanted illustrated panel (the plate or the ink ground inside).
Widget _poly(List<Offset> pts, String bg, double bgDy, double bgScale,
        List<Widget> scene,
        {double bgOpacity = 1}) =>
    Stack(children: [
      ClipPath(
          clipper: _PanelClipper(pts),
          child: Stack(children: [
            Positioned(
                left: 0,
                top: bgDy,
                child: _pic(bg, scale: bgScale, opacity: bgOpacity)),
            ...scene,
          ])),
      CustomPaint(size: const Size(_w, _h), painter: _PanelBorder(pts)),
    ]);

/// The ladder of 30 floors, climbed lit, the floor you are on red, wardens
/// wider, bosses widest and ringed.
Widget _ladder(int floor, {double top = 78, double pitch = 20}) =>
    Stack(children: [
      for (var i = 30; i >= 1; i--)
        () {
          final boss = i % 10 == 0, ward = i % 10 == 5;
          final w = boss
              ? 34.0
              : ward
                  ? 30.0
                  : 24.0;
          final now = i == floor;
          final done = i < floor;
          return Positioned(
              left: 6 + (36 - w) / 2,
              top: top + (30 - i) * pitch,
              child: Container(
                width: w,
                height: pitch - 4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: now
                      ? _red
                      : (done ? _grey.withValues(alpha: 0.85) : _black),
                  border: Border.all(
                      color: boss
                          ? _red
                          : (now
                              ? _red
                              : _grey.withValues(alpha: done ? 0.9 : 0.45)),
                      width: boss ? 2 : 1),
                ),
                child: (now || boss || ward)
                    ? Text('$i',
                        style: _sys(8,
                            color: now ? _paper : (done ? _black : _grey)))
                    : null,
              ));
        }(),
    ]);

/// The Tower's title band: the name, where you are, and the way out.
Widget _tTitle(String title, String sub,
        {bool leave = false, bool back = false}) =>
    Stack(children: [
      if (back)
        const Positioned(
            left: 10,
            top: 14,
            child: Icon(Icons.arrow_back, size: 20, color: _paper)),
      Positioned(
          left: back ? 38 : 14, top: 8, child: Text(title, style: _brush(21))),
      Positioned(
          left: back ? 38 : 14, top: 36, child: Text(sub, style: _sys(9))),
      if (leave)
        const Positioned(
            right: 12,
            top: 14,
            child: Icon(Icons.logout, size: 20, color: _grey)),
    ]);

Widget _ground(String key,
        {double opacity = 0.3, double top = 0, double h = 780}) =>
    Positioned(
        left: 0,
        top: top,
        child: SizedBox(
            width: _w,
            height: h,
            child: ClipRect(
                child: Stack(children: [
              Positioned(
                  left: 0,
                  top: 0,
                  child: _pic(key, scale: 2, opacity: opacity)),
            ]))));

/// An ink-framed slot with a placeholder where a picture will go.
Widget _slotBox(double l, double t, double w, double h,
        {List<Widget> kids = const [], bool red = false}) =>
    Positioned(
        left: l,
        top: t,
        child: SizedBox(
            width: w,
            height: h,
            child: Stack(children: [
              _frame(w, h, inset: 8, fill: 0.85),
              if (red)
                Positioned.fill(
                    child: IgnorePointer(
                        child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                border: Border.all(color: _red, width: 2))))),
              ...kids,
            ])));

Widget _placeholder(double s, {String label = 'art'}) => Container(
    width: s,
    height: s,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        border: Border.all(color: _grey.withValues(alpha: 0.6)),
        color: _dark.withValues(alpha: 0.5)),
    child: Text(label, style: _sys(8)));

const _towerDice = [
  (
    'Ash die',
    'warrior',
    'Light',
    [
      'radiant_judgment',
      'heavy_attack',
      'warrior_iron_stance',
      'shadow_step',
      'fireball',
      'second_wind'
    ]
  ),
  (
    'Oak die',
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
      'edict_of_silence'
    ]
  ),
  (
    'Tally die',
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
      'mage_meteor'
    ]
  ),
];

const _fireDice = [
  (
    'Ash die',
    'warrior',
    'Fire',
    [
      'fireball',
      'heavy_attack',
      'warrior_iron_stance',
      'shadow_step',
      'radiant_judgment',
      'second_wind'
    ]
  ),
  (
    'Oak die',
    'cleric',
    'Light',
    [
      'radiant_judgment',
      'cleric_prayer',
      'quick_heal',
      'celestial_ward',
      'cleric_purify',
      'fireball',
      'cleric_absolution',
      'edict_of_silence'
    ]
  ),
  (
    'Tally die',
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
      'mage_meteor'
    ]
  ),
];

const _fireCards = [
  ('fireball', 'Fire', 'rare'),
  ('radiant_judgment', 'Light', 'common'),
  ('cleric_absolution', 'Light', 'epic'),
];

/// The "Your dice" panel: the die in play ringed, one marked new, the face strip of the die in play.
Widget _dicePanel(double l, double t, double w,
    {bool strip = true,
    bool matches = true,
    List<(String, String, String, List<String>)> dice = _towerDice}) {
  final cell = (w - 12) / 3;
  return Stack(children: [
    _tPanel(l, t, w, strip ? 168 : 128, title: _t('tower_dice_title'), kids: [
      for (var i = 0; i < 3; i++)
        Positioned(
            left: 6 + i * cell,
            top: 6,
            child: _dieCell(dice[i], cell,
                selected: i == 0, matches: matches && i == 0, size: 46)),
      Positioned(
          left: 6 + 2 * cell + cell - 26,
          top: 8,
          child: Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: _red, shape: BoxShape.circle))),
      if (strip)
        Positioned(left: 0, top: 124, child: _faceStrip(dice[0], w, bg: false)),
    ]),
  ]);
}

List<Offset> _quad(double x0, double y0, double x1, double y1, double slantL,
        double slantR) =>
    [
      Offset(x0, y0 + slantL),
      Offset(x1, y0 + slantR),
      Offset(x1, y1),
      Offset(x0, y1)
    ];

// ---- the screens ----------------------------------------------------------

/// Art's wide ink frame (nine-slice, paper inside): the text-heavy screens'
/// panel. The dark text on it is the ink of the page.
class _NineW extends CustomPainter {
  _NineW(this.img, this.scale);
  final ui.Image img;

  /// The frame is drawn at this share of its size (0.5: half, so the ragged
  /// border is about 12 dp and the paper keeps the room).
  final double scale;
  @override
  void paint(Canvas canvas, Size s) {
    // The paper inside Art's frame starts 26, 22, 24, 22 px in from its edges.
    const l = 26.0, t = 22.0, r = 24.0, bm = 22.0;
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final xs = [0.0, l, iw - r, iw];
    final ys = [0.0, t, ih - bm, ih];
    final dx = [0.0, l * scale, s.width - r * scale, s.width];
    final dy = [0.0, t * scale, s.height - bm * scale, s.height];
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 3; i++) {
        canvas.drawImageRect(
            img,
            Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
            Rect.fromLTRB(dx[i], dy[j], dx[i + 1], dy[j + 1]),
            p);
      }
    }
  }

  @override
  bool shouldRepaint(_NineW old) => false;
}

const Color _inkText = Color(0xFF0B0C14);

/// A paper panel in Art's wide frame; [title] sits on a slanted tab.
Widget _paperPanel(double l, double t, double w, double h,
        {String? title,
        double inset = 12,
        Color? wash,
        List<Widget> kids = const []}) =>
    Positioned(
      left: l,
      top: t,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
              child: CustomPaint(painter: _NineW(_im['wide']!, 0.5))),
          if (wash != null)
            Positioned.fill(
                child: Padding(
                    padding: EdgeInsets.all(inset * 0.7),
                    child: Container(color: wash))),
          if (title != null)
            Positioned(
                left: -2,
                top: -10,
                child: Transform(
                    transform: Matrix4.skewX(-0.2),
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 2, 12, 3),
                        color: _red,
                        child: Transform(
                            transform: Matrix4.skewX(0.2),
                            child: Text(title, style: _brush(12.5)))))),
          // The frame's red splashes sit in its top-left and bottom-right
          // corners: the content stays clear of them.
          Positioned.fill(
              child: Padding(
                  padding: const EdgeInsets.only(left: 22, top: 8, bottom: 2),
                  child: Stack(clipBehavior: Clip.none, children: kids))),
        ]),
      ),
    );

/// A chip on paper: the one chosen red, the rest inked, a locked one faint.
Widget _paperChip(String text, {bool chosen = false, bool locked = false}) =>
    Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Transform(
        transform: Matrix4.skewX(-0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: chosen ? _red : Colors.transparent,
              border: Border.all(
                  color: chosen
                      ? _red
                      : _inkText.withValues(alpha: locked ? 0.3 : 0.9),
                  width: 1.5)),
          child: Transform(
              transform: Matrix4.skewX(0.2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (locked)
                  Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_outline,
                          size: 11, color: _inkText.withValues(alpha: 0.4))),
                Text(text,
                    style: _brush(12,
                        color: chosen
                            ? _paper
                            : _inkText.withValues(alpha: locked ? 0.4 : 1))),
              ])),
        ),
      ),
    );

/// A button on paper: the one that goes on red, the rest ink.
Widget _paperBtn(String text,
        {bool red = false, double w = 120, double h = 28, bool dim = false}) =>
    Transform(
      transform: Matrix4.skewX(-0.2),
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: red ? _red : _inkText,
            border: Border.all(color: red ? _red : _inkText)),
        child: Transform(
            transform: Matrix4.skewX(0.2),
            child: Text(text,
                style: _brush(h > 30 ? 14 : 12, color: dim ? _grey : _paper))),
      ),
    );

Widget _sMenu(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('bg', opacity: 1, top: 0, h: 330),
      Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: 330,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_black.withValues(alpha: 0), _black])))),
      _chibi('warrior', 100, 280),
      _chibi('mage', 250, 276),
      _at(22, 60, Text('NARRATIVE', style: _brush(34))),
      _at(
          24,
          106,
          Text('a game of dice and ink',
              style: _prose(13, italic: true, color: _grey))),
      for (final (i, (label, sub, red)) in [
        ('Continue', 'Edda · level 8 · the road to Alster', true),
        ('New game', '', false),
        ('Edit Mode', 'the tools behind the story', false),
        (_t('tower_menu'), _t('tower_menu_sub'), false),
        ('Settings', '', false),
      ].indexed)
        _paperPanel(16, 336 + i * 76.0, 328, 64,
            inset: 10,
            wash: red ? _red : null,
            kids: [
              if (label == _t('tower_menu'))
                Positioned(
                    left: 14,
                    top: 14,
                    bottom: 14,
                    child: Container(width: 4, color: _red)),
              Positioned(
                  left: label == _t('tower_menu') ? 32 : 24,
                  top: 0,
                  bottom: 0,
                  right: 24,
                  child: Row(children: [
                    if (label == _t('tower_menu')) ...[
                      const Icon(Icons.castle_outlined,
                          size: 22, color: _inkText),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(label,
                              style:
                                  _brush(18, color: red ? _paper : _inkText)),
                          if (sub.isNotEmpty)
                            Text(sub,
                                style: _sys(9,
                                    color: red
                                        ? _paper
                                        : const Color(0xFF394A50))),
                        ])),
                  ])),
            ]),
    ]);

Widget _sStart(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_band1', opacity: 0.22, top: 60, h: 660),
      _tTitle(_t('tower_name'), _t('tower_tagline'), back: true),
      _paperPanel(14, 90, 332, 66, title: _t('tower_marks_name'), kids: [
        Positioned(
            left: 22,
            top: 14,
            right: 22,
            child: Row(children: [
              Text('120', style: _brush(28, color: _inkText)),
              const SizedBox(width: 6),
              Text('marks', style: _sys(10, color: const Color(0xFF394A50))),
              const Spacer(),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_t('tower_best', {'n': '14'}),
                        style: _prose(12, color: _inkText, bold: true)),
                    Text(_t('tower_runs_line', {'r': '9', 'w': '3'}),
                        style: _sys(9, color: const Color(0xFF394A50))),
                  ]),
            ])),
      ]),
      _poly(
          const [
            Offset(8, 176),
            Offset(352, 168),
            Offset(352, 282),
            Offset(8, 282)
          ],
          'tower_band2',
          -80,
          2,
          [
            _chibi('warrior', 78, 278),
            _at(
                112,
                176,
                Container(
                    width: 236,
                    height: 104,
                    color: _black.withValues(alpha: 0.82))),
            _at(
                120,
                184,
                Text(_t('tower_floor_of', {'n': '7', 'm': '30'}),
                    style: _brush(18))),
            _at(
                120,
                210,
                Text('Edda · Human · Warrior',
                    style: _prose(12, color: _grey))),
            _at(120, 232, _bar(41, 52, 130)),
            _at(196, 238, _btn(_t('tower_continue'), red: true, w: 148, h: 30)),
          ]),
      _paperPanel(14, 316, 332, 280, title: 'New climb', kids: [
        for (final (i, (g, items)) in [
          (_t('tower_pick_race'), ['Human', 'Elf', 'Dwarf', 'Orc']),
          (_t('tower_pick_profession'), ['Warrior', 'Rogue', 'Cleric']),
          (_t('tower_pick_clan'), ['Dominion', 'Salt Crows', 'Vigil']),
        ].indexed)
          Positioned(
              left: 24,
              top: 24 + i * 68.0,
              right: 20,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g, style: _sys(10, color: const Color(0xFF394A50))),
                    const SizedBox(height: 4),
                    Row(children: [
                      for (final (j, it) in items.indexed)
                        _paperChip(it,
                            chosen: j == 0,
                            locked: j == items.length - 1 && i > 0),
                    ]),
                  ])),
        Positioned(
            left: 24,
            right: 20,
            top: 232,
            child: Text(_t('tower_save_note'),
                style:
                    _prose(11, italic: true, color: const Color(0xFF394A50)))),
      ]),
      _at(60, 626, _btn(_t('tower_climb'), red: true, w: 240, h: 44)),
    ]);

/// The calling pick (the main game's race and profession screen, reused).
Widget _sCreate(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _tTitle(_t('tower_pick_profession'), _t('tower_hint_people'), back: true),
      // the three cards as slanted panels
      for (final (i, (key, name, line, locked)) in [
        (
          'warrior',
          'Warrior',
          'Strikes first, takes a blow. Dice of iron.',
          false
        ),
        ('cleric', 'Cleric', 'Heals, wards, judges. Dice of light.', false),
        ('mage', 'Mage', 'Spells and the void. Dice of crystal.', true),
      ].indexed)
        _poly(_quad(10, 84 + i * 200.0, 350, 268 + i * 200.0, 10, -8), 'bg',
            -60 - i * 120.0, 1, [
          _chibi(key, 80, 262 + i * 200.0, u: 2.4),
          _at(
              142,
              98 + i * 200.0,
              Container(
                  width: 204,
                  height: 150,
                  color: _black.withValues(alpha: 0.78))),
          _at(150, 112 + i * 200.0, Text(name, style: _brush(24))),
          _at(150, 148 + i * 200.0,
              SizedBox(width: 190, child: Text(line, style: _prose(12.5)))),
          _at(
              150,
              206 + i * 200.0,
              locked
                  ? _btn('Locked · 80 marks', w: 150, h: 28, dim: true)
                  : _btn(i == 0 ? 'Chosen' : 'Choose',
                      red: i == 0, w: 110, h: 28)),
        ]),
    ]);

Widget _floorChrome(int floor, String sub) => Stack(children: [
      _tTitle(_t('tower_name'), sub, leave: true),
      _ladder(floor),
    ]);

Widget _sFloor(List<_Foe> foes) {
  const l = 50.0, r = 354.0;
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _floorChrome(
        7, '${_t('tower_floor_of', {'n': '7', 'm': '30'})} · the night rooms'),
    _poly(
        [
          const Offset(l, 80),
          const Offset(r, 80),
          const Offset(r, 250),
          const Offset(l, 276)
        ],
        'tower_band1',
        -20,
        2,
        [
          _chibi('inquisition_warden', 120, 252),
          _chibi('white_soldier', 252, 262),
          _at(l + 8, 88, Text(_t('tower_foes'), style: _sys(9, color: _paper))),
          _at(62, 106, _plate(foes[0], width: 124)),
          _at(206, 106, _plate(foes[2], width: 140)),
        ]),
    _poly(
        [
          const Offset(l, 292),
          const Offset(r, 266),
          const Offset(r, 392),
          const Offset(l, 392)
        ],
        'tower_band2',
        -300,
        2,
        [
          _chibi('warrior', 100, 378),
          _at(l + 70, 322, _heroPlate('Edda', 41, 52, turn: true, width: 120)),
          _at(
              l + 70,
              366,
              Text('${_t('tower_your_health')} 41 / 52',
                  style: _sys(9, color: _paper))),
        ]),
    _tPanel(l, 408, r - l, 38, title: _t('tower_oaths_label'), kids: [
      Positioned(
          left: 12,
          top: 10,
          child: Text(_t('tower_unsworn'),
              style: _prose(12, italic: true, color: _grey))),
    ]),
    _dicePanel(l, 466, r - l, matches: false, dice: _fireDice),
    _at(60, 664, _btn(_t('tower_fight'), red: true, w: 236, h: 42)),
    _at(
        54,
        716,
        SizedBox(
            width: 300,
            child: Text(_t('tower_fight_ground', {'n': '7'}),
                style: _prose(10.5, italic: true, color: _grey)))),
  ]);
}

Widget _sShortcut(List<_Foe> foes) {
  const l = 50.0, r = 354.0;
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _floorChrome(
        7, '${_t('tower_floor_of', {'n': '7', 'm': '30'})} · a choice'),
    _poly(
        [
          const Offset(l, 80),
          const Offset(r, 80),
          const Offset(r, 214),
          const Offset(l, 238)
        ],
        'tower_band2',
        -40,
        2,
        [
          _chibi('inquisition_warden', 130, 214),
          _chibi('white_soldier', 252, 222),
        ]),
    _tPanel(l, 262, r - l, 206,
        title: _t('tower_event_shortcut'),
        red: true,
        kids: [
          Positioned(
              left: 14,
              top: 16,
              right: 14,
              child: Text(_t('tower_event_shortcut_title'), style: _brush(19))),
          Positioned(
              left: 14,
              top: 46,
              right: 14,
              child: Text(_t('tower_event_shortcut_body'), style: _prose(13))),
          Positioned(
              left: 14,
              top: 98,
              right: 14,
              child: Text(
                  '${_t('tower_event_shortcut_win')}: ${_t('tower_event_shortcut_win_many', {
                        'a': '8',
                        'b': '9',
                        'to': '10'
                      })}',
                  style: _prose(12, color: _grey))),
          Positioned(
              left: 14,
              top: 128,
              right: 14,
              child: Text(
                  '${_t('tower_event_shortcut_lose')}: ${_t('tower_event_shortcut_lose_text')}',
                  style: _prose(12, color: _red, italic: true))),
          Positioned(
              left: 8,
              bottom: 14,
              child: _btn(_t('tower_event_shortcut_take'),
                  red: true, w: 134, h: 34)),
          Positioned(
              right: 12,
              bottom: 14,
              child: _btn(_t('tower_event_shortcut_decline'), w: 120, h: 34)),
        ]),
    _tPanel(l, 488, r - l, 70, title: _t('tower_your_health'), kids: [
      Positioned(
          left: 12,
          top: 18,
          child: _heroPlate('Edda', 41, 52, turn: true, width: 130)),
      Positioned(
          left: 168,
          top: 22,
          child: Text('${_t('tower_oaths_label')}: ${_t('tower_unsworn')}',
              style: _prose(11, italic: true, color: _grey))),
    ]),
    _at(60, 664, _btn(_t('tower_fight'), w: 236, h: 42, dim: true)),
    _at(
        54,
        716,
        SizedBox(
            width: 300,
            child: Text('Choose the stair or the door first.',
                style: _prose(10.5, italic: true, color: _grey)))),
  ]);
}

Widget _sParley(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_parley', opacity: 0.55, top: 70, h: 640),
      _floorChrome(
          12, '${_t('tower_floor_of', {'n': '12', 'm': '30'})} · a guardian'),
      _tPanel(50, 380, 304, 214, title: _t('tower_parley'), red: true, kids: [
        Positioned(
            left: 14,
            top: 18,
            right: 14,
            child: Text(_t('tower_parley_title'), style: _brush(19))),
        Positioned(
            left: 14,
            top: 50,
            right: 14,
            child: Text(_t('tower_parley_body'), style: _prose(13))),
        Positioned(
            left: 14,
            top: 98,
            right: 14,
            child: Row(children: [
              Text('62 %', style: _brush(26, color: _red)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      _t('tower_event_chance', {'mod': '+2', 'dc': '10'}),
                      style: _sys(9))),
            ])),
        Positioned(
            left: 14,
            top: 140,
            right: 14,
            child: Text('Sworn oaths make it kneel: no roll.',
                style: _prose(11, italic: true, color: _grey))),
        Positioned(
            left: 10,
            bottom: 14,
            child: _btn(_t('tower_parley_talk'), red: true, w: 120, h: 34)),
        Positioned(
            right: 14,
            bottom: 14,
            child: _btn(_t('tower_parley_fight'), w: 120, h: 34)),
      ]),
    ]);

Widget _sStall(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_shop', opacity: 0.5, top: 70, h: 640),
      _floorChrome(
          12, '${_t('tower_floor_of', {'n': '12', 'm': '30'})} · a stall'),
      _tPanel(50, 250, 304, 400, title: _t('tower_merchant'), kids: [
        Positioned(
            left: 14,
            top: 18,
            right: 14,
            child: Text(_t('tower_merchant_title'), style: _brush(19))),
        Positioned(
            left: 14,
            top: 48,
            right: 14,
            child: Text(_t('tower_merchant_body'), style: _prose(12.5))),
        Positioned(
            left: 14,
            top: 100,
            right: 14,
            child: Text(_t('tower_merchant_wallet', {'n': '120'}),
                style: _sys(10, color: _paper))),
        for (final (i, (name, text, price)) in [
          (
            _t('tower_merchant_salve'),
            _t('tower_merchant_salve_text', {'n': '30'}),
            '40'
          ),
          (
            _t('tower_merchant_potions'),
            _t('tower_merchant_potions_text', {'n': '2'}),
            '60'
          ),
        ].indexed)
          Positioned(
              left: 10,
              right: 10,
              top: 132 + i * 100.0,
              child: SizedBox(
                height: 90,
                child: Stack(children: [
                  _frame(284, 90, inset: 8, fill: 0.8),
                  Positioned(
                      left: 14,
                      top: 12,
                      child: _placeholder(40, label: 'item')),
                  Positioned(
                      left: 66,
                      top: 10,
                      right: 12,
                      child: Text(name, style: _brush(15))),
                  Positioned(
                      left: 66,
                      top: 34,
                      right: 100,
                      child: Text(text, style: _prose(11, color: _grey))),
                  Positioned(
                      right: 12,
                      bottom: 10,
                      child: Row(children: [
                        Text(_t('tower_merchant_price', {'n': price}),
                            style: _sys(9, color: _paper)),
                        const SizedBox(width: 8),
                        _btn(_t('tower_merchant_buy'),
                            red: i == 0, w: 64, h: 24),
                      ])),
                ]),
              )),
        Positioned(
            left: 40,
            bottom: 14,
            child: _btn(_t('tower_merchant_leave'), w: 210, h: 32)),
      ]),
    ]);

Widget _sBargain(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_bargain', opacity: 0.55, top: 70, h: 640),
      _floorChrome(
          17, '${_t('tower_floor_of', {'n': '17', 'm': '30'})} · a bargain'),
      _tPanel(50, 330, 304, 300, title: _t('tower_bargain'), red: true, kids: [
        Positioned(
            left: 14,
            top: 18,
            right: 14,
            child: Text(_t('tower_bargain_title'), style: _brush(19))),
        Positioned(
            left: 14,
            top: 48,
            right: 14,
            child: Text(_t('tower_bargain_body'), style: _prose(12.5))),
        Positioned(
            left: 14,
            top: 120,
            right: 14,
            child:
                Text(_t('tower_bargain_gain'), style: _sys(10, color: _paper))),
        Positioned(
            left: 14,
            top: 138,
            right: 14,
            child: Text(_t('tower_bargain_gain_text', {'stat': 'Strength'}),
                style: _prose(12, color: _paper))),
        Positioned(
            left: 14,
            top: 172,
            right: 14,
            child:
                Text(_t('tower_bargain_cost'), style: _sys(10, color: _red))),
        Positioned(
            left: 14,
            top: 190,
            right: 14,
            child: Text(_t('tower_bargain_cost_text', {'n': '5'}),
                style: _prose(12, color: _grey))),
        Positioned(
            left: 10,
            bottom: 14,
            child: _btn(_t('tower_bargain_accept'), red: true, w: 132, h: 34)),
        Positioned(
            right: 14,
            bottom: 14,
            child: _btn(_t('tower_bargain_refuse'), w: 120, h: 34)),
      ]),
    ]);

Widget _sBoss(List<_Foe> foes) {
  const l = 50.0, r = 354.0;
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _floorChrome(
        10, '${_t('tower_floor_of', {'n': '10', 'm': '30'})} · ${'the boss'}'),
    _poly(
        [
          const Offset(l, 80),
          const Offset(r, 80),
          const Offset(r, 330),
          const Offset(l, 362)
        ],
        'tower_boss10',
        -60,
        2,
        [
          Positioned(
              left: l + 14,
              top: 110,
              child: Transform(
                  transform: Matrix4.skewX(-0.2),
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 3, 14, 3),
                      color: _red,
                      child: Transform(
                          transform: Matrix4.skewX(0.2),
                          child: Text('FLOOR 10 · BOSS', style: _brush(14)))))),
          _chibi('void_sovereign', 200, 338),
          _at(l + 12, 150,
              _plate(foes[1], width: 120, aimed: true, matching: 'Light')),
        ]),
    _tPanel(l, 380, r - l, 52, kids: [
      Positioned(
          left: 12,
          top: 8,
          right: 12,
          child: Text(
              'The Sovereign drinks the light of the first blow: strike it once with Light and it falters.',
              style: _prose(11.5, italic: true))),
    ]),
    _poly(
        [
          const Offset(l, 448),
          const Offset(r, 448),
          const Offset(r, 520),
          const Offset(l, 520)
        ],
        'tower_band2',
        -280,
        2,
        [
          _chibi('warrior', 100, 516),
          _at(l + 70, 470, _heroPlate('Edda', 41, 52, turn: true, width: 120)),
        ]),
    _dicePanel(l, 534, r - l, strip: false),
    _at(60, 686, _btn(_t('tower_fight'), red: true, w: 236, h: 42)),
  ]);
}

Widget _sFight(List<_Foe> foes) {
  Offset p(double x, double y) => Offset(_x(x), y);
  final p1 = [p(0, 100), p(360, 100), p(360, 296), p(0, 326)];
  final p2 = [p(0, 340), p(360, 310), p(360, 470), p(0, 470)];
  final p3 = [p(0, 482), p(360, 482), p(360, 620), p(0, 620)];
  Widget panel(List<Offset> pts, String bg, double bgDy, List<Widget> scene) =>
      Stack(children: [
        ClipPath(
            clipper: _PanelClipper(pts),
            child: Stack(children: [
              Positioned(left: 0, top: bgDy, child: _pic(bg)),
              ...scene
            ])),
        CustomPaint(size: Size(_w * _k, _h), painter: _PanelBorder(pts)),
      ]);
  return Stack(children: [
    Positioned.fill(child: Container(color: _black)),
    _at(14, 8, Text('Floor 7 · The Ashen Tower', style: _brush(21))),
    _at(14, 36, Text('open stair · Round 2', style: _sys(9))),
    // a short climb strip in place of the ladder: 30 ticks, seven climbed
    _at(
        14,
        58,
        Row(children: [
          for (var i = 1; i <= 30; i++)
            Container(
                width: _x(9.4),
                height: i % 10 == 0 ? 20 : 14,
                margin:
                    EdgeInsets.only(right: _x(1.6), top: i % 10 == 0 ? 0 : 6),
                decoration: BoxDecoration(
                    color: i < 7 ? _grey : (i == 7 ? _red : _black),
                    border: Border.all(
                        color: i % 10 == 0
                            ? _red
                            : _grey.withValues(alpha: 0.6)))),
        ])),
    panel(p1, 'bg', -30, [
      Positioned(
          left: _x(262 - 64),
          top: 296 - 100 - 6,
          child: _pic('hit', opacity: 0.9)),
      _chibi('inquisition_warden', _x(110), 300),
      _chibi('white_soldier', _x(262), 296),
      Positioned.fill(
          child: CustomPaint(painter: _SpeedLines(Offset(_x(262), 236)))),
      _at(_x(8), 108, _plate(foes[0], width: _x(150))),
      _at(_x(200), 108,
          _plate(foes[2], width: _x(150), aimed: true, matching: 'Fire')),
    ]),
    panel(p2, 'bg', 30, [
      _chibi('warrior', _x(70), 434),
      _at(_x(120), 400, _heroPlate('Edda', 41, 52, turn: true, width: _x(150))),
      _at(_x(120), 438,
          Text('Level 7 · the Tower hero', style: _sys(9, color: _paper))),
    ]),
    panel(p3, 'bg', 0, [
      _at(
          _x(4),
          496,
          _dieCell(_fireDice[0], _x(112),
              selected: true, matches: true, size: 52)),
      _at(_x(124), 496, _dieCell(_fireDice[1], _x(112), size: 52)),
      _at(_x(244), 496, _dieCell(_fireDice[2], _x(112), size: 52)),
    ]),
    _at(0, 624, _faceStrip(_fireDice[0], _w * _k)),
    _at(0, 654, _hint(foes[2].name, _w * _k - 108, 'Fire')),
    _hand(top: 682, h: 96, w: _k == 1 ? 100 : 97, cards: _fireCards),
    _strike(top: 654, left: _x(256)),
  ]);
}

Widget _sSpoils(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_band2', opacity: 0.25, top: 70, h: 640),
      _floorChrome(
          7,
          '${_t('tower_floor_of', {
                'n': '7',
                'm': '30'
              })} · ${_t('tower_cleared', {'n': '7'})}'),
      _tPanel(50, 100, 304, 520,
          title: _t('tower_spoils_title', {'n': '7'}),
          kids: [
            Positioned(
                left: 14,
                top: 22,
                right: 14,
                child: Text('The silver chest', style: _brush(19))),
            Positioned(
                left: 14,
                top: 50,
                right: 14,
                child: Text(
                    'No gold in the Tower: only what you can wear or drink.',
                    style: _prose(11.5, italic: true, color: _grey))),
            for (final (i, (name, note, tag)) in [
              (
                'Knuckle wrap',
                'ATK +3 · beats the one you wear',
                _t('tower_spoils_worn')
              ),
              ('Antidote', 'Cures poison · 1', _t('tower_spoils_bag')),
              (
                'Knucklebone',
                'A charm. Rattles when a foe is near.',
                _t('tower_spoils_bag')
              ),
            ].indexed)
              Positioned(
                  left: 10,
                  right: 10,
                  top: 86 + i * 104.0,
                  child: SizedBox(
                    height: 94,
                    child: Stack(children: [
                      _frame(284, 94, inset: 8, fill: 0.8),
                      Positioned(
                          left: 14,
                          top: 18,
                          child: _placeholder(54, label: 'item art')),
                      Positioned(
                          left: 80,
                          top: 12,
                          right: 12,
                          child: Text(name, style: _brush(16))),
                      Positioned(
                          left: 80,
                          top: 38,
                          right: 12,
                          child: Text(note, style: _prose(11, color: _grey))),
                      Positioned(
                          left: 80,
                          bottom: 10,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              color: i == 0 ? _red : _dark,
                              child: Text(tag, style: _sys(8, color: _paper)))),
                    ]),
                  )),
            Positioned(
                left: 40,
                bottom: 18,
                child: _btn(_t('tower_take'), red: true, w: 210, h: 40)),
          ]),
    ]);

Widget _sOffer(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_band2', opacity: 0.22, top: 70, h: 640),
      _floorChrome(
          7,
          '${_t('tower_floor_of', {
                'n': '7',
                'm': '30'
              })} · ${_t('tower_choose_one')}'),
      for (final (i, (kind, name, text, glyph)) in [
        (
          _t('tower_kind_die'),
          'Oak die',
          'A d8 with a heal and a ward. It resonates with your clan.',
          'quick_heal'
        ),
        (
          _t('tower_kind_skill'),
          'Radiant Judgment',
          'A Light blow that the Sovereign fears.',
          'radiant_judgment'
        ),
        (
          _t('tower_kind_oath'),
          'Oath of Ash',
          'Swear: one point where you strike, a tenth less health.',
          'warrior_iron_stance'
        ),
      ].indexed)
        Positioned(
            left: 52.0 + (i == 0 ? 0 : 0),
            top: 100 + i * 172.0,
            child: SizedBox(
              width: 300,
              height: 160,
              child: Stack(children: [
                _frame(300, 160, inset: 12, fill: 0.9),
                if (i == 1)
                  Positioned.fill(
                      child: IgnorePointer(
                          child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                  border: Border.all(color: _red, width: 2))))),
                Positioned(
                    left: 18, top: 20, child: _glyph(glyph, 44, lit: i == 1)),
                Positioned(
                    left: 78,
                    top: 18,
                    right: 16,
                    child: Text(kind,
                        style: _sys(9, color: i == 1 ? _red : _grey))),
                Positioned(
                    left: 78,
                    top: 34,
                    right: 16,
                    child: Text(name, style: _brush(17))),
                Positioned(
                    left: 20,
                    top: 82,
                    right: 18,
                    child: Text(text, style: _prose(12))),
              ]),
            )),
      _at(52, 624, _btn(_t('tower_take'), red: true, w: 104, h: 40)),
      _at(166, 624, _btn(_t('tower_refuse'), w: 188, h: 40)),
      _at(
          52,
          676,
          SizedBox(
              width: 300,
              child: Text('Leave them all for a mark.',
                  style: _prose(11, italic: true, color: _grey)))),
    ]);

Widget _sLevelUp(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _tTitle('Level up', 'the Tower hero', back: true),
      _poly(_quad(10, 84, 350, 232, 10, -8), 'bg', -50, 1, [
        _chibi('warrior', 78, 226, u: 2.4),
        _at(
            122,
            98,
            Container(
                width: 224,
                height: 124,
                color: _black.withValues(alpha: 0.78))),
        _at(130, 112, Text('Level 8', style: _brush(30))),
        _at(130, 156, Text('XP 140 / 300', style: _sys(10, color: _paper))),
        _at(
            130,
            176,
            SizedBox(
                width: 190,
                child: Stack(children: [
                  Container(height: 6, color: const Color(0xFF2A2C34)),
                  FractionallySizedBox(
                      widthFactor: 0.47,
                      child: Container(height: 6, color: _red))
                ]))),
        _at(130, 196,
            Text('2 points to place', style: _prose(12, italic: true))),
      ]),
      for (final (i, (name, v, line)) in [
        ('Strength', '9', 'Hits harder, carries more.'),
        ('Dexterity', '7', 'Faster, harder to hit.'),
        ('Wisdom', '5', 'Reads the foe; the d20 tests lean on it.'),
        ('Vigour', '8', 'Health on every level.'),
      ].indexed)
        _slotBox(14, 256 + i * 88.0, 332, 78, kids: [
          Positioned(left: 16, top: 12, child: Text(name, style: _brush(17))),
          Positioned(
              left: 16,
              top: 38,
              child: SizedBox(
                  width: 190,
                  child: Text(line, style: _prose(11, color: _grey)))),
          Positioned(
              right: 70,
              top: 14,
              child: Text(v, style: _brush(26, color: i == 0 ? _red : _paper))),
          Positioned(
              right: 16, top: 20, child: _btn('+', red: i == 0, w: 36, h: 30)),
        ]),
      _at(60, 640, _btn(_t('tower_continue'), red: true, w: 240, h: 44)),
    ]);

Widget _sEnd(bool won) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _poly(
          [
            Offset.zero,
            const Offset(360, 0),
            const Offset(360, 330),
            const Offset(0, 370)
          ],
          won ? 'tower_win' : 'tower_lose',
          won ? -60 : -120,
          2,
          [
            _chibi('warrior', 180, 318),
            _at(
                0,
                24,
                Container(
                    width: 360,
                    height: 128,
                    color: _black.withValues(alpha: 0.78))),
            _at(
                20,
                38,
                SizedBox(
                    width: 320,
                    child: Text(
                        won
                            ? _t('tower_victory')
                            : _t('tower_death', {'n': '7'}),
                        style: _brush(21)))),
          ]),
      _paperPanel(14, 396, 332, 186,
          title: _t('tower_earned', {'n': won ? '210' : '14'}),
          kids: [
            Positioned(
                left: 26,
                top: 22,
                right: 26,
                child: Column(children: [
                  for (final (k, v, red) in [
                    ('Floors climbed', won ? '30' : '7', false),
                    ('Bosses beaten', won ? '3' : '0', false),
                    ('Dice rolled', won ? '212' : '41', false),
                    ('Marks earned', won ? '+210' : '+14', true),
                  ]) ...[
                    Row(children: [
                      Text(k, style: _sys(10, color: const Color(0xFF394A50))),
                      const Spacer(),
                      Text(v,
                          style: _prose(13,
                              color: red ? _red : _inkText, bold: true)),
                    ]),
                    const SizedBox(height: 7),
                  ],
                  Container(height: 1, color: _inkText.withValues(alpha: 0.4)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Text(_t('tower_marks_name'),
                        style: _sys(10, color: const Color(0xFF394A50))),
                    const Spacer(),
                    Text(won ? '330' : '134',
                        style: _prose(13, color: _inkText, bold: true)),
                  ]),
                ])),
          ]),
      if (won)
        _paperPanel(14, 604, 332, 56, title: 'Unlocked', kids: [
          Positioned(
              left: 24,
              top: 18,
              right: 20,
              child: Text(_t('tower_unlock_tide_die'),
                  style: _prose(12.5, color: _inkText, bold: true))),
        ]),
      _at(14, 686, _btn(_t('tower_marks_button'), w: 156, h: 40)),
      _at(190, 686, _btn(_t('tower_climb_again'), red: true, w: 156, h: 40)),
    ]);

Widget _sMarks(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _ground('tower_band3', opacity: 0.18, top: 60, h: 660),
      _tTitle(_t('tower_marks_title'), _t('tower_marks_name'), back: true),
      _paperPanel(14, 88, 332, 60, kids: [
        Positioned(
            left: 26,
            top: 12,
            child: Text('134', style: _brush(30, color: _inkText))),
        Positioned(
            left: 92,
            top: 24,
            child: Text('marks in hand',
                style: _sys(10, color: const Color(0xFF394A50)))),
        Positioned(
            right: 24,
            top: 22,
            child: Text(_t('tower_best', {'n': '14'}),
                style: _prose(12, color: _inkText, bold: true))),
      ]),
      for (final (gi, (group, rows)) in [
        (
          _t('tower_group_peoples'),
          [
            (_t('tower_unlock_cleric'), '80', 'Buy'),
            (_t('tower_unlock_ranger'), '120', 'Buy')
          ]
        ),
        (
          _t('tower_group_clans'),
          [
            (_t('tower_unlock_crows'), '150', 'Buy'),
            (_t('tower_unlock_vigil'), '150', 'Owned')
          ]
        ),
        (
          _t('tower_group_kit'),
          [
            (_t('tower_unlock_flame_die'), '60', 'Owned'),
            (_t('tower_unlock_tide_die'), '200', 'Buy')
          ]
        ),
      ].indexed)
        _paperPanel(14, 176 + gi * 172.0, 332, 156, title: group, kids: [
          for (final (ri, (name, cost, state)) in rows.indexed)
            Positioned(
                left: 24,
                right: 22,
                top: 22 + ri * 62.0,
                child: SizedBox(
                  height: 56,
                  child: Stack(children: [
                    Positioned.fill(
                        child: Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: _inkText.withValues(
                                            alpha: 0.25)))))),
                    Positioned(
                        left: 0,
                        top: 6,
                        right: 96,
                        child:
                            Text(name, style: _brush(13.5, color: _inkText))),
                    Positioned(
                        left: 0,
                        top: 32,
                        child: Text(_t('tower_marks_cost', {'n': cost}),
                            style: _sys(9, color: const Color(0xFF394A50)))),
                    Positioned(
                        right: 0,
                        top: 12,
                        child: state == 'Owned'
                            ? Text('Owned',
                                style: _brush(12,
                                    color: _inkText.withValues(alpha: 0.45)))
                            : _paperBtn(state,
                                red: cost == '80', w: 76, h: 28)),
                  ]),
                )),
        ]),
    ]);

Widget _sCompare(List<_Foe> foes) => Stack(children: [
      Positioned.fill(child: Container(color: _black)),
      _at(
          14,
          10,
          Text('tower_band1: the recolour and Art\'s painted ink',
              style: _brush(20))),
      _at(
          14,
          40,
          Text(
              'left: today\'s PixelLab plate mapped to the ink greys (the placeholder in every picture); right: Art\'s redraw snapped to the same greys',
              style: _sys(9))),
      _at(0, 70, _pic('tower_band1', scale: 2)),
      _at(360, 70, _pic('art_band1', scale: 2)),
      _at(14, 716,
          Text('recolour (placeholder)', style: _prose(13, italic: true))),
      _at(374, 716,
          Text('painted ink sample (Art)', style: _prose(13, italic: true))),
    ]);

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the Tower in ink, version A', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(() async {
      await _load('bg', '$_art/ink_background.png');
      await _load('frame', '$_art/ink_frame.png');
      await _load('wide', 'docs/ux-shots/tower-ink/art/ink_wideframe.png');
      await _load(
          'art_band1', 'docs/ux-shots/tower-ink/art/ink_tower_band1.png');
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
      for (final n in [
        'tower_band1',
        'tower_band2',
        'tower_band3',
        'tower_boss10',
        'tower_parley',
        'tower_shop',
        'tower_bargain',
        'tower_win',
        'tower_lose'
      ]) {
        await _load(n, '$_tw/$n.png');
      }
    });
    final foes = _foes(enemies);
    for (final (name, build, width)
        in <(String, Widget Function(List<_Foe>), double)>[
      ('01-menu', _sMenu, 360),
      ('02-start', _sStart, 360),
      ('03-calling', _sCreate, 360),
      ('04-floor', _sFloor, 360),
      ('05-shortcut', _sShortcut, 360),
      ('06-parley', _sParley, 360),
      ('07-stall', _sStall, 360),
      ('08-bargain', _sBargain, 360),
      ('09-boss', _sBoss, 360),
      ('10-fight', _sFight, 360),
      ('10-fight-320', _sFight, 320),
      ('11-spoils', _sSpoils, 360),
      ('12-offer', _sOffer, 360),
      ('13-levelup', _sLevelUp, 360),
      ('14-death', (f) => _sEnd(false), 360),
      ('15-victory', (f) => _sEnd(true), 360),
      ('16-marks', _sMarks, 360),
      ('17-band1-compare', _sCompare, 720),
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
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
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
