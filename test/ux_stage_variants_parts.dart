// UX mock (pictures only, nothing here ships): new fight/scene stages drawn
// in the style of lib/widgets/fight_backdrop.dart, to choose from before any of
// them goes into lib. Same recipe: a sky, a far and a mid line, a ground, and
// a few shapes of the stage's own.
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum NewStage {
  ruins,
  woods,
  ford,
  burntFields,
  oasis,
  caravanRoad,
  quay,
  pass,
}

class _Look {
  const _Look(this.skyTop, this.skyLow, this.far, this.mid, this.ground,
      this.dark, this.light);
  final Color skyTop, skyLow, far, mid, ground, dark, light;
}

const _looks = {
  NewStage.ruins: _Look(
      Color(0xFF6B6560),
      Color(0xFFB8AB9B),
      Color(0xFF4F4A46),
      Color(0xFF3F3B38),
      Color(0xFF4C453E),
      Color(0xFF2A2724),
      Color(0xFFE2C79A)),
  NewStage.woods: _Look(
      Color(0xFF7E967F),
      Color(0xFFC3D0B2),
      Color(0xFF4F6A4C),
      Color(0xFF3B5339),
      Color(0xFF3A4A30),
      Color(0xFF22301F),
      Color(0xFFF1EBB8)),
  NewStage.ford: _Look(
      Color(0xFF7799AE),
      Color(0xFFD4DEC9),
      Color(0xFF7C927A),
      Color(0xFF63794F),
      Color(0xFF566B42),
      Color(0xFF3F5030),
      Color(0xFFCFE6EE)),
  NewStage.burntFields: _Look(
      Color(0xFF7A5A4A),
      Color(0xFFD99A68),
      Color(0xFF4A3B33),
      Color(0xFF3A2F2A),
      Color(0xFF2F2723),
      Color(0xFF1B1613),
      Color(0xFFFFB45C)),
  NewStage.oasis: _Look(
      Color(0xFFD9A15E),
      Color(0xFFF2D9A4),
      Color(0xFFC99A5A),
      Color(0xFFB8864A),
      Color(0xFFC79A58),
      Color(0xFF7F5A2E),
      Color(0xFFFFF1CC)),
  NewStage.caravanRoad: _Look(
      Color(0xFFD28E5A),
      Color(0xFFF0CFA0),
      Color(0xFFB98650),
      Color(0xFFA9783F),
      Color(0xFFB98B4C),
      Color(0xFF7F5A2E),
      Color(0xFFFFF1CC)),
  NewStage.quay: _Look(
      Color(0xFF2F4A66),
      Color(0xFFC59A78),
      Color(0xFF27425C),
      Color(0xFF1F364B),
      Color(0xFF5A4636),
      Color(0xFF2C2118),
      Color(0xFFFFC66B)),
  NewStage.pass: _Look(
      Color(0xFF8AA0AE),
      Color(0xFFDCD3BC),
      Color(0xFF8B8576),
      Color(0xFF6E685B),
      Color(0xFF8A8068),
      Color(0xFF4F4A3E),
      Color(0xFFF1E7C9)),
};

