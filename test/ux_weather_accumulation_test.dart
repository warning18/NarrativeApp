// Weather that builds up on the ink pieces (UX_SHOTS=<folder>), pictures and a
// clip only: snow, sand and ash grow from a dusting to a heavy cap while a
// screen is open (stills at 0, 10, 30 and 60 s), a tap knocks it off in a puff
// and it starts building again; rain's wetness builds over a few seconds and
// then the drips start. The cap is a soft irregular drift: thickest toward the
// windward side, thin at the ends, loose flakes on top, never a repeating
// scallop, and it stops at a maximum height above the label's room.
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

/// How long a cap takes to reach its heavy height: 30 s in the hardest fall,
/// longer in a light one (fall 0 to 1).
double secondsToHeavy(double fall) => 30 / fall.clamp(0.3, 1.0);

/// The level (0 to 1) after [seconds] on screen at [fall].
double levelAfter(double seconds, double fall) =>
    (seconds / secondsToHeavy(fall)).clamp(0.0, 1.0);

// ---- the soft drift ------------------------------------------------------------

/// The profile of a drift along its length (0 to 1): thin at the ends, thickest
/// toward the windward side, lumpy but smooth (no repeats).
double _profile(double x, int seed, double wind) {
  final peak = 0.5 + wind * 0.18; // the windward side (wind -1 to 1)
  final base = math
      .pow(math.sin(math.pi * math.pow(x, math.log(0.5) / math.log(peak))), 0.8)
      .toDouble();
  final lump = 0.78 +
      0.22 * math.sin(x * 5.3 + seed * 1.7) * math.cos(x * 2.1 + seed) +
      0.12 * math.sin(x * 11.0 + seed * 0.6);
  return (base * lump).clamp(0.0, 1.2);
}

class _Cap extends CustomPainter {
  _Cap(this.kind, this.level, this.fall, this.seed, this.knock);
  final WeatherKind kind;
  final double level; // 0 to 1
  final double fall;
  final int seed;
  final double knock; // 0 none, 0 to 1 falling off

  static const double maxH = 12;

  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed * 97 + 3);
    final wind = (seed % 3 - 1) * 0.8;
    switch (kind) {
      case WeatherKind.snow:
        _drift(canvas, s, r, wind, inkPaper, const Color(0xFFC9D2D6));
      case WeatherKind.dust:
        _drift(canvas, s, r, wind, const Color(0xFFC2AA7F),
            const Color(0xFF9C8660),
            ripples: true);
      case WeatherKind.ash:
        _drift(canvas, s, r, wind, const Color(0xFF4A4A4E),
            const Color(0xFF2A2A2E),
            height: 0.55);
        // embers glow in the dark cap
        if (level > 0.2 && knock == 0) {
          for (var i = 0; i < 2 + (level * 6).round(); i++) {
            canvas.drawCircle(
                Offset(
                    r.nextDouble() * s.width, -2 - r.nextDouble() * 5 * level),
                0.9,
                Paint()..color = const Color(0xFFD06A1E));
          }
        }
      default:
        break;
    }
  }

  void _drift(
      Canvas canvas, Size s, math.Random r, double wind, Color top, Color shade,
      {bool ripples = false, double height = 1}) {
    final lift = knock * 20; // a knocked cap drops
    final fade = (1 - knock).clamp(0.0, 1.0);
    final h = maxH * level * height;
    if (h > 0.4 && fade > 0) {
      final path = Path()..moveTo(-1, 2 + lift);
      final pts = <Offset>[];
      for (var x = 0.0; x <= 1.0001; x += 1 / (s.width / 2.5)) {
        pts.add(Offset(x * s.width, 1 + lift - _profile(x, seed, wind) * h));
      }
      path.lineTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset(
            (pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(s.width + 1, 2 + lift);
      path.close();
      canvas.drawPath(path, Paint()..color = shade.withValues(alpha: fade));
      // the lit upper part, a little narrower
      canvas.save();
      canvas.translate(0, -1.2);
      canvas.drawPath(path, Paint()..color = top.withValues(alpha: fade));
      canvas.restore();
      if (ripples) {
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
              Offset(s.width * (0.2 + 0.15 * i), -h * 0.35 + lift),
              Offset(s.width * (0.35 + 0.15 * i), -h * 0.45 + lift),
              Paint()
                ..color = shade.withValues(alpha: 0.6 * fade)
                ..strokeWidth = 0.8);
        }
      }
      // a few loose flakes on top
      for (var i = 0; i < (level * 7).round(); i++) {
        final x = r.nextDouble() * s.width;
        canvas.drawCircle(
            Offset(
                x,
                1 +
                    lift -
                    _profile(x / s.width, seed, wind) * h -
                    1.5 -
                    r.nextDouble() * 4),
            0.7 + r.nextDouble() * 1.1,
            Paint()..color = top.withValues(alpha: 0.9 * fade));
      }
    }
    // the knock: a puff of flakes thrown off, thicker early
    if (knock > 0 && knock < 1) {
      final heavy = (levelBefore * 14).round();
      for (var i = 0; i < heavy; i++) {
        final a = r.nextDouble() * math.pi * 2;
        final d = knock * (8 + r.nextDouble() * 26);
        canvas.drawCircle(
            Offset(r.nextDouble() * s.width + math.cos(a) * d * 0.6,
                -2 + math.sin(a).abs() * d),
            1.0 + r.nextDouble() * 1.8,
            Paint()..color = top.withValues(alpha: (1 - knock) * 0.95));
      }
    }
  }

  /// The level the cap had when it was knocked (the puff's size).
  double levelBefore = 0.8;

  @override
  bool shouldRepaint(_Cap old) =>
      old.level != level || old.knock != knock || old.kind != kind;
}

