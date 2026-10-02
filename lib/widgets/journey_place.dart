// The Journey map on the real map (v1.181): up close, the place the party
// stands in -- a town's wall, streets out to each way and burned blocks
// between; a camp's tents round its fire; a site's broken stones; the sea
// -- and on the road, the world chart itself, the party walking from one
// landmark to the next in its true direction.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/map_charts.dart';

/// What a place is drawn as, up close.
enum PlaceKind { town, camp, site, sea, wild }

/// The kind for a settlement's `kind` ('camp', 'town', 'village',
/// 'site'), or a landmark at sea. A landmark with no settlement of its
/// own is mostly a street or quarter of a town (the square, the alley,
/// the docks), so it is drawn as one.
PlaceKind placeKindOf(String? settlementKind, {bool atSea = false}) {
  if (atSea) return PlaceKind.sea;
  return switch (settlementKind) {
    'camp' => PlaceKind.camp,
    'site' => PlaceKind.site,
    _ => PlaceKind.town,
  };
}

/// A street from [from] to [to]: out of the square in the way's direction,
/// with a little bend so the town's streets don't run ruler-straight.
Path placeStreet(Offset from, Offset to) {
  final d = to - from;
  final bend = Offset(-d.dy, d.dx) * 0.12;
  final mid = from + d * 0.5 + bend;
  return Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
}

/// The ground of a place: what it is built of, its streets out to each of
/// [spots] from the square at [here], drawn from [seed] so a place looks
/// the same each visit.
class PlacePlanPainter extends CustomPainter {
  PlacePlanPainter({
    required this.kind,
    required this.seed,
    required this.here,
    required this.spots,
    required this.palette,
    required this.ember,
    this.glyphs = const {},
    this.water = '',
  });

  final PlaceKind kind;
  final int seed;
  final Offset here;
  final List<Offset> spots;
  final ChartPalette palette;
  final Color ember;

  /// For each of [spots] (by index) leading into a district with a glyph
  /// (v1.199, see geoGlyphs): the glyph drawn above its mark.
  final Map<int, String> glyphs;