double _h(num n) {
  final x = math.sin(n * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

/// One stage, at [size], [light] 1 by day down to 0.15 in the dark.
void paintNewStage(Canvas canvas, Size size, NewStage stage,
    {double light = 1, bool rain = false}) {
  final s = _looks[stage]!;
  final w = size.width, h = size.height;
  final horizon = h * 0.5;
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [s.skyTop, s.skyLow],
        stops: const [0.0, 0.55],
      ).createShader(Offset.zero & size),
  );
  switch (stage) {
    case NewStage.ruins:
      _birds(canvas, size, s.dark);
      _hills(canvas, size, horizon, s.far, 0.04, 1.2, 2);
      _walls(canvas, size, horizon + h * 0.02, s);
      _ground(canvas, size, horizon + h * 0.08, s);
      _rubble(canvas, size, horizon + h * 0.08, s);
    case NewStage.woods:
      _hills(canvas, size, horizon - h * 0.02, s.far, 0.03, 1.4, 5);
      _treeRow(canvas, size, horizon - h * 0.01, s.far, 0.07, 13, 1);
      _ground(canvas, size, horizon + h * 0.05, s);
      _treeRow(canvas, size, horizon + h * 0.04, s.mid, 0.11, 7, 2);
      _shafts(canvas, size, s.light);
      _litter(canvas, size, horizon + h * 0.05, s.dark);
      _treeRow(canvas, size, h * 0.95, s.dark, 0.3, 3, 3, trunksOnly: true);
    case NewStage.ford:
      _hills(canvas, size, horizon, s.far, 0.05, 1.3, 0);
      _hills(canvas, size, horizon + h * 0.04, s.mid, 0.06, 0.9, 3);
      _ground(canvas, size, horizon + h * 0.1, s);
      _river(canvas, size, horizon + h * 0.1, s);
      _bridge(canvas, size, horizon + h * 0.12, s);
    case NewStage.burntFields:
      _smoke(canvas, size, horizon, s);
      _hills(canvas, size, horizon, s.far, 0.04, 1.1, 1);
      _ground(canvas, size, horizon + h * 0.06, s);
      _furrows(canvas, size, horizon + h * 0.06, s.dark);
      _posts(canvas, size, horizon + h * 0.08, s.dark);
      _embers(canvas, size, horizon + h * 0.06, s.light);
    case NewStage.oasis:
      _sun(canvas, size, Offset(w * 0.78, horizon - h * 0.15), s.light, 24);
      _hills(canvas, size, horizon, s.far, 0.06, 0.8, 1);
      _hills(canvas, size, horizon + h * 0.05, s.mid, 0.08, 0.6, 5);
      _ground(canvas, size, horizon + h * 0.12, s);
      _pool(canvas, size, horizon + h * 0.2);
      _palm(canvas, size, Offset(w * 0.18, horizon + h * 0.2), h * 0.22, s.dark,
          1);
      _palm(canvas, size, Offset(w * 0.3, horizon + h * 0.18), h * 0.17, s.dark,
          -1);
      _palm(canvas, size, Offset(w * 0.86, horizon + h * 0.21), h * 0.2, s.dark,
          -1);
    case NewStage.caravanRoad:
      _sun(canvas, size, Offset(w * 0.25, horizon - h * 0.17), s.light, 26);
      _hills(canvas, size, horizon, s.far, 0.06, 0.8, 4);
      _caravan(canvas, size, horizon - h * 0.004, s.dark);
      _hills(canvas, size, horizon + h * 0.05, s.mid, 0.07, 0.6, 7);
      _ground(canvas, size, horizon + h * 0.12, s);
      _ruts(canvas, size, horizon + h * 0.12, s);
      _bush(canvas, size, Offset(w * 0.12, horizon + h * 0.3), s.dark);
    case NewStage.quay:
      _sun(canvas, size, Offset(w * 0.2, horizon - h * 0.08), s.light, 22);
      _seaBand(canvas, size, horizon - h * 0.02, s);
      _masts(canvas, size, horizon - h * 0.02, s.dark);
      _planks(canvas, size, horizon + h * 0.05, s);
      _bollards(canvas, size, horizon + h * 0.05, s);
      _lamp(canvas, size, Offset(w * 0.14, horizon + h * 0.2), s);
      _lamp(canvas, size, Offset(w * 0.88, horizon + h * 0.16), s);
    case NewStage.pass:
      _peaksFar(canvas, size, horizon, s);
      _hills(canvas, size, horizon + h * 0.02, s.mid, 0.04, 1.0, 6);
      _ground(canvas, size, horizon + h * 0.1, s);
      _road(canvas, size, horizon + h * 0.1, s);
      _rockWall(canvas, size, true, s);
      _rockWall(canvas, size, false, s);
  }
  if (rain) _rainFall(canvas, size);
  if (light < 1) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFF070A18).withValues(alpha: (1 - light) * 0.7),
    );
  }
  canvas.restore();
}

// --- shared pieces (the same recipe as fight_backdrop.dart) -----------------

void _ground(Canvas canvas, Size size, double y, _Look s) {
  final rect = Rect.fromLTRB(0, y, size.width, size.height);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [s.ground, s.dark],
      ).createShader(rect),
  );
}

void _hills(Canvas canvas, Size size, double base, Color colour, double amp,
    double freq, int seed) {
  final path = Path()..moveTo(0, size.height);
  for (var x = 0.0; x <= size.width; x += 4) {
    final y = base -
        size.height *
            amp *
            (0.5 +
                0.5 *
                    math.sin(
                        x / size.width * math.pi * 2 * freq + seed * 1.7)) -
        size.height * amp * 0.4 * math.sin(x / size.width * 7 + seed);
    path.lineTo(x, y);
  }
  path
    ..lineTo(size.width, size.height)
    ..close();
  canvas.drawPath(path, Paint()..color = colour);
}

