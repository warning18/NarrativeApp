// The city plan generator (board 15, docs/proposals/city-plan-record.md):
// lays a city out from above, the way an old city grew: a shore and a
// harbour, a river split round an island, canals off the harbour, a wall
// with its gates, a star of avenues from the market square to the gates,
// an arena, the story's districts as organic shapes tiling the town, and
// the lots of every district as buildings. Pure Dart (no Flutter), so
// tool/city_plans/gen_city_plans.dart can run it from the command line;
// what it makes is stored in assets/gamedata/city_plans.json and read
// through city_plan_record.dart.
import 'dart:math' as math;

/// A point of the plan (1000 x 1000, y down).
class P {
  const P(this.x, this.y);
  final double x;
  final double y;

  P operator +(P o) => P(x + o.x, y + o.y);
  P operator -(P o) => P(x - o.x, y - o.y);
  P operator *(double k) => P(x * k, y * k);
  double get length => math.sqrt(x * x + y * y);
  double dist(P o) => (this - o).length;

  List<int> toJson() => [x.round(), y.round()];
}

/// Where one district goes: its id, its seed point (the middle of its
/// shape) and whether it lies outside the wall (a shore, a yard).
class DistrictSeed {
  const DistrictSeed(this.id, this.at, {this.outside = false});
  final String id;
  final P at;
  final bool outside;
}

/// What a city is laid out from.
class CityPlanSpec {
  const CityPlanSpec({
    required this.cityId,
    required this.seed,
    required this.districts,
    required this.scenesByDistrict,
    this.followUps = const {},
    this.shoreY = 760,
    this.riverX = 400,
    this.centre = const P(560, 420),
    this.wallRadius = 320,
    this.walled = true,
    this.arena = true,
    this.canalXs = const [640, 700],
    this.canalLength = 140,
    this.bayDepth = 90,
    this.lotSpacing = 30,
    this.lotKeep = 1,
  });

  final String cityId;
  final int seed;
  final List<DistrictSeed> districts;

  /// The scenes set in each district (their ids), in story order: each
  /// gets the anchor of a building in its district.
  final Map<String, List<String>> scenesByDistrict;

  /// Scenes that stand at another's building (a way's follow-up, which
  /// returns to the hub from the same spot), by the scene they follow.
  final Map<String, String> followUps;

  /// Where the shore lies (the sea below it), and where the river comes in
  /// from the north. A null [shoreY] is a town inland (no sea, no harbour,
  /// no canals; the wall closes all round); a null [riverX] is a town with
  /// no river (no island, no river bridges). Inland on a river, the quay
  /// lies along the river's east bank.
  final double? shoreY;
  final double? riverX;
  final P centre;
  final double wallRadius;

  /// Whether the town has a wall (its runs, gates and towers); an open
  /// town keeps the same outline for its districts and avenues.
  final bool walled;

  /// Whether the town has an arena north-east of the market.
  final bool arena;

  /// Where the canals leave the harbour (x), and how far north they run;
  /// none inland.
  final List<double> canalXs;
  final double canalLength;

  /// How far the harbour's bay pulls the shore in.
  final double bayDepth;

  /// The spacing of the lots inside the wall, and the share of them still
  /// standing (below 1, a seeded share burned or fallen to empty ground).
  final double lotSpacing;
  final double lotKeep;
}

/// Lays [spec]'s city out: the record city_plans.json stores.
Map<String, Object?> generateCityPlan(CityPlanSpec spec) =>
    _CityGen(spec).build();

class _CityGen {
  _CityGen(this.spec) : rnd = math.Random(spec.seed);

  final CityPlanSpec spec;
  final math.Random rnd;

  double noise(double a, double b) {
    // A smooth, seeded wobble from a few sines.
    final s = spec.seed % 97;
    return math.sin(a * 0.013 + s) * 0.5 +
        math.sin(a * 0.031 + b * 0.017 + s * 1.7) * 0.3 +
        math.sin(b * 0.023 - a * 0.007 + s * 0.3) * 0.2;
  }

  bool get hasShore => spec.shoreY != null;
  bool get hasRiver => spec.riverX != null;

  /// The shore's y at [x]; far below the plan inland.
  double shoreAt(double x) {
    final y = spec.shoreY;
    if (y == null) return 1e6;
    return y + 26 * noise(x, 11) - _bay(x);
  }

