// The chart as a sphere (v1.200): the 256 x 176 chart laid on a band of
// a globe (225 degrees of longitude, 140 of latitude, the rest open sea)
// or, for a chart that says so (ChartGeography.lonSpan and latSpan, board
// 11: the story world), on the whole of it; looked at straight on, turned
// to [lon0], [lat0] and [radius] units wide. Everything the chart painter draws goes through [clamp],
// [polygon] and [runs]; what lies on the far side is hidden, and a shape
// crossing the limb is pressed against it.
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'world_map.dart';

class GlobeView {
  const GlobeView({
    required this.lon0,
    required this.lat0,
    required this.radius,
    required this.centre,
    this.lonSpan = bandLonSpan,
    this.latSpan = bandLatSpan,
  });

  /// Where the globe looks: a longitude and latitude (radians).
  final double lon0;
  final double lat0;

  /// The globe's radius and centre, in the chart's units.
  final double radius;
  final Offset centre;

  /// The chart's width and height on the sphere: by default the band the
  /// first charts were drawn on ([bandLonSpan] by [bandLatSpan]); the whole
  /// sphere is 2 pi by pi.
  final double lonSpan;
  final double latSpan;

  static const double bandLonSpan = math.pi * 1.25;
  static const double bandLatSpan = math.pi * 0.78;

  /// The globe's radius at zoom 1: the whole of it fits a chart's width.
  static const double baseRadius = 80;

  /// A look at [p] (chart units) from straight above, at [zoom], on a
  /// chart spanning [lonSpan] by [latSpan] (the chart's own, see
  /// ChartGeography).
  factory GlobeView.at(Offset p, double zoom, Offset centre,
      {double lonSpan = bandLonSpan, double latSpan = bandLatSpan}) {
    final (lon, lat) = lonLatOf(p, lonSpan: lonSpan, latSpan: latSpan);
    return GlobeView(
        lon0: lon,
        lat0: lat,
        radius: baseRadius * zoom,
        centre: centre,
        lonSpan: lonSpan,
        latSpan: latSpan);
  }

  /// Whether the chart covers the whole sphere: a view can then turn right
  /// over a pole.
  bool get wholeSphere => latSpan >= math.pi - 1e-9;

  double get zoom => radius / baseRadius;

  String get key => '${lon0.toStringAsFixed(4)},${lat0.toStringAsFixed(4)},'
      '${radius.toStringAsFixed(2)},${centre.dx.toStringAsFixed(1)},'
      '${centre.dy.toStringAsFixed(1)}';

  GlobeView copyWith(
          {double? lon0, double? lat0, double? radius, Offset? centre}) =>
      GlobeView(
        lon0: lon0 ?? this.lon0,
        lat0: lat0 ?? this.lat0,
        radius: radius ?? this.radius,
        centre: centre ?? this.centre,
        lonSpan: lonSpan,
        latSpan: latSpan,
      );

  /// The highest latitude a view looks at: off the poles on a band chart;
  /// right over them on the whole sphere (the pole buttons, board 11).
  double get maxLat => wholeSphere ? math.pi / 2 : 1.45;

  /// Turned by [dlon], [dlat] radians, the latitude kept within [maxLat].
  GlobeView turned(double dlon, double dlat) => copyWith(
        lon0: lon0 + dlon,
        lat0: (lat0 + dlat).clamp(-maxLat, maxLat),
      );

  /// Turned to look straight down on the north pole ([north]) or the south
  /// one, at the same longitude and zoom.
  GlobeView toPole({required bool north}) =>
      copyWith(lat0: north ? maxLat : -maxLat);

  /// [p] on the chart as a longitude and latitude, on a chart spanning
  /// [lonSpan] by [latSpan] (the band by default).
  static (double, double) lonLatOf(Offset p,
          {double lonSpan = bandLonSpan, double latSpan = bandLatSpan}) =>
      (
        (p.dx / worldMapWidth - 0.5) * lonSpan,
        (0.5 - p.dy / worldMapHeight) * latSpan,
      );

