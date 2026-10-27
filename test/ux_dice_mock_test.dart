// More dice sizes and styles, with their animations (UX mock, for the user to
// approve before anything is built; Core writes the sizes and rules in
// docs/proposals/dice-sizes.md). Three pictures:
//   dice-family-mock.png  the shapes side by side, at the same scale and at
//                         the fight's size; the styles on one shape
//   dice-roll-mock.png    the roll as a storyboard, and how a critical, a
//                         fumble and a skill face are staged
//   dice-ui-mock.png      the fight's dice row and the character's dice slot
// The styles are the game's own DieSkin data (die_skins.dart: 34 skins,
// base, edge, pattern, glow) painted by its own DiePatternPainter, so any
// skin goes on any shape; the shapes are new, flat-shaded polygons (cheap on
// a phone). The d6 is today's Die3D in the fight.
// UX_SHOTS=<folder> takes the three pictures.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File('assets/fonts/$f').readAsBytesSync())
              .buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

const _bg = Color(0xFF17151B);
const _gold = Color(0xFFE2B890);
const _ash = Color(0xFF9A93A6);
const _line = Color(0xFF3A3642);

TextStyle _t(double size, {Color? c, bool bold = false, bool italic = false}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        height: 1.25,
        color: c ?? const Color(0xFFEDE6DC),
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal);

// ------------------------------------------------------------- the shapes

typedef _P = Offset;

/// A die shape: flat faces in a unit disc, the brightness of each, the face
/// the number is read on.
class _Shape {
  const _Shape(this.name, this.sides, this.faces, this.light, this.front);
  final String name;
  final int sides;
  final List<List<_P>> faces;
  final List<double> light;
  final int front;
}

List<_P> _ring(int n, double r, double start) => [
      for (var i = 0; i < n; i++)
        _P(math.cos(start + i * 2 * math.pi / n) * r,
            math.sin(start + i * 2 * math.pi / n) * r),
    ];

_Shape _d4() {
  const a = _P(0, -1), b = _P(0.9, 0.62), c = _P(-0.9, 0.62), p = _P(0, 0.12);
  return _Shape(
      'd4',
      4,
      [
        [a, b, p],
        [a, p, c],
        [p, b, c],
      ],
      [1.1, 0.8, 0.95],
      2);
}

_Shape _d6() {
  final top = [
    const _P(0, -1),
    const _P(0.87, -0.5),
    const _P(0, 0),
    const _P(-0.87, -0.5)
  ];
  final left = [
    const _P(-0.87, -0.5),
    const _P(0, 0),
    const _P(0, 1),
    const _P(-0.87, 0.5)
  ];
  final right = [
    const _P(0, 0),
    const _P(0.87, -0.5),
    const _P(0.87, 0.5),
    const _P(0, 1)
  ];
  return _Shape('d6', 6, [top, left, right], [1.18, 0.78, 0.95], 2);
}

_Shape _d8() {
  const t = _P(0, -1),
      r = _P(0.92, 0),
      b = _P(0, 1),
      l = _P(-0.92, 0),
      m = _P(0, 0.2);
  return _Shape(
      'd8',
      8,
      [
        [t, l, m],
        [t, m, r],
        [l, b, m],
        [m, b, r],
      ],
      [0.8, 1.15, 0.7, 0.95],
      3);
}

_Shape _d10() {
  const t = _P(0, -1),
      r = _P(0.82, -0.12),
      b = _P(0, 1),
      l = _P(-0.82, -0.12),
      m = _P(0, 0.12);
  return _Shape(
      'd10',
      10,
      [
        [t, l, m],
        [t, m, r],
        [l, b, r, m],
      ],
      [0.8, 1.15, 0.95],
      2);
}

_Shape _d12() {
  final inner = _ring(5, 0.5, -math.pi / 2);
  final outer = _ring(5, 1.0, -math.pi / 2);
  return _Shape(
      'd12',
      12,
      [
        for (var i = 0; i < 5; i++)
          [inner[i], inner[(i + 1) % 5], outer[(i + 1) % 5], outer[i]],
        inner,
      ],
      [1.15, 0.9, 0.7, 0.8, 1.0, 1.08],
      5);
}