class _Wet extends CustomPainter {
  _Wet(this.wet, this.seed);
  final double wet; // 0 to 1
  final int seed;
  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed * 53 + 5);
    if (wet > 0.35) {
      canvas.drawLine(
          Offset(s.width * 0.28, s.height * 0.1),
          Offset(s.width * 0.5, s.height * 0.9),
          Paint()
            ..color = inkPaper.withValues(alpha: 0.10 * wet)
            ..strokeWidth = 2.5);
    }
    // the drips start once the piece is wet through
    final drip = ((wet - 0.6) / 0.4).clamp(0.0, 1.0);
    for (var i = 0; i < 4; i++) {
      final x = 8 + r.nextDouble() * (s.width - 16);
      final len = (3 + r.nextDouble() * 11) * drip;
      if (len < 1) continue;
      canvas.drawLine(
          Offset(x, s.height),
          Offset(x, s.height + len),
          Paint()
            ..color = inkSlate
            ..strokeWidth = 1.6);
      canvas.drawCircle(
          Offset(x, s.height + len), 1.8, Paint()..color = inkGrey);
    }
  }

  @override
  bool shouldRepaint(_Wet old) => old.wet != wet;
}

// ---- the pieces ------------------------------------------------------------------

Widget _button() => Transform(
    transform: Matrix4.skewX(-inkSkew),
    child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        color: inkRed,
        child: Transform(
            transform: Matrix4.skewX(inkSkew),
            child: const Text('Fight',
                style: TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 15,
                    color: inkPaper)))));

Widget _panel() => Container(
    width: 150,
    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
    decoration: const BoxDecoration(
        color: inkBlack,
        border: Border(
            left: BorderSide(color: inkPaper, width: 4),
            top: BorderSide(color: inkSlate),
            right: BorderSide(color: inkSlate),
            bottom: BorderSide(color: inkSlate))),
    child: const Text('Oaths · Unsworn',
        style: TextStyle(
            fontFamily: InkFonts.system, fontSize: 11, color: inkPaper)));

/// A piece under the weather at [seconds] on screen (and knocked [knock]).
Widget _under(WeatherKind kind, Widget piece,
    {required double seconds,
    required double fall,
    double knock = 0,
    double levelBefore = 0.8,
    int seed = 4}) {
  if (kind == WeatherKind.rain) {
    // wetness builds over about 8 s at full fall, then drips
    final wet = (seconds / (8 / fall.clamp(0.3, 1.0))).clamp(0.0, 1.0);
    return Stack(clipBehavior: Clip.none, children: [
      ColorFiltered(
          colorFilter: ColorFilter.mode(
              inkBlack.withValues(alpha: 0.3 * wet), BlendMode.srcATop),
          child: piece),
      Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _Wet(wet, seed)))),
    ]);
  }
  final level = levelAfter(seconds, fall);
  return Stack(clipBehavior: Clip.none, children: [
    piece,
    Positioned.fill(
        child: IgnorePointer(
            child: CustomPaint(
                painter: _Cap(kind, level, fall, seed, knock)
                  ..levelBefore = levelBefore))),
  ]);
}

Widget _cell(Widget a, Widget b, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(
          width: 34,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: InkFonts.system, fontSize: 9, color: inkGrey))),
      Container(
          width: 150,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: inkBlack, border: Border.all(color: inkSlate)),
          child: a),
      const SizedBox(width: 6),
      Container(
          width: 150,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: inkBlack, border: Border.all(color: inkSlate)),
          child: b),
    ]));

Widget _sheet(String title, String note, List<Widget> rows) => Container(
    width: 360,
    color: inkDeep,
    padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(children: [InkTab(title)])),
      Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: Text(note,
              style: const TextStyle(
                  fontFamily: InkFonts.system, fontSize: 9, color: inkGrey))),
      ...rows,
    ]));

