// Two ideas for the main tutorials (UX mock): the user did not like the
// pointer animation, so here are two different ones, to choose between.
//   A. The guide dog walks to the control and acts it out: it trots in, sits
//      by the Journey tab, taps it with a paw; the tab lifts and rings gold
//      and the screen switches, with its one line.
//   B. A short looping demo of the feature inside the card, with the card's
//      own text and its two buttons: the Journey (a route drawn, a pin
//      tapped) and the Character (the radar growing).
// Both skip on a tap, and both are one widget with no hook asked of Core.
// The dog is the game's own guide (companion_sprites.dart).
// UX_SHOTS=<folder> takes docs/ux-shots/tutorial-ideas-mock.png.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/companion_sprites.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';

const _bg = Color(0xFF17151B);
const _page = Color(0xFF121116);
const _gold = Color(0xFFE2B890);
const _ring = Color(0xFFF2C14E);
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

const _tabs = [
  (Icons.menu_book, 'Story'),
  (Icons.person_outline, 'Character'),
  (Icons.local_fire_department_outlined, 'Camp'),
  (Icons.more_horiz, 'Other'),
  (Icons.alt_route, 'Journey'),
];

/// A frame of the app: some content blocks and the tab bar, [lit] the tab
/// the tutorial is about (lifted and ringed), [pressed] how far it is pushed.
class _AppFrame extends StatelessWidget {
  const _AppFrame({this.dim = 0, this.lit = -1, this.pressed = 0, this.child});

  final double dim;
  final int lit;
  final double pressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _build(context, box.biggest));

  Widget _build(BuildContext context, Size size) {
    return Stack(children: [
      Column(children: [
        Container(
          height: 34,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 10),
          color: const Color(0xFF1B1A21),
          child: Text('Chapter 2', style: _t(12, c: _ash)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              for (var i = 0; i < 4; i++)
                Container(
                  height: i == 0 ? 60 : 34,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1B22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ]),
          ),
        ),
        Container(
          height: 54,
          color: const Color(0xFF1B1A21),
          child: Row(children: [
            for (final (i, (icon, label)) in _tabs.indexed)
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, i == lit ? -3 + 4 * pressed : 0),
                  child: Transform.scale(
                    scale: i == lit ? 1.12 - 0.1 * pressed : 1,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 21, color: i == lit ? _ring : _ash),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label,
                                style: _t(9.5, c: i == lit ? _ring : _ash)),
                          ),
                        ]),
                  ),
                ),
              ),
          ]),
        ),
      ]),
      if (dim > 0)
        Positioned.fill(
          child: CustomPaint(
              painter: _Dim(lit < 0 ? null : _tabRect(size, lit), dim)),
        ),
      if (child != null) Positioned.fill(child: child!),
    ]);
  }

  Rect _tabRect(Size size, int i) => Rect.fromLTWH(
      size.width / 5 * i + 2, size.height - 54 + 2, size.width / 5 - 4, 50);
}

class _Dim extends CustomPainter {
  _Dim(this.hole, this.dim);
  final Rect? hole;
  final double dim;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (hole != null) {
      path
        ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(10)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: dim));
    if (hole != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(hole!.inflate(1), const Radius.circular(10)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _ring);
    }
  }

  @override
  bool shouldRepaint(_Dim old) => old.hole != hole || old.dim != dim;
}

Widget _dog(String asset, {double size = 70, bool flip = false}) =>
    Transform.flip(
      flipX: flip,
      child: Image.asset(asset,
          width: size,
          height: size,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.pets, size: size * 0.6, color: _gold)),
    );

const String _walkEast = '$companionAssetsRoot/Walking/east/frame_002.png';
const String _walkEast2 = '$companionAssetsRoot/Walking/east/frame_005.png';
const String _sit = '$companionAssetsRoot/Sitting_down/rotations/south.png';

Widget _bubble(String text) => Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF26232E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: _t(11, italic: true)),
    );

/// A storyboard frame: its time, what happens, and the frame.
Widget _storyFrame(String time, String what, Widget frame) => SizedBox(
      width: 206,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(time, style: _t(12.5, c: _gold, bold: true)),
        const SizedBox(height: 2),
        SizedBox(height: 50, child: Text(what, style: _t(11, c: _ash))),
        Container(
          width: 206,
          height: 340,
          decoration: BoxDecoration(
            color: _page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: frame,
        ),
      ]),
    );