  /// The harbour's bay: the shore pulled in north between the yard and the
  /// wharf.
  double _bay(double x) {
    final d = (x - 560) / 120;
    return spec.bayDepth * math.exp(-d * d);
  }

  late final List<P> river = _river();
  late final List<P> islandArmWest;
  late final List<P> islandArmEast;
  late final List<P> island;

  List<P> _river() {
    final rx = spec.riverX;
    if (rx == null) return const [];
    final pts = <P>[];
    for (var y = 0.0; y <= 1000; y += 25) {
      final x = rx + 40 * noise(y, 3) + (y / 1000) * 90;
      final shore = shoreAt(x);
      pts.add(P(x, math.min(y, shore + 30)));
      if (y > shore + 30) break;
    }
    return pts;
  }

  P riverAt(double y) {
    for (var i = 1; i < river.length; i++) {
      if (river[i].y >= y) {
        final a = river[i - 1], b = river[i];
        final t = (y - a.y) / math.max(1e-6, b.y - a.y);
        return a + (b - a) * t;
      }
    }
    return river.last;
  }

  Map<String, Object?> build() {
    final c = spec.centre;
    // The island: a lens in the river where it widens, south of the centre.
    final iy = c.y + 130;
    final ic = hasRiver ? riverAt(iy) : c;
    if (!hasRiver) {
      island = const [];
      islandArmWest = const [];
      islandArmEast = const [];
    } else {
      island = [
        for (var i = 0; i < 12; i++)
          () {
            final a = i / 12 * 2 * math.pi;
            final r = 1 + 0.12 * noise(a * 100, 7);
            return ic + P(math.cos(a) * 34 * r, math.sin(a) * 72 * r);
          }(),
      ];
      islandArmWest = [
        riverAt(iy - 110),
        ic + const P(-52, -40),
        ic + const P(-56, 40),
        riverAt(iy + 110),
      ];
      islandArmEast = [
        riverAt(iy - 110),
        ic + const P(52, -40),
        ic + const P(56, 40),
        riverAt(iy + 110),
      ];
    }

    // The wall: a wobbling ring round the centre, kept above the shore
    // (the town is open to the harbour).
    final ring = <P>[];
    for (var i = 0; i < 36; i++) {
      final a = i / 36 * 2 * math.pi;
      final r = spec.wallRadius * (1 + 0.09 * noise(a * 160, 5));
      var p = c + P(math.cos(a) * r, math.sin(a) * r * 0.92);
      // The south side runs down to the water: the town meets its harbour.
      final limit = shoreAt(p.x) - 4;
      if (hasShore && (p.y > limit || math.sin(a) > 0.55)) p = P(p.x, limit);
      ring.add(p);
    }
    // The town: the wall's ring; the districts outside it lie on the shore.
    final town = ring;

    // Gates: where the avenues leave, landward.
    final gateAngles = [-2.4, -1.57, -0.7, 0.25, 2.9];
    final gates = <Map<String, Object?>>[];
    final gatePoints = <P>[];
    for (final (i, a) in gateAngles.indexed) {
      final p = _ringPointToward(ring, c, a);
      gatePoints.add(p);
      gates.add({
        'id': 'gate_${['northwest', 'north', 'northeast', 'east', 'west'][i]}',
        'at': p.toJson(),
      });
    }
    // The wall runs between the gates, open where it meets the shore and
    // where the river passes.
    final runs = spec.walled ? _wallRuns(ring, gatePoints) : const <List<P>>[];
    final towers = <P>[
      for (var i = 0; i < ring.length; i += 3)
        if (spec.walled &&
            ring[i].y < shoreAt(ring[i].x) - 30 &&
            (!hasRiver || (ring[i].x - riverAt(ring[i].y).x).abs() > 50) &&
            gatePoints.every((g) => g.dist(ring[i]) > 40))
          ring[i],
    ];

    // Squares: the market at the centre, the arena north-east, a plaza by
    // the temple quarter, the quay on the harbour (inland, along the
    // river's east bank).
    final market = c + const P(40, 10);
    final quayY = c.y - 40;
    final P? quay = hasShore
        ? P(560, shoreAt(560) - 26)
        : hasRiver
            ? P(riverAt(quayY).x + 40, quayY)
            : null;
    final squares = <Map<String, Object?>>[
      _square('sq_market', 'market', market, 46, 34),
      if (spec.arena)
        _square('sq_arena', 'arena', c + const P(170, -150), 52, 40, sides: 18),
      _square('sq_plaza', 'plaza', c + const P(-150, -40), 30, 26),
      if (quay != null)
        hasShore
            ? _square('sq_quay', 'quay', quay, 70, 18)
            : _square('sq_quay', 'quay', quay, 16, 70),
    ];
    final squareShapes = [
      for (final s in squares)
        [
          for (final p in (s['shape'] as List).cast<List<int>>())
            P(p[0].toDouble(), p[1].toDouble())
        ]
    ];

    // Avenues: the star from the market to each gate, to the arena and to
    // the quay.
    final avenues = <List<P>>[
      for (final g in gatePoints) _wobblyLine(market, g),
      if (spec.arena) _wobblyLine(market, c + const P(170, -150)),
      if (hasShore)
        _wobblyLine(market, P(560, shoreAt(560) - 30))
      else if (quay != null)
        _wobblyLine(market, quay + const P(-10, 0)),
    ];

    // Canals off the harbour, north into the wharf.
    final half = spec.canalLength / 2;
    final canals = <List<P>>[
      if (hasShore)
        for (final x in spec.canalXs)
          [
            P(x, shoreAt(x) + 6),
            P(x + 6 * noise(x, 1), shoreAt(x) - half),
            P(x - 4, shoreAt(x) - spec.canalLength),
          ],
    ];

    // The sea: below the shore.
    final sea = <P>[
      if (hasShore) ...[
        for (var x = 0.0; x <= 1000; x += 25) P(x, shoreAt(x)),
        const P(1000, 1000),
        const P(0, 1000),
      ],
    ];

    // Bridges: where an avenue crosses the river or a canal, and two
    // footbridges onto the island.
    final waters = [
      if (hasRiver) ...[river, islandArmWest, islandArmEast],
      ...canals,
    ];
    final bridges = <Map<String, Object?>>[];
    for (final av in avenues) {
      for (final w in waters) {
        for (final hit in _crossings(av, w)) {
          if (bridges.any((b) => _pt(b['at']).dist(hit.$1) < 30)) continue;
          bridges.add({
            'at': hit.$1.toJson(),
            'angle': (hit.$2 * 180 / math.pi).round(),
            'length': 44,
          });
        }
      }
    }
    for (final side in [
      if (hasRiver) ...[-1.0, 1.0]
    ]) {
      final at = ic + P(side * 46, 0);
      bridges.add({'at': at.toJson(), 'angle': 0, 'length': 34});
    }

    // Districts: the seeds' cells of the town, edges wobbled the same way
    // from both sides so neighbours meet.
    final inside = spec.districts.where((d) => !d.outside).toList();
    final districts = <String, Map<String, Object?>>{};
    final shapes = <String, List<P>>{};
    for (final d in inside) {
      var cell = town;
      for (final o in inside) {
        if (o.id == d.id) continue;
        cell = _clipHalf(cell, d.at, o.at);
      }
      shapes[d.id] = _wobble(cell);
    }
    for (final d in spec.districts.where((d) => d.outside)) {
      shapes[d.id] = _outsideShape(d, ring);
    }
    for (final MapEntry(:key, :value) in shapes.entries) {
      final label = _centroid(value);
      final entry = _nearestOnPaths(label, avenues) ?? label;
      districts[key] = {
        'shape': [for (final p in value) p.toJson()],
        'label': label.toJson(),
        'entry': (_inside(entry, value) ? entry : label).toJson(),
      };
    }

    // Lots: points scattered over each district, their cells shrunk into
    // buildings, kept clear of the water, the avenues and the squares.
    final buildings = <Map<String, Object?>>[];
    var n = 0;
    for (final MapEntry(key: id, value: shape) in shapes.entries) {
      final outside = spec.districts.firstWhere((d) => d.id == id).outside;
      final pts = _scatter(shape, outside ? 46 : spec.lotSpacing);
      final lots = <(P, List<P>)>[];
      for (final p in pts) {
        var cell = shape;
        for (final o in pts) {
          if (identical(o, p)) continue;
          if (o.dist(p) > 90) continue;
          cell = _clipHalf(cell, p, o);
        }
        if (cell.length < 3) continue;
        final b = _shrink(cell, 0.72);
        if (_area(b) < 120) continue;
        if (b.any((q) =>
            (hasRiver &&
                (_nearPath(q, river, 22) ||
                    _nearPath(q, islandArmWest, 18) ||
                    _nearPath(q, islandArmEast, 18))) ||
            canals.any((cn) => _nearPath(q, cn, 10)) ||
            avenues.any((av) => _nearPath(q, av, 10)) ||
            squareShapes.any((s) => _inside(q, s)) ||
            (hasRiver && _inside(q, island)) ||
            q.y > shoreAt(q.x) - 8)) {
          continue;
        }
        // A burned town: a seeded share of its lots left empty.
        if (spec.lotKeep < 1 && rnd.nextDouble() > spec.lotKeep) continue;
        lots.add((p, b));
      }
      // The biggest lots near the label are its halls and its temple.
      final label = _pt(districts[id]!['label']);
      lots.sort((a, b) => (_area(b.$2) - b.$1.dist(label))
          .compareTo(_area(a.$2) - a.$1.dist(label)));
      for (final (i, lot) in lots.indexed) {
        final nearWater = lot.$1.y > shoreAt(lot.$1.x) - 70 ||
            canals.any((cn) => _nearPath(lot.$1, cn, 40));
        final kind = outside
            ? 'shed'
            : i == 0
                ? 'hall'
                : i == 1
                    ? 'temple'
                    : nearWater
                        ? 'warehouse'
                        : lot.$1.dist(market) < 90
                            ? 'stall'
                            : 'house';
        buildings.add({
          'id': '${spec.cityId}_b${(n++).toString().padLeft(3, '0')}',
          'district': id,
          'kind': kind,
          'shape': [for (final q in lot.$2) q.toJson()],
        });
      }
    }

    // Streets: the lanes along the districts' edges.
    final streets = <List<P>>[
      for (final shape in shapes.values) [...shape, shape.first],
    ];

    // Anchors: each district's scenes on its halls and temple first, then
    // the houses nearest its label.
    final anchors = <String, String>{};
    for (final MapEntry(key: district, value: scenes)
        in spec.scenesByDistrict.entries) {
      final order = anchorOrder(buildings, districts, district);
      final own = [
        for (final s in scenes)
          if (!spec.followUps.containsKey(s)) s
      ];
      for (final (i, scene) in own.indexed) {
        if (order.isEmpty) break;
        anchors[scene] = order[i % order.length];
      }
    }
    for (final MapEntry(key: scene, value: lead) in spec.followUps.entries) {
      final at = anchors[lead];
      if (at != null) anchors[scene] = at;
    }

    return {
      'seed': spec.seed,
      'sea': [for (final p in sea) p.toJson()],
      'rivers': [
        if (hasRiver) ...[
          {'width': 30, 'path': _json(river)},
          {'width': 16, 'path': _json(islandArmWest)},
          {'width': 16, 'path': _json(islandArmEast)},
        ],
      ],
      'islands': [if (hasRiver) _json(island)],
      'canals': [
        for (final cn in canals) {'width': 10, 'path': _json(cn)}
      ],
      'wall': {
        'runs': [for (final r in runs) _json(r)],
        'gates': spec.walled ? gates : const <Object?>[],
        'towers': _json(towers),
      },
      'avenues': [
        for (final av in avenues) {'width': 16, 'path': _json(av)}
      ],
      'streets': [
        for (final s in streets) {'width': 7, 'path': _json(s)}
      ],
      'bridges': bridges,
      'squares': squares,
      'districts': districts,
      'buildings': buildings,
      'anchors': anchors,
      'names': <String, Object?>{},
    };
  }