_Shape _d20() {
  final tri = _ring(3, 0.5, -math.pi / 2);
  final hex = _ring(6, 1.0, -math.pi / 2);
  final faces = <List<_P>>[];
  final light = <double>[];
  for (var i = 0; i < 3; i++) {
    final t = tri[i], tn = tri[(i + 1) % 3];
    faces.add([t, hex[2 * i], hex[2 * i + 1]]);
    faces.add([t, hex[2 * i + 1], tn]);
    faces.add([tn, hex[2 * i + 1], hex[(2 * i + 2) % 6]]);
    light.addAll([1.1, 0.85, 0.7]);
  }
  faces.add(tri);
  light.add(1.0);
  return _Shape('d20', 20, faces, light, faces.length - 1);
}

final _shapes = [_d4(), _d6(), _d8(), _d10(), _d12(), _d20()];

Color _shade(Color c, double k) => k >= 1
    ? Color.lerp(c, Colors.white, (k - 1).clamp(0, 1) * 1.6)!
    : Color.lerp(c, Colors.black, (1 - k).clamp(0, 1) * 1.6)!;

/// A die: [shape] in [skin], [value] on its front face; the pose of one
/// frame of a roll: [angle] (turn), [sx] and [sy] (the tumble's foreshorten
/// and the bounce's squash), [glow] (0 to 1: the light a face gives).
class _DiePainter extends CustomPainter {
  _DiePainter(this.shape, this.skin, this.value,
      {this.angle = 0,
      this.sx = 1,
      this.sy = 1,
      this.glow = 0,
      this.flash = 0,
      this.blank = false});

  final _Shape shape;
  final DieSkin skin;
  final String value;
  final double angle;
  final double sx;
  final double sy;
  final double glow;
  final double flash;
  final bool blank;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.9;
    final c = size.center(Offset.zero);
    // The glow: a skin's own light, or a landed face's.
    final g = skin.glow;
    if (g != null || glow > 0) {
      canvas.drawCircle(
          c,
          r * (1.15 + glow * 0.35),
          Paint()
            ..shader = ui.Gradient.radial(c, r * (1.15 + glow * 0.35), [
              (g ?? const Color(0xFFF2C14E))
                  .withValues(alpha: 0.18 + glow * 0.45),
              Colors.transparent
            ]));
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.scale(r * sx, r * sy);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 / r
      ..strokeJoin = StrokeJoin.round
      ..color = skin.edge;
    for (var i = 0; i < shape.faces.length; i++) {
      final path = Path()..addPolygon(shape.faces[i], true);
      canvas.drawPath(path, Paint()..color = _shade(skin.base, shape.light[i]));
      // The mark cut into the faces, on the front one only (cheap).
      if (i == shape.front && skin.pattern != DiePattern.none) {
        canvas.save();
        canvas.clipPath(path);
        final b = path.getBounds();
        canvas.translate(b.left, b.top);
        DiePatternPainter(skin.pattern, skin.edge)
            .paint(canvas, Size(b.width, b.height));
        canvas.restore();
      }
      canvas.drawPath(path, edge);
    }
    canvas.restore();
    // The number on the front face, drawn at pixel size (text in a scaled
    // canvas is laid out in whole units and lands off its face).
    final front = shape.faces[shape.front];
    var cx = 0.0, cy = 0.0;
    for (final p in front) {
      cx += p.dx;
      cy += p.dy;
    }
    cx /= front.length;
    cy /= front.length;
    final at = c +
        Offset(cx * r * sx * math.cos(angle) - cy * r * sy * math.sin(angle),
            cx * r * sx * math.sin(angle) + cy * r * sy * math.cos(angle));
    final bright = skin.base.computeLuminance() > 0.45;
    final tp = TextPainter(
      text: TextSpan(
          text: blank ? '' : value,
          style: TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: r * 0.5 * math.min(sx, 1.0),
              height: 1,
              color: bright ? const Color(0xFF1B1710) : skin.edge)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
    if (flash > 0) {
      canvas.drawCircle(c, r * (0.9 + flash * 0.6),
          Paint()..color = Colors.white.withValues(alpha: (1 - flash) * 0.5));
    }
  }

  @override
  bool shouldRepaint(_DiePainter old) => true;
}

/// A coin: a disc with a rim and the face, [flip] foreshortens it.
class _CoinPainter extends CustomPainter {
  _CoinPainter(this.skin, {this.sy = 1, this.heads = true});
  final DieSkin skin;
  final double sy;
  final bool heads;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.9;
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, sy.abs().clamp(0.12, 1.0));
    canvas.drawCircle(
        Offset(0, r * 0.1), r, Paint()..color = _shade(skin.base, 0.6));
    canvas.drawCircle(Offset.zero, r, Paint()..color = skin.base);
    canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = skin.edge);
    // A crown for heads, a sword for tails.
    final p = Paint()..color = skin.edge;
    if (heads) {
      canvas.drawPath(
          Path()
            ..moveTo(-r * 0.45, r * 0.25)
            ..lineTo(-r * 0.5, -r * 0.3)
            ..lineTo(-r * 0.2, 0)
            ..lineTo(0, -r * 0.4)
            ..lineTo(r * 0.2, 0)
            ..lineTo(r * 0.5, -r * 0.3)
            ..lineTo(r * 0.45, r * 0.25)
            ..close(),
          p);
    } else {
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: r * 0.14, height: r * 1.0),
          p);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, r * 0.15), width: r * 0.55, height: r * 0.12),
          p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinPainter old) => true;
}

