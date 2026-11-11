import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fonts.dart';

const _ink = Color(0xFF14121A);
const _iron = Color(0xFF6B6F78);
const _ironLight = Color(0xFF9AA0AB);
const _gold = Color(0xFFE0B04A);
const _blood = Color(0xFFB0413E);
const _band = [Color(0xFF1C2030), Color(0xFF26262C), Color(0xFF241C2E)];

class BoardPainter extends CustomPainter {
  BoardPainter(this.hero, {this.cols = 5});
  final int hero;
  final int cols;
  Offset center(int n, Size s, double cw, double ch, double top) {
    final i = n - 1;
    final row = i ~/ cols;
    var c = i % cols;
    if (row.isOdd) c = cols - 1 - c;
    final rows = (30 / cols).ceil();
    return Offset(c * cw + cw / 2, top + (rows - 1 - row) * ch + ch / 2);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final cw = s.width / cols;
    final rows = (30 / cols).ceil();
    final ch = (s.height - 8) / rows;
    const top = 4.0;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void text(String t, Offset c, double size, Color col, {bool bold = false}) {
      tp.text = TextSpan(
          text: t,
          style: TextStyle(
              fontSize: size,
              fontFamily: 'PixelifySans',
              color: col,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500));
      tp.layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    for (var n = 1; n <= 30; n++) {
      final c = center(n, s, cw, ch, top);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: cw - 6, height: ch - 6),
          const Radius.circular(4));
      final band = (n - 1) ~/ 10;
      final boss = n % 10 == 0, warden = n % 10 == 5;
      canvas.drawRRect(r, Paint()..color = _band[band]);
      canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = boss ? 3 : 2
            ..color = boss ? _blood : (n <= hero ? _gold.withValues(alpha: .7) : _iron));
      // rivets
      for (final d in [r.tlRadius, r.trRadius]) {
        d;
      }
      for (final dx in [-1.0, 1.0]) {
        for (final dy in [-1.0, 1.0]) {
          canvas.drawCircle(
              c + Offset(dx * (cw / 2 - 8), dy * (ch / 2 - 8)), 1.5,
              Paint()..color = _ironLight.withValues(alpha: .6));
        }
      }
      if (warden) {
        final p = Path()
          ..moveTo(c.dx - 9, c.dy - 22)
          ..lineTo(c.dx + 9, c.dy - 22)
          ..lineTo(c.dx + 9, c.dy - 12)
          ..lineTo(c.dx, c.dy - 6)
          ..lineTo(c.dx - 9, c.dy - 12)
          ..close();
        canvas.drawPath(p, Paint()..color = _iron);
        canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = _ironLight);
      }
      if (boss) {
        // skull-ish crown mark
        canvas.drawCircle(c + const Offset(0, -14), 6,
            Paint()..color = _blood.withValues(alpha: .85));
      }
      text('$n', c + Offset(-(cw / 2 - 17), -(ch / 2 - 15)), 15,
          n == hero ? _gold : Colors.white70, bold: n == hero || boss);
    }
    // a ladder: 3 -> 8 (climb), a snake: 17 -> 12 (fall)
    final a = center(3, s, cw, ch, top), b = center(8, s, cw, ch, top);
    for (final k in [-5.0, 5.0]) {
      canvas.drawLine(a + Offset(k, 0), b + Offset(k, 0),
          Paint()..color = const Color(0xFFB08A55)..strokeWidth = 3);
    }
    final steps = 5;
    for (var i = 1; i < steps; i++) {
      final p = Offset.lerp(a, b, i / steps)!;
      canvas.drawLine(p + const Offset(-5, 0), p + const Offset(5, 0),
          Paint()..color = const Color(0xFFB08A55)..strokeWidth = 2);
    }
    final sa = center(17, s, cw, ch, top), sb = center(12, s, cw, ch, top);
    final path = Path()..moveTo(sa.dx, sa.dy);
    const wig = 14.0;
    for (var i = 1; i <= 24; i++) {
      final t = i / 24;
      final p = Offset.lerp(sa, sb, t)!;
      path.lineTo(p.dx + math.sin(t * math.pi * 4) * wig, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF5E8C4A));
    canvas.drawCircle(sa, 6, Paint()..color = const Color(0xFF5E8C4A));
    // hero token
    final h = center(hero, s, cw, ch, top) + const Offset(0, 4);
    canvas.drawCircle(h + const Offset(0, 14), 9,
        Paint()..color = Colors.black54);
    canvas.drawCircle(h, 11, Paint()..color = _gold);
    canvas.drawCircle(
        h,
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF3A2A0A));
    
  }

  @override
  bool shouldRepaint(_) => true;
}

