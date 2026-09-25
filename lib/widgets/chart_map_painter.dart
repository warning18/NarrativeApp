import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../theme/stitched_ink.dart';

/// The world map as a drawn chart (see map_charts.dart): sea and land,
/// rivers, the road walked in dashes, a dotted way on to the next place,
/// the places the story reached with their names, and fog over the rest.
class ChartMapPainter extends CustomPainter {
  ChartMapPainter({
    required this.frame,
    required this.walk,
    required this.geography,
    required this.palette,
    required this.language,
    required this.discovered,
    required this.legs,
    required this.ahead,
    required this.selectedId,
    required this.here,
    required this.walking,
    required this.walkPath,
    required this.chapterFilter,
    required this.reduceMotion,
    required this.chapterColor,
  }) : super(repaint: Listenable.merge([frame, walk]));

  final ValueNotifier<int> frame;
  final Animation<double> walk;
  final ChartGeography geography;
  final ChartPalette palette;
  final AppLanguage language;
  final Set<String> discovered;
  final List<(Landmark, Landmark)> legs;

  /// The next place the story goes, not reached yet: a dotted way to it.
  final Landmark? ahead;
  final String selectedId;
  final Landmark? here;
  final bool walking;
  final List<(double, double)> walkPath;
  final int chapterFilter;
  final bool reduceMotion;
  final Color Function(int chapter) chapterColor;

  /// Places touched by the tear: drawn in its colour.
  static const _voidPlaces = {'reliquary', 'heart', 'shore'};

  /// Where the traveller stands at [landmark] on [geography]: just left
  /// of the place's mark.
  static (double, double) spotOn(ChartGeography geography, Landmark landmark) {
    final p = geography.of(landmark);
    return (p.dx - 5, p.dy + 1);
  }

  bool _active(Landmark l) => chapterFilter == 0 || l.chapter == chapterFilter;

  /// A smooth closed (or open) path through [points] (Catmull-Rom).
  Path _smooth(List<Offset> points, {required bool closed}) {
    final path = Path();
    if (points.isEmpty) return path;
    final n = points.length;
    Offset at(int i) =>
        closed ? points[(i % n + n) % n] : points[i.clamp(0, n - 1)];
    path.moveTo(points.first.dx, points.first.dy);
    final last = closed ? n : n - 1;
    for (var i = 0; i < last; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 3, double gap = 2, double phase = 0}) {
    final delta = b - a;
    final length = delta.distance;
    if (length == 0) return;
    final dir = delta / length;
    var d = -(phase % (dash + gap));
    while (d < length) {
      final start = math.max(d, 0.0), end = math.min(d + dash, length);
      if (end > start) canvas.drawLine(a + dir * start, a + dir * end, paint);
      d += dash + gap;
    }
  }

