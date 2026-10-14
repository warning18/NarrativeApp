// The city chart drawn (see city_chart.dart): the ground and the sea, the
// blocks and their lots, the avenues, squares and water, the buildings the
// story stands at, the fog over what the party has not found, and -- when
// zoomed in -- the names and the pins of the ways. All in the Map look's
// chart colours.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/map_charts.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import 'city_chart.dart';

/// How far in (the view's scale over the fitted one) the lots grow roofs,
/// the buildings their names and the ways their pins.
const double cityChartDetailZoom = 2.0;

class CityChartPainter extends CustomPainter {
  CityChartPainter({
    required this.chart,
    required this.palette,
    required this.scale,
    required this.offset,
    required this.fitted,
    this.explored,
    this.hereDistrict,
    this.hereWayId,
    this.goalWayId,
    this.selectedWayId,
    this.focusDistrict,
    this.pulse = 0,
  });

  final CityChart chart;
  final ChartPalette palette;

  /// Canvas = [offset] + plan point * [scale].
  final double scale;
  final Offset offset;

  /// The scale that fits the whole city in the view: [scale] over it is the
  /// zoom the detail rules read.
  final double fitted;

  /// The ids of the districts the party has found; null for all of them.
  final Set<String>? explored;
  final String? hereDistrict;
  final String? hereWayId;
  final String? goalWayId;
  final String? selectedWayId;

  /// The district being looked at: the others quieten.
  final String? focusDistrict;

  /// 0 to 1, repeating: the party's mark breathing.
  final double pulse;

  double get zoom => scale / fitted;
  bool get detailed => zoom >= cityChartDetailZoom;

  bool _known(String id) => explored == null || explored!.contains(id);

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    final p = palette;
    final dark = p.land.computeLuminance() < 0.4;
    final ground = _mix(p.land, p.coast, dark ? 0.16 : 0.10);
    final street = dark ? _mix(p.land, p.coast, 0.34) : const Color(0xFFF8F0DB);
    final edge = _mix(p.roofs, p.coast, 0.7);
    final fill = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    // Hairlines stay a hairline however far out the view is.
    final hair = math.max(0.4, 0.8 / scale);