Widget _die(_Shape s, DieSkin skin, String v, double size,
        {double angle = 0,
        double sx = 1,
        double sy = 1,
        double glow = 0,
        double flash = 0,
        bool blank = false}) =>
    SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter: _DiePainter(s, skin, v,
              angle: angle,
              sx: sx,
              sy: sy,
              glow: glow,
              flash: flash,
              blank: blank)),
    );

Widget _coin(DieSkin skin, double size, {double sy = 1, bool heads = true}) =>
    SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CoinPainter(skin, sy: sy, heads: heads)));

Widget _title(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(s, style: _t(15, c: _gold, bold: true)),
    );

Widget _note(String s, {double w = 1000}) =>
    SizedBox(width: w, child: Text(s, style: _t(12, c: _ash)));

DieSkin _skin(String id) => dieSkins[id] ?? boneSkin;

// ---------------------------------------------------- picture 1: the family

const _values = {
  'd4': '3',
  'd6': '5',
  'd8': '7',
  'd10': '9',
  'd12': '11',
  'd20': '17'
};

Widget _family() {
  final bone = _skin('starter_die');
  const styles = [
    ('starter_die', 'Bone', 'every die today'),
    ('pilgrim_die', 'Worn wood', 'grain cut in the faces'),
    ('tobin_die', 'Brass', 'rivets in the corners'),
    ('shadow_die', 'Obsidian', 'a black lacquer, scratched'),
    ('tearglass_die', 'Tear-glass', 'cracked, and it glows'),
    ('flame_die', 'Ember', 'cracked, and it glows'),
  ];
  Widget labelled(Widget w, String a, [String? b]) => Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(children: [
          w,
          const SizedBox(height: 4),
          Text(a, style: _t(12.5)),
          if (b != null) Text(b, style: _t(10.5, c: _ash)),
        ]),
      );
  return Padding(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dice: the family, and what a style adds', style: _t(19)),
      const SizedBox(height: 4),
      _note(
          'Six shapes and a coin, the faces flat-shaded in a few polygons (cheap to draw on a phone). The styles are the game’s own skins (die_skins.dart: 34 of them today, on the cube): any skin goes on any shape.'),
      const SizedBox(height: 16),
      _title('The shapes, at the same scale'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final s in _shapes)
          labelled(
              _die(s, bone, _values[s.name]!, 92),
              s.name,
              switch (s.name) {
                'd4' => 'a tetrahedron',
                'd6' => 'the cube (today)',
                'd8' => 'an octahedron',
                'd10' => 'a kite',
                'd12' => 'a dodecahedron',
                _ => 'the forge’s d20',
              }),
        labelled(_coin(bone, 92), 'coin', 'heads or tails'),
      ]),
      const SizedBox(height: 22),
      _title(
          'At the fight’s size (a 44 px die, in the row of the party’s dice)'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final s in _shapes)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _die(s, bone, _values[s.name]!, 44),
          ),
        _coin(bone, 44),
        const SizedBox(width: 24),
        Text(
            'The number stays readable down to 34 px; below that the shape alone says the size.',
            style: _t(11.5, c: _ash, italic: true)),
      ]),
      const SizedBox(height: 22),
      _title(
          'Styles: each on one shape (the same skin data on a d8, a d12, a d20)'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (i, (id, name, note)) in styles.indexed)
          labelled(
              _die(
                  [
                    _shapes[2],
                    _shapes[4],
                    _shapes[5],
                    _shapes[2],
                    _shapes[5],
                    _shapes[4]
                  ][i],
                  _skin(id),
                  '7',
                  92),
              name,
              note),
        // A clan-marked die: its banner cut into the front face.
        labelled(
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(alignment: Alignment.center, children: [
                _die(_shapes[1], _skin('stone_die'), '', 92),
                Positioned(
                    top: 28,
                    right: 12,
                    child: SizedBox(
                        width: 26,
                        child: ClanFlag(factionId: 'vigil', height: 38))),
              ]),
            ),
            'Clan-marked',
            'the clan’s banner on its face'),
      ]),
      const SizedBox(height: 10),
      _note(
          'A style adds: the stone (colour of the faces), the colour of the edge, a mark cut into the faces, and for some a light the die gives off. It changes how a die looks, not what it does. The size (d4 to d20) changes the face count and how the die is read, and is Core’s rule.'),
    ]),
  );
}