  // --- pieces ---------------------------------------------------------

  P _ringPointToward(List<P> ring, P c, double angle) {
    var best = ring.first;
    var bestD = double.infinity;
    for (final p in ring) {
      final a = math.atan2(p.y - c.y, p.x - c.x);
      final d = _angleGap(a, angle);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  List<List<P>> _wallRuns(List<P> ring, List<P> gates) {
    final runs = <List<P>>[];
    var run = <P>[];
    for (var i = 0; i <= ring.length; i++) {
      final p = ring[i % ring.length];
      final open = p.y > shoreAt(p.x) - 24 ||
          (hasRiver && (p.x - riverAt(p.y).x).abs() < 26) ||
          gates.any((g) => g.dist(p) < 1);
      if (open) {
        if (run.length > 1) runs.add(run);
        run = gates.any((g) => g.dist(p) < 1) ? [p] : <P>[];
      } else {
        run.add(p);
      }
    }
    if (run.length > 1) runs.add(run);
    return runs;
  }

  Map<String, Object?> _square(
      String id, String kind, P at, double rx, double ry,
      {int sides = 9}) {
    return {
      'id': id,
      'kind': kind,
      'shape': [
        for (var i = 0; i < sides; i++)
          () {
            final a = i / sides * 2 * math.pi;
            final r = kind == 'arena' ? 1.0 : 1 + 0.15 * noise(a * 90, 9);
            return (at + P(math.cos(a) * rx * r, math.sin(a) * ry * r))
                .toJson();
          }(),
      ],
    };
  }

  List<P> _wobblyLine(P a, P b) {
    const steps = 6;
    final d = b - a;
    final len = d.length;
    final nx = -d.y / len, ny = d.x / len;
    return [
      for (var i = 0; i <= steps; i++)
        () {
          final t = i / steps;
          final w = (i == 0 || i == steps)
              ? 0.0
              : 14 * noise(a.x + b.x + i * 37, a.y + b.y);
          return a + d * t + P(nx * w, ny * w);
        }(),
    ];
  }

  List<P> _outsideShape(DistrictSeed d, List<P> ring) {
    // A strip of shore outside the wall: from the seed west, east up to
    // where the wall comes down to the water.
    var east = d.at.x + 160;
    for (final p in ring) {
      if (p.y > shoreAt(p.x) - 160 && p.x > d.at.x) {
        east = math.min(east, p.x - 14);
      }
    }
    final west = d.at.x - 130;
    final pts = <P>[];
    for (var x = west; x <= east; x += 20) {
      pts.add(P(x, shoreAt(x) - 6));
    }
    pts.add(P(east, shoreAt(east) - 6));
    for (var x = east; x >= west; x -= 20) {
      pts.add(P(x, shoreAt(x) - 120 - 14 * noise(x, 21)));
    }
    return pts;
  }

  /// [cell] cut to the side of the bisector of [a] and [b] that holds [a].
  List<P> _clipHalf(List<P> cell, P a, P b) {
    final m = (a + b) * 0.5;
    final n = b - a;
    double side(P p) => (p.x - m.x) * n.x + (p.y - m.y) * n.y;
    final out = <P>[];
    for (var i = 0; i < cell.length; i++) {
      final p = cell[i], q = cell[(i + 1) % cell.length];
      final sp = side(p), sq = side(q);
      if (sp <= 0) out.add(p);
      if ((sp <= 0) != (sq <= 0)) {
        final t = sp / (sp - sq);
        out.add(p + (q - p) * t);
      }
    }
    return out;
  }

  /// Every edge broken in two with its middle pushed aside by a wobble
  /// that depends only on the edge's ends, so the district on the other
  /// side of it bends the same way.
  List<P> _wobble(List<P> poly) {
    final out = <P>[];
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i], b = poly[(i + 1) % poly.length];
      out.add(a);
      final d = b - a;
      final len = d.length;
      if (len < 40) continue;
      // Symmetric in a and b: the same push from either side.
      final lo = (a.x + a.y) < (b.x + b.y) ? a : b;
      final hi = identical(lo, a) ? b : a;
      final dir = hi - lo;
      final w = 0.12 * len * noise(lo.x * 3 + hi.x, lo.y * 3 + hi.y);
      final mid = (a + b) * 0.5 + P(-dir.y / len * w, dir.x / len * w);
      out.add(mid);
    }
    return out;
  }

