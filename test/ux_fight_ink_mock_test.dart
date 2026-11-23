// The 7th fight screen (UX_SHOTS=<folder>), pictures only: a pixel-art homage
// to ink-wash martial-arts manhwa (general style only, our own characters).
// Art's pieces (art/pixellab-ink/final): the background, the hero and the foe
// (136 canvas, figures about 110 px tall, kept tall: 1 art pixel = 1 dp here),
// the brush frame, the hit splash, the dice. The layout carries what PixelLab
// cannot: diagonal comic-panel borders with black gutters, speed lines on the
// hit, the splash as an overlay, big black areas, and deep red only for health,
// the aimed foe, the ×3 weakness and your turn. The weakness mark is on the
// nameplate; the matching-die hint is the caption under the dice. Mock only.
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
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';

import 'support/fonts.dart';

const String _art = 'docs/ux-shots/fight-proposals/art';
const Color _black = Color(0xFF05060A);
const Color _paper = Color(0xFFEFEDE8);
const Color _grey = Color(0xFF9AA3A7);
const Color _red = Color(0xFFD1141B);

final Map<String, ui.Image> _im = {};

Future<void> _load(String name) async {
  final codec =
      await ui.instantiateImageCodec(File('$_art/$name.png').readAsBytesSync());
  _im[name] = (await codec.getNextFrame()).image;
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

/// A picture at 1 art pixel = 1 dp.
Widget _pic(String name, {Rect? src, bool flip = false, double opacity = 1}) {
  final img = _im[name]!;
  final s = src ?? Rect.fromLTWH(0, 0, img.width * 1.0, img.height * 1.0);
  return CustomPaint(
      size: Size(s.width, s.height),
      painter: _Pic(img, src: src, flip: flip, opacity: opacity));
}

/// A comic panel: [points] cut the screen on a slant; [child] (the scene)
/// shows inside, a thick black border and a thin paper line round it.
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
          ..strokeWidth = 14
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

/// Speed lines converging on [at]: thin paper lines, a few thick ones.
class _SpeedLines extends CustomPainter {
  _SpeedLines(this.at);
  final Offset at;
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 46; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final r0 = 46 + rnd.nextDouble() * 40;
      final r1 = r0 + 40 + rnd.nextDouble() * 150;
      final p = Paint()
        ..strokeCap = StrokeCap.square
        ..strokeWidth = i % 9 == 0 ? 3 : 1
        ..color = (i % 11 == 0 ? _red : _paper).withValues(alpha: 0.7);
      canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * r0,
          at + Offset(math.cos(a), math.sin(a)) * r1, p);
    }
  }

  @override
  bool shouldRepaint(_SpeedLines old) => false;
}

TextStyle _brush(double s, {Color color = _paper}) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: color);
TextStyle _sys(double s, {Color color = _grey}) => TextStyle(
    fontFamily: InkFonts.system, fontSize: s, height: 1.15, color: color);

IconData _icon(String e) => switch (e) {
      'Fire' => Icons.local_fire_department,
      'Electricity' => Icons.bolt,
      'Void' => Icons.blur_on,
      'Light' => Icons.wb_sunny,
      'Ice' => Icons.ac_unit,
      _ => Icons.circle_outlined,
    };

/// A weakness / resistance mark: the weak one in deep red, the resisted in grey.
Widget _mark(String e, {required bool weak, bool ring = false}) => Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _black,
        border: Border.all(color: weak ? _red : _grey, width: ring ? 2.5 : 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon(e), size: 11, color: _paper),
        const SizedBox(width: 2),
        Text(weak ? '×3' : '×½',
            style: TextStyle(
                fontFamily: InkFonts.prose,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1,
                color: weak ? _red : _grey)),
      ]),
    );

/// A nameplate cut like a brush stroke (skewed): the name and, on the same
/// line, the weakness marks; the health bar under it, in deep red.
Widget _plate(String name, int hp, int max,
    {List<String> weak = const [],
    List<String> resist = const [],
    bool aimed = false,
    double width = 130}) {
  return Transform(
    transform: Matrix4.skewX(-0.22),
    child: Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
      decoration: BoxDecoration(
        color: _black,
        border: Border(
            left: BorderSide(color: aimed ? _red : _paper, width: 3),
            bottom: BorderSide(color: aimed ? _red : _grey, width: 1)),
      ),
      child: Transform(
        transform: Matrix4.skewX(0.22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(name, maxLines: 1, style: _brush(12.5)))),
            for (final e in weak) ...[
              const SizedBox(width: 3),
              _mark(e, weak: true, ring: aimed),
            ],
            for (final e in resist) ...[
              const SizedBox(width: 3),
              _mark(e, weak: false),
            ],
          ]),
          const SizedBox(height: 3),
          SizedBox(
            height: 6,
            child: Stack(children: [
              Container(color: const Color(0xFF2A2C34)),
              FractionallySizedBox(
                  widthFactor: hp / max, child: Container(color: _red)),
            ]),
          ),
        ]),
      ),
    ),
  );
}