void _sun(Canvas canvas, Size size, Offset at, Color colour, double radius) {
  canvas.drawCircle(
      at,
      radius * 2.4,
      Paint()
        ..shader = RadialGradient(colors: [
          colour.withValues(alpha: 0.45),
          colour.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: at, radius: radius * 2.4)));
  canvas.drawCircle(at, radius, Paint()..color = colour);
}

void _furrows(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()
    ..color = colour.withValues(alpha: 0.5)
    ..strokeWidth = 1;
  final vanish = Offset(size.width / 2, y);
  for (var i = -9; i <= 9; i++) {
    canvas.drawLine(vanish,
        Offset(size.width / 2 + i * size.width * 0.16, size.height), paint);
  }
}

// ruins
void _birds(Canvas canvas, Size size, Color colour) {
  final p = Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  for (var i = 0; i < 7; i++) {
    final x = size.width * (0.1 + 0.8 * _h(i + 3));
    final y = size.height * (0.1 + 0.2 * _h(i + 9));
    canvas.drawPath(
        Path()
          ..moveTo(x - 6, y - 3)
          ..quadraticBezierTo(x - 2, y + 2, x, y)
          ..quadraticBezierTo(x + 2, y + 2, x + 6, y - 3),
        p);
  }
}

void _walls(Canvas canvas, Size size, double y, _Look s) {
  final w = size.width, h = size.height;
  for (var i = 0; i < 6; i++) {
    final x = w * (0.02 + 0.17 * i);
    final top = y - h * (0.05 + 0.1 * _h(i + 1));
    final width = w * (0.1 + 0.05 * _h(i + 4));
    final path = Path()..moveTo(x, y + 2);
    path.lineTo(x, top + 6);
    var cx = x;
    while (cx < x + width) {
      final step = 7 + 6 * _h(cx);
      final dip = 10 * _h(cx + 5);
      path.lineTo(cx, top + dip);
      cx += step;
      path.lineTo(cx, top + dip);
    }
    path
      ..lineTo(x + width, y + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = i.isEven ? s.mid : s.far);
    if (i == 2) {
      // A window arch with the sky in it.
      final r =
          Rect.fromLTWH(x + width * 0.3, top + 22, width * 0.34, h * 0.07);
      canvas.drawPath(
          Path()
            ..moveTo(r.left, r.bottom)
            ..lineTo(r.left, r.top + r.width / 2)
            ..arcToPoint(Offset(r.right, r.top + r.width / 2),
                radius: Radius.circular(r.width / 2))
            ..lineTo(r.right, r.bottom)
            ..close(),
          Paint()..color = s.skyLow);
    }
  }
}

void _rubble(Canvas canvas, Size size, double y, _Look s) {
  for (var i = 0; i < 26; i++) {
    final x = size.width * _h(i + 20);
    final yy = y + (size.height - y) * math.pow(_h(i + 40), 1.4);
    final r = 3 + 12 * (yy - y) / (size.height - y) * (0.5 + _h(i));
    canvas.drawPath(
        Path()
          ..moveTo(x - r, yy)
          ..lineTo(x - r * 0.4, yy - r * 0.7)
          ..lineTo(x + r * 0.8, yy - r * 0.5)
          ..lineTo(x + r, yy)
          ..close(),
        Paint()..color = i.isEven ? s.dark : s.mid);
  }
}

// woods
void _treeRow(Canvas canvas, Size size, double y, Color colour, double scale,
    int count, int seed,
    {bool trunksOnly = false}) {
  for (var i = 0; i < count; i++) {
    final x = size.width * ((i + 0.5 + (_h(i + seed * 7) - 0.5) * 0.7) / count);
    final hh = size.height * scale * (0.8 + 0.5 * _h(i + seed));
    final tw = hh * 0.1;
    canvas.drawRect(
        Rect.fromLTWH(x - tw / 2, y - hh, tw, hh), Paint()..color = colour);
    if (trunksOnly) continue;
    for (var k = 0; k < 4; k++) {
      canvas.drawCircle(
          Offset(x + (k - 1.5) * hh * 0.12, y - hh - hh * 0.05 * (k % 2)),
          hh * (0.2 + 0.05 * _h(i + k)),
          Paint()..color = colour);
    }
  }
}