  List<P> _scatter(List<P> shape, double spacing) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in shape) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
    }
    final out = <P>[];
    for (var y = minY; y <= maxY; y += spacing) {
      for (var x = minX; x <= maxX; x += spacing) {
        final p = P(x + (rnd.nextDouble() - 0.5) * spacing * 0.7,
            y + (rnd.nextDouble() - 0.5) * spacing * 0.7);
        if (_inside(p, shape)) out.add(p);
      }
    }
    return out;
  }

  Iterable<(P, double)> _crossings(List<P> a, List<P> b) sync* {
    for (var i = 1; i < a.length; i++) {
      for (var j = 1; j < b.length; j++) {
        final hit = _segHit(a[i - 1], a[i], b[j - 1], b[j]);
        if (hit != null) {
          final d = a[i] - a[i - 1];
          yield (hit, math.atan2(d.y, d.x));
        }
      }
    }
  }

  P? _nearestOnPaths(P p, List<List<P>> paths) {
    P? best;
    var bestD = double.infinity;
    for (final path in paths) {
      for (var i = 1; i < path.length; i++) {
        final q = _closest(p, path[i - 1], path[i]);
        final d = q.dist(p);
        if (d < bestD) {
          bestD = d;
          best = q;
        }
      }
    }
    return best;
  }
}

