// The chart's relief (v1.199): coasts broken into bays and headlands, roads
// that bend with the ground, and the terrain of each biome land (ridges,
// woods, lakes, dunes, marsh, cinder cones, glass), all drawn from fixed
// seeds so the world is the same on every opening. Everything here is in
// the chart's own units (worldMapWidth x worldMapHeight).
import 'dart:math' as math;
import 'dart:ui' show Color, Offset;

import 'map_charts.dart';

/// Each edge of [points] split at its middle, the middle pushed sideways
/// by a seeded amount that shrinks by [depth] levels: a coast with
/// headlands and bays, a river with bends.
List<Offset> fractalLine(List<Offset> points,
    {int depth = 4, double rough = 0.14, int seed = 1, bool closed = true}) {
  final rng = math.Random(seed);
  var pts = List<Offset>.from(points);
  for (var level = 0; level < depth; level++) {
    final out = <Offset>[];
    final n = pts.length;
    final edges = closed ? n : n - 1;
    for (var i = 0; i < edges; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      out.add(a);
      final d = b - a;
      final length = d.distance;
      if (length < 1.5) continue;
      final k =
          (rng.nextDouble() - 0.5) * 2 * rough * length / math.pow(1.6, level);
      out.add(Offset(a.dx + d.dx / 2 - d.dy / length * k,
          a.dy + d.dy / 2 + d.dx / length * k));
    }
    if (!closed) out.add(pts.last);
    pts = out;
  }
  return pts;
}

/// A road from [a] to [b] that bends [bends] times on the way, as a road
/// that follows the ground does.
List<Offset> windingRoad(Offset a, Offset b,
    {int seed = 1, int bends = 3, double amp = 0.16}) {
  final rng = math.Random(seed);
  final d = b - a;
  final length = d.distance;
  if (length == 0) return [a, b];
  final n = Offset(-d.dy / length, d.dx / length);
  final pts = [a];
  for (var i = 1; i <= bends; i++) {
    final t = i / (bends + 1) + (rng.nextDouble() - 0.5) * 0.12;
    final k = (rng.nextDouble() - 0.5) * 2 * amp * length;
    pts.add(a + d * t + n * k);
  }
  pts.add(b);
  return pts;
}

