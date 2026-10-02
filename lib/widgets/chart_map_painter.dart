import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/chart_globe.dart';
import '../data/chart_relief.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../theme/stitched_ink.dart';

/// How the chart hides what the story has not reached.
enum ChartFog {
  /// A wash of night over it, cleared round each place read.
  wash,

  /// Uncharted: only a dotted coastline and the lands' names, as on a
  /// chart left unfinished (v1.199).
  uncharted,
}

/// A calque laid over the chart (v1.199): the clans' zones of influence,
/// the player's standing in each land, the lands in their colours, the
/// road by chapter, or where to trade and rest.
enum ChartCalque { none, clans, standing, lands, chapters, shops }

/// The world map as a drawn chart (see map_charts.dart): sea and land with
/// coasts broken into bays and headlands, the lands' biomes and terrain,
/// rivers, the mountain ranges, the road walked as a cased road in each
/// chapter's colour, grey trade roads, villages, bridges and the clans'
/// seats, a dotted way on to the next place, the places the story reached
/// with their names, and fog over the rest.
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
    this.fog = ChartFog.uncharted,
    this.calque = ChartCalque.none,
    this.clanColours = const {},
    this.standingOf = const {},
    this.shopPlaces = const {},
    this.campPlaces = const {},
    this.detail = true,
    this.globe,
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
  final ChartFog fog;
  final ChartCalque calque;

  /// Each clan's colour (factions.json), for the clans calque and the
  /// seats; a clan missing here is drawn in the chart's label colour.
  final Map<String, Color> clanColours;

  /// The player's standing with each clan, -100 to 100, for the standing
  /// calque.
  final Map<String, double> standingOf;

  /// Landmarks where a shop opens, and where the party can rest: the
  /// shops calque.
  final Set<String> shopPlaces;
  final Set<String> campPlaces;

  /// Terrain, features and the trade roads drawn (off for a small chart).
  final bool detail;

  /// The chart as a sphere (v1.200, see chart_globe.dart), or flat.
  final GlobeView? globe;

  /// The canvas in the chart's units: the chart itself when flat, the
  /// whole box round the sphere.
  Rect _whole =
      const Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);

  // Everything drawn goes through these: flat, a point is itself; on the
  // globe it is where the sphere shows it, or hidden.
  Offset _at(Offset p) => globe?.clamp(p) ?? p;
  bool _vis(Offset p) => globe?.visible(p) ?? true;
  Path _poly(List<Offset> pts) {
    final g = globe;
    if (g == null) return Path()..addPolygon(pts, true);
    final shown = g.polygon(pts);
    return shown == null ? Path() : (Path()..addPolygon(shown, true));
  }

  /// The line through [pts], smooth, in its visible stretches.
  Path _line(List<Offset> pts) {
    final g = globe;
    if (g == null) return _smooth(pts, closed: false);
    final path = Path();
    for (final run in g.runs(pts)) {
      path.addPath(_smooth(run, closed: false), Offset.zero);
    }
    return path;
  }

  /// The static layers of each geography and look, recorded once: sea,
  /// coasts, zones, terrain, rivers and ranges.
  static final Map<String, ui.Picture> _ground = {};

  /// The zones the story has reached: those holding a place read.
  Set<int> _reachedZones() {
    final reached = <int>{};
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      final p = geography.of(l);
      for (var i = 0; i < geography.zones.length; i++) {
        if (pointInPolygon(p, geography.zones[i].polygon)) reached.add(i);
      }
    }
    return reached;
  }

  /// Places touched by the tear: drawn in its colour.
  static const _voidPlaces = {'reliquary', 'heart', 'shore'};

  /// Where the traveller stands at [landmark] on [geography]: just left
  /// of the place's mark.
  static (double, double) spotOn(ChartGeography geography, Landmark landmark) {
    final p = geography.of(landmark);
    return (p.dx - 5, p.dy + 1);
  }

  bool _active(Landmark l) => chapterFilter == 0 || l.chapter == chapterFilter;

  bool _zoneReached(Offset p, Set<int> reached) {
    for (var i = 0; i < geography.zones.length; i++) {
      if (pointInPolygon(p, geography.zones[i].polygon)) {
        return reached.contains(i);
      }
    }
    return reached.isNotEmpty;
  }

  /// A road: a dark casing, an earth fill, the colour's dashes down the
  /// middle (no casing for a wake at sea).
  void _road(Canvas canvas, Path path, Color colour,
      {required double width,
      required bool cased,
      double phase = 0,
      double dash = 3,
      double gap = 2.2}) {
    if (cased) {
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF17151B).withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = width * 3.2);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF5E5546)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = width * 2);
    }
    _dashedPath(
        canvas,
        path,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
        dash: dash,
        gap: gap,
        phase: phase);
  }

  static void _dashedPath(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap, double phase = 0}) {
    for (final metric in path.computeMetrics()) {
      var d = -(phase % (dash + gap));
      while (d < metric.length) {
        final start = math.max(d, 0.0), end = math.min(d + dash, metric.length);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        d += dash + gap;
      }
    }
  }

  void _feature(Canvas canvas, ChartFeature f, Offset p) {
    final ink = palette.place;
    switch (f.kind) {
      case ChartFeatureKind.village:
        final seed = chartSeed(f.nameEn);
        for (var i = 0; i < 3; i++) {
          final dx = ((seed >> (i * 3)) % 7) - 3.0 + (i - 1) * 3.2;
          final dy = -3.0 - ((seed >> (i * 2 + 5)) % 3);
          canvas.drawRect(Rect.fromLTWH(p.dx + dx, p.dy + dy, 2.2, 1.6),
              Paint()..color = ink.withValues(alpha: 0.8));
        }
      case ChartFeatureKind.seat:
        final colour = clanColours[f.clan] ?? palette.label;
        canvas.drawCircle(
            p, 3.4, Paint()..color = colour.withValues(alpha: 0.18));
        canvas.drawCircle(
            p,
            3.4,
            Paint()
              ..color = colour
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.7);
        canvas.drawLine(
            Offset(p.dx + 3.4, p.dy - 0.5),
            Offset(p.dx + 3.4, p.dy - 6.5),
            Paint()
              ..color = ink
              ..strokeWidth = 0.5);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx + 3.4, p.dy - 6.5)
              ..lineTo(p.dx + 7.4, p.dy - 5.2)
              ..lineTo(p.dx + 3.4, p.dy - 3.9)
              ..close(),
            Paint()..color = colour);
      case ChartFeatureKind.bridge:
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(f.angle);
        final bar = Paint()
          ..color = const Color(0xFFA39DAE)
          ..strokeWidth = 0.7;
        canvas.drawLine(const Offset(-3.2, -1), const Offset(3.2, -1), bar);
        canvas.drawLine(const Offset(-3.2, 1), const Offset(3.2, 1), bar);
        canvas.restore();
      case ChartFeatureKind.giant:
        final stone = Paint()..color = const Color(0xFF8E8898);
        canvas.drawRect(Rect.fromLTWH(p.dx - 1, p.dy - 3, 2, 4), stone);
        canvas.drawCircle(Offset(p.dx, p.dy - 4), 1, stone);
        canvas.drawLine(
            Offset(p.dx - 2.4, p.dy + 1),
            Offset(p.dx + 2.4, p.dy + 1),
            Paint()
              ..color = const Color(0xFFA39DAE)
              ..strokeWidth = 0.5);
      case ChartFeatureKind.site:
        canvas.drawCircle(p, 1.7, Paint()..color = palette.land);
        canvas.drawCircle(
            p,
            1.7,
            Paint()
              ..color = palette.label
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
        canvas.drawCircle(p, 0.6, Paint()..color = palette.label);
    }
  }

  /// The static layers of [relief] in this look, recorded once.
  ui.Picture _groundFor(ChartRelief relief) {
    final key =
        '${identityHashCode(relief)}:${palette.hashCode}:$detail:${calque == ChartCalque.lands}:${globe?.key}';
    return _ground[key] ??= () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintGround(canvas, relief);
      return recorder.endRecording();
    }();
  }

  void _paintGround(Canvas canvas, ChartRelief relief) {
    final whole = _whole;
    // Sea, with its long swell lines; on the globe, the sky round it and
    // the parallels and meridians over it.
    final g = globe;
    final swell = Paint()
      ..color = palette.seaLine
      ..strokeWidth = 0.7;
    if (g == null) {
      canvas.drawRect(whole, Paint()..color = palette.sea);
      for (var y = 10.0; y < worldMapHeight; y += 16) {
        for (var x = (y ~/ 16).isOdd ? 0.0 : 6.0; x < worldMapWidth; x += 14) {
          canvas.drawLine(Offset(x, y), Offset(x + 6, y + 0.8), swell);
        }
      }
    } else {
      canvas.drawRect(whole, Paint()..color = palette.fog);
      canvas.drawCircle(g.centre, g.radius, Paint()..color = palette.sea);
      canvas.drawCircle(
          g.centre,
          g.radius,
          Paint()
            ..color = palette.coast.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
      final grid = Paint()
        ..color = palette.seaLine.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4;
      for (final line in GlobeView.graticule()) {
        canvas.drawPath(_line(line), grid);
      }
    }
    // Land and coast, with headlands, bays and islets.
    final coastPaint = Paint()
      ..color = palette.coast
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.9;
    final landClip = Path();
    for (final coast in [...relief.coasts, ...relief.islets]) {
      final path = _poly(coast);
      landClip.addPath(path, Offset.zero);
      canvas.drawPath(path, Paint()..color = palette.land);
      canvas.drawPath(path, coastPaint);
    }
    canvas.save();
    canvas.clipPath(landClip);
    // The lands' biomes, laid thin over the land (deeper on the lands
    // calque).
    final wash = calque == ChartCalque.lands ? 0.26 : 0.11;
    for (var i = 0; i < geography.zones.length; i++) {
      final colours = chartBiome(geography.zones[i].biome);
      canvas.drawPath(_poly(relief.zones[i]),
          Paint()..color = colours.ground.withValues(alpha: wash));
    }
    if (detail) _terrain(canvas, relief);
    // Rivers.
    final river = Paint()
      ..color = palette.river
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final r in relief.rivers) {
      canvas.drawPath(_line(r), river);
    }
    canvas.restore();
    // The ranges: peaks along each, larger than the loose ridges.
    if (detail) {
      final rng = math.Random(5);
      for (final range in geography.ranges) {
        final line = fractalLine(range.line,
            depth: 2,
            rough: 0.12,
            seed: chartSeed(range.nameEn),
            closed: false);
        for (final p in line) {
          for (var j = 0; j < 2; j++) {
            final at = p +
                Offset(
                    rng.nextDouble() * 3 - 1.5, rng.nextDouble() * 2.5 - 1.25);
            final size = range.size * 0.26 * (0.7 + rng.nextDouble() * 0.45);
            final ember = range.ember && rng.nextDouble() < 0.5;
            if (!_vis(at)) continue;
            _peak(canvas, _at(at), size, snow: range.snow, ember: ember);
          }
        }
      }
    }
  }

  void _terrain(Canvas canvas, ChartRelief relief) {
    for (final m in relief.terrain) {
      if (!_vis(m.at)) continue;
      final colours = chartBiome(geography.zones[m.zone].biome);
      final p = _at(m.at);
      final s = m.size;
      switch (m.kind) {
        case TerrainKind.peak:
          _peak(canvas, p, s * 1.1, snow: m.snow, ember: m.ember);
        case TerrainKind.tree:
          canvas.drawCircle(p, s * 1.25,
              Paint()..color = colours.detail.withValues(alpha: 0.85));
          canvas.drawLine(
              p,
              p + Offset(0, s * 1.6),
              Paint()
                ..color = const Color(0xFF17151B)
                ..strokeWidth = 0.3);
        case TerrainKind.lake:
          canvas.drawOval(
              Rect.fromCenter(center: p, width: s * 2.2, height: s * 1.3),
              Paint()..color = palette.river);
        case TerrainKind.pool:
          canvas.drawOval(Rect.fromCenter(center: p, width: s * 2, height: s),
              Paint()..color = palette.river.withValues(alpha: 0.8));
        case TerrainKind.tuft:
          final paint = Paint()
            ..color = const Color(0xFF8FA384).withValues(alpha: 0.9)
            ..strokeWidth = 0.3;
          canvas.drawLine(p, p + Offset(0, -s), paint);
          canvas.drawLine(
              p + Offset(-0.6, 0.2), p + Offset(-0.6, -s * 0.7), paint);
          canvas.drawLine(
              p + Offset(0.6, 0.2), p + Offset(0.6, -s * 0.8), paint);
        case TerrainKind.dune:
          final w = s;
          final path = Path()
            ..moveTo(p.dx - w / 2, p.dy)
            ..quadraticBezierTo(p.dx - w / 4, p.dy - w / 4, p.dx, p.dy)
            ..quadraticBezierTo(p.dx + w / 4, p.dy - w / 5, p.dx + w / 2, p.dy);
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFFC9A86A).withValues(alpha: 0.7)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.35);
        case TerrainKind.cone:
          final path = Path()
            ..moveTo(p.dx - s, p.dy + s * 0.5)
            ..lineTo(p.dx - s * 0.3, p.dy - s)
            ..lineTo(p.dx + s * 0.3, p.dy - s)
            ..lineTo(p.dx + s, p.dy + s * 0.5)
            ..close();
          canvas.drawPath(path, Paint()..color = const Color(0xFF4A4448));
          canvas.drawPath(
              path,
              Paint()
                ..color = palette.coast
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.25);
          canvas.drawLine(
              Offset(p.dx - s * 0.3, p.dy - s),
              Offset(p.dx + s * 0.3, p.dy - s),
              Paint()
                ..color = const Color(0xFFE0762B).withValues(alpha: 0.7)
                ..strokeWidth = 0.3);
        case TerrainKind.crack:
          canvas.drawLine(
              p,
              p + Offset(math.cos(m.angle) * s, math.sin(m.angle) * s),
              Paint()
                ..color = palette.coast.withValues(alpha: 0.7)
                ..strokeWidth = 0.25);
        case TerrainKind.shard:
          final path = Path()
            ..moveTo(p.dx, p.dy - s)
            ..lineTo(p.dx + s * 0.8, p.dy - s * 0.4)
            ..lineTo(p.dx + s * 0.5, p.dy + s * 0.6)
            ..lineTo(p.dx - s * 0.4, p.dy + s * 0.3)
            ..close();
          canvas.drawPath(path,
              Paint()..color = const Color(0xFFE9E6DF).withValues(alpha: 0.3));
          canvas.drawPath(
              path,
              Paint()
                ..color = palette.voidColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.25);
        case TerrainKind.cliff:
          final paint = Paint()
            ..color = const Color(0xFFB8C0B4).withValues(alpha: 0.75)
            ..strokeWidth = 0.3;
          canvas.drawLine(
              p + Offset(-s, s), p + Offset(-s * 0.3, -s * 0.7), paint);
          canvas.drawLine(
              p + Offset(s * 0.3, s), p + Offset(s, -s * 0.3), paint);
        case TerrainKind.salt:
          final paint = Paint()
            ..color = const Color(0xFFF1EBDD).withValues(alpha: 0.45)
            ..strokeWidth = 0.25;
          canvas.drawLine(p + Offset(-s, 0), p + Offset(s, 0), paint);
          canvas.drawLine(p + Offset(0, -s), p + Offset(0, s), paint);
        case TerrainKind.terrace:
          final path = Path()
            ..moveTo(p.dx - s, p.dy)
            ..quadraticBezierTo(p.dx, p.dy - s * 0.5, p.dx + s, p.dy);
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFFE9B48A).withValues(alpha: 0.7)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.35);
        case TerrainKind.hatch:
          canvas.drawCircle(p, s,
              Paint()..color = const Color(0xFFF4F7FA).withValues(alpha: 0.5));
      }
    }
  }

  void _peak(Canvas canvas, Offset p, double s,
      {bool snow = false, bool ember = false}) {
    final top = Offset(p.dx, p.dy - s * 1.1);
    final left = Offset(p.dx - s, p.dy + s * 0.5);
    final right = Offset(p.dx + s, p.dy + s * 0.5);
    canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(p.dx + 0.3, right.dy)
          ..close(),
        Paint()..color = const Color(0xFF17151B).withValues(alpha: 0.65));
    canvas.drawPath(
        Path()
          ..moveTo(left.dx, left.dy)
          ..lineTo(top.dx, top.dy)
          ..lineTo(right.dx, right.dy),
        Paint()
          ..color = const Color(0xFFA39DAE)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 0.35);
    if (snow) {
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - s * 0.35, p.dy - s * 0.5)
            ..lineTo(top.dx, top.dy)
            ..lineTo(p.dx + s * 0.35, p.dy - s * 0.5)
            ..close(),
          Paint()..color = const Color(0xFFE6ECF2).withValues(alpha: 0.85));
    }
    if (ember) {
      canvas.drawCircle(Offset(p.dx, top.dy + 0.4), 0.4,
          Paint()..color = const Color(0xFFE0762B));
    }
  }

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
    final bounds = _whole.deflate(1);
    final reached = [
      for (final l in worldMapLandmarks)
        if (discovered.contains(l.id)) l,
    ];
    final taken = <Rect>[
      for (final l in reached)
        if (_vis(geography.of(l)))
          Rect.fromCircle(
              center: _at(geography.of(l)), radius: l.big ? 4.5 : 3.5),
      // The traveller and the pin over them, where the story stands.
      if (standing != null && !walking && _vis(geography.of(standing)))
        () {
          final (x, y) = spotOn(geography, standing);
          final p = _at(Offset(x, y));
          return Rect.fromLTRB(p.dx - 2.5, p.dy - 12.5, p.dx + 2.5, p.dy + 0.5);
        }(),
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
      if (!_vis(geography.of(l))) continue;
      final p = _at(geography.of(l));
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
      if (!_vis(Offset(label.x, label.y))) continue;
      final labelAt = _at(Offset(label.x, label.y));
      // Kept inside the chart, then nudged about until clear.
      final base = Offset(
        labelAt.dx.clamp(bounds.left, bounds.right - size.width),
        labelAt.dy.clamp(bounds.top, bounds.bottom - size.height),
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

    // The lands' names (v1.199): dim until the land is reached.
    final reachedZones = _reachedZones();
    for (var i = 0; i < geography.zones.length; i++) {
      final zone = geography.zones[i];
      final named = reachedZones.contains(i);
      final painter = _layout(
        zone.name(language).toUpperCase(),
        TextStyle(
          fontFamily: InkFonts.system,
          fontSize: 5,
          letterSpacing: 1.2,
          color: palette.label.withValues(alpha: named ? 0.95 : 0.5),
        ),
      );
      final size = Size(painter.width, painter.height);
      if (!_vis(zone.labelAt)) continue;
      final zoneAt = _at(zone.labelAt);
      final base = Offset(
        (zoneAt.dx - size.width / 2)
            .clamp(bounds.left, bounds.right - size.width),
        (zoneAt.dy - size.height / 2)
            .clamp(bounds.top, bounds.bottom - size.height),
      );
      for (final nudge in const [
        Offset.zero, Offset(0, -7), Offset(0, 7), Offset(-12, 0),
        Offset(12, 0), //
      ]) {
        final rect = (base + nudge) & size;
        if (fits(rect)) {
          taken.add(rect);
          painter.paint(canvas, base + nudge);
          break;
        }
      }
    }
    if (!detail) return;
    // The ranges' names, in italics along each.
    for (final range in geography.ranges) {
      if (!_vis(range.line[range.line.length ~/ 2])) continue;
      final mid = _at(range.line[range.line.length ~/ 2]);
      final painter = _layout(
        range.name(language),
        TextStyle(
          fontFamily: InkFonts.prose,
          fontStyle: FontStyle.italic,
          fontSize: 4.6,
          color: const Color(0xFFA39DAE).withValues(alpha: 0.9),
        ),
      );
      final at = Offset(mid.dx - painter.width / 2, mid.dy + range.size * 0.5);
      final rect = at & Size(painter.width, painter.height);
      if (fits(rect)) {
        taken.add(rect);
        painter.paint(canvas, at);
      }
    }
    // The features' names and notes, under each mark, where they fit.
    for (final f in geography.features) {
      if (f.landmark.isNotEmpty) {
        // A seat that is also a story place: its note only, under the
        // place's name.
        if (!discovered.contains(f.landmark)) continue;
      } else if (!f.atSea && !_zoneReached(f.at, reachedZones)) {
        continue;
      } else if (f.atSea && reachedZones.isEmpty) {
        continue;
      }
      if (!_vis(f.at)) continue;
      final featureAt = _at(f.at);
      final seat = f.kind == ChartFeatureKind.seat;
      final colour =
          seat ? (clanColours[f.clan] ?? palette.label) : palette.place;
      final lines = [
        if (f.landmark.isEmpty)
          (
            f.name(language),
            TextStyle(
              fontFamily: seat ? InkFonts.display : InkFonts.prose,
              fontSize: seat ? 5.2 : 4.2,
              color: colour.withValues(alpha: 0.9),
              shadows: [Shadow(color: palette.land, blurRadius: 1.5)],
            )
          ),
        if (f.note(language).isNotEmpty)
          (
            f.note(language),
            TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 3.2,
              color: palette.label.withValues(alpha: 0.9),
            )
          ),
      ];
      var y = featureAt.dy + (f.landmark.isEmpty ? 3.6 : 8);
      for (final (text, style) in lines) {
        final painter = _layout(text, style);
        final at = Offset(
            (featureAt.dx - painter.width / 2)
                .clamp(bounds.left, bounds.right - painter.width),
            y);
        final rect = at & Size(painter.width, painter.height);
        if (!fits(rect)) break;
        taken.add(rect);
        painter.paint(canvas, at);
        y += painter.height - 0.4;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = reduceMotion ? 0 : frame.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final k = size.width / worldMapWidth;
    canvas.scale(k);
    final whole = globe == null
        ? const Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0)
        : Rect.fromLTWH(0, 0, size.width / k, size.height / k);
    _whole = whole;

    final relief = ChartRelief.of(geography);
    final reachedZones = _reachedZones();
    // The sphere turns under the finger: its ground is painted afresh
    // rather than kept.
    if (globe == null) {
      canvas.drawPicture(_groundFor(relief));
    } else {
      _paintGround(canvas, relief);
    }
    // Calques over the lands.
    if (calque == ChartCalque.clans || calque == ChartCalque.standing) {
      for (var i = 0; i < geography.zones.length; i++) {
        if (!reachedZones.contains(i)) continue;
        final zone = geography.zones[i];
        final path = _poly(relief.zones[i]);
        if (calque == ChartCalque.clans) {
          if (zone.influence.isEmpty) continue;
          final (first, strength) = zone.influence.first;
          final colour = clanColours[first] ?? palette.label;
          canvas.drawPath(
              path, Paint()..color = colour.withValues(alpha: 0.38 * strength));
          if (zone.influence.length > 1 && zone.influence[1].$2 >= 0.45) {
            final second = clanColours[zone.influence[1].$1] ?? palette.label;
            canvas.save();
            canvas.clipPath(path);
            final stripe = Paint()
              ..color = second.withValues(alpha: 0.45)
              ..strokeWidth = 0.8;
            for (var d = -worldMapHeight * 1.0; d < worldMapWidth; d += 3.5) {
              canvas.drawLine(Offset(d, 0),
                  Offset(d + worldMapHeight, worldMapHeight * 1.0), stripe);
            }
            canvas.restore();
          }
          canvas.drawPath(
              path,
              Paint()
                ..color = colour.withValues(alpha: 0.9)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.6);
        } else {
          if (zone.influence.isEmpty) continue;
          final standing = standingOf[zone.influence.first.$1] ?? 0;
          // Hunted red through grey to sworn gold.
          final t = ((standing + 100) / 200).clamp(0.0, 1.0);
          final colour = t < 0.5
              ? Color.lerp(
                  const Color(0xFFD9544D), const Color(0xFF8A8F98), t * 2)!
              : Color.lerp(const Color(0xFF8A8F98), const Color(0xFFF2C14E),
                  (t - 0.5) * 2)!;
          canvas.drawPath(
              path, Paint()..color = colour.withValues(alpha: 0.32));
        }
      }
    }

    // Roofs about the places reached: the fog must not give the rest away.
    final roofs = Paint()..color = palette.roofs;
    for (final l in worldMapLandmarks) {
      if (l.atSea || !discovered.contains(l.id)) continue;
      if (!_vis(geography.of(l))) continue;
      final p = _at(geography.of(l));
      final seed = l.id.codeUnits.fold(0, (a, b) => a * 31 + b);
      for (var i = 0; i < 3; i++) {
        final dx = ((seed >> (i * 3)) % 7) - 3.0 + (i - 1) * 6;
        final dy = -6.0 - ((seed >> (i * 2 + 5)) % 4);
        canvas.drawRect(Rect.fromLTWH(p.dx + dx, p.dy + dy, 4, 3), roofs);
      }
    }

    // The shops and camps calque: a coin where a shop opens, a tent where
    // the party can rest.
    if (calque == ChartCalque.shops) {
      for (final l in worldMapLandmarks) {
        if (!discovered.contains(l.id)) continue;
        if (!_vis(geography.of(l))) continue;
        final p = _at(geography.of(l));
        if (shopPlaces.contains(l.id)) {
          canvas.drawCircle(Offset(p.dx + 5, p.dy - 5), 2.4,
              Paint()..color = const Color(0xFFF2C14E));
          canvas.drawCircle(
              Offset(p.dx + 5, p.dy - 5),
              2.4,
              Paint()
                ..color = palette.land
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.6);
        }
        if (campPlaces.contains(l.id)) {
          canvas.drawPath(
              Path()
                ..moveTo(p.dx - 8, p.dy - 2)
                ..lineTo(p.dx - 5, p.dy - 7)
                ..lineTo(p.dx - 2, p.dy - 2)
                ..close(),
              Paint()..color = const Color(0xFF7DBE6A));
        }
      }
    }

    // Trade and quest roads, in grey, where both ends' lands are reached.
    if (detail) {
      for (final (a, b) in geography.tradeRoads) {
        if (!_zoneReached(a, reachedZones) || !_zoneReached(b, reachedZones)) {
          continue;
        }
        final seed = chartSeed('${a.dx},${a.dy}-${b.dx},${b.dy}');
        final path = _line(windingRoad(a, b, seed: seed, amp: 0.12));
        _road(canvas, path, palette.label.withValues(alpha: 0.9),
            width: 0.7, cased: true);
      }
    }

    // Villages, works, bridges, giants, the clans' seats and the later
    // quests' places, each once its land is reached.
    if (detail) {
      for (final f in geography.features) {
        if (!f.atSea && !_zoneReached(f.at, reachedZones)) continue;
        if (f.atSea && reachedZones.isEmpty) continue;
        if (!_vis(f.at)) continue;
        _feature(canvas, f, _at(f.at));
      }
    }

    // Fog over what the story has not reached.
    canvas.saveLayer(whole, Paint());
    final fogPaint = Paint()
      ..color =
          palette.fog.withValues(alpha: fog == ChartFog.uncharted ? 0.94 : 0.9);
    if (globe case final g?) {
      canvas.drawCircle(g.centre, g.radius, fogPaint);
    } else {
      canvas.drawRect(whole, fogPaint);
    }
    if (fog == ChartFog.uncharted) {
      // The coasts, dotted, and the lands' names: the world has a shape
      // before the story.
      final dotted = Paint()
        ..color = palette.coast.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      for (final coast in relief.coasts) {
        _dashedPath(canvas, _poly(coast), dotted, dash: 1.2, gap: 1.2);
      }
    }
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      if (!_vis(geography.of(l))) continue;
      final p = _at(geography.of(l));
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
      if (_vis(geography.of(standing)) && _vis(geography.of(next))) {
        _dashed(
            canvas, _at(geography.of(standing)), _at(geography.of(next)), dots,
            dash: 0.6, gap: 3);
      }
    }

    // The road walked, a cased road in each chapter's colour, its dashes
    // moving along; a sea leg is a dashed wake.
    for (final (a, b) in legs) {
      final on = (_active(a) && _active(b)) ||
          (chapterFilter != 0 &&
              (a.chapter == chapterFilter || b.chapter == chapterFilter));
      final from = geography.of(a), to = geography.of(b);
      final seaLeg =
          a.atSea || b.atSea || (a.id == 'shore' && b.id == 'candlehold');
      final seed = chartSeed('${a.id}-${b.id}');
      final path = _line(windingRoad(from, to,
          seed: seed, bends: seaLeg ? 2 : 3, amp: seaLeg ? 0.08 : 0.16));
      final colour = (chapterFilter == 0 || a.chapter == chapterFilter
              ? chapterColor(a.chapter)
              : chapterColor(b.chapter))
          .withValues(alpha: on ? 0.95 : 0.3);
      _road(canvas, path, colour,
          width: 0.9,
          cased: !seaLeg,
          phase: -f * 1.3,
          dash: seaLeg ? 2.4 : 3,
          gap: seaLeg ? 1.8 : 2.2);
    }

    // The places and their names.
    for (final l in worldMapLandmarks) {
      if (!discovered.contains(l.id)) continue;
      if (!_vis(geography.of(l))) continue;
      final p = _at(geography.of(l));
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
    if (at != null && _vis(Offset(at.$1, at.$2))) {
      final shown = _at(Offset(at.$1, at.$2));
      final x = shown.dx, y = shown.dy;
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
