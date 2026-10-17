// The path of one move between two Journey places on the real world chart
// (wave 14, docs/proposals/journey-world-data.md): the polyline the party
// walks or sails from landmark A to landmark B, in the chart's own
// coordinates (map_charts.dart: the storyChartProvider's chart, the one the
// full map draws), along the world's roads and sea lanes (world_roads.dart),
// with the stops it passes and what kind of move it is. UX animates the
// walk over the full map; this file only says where it goes.
import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../l10n/app_locale.dart';
import 'chart_relief.dart' show chartSeed, windingRoad;
import 'map_charts.dart';
import 'road_chart.dart' show ChartRouteStop;
import 'world_map.dart';
import 'world_roads.dart';

/// What kind of move a leg is.
enum WorldLegKind {
  /// Along land roads only.
  road,

  /// Along sea lanes only (a road of kind sea).
  sea,

  /// Both: a road to a harbour and a sea lane on, or (with no road) a
  /// straight line that leaves the land on the way.
  crossing,
}

/// One road of a leg: walked from landmark [from] to [to], [roadId] the
/// world_roads.dart id ('' on a fallback line), and the points of
/// [WorldLegPath.points] it covers, [start] to [end] (both included).
class WorldLegSegment {
  const WorldLegSegment(
      this.from, this.to, this.roadId, this.kind, this.start, this.end);
  final String from;
  final String to;
  final String roadId;
  final WorldLegKind kind;
  final int start;
  final int end;
}

/// The path from landmark [fromId] to [toId] on one chart.
class WorldLegPath {
  const WorldLegPath({
    required this.fromId,
    required this.toId,
    required this.points,
    required this.kind,
    required this.segments,
    required this.stops,
    required this.routed,
  });

  final String fromId;
  final String toId;

  /// The polyline, in the chart's coordinates, from A's spot to B's: the
  /// corners of each road as the full map draws it (windingRoad, before
  /// the painter smooths it), road after road.
  final List<Offset> points;
  final WorldLegKind kind;
  final List<WorldLegSegment> segments;

  /// The named stops passed (a bridge, a gate, a ford), where they lie on
  /// [points] and how far along (0 to 1).
  final List<ChartRouteStop> stops;

  /// Whether the path follows the roads; false for the fallback (no road
  /// joins A and B, or one is not a landmark): a straight line.
  final bool routed;

  /// The length of [points], in chart units.
  double get length {
    var d = 0.0;
    for (var i = 1; i < points.length; i++) {
      d += (points[i] - points[i - 1]).distance;
    }
    return d;
  }

  /// The point [t] of the way along (0 at A, 1 at B).
  Offset at(double t) => t <= 0
      ? points.first
      : t >= 1
          ? points.last
          : _pointAlong(points, t * length);
}

Offset _pointAlong(List<Offset> pts, double distance) {
  if (pts.isEmpty) return Offset.zero;
  var left = distance;
  for (var i = 1; i < pts.length; i++) {
    final step = (pts[i] - pts[i - 1]).distance;
    if (left <= step && step > 0) {
      return Offset.lerp(pts[i - 1], pts[i], left / step)!;
    }
    left -= step;
  }
  return pts.last;
}

Offset _spot(ChartGeography chart, String id) =>
    chart.places[id] ?? const Offset(worldMapWidth / 2, worldMapHeight / 2);

bool _onLand(ChartGeography chart, Offset p) =>
    chart.lands.any((land) => pointInPolygon(p, land));

/// The kind of a straight move from [a] to [b] by the lie of the land: at
/// sea when either end is a place at sea, a crossing when the line leaves
/// the land on the way, else a road.
WorldLegKind _kindByTerrain(
    ChartGeography chart, String fromId, String toId, Offset a, Offset b) {
  final atSea = [fromId, toId].any((id) => landmarkById(id)?.atSea ?? false);
  if (atSea) return WorldLegKind.sea;
  if (chart.lands.isEmpty) return WorldLegKind.road;
  for (var i = 1; i < 16; i++) {
    if (!_onLand(chart, Offset.lerp(a, b, i / 16)!)) {
      return WorldLegKind.crossing;
    }
  }
  return WorldLegKind.road;
}

