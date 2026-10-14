// The land under a place on the Journey map (v1.197): the zone's biome
// (see geography.dart) painted in code, faint, under the place's own plan
// -- furrowed fields, dunes, cracked salt, waves, ash drifts, terraces,
// cliffs, reeds, snowdrifts or glass shards.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/geography.dart';

/// [biome]'s ground under a place: a thin wash of its colour over the
/// look's [land], and its pattern in a faint line, drawn from [seed] so
/// a place looks the same each visit. [greyed] (the Shroud look) keeps it
/// grey. Drawn a little past the edges, for the map moving with the party.
class BiomeBackdropPainter extends CustomPainter {
  BiomeBackdropPainter({
    required this.biome,
    required this.land,
    required this.seed,
    this.greyed = false,
  });

  final Biome biome;
  final Color land;
  final int seed;
  final bool greyed;

  static const double _margin = 40;

  Color _tone(Color colour) {
    if (!greyed) return colour;
    final v = 0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b;
    return Color.from(alpha: colour.a, red: v, green: v, blue: v);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(-_margin, -_margin, size.width + _margin * 2,
        size.height + _margin * 2);
    final dark = land.computeLuminance() < 0.2;
    final palette = biome.palette;
    // The wash: the biome's ground laid thin over the look's land.
    canvas.drawRect(
        area,
        Paint()
          ..color =
              _tone(palette.ground).withValues(alpha: dark ? 0.10 : 0.16));
    final ink = _BackdropInk(
      line: _tone(dark ? palette.accent : palette.detail)
          .withValues(alpha: dark ? 0.20 : 0.30),
      soft: _tone(palette.ground).withValues(alpha: dark ? 0.14 : 0.22),
      light: _tone(palette.accent).withValues(alpha: dark ? 0.16 : 0.34),
      water: _tone(palette.water).withValues(alpha: dark ? 0.22 : 0.26),
    );
    final rng = math.Random(seed ^ biome.pattern.index * 7919);
    canvas.save();
    canvas.clipRect(area);
    switch (biome.pattern) {
      case BiomePattern.fields:
        _fields(canvas, area, rng, ink);
      case BiomePattern.dunes:
        _dunes(canvas, area, rng, ink);
      case BiomePattern.saltFlats:
        _saltFlats(canvas, area, rng, ink);
      case BiomePattern.waves:
        _waves(canvas, area, rng, ink);
      case BiomePattern.ash:
        _ash(canvas, area, rng, ink);
      case BiomePattern.terraces:
        _terraces(canvas, area, rng, ink);
      case BiomePattern.cliffs:
        _cliffs(canvas, area, rng, ink);
      case BiomePattern.reeds:
        _reeds(canvas, area, rng, ink);
      case BiomePattern.snow:
        _snow(canvas, area, rng, ink);
      case BiomePattern.glass:
        _glass(canvas, area, rng, ink);
    }
    canvas.restore();
  }

  static Paint _stroke(Color colour, double width) => Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Offset _at(Rect area, math.Random rng) => Offset(
      area.left + rng.nextDouble() * area.width,
      area.top + rng.nextDouble() * area.height);

  static int _count(Rect area, double per) =>
      math.max(4, (area.width * area.height / per).round());

  /// Patches of furrowed field, each turned its own way, hedged.
  void _fields(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final furrow = _stroke(ink.line, 0.9);
    final hedge = _stroke(ink.soft, 2.4);
    for (var i = 0; i < _count(area, 9000); i++) {
      final c = _at(area, rng);
      final w = 40 + rng.nextDouble() * 50;
      final h = 24 + rng.nextDouble() * 28;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((rng.nextDouble() - 0.5) * 0.8);
      final patch = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRect(patch, hedge);
      canvas.clipRect(patch);
      final gap = 4.5 + rng.nextDouble() * 2;
      for (var y = patch.top + gap / 2; y < patch.bottom; y += gap) {
        canvas.drawLine(Offset(patch.left, y), Offset(patch.right, y), furrow);
      }
      canvas.restore();
    }
  }

  /// Long crescent ridges, shaded on their lee.
  void _dunes(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final ridge = _stroke(ink.line, 1.1);
    final lee = Paint()..color = ink.soft;
    for (var y = area.top + 18; y < area.bottom; y += 34) {
      var x = area.left - rng.nextDouble() * 60;
      while (x < area.right) {
        final length = 70 + rng.nextDouble() * 90;
        final rise = 8 + rng.nextDouble() * 10;
        final dy = y + (rng.nextDouble() - 0.5) * 14;
        final crest =
            Offset(x + length * (0.35 + rng.nextDouble() * 0.3), dy - rise);
        final top = Path()
          ..moveTo(x, dy)
          ..quadraticBezierTo(crest.dx, crest.dy, x + length, dy);
        canvas.drawPath(
            Path.from(top)
              ..quadraticBezierTo(
                  crest.dx + length * 0.1, dy - rise * 0.2, x, dy)
              ..close(),
            lee);
        canvas.drawPath(top, ridge);
        x += length + 10 + rng.nextDouble() * 40;
      }
    }
  }