Widget _ideaA() {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('A. The guide dog acts it out', style: _t(17, c: _gold, bold: true)),
    const SizedBox(height: 2),
    SizedBox(
      width: 880,
      child: Text(
          'About 3 s for a main tutorial. The dog the player already knows trots in, sits by the control, '
          'taps it with a paw, and the control does what it does. One line of caption in the dog’s own bubble. '
          'A tap anywhere skips; then the same Show me / Later card as today.',
          style: _t(12, c: _ash)),
    ),
    const SizedBox(height: 10),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _storyFrame(
          '0.0 s',
          'The screen dims a little. The dog trots in from the edge.',
          Stack(children: [
            const _AppFrame(dim: 0.4),
            Positioned(left: 8, bottom: 70, child: _dog(_walkEast)),
          ])),
      const SizedBox(width: 12),
      _storyFrame(
          '1.2 s',
          'It walks to the Journey tab and the tab is lit: the dim leaves a hole round it.',
          Stack(children: [
            const _AppFrame(dim: 0.6, lit: 4),
            Positioned(right: 4, bottom: 50, child: _dog(_walkEast2)),
          ])),
      const SizedBox(width: 12),
      _storyFrame(
          '2.0 s',
          'It sits and taps the tab with a paw: the tab dips, rings gold, a ripple.',
          Stack(children: [
            const _AppFrame(dim: 0.6, lit: 4, pressed: 1),
            Positioned(right: 6, bottom: 50, child: _dog(_sit, size: 56)),
            Positioned(
              right: 18,
              bottom: 44,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _ring.withValues(alpha: 0.7), width: 2),
                ),
              ),
            ),
            Positioned(
                left: 10,
                right: 10,
                bottom: 116,
                child: _bubble('The Journey: your story, on a map.')),
          ])),
      const SizedBox(width: 12),
      _storyFrame(
          '2.8 s',
          'The screen switches to it; the dog stays in the corner, then today’s card.',
          Stack(children: [
            _AppFrame(
                dim: 0.5,
                lit: 4,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24212B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New: Journey', style: _t(14, bold: true)),
                          const SizedBox(height: 4),
                          Text('Your story on a map.',
                              style: _t(11.5, c: _ash)),
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Later', style: _t(12, c: _ash)),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFB794F6),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('Show me',
                                      style: _t(11.5,
                                          c: Colors.black, bold: true)),
                                ),
                              ]),
                        ]),
                  ),
                )),
          ])),
    ]),
  ]);
}

// --------------------------------------------------------------------- B

/// The Journey's demo: a route is drawn across a small map, a pin pulses.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF1E2A33));
    final land = Paint()..color = const Color(0xFF2B3B35);
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height * 0.55)
          ..quadraticBezierTo(size.width * 0.3, size.height * 0.3,
              size.width * 0.55, size.height * 0.5)
          ..quadraticBezierTo(size.width * 0.8, size.height * 0.7, size.width,
              size.height * 0.45)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
        land);
    final pts = [
      Offset(size.width * 0.12, size.height * 0.7),
      Offset(size.width * 0.38, size.height * 0.5),
      Offset(size.width * 0.62, size.height * 0.62),
      Offset(size.width * 0.86, size.height * 0.4),
    ];
    // The route, drawn up to t.
    final route = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      route.lineTo(p.dx, p.dy);
    }
    final metric = route.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));
    canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = _ring);
    for (final (i, p) in pts.indexed) {
      final reached = t >= i / (pts.length - 1) - 0.01;
      canvas.drawCircle(p, 5, Paint()..color = reached ? _ring : _ash);
    }
    // The party's mark at the head of the route, a ring pulsing.
    final head =
        metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0))!.position;
    canvas.drawCircle(
        head,
        8 + 3 * math.sin(t * 20).abs(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.t != t;
}

/// The Character's demo: the radar grows.
class _RadarDemo extends CustomPainter {
  _RadarDemo(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF1E1B26));
    final c = size.center(Offset.zero);
    final r = size.height * 0.4;
    const n = 6;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = _line;
    for (final k in [0.4, 0.7, 1.0]) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / n;
        final o = c + Offset(math.cos(a), math.sin(a)) * r * k;
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p..close(), grid);
    }
    const base = [0.45, 0.5, 0.4, 0.55, 0.35, 0.5];
    const more = [0.75, 0.55, 0.6, 0.85, 0.5, 0.7];
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final v = base[i] +
          (more[i] - base[i]) * Curves.easeInOut.transform(t.clamp(0.0, 1.0));
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * v;
      i == 0 ? shape.moveTo(o.dx, o.dy) : shape.lineTo(o.dx, o.dy);
    }
    shape.close();
    canvas.drawPath(shape, Paint()..color = _ring.withValues(alpha: 0.28));
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _ring);
  }

  @override
  bool shouldRepaint(_RadarDemo old) => old.t != t;
}