  TextPainter _layout(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Every name on the chart, set where it fits: each reached place's
  /// name beside its mark (right, left, above or below, the first spot
  /// inside the chart and clear of the other names and marks), then the
  /// regions' names where there is room for them.
  void _names(Canvas canvas, Landmark? standing) {
    const bounds =
        Rect.fromLTWH(1, 1, worldMapWidth - 2.0, worldMapHeight - 2.0);
    final reached = [
      for (final l in worldMapLandmarks)
        if (discovered.contains(l.id)) l,
    ];
    final taken = <Rect>[
      for (final l in reached)
        Rect.fromCircle(center: geography.of(l), radius: l.big ? 4.5 : 3.5),
    ];
    bool fits(Rect r) =>
        bounds.contains(r.topLeft) &&
        bounds.contains(r.bottomRight) &&
        !taken.any((t) => t.overlaps(r));

    // Where the story is gets the first pick, then the chosen place, then
    // the rest in story order.
    final order = [
      ...reached.where((l) => l.id == standing?.id),
      ...reached.where((l) => l.id == selectedId && l.id != standing?.id),
      ...reached.where((l) => l.id != standing?.id && l.id != selectedId),
    ];
    for (final l in order) {
      final p = geography.of(l);
      final isHere = l.id == standing?.id;
      final opacity = _active(l) ? 1.0 : 0.35;
      final painter = _layout(
        l.name(language),
        TextStyle(
          fontFamily: InkFonts.prose,
          fontSize: 6,
          fontWeight: isHere ? FontWeight.w600 : FontWeight.w400,
          color: (isHere ? palette.mark : palette.place)
              .withValues(alpha: opacity),
          shadows: [Shadow(color: palette.land, blurRadius: 2)],
        ),
      );
      final w = painter.width, h = painter.height;
      final right = Offset(p.dx + 5.5, p.dy - h / 2);
      final left = Offset(p.dx - 5.5 - w, p.dy - h / 2);
      final above = Offset(p.dx - w / 2, p.dy - 4.5 - h);
      final below = Offset(p.dx - w / 2, p.dy + 4.5);
      // Above and below slide along to stay inside the chart.
      Offset inside(Offset at) =>
          Offset(at.dx.clamp(bounds.left, bounds.right - w).toDouble(), at.dy);
      final tries = geography.labelsLeft(l)
          ? [left, right, inside(above), inside(below)]
          : [right, left, inside(above), inside(below)];
      Offset? spot;
      for (final at in tries) {
        if (fits(at & Size(w, h))) {
          spot = at;
          break;
        }
      }
      // Nowhere clear: the spot inside the chart that overlaps least.
      if (spot == null) {
        var least = double.infinity;
        for (final at in tries) {
          final rect = at & Size(w, h);
          if (!bounds.contains(rect.topLeft) ||
              !bounds.contains(rect.bottomRight)) {
            continue;
          }
          final overlap = taken.fold(0.0, (sum, t) {
            final i = t.intersect(rect);
            return i.isEmpty ? sum : sum + i.width * i.height;
          });
          if (overlap < least) {
            least = overlap;
            spot = at;
          }
        }
      }
      spot ??= right;
      taken.add(spot & Size(w, h));
      painter.paint(canvas, spot);
    }

    // Region names: named once reached, "uncharted" before, and only
    // where they fit (nudged a little if need be).
    final highest = reached.fold(0, (m, l) => l.chapter > m ? l.chapter : m);
    for (final label in geography.labels) {
      final named = label.chapter <= highest;
      final painter = _layout(
        named
            ? label.text(language)
            : (language == AppLanguage.fr ? 'INEXPLORÉ' : 'UNCHARTED'),
        !named
            ? TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 5,
                letterSpacing: 1,
                color: palette.label.withValues(alpha: 0.7),
              )
            : label.sea
                ? TextStyle(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    fontSize: 7,
                    color: palette.label,
                  )
                : TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 8,
                    letterSpacing: 1.5,
                    color: palette.label,
                  ),
      );
      final size = Size(painter.width, painter.height);
      // Kept inside the chart, then nudged about until clear.
      final base = Offset(
        label.x.clamp(bounds.left, bounds.right - size.width),
        label.y.clamp(bounds.top, bounds.bottom - size.height),
      );
      for (final nudge in const [
        Offset.zero, Offset(0, -8), Offset(0, 8), Offset(-16, 0), //
        Offset(16, 0), Offset(0, -16), Offset(0, 16),
      ]) {
        final at = base + nudge;
        final rect = at & size;
        if (fits(rect)) {
          taken.add(rect);
          painter.paint(canvas, at);
          break;
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = reduceMotion ? 0 : frame.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / worldMapWidth);
    const whole =
        Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);

    // Sea, with its long swell lines.
    canvas.drawRect(whole, Paint()..color = palette.sea);
    final swell = Paint()
      ..color = palette.seaLine
      ..strokeWidth = 0.7;
    for (var y = 10.0; y < worldMapHeight; y += 16) {
      for (var x = (y ~/ 16).isOdd ? 0.0 : 6.0; x < worldMapWidth; x += 14) {
        canvas.drawLine(Offset(x, y), Offset(x + 6, y + 0.8), swell);
      }
    }

    // Land and coast.
    for (final land in geography.lands) {
      final path = _smooth(land, closed: true);
      canvas.drawPath(path, Paint()..color = palette.land);
      canvas.drawPath(
          path,
          Paint()
            ..color = palette.coast
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
    }
    final riverPaint = Paint()
      ..color = palette.river
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    for (final river in geography.rivers) {
      canvas.drawPath(_smooth(river, closed: false), riverPaint);
    }

    // Roofs about the places on land.
    final roofs = Paint()..color = palette.roofs;
    for (final l in worldMapLandmarks) {
      if (l.atSea) continue;
      final p = geography.of(l);
      final seed = l.id.codeUnits.fold(0, (a, b) => a * 31 + b);
      for (var i = 0; i < 3; i++) {
        final dx = ((seed >> (i * 3)) % 7) - 3.0 + (i - 1) * 6;
        final dy = -6.0 - ((seed >> (i * 2 + 5)) % 4);
        canvas.drawRect(Rect.fromLTWH(p.dx + dx, p.dy + dy, 4, 3), roofs);
      }
    }

    // Fog over what the story has not reached.
    canvas.saveLayer(whole, Paint());
    canvas.drawRect(whole, Paint()..color = palette.fog.withValues(alpha: 0.9));
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      final p = geography.of(l);
      canvas.drawCircle(
        p,
        30,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = const RadialGradient(
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromCircle(center: p, radius: 30)),
      );
    }
    canvas.restore();

    // The way on, dotted, to the next place the story goes.
    final next = ahead;
    final standing = here;
    if (next != null && standing != null) {
      final dots = Paint()
        ..color = palette.ahead
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;
      _dashed(canvas, geography.of(standing), geography.of(next), dots,
          dash: 0.6, gap: 3);
    }

    // The road walked, its dashes moving along.
    for (final (a, b) in legs) {
      final on = (_active(a) && _active(b)) ||
          (chapterFilter != 0 &&
              (a.chapter == chapterFilter || b.chapter == chapterFilter));
      final road = Paint()
        ..color = palette.road.withValues(alpha: on ? 0.9 : 0.25)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      _dashed(canvas, geography.of(a), geography.of(b), road,
          dash: 3, gap: 2.2, phase: -f * 1.3);
    }

    // The places and their names.
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      final p = geography.of(l);
      final isHere = l.id == standing?.id;
      final opacity = _active(l) ? 1.0 : 0.35;
      final color = (_voidPlaces.contains(l.id)
              ? palette.voidColor
              : chapterColor(l.chapter))
          .withValues(alpha: opacity);
      if (l.atSea) {
        canvas.drawCircle(
            p,
            2.4,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      } else {
        canvas.drawCircle(p, l.big ? 3.6 : 2.6, Paint()..color = color);
      }
      if (isHere) {
        canvas.drawCircle(
            p,
            4.6,
            Paint()
              ..color = palette.mark
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4);
      }
      if (l.id == selectedId && (reduceMotion || f % 4 < 3)) {
        canvas.drawCircle(
            p,
            6.8,
            Paint()
              ..color = palette.place.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.6);
      }
    }

    _names(canvas, standing);

    // The traveller: walking the road, or standing where the story is
    // under a bobbing pin.
    (double, double)? at;
    if (walking && walkPath.length >= 2) {
      at = pointAlong(walkPath, walk.value);
    } else if (standing != null) {
      at = spotOn(geography, standing);
    }
    if (at != null) {
      final (x, y) = at;
      final cloak = Paint()..color = const Color(0xFFA8A194);
      canvas.drawPath(
          Path()
            ..moveTo(x - 1.8, y)
            ..lineTo(x + 1.8, y)
            ..lineTo(x, y - 4.6)
            ..close(),
          cloak);
      canvas.drawCircle(Offset(x, y - 5.4), 1.2, cloak);
      if (!walking) {
        final bob = f % 4 < 2 ? 0.0 : 0.8;
        canvas.drawPath(
            Path()
              ..moveTo(x, y - 7.5 - bob)
              ..lineTo(x + 1.6, y - 9.6 - bob)
              ..lineTo(x, y - 11.7 - bob)
              ..lineTo(x - 1.6, y - 9.6 - bob)
              ..close(),
            Paint()..color = palette.mark);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ChartMapPainter old) => true;
}
