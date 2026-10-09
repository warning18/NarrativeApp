// The inside of a building drawn (v1.207, see room_plan.dart): the floor
// in boards or flags, the walls with their doors, and what stands in the
// rooms, in the chart's greys with an ember at the hearth.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/map_charts.dart';
import '../data/room_plan.dart';

class RoomPlanPainter extends CustomPainter {
  RoomPlanPainter({
    required this.plan,
    required this.scale,
    required this.origin,
    required this.palette,
    required this.ember,
  });

  final RoomPlan plan;

  /// Map pixels per plan unit, and where the plan's origin falls.
  final double scale;
  final Offset origin;
  final ChartPalette palette;
  final Color ember;

  static const Color _dark = Color(0xFF17151B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final stone = Color.lerp(palette.coast, palette.place, 0.3)!;
    final wood = Color.lerp(palette.roofs, palette.place, 0.14)!;
    final floor = plan.kind.stone
        ? Color.lerp(palette.land, palette.coast, 0.25)!
        : Color.lerp(palette.roofs, palette.land, 0.3)!;

    // The street round the building: the land, darkened.
    canvas.drawRect(RoomPlan.bounds.inflate(2000),
        Paint()..color = palette.land.withValues(alpha: 0.72));
    canvas.drawRect(RoomPlan.bounds.inflate(2000),
        Paint()..color = _dark.withValues(alpha: 0.25));

    final shell = Path()..addPolygon(plan.outline, true);
    // The floor.
    canvas.drawPath(shell, Paint()..color = floor);
    canvas.save();
    canvas.clipPath(shell);
    _floor(canvas, stone, wood);
    for (final f in plan.furniture) {
      _furniture(canvas, f, stone, wood);
    }
    canvas.restore();
    // The walls, outer and inner, then the doors cut through them.
    final wall = Paint()
      ..color = palette.coast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(shell, wall);
    canvas.drawPath(
        shell,
        Paint()
          ..color = stone
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final inner = Paint()
      ..color = palette.coast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.butt;
    for (final (a, b) in plan.walls) {
      canvas.drawLine(a, b, inner);
    }
    for (final door in plan.doors) {
      _door(canvas, door, floor, stone);
    }
    canvas.restore();
  }

  void _floor(Canvas canvas, Color stone, Color wood) {
    final line = Paint()
      ..color = _dark.withValues(alpha: plan.kind.stone ? 0.22 : 0.3)
      ..strokeWidth = 1.2;
    if (plan.kind.rough) {
      // Earth: a stipple.
      final rng = math.Random(plan.seed);
      final dot = Paint()..color = stone.withValues(alpha: 0.35);
      for (var i = 0; i < 400; i++) {
        canvas.drawCircle(
            Offset(rng.nextDouble() * 1000, rng.nextDouble() * 1000),
            1.5 + rng.nextDouble() * 2,
            dot);
      }
      return;
    }
    if (plan.kind.stone) {
      // Flags, in offset rows.
      const s = 56.0;
      for (var y = 0.0; y < 1000; y += s) {
        canvas.drawLine(Offset(0, y), Offset(1000, y), line);
        final shift = ((y / s).round().isOdd) ? s / 2 : 0.0;
        for (var x = shift; x < 1000; x += s) {
          canvas.drawLine(Offset(x, y), Offset(x, y + s), line);
        }
      }
      return;
    }
    // Boards.
    for (var x = 0.0; x < 1000; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, 1000), line);
    }
    final rng = math.Random(plan.seed + 3);
    for (var i = 0; i < 60; i++) {
      final x = (rng.nextInt(38)) * 26.0;
      final y = rng.nextDouble() * 1000;
      canvas.drawLine(Offset(x, y), Offset(x + 26, y), line);
    }
  }

  void _door(Canvas canvas, RoomDoor door, Color floor, Color stone) {
    canvas.save();
    canvas.translate(door.at.dx, door.at.dy);
    canvas.rotate(door.angle);
    // The opening cut through the wall, the floor showing through.
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 20, height: door.width),
        Paint()..color = floor);
    // The leaf, swung open inward, and its arc.
    final leaf = Paint()
      ..color = stone
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final half = door.width / 2;
    canvas.drawLine(
        Offset(0, -half), Offset(-half * 0.75, -half - half * 0.65), leaf);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(0, -half), radius: door.width * 0.98),
        math.pi / 2 + 0.15,
        math.pi / 2 - 0.15,
        false,
        Paint()
          ..color = stone.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Jambs.
    final jamb = Paint()..color = _dark.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(0, -half), 5, jamb);
    canvas.drawCircle(Offset(0, half), 5, jamb);
    canvas.restore();
  }

  void _furniture(Canvas canvas, Furniture f, Color stone, Color wood) {
    canvas.save();
    canvas.translate(f.centre.dx, f.centre.dy);
    canvas.rotate(f.angle);
    final r = Rect.fromCenter(
        center: Offset.zero, width: f.size.width, height: f.size.height);
    final fill = Paint()..color = wood;
    final edge = Paint()
      ..color = _dark.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final shadow = Paint()..color = _dark.withValues(alpha: 0.3);
    switch (f.kind) {
      case FurnitureKind.table:
        final rad = f.size.width / 2;
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + math.pi / 4;
          canvas.drawCircle(Offset(math.cos(a), math.sin(a)) * (rad + 10), 7,
              Paint()..color = stone);
        }
        canvas.drawCircle(const Offset(2, 3), rad, shadow);
        canvas.drawCircle(Offset.zero, rad, fill);
        canvas.drawCircle(Offset.zero, rad, edge);
        canvas.drawCircle(Offset.zero, rad * 0.5,
            Paint()..color = _dark.withValues(alpha: 0.12));
      case FurnitureKind.longTable ||
            FurnitureKind.counter ||
            FurnitureKind.pew:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                r.shift(const Offset(2, 3)), const Radius.circular(4)),
            shadow);
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)), edge);
        if (f.kind == FurnitureKind.longTable) {
          final along = f.size.width > f.size.height;
          final n = ((along ? f.size.width : f.size.height) / 48).floor();
          for (var i = 0; i < n; i++) {
            final t = (i + 0.5) / n - 0.5;
            final off = (along ? f.size.width : f.size.height) * t;
            final side = (along ? f.size.height : f.size.width) / 2 + 10;
            final a = along ? Offset(off, -side) : Offset(-side, off);
            final b = along ? Offset(off, side) : Offset(side, off);
            canvas.drawCircle(a, 6, Paint()..color = stone);
            canvas.drawCircle(b, 6, Paint()..color = stone);
          }
        }
      case FurnitureKind.bar:
        canvas.drawRect(r.shift(const Offset(2, 3)), shadow);
        canvas.drawRect(r, Paint()..color = Color.lerp(wood, _dark, 0.25)!);
        canvas.drawRect(r, edge);
        final hatch = Paint()
          ..color = stone.withValues(alpha: 0.6)
          ..strokeWidth = 1.2;
        final along = f.size.height > f.size.width;
        for (var t = -0.5; t < 0.5; t += 0.08) {
          if (along) {
            canvas.drawLine(Offset(r.left + 4, r.top + (t + 0.5) * r.height),
                Offset(r.right - 4, r.top + (t + 0.5) * r.height + 6), hatch);
          } else {
            canvas.drawLine(Offset(r.left + (t + 0.5) * r.width, r.top + 4),
                Offset(r.left + (t + 0.5) * r.width + 6, r.bottom - 4), hatch);
          }
        }
        // Stools along it.
        final n = ((along ? r.height : r.width) / 40).floor();
        for (var i = 0; i < n; i++) {
          final t = (i + 0.5) / n;
          final p = along
              ? Offset(r.right + 16, r.top + t * r.height)
              : Offset(r.left + t * r.width, r.bottom + 16);
          canvas.drawCircle(p, 7, Paint()..color = stone);
        }
      case FurnitureKind.hearth:
        final along = f.size.height > f.size.width;
        canvas.drawRect(r, Paint()..color = stone);
        canvas.drawRect(r, edge);
        final mouth = along
            ? Rect.fromLTWH(r.left + 8, r.top + 16, r.width + 10, r.height - 32)
            : Rect.fromLTWH(
                r.left + 16, r.top + 8, r.width - 32, r.height + 10);
        canvas.drawRect(mouth, Paint()..color = _dark.withValues(alpha: 0.8));
        canvas.drawCircle(
            mouth.center,
            f.size.height * 0.9,
            Paint()
              ..shader = RadialGradient(colors: [
                ember.withValues(alpha: 0.45),
                ember.withValues(alpha: 0),
              ]).createShader(Rect.fromCircle(
                  center: mouth.center, radius: f.size.height * 0.9)));
        canvas.drawCircle(
            mouth.center, 7, Paint()..color = ember.withValues(alpha: 0.9));
      case FurnitureKind.bed:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                r.shift(const Offset(2, 3)), const Radius.circular(6)),
            shadow);
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)), edge);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, 22),
                const Radius.circular(5)),
            Paint()..color = Color.lerp(stone, Colors.white, 0.4)!);
      case FurnitureKind.cask:
        final rad = f.size.width / 2;
        canvas.drawCircle(const Offset(2, 2), rad, shadow);
        canvas.drawCircle(Offset.zero, rad, fill);
        canvas.drawCircle(Offset.zero, rad, edge);
        canvas.drawLine(Offset(-rad * 0.7, 0), Offset(rad * 0.7, 0), edge);
        canvas.drawLine(Offset(0, -rad * 0.7), Offset(0, rad * 0.7), edge);
      case FurnitureKind.crate:
        canvas.drawRect(r.shift(const Offset(2, 3)), shadow);
        canvas.drawRect(r, fill);
        canvas.drawRect(r, edge);
        canvas.drawLine(r.topLeft, r.bottomRight, edge);
        canvas.drawLine(r.topRight, r.bottomLeft, edge);
      case FurnitureKind.pillar:
        final rad = f.size.width / 2;
        canvas.drawCircle(const Offset(2, 3), rad, shadow);
        canvas.drawCircle(Offset.zero, rad, Paint()..color = stone);
        canvas.drawCircle(Offset.zero, rad, edge);
        canvas.drawCircle(Offset.zero, rad * 0.55, edge..strokeWidth = 1.2);
      case FurnitureKind.altar:
        canvas.drawRect(r.shift(const Offset(2, 3)), shadow);
        canvas.drawRect(r, Paint()..color = stone);
        canvas.drawRect(r, edge);
        final cross = Paint()
          ..color = _dark.withValues(alpha: 0.7)
          ..strokeWidth = 3;
        canvas.drawLine(const Offset(0, -16), const Offset(0, 16), cross);
        canvas.drawLine(const Offset(-10, -6), const Offset(10, -6), cross);
        canvas.drawCircle(const Offset(0, -34), 4, Paint()..color = ember);
        canvas.drawCircle(const Offset(-40, -34), 4, Paint()..color = ember);
        canvas.drawCircle(const Offset(40, -34), 4, Paint()..color = ember);
      case FurnitureKind.shelf:
        canvas.drawRect(r, fill);
        canvas.drawRect(r, edge);
        final along = f.size.height > f.size.width;
        final n = ((along ? r.height : r.width) / 24).floor();
        for (var i = 1; i < n; i++) {
          final t = i / n;
          if (along) {
            canvas.drawLine(Offset(r.left, r.top + t * r.height),
                Offset(r.right, r.top + t * r.height), edge);
          } else {
            canvas.drawLine(Offset(r.left + t * r.width, r.top),
                Offset(r.left + t * r.width, r.bottom), edge);
          }
        }
      case FurnitureKind.cage:
        canvas.drawRect(r, Paint()..color = _dark.withValues(alpha: 0.35));
        canvas.drawRect(r, edge..strokeWidth = 3);
        final bar = Paint()
          ..color = stone
          ..strokeWidth = 2;
        for (var t = 0.2; t < 1; t += 0.2) {
          canvas.drawLine(Offset(r.left + t * r.width, r.top),
              Offset(r.left + t * r.width, r.bottom), bar);
        }
      case FurnitureKind.stair:
        canvas.drawRect(r, Paint()..color = Color.lerp(wood, _dark, 0.15)!);
        canvas.drawRect(r, edge);
        final along = f.size.height > f.size.width;
        final n = ((along ? r.height : r.width) / 14).floor();
        for (var i = 1; i < n; i++) {
          final t = i / n;
          if (along) {
            canvas.drawLine(Offset(r.left, r.top + t * r.height),
                Offset(r.right, r.top + t * r.height), edge);
          } else {
            canvas.drawLine(Offset(r.left + t * r.width, r.top),
                Offset(r.left + t * r.width, r.bottom), edge);
          }
        }
      case FurnitureKind.strongbox:
        canvas.drawRect(r.shift(const Offset(2, 2)), shadow);
        canvas.drawRect(r, Paint()..color = Color.lerp(stone, _dark, 0.3)!);
        canvas.drawRect(r, edge);
        canvas.drawCircle(Offset.zero, 4, Paint()..color = palette.mark);
      case FurnitureKind.dais:
        canvas.drawRect(r, Paint()..color = stone.withValues(alpha: 0.35));
        canvas.drawRect(r, edge..strokeWidth = 1.5);
        // The seat.
        canvas.drawRect(
            Rect.fromCenter(
                center: const Offset(0, -10), width: 44, height: 40),
            fill);
        canvas.drawRect(
            Rect.fromCenter(
                center: const Offset(0, -10), width: 44, height: 40),
            edge);
        canvas.drawRect(
            Rect.fromCenter(
                center: const Offset(0, -34), width: 44, height: 10),
            Paint()..color = stone);
      case FurnitureKind.railing:
        final rail = Paint()
          ..color = stone
          ..strokeWidth = 3;
        canvas.drawLine(Offset(r.left, 0), Offset(r.right, 0), rail);
        for (var x = r.left; x <= r.right; x += 18) {
          canvas.drawLine(Offset(x, -8), Offset(x, 8), rail..strokeWidth = 2);
        }
      case FurnitureKind.rock:
        final path = Path();
        final n = 7;
        for (var i = 0; i < n; i++) {
          final a = i * 2 * math.pi / n;
          final rr = Offset(
              math.cos(a) * r.width / 2 * (0.8 + 0.2 * math.sin(a * 3)),
              math.sin(a) * r.height / 2 * (0.8 + 0.2 * math.cos(a * 2)));
          if (i == 0) {
            path.moveTo(rr.dx, rr.dy);
          } else {
            path.lineTo(rr.dx, rr.dy);
          }
        }
        path.close();
        canvas.drawPath(path.shift(const Offset(2, 3)), shadow);
        canvas.drawPath(path, Paint()..color = stone);
        canvas.drawPath(path, edge);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RoomPlanPainter old) =>
      old.plan != plan ||
      old.scale != scale ||
      old.origin != origin ||
      old.palette != palette ||
      old.ember != ember;
}