/// The path from landmark [fromId] to [toId] (world_map.dart ids, as
/// landmarkOfScene gives them) on [chart], along the shortest way over the
/// world's roads (roadRoute). Each road is laid as the full map draws a leg
/// walked from its first landmark to its second: windingRoad with the seed
/// `chartSeed('from-to')`, three bends on land, two at sea. With no road
/// between them, a straight line, its kind by the terrain ([routed] false).
/// [language] names the stops.
WorldLegPath worldLegPath(
  ChartGeography chart,
  String fromId,
  String toId, {
  AppLanguage language = AppLanguage.en,
}) {
  final a = _spot(chart, fromId), b = _spot(chart, toId);
  final route = roadRoute(fromId, toId);
  if (fromId == toId || route == null || route.isEmpty) {
    final same = fromId == toId;
    final kind =
        same ? WorldLegKind.road : _kindByTerrain(chart, fromId, toId, a, b);
    return WorldLegPath(
      fromId: fromId,
      toId: toId,
      points: same ? [a] : [a, b],
      kind: kind,
      segments:
          same ? const [] : [WorldLegSegment(fromId, toId, '', kind, 0, 1)],
      stops: const [],
      routed: same,
    );
  }
  final points = <Offset>[];
  final segments = <WorldLegSegment>[];
  final named = <(int, int, int, String)>[]; // segment, k, n, name
  for (final leg in route.legs) {
    final sea = leg.road.kind == RoadKind.sea;
    final line = windingRoad(_spot(chart, leg.from), _spot(chart, leg.to),
        seed: chartSeed('${leg.from}-${leg.to}'),
        bends: sea ? 2 : 3,
        amp: sea ? 0.08 : 0.16);
    final start = points.isEmpty ? 0 : points.length - 1;
    points.addAll(points.isEmpty ? line : line.skip(1));
    segments.add(WorldLegSegment(leg.from, leg.to, leg.road.id,
        sea ? WorldLegKind.sea : WorldLegKind.road, start, points.length - 1));
    final stops = leg.stops;
    for (var k = 0; k < stops.length; k++) {
      named
          .add((segments.length - 1, k, stops.length, stops[k].name(language)));
    }
  }
  // Each stop spread evenly along its own road, as chartRouteFor does.
  final before = <double>[0];
  for (var i = 1; i < points.length; i++) {
    before.add(before.last + (points[i] - points[i - 1]).distance);
  }
  final total = math.max(before.last, 0.001);
  final stops = [
    for (final (s, k, n, name) in named)
      () {
        final seg = segments[s];
        final from = before[seg.start], to = before[seg.end];
        final d = from + (to - from) * (k + 1) / (n + 1);
        return ChartRouteStop(_pointAlong(points, d), name, d / total);
      }(),
  ];
  final kinds = {for (final s in segments) s.kind};
  return WorldLegPath(
    fromId: fromId,
    toId: toId,
    points: points,
    kind: kinds.length > 1 ? WorldLegKind.crossing : kinds.single,
    segments: segments,
    stops: stops,
    routed: true,
  );
}

/// The path of the move from scene [fromNodeId] to scene [toNodeId], by
/// their landmarks (landmarkOfScene); null when either has none or both
/// stand at the same landmark (no move on the world chart).
WorldLegPath? worldLegPathForScenes(
  ChartGeography chart,
  String fromNodeId,
  String toNodeId, {
  AppLanguage language = AppLanguage.en,
}) {
  final a = landmarkOfScene(fromNodeId), b = landmarkOfScene(toNodeId);
  if (a == null || b == null || a.id == b.id) return null;
  return worldLegPath(chart, a.id, b.id, language: language);
}