  /// The chart point at [lon], [lat]; on the whole sphere a longitude past
  /// the seam comes round to the chart's other edge.
  static Offset chartOf(double lon, double lat,
      {double lonSpan = bandLonSpan, double latSpan = bandLatSpan}) {
    var l = lon;
    if (lonSpan >= 2 * math.pi - 1e-9) {
      l = (lon + math.pi) % (2 * math.pi) - math.pi;
    }
    return Offset(
      (l / lonSpan + 0.5) * worldMapWidth,
      (0.5 - lat / latSpan) * worldMapHeight,
    );
  }

  /// [p] on the unit sphere as seen from the view: x right, y up, z out
  /// of the screen (hidden when negative).
  (double, double, double) _xyz(Offset p) {
    final (lon, lat) = lonLatOf(p, lonSpan: lonSpan, latSpan: latSpan);
    final dl = lon - lon0;
    final cl = math.cos(lat), sl = math.sin(lat);
    final c0 = math.cos(lat0), s0 = math.sin(lat0);
    final x = cl * math.sin(dl);
    final y = c0 * sl - s0 * cl * math.cos(dl);
    final z = s0 * sl + c0 * cl * math.cos(dl);
    return (x, y, z);
  }

  bool visible(Offset p) => _xyz(p).$3 >= 0;

  /// Where [p] falls on the chart's canvas; a hidden point is pressed
  /// against the limb on its side.
  Offset clamp(Offset p) {
    var (x, y, z) = _xyz(p);
    if (z < 0) {
      final d = math.sqrt(x * x + y * y);
      if (d > 0) {
        x /= d;
        y /= d;
      } else {
        x = 1;
        y = 0;
      }
    }
    return Offset(centre.dx + x * radius, centre.dy - y * radius);
  }

  /// [pts] on the canvas, or null when none of them shows.
  List<Offset>? polygon(List<Offset> pts) {
    if (!pts.any(visible)) return null;
    return [for (final p in pts) clamp(p)];
  }

  /// The visible stretches of the line through [pts], each on the canvas.
  List<List<Offset>> runs(List<Offset> pts) {
    final out = <List<Offset>>[];
    var run = <Offset>[];
    for (final p in pts) {
      if (visible(p)) {
        run.add(clamp(p));
      } else if (run.isNotEmpty) {
        if (run.length >= 2) out.add(run);
        run = [];
      }
    }
    if (run.length >= 2) out.add(run);
    return out;
  }

  /// The chart point under [canvasPoint], or null off the globe.
  Offset? chartAt(Offset canvasPoint) {
    final dx = (canvasPoint.dx - centre.dx) / radius;
    final dy = -(canvasPoint.dy - centre.dy) / radius;
    final r2 = dx * dx + dy * dy;
    if (r2 > 1) return null;
    final z = math.sqrt(1 - r2);
    final c0 = math.cos(lat0), s0 = math.sin(lat0);
    final lat = math.asin((dy * c0 + z * s0).clamp(-1.0, 1.0));
    final lon = lon0 + math.atan2(dx, z * c0 - dy * s0);
    return chartOf(lon, lat, lonSpan: lonSpan, latSpan: latSpan);
  }

  /// The parallels and meridians, as chart lines to draw through [runs].
  static List<List<Offset>> graticule() {
    final lines = <List<Offset>>[];
    for (var lat = -60.0; lat <= 60; lat += 20) {
      lines.add([
        for (var lon = -112.0; lon <= 112; lon += 4)
          chartOf(lon * math.pi / 180, lat * math.pi / 180),
      ]);
    }
    for (var lon = -90.0; lon <= 90; lon += 30) {
      lines.add([
        for (var lat = -70.0; lat <= 70; lat += 4)
          chartOf(lon * math.pi / 180, lat * math.pi / 180),
      ]);
    }
    return lines;
  }
}