Widget _timeline(WeatherKind kind, String title, String note,
        {double fall = 0.6}) =>
    _sheet(title, note, [
      for (final t in const [0, 10, 30, 60])
        _cell(
            _under(kind, _button(), seconds: t.toDouble(), fall: fall),
            _under(kind, _panel(), seconds: t.toDouble(), fall: fall, seed: 7),
            '$t s'),
    ]);

Widget _knockSheet() => _sheet(
        'Snow: a tap knocks it off',
        'Heavy cap (60 s), then a tap: it lifts and falls in a puff, then builds again from nothing.',
        [
          _cell(
              _under(WeatherKind.snow, _button(), seconds: 60, fall: 0.6),
              _under(WeatherKind.snow, _panel(),
                  seconds: 60, fall: 0.6, seed: 7),
              'before'),
          _cell(
              _under(WeatherKind.snow, _button(),
                  seconds: 60, fall: 0.6, knock: 0.15, levelBefore: 1),
              _under(WeatherKind.snow, _panel(),
                  seconds: 60, fall: 0.6, knock: 0.15, levelBefore: 1, seed: 7),
              'tap'),
          _cell(
              _under(WeatherKind.snow, _button(),
                  seconds: 60, fall: 0.6, knock: 0.5, levelBefore: 1),
              _under(WeatherKind.snow, _panel(),
                  seconds: 60, fall: 0.6, knock: 0.5, levelBefore: 1, seed: 7),
              '+0.2 s'),
          _cell(
              _under(WeatherKind.snow, _button(), seconds: 0, fall: 0.6),
              _under(WeatherKind.snow, _panel(),
                  seconds: 0, fall: 0.6, seed: 7),
              '+0.5 s'),
          _cell(
              _under(WeatherKind.snow, _button(), seconds: 12, fall: 0.6),
              _under(WeatherKind.snow, _panel(),
                  seconds: 12, fall: 0.6, seed: 7),
              '+12 s'),
        ]);

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> shoot(WidgetTester tester, Widget w, String name,
      {double scale = 2, double height = 1400}) async {
    final key = GlobalKey();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(360, height);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: InkFonts.prose),
        home: Scaffold(
            backgroundColor: inkDeep,
            body: SingleChildScrollView(
                child: RepaintBoundary(key: key, child: w)))));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(tester.takeException(), isNull, reason: name);
    await tester.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: scale);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('accumulation sheets and clip frames', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    await tester.runAsync(InkImages.preload);
    Directory(shots!).createSync(recursive: true);
    addTearDown(tester.view.reset);
    await shoot(
        tester,
        _timeline(WeatherKind.snow, 'Snow builds up',
            'Fall 0.6: a dusting at 0 s, heavy at about 50 s. Soft drifts, thickest windward.'),
        'snow-accumulation');
    await shoot(tester, _knockSheet(), 'snow-knock');
    await shoot(
        tester,
        _timeline(WeatherKind.dust, 'Sand builds up',
            'The same idea in sand: a drift with ripples.'),
        'sand-accumulation');
    await shoot(
        tester,
        _timeline(WeatherKind.ash, 'Ash settles',
            'Dark soot, a few embers glowing in it.'),
        'ash-accumulation');
    await shoot(
        tester,
        _timeline(WeatherKind.rain, 'Rain: wetness builds',
            'Darker over a few seconds, then the drips start (fall 0.6).'),
        'rain-accumulation');

    // The clip: one button and one panel, 60 s of snow in 8 s (x7.5), a tap at
    // 5.6 s of the clip (42 s of snow), then it builds again.
    final frames = Directory('$shots/frames')..createSync(recursive: true);
    const fps = 12;
    const total = 96;
    for (var f = 0; f < total; f++) {
      final clip = f / fps;
      var seconds = clip * 7.5;
      var knock = 0.0;
      const tapAt = 5.6;
      if (clip >= tapAt) {
        final since = clip - tapAt;
        if (since < 0.5) {
          knock = since / 0.5;
          seconds = tapAt * 7.5;
        } else {
          seconds = (since - 0.5) * 7.5;
        }
      }
      final w = _sheet('Snow, 60 s in 8 s', 'x7.5, a tap at 5.6 s', [
        _cell(
            _under(WeatherKind.snow, _button(),
                seconds: seconds, fall: 0.6, knock: knock, levelBefore: 0.85),
            _under(WeatherKind.snow, _panel(),
                seconds: seconds,
                fall: 0.6,
                knock: knock,
                levelBefore: 0.85,
                seed: 7),
            '${seconds.round()} s'),
      ]);
      await shoot(tester, w, 'frames/f${f.toString().padLeft(3, '0')}',
          scale: 1, height: 200);
    }
    expect(frames.listSync().length, total);
  });
}
