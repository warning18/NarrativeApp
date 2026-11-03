// A route along the world's roads, laid on a chart (v1.254): the landmarks it
// passes and the named stops between them, in order, as points the Journey
// map walks the party along (see world_roads.dart for the roads themselves).
import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../l10n/app_locale.dart';
import 'map_charts.dart';
import 'world_map.dart';
import 'world_roads.dart';

/// A named stop on a [ChartRoute]: where it is, its name, and how far along
/// the route it lies (0 at the start, 1 at the end).
class ChartRouteStop {
  const ChartRouteStop(this.at, this.name, this.along);

  final Offset at;
  final String name;
  final double along;
}

/// The points of a route on one chart: each landmark passed and the stops
/// between them, in order, from the first landmark to the last.
class ChartRoute {
  const ChartRoute(this.points, this.stops);

  final List<Offset> points;
  final List<ChartRouteStop> stops;

  /// The stop passed last once the party has walked [walk] of the way
  /// (0 to 1), or null before the first one.
  ChartRouteStop? passed(double walk) {
    ChartRouteStop? last;
    for (final stop in stops) {
      if (stop.along <= walk) last = stop;
    }
    return last;
  }

  /// The corners of the route's bounding box.
  (Offset, Offset) get bounds {
    var minX = points.first.dx, maxX = minX;
    var minY = points.first.dy, maxY = minY;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return (Offset(minX, minY), Offset(maxX, maxY));
  }
}

/// [route] laid on [geography]: each landmark where the chart puts it, each
/// stop spread along the leg that holds it, a little to one side and the
/// other so the road bends instead of running ruler-straight.
ChartRoute? _chartRouteFor(
    ChartGeography geography, RoadRoute route, AppLanguage language) {
  if (route.isEmpty) return null;
  final points = <Offset>[];
  final named = <(Offset, String)>[];
  for (final leg in route.legs) {
    final a = landmarkById(leg.from);
    final b = landmarkById(leg.to);
    if (a == null || b == null) return null;
    final start = geography.of(a);
    final end = geography.of(b);
    if (points.isEmpty) points.add(start);
    final stops = leg.stops;
    final d = end - start;
    final side = Offset(-d.dy, d.dx) / math.max(d.distance, 1);
    for (var i = 0; i < stops.length; i++) {
      final f = (i + 1) / (stops.length + 1);
      final bend = (i.isEven ? 1 : -1) * d.distance * 0.06;
      final at = start + d * f + side * bend;
      points.add(at);
      named.add((at, stops[i].name(language)));
    }
    points.add(end);
  }
  final cumulative = <double>[0];
  for (var i = 1; i < points.length; i++) {
    cumulative.add(cumulative.last + (points[i] - points[i - 1]).distance);
  }
  final total = math.max(cumulative.last, 0.001);
  return ChartRoute(points, [
    for (final (at, name) in named)
      ChartRouteStop(at, name, cumulative[points.indexOf(at)] / total),
  ]);
}

/// The way along the roads from landmark [fromId] to [toId], laid on
/// [geography], or null when no road leads there.
ChartRoute? chartRoadsBetween(ChartGeography geography, String fromId,
    String toId, AppLanguage language) {
  final route = roadRoute(fromId, toId);
  return route == null ? null : _chartRouteFor(geography, route, language);
}
