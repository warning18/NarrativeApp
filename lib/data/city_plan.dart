// A city drawn as a city (v1.203): a wall with its gates and towers, main
// streets from the gates to the market square, ring streets and lanes
// between, houses set along every street, a church, a keep, the water
// with its quays and bridges, fields and a suburb outside the wall; and
// the story's districts set on it as the buildings they are (a gate, a
// wharf, a keep, an undercroft, a hall, a temple, the tear), each with the
// spot the party stands at. Everything is laid out from a seed in the
// plan's own units (a 1000 x 1000 square), the same on every visit, and
// the painter scales it to the map.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

/// How big the place is: how wide its wall, how many streets.
enum CitySize { village, town, city }

/// A district of the place, as geography.json gives it: its id and the
/// glyph that says what it is (see geoGlyphs).
class CityDistrict {
  const CityDistrict(this.id, this.glyph);
  final String id;
  final String glyph;
}

/// What a building is drawn as.
enum CityBuildingKind { house, shack, warehouse, stall, hall, field }

class CityBuilding {
  const CityBuilding(this.centre, this.size, this.angle, this.kind);
  final Offset centre;
  final Size size;
  final double angle;
  final CityBuildingKind kind;

  Rect get rect =>
      Rect.fromCenter(center: centre, width: size.width, height: size.height);
}

class CityStreet {
  const CityStreet(this.points, this.width, {this.main = false});
  final List<Offset> points;
  final double width;
  final bool main;
}

/// What a landmark is drawn as (the districts' buildings, and the city's
/// own church, keep and mill).
enum CityLandmarkKind {
  gate,
  market,
  church,
  keep,
  quay,
  wharf,
  yard,
  bridge,
  cellar,
  slum,
  hall,
  fields,
  tear,
  plaza,
  mill,
}

class CityLandmark {
  const CityLandmark({
    required this.kind,
    required this.at,
    required this.angle,
    required this.anchor,
    this.districtId = '',
    this.extent = 40,
  });

  /// The district it stands for, or '' for one of the city's own.
  final String districtId;
  final CityLandmarkKind kind;

  /// Its middle and the way it faces (radians, 0 east, y down).
  final Offset at;
  final double angle;

  /// Where the party stands at it: its door, its foot, the quayside.
  final Offset anchor;

  /// How far it reaches from [at], kept clear of houses.
  final double extent;
}

/// The city, laid out once.
class CityPlan {
  CityPlan._({
    required this.seed,
    required this.size,
    required this.water,
    required this.centre,
    required this.radius,
    required this.squareRadius,
    required this.wallRuns,
    required this.gates,
    required this.towers,
    required this.streets,
    required this.buildings,
    required this.landmarks,
    required this.anchors,
    required this.trees,
    required this.river,
    required this.riverWidth,
    required this.shoreline,
    required this.bridges,
    required this.quays,
    required this.boats,
    required this.frame,
  }) {
    _buildGraph();
  }

  /// The plan's own square.
  static const Rect bounds = Rect.fromLTWH(0, 0, 1000, 1000);

  final int seed;
  final CitySize size;

  /// 'river', 'shore' or ''.
  final String water;
  final Offset centre;
  final double radius;
  final double squareRadius;

  /// The wall, in runs between its gates (and its waterfront, left open).
  final List<List<Offset>> wallRuns;
  final List<Offset> gates;
  final List<Offset> towers;
  final List<CityStreet> streets;
  final List<CityBuilding> buildings;
  final List<CityLandmark> landmarks;

  /// Where the party stands in each district, by district id; the place
  /// itself (its square) under ''.
  final Map<String, Offset> anchors;
  final List<Offset> trees;

  /// The river through the city, top to bottom, or empty.
  final List<Offset> river;
  final double riverWidth;

  /// The shoreline, top to bottom, the sea to its left; or empty.
  final List<Offset> shoreline;

  /// Bridges over the river: where, and the way they cross.
  final List<(Offset, double)> bridges;

  /// Quays along the water: each from its landward end to its end in the
  /// water.
  final List<(Offset, Offset)> quays;
  final List<(Offset, double)> boats;

  /// What the map should keep in view: the wall and everything the story
  /// stands at, with a little country round it.
  final Rect frame;

  bool get walled => wallRuns.isNotEmpty;

  /// Where the party stands in [districtId] ('' or unknown: the square).
  Offset anchorOf(String districtId) =>
      anchors[districtId] ?? anchors[''] ?? centre;

  // --- The street graph, for the party's walks ---------------------------

  final List<Offset> _nodes = [];
  final List<List<(int, double)>> _edges = [];