// ----------------------------------------------------- picture 2: the roll

/// One frame of a roll: its time and what it is.
class _Frame {
  const _Frame(this.t, this.what, this.angle, this.sx, this.sy, this.dy,
      {this.glow = 0,
      this.flash = 0,
      this.dx = 0,
      this.blank = false,
      this.ghost = false});
  final String t;
  final String what;
  final double angle;
  final double sx;
  final double sy;
  final double dy;
  final double glow;
  final double flash;
  final double dx;
  final bool blank;
  final bool ghost;
}

Widget _cell(_Shape? s, DieSkin skin, String v, _Frame f,
    {bool coin = false, double size = 60}) {
  Widget body = coin
      ? _coin(skin, size, sy: f.sx)
      : _die(s!, skin, v, size,
          angle: f.angle,
          sx: f.sx,
          sy: f.sy,
          glow: f.glow,
          flash: f.flash,
          blank: f.blank);
  return SizedBox(
    width: 96,
    height: 108,
    child: Stack(alignment: Alignment.center, children: [
      // The floor's shadow.
      Positioned(
        bottom: 14,
        child: Container(
          width: 38 * (1 - f.dy.abs() * 0.5),
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withValues(alpha: 0.35 - f.dy.abs() * 0.2),
          ),
        ),
      ),
      Positioned(
        bottom: 18 + f.dy * 34,
        left: 18 + f.dx * 10,
        child: Stack(children: [
          if (f.ghost)
            Opacity(
                opacity: 0.25,
                child: Transform.translate(
                    offset: const Offset(-12, 8),
                    child: Transform.rotate(angle: -0.5, child: body))),
          body,
        ]),
      ),
    ]),
  );
}

Widget _strip(String title, String note, _Shape? s, DieSkin skin, String v,
    List<_Frame> frames,
    {bool coin = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(title),
      Text(note, style: _t(11.5, c: _ash)),
      const SizedBox(height: 6),
      Row(children: [
        for (final f in frames)
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF1D1B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _line)),
            child: Column(children: [
              _cell(s, skin, v, f, coin: coin),
              Text(f.t, style: _t(10.5, c: _gold, bold: true)),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: SizedBox(
                    width: 88,
                    height: 28,
                    child: Text(f.what,
                        textAlign: TextAlign.center, style: _t(9.5, c: _ash))),
              ),
            ]),
          ),
      ]),
    ]),
  );
}