  /// A crust of salt cracked into plates, with white flecks.
  void _saltFlats(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    const step = 34.0;
    final cols = (area.width / step).ceil() + 1;
    final rows = (area.height / step).ceil() + 1;
    final points = [
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < cols; c++)
            Offset(
              area.left +
                  c * step +
                  (r.isOdd ? step / 2 : 0) +
                  (rng.nextDouble() - 0.5) * step * 0.5,
              area.top + r * step + (rng.nextDouble() - 0.5) * step * 0.5,
            ),
        ],
    ];
    final crack = _stroke(ink.line, 0.8);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final p = points[r][c];
        if (c + 1 < cols) canvas.drawLine(p, points[r][c + 1], crack);
        if (r + 1 < rows) {
          canvas.drawLine(p, points[r + 1][c], crack);
          final diagonal = r.isOdd ? c + 1 : c - 1;
          if (diagonal >= 0 && diagonal < cols && rng.nextBool()) {
            canvas.drawLine(p, points[r + 1][diagonal], crack);
          }
        }
      }
    }
    final fleck = Paint()..color = ink.light;
    for (var i = 0; i < _count(area, 900); i++) {
      canvas.drawCircle(_at(area, rng), 0.8 + rng.nextDouble(), fleck);
    }
  }

  /// Rows of small wave crests.
  void _waves(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final crest = _stroke(ink.water, 1.2);
    for (var y = area.top + 10; y < area.bottom; y += 22) {
      var x = area.left + rng.nextDouble() * 30;
      while (x < area.right) {
        final w = 14 + rng.nextDouble() * 10;
        final dy = y + (rng.nextDouble() - 0.5) * 6;
        canvas.drawPath(
            Path()
              ..moveTo(x, dy)
              ..quadraticBezierTo(x + w / 4, dy - 4, x + w / 2, dy)
              ..quadraticBezierTo(x + w * 3 / 4, dy + 4, x + w, dy),
            crest);
        x += w + 18 + rng.nextDouble() * 30;
      }
    }
  }

  /// Ash blown into long drifts, and specks of it everywhere.
  void _ash(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final drift = _stroke(ink.line, 1.4);
    for (var i = 0; i < _count(area, 7000); i++) {
      final a = _at(area, rng);
      final length = 50 + rng.nextDouble() * 80;
      final b = a + Offset(length, length * 0.35);
      final bend = (rng.nextDouble() - 0.5) * 24;
      canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..cubicTo(a.dx + length * 0.3, a.dy + bend, b.dx - length * 0.3,
                b.dy - bend, b.dx, b.dy),
          drift);
    }
    final speck = Paint()..color = ink.line;
    for (var i = 0; i < _count(area, 500); i++) {
      canvas.drawCircle(_at(area, rng), 0.6 + rng.nextDouble() * 0.9, speck);
    }
  }

  /// Stepped bands across the slope, every other one shaded.
  void _terraces(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final edge = _stroke(ink.line, 1.1);
    final shade = Paint()..color = ink.soft;
    final phase = rng.nextDouble() * math.pi * 2;
    double wave(double x, double y) =>
        math.sin(x / 90 + phase + y / 140) * 10 + math.sin(x / 37) * 2;
    var band = 0;
    for (var y = area.top; y < area.bottom; y += 26, band++) {
      final top = Path();
      final bottom = <Offset>[];
      for (var x = area.left; x <= area.right + 12; x += 12) {
        final p = Offset(x, y + wave(x, y));
        if (x == area.left) {
          top.moveTo(p.dx, p.dy);
        } else {
          top.lineTo(p.dx, p.dy);
        }
        bottom.add(Offset(x, y + 9 + wave(x, y + 9)));
      }
      if (band.isEven) {
        final fill = Path.from(top);
        for (final p in bottom.reversed) {
          fill.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(fill..close(), shade);
      }
      canvas.drawPath(top, edge);
    }
  }

  /// Jagged cliff edges with hachures hanging under them.
  void _cliffs(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final edge = _stroke(ink.line, 1.3);
    final tick = _stroke(ink.line, 0.8);
    for (var i = 0; i < _count(area, 14000); i++) {
      final start = _at(area, rng);
      final points = [start];
      var p = start;
      final segments = 4 + rng.nextInt(4);
      for (var s = 0; s < segments; s++) {
        p = p +
            Offset(10 + rng.nextDouble() * 14, (rng.nextDouble() - 0.5) * 12);
        points.add(p);
      }
      canvas.drawPath(Path()..addPolygon(points, false), edge);
      for (var s = 0; s < points.length - 1; s++) {
        final a = points[s], b = points[s + 1];
        for (var t = 0.2; t < 1; t += 0.3) {
          final q = Offset.lerp(a, b, t)!;
          canvas.drawLine(q, q + Offset(-1.5, 5 + rng.nextDouble() * 5), tick);
        }
      }
    }
  }

  /// Clumps of reeds round still pools.
  void _reeds(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final pool = Paint()..color = ink.water;
    for (var i = 0; i < _count(area, 16000); i++) {
      final c = _at(area, rng);
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: 30 + rng.nextDouble() * 40,
              height: 10 + rng.nextDouble() * 12),
          pool);
    }
    final reed = _stroke(ink.line, 1);
    for (var i = 0; i < _count(area, 2200); i++) {
      final base = _at(area, rng);
      final stems = 3 + rng.nextInt(4);
      for (var s = 0; s < stems; s++) {
        final lean = (s - stems / 2) * 2.2 + (rng.nextDouble() - 0.5) * 2;
        final h = 8 + rng.nextDouble() * 9;
        final foot = base.translate(s * 1.6 - stems * 0.8, 0);
        canvas.drawPath(
            Path()
              ..moveTo(foot.dx, foot.dy)
              ..quadraticBezierTo(foot.dx + lean * 0.3, foot.dy - h * 0.6,
                  foot.dx + lean, foot.dy - h),
            reed);
      }
    }
  }

  /// Soft drifts piled by the wind, and falling flakes.
  void _snow(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final drift = Paint()..color = ink.light;
    final rim = _stroke(ink.line, 0.9);
    for (var i = 0; i < _count(area, 6500); i++) {
      final c = _at(area, rng);
      final w = 40 + rng.nextDouble() * 60;
      final h = 8 + rng.nextDouble() * 8;
      final mound = Path()
        ..moveTo(c.dx - w / 2, c.dy)
        ..cubicTo(c.dx - w / 4, c.dy - h * 1.4, c.dx + w / 5, c.dy - h * 1.2,
            c.dx + w / 2, c.dy)
        ..close();
      canvas.drawPath(mound, drift);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - w / 2, c.dy)
            ..cubicTo(c.dx - w / 4, c.dy - h * 1.4, c.dx + w / 5,
                c.dy - h * 1.2, c.dx + w / 2, c.dy),
          rim);
    }
    final flake = Paint()..color = ink.light;
    for (var i = 0; i < _count(area, 700); i++) {
      canvas.drawCircle(_at(area, rng), 0.8 + rng.nextDouble() * 0.8, flake);
    }
  }

  /// Shards of glass strewn about, catching the light.
  void _glass(Canvas canvas, Rect area, math.Random rng, _BackdropInk ink) {
    final fill = Paint()..color = ink.light;
    final edge = _stroke(ink.line, 0.9);
    for (var i = 0; i < _count(area, 1800); i++) {
      final c = _at(area, rng);
      final r = 5 + rng.nextDouble() * 9;
      final turn = rng.nextDouble() * math.pi * 2;
      final shard = Path()
        ..addPolygon([
          for (var k = 0; k < 3; k++)
            c +
                Offset.fromDirection(
                    turn + k * 2.1 + (rng.nextDouble() - 0.5) * 0.6,
                    r * (k == 0 ? 1 : 0.45 + rng.nextDouble() * 0.3)),
        ], true);
      canvas.drawPath(shard, fill);
      canvas.drawPath(shard, edge);
      if (rng.nextDouble() < 0.25) {
        canvas.drawLine(c.translate(-3, 0), c.translate(3, 0), edge);
        canvas.drawLine(c.translate(0, -3), c.translate(0, 3), edge);
      }
    }
  }

  @override
  bool shouldRepaint(BiomeBackdropPainter old) =>
      !identical(old.biome, biome) ||
      old.land != land ||
      old.seed != seed ||
      old.greyed != greyed;
}

/// The backdrop's inks: its line, a soft shade of the ground, a light one
/// (snow, salt, glass) and water.
class _BackdropInk {
  const _BackdropInk({
    required this.line,
    required this.soft,
    required this.light,
    required this.water,
  });

  final Color line;
  final Color soft;
  final Color light;
  final Color water;
}
