// The ink pieces with slight variation and with weather (UX_SHOTS=<folder>),
// pictures only: a sheet of the same pieces under six seeds, and a sheet per
// weather (rain, snow, dust, fog and ash). A seed picks the tear, the tint, the
// tilt, the stain, the pin; the weather is drawn over the piece, its caps outside
// the label's room. Nothing here ships; the table is docs/ux-shots/ui-variation/README.md.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/screens/tower/ink/ink_images.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

// ---- the seed: what a seed picks -------------------------------------------

const _reds = [
  Color(0xFFC1121A), // red
  Color(0xFFA8321C), // rust
  Color(0xFF7A2A22), // dried blood
  Color(0xFF9E4A48), // faded red
  Color(0xFFB5121B),
  Color(0xFF8E141A),
];
const _papers = [
  Color(0xFFEFEDE8), // paper
  Color(0xFFE6E0D0), // warm grey
  Color(0xFFDDE3E6), // cold grey
  Color(0xFFEFE6D2), // ochre-tinged
  Color(0xFFE9E9E4),
  Color(0xFFE2DCCB),
];

/// Set while a weather sheet is built: the weather goes on inside the tilt, so
/// the caps follow the piece's edge.
Widget Function(Widget)? _skyHook;

class _Seed {
  _Seed(this.n) : r = math.Random(n * 7919 + 13);
  final int n;
  final math.Random r;
  Color get red => _reds[n % _reds.length];
  Color get paper => _papers[(n * 5 + 1) % _papers.length];
  double get tilt => ((n % 3) + 1) * (n.isEven ? 1 : -1) * math.pi / 180;
  bool get fold => n % 3 == 0;
  bool get burn => n % 4 == 1;
  bool get pin => n % 2 == 0;
  bool get chip => n % 3 == 2;
  int get stains => 1 + n % 3;
  List<double> teeth(int count) => [
        for (var i = 0; i < count; i++)
          2 + math.Random(n * 31 + i).nextDouble() * 9
      ];
}

/// Tear, chip, fold, burn, stains, pin and tilt on a piece, from a seed.
class _Worn extends StatelessWidget {
  _Worn(this.seed, this.child, {this.tear = true}) : hook = _skyHook;
  final Widget Function(Widget)? hook;
  final _Seed seed;
  final Widget child;
  final bool tear;

  @override
  Widget build(BuildContext context) {
    Widget w = child;
    {
      w = Stack(clipBehavior: Clip.none, children: [
        w,
        Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _Marks(seed)))),
        if (seed.pin)
          Positioned(
              left: 4,
              top: 3,
              child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          seed.n % 4 == 0 ? const Color(0xFF8E141A) : inkGrey,
                      border: Border.all(color: inkBlack, width: 0.8)))),
      ]);
    }
    if (tear || seed.chip) {
      w = ClipPath(clipper: _Tear(seed, tear), child: w);
    }
    final sky = hook;
    if (sky != null) w = sky(w);
    return Transform.rotate(angle: seed.tilt, child: w);
  }
}

class _Tear extends CustomClipper<Path> {
  _Tear(this.seed, this.tear);
  final _Seed seed;
  final bool tear;
  @override
  Path getClip(Size s) {
    final p = Path()..moveTo(0, 0);
    // top edge straight, right edge torn (a seeded pattern), bottom edge
    // lightly torn, left edge straight; a chip takes one corner off.
    p.lineTo(s.width - (seed.chip ? 7 : 0), 0);
    if (seed.chip) p.lineTo(s.width, 7);
    final t = seed.teeth(6);
    final h = s.height / t.length;
    if (tear) {
      for (var i = 0; i < t.length; i++) {
        p.lineTo(s.width - t[i], h * i + h * 0.4);
        p.lineTo(s.width - t[(i + 2) % t.length] * 0.4, h * (i + 1));
      }
    } else {
      p.lineTo(s.width, s.height);
    }
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_Tear old) => old.seed.n != seed.n;
}

