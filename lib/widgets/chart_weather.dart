// The weather over the chart (v1.204, see climate.dart): clouds carried
// on the wind with their shadows on the land, rain slanting under them,
// snow over the cold lands, dust over the dry ones and ash over the
// burnt. The sky holds still (v1.210): the game plays turn by turn, so
// nothing drifts until the story's day turns, and zooming or turning the
// map shows the same clouds. Painted on its own layer over the chart, so
// the chart itself is not drawn again for every cloud.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/chart_globe.dart';
import '../data/climate.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';

/// The weather layer: a canvas the size of the chart (or of the globe's
/// box), painted once for the day's sky.
class ChartWeather extends StatefulWidget {
  const ChartWeather({
    super.key,
    required this.size,
    required this.geography,
    required this.palette,
    required this.day,
    this.globe,
    this.showOf,
  });

  final Size size;
  final ChartGeography geography;
  final ChartPalette palette;

  /// The story's day: the sky is the day's.
  final int day;

  /// The chart as a sphere, or flat.
  final GlobeView? globe;

  /// Whether the sky is drawn at all right now (v1.208): the Layers sheet
  /// can keep it to the world zoom.
  final bool Function()? showOf;

  @override
  State<ChartWeather> createState() => _ChartWeatherState();
}

class _ChartWeatherState extends State<ChartWeather>
    with SingleTickerProviderStateMixin {
  /// The sky fades in as the chart opens (v1.208), rather than popping.
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _fade,
        child: RepaintBoundary(
          child: CustomPaint(
            size: widget.size,
            painter: ChartWeatherPainter(
              geography: widget.geography,
              palette: widget.palette,
              day: widget.day,
              globe: widget.globe,
              showOf: widget.showOf,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the sky of one moment over the chart.
class ChartWeatherPainter extends CustomPainter {
  ChartWeatherPainter({
    required this.geography,
    required this.palette,
    required this.day,
    this.globe,
    this.showOf,
  });

  final ChartGeography geography;
  final ChartPalette palette;
  final int day;
  final GlobeView? globe;
  final bool Function()? showOf;

  /// The sky's time: the day's, fixed (see ChartClimate.timeOf).
  double get time => ChartClimate.timeOf(day);

  @override
  void paint(Canvas canvas, Size size) {
    if (showOf?.call() == false) return;
    final climate = ChartClimate.of(geography);
    final t = time;
    final k = size.width / worldMapWidth;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(k);
    final whole = globe == null
        ? ChartClimate.bounds
        : Rect.fromLTWH(0, 0, size.width / k, size.height / k);
    // The cells of sky: the same lattice however close the chart is
    // looked at (v1.210), so zooming never reshapes the clouds.
    final step = globe == null ? 3.2 : 4.4;
    final shown = ChartClimate.bounds;
    final g = globe;
    Offset at(Offset p) => g?.clamp(p) ?? p;
    bool vis(Offset p) => g?.visible(p) ?? true;
    // The sky's cells are worked out once for the day (again only when
    // the sphere turns).
    final cacheKey =
        '${identityHashCode(geography)}:$step:$t:${g?.key}:${size.width}';
    final List<(Offset, Offset, WeatherSample)> cells;
    if (_cellsKey == cacheKey) {
      cells = _cells;
    } else {
      cells = [];
      final i0 = (shown.left / step).floor(), i1 = (shown.right / step).ceil();
      final j0 = (shown.top / step).floor(), j1 = (shown.bottom / step).ceil();
      for (var j = j0; j <= j1; j++) {
        for (var i = i0; i <= i1; i++) {
          final p = Offset((i + 0.5) * step + _jitter(i, j) * step * 0.4,
              (j + 0.5) * step + _jitter(j, i) * step * 0.4);
          if (!ChartClimate.bounds.contains(p) || !vis(p)) continue;
          final q = at(p);
          if (g != null && !whole.inflate(step).contains(q)) continue;
          final w = climate.weather(p, t);
          if (w.cloud < 0.12 && w.kind != WeatherKind.fog) continue;
          cells.add((p, q, w));
        }
      }
      _cells = cells;
      _cellsKey = cacheKey;
    }
    if (cells.isEmpty) {
      canvas.restore();
      return;
    }
    // On the sphere, the cells near the limb lean away: they are scaled
    // by how much of the sky they show.
    double facing(Offset p) {
      if (g == null) return 1;
      final c = g.clamp(p);
      final r = (c - g.centre).distance / g.radius;
      return math.sqrt((1 - r * r).clamp(0.0, 1.0));
    }

    final dark = palette.fog;
    final pale = Color.lerp(palette.place, Colors.white, 0.35)!;
    final sigma = step * 0.55 * (g == null ? 1 : g.zoom.clamp(0.6, 2.0));

    // The cloud banks: the cover of every cell laid as a patch and the
    // patches blurred into one soft field, so the banks take the shape of
    // the sky's field rather than a scatter of discs; their shadow on the
    // land first, offset toward the lee.
    final sh = step * 1.05;
    canvas.saveLayer(
        whole,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    for (final (p, q, w) in cells) {
      if (w.cloud < 0.3) continue;
      final f = facing(p);
      canvas.drawRect(
          Rect.fromCenter(
              center: q + Offset(step * 0.3, step * 0.4) * f,
              width: sh * f,
              height: sh * f),
          Paint()
            ..color =
                dark.withValues(alpha: 0.14 * _smooth(0.3, 0.9, w.cloud)));
    }
    canvas.restore();
    canvas.saveLayer(
        whole,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    for (final (p, q, w) in cells) {
      final f = facing(p);
      final fog = w.kind == WeatherKind.fog;
      final cover = fog ? 0.55 : w.cloud;
      if (cover < 0.2) continue;
      final alpha = fog ? 0.16 : 0.04 + 0.2 * _smooth(0.2, 0.95, cover);
      canvas.drawRect(Rect.fromCenter(center: q, width: sh * f, height: sh * f),
          Paint()..color = pale.withValues(alpha: alpha));
    }
    canvas.restore();
    // The banks' edges drawn in ink, as a chart would pen them: the line
    // where the cover passes half, through the cells' corners.
    _cloudEdges(canvas, climate, t, step, shown, g, at, vis, facing);

    // What falls: rain slanting on the wind, snow drifting, dust and ash
    // streaming.
    final phase = t * ChartClimate.secondsADay;
    final rain = Paint()
      ..color = Color.lerp(palette.river, Colors.white, 0.45)!
      ..strokeCap = StrokeCap.round;
    final snow = Paint()..color = Colors.white;
    final dust = Paint()
      ..color = const Color(0xFFC9A46A)
      ..strokeCap = StrokeCap.round;
    final ash = Paint()..color = Color.lerp(palette.place, palette.fog, 0.3)!;
    for (final (p, q, w) in cells) {
      if (w.fall < 0.15) continue;
      final f = facing(p);
      if (f < 0.25) continue;
      final n = (2 + w.fall * 5).round();
      final wind = Offset(math.cos(w.windAngle), math.sin(w.windAngle));
      for (var m = 0; m < n; m++) {
        final h1 = _hashOf(p, m), h2 = _hashOf(p, m + 31);
        final o = Offset((h1 - 0.5) * step * 1.6, (h2 - 0.5) * step * 1.6) * f;
        switch (w.kind) {
          case WeatherKind.rain:
            final fall = (phase * (1.6 + h1) + h2) % 1.0;
            final a =
                q + o + Offset(wind.dx * 0.6, 1) * (fall - 0.5) * step * f;
            final slant = Offset(wind.dx * 0.25, 0.8) * (0.9 * f);
            canvas.drawLine(
                a,
                a + slant,
                rain
                  ..strokeWidth = 0.16 * (1 + w.fall)
                  ..color = rain.color.withValues(
                      alpha: 0.55 * w.fall * math.sin(math.pi * fall)));
          case WeatherKind.snow:
            final fall = (phase * (0.25 + h1 * 0.2) + h2) % 1.0;
            final sway = math.sin(phase * 0.8 + m) * 0.3;
            final a = q +
                o +
                Offset(sway + wind.dx * 0.2, (fall - 0.5) * step * 1.2) * f;
            canvas.drawCircle(
                a,
                0.22 * (1 + w.fall) * f,
                snow
                  ..color = Colors.white.withValues(
                      alpha: 0.7 * w.fall * math.sin(math.pi * fall)));
          case WeatherKind.dust:
            final run = (phase * (1.2 + h1) + h2) % 1.0;
            final a = q + o + wind * (run - 0.5) * step * 1.4 * f;
            canvas.drawLine(
                a,
                a + wind * (0.9 + w.fall) * f,
                dust
                  ..strokeWidth = 0.2
                  ..color = dust.color.withValues(
                      alpha: 0.5 * w.fall * math.sin(math.pi * run)));
          case WeatherKind.ash:
            final run = (phase * (0.5 + h1 * 0.4) + h2) % 1.0;
            final a = q + o + wind * (run - 0.5) * step * 1.1 * f;
            canvas.drawCircle(
                a,
                0.18 * f,
                ash
                  ..color = ash.color.withValues(
                      alpha: 0.6 * w.fall * math.sin(math.pi * run)));
          case WeatherKind.clear || WeatherKind.cloud || WeatherKind.fog:
            break;
        }
      }
    }
    canvas.restore();
  }

  /// The cells last worked out, for the frames between (see paint).
  static List<(Offset, Offset, WeatherSample)> _cells = const [];
  static String _cellsKey = '';

  /// The ink line round each cloud bank: marching squares over the sky's
  /// cells at half cover, each segment drawn with a slight waver.
  void _cloudEdges(
      Canvas canvas,
      ChartClimate climate,
      double t,
      double step,
      Rect shown,
      GlobeView? g,
      Offset Function(Offset) at,
      bool Function(Offset) vis,
      double Function(Offset) facing) {
    const level = 0.5;
    final i0 = (shown.left / step).floor(), i1 = (shown.right / step).ceil();
    final j0 = (shown.top / step).floor(), j1 = (shown.bottom / step).ceil();
    final cols = i1 - i0 + 2, rows = j1 - j0 + 2;
    final field = List<double>.filled(cols * rows, 0);
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final p = Offset((i0 + i) * step, (j0 + j) * step);
        if (!ChartClimate.bounds.contains(p)) continue;
        field[j * cols + i] = climate.cloudAt(p, t);
      }
    }
    final ink = Paint()
      ..color = Color.lerp(palette.place, palette.fog, 0.35)!
          .withValues(alpha: g == null ? 0.42 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (0.22 * math.sqrt(step)).clamp(0.25, 0.6);
    Offset corner(int i, int j) => Offset((i0 + i) * step, (j0 + j) * step);
    Offset lerp(Offset a, Offset b, double va, double vb) =>
        a + (b - a) * ((level - va) / (vb - va)).clamp(0.0, 1.0);
    void segment(Offset a, Offset b) {
      if (!vis(a) || !vis(b)) return;
      final pa = at(a), pb = at(b);
      // A waver on the pen, by the place, so the edge is never a straight
      // run of cells.
      final mid = (pa + pb) / 2;
      final d = pb - pa;
      final n =
          d.distance == 0 ? Offset.zero : Offset(-d.dy, d.dx) / d.distance;
      final waver = (_hashOf(a, 5) - 0.5) * step * 0.35 * facing(a);
      final path = Path()
        ..moveTo(pa.dx, pa.dy)
        ..quadraticBezierTo(
            mid.dx + n.dx * waver, mid.dy + n.dy * waver, pb.dx, pb.dy);
      canvas.drawPath(path, ink);
    }

    for (var j = 0; j + 1 < rows; j++) {
      for (var i = 0; i + 1 < cols; i++) {
        final v00 = field[j * cols + i], v10 = field[j * cols + i + 1];
        final v01 = field[(j + 1) * cols + i];
        final v11 = field[(j + 1) * cols + i + 1];
        final code = (v00 >= level ? 1 : 0) |
            (v10 >= level ? 2 : 0) |
            (v11 >= level ? 4 : 0) |
            (v01 >= level ? 8 : 0);
        if (code == 0 || code == 15) continue;
        final p00 = corner(i, j), p10 = corner(i + 1, j);
        final p01 = corner(i, j + 1), p11 = corner(i + 1, j + 1);
        final top = lerp(p00, p10, v00, v10);
        final right = lerp(p10, p11, v10, v11);
        final bottom = lerp(p01, p11, v01, v11);
        final left = lerp(p00, p01, v00, v01);
        switch (code) {
          case 1 || 14:
            segment(left, top);
          case 2 || 13:
            segment(top, right);
          case 3 || 12:
            segment(left, right);
          case 4 || 11:
            segment(right, bottom);
          case 5:
            segment(left, top);
            segment(right, bottom);
          case 6 || 9:
            segment(top, bottom);
          case 7 || 8:
            segment(left, bottom);
          case 10:
            segment(top, right);
            segment(left, bottom);
        }
      }
    }
  }

  static double _jitter(int i, int j) =>
      _hashOf(Offset(i * 1.0, j * 1.0), 7) - 0.5;

  static double _hashOf(Offset p, int m) {
    final x =
        math.sin(p.dx * 12.9898 + p.dy * 78.233 + m * 37.719) * 43758.5453;
    return x - x.floorToDouble();
  }

  static double _smooth(double lo, double hi, double x) {
    final t = ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  bool shouldRepaint(ChartWeatherPainter old) =>
      old.geography != geography ||
      old.palette != palette ||
      old.day != day ||
      old.globe?.key != globe?.key;
}
