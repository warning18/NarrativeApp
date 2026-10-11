// The Eel's hulls from above (v1.228): what each ship form adds to the
// painter's plain hull -- castles, oars, iron plate and funnels, the rigs
// of every mast, and the gear that holds a flying boat up. See
// ship_forms.dart for the data and TopShipPainter for the rest of the ship.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ship_forms.dart';

const Color _timber = Color(0xFF3A2818);

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The raised stern and bow decks of [form], over its deck.
void paintCastles(Canvas canvas, ShipForm form, double x0, double cy,
    double len, double beam, Color hull, Color trim) {
  for (final (from, to) in form.castles) {
    final castle =
        form.outline(x0, cy, len, beam, scale: 0.7, from: from, to: to, n: 14);
    canvas.drawPath(castle, _fill(hull.withValues(alpha: 0.85)));
    canvas.drawPath(castle, _line(trim.withValues(alpha: 0.9), 1.2));
    for (var k = 1; k < 4; k++) {
      final x = x0 + len * (from + (to - from) * k / 4);
      canvas.drawLine(Offset(x, cy - beam * 0.3), Offset(x, cy + beam * 0.3),
          _line(Colors.black.withValues(alpha: 0.3), 1));
    }
  }
}

/// [form]'s oars, a side, dipping with [t].
void paintOars(Canvas canvas, ShipForm form, double x0, double cy, double len,
    double beam, double t) {
  for (var i = 0; i < form.oars; i++) {
    final u = 0.22 + 0.5 * (i + 0.5) / form.oars;
    final w = form.widthAt(u) * beam / 2;
    final stroke = 0.5 + 0.5 * math.sin(t * 4 + i * 0.6);
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
          Offset(x0 + len * u, cy + side * w),
          Offset(x0 + len * u - 6 - 3 * stroke,
              cy + side * (w + beam * (0.32 + 0.1 * stroke))),
          _line(const Color(0xFFC9B58A), 1.8));
    }
  }
}

/// Plate lines, two funnels with smoke and an iron prow: the dwarven
/// ironclad.
void paintIronWork(Canvas canvas, ShipForm form, double x0, double cy,
    double len, double beam, double t) {
  for (final u in [0.18, 0.32, 0.46, 0.6, 0.74]) {
    canvas.drawLine(
        Offset(x0 + len * u, cy - beam * 0.36),
        Offset(x0 + len * u, cy + beam * 0.36),
        _line(Colors.black.withValues(alpha: 0.4), 2));
  }
  for (final u in [0.34, 0.56]) {
    final c = Offset(x0 + len * u, cy);
    canvas.drawCircle(c, beam * 0.17, _fill(const Color(0xFF1E2126)));
    canvas.drawCircle(c, beam * 0.17, _line(const Color(0xFFC9A74E), 2));
    canvas.drawCircle(c, beam * 0.1, _fill(const Color(0xFF0E0F12)));
    for (var k = 0; k < 3; k++) {
      final life = (t * 0.7 + k / 3 + u) % 1;
      canvas.drawCircle(
          c + Offset(-life * beam * 0.5, -life * beam * 0.18),
          beam * (0.1 + 0.16 * life),
          _fill(const Color(0xFF8A9099).withValues(alpha: 0.32 * (1 - life))));
    }
  }
  final bow = x0 + len;
  canvas.drawPath(
      Path()
        ..moveTo(bow - len * 0.03, cy - beam * 0.08)
        ..lineTo(bow + len * 0.07, cy)
        ..lineTo(bow - len * 0.03, cy + beam * 0.08)
        ..close(),
      _fill(const Color(0xFF8A9099)));
}

