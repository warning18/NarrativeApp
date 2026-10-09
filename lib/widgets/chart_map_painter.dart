import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/chart_globe.dart';
import '../data/chart_relief.dart';
import '../data/climate.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';

/// How the chart hides what the story has not reached.
enum ChartFog {
  /// A wash of night over it, cleared round each place read.
  wash,

  /// Uncharted: only a dotted coastline and the lands' names, as on a
  /// chart left unfinished (v1.199).
  uncharted,

  /// No fog: the whole world shown (v1.206), for a chart that has nothing
  /// left to find.
  none,
}

/// A calque laid over the chart (v1.199): the clans' zones of influence,
/// the player's standing in each land, the lands in their colours, the
/// road by chapter, or where to trade and rest; and the land's climate
/// (v1.204, see climate.dart): its heights with their contours, how wet
/// it is, how warm.
enum ChartCalque {
  none,
  clans,
  standing,
  lands,
  chapters,
  shops,
  height,
  humidity,
  warmth;

  /// A calque of the climate: tints over every land, with a legend.
  bool get climate => this == height || this == humidity || this == warmth;
}

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
    this.fogOf,
    Listenable? view,
  }) : super(
            repaint: Listenable.merge(
                [frame, walk, _ready, if (view != null) view]));

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
  /// How much of the fog is laid yet (v1.208): it fades in as the chart
  /// opens from the streets. Null reads as all of it.
  final double Function()? fogOf;

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

  /// The climate calque on the flat chart, recorded once per calque and
  /// look.
  static final Map<String, ui.Picture> _climatePictures = {};
  ui.Picture _climateFor() {
    final key =
        '${identityHashCode(geography)}:${calque.name}:${palette.hashCode}';
    return _climatePictures[key] ??= () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintClimate(canvas);
      return recorder.endRecording();
    }();
  }

  /// The colour of the [calque] at [value]: height from the low green
  /// through ochre and brown to the white of the peaks; moisture from dry
  /// ochre to a wet blue-green; warmth from the blue of the frost to the
  /// red of the hottest noon.
  static Color climateTint(ChartCalque calque, double value) {
    List<(double, Color)> stops = switch (calque) {
      ChartCalque.height => const [
          (0.0, Color(0xFF3F7A4E)),
          (0.18, Color(0xFF7FA05A)),
          (0.38, Color(0xFFC9B46A)),
          (0.6, Color(0xFFB07A48)),
          (0.8, Color(0xFF8A6652)),
          (1.0, Color(0xFFF2F2F2)),
        ],
      ChartCalque.humidity => const [
          (0.0, Color(0xFFCB9A55)),
          (0.3, Color(0xFFB7B46E)),
          (0.55, Color(0xFF7FA66A)),
          (0.8, Color(0xFF4E8F8E)),
          (1.0, Color(0xFF3A6FA8)),
        ],
      _ => const [
          (0.0, Color(0xFF5B7FD9)),
          (0.3, Color(0xFF9FC4E6)),
          (0.5, Color(0xFFE6E0B4)),
          (0.72, Color(0xFFE59A4A)),
          (1.0, Color(0xFFBF3A2B)),
        ],
    };
    final v = value.clamp(0.0, 1.0);
    for (var i = 0; i + 1 < stops.length; i++) {
      final (a, ca) = stops[i];
      final (b, cb) = stops[i + 1];
      if (v <= b) return Color.lerp(ca, cb, (v - a) / (b - a))!;
    }
    return stops.last.$2;
  }

  /// Warmth on the legend's scale: -15 degrees is 0, 30 is 1.
  static double warmthScale(double degrees) =>
      ((degrees + 15) / 45).clamp(0.0, 1.0);

  void _paintClimate(Canvas canvas) {
    final climate = ChartClimate.of(geography);
    final g = globe;
    // The sphere is painted afresh on every turn: coarser cells.
    final step = g == null ? ChartClimate.cell : ChartClimate.cell * 2;
    // Cells butt against each other with no seam: no anti-aliasing.
    final paint = Paint()..isAntiAlias = false;
    final alpha = palette == ChartPalette.of(MapLook.parchment) ? 0.5 : 0.55;
    for (var y = step / 2; y < worldMapHeight; y += step) {
      for (var x = step / 2; x < worldMapWidth; x += step) {
        final p = Offset(x, y);
        if (!climate.isLand(p)) continue;
        if (g != null && !g.visible(p)) continue;
        final value = switch (calque) {
          ChartCalque.height => climate.elevationAt(p),
          ChartCalque.humidity => climate.humidityAt(p),
          _ => warmthScale(climate.temperatureAt(p)),
        };
        paint.color = climateTint(calque, value).withValues(alpha: alpha);
        if (g == null) {
          canvas.drawRect(
              Rect.fromCenter(center: p, width: step, height: step), paint);
        } else {
          final q = g.clamp(p);
          final r = (q - g.centre).distance / g.radius;
          final facing = math.sqrt((1 - r * r).clamp(0.0, 1.0));
          canvas.drawCircle(
              q, step * 0.7 * g.zoom.clamp(0.5, 2.0) * facing, paint);
        }
      }
    }
    // Contours: of height on the height calque, of moisture on its own.
    if (calque == ChartCalque.warmth) return;
    final humid = calque == ChartCalque.humidity;
    final levels =
        humid ? const [0.35, 0.55, 0.75] : const [0.2, 0.35, 0.5, 0.65, 0.8];
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = (humid ? palette.river : palette.coast).withValues(alpha: 0.9);
    for (var i = 0; i < levels.length; i++) {
      line.strokeWidth = i.isOdd ? 0.3 : 0.45;
      for (final run in climate.contours(levels[i], humidity: humid)) {
        if (g == null) {
          canvas.drawPath(_smooth(run, closed: false), line);
        } else {
          for (final shown in g.runs(run)) {
            canvas.drawPath(_smooth(shown, closed: false), line);
          }
        }
      }
    }
  }

  /// A strip of the calque's colours with its ends named, bottom right.
  void _climateLegend(Canvas canvas, Rect whole) {
    const w = 52.0, h = 3.6;
    final o = Offset(whole.right - w - 8, whole.bottom - 11);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(o.dx - 3, o.dy - 3, w + 6, h + 11),
            const Radius.circular(1.5)),
        Paint()..color = palette.fog.withValues(alpha: 0.75));
    for (var i = 0; i < 26; i++) {
      canvas.drawRect(Rect.fromLTWH(o.dx + i * w / 26, o.dy, w / 26 + 0.2, h),
          Paint()..color = climateTint(calque, i / 25));
    }
    final (low, high) = switch (calque) {
      ChartCalque.humidity => ('chart_legend_dry', 'chart_legend_wet'),
      ChartCalque.warmth => ('chart_legend_cold', 'chart_legend_warm'),
      _ => ('chart_legend_low', 'chart_legend_high'),
    };
    final style = TextStyle(
        fontFamily: InkFonts.prose, fontSize: 3.6, color: palette.place);
    final a = TextPainter(
        text: TextSpan(text: trFor(language, low), style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    a.paint(canvas, Offset(o.dx, o.dy + h + 0.6));
    final b = TextPainter(
        text: TextSpan(text: trFor(language, high), style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    b.paint(canvas, Offset(o.dx + w - b.width, o.dy + h + 0.6));
  }

  /// The light on the land: from the north-west, high.
  static const double _lightX = -0.57, _lightY = -0.57, _lightZ = 0.59;

  /// How much higher the heights are drawn than they are wide, for the
  /// shading to show them.
  static const double _reliefExaggeration = 18;

  /// Ticks when a skin or a shading rendered in the background is ready,
  /// so every chart painting repaints with it (never disposed, unlike a
  /// map's own frame).
  static final ValueNotifier<int> _ready = ValueNotifier(0);

  /// The shaded relief as an image over the whole chart, per geography:
  /// made once, in the background, and kept; drawn smooth at any zoom.
  static final Map<ChartGeography, ui.Image> _shades = {};
  static final Set<ChartGeography> _shadesPending = {};

  /// Pixels per chart unit in the shading.
  static const double _shadePx = 2;

  ui.Image? _shadeImage() {
    final made = _shades[geography];
    if (made != null) return made;
    if (_shadesPending.add(geography)) {
      prepareShade().then((_) => _ready.value++);
    }
    return null;
  }

  /// Renders the shaded relief for this chart and keeps it; done once per
  /// chart. Tests and screenshots await it before painting.
  Future<ui.Image> prepareShade() async {
    final made = _shades[geography];
    if (made != null) return made;
    _shadesPending.add(geography);
    final image = await _renderShade(geography);
    _shades[geography] = image;
    _shadesPending.remove(geography);
    return image;
  }

  /// Each pixel's slope against the light: the lit side white, the far
  /// side black, both faint; the sea and the flat left clear.
  static Future<ui.Image> _renderShade(ChartGeography geography) {
    final climate = ChartClimate.of(geography);
    final w = (worldMapWidth * _shadePx).round();
    final h = (worldMapHeight * _shadePx).round();
    final pixels = Uint8List(w * h * 4);
    double height(Offset p) {
      final e = climate.elevationAt(p);
      if (e <= 0) return 0;
      // A fine grain on the slopes, so the shading has texture.
      return e + 0.04 * (fbm(p, 5, 2, 77) - 0.5) * math.min(1, e * 8);
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = Offset((x + 0.5) / _shadePx, (y + 0.5) / _shadePx);
        if (!climate.isLand(p)) continue;
        final gx = (height(p + const Offset(0.7, 0)) -
                height(p - const Offset(0.7, 0))) /
            1.4 *
            _reliefExaggeration;
        final gy = (height(p + const Offset(0, 0.7)) -
                height(p - const Offset(0, 0.7))) /
            1.4 *
            _reliefExaggeration;
        final len = math.sqrt(gx * gx + gy * gy + 1);
        final lit = (-gx * _lightX - gy * _lightY + _lightZ) / len;
        final delta = lit - _lightZ;
        if (delta.abs() < 0.01) continue;
        final k = (y * w + x) * 4;
        // The engine reads the pixels premultiplied: a white at part
        // alpha is written as that alpha in every channel.
        if (delta < 0) {
          pixels[k + 3] = (math.min(0.42, -delta * 0.9) * 255).round();
        } else {
          final a = (math.min(0.24, delta * 0.5) * 255).round();
          pixels[k] = a;
          pixels[k + 1] = a;
          pixels[k + 2] = a;
          pixels[k + 3] = a;
        }
      }
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  // ------------------------------------------------------------ sphere

  /// The flat chart rendered as an image, per look and detail, to wrap
  /// the sphere in; made once, in the background, and kept.
  static final Map<String, ui.Image> _skins = {};
  static final Set<String> _skinsPending = {};

  /// Pixels per chart unit in the skin, by detail.
  static double _skinScale(int lod) => lod >= 2 ? 6 : (lod == 1 ? 4 : 3);

  String _skinKey(ChartRelief relief) =>
      '${identityHashCode(relief)}:${palette.hashCode}:$detail:${calque == ChartCalque.lands}:$_lod';

  /// A twin of this painter looking at the chart flat, at this zoom.
  ChartMapPainter _flatTwin() {
    final zoom = _zoom;
    return ChartMapPainter(
      frame: frame,
      walk: walk,
      geography: geography,
      palette: palette,
      language: language,
      discovered: discovered,
      legs: legs,
      ahead: ahead,
      selectedId: selectedId,
      here: here,
      walking: walking,
      walkPath: walkPath,
      chapterFilter: chapterFilter,
      reduceMotion: reduceMotion,
      chapterColor: chapterColor,
      fog: fog,
      calque: calque,
      clanColours: clanColours,
      standingOf: standingOf,
      shopPlaces: shopPlaces,
      campPlaces: campPlaces,
      detail: detail,
      zoomOf: () => zoom,
    ).._whole =
        const Rect.fromLTWH(0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0);
  }

  /// The sphere's skin, or null while it is still being made (the first
  /// look at the sphere, and the first at each level of detail).
  ui.Image? _globeSkin(ChartRelief relief) {
    final key = _skinKey(relief);
    final made = _skins[key];
    if (made != null) return made;
    if (_skinsPending.add(key)) {
      prepareSkin().then((_) => _ready.value++);
    }
    return null;
  }

  /// Renders the flat chart into the sphere's skin for this look and
  /// detail, and keeps it; done once per key. Tests and screenshots await
  /// it before painting the sphere.
  Future<ui.Image> prepareSkin() async {
    final relief = ChartRelief.of(geography);
    final key = _skinKey(relief);
    final made = _skins[key];
    if (made != null) return made;
    _skinsPending.add(key);
    // The shaded relief goes into the skin, so it is rendered first.
    await prepareShade();
    final s = _skinScale(_lod);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(s);
    _flatTwin()._paintGround(canvas, relief);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
        (worldMapWidth * s).round(), (worldMapHeight * s).round());
    picture.dispose();
    _skins[key] = image;
    _skinsPending.remove(key);
    return image;
  }

  /// How far the heights lift the sphere's surface, as a share of its
  /// radius at the highest peak: enough to show on the limb.
  static const double _reliefLift = 0.014;

  /// The sphere with the chart wrapped on it: the sky, the open sea, a
  /// mesh over the chart's rectangle textured with its skin (each vertex
  /// lifted by its height), then the parallels and meridians.
  void _paintGlobeSkinned(Canvas canvas, GlobeView g, ui.Image skin) {
    canvas.drawRect(_whole, Paint()..color = palette.fog);
    canvas.drawCircle(g.centre, g.radius, Paint()..color = palette.sea);
    final climate = ChartClimate.of(geography);
    final s = skin.width / worldMapWidth;
    const step = 3.0;
    final cols = (worldMapWidth / step).ceil() + 1;
    final rows = (worldMapHeight / step).ceil() + 1;
    final positions = Float32List(cols * rows * 2);
    final texture = Float32List(cols * rows * 2);
    final shown = List<bool>.filled(cols * rows, false);
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final p = Offset(math.min(i * step, worldMapWidth * 1.0),
            math.min(j * step, worldMapHeight * 1.0));
        final k = j * cols + i;
        texture[k * 2] = p.dx * s;
        texture[k * 2 + 1] = p.dy * s;
        if (!g.visible(p)) continue;
        shown[k] = true;
        var q = g.clamp(p);
        final lift = climate.elevationAt(p) * _reliefLift;
        if (lift > 0) q = g.centre + (q - g.centre) * (1 + lift);
        positions[k * 2] = q.dx;
        positions[k * 2 + 1] = q.dy;
      }
    }
    final indices = <int>[];
    for (var j = 0; j + 1 < rows; j++) {
      for (var i = 0; i + 1 < cols; i++) {
        final a = j * cols + i, b = a + 1, c = a + cols, d = c + 1;
        if (!shown[a] || !shown[b] || !shown[c] || !shown[d]) continue;
        indices
          ..add(a)
          ..add(b)
          ..add(c)
          ..add(b)
          ..add(d)
          ..add(c);
      }
    }
    if (indices.isNotEmpty) {
      final vertices = ui.Vertices.raw(ui.VertexMode.triangles, positions,
          textureCoordinates: texture, indices: Uint16List.fromList(indices));
      canvas.drawVertices(
          vertices,
          BlendMode.srcOver,
          Paint()
            ..shader = ui.ImageShader(skin, TileMode.clamp, TileMode.clamp,
                Matrix4.identity().storage,
                filterQuality: FilterQuality.medium));
    }
    final grid = Paint()
      ..color = palette.seaLine.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;
    for (final line in GlobeView.graticule()) {
      canvas.drawPath(_line(line), grid);
    }
  }

  /// The light on the sphere (v1.206): the limb darkened away from the
  /// light in the upper left, a soft highlight toward it, a thin pale air
  /// round the edge, and the limb drawn.
  void _globeLight(Canvas canvas, GlobeView g) {
    final c = g.centre, r = g.radius;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-r * 0.35, -r * 0.35),
            r * 1.42,
            [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.6),
            ],
            const [0, 0.45, 0.8, 1],
          ));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            c + Offset(-r * 0.45, -r * 0.45),
            r * 0.9,
            [Colors.white.withValues(alpha: 0.07), Colors.transparent],
          ));
    final air = Color.lerp(palette.place, palette.sea, 0.5)!;
    canvas.drawCircle(
        c,
        r * 1.04,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            r * 1.04,
            [
              Colors.transparent,
              Colors.transparent,
              air.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            const [0, 0.95, 0.965, 1],
          ));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = palette.coast.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
  }

  /// The static layers of [relief] in this look, recorded once.
  ui.Picture _groundFor(ChartRelief relief) {
    final key =
        '${identityHashCode(relief)}:${palette.hashCode}:$detail:${calque == ChartCalque.lands}:${globe?.key}:$_lod:${_shades.containsKey(geography)}';
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
    // The relief shaded (v1.206): the land lit from the north-west,
    // its slopes toward the light paler, those away darker, grey on grey.
    if (detail && globe == null) {
      final shade = _shadeImage();
      if (shade != null) {
        canvas.drawImageRect(
            shade,
            Rect.fromLTWH(
                0, 0, shade.width.toDouble(), shade.height.toDouble()),
            const Rect.fromLTWH(
                0, 0, worldMapWidth * 1.0, worldMapHeight * 1.0),
            Paint()..filterQuality = FilterQuality.medium);
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
      // The sphere wears the flat chart as its skin (v1.206), at the
      // chart's own detail, once that skin is rendered; until then it is
      // painted coarse, as before.
      final skin = _globeSkin(relief);
      if (skin != null) {
        _paintGlobeSkinned(canvas, globe!, skin);
      } else {
        _paintGround(canvas, relief);
      }
      _globeLight(canvas, globe!);
    }
    // The climate calques (v1.204), under the fog like the ground.
    if (calque.climate) {
      if (globe == null) {
        canvas.drawPicture(_climateFor());
      } else {
        _paintClimate(canvas);
      }
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

    // Fog over what the story has not reached (none on a chart with
    // nothing left to find, v1.206).
    if (fog != ChartFog.none) {
      canvas.saveLayer(whole, Paint());
      final fogPaint = Paint()
        ..color = palette.fog.withValues(
            alpha: (fog == ChartFog.uncharted ? 0.94 : 0.9) *
                (fogOf?.call() ?? 1).clamp(0.0, 1.0));
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
      // What the story has reached shows through (v1.208): each land a
      // place was read in, whole, its torn edge softened; the roads
      // walked as corridors; and a small clearing round a place read
      // outside any land (at sea), where before every place cleared one
      // disc of the same size.
      final clear = Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.black
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      for (final i in reachedZones) {
        canvas.drawPath(_poly(relief.zones[i]), clear);
      }
      final corridor = Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (final (a, b) in legs) {
        if (!discovered.contains(a.id) || !discovered.contains(b.id)) {
          continue;
        }
        final from = geography.of(a), to = geography.of(b);
        final seaLeg =
            a.atSea || b.atSea || (a.id == 'shore' && b.id == 'candlehold');
        canvas.drawPath(
            _line(windingRoad(from, to,
                seed: chartSeed('${a.id}-${b.id}'),
                bends: seaLeg ? 2 : 3,
                amp: seaLeg ? 0.08 : 0.16)),
            corridor);
      }
      for (final l in worldMapLandmarks) {
        if (!discovered.contains(l.id)) continue;
        final at = geography.of(l);
        if (!_vis(at)) continue;
        final inLand = reachedZones
            .any((i) => pointInPolygon(at, geography.zones[i].polygon));
        final p = _at(at);
        final r = inLand ? 10.0 : 18.0;
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..blendMode = BlendMode.dstOut
            ..shader = RadialGradient(
              colors: const [Colors.black, Colors.black, Colors.transparent],
              stops: const [0, 0.5, 1],
            ).createShader(Rect.fromCircle(center: p, radius: r)),
        );
      }
      canvas.restore();
    }
    // A compass rose and a scale bar on the flat chart (v1.202), over the
    // fog: a chart has them before the story does.
    if (globe == null && detail) {
      _compass(canvas, const Offset(17, 18), 7.5);
      _scaleBar(canvas, const Offset(8, 167));
    }
    if (calque.climate && detail) _climateLegend(canvas, whole);

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