class _Marks extends CustomPainter {
  _Marks(this.seed);
  final _Seed seed;
  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed.n * 101 + 7);
    for (var i = 0; i < seed.stains; i++) {
      final c = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      canvas.drawCircle(c, 5 + r.nextDouble() * 9,
          Paint()..color = const Color(0xFF5A4636).withValues(alpha: 0.13));
    }
    // ink splatter
    for (var i = 0; i < 3 + seed.n % 4; i++) {
      final c = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      canvas.drawCircle(
          c,
          0.6 + r.nextDouble() * 1.4,
          Paint()
            ..color = (i.isEven ? inkBlack : const Color(0xFF8E141A))
                .withValues(alpha: 0.55));
    }
    if (seed.burn) {
      canvas.drawCircle(
          Offset(s.width, s.height * 0.8),
          14,
          Paint()
            ..shader = ui.Gradient.radial(Offset(s.width, s.height * 0.8), 14,
                [const Color(0xAA1B1008), const Color(0x001B1008)]));
    }
    if (seed.fold) {
      final p = Path()
        ..moveTo(s.width - 12, s.height)
        ..lineTo(s.width, s.height - 12)
        ..lineTo(s.width, s.height)
        ..close();
      canvas.drawPath(p, Paint()..color = inkBlack.withValues(alpha: 0.45));
      canvas.drawLine(
          Offset(s.width - 12, s.height),
          Offset(s.width, s.height - 12),
          Paint()
            ..color = inkPaper.withValues(alpha: 0.5)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_Marks old) => old.seed.n != seed.n;
}

// ---- the pieces --------------------------------------------------------------

TextStyle _t(Color c, {double size = 14}) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: size, color: c);

Widget _redSkew(_Seed s) => _Worn(
    s,
    Transform(
        transform: Matrix4.skewX(-inkSkew),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            color: s.red,
            child: Transform(
                transform: Matrix4.skewX(inkSkew),
                child: Text('Fight', style: _t(inkPaper))))),
    tear: false);

Widget _paperFrame(_Seed s) {
  // The wide frame's paper tinted warm or cold; stains over it.
  final p = s.paper;
  final matrix = <double>[
    p.r / 0.94,
    0,
    0,
    0,
    0,
    0,
    p.g / 0.93,
    0,
    0,
    0,
    0,
    0,
    p.b / 0.91,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  return _Worn(
      s,
      SizedBox(
          width: 118,
          child: ColorFiltered(
              colorFilter: ColorFilter.matrix(matrix),
              child: InkPaperPanel(
                  padding: const EdgeInsets.fromLTRB(34, 8, 12, 8),
                  child: Text('Settings', style: _t(inkOnPaper))))),
      tear: false);
}

Widget _blackLine(_Seed s) => _Worn(
    s,
    Transform(
        transform: Matrix4.skewX(-inkSkew),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: inkBlack,
                border:
                    Border.all(color: inkPaper, width: s.n.isEven ? 1.5 : 1)),
            child: Transform(
                transform: Matrix4.skewX(inkSkew),
                child: Text('The door', style: _t(inkPaper, size: 13))))),
    tear: false);

Widget _panel(_Seed s) => _Worn(
    s,
    Container(
        width: 112,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
            color: inkBlack,
            border: Border(
                left: BorderSide(
                    color: s.n % 3 == 1 ? s.red : inkPaper,
                    width: s.n.isEven ? 4 : 3),
                top: const BorderSide(color: inkSlate),
                right: const BorderSide(color: inkSlate),
                bottom: const BorderSide(color: inkSlate))),
        child: const Text('Oaths · Unsworn',
            style: TextStyle(
                fontFamily: InkFonts.system, fontSize: 10, color: inkPaper))),
    tear: false);

Widget _strip(_Seed s) => _Worn(
    s,
    Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 20, 5),
        color: s.red,
        child: Text('Chapter 3', style: _t(inkPaper, size: 13))));

final _pieces = <(String, Widget Function(_Seed))>[
  ('Red skew button', _redSkew),
  ('Paper frame button', _paperFrame),
  ('Black + paper line button', _blackLine),
  ('Ink panel', _panel),
  ('Torn banner tab', _strip),
];

// ---- the weather ----------------------------------------------------------------