/// One mast's sail seen from above at [x], in cloth [sail] edged [trim],
/// bellied by [billow] (0 to 1); [battered] tears it.
void paintMastSail(
    Canvas canvas,
    ShipMast mast,
    double x,
    double cy,
    double len,
    double beam,
    Color sail,
    Color trim,
    double billow,
    bool battered,
    Color mastColor) {
  final alpha = battered ? 0.7 : 0.92;
  final edge = _line(trim.withValues(alpha: 0.8), 1);
  final shadow = Paint()..color = Colors.black.withValues(alpha: 0.2);
  switch (mast.kind) {
    case SailKind.square:
      final span = beam * 1.28 * mast.size;
      final belly = beam * (0.32 + 0.06 * billow) * mast.size;
      final path = Path()
        ..moveTo(x, cy - span / 2)
        ..quadraticBezierTo(x + belly, cy, x, cy + span / 2)
        ..quadraticBezierTo(x + belly * 0.35, cy, x, cy - span / 2)
        ..close();
      canvas.drawPath(path.shift(const Offset(5, 7)), shadow);
      canvas.drawPath(path, _fill(sail.withValues(alpha: alpha)));
      canvas.drawPath(path, edge);
      if (battered) {
        canvas.drawLine(
            Offset(x + belly * 0.3, cy - span * 0.2),
            Offset(x + belly * 0.5, cy + span * 0.05),
            _line(Colors.black.withValues(alpha: 0.6), 2));
      }
      canvas.drawLine(Offset(x, cy - span / 2 - 2),
          Offset(x, cy + span / 2 + 2), _line(mastColor, 2.5));
    case SailKind.gaff:
      final length = len * 0.3 * mast.size;
      final sway = beam * (0.28 + 0.05 * billow);
      final path = Path()
        ..moveTo(x, cy - 1)
        ..quadraticBezierTo(
            x - length * 0.5, cy + sway, x - length, cy + beam * 0.1)
        ..quadraticBezierTo(x - length * 0.5, cy + beam * 0.08, x, cy + 1)
        ..close();
      canvas.drawPath(path.shift(const Offset(5, 7)), shadow);
      canvas.drawPath(path, _fill(sail.withValues(alpha: alpha)));
      canvas.drawPath(path, edge);
      canvas.drawLine(Offset(x, cy), Offset(x - length, cy + beam * 0.1),
          _line(mastColor, 2));
    case SailKind.lateen:
      final length = len * 0.28 * mast.size;
      final tipUp = Offset(x - length * 0.25, cy - beam * 0.62);
      final tipDown =
          Offset(x + length * (0.5 + 0.04 * billow), cy + beam * 0.14);
      final path = Path()
        ..moveTo(tipUp.dx, tipUp.dy)
        ..lineTo(tipDown.dx, tipDown.dy)
        ..lineTo(x - length * 0.1, cy + beam * 0.06)
        ..close();
      canvas.drawPath(path.shift(const Offset(5, 7)), shadow);
      canvas.drawPath(path, _fill(sail.withValues(alpha: alpha)));
      canvas.drawPath(path, edge);
      canvas.drawLine(tipUp, tipDown, _line(mastColor, 2.2));
  }
  canvas.drawCircle(Offset(x, cy), 3.5, _fill(const Color(0xFF2A1C10)));
}

/// The headsails on the bowsprit of [form] and the sprit itself.
void paintBowrig(Canvas canvas, ShipForm form, double x0, double cy, double len,
    double beam, Color sail, Color trim) {
  final bow = x0 + len;
  final reach = form.beak ? 0.18 : 0.1;
  canvas.drawLine(Offset(bow - len * 0.06, cy), Offset(bow + len * reach, cy),
      _line(_timber, 2.6));
  if (form.beak) {
    // The spritsail under the bowsprit.
    final sx = bow + len * 0.06;
    final path = Path()
      ..moveTo(sx, cy - beam * 0.3)
      ..quadraticBezierTo(sx + beam * 0.14, cy, sx, cy + beam * 0.3)
      ..quadraticBezierTo(sx + beam * 0.05, cy, sx, cy - beam * 0.3)
      ..close();
    canvas.drawPath(path, _fill(sail));
    canvas.drawPath(path, _line(trim, 1));
  }
  for (var j = 0; j < form.jibs; j++) {
    final tip = Offset(bow + len * (reach - j * 0.045), cy);
    final foot = len * 0.12 * (1 - j * 0.18);
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - foot, cy - beam * 0.12)
          ..lineTo(tip.dx - foot, cy + beam * 0.07)
          ..close(),
        _fill(sail.withValues(alpha: 0.92)));
    canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - foot, cy - beam * 0.12)
          ..lineTo(tip.dx - foot, cy + beam * 0.07)
          ..close(),
        _line(trim.withValues(alpha: 0.8), 1));
  }
}