  void _buildGraph() {
    int node(Offset p) {
      for (var i = 0; i < _nodes.length; i++) {
        if ((_nodes[i] - p).distance < 9) return i;
      }
      _nodes.add(p);
      _edges.add([]);
      return _nodes.length - 1;
    }

    void link(int a, int b) {
      if (a == b) return;
      final d = (_nodes[a] - _nodes[b]).distance;
      if (_edges[a].any((e) => e.$1 == b)) return;
      _edges[a].add((b, d));
      _edges[b].add((a, d));
    }

    for (final street in streets) {
      int? last;
      for (var i = 0; i + 1 < street.points.length; i++) {
        final a = street.points[i], b = street.points[i + 1];
        final length = (b - a).distance;
        final steps = math.max(1, (length / 28).round());
        for (var k = 0; k <= steps; k++) {
          if (k == steps && i + 1 < street.points.length - 1) break;
          final p = a + (b - a) * (k / steps);
          final n = node(p);
          if (last != null) link(last, n);
          last = n;
        }
      }
    }
    // Streets that cross without sharing a point still meet.
    for (var i = 0; i < _nodes.length; i++) {
      for (var j = i + 1; j < _nodes.length; j++) {
        if ((_nodes[i] - _nodes[j]).distance < 20) link(i, j);
      }
    }
  }