  /// The place's water (v1.199): a 'river' through it, a 'shore' beside
  /// it, or ''.
  final String water;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    if (kind == PlaceKind.sea) {
      canvas.drawRect(Offset.zero & size, Paint()..color = palette.sea);
      final wave = Paint()
        ..color = palette.seaLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (var i = 0; i < 40; i++) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height;
        canvas.drawPath(
            Path()
              ..moveTo(x, y)
              ..quadraticBezierTo(x + 7, y - 5, x + 14, y)
              ..quadraticBezierTo(x + 21, y + 5, x + 28, y),
            wave);
      }
      return;
    }

    // The place's water: a river in from the top and out at the foot,
    // bending past the square; or the sea along the left side.
    if (water == 'river') {
      final x = here.dx - 70 + (rng.nextDouble() - 0.5) * 20;
      final river = Path()
        ..moveTo(x, -10)
        ..cubicTo(x + 30, size.height * 0.3, x - 30, size.height * 0.6, x + 10,
            size.height + 10);
      canvas.drawPath(
          river,
          Paint()
            ..color = palette.fog.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 26
            ..strokeCap = StrokeCap.round);
      canvas.drawPath(
          river,
          Paint()
            ..color = palette.river
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18
            ..strokeCap = StrokeCap.round);
    } else if (water == 'shore') {
      final edge = Path()
        ..moveTo(0, -10)
        ..lineTo(size.width * 0.18, -10)
        ..cubicTo(size.width * 0.24, size.height * 0.3, size.width * 0.12,
            size.height * 0.6, size.width * 0.2, size.height + 10)
        ..lineTo(0, size.height + 10)
        ..close();
      canvas.drawPath(edge, Paint()..color = palette.sea);
      canvas.drawPath(
          edge,
          Paint()
            ..color = palette.coast
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // The streets (or paths) out of the square.
    final streets = [for (final spot in spots) placeStreet(here, spot)];
    final streetWidth = switch (kind) {
      PlaceKind.town => 16.0,
      PlaceKind.camp => 9.0,
      _ => 7.0,
    };
    for (final street in streets) {
      canvas.drawPath(
          street,
          Paint()
            ..color = palette.coast.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = streetWidth);
    }
    // Points along the streets and at the marks: nothing is built there.
    final kept = <Offset>[
      here,
      ...spots,
      for (final street in streets)
        for (final metric in street.computeMetrics())
          for (var d = 0.0; d < metric.length; d += 12)
            metric.getTangentForOffset(d)!.position,
    ];
    bool clear(Offset p, double r) =>
        kept.every((k) => (k - p).distance > r + streetWidth / 2 + 6);

    final reach = spots.isEmpty
        ? size.shortestSide * 0.4
        : spots.map((s) => (s - here).distance).reduce(math.max) + 26;

    switch (kind) {
      case PlaceKind.town:
        // What is left of the wall, round the town.
        final wall = Rect.fromCenter(
            center: here,
            width: math.min(size.width - 8, reach * 2.1),
            height: math.min(size.height - 8, reach * 2.3));
        final wallPaint = Paint()
          ..color = palette.coast.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (final metric in (Path()..addOval(wall)).computeMetrics()) {
          var d = 0.0;
          while (d < metric.length) {
            final run = 26 + rng.nextDouble() * 34;
            canvas.drawPath(
                metric.extractPath(d, math.min(d + run, metric.length)),
                wallPaint);
            d += run + 8 + rng.nextDouble() * 16;
          }
        }
        // Blocks between the streets, each clear of the others.
        final built = <Rect>[];
        for (var i = 0; i < 70; i++) {
          final w = 18 + rng.nextDouble() * 22;
          final h = 14 + rng.nextDouble() * 16;
          final c = Offset(
              rng.nextDouble() * size.width, rng.nextDouble() * size.height);
          if (!clear(c, math.max(w, h) / 2)) continue;
          final rect = Rect.fromCenter(center: c, width: w, height: h);
          if (built.any((b) => b.inflate(5).overlaps(rect))) continue;
          built.add(rect);
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate((rng.nextDouble() - 0.5) * 0.3);
          final local =
              Rect.fromCenter(center: Offset.zero, width: w, height: h);
          canvas.drawRect(
              local, Paint()..color = palette.roofs.withValues(alpha: 0.9));
          canvas.drawRect(
              local,
              Paint()
                ..color = palette.coast.withValues(alpha: 0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
          canvas.restore();
        }
        // The square.
        canvas.drawCircle(
            here, 40, Paint()..color = palette.coast.withValues(alpha: 0.22));
      case PlaceKind.camp:
        // Tents round the fire, a glow at its heart.
        canvas.drawCircle(
            here, 46, Paint()..color = ember.withValues(alpha: 0.10));
        for (var i = 0; i < 26; i++) {
          final c = Offset(
              rng.nextDouble() * size.width, rng.nextDouble() * size.height);
          if (!clear(c, 14)) continue;
          final s = 10 + rng.nextDouble() * 7;
          canvas.drawPath(
              Path()
                ..moveTo(c.dx - s, c.dy + s * 0.7)
                ..lineTo(c.dx, c.dy - s * 0.8)
                ..lineTo(c.dx + s, c.dy + s * 0.7)
                ..close(),
              Paint()..color = palette.roofs);
          canvas.drawLine(
              Offset(c.dx, c.dy - s * 0.8),
              Offset(c.dx, c.dy + s * 0.7),
              Paint()
                ..color = palette.coast
                ..strokeWidth = 1);
        }
      case PlaceKind.site:
        // Broken stones and rubble.
        for (var i = 0; i < 40; i++) {
          final c = Offset(
              rng.nextDouble() * size.width, rng.nextDouble() * size.height);
          if (!clear(c, 8)) continue;
          final tall = rng.nextBool();
          canvas.drawRect(
              Rect.fromCenter(
                  center: c,
                  width: tall ? 6 : 12,
                  height: tall ? 14 + rng.nextDouble() * 10 : 6),
              Paint()..color = palette.roofs);
        }
      case PlaceKind.wild:
        // Trees in clumps: a crown over a short trunk.
        for (var i = 0; i < 70; i++) {
          final c = Offset(
              rng.nextDouble() * size.width, rng.nextDouble() * size.height);
          if (!clear(c, 7)) continue;
          final r = 4 + rng.nextDouble() * 3;
          canvas.drawLine(
              c,
              c.translate(0, r + 3),
              Paint()
                ..color = palette.coast
                ..strokeWidth = 1.5);
          canvas.drawCircle(c, r, Paint()..color = palette.roofs);
          canvas.drawCircle(
              c,
              r,
              Paint()
                ..color = palette.coast.withValues(alpha: 0.6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
      case PlaceKind.sea:
        break;
    }

    // The districts' glyphs, above the marks of the ways into them.
    for (final entry in glyphs.entries) {
      if (entry.key < 0 || entry.key >= spots.length) continue;
      _glyph(canvas, entry.value, spots[entry.key].translate(0, -34));
    }
  }

  /// A district's glyph (v1.199): what it is, before its name is read.
  void _glyph(Canvas canvas, String glyph, Offset p) {
    final line = Paint()
      ..color = palette.place
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = palette.land;
    final x = p.dx, y = p.dy;
    switch (glyph) {
      case 'bridge':
        canvas.drawLine(
            Offset(x - 14, y), Offset(x + 14, y), line..strokeWidth = 3);
        canvas.drawPath(
            Path()
              ..moveTo(x - 12, y + 3)
              ..quadraticBezierTo(x - 6, y - 3, x, y + 3)
              ..quadraticBezierTo(x + 6, y - 3, x + 12, y + 3),
            line..strokeWidth = 1.2);
      case 'keep':
        canvas.drawRect(
            Rect.fromCenter(center: p, width: 18, height: 18), fill);
        canvas.drawRect(
            Rect.fromCenter(center: p, width: 18, height: 18), line);
        final top = y - 9;
        canvas.drawPath(
            Path()
              ..moveTo(x - 9, top)
              ..lineTo(x - 9, top - 4)
              ..lineTo(x - 5, top - 4)
              ..lineTo(x - 5, top)
              ..lineTo(x - 1, top)
              ..lineTo(x - 1, top - 4)
              ..lineTo(x + 3, top - 4)
              ..lineTo(x + 3, top)
              ..lineTo(x + 7, top)
              ..lineTo(x + 7, top - 4)
              ..lineTo(x + 9, top - 4),
            line..strokeWidth = 1.2);
      case 'quay':
        canvas.drawLine(
            Offset(x - 14, y), Offset(x + 14, y), line..strokeWidth = 1.8);
        canvas.drawLine(Offset(x - 8, y), Offset(x - 8, y + 8), line);
        canvas.drawLine(Offset(x + 8, y), Offset(x + 8, y + 8), line);
        canvas.drawPath(
            Path()
              ..moveTo(x + 2, y - 14)
              ..lineTo(x + 10, y - 4)
              ..lineTo(x - 6, y - 4)
              ..close(),
            Paint()..color = palette.place.withValues(alpha: 0.8));
      case 'wharf':
        canvas.drawLine(Offset(x - 12, y - 6), Offset(x + 12, y - 6),
            line..strokeWidth = 1.8);
        canvas.drawLine(Offset(x - 12, y + 6), Offset(x + 12, y + 6), line);
        canvas.drawLine(Offset(x - 6, y - 12), Offset(x - 6, y + 12),
            line..strokeWidth = 1);
        canvas.drawLine(Offset(x + 6, y - 12), Offset(x + 6, y + 12), line);
      case 'gate':
        canvas.drawPath(
            Path()
              ..moveTo(x - 10, y + 8)
              ..lineTo(x - 10, y - 4)
              ..arcToPoint(Offset(x + 10, y - 4),
                  radius: const Radius.circular(10))
              ..lineTo(x + 10, y + 8),
            line..strokeWidth = 2);
        canvas.drawLine(Offset(x - 14, y + 8), Offset(x + 14, y + 8), line);
      case 'temple':
        final path = Path()
          ..moveTo(x - 12, y + 8)
          ..lineTo(x - 12, y - 2)
          ..lineTo(x, y - 10)
          ..lineTo(x + 12, y - 2)
          ..lineTo(x + 12, y + 8)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, line);
        canvas.drawLine(Offset(x, y - 14), Offset(x, y - 8), line);
        canvas.drawLine(Offset(x - 3, y - 11), Offset(x + 3, y - 11), line);
      case 'void':
        canvas.drawPath(
            Path()
              ..moveTo(x, y - 14)
              ..lineTo(x + 5, y - 5)
              ..lineTo(x + 3, y + 4)
              ..lineTo(x, y + 12)
              ..lineTo(x - 3, y + 4)
              ..lineTo(x - 5, y - 5)
              ..close(),
            Paint()..color = palette.voidColor.withValues(alpha: 0.9));
      case 'hall':
        canvas.drawRect(Rect.fromLTWH(x - 14, y - 2, 28, 10), fill);
        canvas.drawRect(Rect.fromLTWH(x - 14, y - 2, 28, 10), line);
        canvas.drawPath(
            Path()
              ..moveTo(x, y - 16)
              ..lineTo(x + 4, y - 10)
              ..lineTo(x - 4, y - 10)
              ..close(),
            Paint()..color = palette.mark);
        canvas.drawCircle(Offset(x, y - 12), 2, Paint()..color = ember);
      case 'market':
        canvas.drawPath(
            Path()
              ..moveTo(x - 12, y - 4)
              ..lineTo(x + 12, y - 4)
              ..lineTo(x + 9, y + 2)
              ..lineTo(x - 9, y + 2)
              ..close(),
            Paint()..color = palette.place.withValues(alpha: 0.8));
        canvas.drawLine(Offset(x - 9, y + 2), Offset(x - 9, y + 10), line);
        canvas.drawLine(Offset(x + 9, y + 2), Offset(x + 9, y + 10), line);
      case 'yard':
        canvas.drawPath(
            Path()
              ..moveTo(x - 14, y + 6)
              ..quadraticBezierTo(x, y - 12, x + 14, y + 6),
            line..strokeWidth = 2);
        canvas.drawLine(
            Offset(x - 8, y), Offset(x - 8, y - 10), line..strokeWidth = 1.5);
        canvas.drawLine(Offset(x + 8, y), Offset(x + 8, y - 10), line);
      case 'cellar':
        canvas.drawRect(Rect.fromLTWH(x - 10, y - 4, 20, 12), fill);
        canvas.drawRect(Rect.fromLTWH(x - 10, y - 4, 20, 12), line);
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), line);
      case 'field':
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(Offset(x - 12, y + i * 5.0),
              Offset(x + 12, y + i * 5.0), line..strokeWidth = 1);
        }
      case 'slum':
        final roofs = Paint()..color = palette.place.withValues(alpha: 0.8);
        canvas.drawRect(Rect.fromLTWH(x - 9, y - 6, 6, 5), roofs);
        canvas.drawRect(Rect.fromLTWH(x - 1, y - 9, 6, 5), roofs);
        canvas.drawRect(Rect.fromLTWH(x + 5, y - 3, 6, 5), roofs);
        canvas.drawRect(Rect.fromLTWH(x - 6, y + 2, 6, 5), roofs);
    }
  }

  @override
  bool shouldRepaint(PlacePlanPainter old) =>
      old.kind != kind ||
      old.water != water ||
      old.glyphs.length != glyphs.length ||
      old.seed != seed ||
      old.here != here ||
      old.palette != palette ||
      old.spots.length != spots.length ||
      [
        for (var i = 0; i < spots.length; i++) old.spots[i] != spots[i],
      ].any((changed) => changed);
}

/// A landmark on the chart, for [RegionFlightPainter]: where, its name,
/// and whether it is the one left or the one reached.
typedef ChartMark = ({Offset at, String name, bool known});

/// The road between two places on the world chart: the land and rivers of
/// [geography] framed on [from] and [to], the places around, and the
/// party walking the road at [t] (0 to 1). It zooms out of the place left
/// at the start and into the place reached at the end.
class RegionFlightPainter extends CustomPainter {
  RegionFlightPainter({
    required this.geography,
    required this.from,
    required this.to,
    required this.marks,
    required this.t,
    required this.palette,
    required this.fromName,
    required this.toName,
  });

  final ChartGeography geography;
  final Offset from;
  final Offset to;
  final List<ChartMark> marks;
  final double t;
  final ChartPalette palette;
  final String fromName;
  final String toName;

  @override
  void paint(Canvas canvas, Size size) {
    // Framed on the two places with room around, then zoomed: in from the
    // place left, out, and in again on the place reached.
    final mid = (from + to) / 2;
    final span = math.max((to - from).distance, 30.0) * 1.9;
    final fit = math.min(size.width, size.height) / span;
    final zoomIn = t < 0.2
        ? 1 - Curves.easeOut.transform(t / 0.2)
        : t > 0.8
            ? Curves.easeIn.transform((t - 0.8) / 0.2)
            : 0.0;
    final focus = t < 0.5 ? from : to;
    final centre = Offset.lerp(mid, focus, zoomIn)!;
    final scale = fit * (1 + zoomIn * 5);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.sea);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-centre.dx, -centre.dy);
    for (final land in geography.lands) {
      canvas.drawPath(
          _smooth(land, closed: true), Paint()..color = palette.land);
      canvas.drawPath(
          _smooth(land, closed: true),
          Paint()
            ..color = palette.coast
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 / scale);
    }
    for (final river in geography.rivers) {
      canvas.drawPath(
          _smooth(river, closed: false),
          Paint()
            ..color = palette.river
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 / scale);
    }
    // The road, walked so far in the party's colour.
    final d = to - from;
    final bend = Offset(-d.dy, d.dx) * 0.14;
    final road = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(from.dx + d.dx / 2 + bend.dx,
          from.dy + d.dy / 2 + bend.dy, to.dx, to.dy);
    final metric = road.computeMetrics().first;
    final walk =
        Curves.easeInOut.transform(((t - 0.18) / 0.62).clamp(0.0, 1.0));
    canvas.drawPath(
        road,
        Paint()
          ..color = palette.ahead
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale);
    canvas.drawPath(
        metric.extractPath(0, metric.length * walk),
        Paint()
          ..color = palette.mark
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3 / scale);
    for (final mark in marks) {
      canvas.drawCircle(
          mark.at, 3.2 / scale * 1.4, Paint()..color = palette.land);
      canvas.drawCircle(
          mark.at,
          3.2 / scale * 1.4,
          Paint()
            ..color = mark.known ? palette.place : palette.label
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 / scale);
    }
    final party = metric.getTangentForOffset(metric.length * walk)!.position;
    canvas.drawCircle(party, 7 / scale, Paint()..color = palette.mark);
    canvas.drawCircle(
        party,
        7 / scale,
        Paint()
          ..color = palette.land
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale);
    canvas.restore();

    // The two names, on screen.
    Offset onScreen(Offset p) =>
        (p - centre) * scale + Offset(size.width / 2, size.height / 2);
    void name(String text, Offset p, Color colour) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              color: colour,
              fontSize: 13,
              fontFamily: 'PixelifySans',
              shadows: [Shadow(color: palette.land, blurRadius: 4)]),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 160);
      final at = onScreen(p);
      final left = at.dx + 12 + painter.width > size.width
          ? at.dx - 12 - painter.width
          : at.dx + 12;
      painter.paint(canvas, Offset(left, at.dy - painter.height / 2));
    }

    if (zoomIn < 0.6) {
      name(fromName, from, palette.place);
      name(toName, to, palette.mark);
    }
  }

  static Path _smooth(List<Offset> points, {required bool closed}) {
    final path = Path();
    if (points.isEmpty) return path;
    final n = points.length;
    path.moveTo(points[0].dx, points[0].dy);
    final last = closed ? n : n - 1;
    for (var i = 0; i < last; i++) {
      final p0 = points[closed ? (i - 1 + n) % n : math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[closed ? (i + 2) % n : math.min(n - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  @override
  bool shouldRepaint(RegionFlightPainter old) =>
      old.t != t || old.from != from || old.to != to || old.palette != palette;
}