    // The land and the sea.
    canvas.drawRect(chart.bounds.inflate(4000), fill..color = p.land);
    final rng = math.Random(chart.name.hashCode);
    {
      // Fields and trees outside the wall, quiet.
      final field = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _mix(p.land, p.coast, 0.35);
      for (var i = 0; i < 70; i++) {
        final x = 560 + rng.nextDouble() * (chart.width - 560);
        final y = rng.nextDouble() * chart.height;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate((rng.nextDouble() - 0.5) * 0.9);
        canvas.drawRect(
            Rect.fromLTWH(
                0, 0, 26 + rng.nextDouble() * 34, 10 + rng.nextDouble() * 12),
            field);
        canvas.restore();
      }
    }
    canvas.drawRect(
        const Rect.fromLTWH(-4000, -4000, 4000, 9000), fill..color = p.sea);
    canvas.drawPath(chart.sea, fill..color = p.sea);
    final wave = stroke
      ..strokeWidth = 1.1
      ..color = p.seaLine;
    for (var k = 0; k < 26; k++) {
      final y = k * 40.0 + 6;
      final x = 5 + rng.nextDouble() * 35;
      canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..relativeQuadraticBezierTo(10, -6, 20, 0)
            ..relativeQuadraticBezierTo(10, 6, 20, 0)
            ..relativeQuadraticBezierTo(10, -6, 20, 0),
          wave);
    }
    canvas.drawPath(chart.ground, fill..color = ground);

    // The blocks' wash, a district each.
    for (final d in chart.districts) {
      final dim = focusDistrict != null && focusDistrict != d.id ? 0.4 : 1.0;
      canvas.drawPath(
          d.blocks,
          fill
            ..color =
                d.colour.withValues(alpha: (dark ? 0.13 : 0.16) * dim + 0.02));
    }

    // Avenues and squares, then the water and its bridges.
    stroke
      ..strokeWidth = hair
      ..color = edge;
    canvas.drawPath(chart.avenues, fill..color = street);
    canvas.drawPath(chart.avenues, stroke);
    canvas.drawPath(chart.squares, fill..color = street);
    canvas.drawPath(chart.squares, stroke);
    // Streets and avenues as lines: an edge, then the road on it.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final r in chart.roads) {
      canvas.drawPath(
          r.path,
          line
            ..strokeWidth = r.width + 1.6
            ..color = edge);
    }
    for (final r in chart.roads) {
      canvas.drawPath(
          r.path,
          line
            ..strokeWidth = r.width
            ..color = street);
    }
    // Rivers and canals.
    for (final r in chart.waterways) {
      canvas.drawPath(
          r.path,
          line
            ..strokeWidth = r.width + 2.4
            ..color = p.coast);
    }
    for (final r in chart.waterways) {
      canvas.drawPath(
          r.path,
          line
            ..strokeWidth = r.width
            ..color = p.river);
    }
    final isles = chart.islands;
    if (isles != null) {
      canvas.drawPath(isles, fill..color = ground);
      canvas.drawPath(
          isles,
          stroke
            ..strokeWidth = 1.2
            ..color = p.coast);
    }
    canvas.drawPath(chart.water, fill..color = p.river);
    canvas.drawPath(
        chart.water,
        stroke
          ..strokeWidth = 1.2
          ..color = p.coast);
    canvas.drawPath(chart.bridges, fill..color = p.coast);

    // The lots: every house.
    for (final d in chart.districts) {
      final dim = focusDistrict != null && focusDistrict != d.id ? 0.55 : 1.0;
      canvas.drawPath(
          d.lots, fill..color = _mix(p.roofs, d.colour, 0.10 * dim + 0.01));
      if (zoom >= 0.9) {
        canvas.drawPath(
            d.lots,
            stroke
              ..strokeWidth = zoom >= 1.6 ? 0.5 : 0.4
              ..color = edge);
      }
      if (zoom >= 1.5) {
        canvas.drawPath(
            d.ridges,
            stroke
              ..strokeWidth = 0.5
              ..color = edge.withValues(alpha: 0.8));
      }
    }

    // The arena.
    canvas.drawPath(chart.arena, fill..color = _mix(p.roofs, p.coast, 0.3));
    canvas.drawPath(
        chart.arena,
        stroke
          ..strokeWidth = 1.2
          ..color = p.coast);
    canvas.drawPath(chart.arenaInner, fill..color = _mix(p.land, p.coast, 0.5));
    canvas.drawPath(
        chart.arenaInner,
        stroke
          ..strokeWidth = 0.8
          ..color = p.coast);

    // The buildings the story stands at.
    for (final b in chart.buildings) {
      if (b.quiet || !b.story) continue;
      final d = chart.districts[b.district];
      canvas.drawPath(b.shape, fill..color = _mix(p.roofs, d.colour, 0.55));
      canvas.drawPath(
          b.shape,
          stroke
            ..strokeWidth = 1.0
            ..color = d.colour);
      if (!b.round && zoom >= 1.5) {
        canvas.drawLine(
            b.ridge.$1,
            b.ridge.$2,
            stroke
              ..strokeWidth = 0.7
              ..color = d.colour.withValues(alpha: 0.8));
      }
    }

    _marks(canvas, fill, stroke, dark);

    // What the party has not found: fog, a dashed outline.
    for (final d in chart.districts) {
      if (_known(d.id)) continue;
      canvas.drawPath(d.blocks, fill..color = p.fog.withValues(alpha: 0.88));
      // Its buildings stand a little beyond its blocks: fogged too.
      for (final b in chart.buildings) {
        if (chart.districts[b.district].id != d.id) continue;
        canvas.drawPath(b.shape, fill..color = p.fog.withValues(alpha: 0.88));
        canvas.drawPath(
            b.shape,
            stroke
              ..strokeWidth = 7
              ..color = p.fog.withValues(alpha: 0.88));
      }
      _dashed(
          canvas,
          d.blocks,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = d.colour);
    }

    // The wall.
    canvas.drawPath(
        chart.wall,
        stroke
          ..strokeWidth = 4
          ..color = p.coast);
    fill.color = p.coast;
    for (final t in chart.towers) {
      canvas.drawRect(Rect.fromCenter(center: t, width: 10, height: 10), fill);
    }

    // Names and pins sit on the plan but are drawn at the screen's size.
    _labels(canvas);
    _pins(canvas);
    canvas.restore();
  }

  void _marks(Canvas canvas, Paint fill, Paint stroke, bool dark) {
    final p = palette;
    fill.color = chart.districts.isEmpty
        ? p.road
        : chart.districts
            .firstWhere((d) => d.id == 'alleys',
                orElse: () => chart.districts.first)
            .colour
            .withValues(alpha: 0.18);
    for (final l in chart.lanterns) {
      canvas.drawCircle(l, 6, fill);
    }
    fill.color = p.road;
    for (final l in chart.lanterns) {
      canvas.drawCircle(l, 1.5, fill);
    }
    fill.color = _mix(p.roofs, const Color(0xFFE8B94E), 0.7);
    for (final s in chart.stalls) {
      canvas.drawRect(Rect.fromLTWH(s.dx, s.dy, 6, 4), fill);
    }
    fill.color = p.place.withValues(alpha: 0.7);
    for (final (at, angle) in chart.boats) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle * math.pi / 180);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 12, height: 3.6), fill);
      canvas.restore();
    }
    for (final t in chart.trees) {
      canvas.drawCircle(t, 5, fill..color = _mix(p.land, p.river, 0.5));
      canvas.drawCircle(
          t,
          5,
          stroke
            ..strokeWidth = 0.6
            ..color = p.coast);
    }
    fill.color = p.coast;
    for (final r in chart.piers) {
      canvas.drawRect(r, fill);
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
        d += 9;
      }
    }
  }

  TextPainter _text(String s, double px, Color c,
      {FontWeight w = FontWeight.w600, String family = InkFonts.prose}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontFamily: family,
              fontSize: px,
              color: c,
              fontWeight: w,
              letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp;
  }

  void _labels(Canvas canvas) {
    final p = palette;
    final inv = 1 / scale;
    for (final d in chart.districts) {
      final known = _known(d.id);
      if (detailed && focusDistrict != d.id) continue;
      canvas.save();
      canvas.translate(d.centre.dx, d.centre.dy);
      canvas.scale(inv);
      if (!known) {
        final q = _text('?', 26, d.colour,
            w: FontWeight.w800, family: InkFonts.display);
        q.paint(canvas, Offset(-q.width / 2, -q.height / 2));
        canvas.restore();
        continue;
      }
      if (focusDistrict == null) {
        final tp = _text(d.name, 12.5, p.place, family: InkFonts.display);
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: tp.width + 14,
                height: tp.height + 8),
            const Radius.circular(8));
        canvas.drawRRect(r, Paint()..color = p.fog.withValues(alpha: 0.78));
        canvas.drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = d.colour);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      }
      canvas.restore();
    }
    if (!detailed) return;
    // Building names, in the district being looked at.
    for (final b in chart.buildings) {
      if (b.quiet || !b.story || b.name.isEmpty) continue;
      final d = chart.districts[b.district];
      if (focusDistrict != null && d.id != focusDistrict) continue;
      if (!_known(d.id)) continue;
      canvas.save();
      canvas.translate(b.at.dx, b.at.dy);
      canvas.scale(inv);
      final tp = _text(b.name, 9.5, p.place, w: FontWeight.w500);
      final below = Offset(-tp.width / 2, 12);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  below.dx - 3, below.dy - 1, tp.width + 6, tp.height + 2),
              const Radius.circular(4)),
          Paint()..color = p.fog.withValues(alpha: 0.7));
      tp.paint(canvas, below);
      canvas.restore();
    }
  }

  /// Where a way's pin sits: on its building.
  Offset pinAt(CityChartWay w) =>
      chart.buildingOf(w)?.at ?? chart.districts[w.district].centre;

  /// The pins' radius on the screen.
  static const double pinRadius = 11;

  void _pins(Canvas canvas) {
    final p = palette;
    final inv = 1 / scale;
    // The party's mark: a breathing ring on the building it stands at, or
    // on its district when it is not at a way.
    Offset? here;
    for (final w in chart.ways) {
      if (w.id == hereWayId) here = pinAt(w);
    }
    if (here == null && hereDistrict != null) {
      final d = chart.districtById(hereDistrict!);
      if (d != null && _known(d.id)) here = d.centre.translate(0, 22 * inv);
    }
    if (here != null) {
      canvas.save();
      canvas.translate(here.dx, here.dy);
      canvas.scale(inv);
      final r = 14 + 4 * pulse;
      canvas.drawCircle(
          Offset.zero,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = p.mark.withValues(alpha: 1 - 0.5 * pulse));
      canvas.drawCircle(Offset.zero, 4, Paint()..color = p.mark);
      canvas.restore();
    }
    if (!detailed) return;
    for (final w in chart.ways) {
      final d = chart.districts[w.district];
      if (focusDistrict != null && d.id != focusDistrict) continue;
      if (!_known(d.id)) continue;
      final at = pinAt(w);
      final selected = w.id == selectedWayId;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(inv);
      // The pin sits just above its building.
      canvas.translate(0, -16);
      paintWayPin(canvas, w.kind, d.colour, p,
          selected: selected, goal: w.id == goalWayId);
      canvas.restore();
    }
  }

  /// A pin: a disc in the district's colour with the sign of what the way
  /// is, a small flag on it when it is the goal the player set.
  static void paintWayPin(
      Canvas canvas, CityWayKind kind, Color colour, ChartPalette p,
      {bool selected = false, bool goal = false}) {
    canvas.drawCircle(
        const Offset(0, 1.5), pinRadius, Paint()..color = Colors.black26);
    canvas.drawCircle(Offset.zero, pinRadius, Paint()..color = p.fog);
    canvas.drawCircle(
        Offset.zero,
        pinRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 1.8
          ..color = selected ? p.mark : colour);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = p.place;
    switch (kind) {
      case CityWayKind.quest:
        // A diamond with a dot: a thing to be done.
        canvas.drawPath(
            Path()
              ..moveTo(0, -5.5)
              ..lineTo(4.5, 0)
              ..lineTo(0, 5.5)
              ..lineTo(-4.5, 0)
              ..close(),
            ink);
      case CityWayKind.fight:
        canvas.drawLine(const Offset(-4.5, -4.5), const Offset(4.5, 4.5), ink);
        canvas.drawLine(const Offset(4.5, -4.5), const Offset(-4.5, 4.5), ink);
      case CityWayKind.check:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: 9, height: 9),
                const Radius.circular(2)),
            ink);
        canvas.drawCircle(Offset.zero, 0.9, Paint()..color = p.place);
      case CityWayKind.shop:
        canvas.drawCircle(Offset.zero, 4.5, ink);
        canvas.drawLine(const Offset(0, -2), const Offset(0, 2), ink);
      case CityWayKind.road:
        canvas.drawPath(
            Path()
              ..moveTo(-3, -4.5)
              ..lineTo(3, 0)
              ..lineTo(-3, 4.5),
            ink);
    }
    if (goal) {
      canvas.drawLine(
          const Offset(5, -8),
          const Offset(5, -19),
          Paint()
            ..color = p.mark
            ..strokeWidth = 1.6);
      canvas.drawPath(
          Path()
            ..moveTo(5, -19)
            ..lineTo(13, -16)
            ..lineTo(5, -13)
            ..close(),
          Paint()..color = p.mark);
    }
  }

  @override
  bool shouldRepaint(CityChartPainter old) =>
      old.scale != scale ||
      old.offset != offset ||
      old.fitted != fitted ||
      old.palette != palette ||
      old.explored != explored ||
      old.hereDistrict != hereDistrict ||
      old.hereWayId != hereWayId ||
      old.goalWayId != goalWayId ||
      old.selectedWayId != selectedWayId ||
      old.focusDistrict != focusDistrict ||
      old.pulse != pulse;
}