/// Weather drawn over a piece: its caps and drips sit just outside the box
/// (the label's room is never covered), the wet and the veil lie over it.
class _Sky extends StatelessWidget {
  const _Sky(this.kind, this.fall, this.seed, this.child);
  final WeatherKind kind;
  final double fall;
  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget w = child;
    switch (kind) {
      case WeatherKind.rain:
        w = ColorFiltered(
            colorFilter: ColorFilter.mode(
                inkBlack.withValues(alpha: 0.18 + 0.2 * fall),
                BlendMode.srcATop),
            child: w);
      case WeatherKind.fog:
        w = Opacity(opacity: 1 - 0.28 * fall, child: w);
      default:
        break;
    }
    return Stack(clipBehavior: Clip.none, children: [
      w,
      Positioned.fill(
          child: IgnorePointer(
              child: CustomPaint(
                  painter: _SkyPainter(kind, fall, seed),
                  // the caps and drips reach outside the box
                  size: Size.infinite))),
    ]);
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.kind, this.fall, this.seed);
  final WeatherKind kind;
  final double fall;
  final int seed;

  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed * 53 + 5);
    switch (kind) {
      case WeatherKind.rain:
        // a glossy streak, ink bled at the foot, drips off the bottom edge
        canvas.drawLine(
            Offset(s.width * 0.25, s.height * 0.1),
            Offset(s.width * 0.5, s.height * 0.9),
            Paint()
              ..color = inkPaper.withValues(alpha: 0.12 + 0.12 * fall)
              ..strokeWidth = 3);
        canvas.drawRect(Rect.fromLTWH(0, s.height - 3, s.width, 3),
            Paint()..color = inkBlack.withValues(alpha: 0.35));
        final drips = 2 + (fall * 3).round();
        for (var i = 0; i < drips; i++) {
          final x = 8 + r.nextDouble() * (s.width - 16);
          final len = 4 + r.nextDouble() * 9 * fall + 3;
          canvas.drawLine(
              Offset(x, s.height),
              Offset(x, s.height + len),
              Paint()
                ..color = inkSlate
                ..strokeWidth = 1.6);
          canvas.drawCircle(
              Offset(x, s.height + len), 1.8, Paint()..color = inkGrey);
        }
      case WeatherKind.snow:
        // snow piled on the top edge (outside the box), frost at the corners
        final cap = Path()..moveTo(-1, 1);
        final h = 3 + 5 * fall;
        var x = -1.0;
        while (x < s.width + 1) {
          final w = 5 + r.nextDouble() * 6;
          cap.quadraticBezierTo(x + w / 2, -h - r.nextDouble() * 3, x + w, 1);
          x += w;
        }
        cap.lineTo(s.width + 1, 2);
        cap.lineTo(-1, 2);
        cap.close();
        canvas.drawPath(cap, Paint()..color = inkPaper);
        for (final c in [
          const Offset(0, 0),
          Offset(s.width, 0),
          Offset(0, s.height),
          Offset(s.width, s.height)
        ]) {
          for (var i = 0; i < 4; i++) {
            canvas.drawCircle(
                c +
                    Offset((c.dx == 0 ? 1 : -1) * r.nextDouble() * 7,
                        (c.dy == 0 ? 1 : -1) * r.nextDouble() * 6),
                0.8 + r.nextDouble() * 1.3,
                Paint()..color = inkPaper.withValues(alpha: 0.85));
          }
        }
      case WeatherKind.dust:
        // a sand drift along the top edge, dust in the corners
        const sand = Color(0xFFB9A27A);
        final drift = Path()..moveTo(-1, 1);
        final amp = 2 + 4 * fall;
        for (var x = 0.0; x <= s.width + 4; x += 4) {
          drift.lineTo(x, -amp * (0.5 + 0.5 * math.sin(x / 11 + seed)) + 1);
        }
        drift
          ..lineTo(s.width + 1, 2)
          ..lineTo(-1, 2)
          ..close();
        canvas.drawPath(drift, Paint()..color = sand);
        for (final c in [Offset(0, s.height), Offset(s.width, s.height)]) {
          for (var i = 0; i < 6 + (fall * 6).round(); i++) {
            canvas.drawCircle(
                c +
                    Offset((c.dx == 0 ? 1 : -1) * r.nextDouble() * 12,
                        -r.nextDouble() * 8),
                0.7 + r.nextDouble(),
                Paint()..color = sand.withValues(alpha: 0.8));
          }
        }
      case WeatherKind.fog:
        // a faded veil, thicker toward the foot
        canvas.drawRect(
            Offset.zero & s,
            Paint()
              ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), [
                inkGrey.withValues(alpha: 0.05),
                inkGrey.withValues(alpha: 0.22 + 0.2 * fall)
              ]));
      case WeatherKind.ash:
        // burnt specks, soot along the top
        canvas.drawRect(Rect.fromLTWH(0, 0, s.width, 3),
            Paint()..color = const Color(0xFF1B1008).withValues(alpha: 0.7));
        for (var i = 0; i < 6 + (fall * 10).round(); i++) {
          canvas.drawCircle(
              Offset(r.nextDouble() * s.width, r.nextDouble() * s.height),
              0.6 + r.nextDouble() * 1.2,
              Paint()
                ..color = (i % 4 == 0
                        ? const Color(0xFFD06A1E)
                        : const Color(0xFF1B1008))
                    .withValues(alpha: 0.85));
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.kind != kind || old.fall != fall;
}