/// The shadow a flying boat throws on the sea below, offset and soft.
void paintSkyShadow(Canvas canvas, Path hull) {
  canvas.drawPath(
      hull.shift(const Offset(16, 28)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
}

/// What holds a flying boat up and drives it, over her deck: gasbags and a
/// screw, bat wings and a furnace, lodestones, or bone wings. [cloth] is the
/// hull's sail colour, [trim] its trim.
void paintSkyRig(Canvas canvas, ShipForm form, double x0, double cy, double len,
    double beam, double t, Color cloth, Color trim) {
  switch (form.kind) {
    case HullKind.gasbag:
      for (final side in [-1.0, 1.0]) {
        final c = Offset(x0 + len * 0.5, cy + side * beam * 0.78);
        final bag =
            Rect.fromCenter(center: c, width: len * 0.52, height: beam * 0.46);
        // The outrigger struts down to the hull.
        for (final u in [-0.16, 0.0, 0.16]) {
          canvas.drawLine(
              Offset(c.dx + len * u, cy + side * beam * 0.4),
              Offset(c.dx + len * u, c.dy - side * beam * 0.1),
              _line(_timber, 1.6));
        }
        canvas.drawOval(bag.shift(const Offset(4, 6)),
            _fill(Colors.black.withValues(alpha: 0.2)));
        canvas.drawOval(bag, _fill(cloth));
        canvas.drawOval(bag, _line(trim.withValues(alpha: 0.85), 1.2));
        for (var k = -2; k <= 2; k++) {
          final x = c.dx + k * bag.width * 0.17;
          final half =
              beam * 0.23 * math.sqrt(math.max(0, 1 - math.pow(k / 2.9, 2)));
          canvas.drawLine(Offset(x, c.dy - half), Offset(x, c.dy + half),
              _line(trim.withValues(alpha: 0.4), 1));
        }
      }
      // The boiler's funnel, its smoke, and the pusher screw at the stern.
      final funnel = Offset(x0 + len * 0.3, cy);
      canvas.drawCircle(funnel, beam * 0.1, _fill(const Color(0xFF1E2126)));
      canvas.drawCircle(
          funnel, beam * 0.1, _line(const Color(0xFFC9A74E), 1.6));
      for (var k = 0; k < 3; k++) {
        final life = (t * 0.8 + k / 3) % 1;
        canvas.drawCircle(
            funnel + Offset(-life * beam * 0.6, -life * beam * 0.2),
            beam * (0.08 + 0.12 * life),
            _fill(const Color(0xFFB0B4BA).withValues(alpha: 0.4 * (1 - life))));
      }
      _screw(canvas, Offset(x0 - len * 0.015, cy), beam * 0.2, t);
    case HullKind.batwing:
      for (final side in [-1.0, 1.0]) {
        final shoulder = Offset(x0 + len * 0.46, cy + side * beam * 0.34);
        final tips = [
          Offset(x0 + len * 0.62, cy + side * beam * 0.8),
          Offset(x0 + len * 0.44, cy + side * beam * 0.86),
          Offset(x0 + len * 0.27, cy + side * beam * 0.78),
          Offset(x0 + len * 0.15, cy + side * beam * 0.62),
        ];
        final wing = Path()..moveTo(shoulder.dx, shoulder.dy);
        for (var i = 0; i < tips.length; i++) {
          final mid =
              Offset.lerp(i == 0 ? shoulder : tips[i - 1], tips[i], 0.5)!;
          wing.quadraticBezierTo(mid.dx - len * 0.02,
              mid.dy + side * beam * 0.08, tips[i].dx, tips[i].dy);
        }
        wing.lineTo(x0 + len * 0.18, cy + side * beam * 0.32);
        wing.close();
        canvas.drawPath(wing.shift(const Offset(4, 6)),
            _fill(Colors.black.withValues(alpha: 0.2)));
        canvas.drawPath(wing, _fill(cloth));
        canvas.drawPath(wing, _line(trim.withValues(alpha: 0.9), 1.2));
        for (final tip in tips) {
          canvas.drawLine(
              shoulder, tip, _line(_timber.withValues(alpha: 0.8), 1.8));
        }
      }
      // The soul furnace: a funnel that burns, a pulse of green fire.
      final furnace = Offset(x0 + len * 0.2, cy);
      final pulse = 0.55 + 0.25 * math.sin(t * 5);
      canvas.drawCircle(
          furnace,
          beam * 0.18,
          _fill(const Color(0xFF7BE0A2).withValues(alpha: pulse * 0.35))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(furnace, beam * 0.1, _fill(const Color(0xFF1E2126)));
      canvas.drawCircle(
          furnace, beam * 0.1, _line(const Color(0xFF7BE0A2), 1.6));
    case HullKind.lodestone:
      for (final (u, side) in [
        (0.14, -1.0),
        (0.14, 1.0),
        (0.84, -1.0),
        (0.84, 1.0)
      ]) {
        final c = Offset(x0 + len * u, cy + side * beam * 0.46);
        final glow = 0.5 + 0.3 * math.sin(t * 2.4 + u * 9 + side);
        canvas.drawCircle(
            c,
            beam * 0.17,
            _fill(const Color(0xFF80D8FF).withValues(alpha: glow * 0.4))
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(c, beam * 0.09, _fill(const Color(0xFF4A5560)));
        canvas.drawCircle(c, beam * 0.09, _line(const Color(0xFFB8E8FF), 1.4));
        canvas.drawCircle(c, beam * 0.035, _fill(const Color(0xFFE6F8FF)));
      }
    case HullKind.bone:
      for (final side in [-1.0, 1.0]) {
        final shoulder = Offset(x0 + len * 0.5, cy + side * beam * 0.4);
        final tips = [
          Offset(x0 + len * 0.7, cy + side * beam * 0.84),
          Offset(x0 + len * 0.5, cy + side * beam * 0.88),
          Offset(x0 + len * 0.3, cy + side * beam * 0.8),
          Offset(x0 + len * 0.16, cy + side * beam * 0.64),
        ];
        final wing = Path()..moveTo(shoulder.dx, shoulder.dy);
        for (final tip in tips) {
          wing.lineTo(tip.dx, tip.dy);
        }
        wing.lineTo(x0 + len * 0.22, cy + side * beam * 0.34);
        wing.close();
        canvas.drawPath(wing.shift(const Offset(4, 6)),
            _fill(Colors.black.withValues(alpha: 0.2)));
        canvas.drawPath(
            wing, _fill(const Color(0xFFD9CDB0).withValues(alpha: 0.88)));
        for (final tip in tips) {
          canvas.drawLine(shoulder, tip, _line(const Color(0xFF8E8468), 2.4));
          canvas.drawCircle(tip, 2.2, _fill(const Color(0xFFEFE6CE)));
        }
        canvas.drawPath(wing, _line(const Color(0xFF6E6246), 1.2));
      }
    case HullKind.hull:
    case HullKind.twin:
    case HullKind.iron:
      break;
  }
}

void _screw(Canvas canvas, Offset c, double r, double t) {
  final a = t * 22;
  for (var k = 0; k < 2; k++) {
    final d =
        Offset(math.cos(a + k * math.pi / 2), math.sin(a + k * math.pi / 2)) *
            r;
    canvas.drawLine(c - d, c + d,
        _line(const Color(0xFFC9B58A).withValues(alpha: 0.7), 2.2));
  }
  canvas.drawCircle(c, r * 0.9, _line(Colors.white.withValues(alpha: 0.18), 1));
  canvas.drawCircle(c, 2.4, _fill(const Color(0xFF2A1C10)));
}

/// The twin hulls of [form]: two slender hulls and the deck between them.
/// Returns the union silhouette and the platform (the deck).
(Path, Path) twinHull(
    ShipForm form, double x0, double cy, double len, double beam) {
  final slender = beam * 0.36;
  final top = form.outline(x0, cy - beam * 0.32, len, slender);
  final bottom = form.outline(x0, cy + beam * 0.32, len, slender);
  final platform = Path()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(x0 + len * 0.2, cy - beam * 0.36, x0 + len * 0.74,
            cy + beam * 0.36),
        const Radius.circular(4)));
  final union = Path.combine(PathOperation.union,
      Path.combine(PathOperation.union, top, bottom), platform);
  return (union, platform);
}
