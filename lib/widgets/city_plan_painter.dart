// The city plan drawn (v1.203, see city_plan.dart): water, fields and
// roads, the streets and the houses along them, the square, the wall with
// its towers and gates, and the landmarks the story's districts are --
// church, keep, hall, undercroft, quays and wharves, a yard, a bridge, a
// slum, the tear -- all in the chart's colours, scaled to the map.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/city_plan.dart';
import '../data/map_charts.dart';

class CityPlanPainter extends CustomPainter {
  CityPlanPainter({
    required this.plan,
    required this.scale,
    required this.origin,
    required this.palette,
    required this.ember,
  });

  final CityPlan plan;

  /// Canvas = [origin] + plan point * [scale].
  final double scale;
  final Offset origin;
  final ChartPalette palette;
  final Color ember;

  static const _dark = Color(0xFF17151B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final rng = math.Random(plan.seed);
    final stone = Color.lerp(palette.coast, palette.place, 0.3)!;
    final roof = Color.lerp(palette.roofs, palette.place, 0.14)!;
    final roofDark = Color.lerp(palette.roofs, _dark, 0.35)!;

    // The ground: the land's pattern under it quietened, the ground
    // inside the wall trodden paler.
    canvas.drawRect(CityPlan.bounds.inflate(2000),
        Paint()..color = palette.land.withValues(alpha: 0.72));
    canvas.drawCircle(plan.centre, plan.radius * 0.95,
        Paint()..color = palette.coast.withValues(alpha: 0.1));

    _water(canvas);
    _fields(canvas, stone);
    _streets(canvas, stone);
    _square(canvas, stone);
    for (final b in plan.buildings) {
      switch (b.kind) {
        case CityBuildingKind.house:
          _house(canvas, b, roof, roofDark, stone, rng);
        case CityBuildingKind.shack:
          _house(canvas, b, roofDark, _dark.withValues(alpha: 0.5), stone, rng,
              ridge: false);
        case CityBuildingKind.hall:
          _house(canvas, b, Color.lerp(roof, palette.place, 0.1)!, roofDark,
              stone, rng);
        case CityBuildingKind.warehouse:
          _house(
              canvas, b, Color.lerp(roof, _dark, 0.2)!, roofDark, stone, rng);
        case CityBuildingKind.stall:
          canvas.save();
          canvas.translate(b.centre.dx, b.centre.dy);
          canvas.rotate(b.angle);
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: b.size.width,
                  height: b.size.height),
              Paint()..color = palette.mark.withValues(alpha: 0.55));
          canvas.restore();
        case CityBuildingKind.field:
          break;
      }
    }
    for (final l in plan.landmarks) {
      _landmark(canvas, l, stone, roof, roofDark);
    }
    _wall(canvas, stone);
    for (final t in plan.trees) {
      _tree(canvas, t, 5 + (t.dx * 7 + t.dy) % 4);
    }
    canvas.restore();
  }

  void _water(Canvas canvas) {
    if (plan.shoreline.isNotEmpty) {
      final sea = Path()..moveTo(-60, -60);
      for (final p in plan.shoreline) {
        sea.lineTo(p.dx, p.dy);
      }
      sea
        ..lineTo(-60, 1060)
        ..close();
      canvas.drawPath(sea, Paint()..color = palette.sea);
      canvas.save();
      canvas.clipPath(sea);
      canvas.drawPath(
          sea,
          Paint()
            ..color = Color.lerp(palette.sea, palette.seaLine, 0.9)!
                .withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 40);
      final surf = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      for (var i = 0; i + 1 < plan.shoreline.length; i += 2) {
        final p = plan.shoreline[i] + const Offset(-28, 0);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx - 14, p.dy)
              ..quadraticBezierTo(p.dx - 7, p.dy - 5, p.dx, p.dy)
              ..quadraticBezierTo(p.dx + 7, p.dy + 5, p.dx + 14, p.dy),
            surf);
      }
      canvas.restore();
      canvas.drawPath(
          sea,
          Paint()
            ..color = palette.coast
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    if (plan.river.isNotEmpty) {
      final path = Path()..moveTo(plan.river.first.dx, plan.river.first.dy);
      for (final p in plan.river.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = palette.coast.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = plan.riverWidth + 6);
      canvas.drawPath(
          path,
          Paint()
            ..color = palette.river
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = plan.riverWidth);
      final ripple = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i + 1 < plan.river.length; i += 2) {
        final a = plan.river[i], b = plan.river[i + 1];
        final d = (b - a) / (b - a).distance;
        final side =
            Offset(-d.dy, d.dx) * ((i % 3) - 1) * plan.riverWidth * 0.25;
        canvas.drawLine(a + side - d * 5, a + side + d * 5, ripple);
      }
    }
    // Quays and boats.
    final timber = Paint()
      ..color = Color.lerp(palette.coast, palette.place, 0.35)!
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;
    for (final (a, b) in plan.quays) {
      canvas.drawLine(a, b, timber);
      final d = b - a;
      final n = d / d.distance;
      for (var t = 8.0; t < d.distance; t += 14) {
        final p = a + n * t;
        canvas.drawCircle(
            p, 1.6, Paint()..color = _dark.withValues(alpha: 0.7));
      }
    }
    for (final (at, angle) in plan.boats) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      canvas.drawPath(
          Path()
            ..moveTo(-12, 0)
            ..quadraticBezierTo(0, 7, 12, 0)
            ..lineTo(9, -3)
            ..lineTo(-9, -3)
            ..close(),
          Paint()..color = Color.lerp(palette.roofs, palette.place, 0.3)!);
      canvas.drawLine(
          const Offset(0, -3), const Offset(0, -14), timber..strokeWidth = 1.6);
      canvas.restore();
    }
  }

  void _fields(Canvas canvas, Color stone) {
    for (final b in plan.buildings) {
      if (b.kind != CityBuildingKind.field) continue;
      canvas.save();
      canvas.translate(b.centre.dx, b.centre.dy);
      canvas.rotate(b.angle);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: b.size.width, height: b.size.height);
      canvas.drawRect(
          rect, Paint()..color = palette.coast.withValues(alpha: 0.1));
      final furrow = Paint()
        ..color = stone.withValues(alpha: 0.45)
        ..strokeWidth = 1;
      for (var y = rect.top + 4; y < rect.bottom; y += 5) {
        canvas.drawLine(
            Offset(rect.left + 2, y), Offset(rect.right - 2, y), furrow);
      }
      canvas.drawRect(
          rect,
          Paint()
            ..color = stone.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      canvas.restore();
    }
  }

  void _streets(Canvas canvas, Color stone) {
    final casing = Paint()
      ..color = _dark.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bed = Paint()
      ..color = palette.coast.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path pathOf(CityStreet s) {
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        final p = s.points[i];
        if (i + 1 < s.points.length) {
          final q = s.points[i + 1];
          final mid = (p + q) / 2;
          path.quadraticBezierTo(p.dx, p.dy, mid.dx, mid.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      return path;
    }

    for (final s in plan.streets) {
      canvas.drawPath(pathOf(s), casing..strokeWidth = s.width + 3);
    }
    for (final s in plan.streets) {
      canvas.drawPath(
          pathOf(s),
          bed
            ..strokeWidth = s.width
            ..color = palette.coast.withValues(alpha: s.main ? 0.7 : 0.5));
    }
    // Bridges over the river: a deck with parapets and arches under.
    for (final (at, angle) in plan.bridges) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final w = plan.riverWidth + 14;
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: w, height: 12),
          Paint()..color = stone);
      final parapet = Paint()
        ..color = _dark.withValues(alpha: 0.7)
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(-w / 2, -6), Offset(w / 2, -6), parapet);
      canvas.drawLine(Offset(-w / 2, 6), Offset(w / 2, 6), parapet);
      for (final x in [-w / 4, 0.0, w / 4]) {
        canvas.drawPath(
            Path()
              ..moveTo(x - 5, 6)
              ..quadraticBezierTo(x, 14, x + 5, 6),
            parapet..strokeWidth = 1.2);
      }
      canvas.restore();
    }
  }

  void _square(Canvas canvas, Color stone) {
    final c = plan.centre, r = plan.squareRadius;
    canvas.drawCircle(
        c, r, Paint()..color = palette.coast.withValues(alpha: 0.3));
    final rng = math.Random(plan.seed + 3);
    final cobble = Paint()..color = stone.withValues(alpha: 0.5);
    for (var i = 0; i < 70; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final rr = r * 0.25 + rng.nextDouble() * r * 0.7;
      canvas.drawCircle(
          c + Offset(math.cos(a) * rr, math.sin(a) * rr), 1.4, cobble);
    }
    // The market cross, or the well.
    canvas.drawCircle(c, 5, Paint()..color = palette.river);
    canvas.drawCircle(
        c,
        5,
        Paint()
          ..color = stone
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _house(Canvas canvas, CityBuilding b, Color fill, Color shade,
      Color stone, math.Random rng,
      {bool ridge = true}) {
    canvas.save();
    canvas.translate(b.centre.dx, b.centre.dy);
    canvas.rotate(b.angle);
    final rect = Rect.fromCenter(
        center: Offset.zero, width: b.size.width, height: b.size.height);
    canvas.drawRect(rect.shift(const Offset(1.5, 1.5)),
        Paint()..color = _dark.withValues(alpha: 0.35));
    canvas.drawRect(rect, Paint()..color = fill);
    if (ridge) {
      canvas.drawRect(Rect.fromLTRB(rect.left, 0, rect.right, rect.bottom),
          Paint()..color = shade.withValues(alpha: 0.5));
      canvas.drawLine(
          Offset(rect.left, 0),
          Offset(rect.right, 0),
          Paint()
            ..color = palette.place.withValues(alpha: 0.4)
            ..strokeWidth = 0.8);
      if (rng.nextDouble() < 0.35) {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(rect.right - 3, rect.top + 2.5),
                width: 2.4,
                height: 2.4),
            Paint()..color = stone);
      }
    }
    canvas.drawRect(
        rect,
        Paint()
          ..color = stone
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
    canvas.restore();
  }

  void _tree(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c.translate(1.2, 1.2), r,
        Paint()..color = _dark.withValues(alpha: 0.35));
    canvas.drawCircle(
        c, r, Paint()..color = Color.lerp(palette.roofs, palette.river, 0.35)!);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Color.lerp(palette.coast, palette.place, 0.25)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  void _wall(Canvas canvas, Color stone) {
    if (!plan.walled) return;
    final wall = Paint()
      ..color = palette.coast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.butt;
    final crest = Paint()
      ..color = stone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    for (final run in plan.wallRuns) {
      final path = Path()..moveTo(run.first.dx, run.first.dy);
      for (final p in run.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = _dark.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(path, wall);
      canvas.drawPath(path, crest);
    }
    for (final t in plan.towers) {
      canvas.drawRect(Rect.fromCenter(center: t, width: 14, height: 14),
          Paint()..color = _dark.withValues(alpha: 0.6));
      canvas.drawRect(Rect.fromCenter(center: t, width: 12, height: 12),
          Paint()..color = stone);
      canvas.drawRect(
          Rect.fromCenter(center: t, width: 12, height: 12),
          Paint()
            ..color = _dark.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  void _landmark(
      Canvas canvas, CityLandmark l, Color stone, Color roof, Color roofDark) {
    canvas.save();
    canvas.translate(l.at.dx, l.at.dy);
    // Facing the centre: the front is at -x after this turn.
    canvas.rotate(l.angle);
    final outline = Paint()
      ..color = stone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()..color = roof;
    final shade = Paint()..color = roofDark.withValues(alpha: 0.5);
    void block(Rect r) {
      canvas.drawRect(r.shift(const Offset(2, 2)),
          Paint()..color = _dark.withValues(alpha: 0.35));
      canvas.drawRect(r, fill);
      canvas.drawRect(
          Rect.fromLTRB(r.left, r.center.dy, r.right, r.bottom), shade);
      canvas.drawRect(r, outline);
    }

    switch (l.kind) {
      case CityLandmarkKind.gate:
        // Two towers either side of the road, a lintel between.
        for (final y in const [-14.0, 14.0]) {
          canvas.drawRect(
              Rect.fromCenter(center: Offset(0, y), width: 16, height: 14),
              Paint()..color = stone);
          canvas.drawRect(
              Rect.fromCenter(center: Offset(0, y), width: 16, height: 14),
              Paint()
                ..color = _dark.withValues(alpha: 0.7)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
        canvas.drawLine(
            const Offset(0, -7),
            const Offset(0, 7),
            Paint()
              ..color = _dark.withValues(alpha: 0.7)
              ..strokeWidth = 3);
      case CityLandmarkKind.market:
        break;
      case CityLandmarkKind.church:
        final small = l.extent < 40;
        final nave = small ? 26.0 : 60.0, width = small ? 14.0 : 26.0;
        // Nave along the facing axis, transept, apse at the back, tower
        // at the front with its cross; graves beside.
        block(Rect.fromLTWH(-nave / 2, -width / 2, nave, width));
        if (!small) {
          block(Rect.fromLTWH(nave * 0.15, -width, 16, width * 2));
        }
        canvas.drawArc(
            Rect.fromCircle(center: Offset(nave / 2, 0), radius: width / 2),
            -math.pi / 2,
            math.pi,
            true,
            fill);
        canvas.drawArc(
            Rect.fromCircle(center: Offset(nave / 2, 0), radius: width / 2),
            -math.pi / 2,
            math.pi,
            false,
            outline);
        canvas.drawLine(
            Offset(-nave / 2, 0),
            Offset(nave / 2, 0),
            Paint()
              ..color = palette.place.withValues(alpha: 0.5)
              ..strokeWidth = 1);
        final tower = small ? 9.0 : 15.0;
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(-nave / 2 + tower / 2, 0),
                width: tower,
                height: tower),
            Paint()..color = stone);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(-nave / 2 + tower / 2, 0),
                width: tower,
                height: tower),
            Paint()
              ..color = _dark.withValues(alpha: 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        final cross = Paint()
          ..color = palette.place
          ..strokeWidth = 1.4;
        final cx = -nave / 2 + tower / 2;
        canvas.drawLine(Offset(cx, -4), Offset(cx, 4), cross);
        canvas.drawLine(Offset(cx - 3, -1), Offset(cx + 3, -1), cross);
        if (!small) {
          final grave = Paint()
            ..color = stone.withValues(alpha: 0.8)
            ..strokeWidth = 1;
          for (var i = 0; i < 6; i++) {
            final g = Offset(
                -nave / 2 + 8 + (i % 3) * 9, width / 2 + 10 + (i ~/ 3) * 9);
            canvas.drawLine(
                g + const Offset(0, -4), g + const Offset(0, 3), grave);
            canvas.drawLine(
                g + const Offset(-2.5, -2), g + const Offset(2.5, -2), grave);
          }
        }
      case CityLandmarkKind.keep:
        // A bailey wall, open to the front, the keep square in it with
        // its four towers and a banner.
        final bailey = Paint()
          ..color = palette.coast
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: 46),
            math.pi + 0.5, 2 * math.pi - 1.0, false, bailey);
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 46),
            math.pi + 0.5,
            2 * math.pi - 1.0,
            false,
            Paint()
              ..color = stone
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
        for (final a in const [math.pi + 0.5, math.pi - 0.5, 0.9, -0.9]) {
          final t = Offset(math.cos(a), math.sin(a)) * 46;
          canvas.drawRect(Rect.fromCenter(center: t, width: 12, height: 12),
              Paint()..color = stone);
        }
        block(const Rect.fromLTWH(-16, -16, 32, 32));
        for (final c in const [
          Offset(-16, -16),
          Offset(16, -16),
          Offset(-16, 16),
          Offset(16, 16)
        ]) {
          canvas.drawCircle(c, 5.5, Paint()..color = stone);
          canvas.drawCircle(
              c,
              5.5,
              Paint()
                ..color = _dark.withValues(alpha: 0.7)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
        canvas.drawLine(
            Offset.zero,
            const Offset(0, -26),
            Paint()
              ..color = palette.place
              ..strokeWidth = 1.2);
        canvas.drawPath(
            Path()
              ..moveTo(0, -26)
              ..lineTo(10, -22)
              ..lineTo(0, -18)
              ..close(),
            Paint()..color = palette.mark);
      case CityLandmarkKind.hall:
        block(const Rect.fromLTWH(-26, -16, 52, 32));
        canvas.drawRect(
            const Rect.fromLTWH(-26, -16, 12, 12), Paint()..color = stone);
        canvas.drawRect(const Rect.fromLTWH(-26, -16, 12, 12), outline);
        // Steps down to the front.
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
              Offset(-30 - i * 2.0, -6.0 + i),
              Offset(-30 - i * 2.0, 6.0 - i),
              Paint()
                ..color = stone
                ..strokeWidth = 1);
        }
      case CityLandmarkKind.cellar:
        block(const Rect.fromLTWH(-18, -12, 36, 24));
        canvas.drawRect(const Rect.fromLTWH(-18, -12, 36, 24),
            Paint()..color = _dark.withValues(alpha: 0.3));
        for (final y in const [-7.0, 0.0, 7.0]) {
          canvas.drawArc(
              Rect.fromCircle(center: Offset(-18, y), radius: 3),
              math.pi / 2,
              math.pi,
              false,
              Paint()
                ..color = palette.place.withValues(alpha: 0.8)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
      case CityLandmarkKind.quay || CityLandmarkKind.wharf:
        // The quay and boats are in the plan's water; a crane on the quay.
        canvas.drawLine(
            const Offset(-8, -16),
            const Offset(-8, -30),
            Paint()
              ..color = stone
              ..strokeWidth = 2);
        canvas.drawLine(
            const Offset(-8, -30),
            const Offset(6, -26),
            Paint()
              ..color = stone
              ..strokeWidth = 2);
        canvas.drawLine(
            const Offset(6, -26),
            const Offset(6, -20),
            Paint()
              ..color = stone
              ..strokeWidth = 1);
      case CityLandmarkKind.yard:
        // A slipway to the water and a hull ribbed on it.
        canvas.drawRect(const Rect.fromLTWH(-30, -22, 60, 44),
            Paint()..color = palette.coast.withValues(alpha: 0.18));
        canvas.drawRect(const Rect.fromLTWH(-30, -22, 60, 44), outline);
        final rib = Paint()
          ..color = stone
          ..strokeWidth = 1.4;
        canvas.drawLine(
            const Offset(-22, 0), const Offset(22, 0), rib..strokeWidth = 2.2);
        for (var x = -18.0; x <= 18; x += 6) {
          final h = 10 - (x.abs() / 18) * 6;
          canvas.drawLine(Offset(x, -h), Offset(x, h), rib..strokeWidth = 1.2);
        }
        canvas.drawLine(
            const Offset(-6, 24), const Offset(-6, 50), rib..strokeWidth = 1.5);
        canvas.drawLine(const Offset(6, 24), const Offset(6, 50), rib);
      case CityLandmarkKind.bridge:
        break;
      case CityLandmarkKind.slum:
        // Fires among the shacks.
        for (final o in const [
          Offset(-20, 10),
          Offset(24, -16),
          Offset(2, 30)
        ]) {
          canvas.drawCircle(
              o, 3, Paint()..color = ember.withValues(alpha: 0.8));
          canvas.drawCircle(
              o, 8, Paint()..color = ember.withValues(alpha: 0.15));
        }
      case CityLandmarkKind.fields:
        // The farmhouse among them.
        block(const Rect.fromLTWH(-10, -7, 20, 14));
      case CityLandmarkKind.tear:
        canvas.drawCircle(
            Offset.zero, 34, Paint()..color = _dark.withValues(alpha: 0.6));
        final star = Path();
        for (var i = 0; i < 14; i++) {
          final a = i * math.pi / 7;
          final r = i.isEven ? 22.0 : 7.0;
          final p = Offset(math.cos(a) * r, math.sin(a) * r);
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas.drawPath(
            star, Paint()..color = palette.voidColor.withValues(alpha: 0.85));
        canvas.drawPath(
            star,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      case CityLandmarkKind.plaza:
        canvas.drawCircle(Offset.zero, 18,
            Paint()..color = palette.coast.withValues(alpha: 0.3));
        canvas.drawCircle(const Offset(6, -6), 5,
            Paint()..color = Color.lerp(palette.roofs, palette.river, 0.35)!);
      case CityLandmarkKind.mill:
        block(const Rect.fromLTWH(-9, -9, 18, 18));
        if (plan.water.isEmpty) {
          // A windmill: four sails.
          final sail = Paint()
            ..color = palette.place.withValues(alpha: 0.85)
            ..strokeWidth = 1.6;
          for (var i = 0; i < 4; i++) {
            final a = i * math.pi / 2 + 0.4;
            canvas.drawLine(
                Offset.zero, Offset(math.cos(a), math.sin(a)) * 18, sail);
          }
        } else {
          // A wheel in the water, at the front.
          canvas.drawCircle(
              const Offset(-14, 0),
              8,
              Paint()
                ..color = stone
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6);
          for (var i = 0; i < 4; i++) {
            final a = i * math.pi / 4;
            canvas.drawLine(
                Offset(-14.0 + math.cos(a) * 8, math.sin(a) * 8),
                Offset(-14.0 - math.cos(a) * 8, -math.sin(a) * 8),
                Paint()
                  ..color = stone
                  ..strokeWidth = 1);
          }
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CityPlanPainter old) =>
      old.plan != plan ||
      old.scale != scale ||
      old.origin != origin ||
      old.palette != palette;
}