// --- shared geometry --------------------------------------------------

List<List<int>> _json(List<P> pts) => [for (final p in pts) p.toJson()];

P _pt(Object? raw) {
  final l = (raw as List).cast<num>();
  return P(l[0].toDouble(), l[1].toDouble());
}

double _angleGap(double a, double b) {
  var d = (a - b) % (2 * math.pi);
  if (d < 0) d += 2 * math.pi;
  return math.min(d, 2 * math.pi - d);
}

P _closest(P p, P a, P b) {
  final ab = b - a;
  final len2 = ab.x * ab.x + ab.y * ab.y;
  if (len2 == 0) return a;
  final t = (((p - a).x * ab.x + (p - a).y * ab.y) / len2).clamp(0.0, 1.0);
  return a + ab * t;
}

bool _nearPath(P p, List<P> path, double r) {
  for (var i = 1; i < path.length; i++) {
    if (_closest(p, path[i - 1], path[i]).dist(p) < r) return true;
  }
  return false;
}

P? _segHit(P p, P p2, P q, P q2) {
  final r = p2 - p, s = q2 - q;
  final denom = r.x * s.y - r.y * s.x;
  if (denom.abs() < 1e-9) return null;
  final qp = q - p;
  final t = (qp.x * s.y - qp.y * s.x) / denom;
  final u = (qp.x * r.y - qp.y * r.x) / denom;
  if (t < 0 || t > 1 || u < 0 || u > 1) return null;
  return p + r * t;
}