void _shafts(Canvas canvas, Size size, Color colour) {
  for (var i = 0; i < 4; i++) {
    final x = size.width * (0.15 + 0.22 * i);
    canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + 26, 0)
          ..lineTo(x + 110, size.height * 0.75)
          ..lineTo(x + 50, size.height * 0.75)
          ..close(),
        Paint()..color = colour.withValues(alpha: 0.1));
  }
}

void _litter(Canvas canvas, Size size, double y, Color colour) {
  for (var i = 0; i < 60; i++) {
    final x = size.width * _h(i + 70);
    final yy = y + (size.height - y) * _h(i + 90);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, yy), width: 7, height: 2.5),
        Paint()..color = colour.withValues(alpha: 0.6));
  }
}

// ford
void _river(Canvas canvas, Size size, double y, _Look s) {
  final path = Path()
    ..moveTo(0, y + size.height * 0.04)
    ..quadraticBezierTo(size.width * 0.5, y - size.height * 0.03, size.width,
        y + size.height * 0.07)
    ..lineTo(size.width, y + size.height * 0.2)
    ..quadraticBezierTo(
        size.width * 0.5, y + size.height * 0.1, 0, y + size.height * 0.19)
    ..close();
  canvas.drawPath(path, Paint()..color = const Color(0xFF4F7FA0));
  final glint = Paint()
    ..color = s.light.withValues(alpha: 0.55)
    ..strokeWidth = 1.4;
  for (var i = 0; i < 12; i++) {
    final x = size.width * _h(i + 5);
    final yy = y + size.height * (0.05 + 0.1 * _h(i + 8));
    canvas.drawLine(Offset(x, yy), Offset(x + 14, yy), glint);
  }
}

void _bridge(Canvas canvas, Size size, double y, _Look s) {
  final w = size.width, h = size.height;
  final x0 = w * 0.05, x1 = w * 0.6, deck = y + h * 0.02;
  canvas.drawRect(
      Rect.fromLTRB(x0, deck - 6, x1, deck + h * 0.05), Paint()..color = s.far);
  for (var i = 0; i < 3; i++) {
    final cx = x0 + (x1 - x0) * (0.2 + 0.3 * i);
    canvas.drawPath(
        Path()
          ..moveTo(cx - 28, deck + h * 0.05)
          ..quadraticBezierTo(cx, deck + h * 0.0, cx + 28, deck + h * 0.05)
          ..close(),
        Paint()..color = s.dark);
  }
}

// burnt fields
void _smoke(Canvas canvas, Size size, double y, _Look s) {
  for (var i = 0; i < 4; i++) {
    final x = size.width * (0.12 + 0.26 * i);
    final p = Path()
      ..moveTo(x - 8, y)
      ..cubicTo(x - 20, y - size.height * 0.15, x + 24, y - size.height * 0.28,
          x - 4, y - size.height * 0.42)
      ..lineTo(x + 30, y - size.height * 0.42)
      ..cubicTo(x + 36, y - size.height * 0.28, x + 4, y - size.height * 0.15,
          x + 10, y)
      ..close();
    canvas.drawPath(p, Paint()..color = s.dark.withValues(alpha: 0.35));
  }
}

void _posts(Canvas canvas, Size size, double y, Color colour) {
  final p = Paint()
    ..color = colour
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 9; i++) {
    final x = size.width * (0.04 + 0.12 * i);
    final yy = y + (size.height - y) * 0.15 * (i % 3) + 10;
    final hh = 14.0 + 10 * (i % 3);
    canvas.drawLine(Offset(x, yy), Offset(x + (i.isEven ? 3 : -3), yy - hh), p);
  }
}

void _embers(Canvas canvas, Size size, double y, Color colour) {
  for (var i = 0; i < 34; i++) {
    final x = size.width * _h(i + 120);
    final yy = y + (size.height - y) * _h(i + 140);
    canvas.drawCircle(Offset(x, yy), 1.2 + 1.2 * _h(i),
        Paint()..color = colour.withValues(alpha: 0.5 + 0.4 * _h(i + 3)));
  }
}