/// The card with its demo inset: the card's own text and buttons.
Widget _demoCard({
  required String title,
  required String text,
  required CustomPainter Function(double) painter,
  required double t,
  required String caption,
}) =>
    Container(
      width: 290,
      decoration: BoxDecoration(
        color: const Color(0xFF24212B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            CustomPaint(painter: painter(t)),
            Positioned(
              left: 8,
              bottom: 6,
              child: Text(caption,
                  style: _t(10.5, c: Colors.white70, italic: true)),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: Row(children: [
                const Icon(Icons.loop, size: 13, color: Colors.white54),
                const SizedBox(width: 3),
                Text('tap to skip', style: _t(10, c: Colors.white54)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: _t(16, bold: true)),
            const SizedBox(height: 4),
            Text(text, style: _t(12.5, c: _ash)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Later', style: _t(13, c: _ash)),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: const Color(0xFFB794F6),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    Text('Show me', style: _t(13, c: Colors.black, bold: true)),
              ),
            ]),
          ]),
        ),
      ]),
    );

Widget _ideaB() {
  Widget cardAt(double t, String label,
          {required String title,
          required String text,
          required CustomPainter Function(double) p,
          required String caption}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _t(11.5, c: _gold, bold: true)),
        const SizedBox(height: 4),
        _demoCard(title: title, text: text, painter: p, t: t, caption: caption),
      ]);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('B. A short looping demo inside the card',
        style: _t(17, c: _gold, bold: true)),
    const SizedBox(height: 2),
    SizedBox(
      width: 880,
      child: Text(
          'No overlay, no pointer: the card the player already gets (its own title, line and buttons) gets a small '
          'picture at its top that plays the feature in miniature, in a loop of about 3 s, while the player reads. '
          'A tap on the picture, Later or Show me ends it. Three frames of the loop are shown for each example.',
          style: _t(12, c: _ash)),
    ),
    const SizedBox(height: 10),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (t, label) in const [
        (0.1, 'The Journey, 0.3 s'),
        (0.55, '1.6 s'),
        (1.0, '3.0 s, then it loops')
      ]) ...[
        cardAt(t, label,
            title: 'New: Journey',
            text:
                'Your story on a map. Follow the route; tap a pin to see what waits there.',
            p: _RoutePainter.new,
            caption: 'a route is drawn across the map'),
        const SizedBox(width: 12),
      ],
    ]),
    const SizedBox(height: 14),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (t, label) in const [
        (0.0, 'The Character, 0.0 s'),
        (0.5, '1.5 s'),
        (1.0, '3.0 s, then it loops')
      ]) ...[
        cardAt(t, label,
            title: 'New: Character',
            text:
                'Your abilities, your gear and how you lean. It grows as you do.',
            p: _RadarDemo.new,
            caption: 'the radar grows with a level'),
        const SizedBox(width: 12),
      ],
    ]),
  ]);
}

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Two ways to introduce a main tutorial, to choose between',
            style: _t(19)),
        const SizedBox(height: 16),
        _ideaA(),
        const SizedBox(height: 30),
        _ideaB(),
        const SizedBox(height: 18),
        SizedBox(
          width: 900,
          child: Text(
              'Both play once for each topic (the same seen setting as the unlock card) and again from the Tutorials list; '
              'reduced motion shows the last frame still. A: the dog’s frames are the ones the tour uses, so the art exists; '
              'it needs the control’s target id, as the tour already has. B: each topic needs its own small demo drawn (about a '
              'day each); the card does not change. A is livelier and ties to the dog; B is calmer and shows the feature itself.',
              style: _t(12, c: _ash, italic: true)),
        ),
      ]),
    );

void main() {
  setUpAll(loadAppFonts);

  test('the dog frames the mock draws are the guide’s own', () {
    expect(_walkEast, contains('Walking/east'));
    expect(_sit, contains('Sitting_down'));
  });

  testWidgets('a picture of the two tutorial ideas (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1000, 1560);
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
                key: key, child: ColoredBox(color: _bg, child: _board())),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/tutorial-ideas-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