// The poses of a polyhedron's roll: thrown, tumbling, bouncing, settling.
const _tumble = [
  _Frame('0.00 s', 'thrown: small, up', 0.4, 0.6, 0.6, 0.0, ghost: true),
  _Frame('0.15 s', 'at the top', 1.6, 0.8, 0.95, 1.0, ghost: true),
  _Frame('0.35 s', 'tumbling down', 3.1, 0.5, 1.0, 0.7, ghost: true),
  _Frame('0.55 s', 'first touch: squash', 4.4, 1.15, 0.8, 0.0),
  _Frame('0.70 s', 'a small bounce', 5.2, 0.92, 1.0, 0.3),
  _Frame('0.85 s', 'settles, rocks', 6.1, 1.0, 0.97, 0.0),
  _Frame('1.00 s', 'at rest, the face lit', 6.283, 1.0, 1.0, 0.0, glow: 0.3),
];

Widget _roll() {
  final bone = _skin('starter_die');
  final ember = _skin('flame_die');
  const rest = _Frame('', '', 0, 1, 1, 0);
  return Padding(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('The roll: about 1 s, tap to skip', style: _t(19)),
      const SizedBox(height: 4),
      _note(
          'Seven beats: the throw, the tumble, the bounce, the settle, the read. The whole roll stays under 1.2 s; a tap shows the result at once, and with reduced motion only the last frame is shown.'),
      const SizedBox(height: 14),
      _strip(
          'A polyhedron (d4, d8, d10, d12, d20): a spin, foreshortened by the turn, with a squash on the floor',
          'New, but cheap: one flat-shaded polygon set, a rotation, a scale for the tumble and a squash. No real 3D.',
          _shapes[2],
          bone,
          '7',
          _tumble),
      _strip(
          'The d6 stays what it is today: Die3D, the cube tumbling in perspective',
          'Existing: die_3d.dart. It already lands on the face rolled and lets go a burst fitted to what the face does.',
          _shapes[1],
          bone,
          '5',
          _tumble),
      _strip(
          'The coin: a flip, its width foreshortened to a line twice, then a wobble',
          'New, cheaper still: a disc scaled across its width.',
          null,
          bone,
          '',
          [
            const _Frame('0.00 s', 'thrown', 0, 0.9, 1, 0.0, ghost: true),
            const _Frame('0.15 s', 'edge-on', 0, 0.12, 1, 0.9),
            const _Frame('0.30 s', 'tails up', 0, 0.9, 1, 1.0),
            const _Frame('0.45 s', 'edge-on again', 0, 0.12, 1, 0.6),
            const _Frame('0.60 s', 'lands, squash', 0, 1.0, 0.85, 0.0),
            const _Frame('0.80 s', 'wobbles', 0, 0.8, 1, 0.1),
            const _Frame('1.00 s', 'heads, lit', 0, 1.0, 1, 0.0, glow: 0.3),
          ],
          coin: true),
      const SizedBox(height: 4),
      _title('The read: how the face is staged'),
      Text(
          'The last 0.2 s, the same shape, different beats. Each is cheap: a flash, an offset, a glow.',
          style: _t(11.5, c: _ash)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (title, frames, skin, v, note) in [
          (
            'A critical',
            [
              const _Frame('0.85 s', 'lands', 6.283, 1.0, 1.0, 0.0),
              const _Frame('0.92 s', 'a white flash', 6.283, 1.05, 1.05, 0.0,
                  flash: 0.35, glow: 0.8),
              const _Frame(
                  '1.0 s', 'held beat: gold ring', 6.283, 1.12, 1.12, 0.0,
                  glow: 1.0),
            ],
            bone,
            '20',
            'existing: the surge ring and the burst',
          ),
          (
            'A fumble',
            [
              const _Frame('0.85 s', 'lands', 6.283, 1.0, 1.0, 0.0),
              const _Frame('0.92 s', 'a shudder sideways', 6.283, 1.0, 1.0, 0.0,
                  dx: 1.2),
              const _Frame('1.0 s', 'dims, grey puff', 6.283, 0.96, 0.96, 0.0,
                  blank: true),
            ],
            bone,
            '1',
            'existing: the blank’s shudder and dust',
          ),
          (
            'A skill face',
            [
              const _Frame('0.85 s', 'lands', 6.283, 1.0, 1.0, 0.0),
              const _Frame('0.92 s', 'the die glows', 6.283, 1.06, 1.06, 0.0,
                  glow: 0.6),
              const _Frame('1.0 s', 'its icon rises', 6.283, 1.1, 1.1, 0.0,
                  glow: 0.9),
            ],
            ember,
            '!',
            'existing: the bigger burst of a skill face',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: _t(13, bold: true)),
              Text(note, style: _t(10.5, c: _ash, italic: true)),
              const SizedBox(height: 4),
              Row(children: [
                for (final f in frames)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1D1B22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _line)),
                    child: Column(children: [
                      _cell(_shapes[5], skin, v, f),
                      Text(f.t, style: _t(10.5, c: _gold, bold: true)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                        child: SizedBox(
                            width: 88,
                            height: 28,
                            child: Text(f.what,
                                textAlign: TextAlign.center,
                                style: _t(9.5, c: _ash))),
                      ),
                    ]),
                  ),
              ]),
            ]),
          ),
      ]),
      const SizedBox(height: 10),
      _title('Existing pieces and new ones'),
      _note(
          'Reused: the cube’s tumble and landing bursts (Die3D, DieFx), the surge ring, the blank’s shudder, skins and patterns (die_skins.dart), the d20 forge cast (d20_roll.dart) for a d20 shown large (the forge, a check), the sparks (pixel_vfx). New: the flat polyhedron painter and its tumble, the coin flip, the held beat at a critical (a 0.15 s pause before the read), the die’s own glow on a skill face.\nBudget: one CustomPaint of at most 20 polygons per die, one controller; nothing is rasterised. A party of six dice rolls at once without a dropped frame in a mock on a phone-class GPU (to be measured when built).'),
      const SizedBox(height: 4),
      Opacity(opacity: 0, child: _cell(_shapes[0], ember, '1', rest)),
    ]),
  );
}