class StairPainter extends CustomPainter {
  StairPainter(this.t, this.full);
  final double t;
  final bool full;
  @override
  void paint(Canvas canvas, Size s) {
    if (!full) {
      // left rail: floors 12 -> 13 stepping one notch
      const w = 40.0;
      for (var i = 0; i < 6; i++) {
        final y = s.height - 24 - i * 28.0;
        final wi = i == 3 ? 28.0 : 20.0;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(w / 2, y), width: wi, height: 22),
                const Radius.circular(6)),
            Paint()..color = const Color(0xFF211E28));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(w / 2, y), width: wi, height: 22),
                const Radius.circular(6)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = i <= 2 ? _gold : _iron);
      }
      final e = Curves.easeInOut.transform(t);
      final y = s.height - 24 - (2 + e) * 28.0 - 2 * math.sin(e * math.pi) * 6;
      canvas.drawCircle(Offset(w / 2, y - 8), 7, Paint()..color = _gold);
      canvas.drawCircle(Offset(w / 2, y + 1), 5, Paint()..color = _gold.withValues(alpha: .7));
      return;
    }
    // full-width stair
    final steps = 6;
    final sw = s.width / steps, sh = s.height / (steps + 1);
    for (var i = 0; i < steps; i++) {
      final r = Rect.fromLTWH(i * sw, s.height - (i + 1) * sh, sw + 1, (i + 1) * sh);
      canvas.drawRect(r, Paint()..color = Color.lerp(const Color(0xFF26262C), const Color(0xFF3A3A44), i / steps)!);
      canvas.drawRect(
          Rect.fromLTWH(r.left, r.top, r.width, 4), Paint()..color = _ironLight.withValues(alpha: .5));
      canvas.drawRect(r, Paint()..style = PaintingStyle.stroke..color = _iron);
    }
    final p = Curves.easeInOut.transform(t) * (steps - 1);
    final i = p.floor().clamp(0, steps - 2);
    final f = p - i;
    final x = (i + f + .5) * sw;
    final y = s.height - (i + 1 + f) * sh - 14 - math.sin(f * math.pi) * 14;
    canvas.drawCircle(Offset(x, y), 12, Paint()..color = _gold);
    canvas.drawCircle(Offset(x, y), 12, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF3A2A0A));
    final tp = TextPainter(
        text: const TextSpan(text: ' ', style: TextStyle(fontSize: 1)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => true;
}

Future<void> _save(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(d!.buffer.asUint8List());
  });
}

void main() {
  final out = Platform.environment['UX_SHOTS'];
  setUpAll(loadAppFonts);
  Future<void> shot(WidgetTester tester, double w, double h, Widget child, String name) async {
    await tester.binding.setSurfaceSize(Size(w, h));
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: key, child: Material(color: _ink, child: child))));
    await tester.pump();
    await _save(tester, key, '$out/$name.png');
  }

  testWidgets('board', skip: out == null, (tester) async {
    for (final w in [412.0, 360.0]) {
      await shot(tester, w, 560, Padding(padding: const EdgeInsets.all(8), child: CustomPaint(size: Size.infinite, painter: BoardPainter(13))), 'board-${w.toInt()}');
    }
  });

  testWidgets('stairs', skip: out == null, (tester) async {
    for (var i = 0; i < 4; i++) {
      final t = i / 3;
      await shot(tester, 120, 200, CustomPaint(size: Size.infinite, painter: StairPainter(t, false)), 'a-$i');
      await shot(tester, 412, 220, CustomPaint(size: Size.infinite, painter: StairPainter(t, true)), 'b-$i');
    }
  });
}