Widget _heroPlate(String name, int hp, int max, {bool turn = false}) =>
    Transform(
      transform: Matrix4.skewX(-0.22),
      child: Container(
        width: 96,
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
        decoration: BoxDecoration(
          color: _black,
          border: Border(
              left: BorderSide(color: turn ? _red : _paper, width: 3),
              bottom: BorderSide(color: turn ? _red : _grey, width: 1)),
        ),
        child: Transform(
          transform: Matrix4.skewX(0.22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(name, style: _brush(12.5))),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Stack(children: [
                Container(color: const Color(0xFF2A2C34)),
                FractionallySizedBox(
                    widthFactor: hp / max, child: Container(color: _red)),
              ]),
            ),
          ]),
        ),
      ),
    );

/// The foe/hero figure (canvas 136; the figure fills x 48..99, y 18..129):
/// positioned so its feet stand at ([cx], [feetY]).
Widget _figure(String name, double cx, double feetY, {bool flip = false}) =>
    Positioned(left: cx - 68, top: feetY - 129, child: _pic(name, flip: flip));

Widget _die(String name, String element, {bool lit = false}) => SizedBox(
      width: 88,
      height: 104,
      child: Stack(clipBehavior: Clip.none, children: [
        if (lit)
          Positioned(
            left: 4,
            top: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(border: Border.all(color: _red, width: 3)),
            ),
          ),
        Positioned(left: 0, top: 0, child: _pic(name)),
        if (lit)
          Positioned(right: -2, top: -8, child: _mark(element, weak: true)),
        Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: Center(child: Text(element, style: _sys(9)))),
      ]),
    );

/// A skill card in the brush frame (the frame's corners kept at 1:1, the
/// sides stretched), lit in deep red.
class _FramePainter extends CustomPainter {
  _FramePainter(this.img);
  final ui.Image img;
  @override
  void paint(Canvas canvas, Size s) {
    const ins = 24.0;
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final xs = [0.0, ins, iw - ins, iw];
    final ys = [0.0, ins, ih - ins, ih];
    final dx = [0.0, ins, s.width - ins, s.width];
    final dy = [0.0, ins, s.height - ins, s.height];
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
  bool shouldRepaint(_FramePainter old) => false;
}

Widget _card((String, String) c, {bool lit = false}) {
  final (id, element) = c;
  return SizedBox(
    width: 104,
    height: 124,
    child: Stack(children: [
      Positioned.fill(child: Container(color: _black.withValues(alpha: 0.9))),
      Positioned.fill(
          child: CustomPaint(painter: _FramePainter(_im['ink_frame']!))),
      if (lit)
        Positioned.fill(
          child: Container(
              margin: const EdgeInsets.all(3),
              decoration:
                  BoxDecoration(border: Border.all(color: _red, width: 2))),
        ),
      Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_icon(element), size: 11, color: lit ? _red : _grey),
            const SizedBox(height: 2),
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.33, 0.33, 0.33, 0, 0, //
                0.33, 0.33, 0.33, 0, 0,
                0.33, 0.33, 0.33, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: SkillPixelIcon(id, size: 36),
            ),
            const SizedBox(height: 3),
            for (final word in skillDisplayName(id).split(' '))
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(word, maxLines: 1, style: _brush(10.5))),
          ]),
        ),
      ),
    ]),
  );
}