  int _nearestNode(Offset p) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < _nodes.length; i++) {
      final d = (_nodes[i] - p).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// The way through the streets from [from] to [to], [from] first and
  /// [to] last; a straight line when the city has no streets.
  List<Offset> route(Offset from, Offset to) {
    if (_nodes.isEmpty) return [from, to];
    final a = _nearestNode(from), b = _nearestNode(to);
    final dist = List<double>.filled(_nodes.length, double.infinity);
    final prev = List<int>.filled(_nodes.length, -1);
    final done = List<bool>.filled(_nodes.length, false);
    dist[a] = 0;
    for (var round = 0; round < _nodes.length; round++) {
      var u = -1;
      var best = double.infinity;
      for (var i = 0; i < _nodes.length; i++) {
        if (!done[i] && dist[i] < best) {
          best = dist[i];
          u = i;
        }
      }
      if (u < 0 || u == b) break;
      done[u] = true;
      for (final (v, w) in _edges[u]) {
        if (dist[u] + w < dist[v]) {
          dist[v] = dist[u] + w;
          prev[v] = u;
        }
      }
    }
    if (dist[b] == double.infinity) return [from, to];
    final path = <Offset>[];
    for (var n = b; n != -1; n = prev[n]) {
      path.add(_nodes[n]);
    }
    final out = [from, ...path.reversed, to];
    // The first and last street points are dropped when they double back
    // past the ends.
    if (out.length > 2 && (out[1] - out[0]).distance < 6) out.removeAt(1);
    if (out.length > 2 && (out[out.length - 2] - out.last).distance < 6) {
      out.removeAt(out.length - 2);
    }
    return out;
  }

  // --- Laying the city out ----------------------------------------------

  static final Map<String, CityPlan> _cache = {};

  /// The plan of a place, kept once laid: [seed] and the rest make its
  /// key. [exitBearings] are the directions of the roads out to other
  /// places (radians, 0 east, y down), where the gates go first.
  static CityPlan of({
    required int seed,
    required CitySize size,
    required String water,
    required List<CityDistrict> districts,
    List<double> exitBearings = const [],
  }) {
    final key =
        '$seed:${size.name}:$water:${districts.map((d) => '${d.id}=${d.glyph}').join(',')}';
    return _cache[key] ??= _lay(
        seed: seed,
        size: size,
        water: water,
        districts: districts,
        exitBearings: exitBearings);
  }

  static CityPlan _lay({
    required int seed,
    required CitySize size,
    required String water,
    required List<CityDistrict> districts,
    required List<double> exitBearings,
  }) {
    final rng = math.Random(seed);
    final radius = switch (size) {
      CitySize.city => 330.0,
      CitySize.town => 240.0,
      CitySize.village => 150.0,
    };
    final squareRadius = switch (size) {
      CitySize.city => 46.0,
      CitySize.town => 36.0,
      CitySize.village => 26.0,
    };
    // The water first: the city stands back from it.
    final river = <Offset>[];
    var riverWidth = 0.0;
    final shoreline = <Offset>[];
    var centre = const Offset(500, 500);
    if (water == 'river') {
      riverWidth = size == CitySize.city ? 40 : 30;
      final base = 500 - radius * 0.45 + (rng.nextDouble() - 0.5) * 40;
      final phase = rng.nextDouble() * math.pi;
      for (var y = -40.0; y <= 1040; y += 25) {
        river.add(Offset(
            base + 55 * math.sin(y / 230 + phase) + 18 * math.sin(y / 70), y));
      }
    } else if (water == 'shore') {
      final phase = rng.nextDouble() * math.pi;
      for (var y = -40.0; y <= 1040; y += 25) {
        shoreline.add(
            Offset(500 - radius * 0.95 + 30 * math.sin(y / 260 + phase), y));
      }
      centre = Offset(500 + radius * 0.12, 500);
    }
    double shoreX(double y) {
      if (shoreline.isEmpty) return -1e9;
      var best = shoreline.first;
      for (final p in shoreline) {
        if ((p.dy - y).abs() < (best.dy - y).abs()) best = p;
      }
      return best.dx;
    }

    bool inWater(Offset p, [double margin = 0]) {
      if (shoreline.isNotEmpty && p.dx < shoreX(p.dy) + margin) return true;
      if (river.isNotEmpty) {
        for (final q in river) {
          if ((q.dy - p.dy).abs() < 30 &&
              (q - p).distance < riverWidth / 2 + margin) {
            return true;
          }
        }
      }
      return false;
    }

    // The wall: a ring of points, a little uneven, open where the water
    // is; each gate a gap in it.
    final walled = size != CitySize.village;
    final wallPoints = <Offset?>[];
    const wallN = 28;
    for (var i = 0; i < wallN; i++) {
      final a = i * 2 * math.pi / wallN;
      final r = radius * (0.94 + rng.nextDouble() * 0.1);
      final p = centre + Offset(math.cos(a), math.sin(a)) * r;
      wallPoints.add(inWater(p, 26) ? null : p);
    }
    // Gates: the roads out go first, then north, south, east and west,
    // never over the water.
    final wantedGates = switch (size) {
          CitySize.city => 3,
          CitySize.town => 2,
          CitySize.village => 2,
        } +
        districts.where((d) => d.glyph == 'gate').length;
    final gateBearings = <double>[];
    double norm(double a) => a % (2 * math.pi);
    bool farFrom(double a) =>
        gateBearings.every((g) => _angleBetween(g, a).abs() > 0.9);
    for (final b in [
      ...exitBearings,
      -math.pi / 2,
      math.pi / 2,
      0.0,
      math.pi,
      -math.pi / 4,
      math.pi * 3 / 4
    ]) {
      if (gateBearings.length >= math.min(wantedGates, 4)) break;
      final p = centre + Offset(math.cos(b), math.sin(b)) * radius;
      final road = centre + Offset(math.cos(b), math.sin(b)) * radius * 1.7;
      if (inWater(p, 30) || inWater(road, 10) || !farFrom(norm(b))) continue;
      gateBearings.add(norm(b));
    }
    if (gateBearings.isEmpty) gateBearings.add(0);
    final gates = <Offset>[
      for (final b in gateBearings)
        centre + Offset(math.cos(b), math.sin(b)) * radius * 0.98,
    ];
    final wallRuns = <List<Offset>>[];
    final towers = <Offset>[];
    if (walled) {
      // The ring broken at each gate (a gap of 26 units) and at the
      // water; each run a list of points.
      var run = <Offset>[];
      void close() {
        if (run.length >= 2) wallRuns.add(run);
        run = [];
      }

      for (var i = 0; i <= wallN; i++) {
        final p = wallPoints[i % wallN];
        if (p == null) {
          close();
          continue;
        }
        final a = i * 2 * math.pi / wallN;
        final atGate =
            gateBearings.any((g) => _angleBetween(g, a).abs() < 0.13);
        if (atGate) {
          close();
          continue;
        }
        run.add(p);
      }
      close();
      for (final r in wallRuns) {
        towers.add(r.first);
        towers.add(r.last);
        var d = 0.0;
        for (var i = 0; i + 1 < r.length; i++) {
          d += (r[i + 1] - r[i]).distance;
          if (d > 120) {
            towers.add(r[i + 1]);
            d = 0;
          }
        }
      }
    }

    // The streets: main streets from each gate to the square's edge, on
    // out of the gate to the plan's edge; rings; lanes between.
    final streets = <CityStreet>[];
    final mainWidth = size == CitySize.city ? 15.0 : 12.0;
    for (var g = 0; g < gates.length; g++) {
      final b = gateBearings[g];
      final gate = gates[g];
      final edge = centre + Offset(math.cos(b), math.sin(b)) * squareRadius;
      final d = edge - gate;
      final n = Offset(-d.dy, d.dx) / d.distance;
      final k1 = (rng.nextDouble() - 0.5) * 50,
          k2 = (rng.nextDouble() - 0.5) * 50;
      streets.add(CityStreet([
        gate,
        gate + d * 0.35 + n * k1,
        gate + d * 0.7 + n * k2,
        edge,
      ], mainWidth, main: true));
      // The road on out into the country.
      final far = centre + Offset(math.cos(b), math.sin(b)) * 600;
      final out = far - gate;
      final on = Offset(-out.dy, out.dx) / out.distance;
      streets.add(CityStreet([
        gate,
        gate + out * 0.4 + on * (rng.nextDouble() - 0.5) * 60,
        far,
      ], mainWidth * 0.8));
    }
    List<Offset> ring(double r, int n, double wobble) => [
          for (var i = 0; i <= n; i++)
            () {
              final a = (i % n) * 2 * math.pi / n;
              final rr = r * (1 + (math.sin(a * 3 + seed) * wobble));
              return centre + Offset(math.cos(a), math.sin(a)) * rr;
            }(),
        ];
    final rings = <double>[
      0.45,
      if (size == CitySize.city) 0.76,
    ];
    for (final f in rings) {
      final pts =
          ring(radius * f, 14, 0.05).where((p) => !inWater(p, 12)).toList();
      // A ring that meets the water is drawn in its dry stretches.
      var run = <Offset>[];
      final all = ring(radius * f, 14, 0.05);
      for (final p in all) {
        if (inWater(p, 12)) {
          if (run.length >= 2) streets.add(CityStreet(run, 9));
          run = [];
        } else {
          run.add(p);
        }
      }
      if (run.length >= 2) streets.add(CityStreet(run, 9));
      if (pts.length < 3) continue;
    }
    final laneCount = switch (size) {
      CitySize.city => 11,
      CitySize.town => 7,
      CitySize.village => 4,
    };
    for (var i = 0; i < laneCount; i++) {
      final a = i * 2 * math.pi / laneCount + rng.nextDouble() * 0.4;
      if (gateBearings.any((g) => _angleBetween(g, a).abs() < 0.32)) continue;
      final r0 = radius * (size == CitySize.village ? 0.25 : 0.2);
      final r1 = radius * (walled ? 0.9 : 0.75);
      final from = centre + Offset(math.cos(a), math.sin(a)) * r0;
      final to = centre + Offset(math.cos(a), math.sin(a)) * r1;
      if (inWater(from, 8) || inWater(to, 8)) continue;
      final d = to - from;
      final n = Offset(-d.dy, d.dx) / d.distance;
      streets.add(CityStreet(
          [from, from + d * 0.5 + n * (rng.nextDouble() - 0.5) * 36, to], 7));
    }
    // Cross lanes in a city: short arcs between the rings.
    if (size == CitySize.city) {
      for (var i = 0; i < 6; i++) {
        final a = rng.nextDouble() * 2 * math.pi;
        final r = radius * (0.55 + rng.nextDouble() * 0.15);
        final pts = [
          for (var k = 0; k <= 3; k++)
            centre + Offset(math.cos(a + k * 0.12), math.sin(a + k * 0.12)) * r,
        ];
        if (pts.any((p) => inWater(p, 8))) continue;
        streets.add(CityStreet(pts, 6));
      }
    }

    // Bridges: where a street crosses the river, the street carries over.
    final bridges = <(Offset, double)>[];
    if (river.isNotEmpty) {
      for (final street in streets) {
        for (var i = 0; i + 1 < street.points.length; i++) {
          final a = street.points[i], b = street.points[i + 1];
          for (var k = 0; k + 1 < river.length; k++) {
            final x = _segmentsCross(a, b, river[k], river[k + 1]);
            if (x != null) {
              final d = b - a;
              bridges.add((x, math.atan2(d.dy, d.dx)));
            }
          }
        }
      }
    }

    // The landmarks: the districts first, in the order that gives each
    // its proper ground, then the city's own church, keep and mill.
    final landmarks = <CityLandmark>[];
    final anchors = <String, Offset>{'': centre};
    final reserved = <(Offset, double)>[]; // circles no house may enter
    final usedBearings = <double>[...gateBearings];
    double freeBearing({double from = 0.0, bool dry = true, double r = 0.6}) {
      var best = 0.0;
      var bestGap = -1.0;
      for (var i = 0; i < 24; i++) {
        final a = from + i * 2 * math.pi / 24 + 0.13;
        final p = centre + Offset(math.cos(a), math.sin(a)) * radius * r;
        if (dry && inWater(p, 40)) continue;
        final gap = usedBearings.isEmpty
            ? math.pi
            : usedBearings
                .map((u) => _angleBetween(u, a).abs())
                .reduce(math.min);
        if (gap > bestGap) {
          bestGap = gap;
          best = a;
        }
      }
      usedBearings.add(best);
      return best;
    }

    /// The water's edge nearest the city on the side that faces it, at a
    /// height [dy] from the centre, and the way out over the water.
    (Offset, double)? waterside(double dy) {
      final y = centre.dy + dy;
      if (shoreline.isNotEmpty) {
        return (Offset(shoreX(y) + 2, y), math.pi);
      }
      if (river.isNotEmpty) {
        var best = river.first;
        for (final p in river) {
          if ((p.dy - y).abs() < (best.dy - y).abs()) best = p;
        }
        // The bank on the city's side: the centre's side of the river.
        final side = centre.dx > best.dx ? 1.0 : -1.0;
        return (
          Offset(best.dx + side * (riverWidth / 2 + 2), best.dy),
          side > 0 ? math.pi : 0.0
        );
      }
      return null;
    }

    /// A short lane from [anchor] to the nearest street there is.
    void spur(Offset anchor, double width) {
      Offset? best;
      var bestD = double.infinity;
      for (final st in streets) {
        for (var i = 0; i + 1 < st.points.length; i++) {
          final a = st.points[i], b = st.points[i + 1];
          final ab = b - a;
          final len2 = ab.distanceSquared;
          final t = len2 == 0
              ? 0.0
              : (((anchor - a).dx * ab.dx + (anchor - a).dy * ab.dy) / len2)
                  .clamp(0.0, 1.0);
          final q = a + ab * t;
          final d = (q - anchor).distance;
          if (d < bestD) {
            bestD = d;
            best = q;
          }
        }
      }
      if (best == null || bestD < 6) return;
      streets.add(CityStreet([anchor, best], width));
    }

    var gateIndex = 0;
    var quayDy = -70.0;
    final quays = <(Offset, Offset)>[];
    final boats = <(Offset, double)>[];
    void reserve(Offset at, double r) => reserved.add((at, r));
    final pending = [...districts];
    // Gates and the market go on fixed ground, so first.
    pending.sort((a, b) {
      int rank(String g) => switch (g) {
            'gate' => 0,
            'market' => 1,
            'bridge' => 2,
            'quay' || 'wharf' || 'yard' => 3,
            'keep' => 4,
            'temple' || 'hall' || 'cellar' => 5,
            _ => 6,
          };
      return rank(a.glyph).compareTo(rank(b.glyph));
    });
    var hasChurch = false, hasKeep = false, hasMarketHall = false;
    for (final d in pending) {
      switch (d.glyph) {
        case 'gate':
          final g = gates[gateIndex % gates.length];
          final b = gateBearings[gateIndex % gates.length];
          gateIndex++;
          final inward = Offset(-math.cos(b), -math.sin(b));
          final anchor = g + inward * 26;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.gate,
              at: g,
              angle: b,
              anchor: anchor,
              districtId: d.id,
              extent: 30));
          anchors[d.id] = anchor;
          reserve(g, 34);
        case 'market':
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.market,
              at: centre,
              angle: 0,
              anchor: centre,
              districtId: d.id,
              extent: squareRadius));
          anchors[d.id] = centre;
          hasMarketHall = true;
        case 'bridge':
          if (bridges.isNotEmpty) {
            // The bridge nearest the centre.
            bridges.sort((a, b) => (a.$1 - centre)
                .distanceSquared
                .compareTo((b.$1 - centre).distanceSquared));
            final (at, angle) = bridges.first;
            final toCentre = centre - at;
            final along = Offset(math.cos(angle), math.sin(angle));
            final sign = (toCentre.dx * along.dx + toCentre.dy * along.dy) >= 0
                ? 1.0
                : -1.0;
            final anchor = at + along * sign * (riverWidth / 2 + 16);
            landmarks.add(CityLandmark(
                kind: CityLandmarkKind.bridge,
                at: at,
                angle: angle,
                anchor: anchor,
                districtId: d.id,
                extent: riverWidth));
            anchors[d.id] = anchor;
          } else {
            final a = freeBearing();
            final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.5;
            landmarks.add(CityLandmark(
                kind: CityLandmarkKind.plaza,
                at: at,
                angle: a,
                anchor: at,
                districtId: d.id,
                extent: 24));
            anchors[d.id] = at;
            reserve(at, 30);
          }
        case 'quay' || 'wharf' || 'yard':
          final side = waterside(quayDy);
          quayDy += 110;
          if (side == null) {
            final a = freeBearing(r: 0.85);
            final at =
                centre + Offset(math.cos(a), math.sin(a)) * radius * 0.85;
            landmarks.add(CityLandmark(
                kind: CityLandmarkKind.yard,
                at: at,
                angle: a,
                anchor: at + Offset(math.cos(a), math.sin(a)) * -40,
                districtId: d.id,
                extent: 44));
            anchors[d.id] = at + Offset(math.cos(a), math.sin(a)) * -40;
            reserve(at, 50);
            break;
          }
          final (edge, outAngle) = side;
          final out = Offset(math.cos(outAngle), math.sin(outAngle));
          final along = Offset(-out.dy, out.dx);
          final kind = switch (d.glyph) {
            'wharf' => CityLandmarkKind.wharf,
            'yard' => CityLandmarkKind.yard,
            _ => CityLandmarkKind.quay,
          };
          final anchor = edge - out * 16;
          landmarks.add(CityLandmark(
              kind: kind,
              at: edge,
              angle: outAngle,
              anchor: anchor,
              districtId: d.id,
              extent: 60));
          anchors[d.id] = anchor;
          reserve(edge, 46);
          quays.add((edge - along * 40, edge + along * 40));
          if (kind == CityLandmarkKind.wharf) {
            for (final k in const [-28.0, 0.0, 28.0]) {
              quays.add((edge + along * k, edge + along * k + out * 34));
            }
          }
          boats.add((edge + out * 26 + along * 14, outAngle + 0.4));
          boats.add((edge + out * 20 - along * 30, outAngle - 0.3));
          spur(anchor, 9);
        case 'keep':
          hasKeep = true;
          final a = freeBearing(r: 0.8);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.78;
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -62;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.keep,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 64));
          anchors[d.id] = anchor;
          reserve(at, 70);
          spur(anchor, 9);
        case 'temple':
          hasChurch = true;
          final a = freeBearing(r: 0.5);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.5;
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -48;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.church,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 54));
          anchors[d.id] = anchor;
          reserve(at, 58);
        case 'hall':
          hasMarketHall = true;
          final a = freeBearing(r: 0.3);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.3;
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -34;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.hall,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 40));
          anchors[d.id] = anchor;
          reserve(at, 44);
        case 'cellar':
          final a = freeBearing(r: 0.6);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.62;
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -30;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.cellar,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 36));
          anchors[d.id] = anchor;
          reserve(at, 40);
        case 'slum':
          // Outside the wall, by a gate.
          final g = gateIndex < gates.length ? gateIndex : 0;
          final b = gateBearings[(g + 1) % gates.length];
          final gate = gates[(g + 1) % gates.length];
          final outward = Offset(math.cos(b), math.sin(b));
          final at = gate + outward * 90;
          final anchor = gate + outward * 60;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.slum,
              at: at,
              angle: b,
              anchor: anchor,
              districtId: d.id,
              extent: 70));
          anchors[d.id] = anchor;
        case 'field':
          final a = freeBearing(r: 1.3);
          final at = centre + Offset(math.cos(a), math.sin(a)) * (radius + 110);
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -50;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.fields,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 90));
          anchors[d.id] = anchor;
          reserve(at, 90);
          spur(anchor, 7);
        case 'void':
          final a = freeBearing(r: 1.0);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.92;
          final anchor = at + Offset(math.cos(a), math.sin(a)) * -44;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.tear,
              at: at,
              angle: a,
              anchor: anchor,
              districtId: d.id,
              extent: 50));
          anchors[d.id] = anchor;
          reserve(at, 56);
          spur(anchor, 7);
        default:
          final a = freeBearing(r: 0.55);
          final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.55;
          landmarks.add(CityLandmark(
              kind: CityLandmarkKind.plaza,
              at: at,
              angle: a,
              anchor: at,
              districtId: d.id,
              extent: 24));
          anchors[d.id] = at;
          reserve(at, 30);
      }
    }
    // The city's own: a church (a chapel in a village), a keep in a city,
    // a mill by the water or a windmill without.
    if (!hasChurch) {
      final a = freeBearing(r: 0.5);
      final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.5;
      landmarks.add(CityLandmark(
          kind: CityLandmarkKind.church,
          at: at,
          angle: a,
          anchor: at + Offset(math.cos(a), math.sin(a)) * -48,
          extent: size == CitySize.village ? 34 : 54));
      reserve(at, size == CitySize.village ? 40 : 58);
    }
    if (!hasKeep && size == CitySize.city) {
      final a = freeBearing(r: 0.8);
      final at = centre + Offset(math.cos(a), math.sin(a)) * radius * 0.78;
      landmarks.add(CityLandmark(
          kind: CityLandmarkKind.keep,
          at: at,
          angle: a,
          anchor: at + Offset(math.cos(a), math.sin(a)) * -62,
          extent: 64));
      reserve(at, 70);
    }
    if (!hasMarketHall && size != CitySize.village) {
      landmarks.add(CityLandmark(
          kind: CityLandmarkKind.market,
          at: centre,
          angle: 0,
          anchor: centre,
          extent: squareRadius));
    }
    {
      final side = waterside(radius * 0.9);
      if (side != null && size != CitySize.village) {
        final (edge, outAngle) = side;
        final out = Offset(math.cos(outAngle), math.sin(outAngle));
        landmarks.add(CityLandmark(
            kind: CityLandmarkKind.mill,
            at: edge - out * 14,
            angle: outAngle,
            anchor: edge - out * 30,
            extent: 24));
        reserve(edge - out * 14, 28);
      } else {
        final a = freeBearing(r: 1.25);
        final at = centre + Offset(math.cos(a), math.sin(a)) * (radius + 90);
        landmarks.add(CityLandmark(
            kind: CityLandmarkKind.mill,
            at: at,
            angle: a,
            anchor: at + Offset(math.cos(a), math.sin(a)) * -24,
            extent: 26));
        reserve(at, 30);
      }
    }
    reserve(centre, squareRadius + 8);
    for (final l in landmarks) {
      if (l.kind == CityLandmarkKind.market ||
          l.kind == CityLandmarkKind.bridge ||
          l.kind == CityLandmarkKind.gate) {
        continue;
      }
      spur(l.anchor, 7);
    }

    // The buildings: houses along every street, both sides; shacks in
    // the slum; warehouses by the quays; fields and farms outside; then
    // the blocks between filled in.
    final buildings = <CityBuilding>[];
    bool insideWall(Offset p) => (p - centre).distance < radius * 0.93;
    double toStreet(Offset p) {
      var best = double.infinity;
      for (final s in streets) {
        for (var i = 0; i + 1 < s.points.length; i++) {
          final d =
              _pointToSegment(p, s.points[i], s.points[i + 1]) - s.width / 2;
          if (d < best) best = d;
        }
      }
      return best;
    }

    bool free(Offset c, double w, double h, {double gap = 4}) {
      final r = math.max(w, h) / 2;
      if (!bounds.deflate(10).contains(c)) return false;
      if (inWater(c, r + 6)) return false;
      if (toStreet(c) < r * 0.75 + gap) return false;
      for (final (at, rr) in reserved) {
        if ((at - c).distance < rr + r) return false;
      }
      for (final b in buildings) {
        if ((b.centre - c).distance <
            (math.max(b.size.width, b.size.height) + math.max(w, h)) / 2 +
                gap) {
          return false;
        }
      }
      if (walled) {
        // Not on the wall itself.
        final d = (c - centre).distance;
        if ((d - radius).abs() < r + 16) return false;
      }
      return true;
    }

    for (final street in streets) {
      for (var i = 0; i + 1 < street.points.length; i++) {
        final a = street.points[i], b = street.points[i + 1];
        final d = b - a;
        final length = d.distance;
        if (length < 20) continue;
        final unit = d / length;
        final normal = Offset(-unit.dy, unit.dx);
        final angle = math.atan2(unit.dy, unit.dx);
        for (var t = 14.0; t < length - 10; t += 0) {
          final w = 16 + rng.nextDouble() * 14;
          final h = 11 + rng.nextDouble() * 7;
          final along = a + unit * t;
          final inside = insideWall(along);
          final suburb = !walled || (along - centre).distance < radius + 170;
          for (final side in const [1.0, -1.0]) {
            if (!inside && (rng.nextDouble() < 0.55 || !suburb)) continue;
            if (inside && rng.nextDouble() < 0.12) continue;
            final c = along + normal * side * (street.width / 2 + 5 + h / 2);
            if (!free(c, w, h, gap: 3)) continue;
            buildings.add(CityBuilding(c, Size(w, h), angle,
                inside ? CityBuildingKind.house : CityBuildingKind.house));
          }
          t += w + 5 + rng.nextDouble() * 6;
        }
      }
    }
    // Shacks of the slum, warehouses at the quays, stalls on the square,
    // fields and an orchard outside.
    for (final l in landmarks) {
      switch (l.kind) {
        case CityLandmarkKind.slum:
          final out = Offset(math.cos(l.angle), math.sin(l.angle));
          final side = Offset(-out.dy, out.dx);
          for (var i = 0; i < 16; i++) {
            final c = l.at +
                out * (rng.nextDouble() - 0.5) * 110 +
                side * (rng.nextDouble() - 0.5) * 120;
            if (!free(c, 10, 8, gap: 2)) continue;
            buildings.add(CityBuilding(c, const Size(10, 8),
                rng.nextDouble() * math.pi, CityBuildingKind.shack));
          }
        case CityLandmarkKind.quay || CityLandmarkKind.wharf:
          final out = Offset(math.cos(l.angle), math.sin(l.angle));
          final side = Offset(-out.dy, out.dx);
          for (final k in const [-30.0, 0.0, 30.0]) {
            final c = l.at - out * 34 + side * k;
            final w = 24.0, h = 14.0;
            final ok = !inWater(c, 8) &&
                buildings.every((b) =>
                    (b.centre - c).distance >
                    (math.max(b.size.width, b.size.height) + w) / 2 + 2);
            if (!ok) continue;
            buildings.add(CityBuilding(c, Size(w, h), l.angle + math.pi / 2,
                CityBuildingKind.warehouse));
          }
        case CityLandmarkKind.market:
          for (var i = 0; i < 7; i++) {
            final a = i * 2 * math.pi / 7 + 0.4;
            final c =
                l.at + Offset(math.cos(a), math.sin(a)) * (squareRadius * 0.62);
            buildings.add(CityBuilding(
                c, const Size(9, 6), a + math.pi / 2, CityBuildingKind.stall));
          }
        case CityLandmarkKind.fields:
          final out = Offset(math.cos(l.angle), math.sin(l.angle));
          final side = Offset(-out.dy, out.dx);
          for (final (dx, dy) in const [
            (-40.0, -30.0),
            (10.0, -34.0),
            (-30.0, 24.0),
            (26.0, 20.0)
          ]) {
            final c = l.at + out * dx + side * dy;
            buildings.add(CityBuilding(
                c,
                Size(44 + rng.nextDouble() * 14, 30),
                l.angle + (rng.nextDouble() - 0.5) * 0.3,
                CityBuildingKind.field));
          }
        default:
          break;
      }
    }
    if (walled) {
      // Fields round the city, out beyond the wall.
      for (var i = 0; i < (size == CitySize.city ? 10 : 7); i++) {
        final a = rng.nextDouble() * 2 * math.pi;
        final r = radius + 70 + rng.nextDouble() * 160;
        final c = centre + Offset(math.cos(a), math.sin(a)) * r;
        if (!free(c, 50, 34, gap: 8)) continue;
        buildings.add(CityBuilding(c, Size(40 + rng.nextDouble() * 24, 30),
            a + (rng.nextDouble() - 0.5) * 0.6, CityBuildingKind.field));
      }
    }
    // The blocks between the streets, filled.
    final fillTries = switch (size) {
      CitySize.city => 900,
      CitySize.town => 500,
      CitySize.village => 160,
    };
    for (var i = 0; i < fillTries; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      final r = math.sqrt(rng.nextDouble()) * radius * 0.9;
      final c = centre + Offset(math.cos(a), math.sin(a)) * r;
      final w = 14 + rng.nextDouble() * 12, h = 10 + rng.nextDouble() * 8;
      if (!free(c, w, h, gap: 4)) continue;
      if (toStreet(c) > 56) continue; // every house stands near a street
      buildings.add(CityBuilding(
          c, Size(w, h), rng.nextDouble() * math.pi, CityBuildingKind.house));
    }
    // Trees: in the yards left inside, and over the country.
    final trees = <Offset>[];
    for (var i = 0; i < 70; i++) {
      final c = Offset(rng.nextDouble() * 1000, rng.nextDouble() * 1000);
      final inside = (c - centre).distance < radius;
      if (inside && rng.nextDouble() < 0.85) continue;
      final n = inside ? 1 : 2 + rng.nextInt(6);
      for (var k = 0; k < n; k++) {
        final t = c +
            Offset(
                (rng.nextDouble() - 0.5) * 50, (rng.nextDouble() - 0.5) * 40);
        if (!free(t, 10, 10, gap: 2)) continue;
        if (toStreet(t) < 8) continue;
        if (trees.any((o) => (o - t).distance < 9)) continue;
        trees.add(t);
      }
    }

    var frame = Rect.fromCircle(center: centre, radius: radius + 34);
    for (final l in landmarks) {
      if (l.districtId.isEmpty) continue;
      frame =
          frame.expandToInclude(Rect.fromCircle(center: l.anchor, radius: 40));
    }
    frame = frame.intersect(bounds);
    return CityPlan._(
      seed: seed,
      size: size,
      water: water,
      centre: centre,
      radius: radius,
      squareRadius: squareRadius,
      wallRuns: wallRuns,
      gates: gates,
      towers: towers,
      streets: streets,
      buildings: buildings,
      landmarks: landmarks,
      anchors: anchors,
      trees: trees,
      river: river,
      riverWidth: riverWidth,
      shoreline: shoreline,
      bridges: bridges,
      quays: quays,
      boats: boats,
      frame: frame,
    );
  }
}

double _angleBetween(double a, double b) {
  var d = (a - b) % (2 * math.pi);
  if (d > math.pi) d -= 2 * math.pi;
  return d;
}

double _pointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.distanceSquared;
  if (len2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

/// Where segments [a]-[b] and [c]-[d] cross, or null.
Offset? _segmentsCross(Offset a, Offset b, Offset c, Offset d) {
  final r = b - a, s = d - c;
  final denom = r.dx * s.dy - r.dy * s.dx;
  if (denom.abs() < 1e-9) return null;
  final qp = c - a;
  final t = (qp.dx * s.dy - qp.dy * s.dx) / denom;
  final u = (qp.dx * r.dy - qp.dy * r.dx) / denom;
  if (t < 0 || t > 1 || u < 0 || u > 1) return null;
  return a + r * t;
}