// oasis
void _pool(Canvas canvas, Size size, double y) {
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.52, y),
      width: size.width * 0.5,
      height: size.height * 0.07);
  canvas.drawOval(r, Paint()..color = const Color(0xFF3C95A0));
  canvas.drawOval(r.deflate(7),
      Paint()..color = const Color(0xFF63BAC0).withValues(alpha: 0.7));
}

void _palm(Canvas canvas, Size size, Offset base, double height, Color colour,
    int lean) {
  final trunk = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(base.dx + lean * 14, base.dy - height * 0.5,
        base.dx + lean * 8, base.dy - height);
  canvas.drawPath(
      trunk,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.06
        ..color = colour);
  final top = Offset(base.dx + lean * 8, base.dy - height);
  final frond = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = colour;
  for (var i = -3; i <= 3; i++) {
    final a = -math.pi / 2 + i * 0.5;
    final end = top +
        Offset(math.cos(a), math.sin(a)) * height * 0.5 +
        Offset(0, height * 0.12 * i.abs());
    canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(top.dx + (end.dx - top.dx) * 0.6,
              top.dy - height * 0.12, end.dx, end.dy),
        frond);
  }
}

// caravan road
void _caravan(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()..color = colour;
  for (var i = 0; i < 5; i++) {
    final x = size.width * (0.5 + 0.075 * i);
    final u = size.height * 0.03;
    canvas.drawRect(Rect.fromLTWH(x, y - u * 0.9, u * 0.95, u * 0.55), paint);
    canvas.drawCircle(Offset(x + u * 0.5, y - u * 1.15), u * 0.28, paint);
    canvas.drawRect(
        Rect.fromLTWH(x + u * 1.2, y - u * 1.5, u * 0.18, u * 0.7), paint);
    canvas.drawCircle(Offset(x + u * 0.9, y - u * 1.55), u * 0.2, paint);
    for (final lx in [0.05, 0.3, 0.65, 0.85]) {
      canvas.drawRect(
          Rect.fromLTWH(x + u * lx, y - u * 0.4, u * 0.1, u * 0.45), paint);
    }
  }
}

void _ruts(Canvas canvas, Size size, double y, _Look s) {
  final vanish = Offset(size.width * 0.5, y);
  for (final dx in [-0.18, 0.18]) {
    final rut = Path()
      ..moveTo(vanish.dx + dx * 6, y)
      ..lineTo(size.width * (0.5 + dx * 2.6) - 14, size.height)
      ..lineTo(size.width * (0.5 + dx * 2.6) + 14, size.height)
      ..lineTo(vanish.dx + dx * 6 + 2, y)
      ..close();
    canvas.drawPath(rut, Paint()..color = s.dark.withValues(alpha: 0.45));
  }
}

void _bush(Canvas canvas, Size size, Offset at, Color colour) {
  for (var i = 0; i < 9; i++) {
    final a = -math.pi * (0.1 + 0.8 * i / 8);
    canvas.drawLine(
        at,
        at + Offset(math.cos(a), math.sin(a)) * 26,
        Paint()
          ..color = colour
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
  }
}

// quay
void _seaBand(Canvas canvas, Size size, double y, _Look s) {
  final r = Rect.fromLTRB(0, y, size.width, y + size.height * 0.1);
  canvas.drawRect(r, Paint()..color = s.far);
  for (var i = 0; i < 8; i++) {
    canvas.drawLine(
        Offset(size.width * _h(i + 6), y + 6 + 5 * i),
        Offset(size.width * _h(i + 6) + 26, y + 6 + 5 * i),
        Paint()..color = s.light.withValues(alpha: 0.35));
  }
}

void _masts(Canvas canvas, Size size, double y, Color colour) {
  final p = Paint()
    ..color = colour
    ..strokeWidth = 2.4;
  for (var i = 0; i < 5; i++) {
    final x = size.width * (0.1 + 0.2 * i + 0.04 * _h(i));
    final hh = size.height * (0.16 + 0.1 * _h(i + 3));
    canvas.drawLine(Offset(x, y), Offset(x, y - hh), p);
    canvas.drawLine(
        Offset(x - 12, y - hh * 0.7), Offset(x + 12, y - hh * 0.7), p);
    canvas.drawPath(
        Path()
          ..moveTo(x + 2, y - hh * 0.9)
          ..lineTo(x + 18, y - hh * 0.35)
          ..lineTo(x + 2, y - hh * 0.35)
          ..close(),
        Paint()..color = colour.withValues(alpha: 0.85));
  }
}

void _planks(Canvas canvas, Size size, double y, _Look s) {
  _ground(canvas, size, y, s);
  final line = Paint()
    ..color = s.dark.withValues(alpha: 0.7)
    ..strokeWidth = 1.2;
  final vanish = Offset(size.width * 0.5, y - 40);
  for (var i = -12; i <= 12; i++) {
    canvas.drawLine(vanish,
        Offset(size.width * 0.5 + i * size.width * 0.14, size.height), line);
  }
  for (var k = 1; k < 8; k++) {
    final yy = y + (size.height - y) * math.pow(k / 8, 1.8);
    canvas.drawLine(Offset(0, yy), Offset(size.width, yy), line);
  }
}

void _bollards(Canvas canvas, Size size, double y, _Look s) {
  for (var i = 0; i < 5; i++) {
    final x = size.width * (0.08 + 0.21 * i);
    final yy = y + (size.height - y) * (0.12 + 0.1 * (i % 3));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, yy, 12, 18), const Radius.circular(3)),
        Paint()..color = s.dark);
  }
}