// -------------------------------------------------------- picture 3: the UI

Widget _phone(String title, double w, double h, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: _t(13.5, c: _gold)),
        ),
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFF121116),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );

Widget _fightDice() {
  final bone = _skin('starter_die');
  final ember = _skin('flame_die');
  final glass = _skin('tearglass_die');
  Widget slot(_Shape s, DieSkin k, String v,
          {bool lit = false,
          bool held = false,
          bool dim = false,
          String? tag}) =>
      Column(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: held
                    ? const Color(0xFFF2C14E)
                    : lit
                        ? const Color(0xFFB794F6)
                        : _line,
                width: held || lit ? 2 : 1),
          ),
          child: Opacity(
            opacity: dim ? 0.45 : 1,
            child: Stack(alignment: Alignment.center, children: [
              _die(s, k, v, 46, glow: lit ? 0.7 : 0),
              if (held)
                const Positioned(
                    right: -2,
                    top: -2,
                    child:
                        Icon(Icons.lock, size: 13, color: Color(0xFFF2C14E))),
            ]),
          ),
        ),
        const SizedBox(height: 3),
        Text(tag ?? s.name, style: _t(10, c: _ash)),
      ]);
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(
      height: 150,
      alignment: Alignment.center,
      color: const Color(0xFF1B2A33),
      child: Text('the fight', style: _t(13, c: _ash, italic: true)),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YOUR DICE', style: _t(10.5, c: _ash, bold: true)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          slot(_shapes[1], bone, '5'),
          slot(_shapes[2], ember, '!', lit: true, tag: 'd8 · a skill face'),
          slot(_shapes[5], glass, '17', held: true, tag: 'd20 · kept'),
          slot(_shapes[1], bone, '?', dim: true, tag: 'd6 · not rolled'),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: Text(
                  'The die’s shape is its size: a d8 has more faces, so more can come up. The face that landed is read on the die; a kept die wears a gold lock.',
                  style: _t(11.5, c: _ash, italic: true))),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: () {}, child: const Text('Roll')),
        ),
      ]),
    ),
  ]);
}

