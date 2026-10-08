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
    this.zoomOf,
    Listenable? view,
  }) : super(repaint: Listenable.merge([frame, walk, if (view != null) view]));

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

  /// How close the chart is looked at (1 = the whole of it in the box):
  /// the names keep a readable size and the small detail shows as the
  /// chart comes closer (v1.202). Null reads as 1.
  final double Function()? zoomOf;

  /// How close the chart is looked at, clamped, and the sizes that follow
  /// it: names and marks shrink in the chart's units as it comes closer,
  /// so they keep near one size on screen; the fine detail (coast ticks,
  /// stipple, the features' names) shows from the second level on.
  double get _zoom => (zoomOf?.call() ?? 1).clamp(1.0, 12.0);
  int get _lod => _zoom < 1.8
      ? 0
      : _zoom < 4.5
          ? 1
          : 2;
  double get _t => math.pow(_zoom, -0.8).toDouble();
  double get _m => math.pow(_zoom, -0.65).toDouble();
  double get _w => math.pow(_zoom, -0.45).toDouble();

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

  /// A house: a body and a pitched roof, [w] wide, at [o] (its foot's
  /// middle).
  void _house(
      Canvas canvas, Offset o, double w, double h, Color body, Color roof) {
    canvas.drawRect(
        Rect.fromLTWH(o.dx - w / 2, o.dy - h, w, h), Paint()..color = body);
    canvas.drawPath(
        Path()
          ..moveTo(o.dx - w / 2 - 0.2, o.dy - h)
          ..lineTo(o.dx, o.dy - h - w * 0.55)
          ..lineTo(o.dx + w / 2 + 0.2, o.dy - h)
          ..close(),
        Paint()..color = roof);
  }

  void _feature(Canvas canvas, ChartFeature f, Offset p) {
    final ink = palette.place;
    final dark = const Color(0xFF17151B).withValues(alpha: 0.8);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.scale((_m * 1.3).clamp(0.3, 1.3));
    switch (f.kind) {
      case ChartFeatureKind.village:
        // Four houses about a lane, and a field or two beside them.
        final seed = chartSeed(f.nameEn);
        final field = Paint()
          ..color = ink.withValues(alpha: 0.45)
          ..strokeWidth = 0.25;
        final fx = (seed % 2 == 0 ? 4.0 : -8.5), fy = -1.5;
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
              Offset(fx, fy + i * 0.9), Offset(fx + 4.5, fy + i * 0.9), field);
        }
        for (var i = 0; i < 4; i++) {
          final dx = -3.6 + i * 2.5 + (((seed >> (i * 3)) % 5) - 2) * 0.25;
          final dy = ((seed >> (i * 2 + 5)) % 3) * 0.6 - 0.4;
          _house(canvas, Offset(dx, dy), 1.9, 1.3, ink.withValues(alpha: 0.85),
              dark);
        }
      case ChartFeatureKind.seat:
        // The clan's hold: a keep between two towers on a ring wall, its
        // banner in the clan's colour.
        final colour = clanColours[f.clan] ?? palette.label;
        canvas.drawCircle(
            Offset.zero, 4.2, Paint()..color = colour.withValues(alpha: 0.16));
        canvas.drawCircle(
            Offset.zero,
            4.2,
            Paint()
              ..color = colour
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.6);
        final stone = Paint()..color = ink.withValues(alpha: 0.9);
        canvas.drawRect(const Rect.fromLTWH(-2.4, -1.6, 4.8, 2.6), stone);
        canvas.drawRect(const Rect.fromLTWH(-3.2, -3.2, 1.4, 4.2), stone);
        canvas.drawRect(const Rect.fromLTWH(1.8, -3.2, 1.4, 4.2), stone);
        canvas.drawRect(const Rect.fromLTWH(-0.9, -3.0, 1.8, 1.4), stone);
        final merlon = Paint()..color = dark;
        for (final x in const [-3.2, -2.4, 1.8, 2.6]) {
          canvas.drawRect(Rect.fromLTWH(x, -3.5, 0.5, 0.5), merlon);
        }
        canvas.drawLine(
            const Offset(0, -3),
            const Offset(0, -7.2),
            Paint()
              ..color = ink
              ..strokeWidth = 0.4);
        canvas.drawPath(
            Path()
              ..moveTo(0, -7.2)
              ..lineTo(3.4, -6.1)
              ..lineTo(0, -5)
              ..close(),
            Paint()..color = colour);
      case ChartFeatureKind.bridge:
        canvas.rotate(f.angle);
        final bar = Paint()
          ..color = const Color(0xFFA39DAE)
          ..strokeWidth = 0.6;
        canvas.drawLine(const Offset(-4, -1.1), const Offset(4, -1.1), bar);
        canvas.drawLine(const Offset(-4, 1.1), const Offset(4, 1.1), bar);
        final arch = Paint()
          ..color = const Color(0xFFA39DAE).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4;
        for (final x in const [-2.2, 0.0, 2.2]) {
          canvas.drawPath(
              Path()
                ..moveTo(x - 1, 1.1)
                ..quadraticBezierTo(x, 2.6, x + 1, 1.1),
              arch);
        }
      case ChartFeatureKind.giant:
        final stone = Paint()..color = const Color(0xFF8E8898);
        canvas.drawOval(const Rect.fromLTWH(-2.6, 1.2, 5.2, 1.2),
            Paint()..color = dark.withValues(alpha: 0.35));
        canvas.drawRect(const Rect.fromLTWH(-1.1, -3.4, 2.2, 4.6), stone);
        canvas.drawRect(const Rect.fromLTWH(-2.2, -2.8, 1, 3), stone);
        canvas.drawRect(const Rect.fromLTWH(1.2, -2.8, 1, 3), stone);
        canvas.drawCircle(const Offset(0, -4.4), 1.1, stone);
        canvas.drawLine(
            const Offset(-2.8, 1.2),
            const Offset(2.8, 1.2),
            Paint()
              ..color = const Color(0xFFA39DAE)
              ..strokeWidth = 0.5);
      case ChartFeatureKind.site:
        // A ruin: two columns, a fallen lintel, rubble.
        final stone = Paint()..color = ink.withValues(alpha: 0.8);
        canvas.drawRect(const Rect.fromLTWH(-2.4, -3, 0.9, 3.4), stone);
        canvas.drawRect(const Rect.fromLTWH(1.2, -2.2, 0.9, 2.6), stone);
        canvas.save();
        canvas.rotate(0.35);
        canvas.drawRect(const Rect.fromLTWH(-1.2, 0.2, 3.2, 0.7), stone);
        canvas.restore();
        for (final r in const [
          Offset(-1.4, 1.1),
          Offset(0.6, 1.6),
          Offset(2.6, 0.9)
        ]) {
          canvas.drawCircle(r, 0.35, stone);
        }
    }
    canvas.restore();
  }

  /// The static layers of [relief] in this look, recorded once.
  ui.Picture _groundFor(ChartRelief relief) {
    final key =
        '${identityHashCode(relief)}:${palette.hashCode}:$detail:${calque == ChartCalque.lands}:${globe?.key}:$_lod';
    return _ground[key] ??= () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintGround(canvas, relief);
      return recorder.endRecording();
    }();
  }

  void _paintGround(Canvas canvas, ChartRelief relief) {
    final whole = _whole;
    // The sphere is painted afresh on every turn, so it keeps to the
    // coarse detail.
    final lod = globe == null ? _lod : 0;
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
    // Waves on the open sea (v1.202).
    if (detail) {
      var i = 0;
      for (final w in relief.waves) {
        i++;
        if (lod == 0 && i.isOdd) continue;
        if (!_vis(w)) continue;
        _wave(canvas, _at(w), 2.4);
      }
    }
    // The shallows along every coast (v1.202): the sea paler there, in
    // two bands, under the land.
    final shallow = Color.lerp(palette.sea, palette.seaLine, 0.9)!;
    final allCoasts = [...relief.coasts, ...relief.islets];
    for (final coast in allCoasts) {
      final path = _poly(coast);
      canvas.drawPath(
          path,
          Paint()
            ..color = shallow.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 7);
      canvas.drawPath(
          path,
          Paint()
            ..color = shallow.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 3);
    }
    // Land and coast, with headlands, bays and islets.
    final coastPaint = Paint()
      ..color = palette.coast
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.9;
    final landClip = Path();
    for (final coast in allCoasts) {
      final path = _poly(coast);
      landClip.addPath(path, Offset.zero);
      canvas.drawPath(path, Paint()..color = palette.land);
      canvas.drawPath(path, coastPaint);
    }
    // Water lines off the coasts (v1.202), as a pen chart hatches them.
    if (detail && lod >= 1) {
      for (final coast in relief.coasts) {
        _coastTicks(canvas, coast, lod);
      }
    }
    canvas.save();
    canvas.clipPath(landClip);
    // A pale shore band inside every coast (v1.202).
    final shore = Color.lerp(palette.land, palette.coast, 0.35)!;
    for (final coast in allCoasts) {
      canvas.drawPath(
          _poly(coast),
          Paint()
            ..color = shore.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 2.4);
    }
    // The lands' biomes, laid thin over the land (deeper on the lands
    // calque), each land's edge dotted (v1.202).
    final wash = calque == ChartCalque.lands ? 0.26 : 0.11;
    for (var i = 0; i < geography.zones.length; i++) {
      final colours = chartBiome(geography.zones[i].biome);
      canvas.drawPath(_poly(relief.zones[i]),
          Paint()..color = colours.ground.withValues(alpha: wash));
    }
    final border = Paint()
      ..color = palette.coast.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35;
    for (var i = 0; i < geography.zones.length; i++) {
      _dashedPath(canvas, _poly(relief.zones[i]), border, dash: 0.9, gap: 1.3);
    }
    // The ground's grain (v1.202): a stipple of each biome's accent.
    if (detail && lod >= 1) {
      for (var i = 0; i < geography.zones.length; i++) {
        _stipple(canvas, relief.zones[i], geography.zones[i], lod);
      }
    }
    if (detail) _terrain(canvas, relief);
    if (detail && lod >= 1) _terrain(canvas, relief, fine: true);
    // Rivers (v1.202): a thread at the source widening to the mouth, a
    // light down the middle, the streams that feed them, and a small
    // delta where each meets the sea.
    for (final t in relief.tributaries) {
      _river(canvas, t, from: 0.45, to: 0.9, colour: palette.river);
    }
    final gleam = Color.lerp(palette.river, Colors.white, 0.28)!;
    for (final r in relief.rivers) {
      _river(canvas, r, from: 0.8, to: 2.4, colour: palette.river);
      _river(canvas, r.sublist(r.length ~/ 3),
          from: 0.25, to: 0.5, colour: gleam.withValues(alpha: 0.45));
      _delta(canvas, r);
    }
    canvas.restore();
    // The ranges: a ridge line, and peaks along it larger than the loose
    // ridges, shaded on their east side.
    if (detail) {
      final rng = math.Random(5);
      for (final range in geography.ranges) {
        final line = fractalLine(range.line,
            depth: 2,
            rough: 0.12,
            seed: chartSeed(range.nameEn),
            closed: false);
        canvas.drawPath(
            _line(line),
            Paint()
              ..color = const Color(0xFF17151B).withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = range.size * 0.4);
        for (final p in line) {
          for (var j = 0; j < 2; j++) {
            final at = p +
                Offset(
                    rng.nextDouble() * 3 - 1.5, rng.nextDouble() * 2.5 - 1.25);
            final size = range.size * 0.3 * (0.7 + rng.nextDouble() * 0.45);
            final ember = range.ember && rng.nextDouble() < 0.5;
            if (!_vis(at)) continue;
            _peak(canvas, _at(at), size, snow: range.snow, ember: ember);
          }
        }
      }
    }
  }

  /// A wave on the open sea: two crests, one under the other.
  void _wave(Canvas canvas, Offset p, double s) {
    final crest = Color.lerp(palette.seaLine, Colors.white, 0.18)!;
    final paint = Paint()
      ..color = crest.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.4;
    canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy)
          ..quadraticBezierTo(p.dx - s / 2, p.dy - s * 0.5, p.dx, p.dy)
          ..quadraticBezierTo(p.dx + s / 2, p.dy + s * 0.5, p.dx + s, p.dy),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(p.dx - s * 0.5, p.dy + 1.3)
          ..quadraticBezierTo(
              p.dx - s * 0.2, p.dy + 1.3 - s * 0.35, p.dx + s * 0.1, p.dy + 1.3)
          ..quadraticBezierTo(p.dx + s * 0.4, p.dy + 1.3 + s * 0.35,
              p.dx + s * 0.7, p.dy + 1.3),
        paint..color = crest.withValues(alpha: 0.5));
  }

  /// Short lines off the sea side of [coast], every so often along it: a
  /// second row further out at the closest level.
  void _coastTicks(Canvas canvas, List<Offset> coast, int lod) {
    final n = coast.length;
    if (n < 3) return;
    final tick = Paint()
      ..color =
          Color.lerp(palette.sea, palette.coast, 0.6)!.withValues(alpha: 0.85)
      ..strokeWidth = 0.28;
    final far = Paint()
      ..color =
          Color.lerp(palette.sea, palette.coast, 0.5)!.withValues(alpha: 0.5)
      ..strokeWidth = 0.25;
    // Which side is the sea: the first edge's left normal, tested once.
    var sign = 1.0;
    for (var i = 0; i < n; i++) {
      final a = coast[i], b = coast[(i + 1) % n];
      final d = b - a;
      if (d.distance < 0.5) continue;
      final left = Offset(d.dy, -d.dx) / d.distance;
      sign = pointInPolygon(a + d / 2 + left * 0.8, coast) ? -1.0 : 1.0;
      break;
    }
    var carry = 0.0;
    const step = 2.3;
    for (var i = 0; i < n; i++) {
      final a = coast[i], b = coast[(i + 1) % n];
      final d = b - a;
      final length = d.distance;
      if (length == 0) continue;
      final normal = Offset(d.dy, -d.dx) / length * sign;
      var at = step - carry;
      while (at < length) {
        final p = a + d * (at / length);
        if (_vis(p)) {
          canvas.drawLine(_at(p + normal * 0.7), _at(p + normal * 1.7), tick);
          if (lod >= 2) {
            canvas.drawLine(_at(p + normal * 2.5), _at(p + normal * 3.1), far);
          }
        }
        at += step;
      }
      carry = length - (at - step);
    }
  }

  /// Dots of the biome's accent over the land [poly] of [zone].
  void _stipple(Canvas canvas, List<Offset> poly, ChartZone zone, int lod) {
    final rng = math.Random(chartSeed(zone.nameEn));
    final xs = poly.map((p) => p.dx), ys = poly.map((p) => p.dy);
    final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
    final y0 = ys.reduce(math.min), y1 = ys.reduce(math.max);
    final area = (x1 - x0) * (y1 - y0);
    final n = (area / (lod >= 2 ? 40 : 75)).round().clamp(8, 600);
    final dot = Paint()
      ..color = chartBiome(zone.biome).accent.withValues(alpha: 0.22);
    for (var i = 0; i < n; i++) {
      final p = Offset(
          x0 + rng.nextDouble() * (x1 - x0), y0 + rng.nextDouble() * (y1 - y0));
      if (!pointInPolygon(p, poly) || !_vis(p)) continue;
      canvas.drawCircle(_at(p), 0.22 + rng.nextDouble() * 0.14, dot);
    }
  }

  /// A river (or a stream) as a line that widens from [from] at its
  /// source to [to] at its mouth.
  void _river(Canvas canvas, List<Offset> pts,
      {required double from, required double to, required Color colour}) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (globe != null) {
      canvas.drawPath(_line(pts), paint..strokeWidth = (from + to) / 2);
      return;
    }
    final path = _smooth(pts, closed: false);
    for (final metric in path.computeMetrics()) {
      final n = (metric.length / 2.5).ceil().clamp(2, 400);
      for (var i = 0; i < n; i++) {
        final a = metric.length * i / n, b = metric.length * (i + 1) / n;
        final w = from + (to - from) * ((i + 0.5) / n);
        canvas.drawPath(metric.extractPath(a, math.min(b + 0.3, metric.length)),
            paint..strokeWidth = w);
      }
    }
  }

  /// The small fan of a river's mouth.
  void _delta(Canvas canvas, List<Offset> river) {
    if (river.length < 2 || !_vis(river.last)) return;
    final mouth = river.last;
    final d = mouth - river[river.length - 2];
    if (d.distance == 0) return;
    final dir = d / d.distance;
    final paint = Paint()
      ..color = palette.river.withValues(alpha: 0.7)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.7;
    for (final a in const [-0.5, 0.5]) {
      final turned = Offset(dir.dx * math.cos(a) - dir.dy * math.sin(a),
          dir.dx * math.sin(a) + dir.dy * math.cos(a));
      canvas.drawLine(_at(mouth), _at(mouth + turned * 2.6), paint);
    }
  }

  /// A compass rose: four long points, four short, north named.
  void _compass(Canvas canvas, Offset c, double r) {
    final ink = palette.label.withValues(alpha: 0.9);
    final fill = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35;
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * 0.55, line..strokeWidth = 0.25);
    for (var i = 0; i < 8; i++) {
      final long = i.isEven;
      final a = i * math.pi / 4 - math.pi / 2;
      final len = long ? r * (i == 0 ? 1.25 : 0.95) : r * 0.5;
      final tip = c + Offset(math.cos(a), math.sin(a)) * len;
      final half = long ? r * 0.16 : r * 0.1;
      final side = Offset(-math.sin(a), math.cos(a)) * half;
      final base = c + Offset(math.cos(a), math.sin(a)) * (long ? 0 : r * 0.2);
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(base.dx + side.dx, base.dy + side.dy)
            ..lineTo(base.dx - side.dx, base.dy - side.dy)
            ..close(),
          long ? fill : Paint()
            ..color = ink.withValues(alpha: 0.55));
    }
    final n = _layout(
        'N',
        TextStyle(
            fontFamily: InkFonts.display, fontSize: 4.2, color: palette.place));
    n.paint(canvas, Offset(c.dx - n.width / 2, c.dy - r * 1.25 - n.height));
  }

  /// A chart's scale bar: thirty leagues in alternating blocks.
  void _scaleBar(Canvas canvas, Offset o) {
    final ink = palette.label.withValues(alpha: 0.9);
    const unit = 10.0;
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(o.dx + i * unit, o.dy, unit, 1.1);
      canvas.drawRect(
          rect,
          i.isEven
              ? (Paint()..color = ink)
              : (Paint()
                ..color = ink
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.3));
    }
    final caption = _layout(
        language == AppLanguage.fr ? '30 lieues' : '30 leagues',
        TextStyle(
            fontFamily: InkFonts.prose,
            fontStyle: FontStyle.italic,
            fontSize: 3.2,
            color: ink));
    caption.paint(canvas, Offset(o.dx, o.dy - caption.height - 0.3));
  }

  void _terrain(Canvas canvas, ChartRelief relief, {bool fine = false}) {
    final shadow = const Color(0xFF17151B);
    for (final m in fine ? relief.fineTerrain : relief.terrain) {
      if (!_vis(m.at)) continue;
      final colours = chartBiome(geography.zones[m.zone].biome);
      final p = _at(m.at);
      final s = m.size;
      switch (m.kind) {
        case TerrainKind.peak:
          _peak(canvas, p, s * 1.1, snow: m.snow, ember: m.ember);
        case TerrainKind.tree:
          // A crown lit from the north-west, over a short trunk.
          canvas.drawLine(
              p,
              p + Offset(0, s * 1.7),
              Paint()
                ..color = shadow.withValues(alpha: 0.8)
                ..strokeWidth = 0.3);
          canvas.drawCircle(p + Offset(s * 0.28, s * 0.22), s * 1.15,
              Paint()..color = shadow.withValues(alpha: 0.45));
          canvas.drawCircle(p, s * 1.15,
              Paint()..color = colours.detail.withValues(alpha: 0.9));
          canvas.drawCircle(p + Offset(-s * 0.3, -s * 0.3), s * 0.5,
              Paint()..color = colours.accent.withValues(alpha: 0.35));
        case TerrainKind.conifer:
          canvas.drawLine(
              p,
              p + Offset(0, s * 0.9),
              Paint()
                ..color = shadow.withValues(alpha: 0.8)
                ..strokeWidth = 0.3);
          final fir = Path()
            ..moveTo(p.dx, p.dy - s * 2.2)
            ..lineTo(p.dx + s * 0.75, p.dy)
            ..lineTo(p.dx - s * 0.75, p.dy)
            ..close();
          canvas.drawPath(fir, Paint()..color = colours.detail);
          canvas.drawPath(
              Path()
                ..moveTo(p.dx, p.dy - s * 2.2)
                ..lineTo(p.dx + s * 0.75, p.dy)
                ..lineTo(p.dx, p.dy)
                ..close(),
              Paint()..color = shadow.withValues(alpha: 0.4));
        case TerrainKind.hill:
          final hill = Path()
            ..moveTo(p.dx - s, p.dy)
            ..quadraticBezierTo(
                p.dx - s * 0.4, p.dy - s * 0.7, p.dx, p.dy - s * 0.62)
            ..quadraticBezierTo(
                p.dx + s * 0.5, p.dy - s * 0.55, p.dx + s, p.dy);
          canvas.drawPath(
              hill, Paint()..color = colours.detail.withValues(alpha: 0.28));
          canvas.drawPath(
              hill,
              Paint()
                ..color = palette.coast.withValues(alpha: 0.8)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.3);
          final hatch = Paint()
            ..color = shadow.withValues(alpha: 0.35)
            ..strokeWidth = 0.22;
          for (var i = 1; i <= 3; i++) {
            final x = p.dx + s * 0.2 * i;
            canvas.drawLine(Offset(x, p.dy - s * (0.62 - 0.14 * i)),
                Offset(x + s * 0.18, p.dy - 0.1), hatch);
          }
        case TerrainKind.rock:
          final rock = Path()
            ..moveTo(p.dx - s, p.dy + s * 0.4)
            ..lineTo(p.dx - s * 0.5, p.dy - s * 0.6)
            ..lineTo(p.dx + s * 0.3, p.dy - s * 0.8)
            ..lineTo(p.dx + s, p.dy + s * 0.1)
            ..lineTo(p.dx + s * 0.6, p.dy + s * 0.5)
            ..close();
          canvas.drawPath(
              rock, Paint()..color = Color.lerp(colours.detail, shadow, 0.35)!);
          canvas.drawPath(
              rock,
              Paint()
                ..color = palette.coast
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.22);
        case TerrainKind.lake:
          final rect =
              Rect.fromCenter(center: p, width: s * 2.4, height: s * 1.4);
          canvas.drawOval(rect, Paint()..color = palette.river);
          canvas.drawOval(
              rect,
              Paint()
                ..color = Color.lerp(palette.river, palette.coast, 0.5)!
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.3);
          canvas.drawPath(
              Path()
                ..moveTo(p.dx - s * 0.8, p.dy - s * 0.2)
                ..quadraticBezierTo(p.dx - s * 0.3, p.dy - s * 0.5,
                    p.dx + s * 0.2, p.dy - s * 0.3),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.25);
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
          canvas.drawPath(
              Path()
                ..moveTo(p.dx - w / 2, p.dy)
                ..quadraticBezierTo(p.dx - w / 4, p.dy - w / 4, p.dx, p.dy)
                ..close(),
              Paint()..color = shadow.withValues(alpha: 0.18));
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
          // Snow lying in drifts: three short strokes.
          final drift = Paint()
            ..color = const Color(0xFFF4F7FA).withValues(alpha: 0.55)
            ..strokeWidth = 0.22;
          for (var i = -1; i <= 1; i++) {
            canvas.drawLine(p + Offset(-s * 1.4, i * s * 0.9),
                p + Offset(s * 1.4 - i.abs() * s * 0.5, i * s * 0.9), drift);
          }
      }
    }
  }

  void _peak(Canvas canvas, Offset p, double s,
      {bool snow = false, bool ember = false}) {
    final top = Offset(p.dx, p.dy - s * 1.1);
    final left = Offset(p.dx - s, p.dy + s * 0.5);
    final right = Offset(p.dx + s, p.dy + s * 0.5);
    // The lit face, the shaded one, and the outline.
    canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(p.dx, right.dy)
          ..close(),
        Paint()..color = const Color(0xFFA39DAE).withValues(alpha: 0.22));
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
    // Hachures down the lit face.
    final hatch = Paint()
      ..color = const Color(0xFFA39DAE).withValues(alpha: 0.5)
      ..strokeWidth = 0.2;
    for (var i = 1; i <= 2; i++) {
      final t = i / 3;
      canvas.drawLine(Offset.lerp(top, left, t)!,
          Offset.lerp(top, left, t)! + Offset(s * 0.35, s * 0.25), hatch);
    }
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
    final t = _t, m = _m, lod = _lod;
    final taken = <Rect>[
      for (final l in reached)
        if (_vis(geography.of(l)))
          Rect.fromCircle(
              center: _at(geography.of(l)), radius: (l.big ? 4.5 : 3.5) * m),
      // The traveller and the pin over them, where the story stands.
      if (standing != null && !walking && _vis(geography.of(standing)))
        () {
          final (x, y) = spotOn(geography, standing);
          final p = _at(Offset(x, y));
          return Rect.fromLTRB(
              p.dx - 2.5 * m, p.dy - 12.5 * m, p.dx + 2.5 * m, p.dy + 0.5);
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
          fontSize: 6 * t,
          fontWeight: isHere ? FontWeight.w600 : FontWeight.w400,
          color: (isHere ? palette.mark : palette.place)
              .withValues(alpha: opacity),
          shadows: [
            Shadow(color: palette.land, blurRadius: 2 * t),
            Shadow(color: palette.land, blurRadius: 0.6 * t),
          ],
        ),
      );
      final w = painter.width, h = painter.height;
      final off = 5.5 * m, up = 4.5 * m;
      final right = Offset(p.dx + off, p.dy - h / 2);
      final left = Offset(p.dx - off - w, p.dy - h / 2);
      final above = Offset(p.dx - w / 2, p.dy - up - h);
      final below = Offset(p.dx - w / 2, p.dy + up);
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
                fontSize: 5 * t,
                letterSpacing: 1 * t,
                color: palette.label.withValues(alpha: 0.7),
              )
            : label.sea
                ? TextStyle(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    fontSize: 7 * t,
                    color: palette.label,
                  )
                : TextStyle(
                    fontFamily: InkFonts.display,
                    fontSize: 8 * t,
                    letterSpacing: 1.5 * t,
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
          fontSize: 5 * t,
          letterSpacing: 1.2 * t,
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
    // The small names show once the chart is looked at closer (v1.202).
    if (!detail || lod == 0) return;
    // The ranges' names, in italics along each.
    for (final range in geography.ranges) {
      if (!_vis(range.line[range.line.length ~/ 2])) continue;
      final mid = _at(range.line[range.line.length ~/ 2]);
      final painter = _layout(
        range.name(language),
        TextStyle(
          fontFamily: InkFonts.prose,
          fontStyle: FontStyle.italic,
          fontSize: 4.6 * t,
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
              fontSize: (seat ? 5.2 : 4.2) * t,
              color: colour.withValues(alpha: 0.9),
              shadows: [Shadow(color: palette.land, blurRadius: 1.5 * t)],
            )
          ),
        if (f.note(language).isNotEmpty && lod >= 2)
          (
            f.note(language),
            TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 3.2 * t,
              color: palette.label.withValues(alpha: 0.9),
            )
          ),
      ];
      var y = featureAt.dy + (f.landmark.isEmpty ? 3.6 : 8) * m;
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
    final m = _m, w = _w;
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

    // The towns about the places reached (v1.202): houses round each, a
    // wall round the big ones; the fog must not give the rest away.
    final roofDark = Color.lerp(palette.roofs, const Color(0xFF17151B), 0.4)!;
    for (final l in worldMapLandmarks) {
      if (l.atSea || !discovered.contains(l.id)) continue;
      if (!_vis(geography.of(l))) continue;
      final p = _at(geography.of(l));
      final rng = math.Random(chartSeed(l.id));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.scale((m * 1.3).clamp(0.5, 1.3));
      final n = l.big ? 8 : 4;
      if (l.big) {
        _dashedPath(
            canvas,
            Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 7.6)),
            Paint()
              ..color = palette.coast.withValues(alpha: 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.7,
            dash: 3,
            gap: 1.4);
      }
      for (var i = 0; i < n; i++) {
        final a = i * 2 * math.pi / n + rng.nextDouble() * 0.5;
        final r = (l.big ? 4.2 : 3.4) + rng.nextDouble() * 1.4;
        final o = Offset(math.cos(a) * r, math.sin(a) * r * 0.75 + 1);
        final size = 1.7 + rng.nextDouble() * 0.9;
        _house(canvas, o, size, size * 0.7, palette.roofs, roofDark);
      }
      canvas.restore();
    }

    // The shops and camps calque: a coin where a shop opens, a tent where
    // the party can rest.
    if (calque == ChartCalque.shops) {
      for (final l in worldMapLandmarks) {
        if (!discovered.contains(l.id)) continue;
        if (!_vis(geography.of(l))) continue;
        final p = _at(geography.of(l));
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.scale(m.clamp(0.35, 1.0));
        if (shopPlaces.contains(l.id)) {
          canvas.drawCircle(const Offset(5, -5), 2.4,
              Paint()..color = const Color(0xFFF2C14E));
          canvas.drawCircle(
              const Offset(5, -5),
              2.4,
              Paint()
                ..color = palette.land
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.6);
        }
        if (campPlaces.contains(l.id)) {
          canvas.drawPath(
              Path()
                ..moveTo(-8, -2)
                ..lineTo(-5, -7)
                ..lineTo(-2, -2)
                ..close(),
              Paint()..color = const Color(0xFF7DBE6A));
        }
        canvas.restore();
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
            width: 0.7 * w, cased: true, dash: 3 * w, gap: 2.2 * w);
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
    // A compass rose and a scale bar on the flat chart (v1.202), over the
    // fog: a chart has them before the story does.
    if (globe == null && detail) {
      _compass(canvas, const Offset(17, 18), 7.5);
      _scaleBar(canvas, const Offset(8, 167));
    }

    // The way on, dotted, to the next place the story goes.
    final next = ahead;
    final standing = here;
    if (next != null && standing != null) {
      final dots = Paint()
        ..color = palette.ahead
        ..strokeWidth = 0.9 * w
        ..strokeCap = StrokeCap.round;
      if (_vis(geography.of(standing)) && _vis(geography.of(next))) {
        _dashed(
            canvas, _at(geography.of(standing)), _at(geography.of(next)), dots,
            dash: 0.6 * w, gap: 3 * w);
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
          width: 0.9 * w,
          cased: !seaLeg,
          phase: -f * 1.3 * w,
          dash: (seaLeg ? 2.4 : 3) * w,
          gap: (seaLeg ? 1.8 : 2.2) * w);
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
            2.4 * m,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1 * m);
      } else {
        canvas.drawCircle(p, (l.big ? 3.6 : 2.6) * m, Paint()..color = color);
        canvas.drawCircle(
            p,
            (l.big ? 3.6 : 2.6) * m,
            Paint()
              ..color = const Color(0xFF17151B).withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.4 * m);
      }
      if (isHere) {
        canvas.drawCircle(
            p,
            4.6 * m,
            Paint()
              ..color = palette.mark
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * m);
      }
      if (l.id == selectedId && (reduceMotion || f % 4 < 3)) {
        canvas.drawCircle(
            p,
            6.8 * m,
            Paint()
              ..color = palette.place.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.6 * m);
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
      canvas.save();
      canvas.translate(shown.dx, shown.dy);
      canvas.scale(m.clamp(0.4, 1.0));
      const x = 0.0, y = 0.0;
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
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ChartMapPainter old) => true;
}