Widget _head(String name, {bool now = false}) => Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: _black,
        shape: BoxShape.circle,
        border: Border.all(color: now ? _red : _grey, width: now ? 3 : 1.5),
      ),
      child: ClipOval(
          child: CustomPaint(
              painter:
                  _Pic(_im[name]!, src: const Rect.fromLTWH(44, 14, 56, 56)))),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the ink fight screen', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    String ename(String id) => (enemies[id] as Map)['enemyName'] as String;
    List<String> list(String id, String k) =>
        [for (final e in ((enemies[id] as Map)[k] as List)) '$e'];
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final n in [
        'ink_background',
        'ink_hero',
        'ink_foe',
        'ink_frame',
        'ink_hit',
        'ink_d6',
        'alt_ink_d12',
      ]) {
        await _load(n);
      }
    });
    tester.view.physicalSize = const Size(360, 836);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The three panels, cut on a slant.
    const p1 = [
      Offset(0, 100),
      Offset(360, 100),
      Offset(360, 322),
      Offset(0, 368)
    ];
    const p2 = [
      Offset(0, 384),
      Offset(360, 338),
      Offset(360, 528),
      Offset(0, 528)
    ];
    const p3 = [
      Offset(0, 544),
      Offset(360, 544),
      Offset(360, 664),
      Offset(0, 664)
    ];

    Widget panel(List<Offset> pts, double bgOffset, List<Widget> scene) =>
        Stack(children: [
          ClipPath(
            clipper: _PanelClipper(pts),
            child: Stack(children: [
              Positioned(left: 0, top: bgOffset, child: _pic('ink_background')),
              ...scene,
            ]),
          ),
          CustomPaint(size: const Size(360, 836), painter: _PanelBorder(pts)),
        ]);

    final boundary = GlobalKey();
    final sov = ename('void_sovereign');
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.dark)),
        home: Scaffold(
          backgroundColor: _black,
          body: SizedBox(
            width: 360,
            height: 836,
            child: Stack(children: [
              Positioned.fill(child: Container(color: _black)),
              // The title band: big black, the brush title, the turn bar.
              Positioned(
                  left: 14,
                  top: 8,
                  child: Text('Fight: $sov', style: _brush(21))),
              Positioned(
                  left: 14,
                  top: 36,
                  child: Text('The rift · Round 2', style: _sys(9))),
              Positioned(
                  left: 14,
                  top: 54,
                  child: Row(children: [
                    Text('TURN', style: _sys(9)),
                    const SizedBox(width: 6),
                    _head('ink_hero', now: true),
                    _head('ink_foe'),
                    _head('ink_hero'),
                    _head('ink_foe'),
                    _head('ink_hero'),
                    _head('ink_foe'),
                  ])),
              // 1 The foes' panel (top, the bottom edge cut on a slant).
              panel(p1, -22, [
                _figure('ink_foe', 84, 270),
                _figure('ink_foe', 190, 252),
                _figure('ink_foe', 300, 236),
                // The hit on the aimed one: the splash and the speed lines.
                Positioned(
                    left: 190 - 64 + 6,
                    top: 252 - 129 + 10,
                    child: _pic('ink_hit', opacity: 0.95)),
                Positioned.fill(
                    child: CustomPaint(
                        painter: _SpeedLines(const Offset(196, 196)))),
                Positioned(
                    left: 14,
                    top: 276,
                    child: _plate(ename('inquisition_warden'), 22, 22,
                        weak: list('inquisition_warden', 'weakTo'),
                        resist: list('inquisition_warden', 'resists'),
                        width: 150)),
                Positioned(
                    left: 128,
                    top: 124,
                    child: _plate(sov, 86, 86,
                        weak: list('void_sovereign', 'weakTo'),
                        resist: list('void_sovereign', 'resists'),
                        aimed: true,
                        width: 176)),
                Positioned(
                    left: 214,
                    top: 262,
                    child: _plate(ename('white_soldier'), 11, 16,
                        weak: list('white_soldier', 'weakTo'),
                        resist: list('white_soldier', 'resists'),
                        width: 150)),
              ]),
              // 2 The heroes' panel (the top edge cut the other way).
              panel(p2, 36, [
                _figure('ink_hero', 62, 492, flip: false),
                _figure('ink_hero', 160, 482),
                _figure('ink_hero', 258, 472),
                Positioned(
                    left: 14,
                    top: 494,
                    child: _heroPlate('Edda', 41, 52, turn: true)),
                Positioned(
                    left: 112, top: 484, child: _heroPlate('Liora', 30, 36)),
                Positioned(
                    left: 210, top: 474, child: _heroPlate('Vess', 24, 28)),
              ]),
              // 3 The dice, on the snow.
              panel(p3, 0, [
                Positioned(
                    left: 22,
                    top: 560,
                    child: _die('ink_d6', 'Light', lit: true)),
                Positioned(
                    left: 136, top: 564, child: _die('alt_ink_d12', 'Fire')),
                Positioned(left: 248, top: 560, child: _die('ink_d6', 'Void')),
              ]),
              Positioned(
                  left: 0,
                  right: 0,
                  top: 670,
                  child: Container(
                      color: _black.withValues(alpha: 0.82),
                      padding: const EdgeInsets.fromLTRB(14, 3, 14, 3),
                      child: Row(children: [
                        const Icon(Icons.wb_sunny, size: 12, color: _red),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                                'Your Light die hits $sov ×3: it is weak to Light.',
                                maxLines: 1,
                                style: const TextStyle(
                                    fontFamily: InkFonts.prose,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                    color: _paper))),
                      ]))),
              // The hand in brush frames, on the black.
              for (var i = 0; i < 3; i++)
                Positioned(
                    left: 8.0 + i * 120,
                    top: 700,
                    child: _card(
                        const [
                          ('radiant_judgment', 'Light'),
                          ('fireball', 'Fire'),
                          ('cleric_absolution', 'Light'),
                        ][i],
                        lit: i == 0)),
              // Strike, a red brush button over the gutter.
              Positioned(
                  left: 262,
                  top: 628,
                  child: Transform(
                    transform: Matrix4.skewX(-0.22),
                    child: Container(
                      width: 92,
                      height: 34,
                      alignment: Alignment.center,
                      color: _red,
                      child: Transform(
                          transform: Matrix4.skewX(0.22),
                          child: Text('Strike ×3',
                              style: _brush(15, color: _paper))),
                    ),
                  )),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/ink.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