Widget _diceSlot() {
  final bone = _skin('starter_die');
  Widget tile(String name, Widget die, {bool lit = false}) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lit ? const Color(0xFFE2B890) : _line),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          die,
          const SizedBox(height: 3),
          Text(name,
              style: _t(11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
  Widget row(_Shape s, DieSkin k, String name, String line,
          {bool on = false}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? const Color(0xFFB794F6) : _line),
        ),
        child: Row(children: [
          _die(s, k, '', 34),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: _t(14.5, bold: true)),
              Text(line, style: _t(11.5, c: _ash)),
            ]),
          ),
          if (on) const Icon(Icons.check, size: 18, color: Color(0xFFB794F6)),
        ]),
      );
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(
        height: 50,
        color: const Color(0xFF1B1A21),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        child: Text('Inventory',
            style: const TextStyle(
                fontFamily: 'IMFellEnglishSC',
                fontSize: 20,
                color: Color(0xFFEDE6DC)))),
    Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TODAY’S DICE SLOT', style: _t(10.5, c: _ash, bold: true)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B22),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE2B890)),
          ),
          child: Row(children: [
            const Icon(Icons.casino, size: 20, color: Color(0xFFE2B890)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DICE', style: _t(10, c: _ash)),
              Text('starter_die', style: _t(14)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Text('PROPOSED: THE DIE, BY ITS LOOK AND NAME',
            style: _t(10.5, c: _ash, bold: true)),
        const SizedBox(height: 6),
        SizedBox(
          width: 130,
          height: 104,
          child: tile('Lucky Die', _die(_shapes[1], bone, '5', 52), lit: true),
        ),
        const SizedBox(height: 4),
        Text(
            'Lucky Die · d6 · bone (the die’s name, its shape and its material, not its id)',
            style: _t(11, c: _ash, italic: true)),
        const SizedBox(height: 16),
        Text('CHOOSING (the sheet the slot opens)',
            style: _t(10.5, c: _ash, bold: true)),
        const SizedBox(height: 6),
        row(_shapes[1], bone, 'Lucky Die', 'd6 · 6 faces · bone', on: true),
        row(_shapes[2], _skin('flame_die'), 'Ember Die',
            'd8 · 8 faces · ember'),
        row(_shapes[5], _skin('tearglass_die'), 'Tear-glass Die',
            'd20 · 20 faces · tear-glass'),
      ]),
    ),
  ]);
}

Widget _ui() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where the dice show: the fight, and the character’s slot',
            style: _t(19)),
        const SizedBox(height: 4),
        _note(
            'In the fight each die is a small tile of its shape and style, with the shape’s name under it; a die that landed on a skill face glows, a kept die has a gold lock, one not yet rolled is pale. On the Inventory screen the Dice slot says the die’s name and shows its shape instead of its id, and the sheet it opens lists the dice by look, shape and material.',
            w: 900),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _phone('In the fight (the party’s dice row)', 360, 480, _fightDice()),
          const SizedBox(width: 22),
          _phone('The character’s dice slot', 360, 640, _diceSlot()),
        ]),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('six shapes with the faces they should show', () {
    expect(_shapes.map((s) => s.sides), [4, 6, 8, 10, 12, 20]);
    for (final s in _shapes) {
      expect(s.faces.length, s.light.length, reason: s.name);
      expect(s.front, lessThan(s.faces.length), reason: s.name);
      expect(s.faces.length, lessThanOrEqualTo(20),
          reason: 'a die is at most 20 polygons: cheap on a phone');
    }
  });

  test('every style of the picture is a skin the game already has', () {
    for (final id in const [
      'starter_die',
      'pilgrim_die',
      'tobin_die',
      'shadow_die',
      'tearglass_die',
      'flame_die',
      'stone_die'
    ]) {
      expect(dieSkins.containsKey(id), isTrue, reason: id);
    }
  });

  Future<void> shoot(
      WidgetTester tester, Widget w, Size size, String name) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RepaintBoundary(
                key: key, child: ColoredBox(color: _bg, child: w)),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  }

  testWidgets('the dice family (UX_SHOTS=<folder>)', (tester) async {
    await shoot(
        tester, _family(), const Size(1200, 760), 'dice-family-mock.png');
  });

  testWidgets('the roll (UX_SHOTS=<folder>)', (tester) async {
    await shoot(tester, _roll(), const Size(1000, 1330), 'dice-roll-mock.png');
  });

  testWidgets('the dice in the UI (UX_SHOTS=<folder>)', (tester) async {
    await shoot(tester, _ui(), const Size(900, 780), 'dice-ui-mock.png');
  });
}