bool _inside(P p, List<P> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.y > p.y) != (b.y > p.y) &&
        p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

double _area(List<P> poly) {
  var s = 0.0;
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i], b = poly[(i + 1) % poly.length];
    s += a.x * b.y - b.x * a.y;
  }
  return s.abs() / 2;
}

P _centroid(List<P> poly) {
  var x = 0.0, y = 0.0;
  for (final p in poly) {
    x += p.x;
    y += p.y;
  }
  return P(x / poly.length, y / poly.length);
}

List<P> _shrink(List<P> poly, double k) {
  final c = _centroid(poly);
  return [for (final p in poly) c + (p - c) * k];
}

/// The order a district's buildings take the scenes set in it: its halls
/// and temples first, then the rest, each nearest the district's label
/// first; the same in the generator and at play (city_plan_record.dart).
List<String> anchorOrder(List<Map<String, Object?>> buildings,
    Map<String, Map<String, Object?>> districts, String district) {
  final label = districts[district]?['label'];
  if (label == null) return const [];
  final at = _pt(label);
  int rank(String kind) => kind == 'hall' || kind == 'temple' ? 0 : 1;
  final own = [
    for (final b in buildings)
      if (b['district'] == district) b
  ];
  P mid(Map<String, Object?> b) =>
      _centroid([for (final q in (b['shape'] as List)) _pt(q)]);
  own.sort((a, b) {
    final r = rank(a['kind'] as String).compareTo(rank(b['kind'] as String));
    if (r != 0) return r;
    final d = mid(a).dist(at).compareTo(mid(b).dist(at));
    return d != 0 ? d : (a['id'] as String).compareTo(b['id'] as String);
  });
  return [for (final b in own) b['id'] as String];
}