// ---- the sheets -----------------------------------------------------------------

Widget _cap(String t, {Color c = inkGrey, bool bold = false}) => Text(t,
    style: TextStyle(
        fontFamily: InkFonts.system,
        fontSize: 9,
        height: 1.2,
        color: c,
        fontWeight: bold ? FontWeight.w700 : null));

Widget _cell(Widget child, String label, {double w = 104}) => SizedBox(
    width: w,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: w,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: inkBlack, border: Border.all(color: inkSlate)),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(padding: const EdgeInsets.all(10), child: child))),
      const SizedBox(height: 2),
      _cap(label),
    ]));

Widget _group(String title, List<Widget> cells) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 14, color: inkRed),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: _t(inkPaper, size: 14))
      ]),
      const SizedBox(height: 5),
      Wrap(spacing: 6, runSpacing: 8, children: cells),
    ]));

Widget _sheet(String title, String note, List<Widget> groups) => Container(
    width: 360,
    color: inkDeep,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [InkTab(title)]),
      const SizedBox(height: 6),
      _cap(note),
      const SizedBox(height: 12),
      ...groups,
    ]));

Widget _variationSheet() => _sheet('Variation: six seeds',
        'Same pieces, a seed picks tear, tint, tilt, stain, pin, fold, chip.', [
      for (final (name, build) in _pieces)
        _group(name,
            [for (var n = 1; n <= 6; n++) _cell(build(_Seed(n)), 'seed $n')]),
    ]);

Widget _weatherSheet(WeatherKind kind, String title, String note) {
  Widget cell(
      Widget Function(_Seed) build, int seed, double? fall, String label) {
    _skyHook = fall == null ? null : (w) => _Sky(kind, fall, seed, w);
    final w = _cell(build(_Seed(seed)), label);
    _skyHook = null;
    return w;
  }

  return _sheet(title, note, [
    for (final (name, build) in _pieces)
      _group(name, [
        cell(build, 2, null, 'clear'),
        cell(build, 2, 0.4, 'light'),
        cell(build, 5, 1.0, 'heavy'),
      ]),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('variation and weather sheets', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(InkImages.preload);
    Directory(shots!).createSync(recursive: true);
    final sheets = <String, Widget>{
      'variation': _variationSheet(),
      'weather-rain': _weatherSheet(WeatherKind.rain, 'Rain',
          'Darker, a glossy streak, ink bled at the foot, drips off the bottom edge.'),
      'weather-snow': _weatherSheet(WeatherKind.snow, 'Snow',
          'Snow piled on the top edge (outside the label), frost at the corners.'),
      'weather-dust': _weatherSheet(WeatherKind.dust, 'Sand and dust',
          'A sand drift on the top edge, dust in the lower corners.'),
      'weather-fog': _weatherSheet(
          WeatherKind.fog, 'Fog', 'A faded veil, thicker toward the foot.'),
      'weather-ash': _weatherSheet(WeatherKind.ash, 'Ash and embers',
          'Soot along the top, burnt specks and a few embers.'),
    };
    for (final e in sheets.entries) {
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: InkFonts.prose),
          home: Scaffold(
              backgroundColor: inkDeep,
              body: SingleChildScrollView(
                  child: RepaintBoundary(key: key, child: e.value)))));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: e.key);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/ink-${e.key}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