/// A seed from [text] that is the same on every run.
int chartSeed(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// A biome's colours for the chart, as biomes.json gives them (the chart
/// has no database at hand): ground, detail and accent.
class ChartBiomeColours {
  const ChartBiomeColours(this.ground, this.detail, this.accent);
  final Color ground;
  final Color detail;
  final Color accent;
}

const Map<String, ChartBiomeColours> chartBiomeColours = {
  'temperate': ChartBiomeColours(
      Color(0xFF7E9A5A), Color(0xFF56703C), Color(0xFFC9D7A0)),
  'desert': ChartBiomeColours(
      Color(0xFFC9A86A), Color(0xFF9C7B45), Color(0xFFE8D7A8)),
  'arid_coast': ChartBiomeColours(
      Color(0xFFD2BE94), Color(0xFFA3865A), Color(0xFFF1EBDD)),
  'sea': ChartBiomeColours(
      Color(0xFF2F5D7C), Color(0xFF1E3F57), Color(0xFFCFE3EE)),
  'ashlands': ChartBiomeColours(
      Color(0xFF8C877E), Color(0xFF5F5B55), Color(0xFFD8D3C8)),
  'volcanic': ChartBiomeColours(
      Color(0xFFA0523D), Color(0xFF6E3527), Color(0xFFE9B48A)),
  'sea_cliffs': ChartBiomeColours(
      Color(0xFF7D8C7A), Color(0xFF4E5B52), Color(0xFFD9DDD2)),
  'fen': ChartBiomeColours(
      Color(0xFF5E6B57), Color(0xFF3B4538), Color(0xFFA9B59A)),
  'frost': ChartBiomeColours(
      Color(0xFFD7DEE6), Color(0xFF9AA7B4), Color(0xFFF4F7FA)),
  'tear': ChartBiomeColours(
      Color(0xFFA7A39C), Color(0xFF6E6A73), Color(0xFFE9E6DF)),
};

ChartBiomeColours chartBiome(String id) =>
    chartBiomeColours[id] ?? chartBiomeColours['ashlands']!;

/// One piece of terrain on a land.
enum TerrainKind {
  peak,
  tree,
  lake,
  dune,
  tuft,
  pool,
  cone,
  crack,
  shard,
  cliff,
  salt,
  terrace,
  hatch,

  /// A rounded hill, shaded on one side (v1.202).
  hill,

  /// A fir, on the cold and the high lands (v1.202).
  conifer,

  /// A boulder or an outcrop (v1.202).
  rock,
}

class TerrainMark {
  const TerrainMark(this.kind, this.at, this.size, this.zone,
      {this.snow = false, this.ember = false, this.angle = 0});
  final TerrainKind kind;
  final Offset at;
  final double size;

  /// The zone (index in the geography's list) it belongs to.
  final int zone;
  final bool snow;
  final bool ember;
  final double angle;
}

/// The relief of one geography, worked out once: the coasts and zones
/// broken into bays and headlands, the rivers bent, the terrain laid.
class ChartRelief {
  ChartRelief._(
      this.geography,
      this.coasts,
      this.zones,
      this.rivers,
      this.terrain,
      this.islets,
      this.tributaries,
      this.waves,
      this.fineTerrain);

  final ChartGeography geography;
  final List<List<Offset>> coasts;
  final List<List<Offset>> zones;

  /// Each river bent, its points ordered source to mouth (the end nearer
  /// a coast is the mouth, v1.202).
  final List<List<Offset>> rivers;
  final List<TerrainMark> terrain;

  /// Skerries and islets off the coasts, drawn as land but holding
  /// nothing.
  final List<List<Offset>> islets;

  /// Streams that join the rivers (v1.202): each from its source to the
  /// river it meets, the last point on the river.
  final List<List<Offset>> tributaries;

  /// Where a wave is drawn on the open sea (v1.202), clear of the lands.
  final List<Offset> waves;

  /// The small terrain (trees, rocks, tufts, drifts) that shows only when
  /// the chart is looked at closer (v1.202).
  final List<TerrainMark> fineTerrain;

  static final Map<ChartGeography, ChartRelief> _cache = {};

  static ChartRelief of(ChartGeography geography) =>
      _cache[geography] ??= _build(geography);

  static ChartRelief _build(ChartGeography g) {
    final seed0 =
        chartSeed(g.places.keys.join(',') + g.lands.length.toString());
    final coasts = [
      for (var i = 0; i < g.lands.length; i++)
        fractalLine(g.lands[i], seed: seed0 + i),
    ];
    final zones = [
      for (var i = 0; i < g.zones.length; i++)
        fractalLine(g.zones[i].polygon,
            depth: 3, rough: 0.10, seed: seed0 + 300 + i),
    ];
    // The rivers, each turned to run source to mouth: the end nearer a
    // coast is the mouth.
    double toCoast(Offset p) {
      var best = double.infinity;
      for (final land in g.lands) {
        for (final q in land) {
          final d = (q - p).distance;
          if (d < best) best = d;
        }
      }
      return best;
    }

    final rivers = [
      for (var i = 0; i < g.rivers.length; i++)
        () {
          final bent = fractalLine(g.rivers[i],
              depth: 3, rough: 0.14, seed: seed0 + 500 + i, closed: false);
          return toCoast(bent.first) < toCoast(bent.last)
              ? bent.reversed.toList()
              : bent;
        }(),
    ];
    // Islets: small lands a little off a coast, never over a place.
    final rng = math.Random(seed0 + 99);
    final islets = <List<Offset>>[];
    bool onLand(Offset p) => coasts.any((c) => pointInPolygon(p, c));
    bool nearPlace(Offset p, double r) =>
        g.places.values.any((q) => (q - p).distance < r);
    for (var i = 0; i < 12; i++) {
      for (var attempt = 0; attempt < 30; attempt++) {
        final c =
            Offset(4 + rng.nextDouble() * 248, 4 + rng.nextDouble() * 168);
        if (onLand(c) || nearPlace(c, 8)) continue;
        var near = false;
        for (final coast in coasts) {
          for (var k = 0; k < coast.length; k += 6) {
            if ((coast[k] - c).distance < 9) {
              near = true;
              break;
            }
          }
          if (near) break;
        }
        if (!near) continue;
        final r = 1.2 + rng.nextDouble() * 2;
        final n = 5 + rng.nextInt(4);
        islets.add([
          for (var j = 0; j < n; j++)
            Offset(
                c.dx +
                    math.cos(j * 2 * math.pi / n) *
                        r *
                        (0.6 + rng.nextDouble() * 0.7),
                c.dy +
                    math.sin(j * 2 * math.pi / n) *
                        r *
                        (0.6 + rng.nextDouble() * 0.7)),
        ]);
        break;
      }
    }
    final terrain = <TerrainMark>[];
    final trng = math.Random(seed0 + 7);
    final avoid = [
      ...g.places.values,
      for (final f in g.features) f.at,
    ];
    for (var zi = 0; zi < g.zones.length; zi++) {
      terrain.addAll(_terrainFor(
          g.zones[zi].biome, zones[zi], zi, trng, avoid, g.ranges.isNotEmpty));
    }
    final fineTerrain = <TerrainMark>[];
    final frng = math.Random(seed0 + 17);
    for (var zi = 0; zi < g.zones.length; zi++) {
      fineTerrain.addAll(_terrainFor(
          g.zones[zi].biome, zones[zi], zi, frng, avoid, g.ranges.isNotEmpty,
          fine: true));
    }
    // Streams into the rivers: one from each side where the land allows,
    // joining a third to two thirds of the way down, clear of the places.
    final tributaries = <List<Offset>>[];
    final srng = math.Random(seed0 + 11);
    for (var i = 0; i < rivers.length; i++) {
      final r = rivers[i];
      if (r.length < 6) continue;
      for (final side in const [1.0, -1.0]) {
        for (var attempt = 0; attempt < 6; attempt++) {
          final at = (r.length * (0.3 + srng.nextDouble() * 0.4)).floor();
          final junction = r[at];
          final d = r[math.min(at + 1, r.length - 1)] - r[math.max(at - 1, 0)];
          if (d.distance == 0) continue;
          final back = -d / d.distance;
          final angle = side * (0.6 + srng.nextDouble() * 0.5);
          final dir = Offset(
              back.dx * math.cos(angle) - back.dy * math.sin(angle),
              back.dx * math.sin(angle) + back.dy * math.cos(angle));
          final length = 8 + srng.nextDouble() * 9;
          final source = junction + dir * length;
          if (!onLand(source) || nearPlace(source, 5)) continue;
          final line = fractalLine([source, junction],
              depth: 2,
              rough: 0.14,
              seed: seed0 + 700 + i * 2 + attempt,
              closed: false);
          if (line.any((p) => !onLand(p)) ||
              line.any((p) => nearPlace(p, 3.5))) {
            continue;
          }
          tributaries.add(line);
          break;
        }
      }
    }
    // Waves on the open sea, well off the lands and the places at sea.
    final wrng = math.Random(seed0 + 13);
    final waves = <Offset>[];
    bool nearLand(Offset p) {
      for (final coast in coasts) {
        for (var k = 0; k < coast.length; k += 4) {
          if ((coast[k] - p).distance < 5) return true;
        }
      }
      return false;
    }

    for (var i = 0; i < 90; i++) {
      final p = Offset(wrng.nextDouble() * 256, wrng.nextDouble() * 176);
      if (onLand(p) || nearLand(p) || nearPlace(p, 7)) continue;
      if (waves.any((w) => (w - p).distance < 9)) continue;
      waves.add(p);
    }
    return ChartRelief._(g, coasts, zones, rivers, terrain, islets, tributaries,
        waves, fineTerrain);
  }

  static List<TerrainMark> _terrainFor(String biome, List<Offset> poly, int zi,
      math.Random rng, List<Offset> avoid, bool hasRanges,
      {bool fine = false}) {
    final xs = poly.map((p) => p.dx), ys = poly.map((p) => p.dy);
    final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
    final y0 = ys.reduce(math.min), y1 = ys.reduce(math.max);
    final area = (x1 - x0) * (y1 - y0);
    final out = <TerrainMark>[];
    Offset? spot(double margin) {
      for (var i = 0; i < 40; i++) {
        final p = Offset(x0 + rng.nextDouble() * (x1 - x0),
            y0 + rng.nextDouble() * (y1 - y0));
        if (pointInPolygon(p, poly) &&
            avoid.every((a) => (a - p).distance > margin)) {
          return p;
        }
      }
      return null;
    }

    int count(double per, [double scale = 1.6]) =>
        math.max(1, (area / per * scale).round());
    void add(TerrainKind kind, double per, double margin, double lo, double hi,
        {bool snow = false, bool emberChance = false}) {
      for (var i = 0; i < count(per); i++) {
        final p = spot(margin);
        if (p == null) continue;
        out.add(TerrainMark(kind, p, lo + rng.nextDouble() * (hi - lo), zi,
            snow: snow,
            ember: emberChance && rng.nextDouble() < 0.35,
            angle: rng.nextDouble() * math.pi));
      }
    }

    // Woods: clumps of trees, firs on the cold and the high lands.
    void woods(double per, int lo, int hi, {bool firs = false}) {
      for (var i = 0; i < count(per); i++) {
        final p = spot(4);
        if (p == null) continue;
        for (var j = 0; j < lo + rng.nextInt(hi - lo + 1); j++) {
          final q = p +
              Offset(rng.nextDouble() * 4 - 2, rng.nextDouble() * 2.6 - 1.3);
          if (!pointInPolygon(q, poly)) continue;
          out.add(TerrainMark(
              firs && rng.nextDouble() < 0.7
                  ? TerrainKind.conifer
                  : TerrainKind.tree,
              q,
              0.45 + rng.nextDouble() * 0.35,
              zi));
        }
      }
    }

    // The fine terrain: only the small kinds, twice as many, a little
    // smaller.
    if (fine) {
      void small(TerrainKind kind, double per, double lo, double hi) =>
          add(kind, per, 2.5, lo, hi);
      switch (biome) {
        case 'temperate':
          woods(240, 2, 4);
          small(TerrainKind.rock, 900, 0.3, 0.5);
          small(TerrainKind.tuft, 500, 0.5, 0.8);
        case 'fen':
          small(TerrainKind.tuft, 120, 0.6, 1.0);
          woods(700, 1, 3);
        case 'desert':
          small(TerrainKind.rock, 500, 0.3, 0.6);
          small(TerrainKind.dune, 400, 1.2, 2.2);
        case 'arid_coast':
          small(TerrainKind.rock, 500, 0.3, 0.5);
          small(TerrainKind.tuft, 500, 0.4, 0.7);
        case 'ashlands':
          small(TerrainKind.rock, 450, 0.3, 0.6);
          small(TerrainKind.crack, 500, 0.6, 1.2);
        case 'volcanic':
          small(TerrainKind.rock, 500, 0.3, 0.6);
          small(TerrainKind.crack, 500, 0.6, 1.2);
        case 'tear':
          small(TerrainKind.shard, 350, 0.3, 0.6);
        case 'sea_cliffs':
          woods(600, 1, 3, firs: true);
          small(TerrainKind.rock, 600, 0.3, 0.5);
        case 'frost':
          small(TerrainKind.hatch, 160, 0.3, 0.5);
          woods(700, 1, 3, firs: true);
      }
      return out;
    }
    // Ridges on the cold and broken lands (the Ring has its named ranges
    // too, so it takes fewer loose peaks).
    if (const {'frost', 'volcanic', 'sea_cliffs', 'ashlands'}.contains(biome)) {
      final ridges = count(1600, hasRanges ? 0.9 : 1.6);
      for (var r = 0; r < ridges; r++) {
        final p = spot(6);
        if (p == null) continue;
        final ang = rng.nextDouble() * math.pi;
        final len = 8 + rng.nextDouble() * 14;
        for (var j = 0; j < len ~/ 3; j++) {
          final q = Offset(
              p.dx + math.cos(ang) * j * 3 + rng.nextDouble() * 2 - 1,
              p.dy + math.sin(ang) * j * 3 + rng.nextDouble() * 2 - 1);
          if (!pointInPolygon(q, poly) ||
              avoid.any((a) => (a - q).distance < 5)) {
            continue;
          }
          out.add(TerrainMark(
              TerrainKind.peak, q, 0.7 + rng.nextDouble() * 0.6, zi,
              snow: biome == 'frost',
              ember: biome == 'volcanic' && rng.nextDouble() < 0.35));
        }
      }
    }
    switch (biome) {
      case 'temperate':
        woods(300, 3, 7);
        add(TerrainKind.hill, 700, 4, 1.4, 2.4);
        add(TerrainKind.lake, 2200, 6, 1.0, 2.0);
        add(TerrainKind.rock, 1800, 3, 0.4, 0.7);
      case 'fen':
        add(TerrainKind.tuft, 220, 3, 0.8, 1.2);
        add(TerrainKind.pool, 700, 4, 0.8, 1.6);
        woods(900, 2, 4);
        add(TerrainKind.hill, 1600, 4, 1.0, 1.6);
      case 'desert':
        add(TerrainKind.dune, 180, 3, 2.0, 4.5);
        add(TerrainKind.rock, 1200, 3, 0.4, 0.8);
      case 'arid_coast':
        add(TerrainKind.salt, 320, 3, 0.8, 1.2);
        add(TerrainKind.hill, 1200, 4, 1.0, 1.8);
        add(TerrainKind.rock, 1000, 3, 0.4, 0.7);
      case 'ashlands':
        add(TerrainKind.cone, 600, 4, 0.5, 0.9);
        add(TerrainKind.crack, 450, 2, 1.0, 2.0);
        add(TerrainKind.rock, 900, 3, 0.4, 0.8);
        woods(2200, 2, 3, firs: true);
      case 'volcanic':
        add(TerrainKind.terrace, 450, 3, 1.5, 3.0);
        add(TerrainKind.crack, 800, 2, 0.8, 1.6);
        add(TerrainKind.rock, 1000, 3, 0.4, 0.8);
      case 'tear':
        add(TerrainKind.shard, 300, 3, 0.5, 1.0);
        add(TerrainKind.crack, 900, 2, 0.8, 1.6);
      case 'sea_cliffs':
        add(TerrainKind.cliff, 420, 3, 0.8, 1.2);
        woods(1200, 2, 4, firs: true);
        add(TerrainKind.rock, 1200, 3, 0.4, 0.7);
      case 'frost':
        add(TerrainKind.hatch, 260, 2, 0.3, 0.5);
        woods(1300, 2, 4, firs: true);
        add(TerrainKind.rock, 1400, 3, 0.4, 0.7);
    }
    return out;
  }
}