void _lamp(Canvas canvas, Size size, Offset base, _Look s) {
  canvas.drawLine(
      base,
      base - const Offset(0, 90),
      Paint()
        ..color = s.dark
        ..strokeWidth = 3);
  final at = base - const Offset(0, 96);
  canvas.drawCircle(
      at,
      40,
      Paint()
        ..shader = RadialGradient(colors: [
          s.light.withValues(alpha: 0.6),
          s.light.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: at, radius: 40)));
  canvas.drawCircle(at, 5, Paint()..color = s.light);
}

// pass
void _peaksFar(Canvas canvas, Size size, double y, _Look s) {
  final path = Path()..moveTo(0, y);
  final pts = [0.0, 0.14, 0.26, 0.42, 0.58, 0.72, 0.86, 1.0];
  final hs = [0.1, 0.22, 0.12, 0.27, 0.15, 0.24, 0.1, 0.18];
  for (var i = 0; i < pts.length; i++) {
    path.lineTo(size.width * pts[i], y - size.height * hs[i]);
  }
  path
    ..lineTo(size.width, y)
    ..close();
  canvas.drawPath(path, Paint()..color = s.far);
}

void _road(Canvas canvas, Size size, double y, _Look s) {
  final path = Path()
    ..moveTo(size.width * 0.5 - 6, y)
    ..cubicTo(size.width * 0.3, y + size.height * 0.12, size.width * 0.75,
        y + size.height * 0.25, size.width * 0.3, size.height)
    ..lineTo(size.width * 0.78, size.height)
    ..cubicTo(size.width * 0.9, y + size.height * 0.25, size.width * 0.62,
        y + size.height * 0.12, size.width * 0.5 + 6, y)
    ..close();
  canvas.drawPath(path, Paint()..color = s.light.withValues(alpha: 0.45));
}

void _rockWall(Canvas canvas, Size size, bool left, _Look s) {
  final w = size.width, h = size.height;
  final path = Path()..moveTo(left ? 0 : w, h * 0.12);
  final dir = left ? 1 : -1;
  final pts = [
    [0.1, 0.12],
    [0.16, 0.3],
    [0.1, 0.42],
    [0.2, 0.52],
    [0.12, 0.7],
    [0.0, 0.78]
  ];
  for (final p in pts) {
    path.lineTo(left ? w * p[0] : w * (1 - p[0]), h * p[1]);
  }
  path
    ..lineTo(left ? 0 : w, h * 0.78)
    ..close();
  canvas.drawPath(
      path, Paint()..color = left ? s.mid : s.dark.withValues(alpha: 0.9));
  canvas.drawLine(
      Offset(left ? w * 0.04 : w * 0.96, h * 0.2),
      Offset(left ? w * 0.08 * dir + w * 0.0 : w - w * 0.08, h * 0.4),
      Paint()
        ..color = s.far
        ..strokeWidth = 2);
}

void _rainFall(Canvas canvas, Size size) {
  final p = Paint()
    ..color = const Color(0xFFBFDCE6).withValues(alpha: 0.5)
    ..strokeWidth = 1.2;
  for (var i = 0; i < 70; i++) {
    final x = size.width * _h(i + 200);
    final y = size.height * _h(i + 300);
    canvas.drawLine(Offset(x, y), Offset(x - 5, y + 16), p);
  }
}
