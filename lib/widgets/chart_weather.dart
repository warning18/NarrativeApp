// The weather over the chart (v1.204, see climate.dart): clouds carried
// on the wind with their shadows on the land, rain slanting under them,
// snow over the cold lands, dust over the dry ones and ash over the
// burnt, all moving while the map is watched. Painted on its own layer
// over the chart, so the chart itself is not drawn again for every
// cloud.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/chart_globe.dart';
import '../data/climate.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';

/// The weather layer: a canvas the size of the chart (or of the globe's
/// box), ticking on its own clock.
class ChartWeather extends StatefulWidget {
  const ChartWeather({
    super.key,
    required this.size,
    required this.geography,
    required this.palette,
    required this.day,
    this.globe,
    this.zoomOf,
    this.visibleOf,
    this.still = false,
  });

  final Size size;
  final ChartGeography geography;
  final ChartPalette palette;

  /// The story's day: the sky's time runs from it.
  final int day;

  /// The chart as a sphere, or flat.
  final GlobeView? globe;

  /// How close the chart is looked at (1 = the whole of it in the box).
  final double Function()? zoomOf;

  /// The part of the chart in view (chart units), to paint only that.
  final Rect Function()? visibleOf;

  /// No motion: one still sky.
  final bool still;

  @override
  State<ChartWeather> createState() => _ChartWeatherState();
}

class _ChartWeatherState extends State<ChartWeather>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMilliseconds / 1000;
    });
    if (!widget.still) _ticker.start();
  }

  @override
  void didUpdateWidget(ChartWeather old) {
    super.didUpdateWidget(old);
    if (old.still != widget.still) {
      if (widget.still) {
        _ticker.stop();
      } else {
        _ticker.start();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: widget.size,
          painter: ChartWeatherPainter(
            clock: _clock,
            geography: widget.geography,
            palette: widget.palette,
            day: widget.day,
            globe: widget.globe,
            zoomOf: widget.zoomOf,
            visibleOf: widget.visibleOf,
          ),
        ),
      ),
    );
  }
}

/// Paints the sky of one moment over the chart.
class ChartWeatherPainter extends CustomPainter {
  ChartWeatherPainter({
    required this.clock,
    required this.geography,
    required this.palette,
    required this.day,
    this.globe,
    this.zoomOf,
    this.visibleOf,
  }) : super(repaint: clock);

  final ValueNotifier<double> clock;
  final ChartGeography geography;
  final ChartPalette palette;
  final int day;
  final GlobeView? globe;
  final double Function()? zoomOf;
  final Rect Function()? visibleOf;

  /// The sky's time: the story's day, and the seconds this layer has
  /// been watched (the app's clock, so every map agrees).
  double get time => ChartClimate.timeOf(day);

  @override
  void paint(Canvas canvas, Size size) {
    final climate = ChartClimate.of(geography);
    final t = time;
    final zoom = (zoomOf?.call() ?? 1).clamp(1.0, 12.0);
    final k = size.width / worldMapWidth;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(k);
    final whole = globe == null
        ? ChartClimate.bounds
        : Rect.fromLTWH(0, 0, size.width / k, size.height / k);
    // The cells of sky: closer in, finer, over the part in view only.
    final step = (5.2 / math.sqrt(zoom)).clamp(2.0, 5.2);
    final shown = globe == null
        ? (visibleOf?.call() ?? ChartClimate.bounds)
            .inflate(step * 2)
            .intersect(ChartClimate.bounds)
        : ChartClimate.bounds;
    final g = globe;
    Offset at(Offset p) => g?.clamp(p) ?? p;
    bool vis(Offset p) => g?.visible(p) ?? true;
    // The sky's cells are worked out a few times a second, not every
    // frame: the clouds move slowly, only what falls needs each frame.
    final cacheKey =
        '${identityHashCode(geography)}:$step:$shown:${g?.key}:${size.width}';
    final List<(Offset, Offset, WeatherSample)> cells;
    if (_cellsKey == cacheKey &&
        (t - _cellsAt).abs() * ChartClimate.secondsADay < 0.25) {
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
      _cellsAt = t;
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

    // The clouds' shadows on the land, blurred together.
    canvas.saveLayer(
        whole,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    for (final (p, q, w) in cells) {
      if (w.cloud < 0.3) continue;
      final f = facing(p);
      final r = step * (0.4 + w.cloud * 0.45) * f;
      canvas.drawCircle(
          q + Offset(step * 0.3, step * 0.4) * f,
          r,
          Paint()
            ..color =
                dark.withValues(alpha: 0.16 * _smooth(0.3, 0.9, w.cloud)));
    }
    canvas.restore();

    // The clouds themselves.
    canvas.saveLayer(
        whole,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    for (final (p, q, w) in cells) {
      final f = facing(p);
      final fog = w.kind == WeatherKind.fog;
      final cover = fog ? 0.55 : w.cloud;
      if (cover < 0.2) continue;
      final r = step * (0.4 + cover * 0.5) * f;
      final alpha = fog ? 0.2 : 0.06 + 0.24 * _smooth(0.2, 0.95, cover);
      canvas.drawCircle(q, r, Paint()..color = pale.withValues(alpha: alpha));
      if (cover > 0.7 && !fog) {
        // A thicker heart to the heavy cloud.
        canvas.drawCircle(q + Offset(-step * 0.2, -step * 0.15) * f, r * 0.5,
            Paint()..color = pale.withValues(alpha: 0.18));
      }
    }
    canvas.restore();

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
  static double _cellsAt = -1;

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
      old.globe?.key != globe?.key ||
      old.zoomOf != zoomOf;
}
