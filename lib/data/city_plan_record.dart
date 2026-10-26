// A city's plan as stored (board 15, docs/proposals/city-plan-record.md):
// assets/gamedata/city_plans.json, laid out by city_plan_generator.dart.
// Typed for the painter (every polygon and path a list of Offsets in the
// plan's 1000 x 1000 square, y down), and a PlacePlan for the Journey: where
// each district's entry is, which building each way's pin stands on, and how
// to walk between two points along the avenues and streets.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'place_plan.dart';

List<Offset> _points(Object? raw) => [
      for (final p in (raw as List? ?? const []))
        if (p is List && p.length >= 2)
          Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];

Offset _point(Object? raw) {
  final pts = _points([raw]);
  return pts.isEmpty ? Offset.zero : pts.single;
}

/// A line of the plan with its width: a river, a canal, an avenue, a street.
class CityPath {
  const CityPath(this.points, this.width);

  factory CityPath.fromJson(Object? raw) {
    final map = raw is Map ? raw : const {};
    return CityPath(
        _points(map['path']), (map['width'] as num?)?.toDouble() ?? 6);
  }

  final List<Offset> points;
  final double width;
}

class CityGate {
  const CityGate(this.id, this.at);
  final String id;
  final Offset at;
}

class CityBridge {
  const CityBridge(this.at, this.angleDegrees, this.length);
  final Offset at;

  /// Along the bridge, in degrees (0 east, y down).
  final double angleDegrees;
  final double length;
}

/// An open square: 'market', 'arena', 'plaza' or 'quay'.
class CitySquare {
  const CitySquare(this.id, this.kind, this.shape);
  final String id;
  final String kind;
  final List<Offset> shape;

  Offset get centre => polygonCentre(shape);
}

class CityDistrictShape {
  const CityDistrictShape(this.id, this.shape, this.label, this.entry);
  final String id;
  final List<Offset> shape;

  /// Where its name goes.
  final Offset label;

  /// Where the party stands when it walks in.
  final Offset entry;
}

/// A building on its lot: 'house', 'hall', 'temple', 'warehouse', 'stall'
/// or 'shed'.
class CityPlanBuilding {
  const CityPlanBuilding(this.id, this.district, this.kind, this.shape);
  final String id;
  final String district;
  final String kind;
  final List<Offset> shape;

  Offset get centre => polygonCentre(shape);

  /// A hall or a temple: where a way's pin goes first.
  bool get notable => kind == 'hall' || kind == 'temple';
}

/// One of a town's services pinned on its plan (wave 14, see
/// town_service_pins.dart): its [kind] (see townServiceKinds), where it
/// stands ([at], on a square or a lot of the record) and the district that
/// is in.
class CityServicePin {
  const CityServicePin(this.id, this.kind, this.at, this.district);
  final String id;
  final String kind;
  final Offset at;
  final String district;
}

/// One city's plan (see the file's header).
class CityPlanRecord implements PlacePlan {
  CityPlanRecord({
    required this.cityId,
    required this.seed,
    this.sea = const [],
    this.rivers = const [],
    this.islands = const [],
    this.canals = const [],
    this.wallRuns = const [],
    this.gates = const [],
    this.towers = const [],
    this.avenues = const [],
    this.streets = const [],
    this.bridges = const [],
    this.squares = const [],
    this.districts = const {},
    this.buildings = const [],
    this.anchors = const {},
    this.names = const {},
    this.services = const [],
  });

  factory CityPlanRecord.fromJson(String cityId, Map raw) {
    final wall = raw['wall'] is Map ? raw['wall'] as Map : const {};
    List<CityPath> paths(String key) =>
        [for (final p in (raw[key] as List? ?? const [])) CityPath.fromJson(p)];
    return CityPlanRecord(
      cityId: cityId,
      seed: (raw['seed'] as num?)?.toInt() ?? 0,
      sea: _points(raw['sea']),
      rivers: paths('rivers'),
      islands: [
        for (final i in (raw['islands'] as List? ?? const [])) _points(i)
      ],
      canals: paths('canals'),
      wallRuns: [
        for (final r in (wall['runs'] as List? ?? const [])) _points(r)
      ],
      gates: [
        for (final g in (wall['gates'] as List? ?? const []))
          if (g is Map) CityGate(g['id']?.toString() ?? '', _point(g['at']))
      ],
      towers: _points(wall['towers']),
      avenues: paths('avenues'),
      streets: paths('streets'),
      bridges: [
        for (final b in (raw['bridges'] as List? ?? const []))
          if (b is Map)
            CityBridge(_point(b['at']), (b['angle'] as num?)?.toDouble() ?? 0,
                (b['length'] as num?)?.toDouble() ?? 30)
      ],
      squares: [
        for (final s in (raw['squares'] as List? ?? const []))
          if (s is Map)
            CitySquare(s['id']?.toString() ?? '', s['kind']?.toString() ?? '',
                _points(s['shape']))
      ],
      districts: {
        for (final MapEntry(:key, :value)
            in ((raw['districts'] as Map?) ?? const {}).entries)
          if (value is Map)
            key.toString(): CityDistrictShape(
                key.toString(),
                _points(value['shape']),
                _point(value['label']),
                _point(value['entry'])),
      },
      buildings: [
        for (final b in (raw['buildings'] as List? ?? const []))
          if (b is Map)
            CityPlanBuilding(
                b['id']?.toString() ?? '',
                b['district']?.toString() ?? '',
                b['kind']?.toString() ?? 'house',
                _points(b['shape']))
      ],
      anchors: {
        for (final MapEntry(:key, :value)
            in ((raw['anchors'] as Map?) ?? const {}).entries)
          key.toString(): value.toString(),
      },
      names: {
        for (final MapEntry(:key, :value)
            in ((raw['names'] as Map?) ?? const {}).entries)
          if (value is Map)
            key.toString(): (
              en: value['en']?.toString() ?? '',
              fr: value['fr']?.toString() ?? ''
            ),
      },
      services: [
        for (final p in (raw['services'] as List? ?? const []))
          if (p is Map)
            CityServicePin(
              p['id']?.toString() ?? '',
              p['kind']?.toString() ?? '',
              _point(p['at']),
              p['district']?.toString() ?? '',
            ),
      ],
    );
  }

  /// The plan's own square.
  static const Rect bounds = Rect.fromLTWH(0, 0, 1000, 1000);

  final String cityId;
  final int seed;

  /// The water beyond the shore (empty inland).
  final List<Offset> sea;

  /// The river and its arms round an island.
  final List<CityPath> rivers;
  final List<List<Offset>> islands;
  final List<CityPath> canals;

  /// The wall, in runs: open at the gates, the river and the harbour.
  final List<List<Offset>> wallRuns;
  final List<CityGate> gates;
  final List<Offset> towers;
  final List<CityPath> avenues;
  final List<CityPath> streets;
  final List<CityBridge> bridges;
  final List<CitySquare> squares;

  /// Every district's shape, by its geography id.
  final Map<String, CityDistrictShape> districts;
  final List<CityPlanBuilding> buildings;

  /// The building each way's pin stands on, by the way's scene id (as laid
  /// out; see [buildingOfWay]).
  final Map<String, String> anchors;

  /// Narrative's names of the buildings, by building id.
  final Map<String, ({String en, String fr})> names;

  /// The town's services on the plan (the notice board, the market…), in
  /// the order of townServiceKinds; see town_services.dart for what each
  /// opens.
  final List<CityServicePin> services;

  late final Map<String, CityPlanBuilding> _byId = {
    for (final b in buildings) b.id: b,
  };

  CityPlanBuilding? building(String id) => _byId[id];

  /// [id]'s name in the chosen language ('' for none written).
  String nameOf(String buildingId, {required bool french}) {
    final n = names[buildingId];
    if (n == null) return '';
    return french && n.fr.isNotEmpty ? n.fr : n.en;
  }

  /// The district [p] lies in, or null (outside the town).
  String? districtAt(Offset p) {
    for (final d in districts.values) {
      if (pointInPolygonOffsets(p, d.shape)) return d.id;
    }
    return null;
  }

  /// The order [districtId]'s buildings take ways: halls and temples
  /// first, then the rest, each nearest the district's label first (as
  /// city_plan_generator.dart's anchorOrder).
  List<CityPlanBuilding> anchorOrder(String districtId) {
    final d = districts[districtId];
    if (d == null) return const [];
    final own = [
      for (final b in buildings)
        if (b.district == districtId) b
    ];
    own.sort((a, b) {
      final r = (a.notable ? 0 : 1).compareTo(b.notable ? 0 : 1);
      if (r != 0) return r;
      final c = (a.centre - d.label)
          .distance
          .compareTo((b.centre - d.label).distance);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return own;
  }

  /// The building the way to scene [sceneId] stands on in [districtId]:
  /// its own anchor when that lies in the district; else (a scene moved to
  /// another district since the plan was laid out) a building of that
  /// district no other way holds, picked by the scene's id so it is the same
  /// every time; null for a district not on the plan.
  CityPlanBuilding? buildingOfWay(String sceneId, String districtId) {
    final own = building(anchors[sceneId] ?? '');
    if (own != null && own.district == districtId) return own;
    final order = anchorOrder(districtId);
    if (order.isEmpty) return null;
    final held = anchors.values.toSet();
    final free = [
      for (final b in order)
        if (!held.contains(b.id)) b
    ];
    final pool = free.isEmpty ? order : free;
    return pool[_stableHash(sceneId) % pool.length];
  }

  // --- PlacePlan ------------------------------------------------------

  @override
  Rect get frame => bounds;

  /// A district's entry, a building's middle, or the market square's
  /// middle for '' (or anything not on the plan).
  @override
  Offset anchorOf(String id) {
    final d = districts[id];
    if (d != null) return d.entry;
    final b = building(id);
    if (b != null) return b.centre;
    for (final s in squares) {
      if (s.kind == 'market') return s.centre;
    }
    return bounds.center;
  }

  late final List<Offset> _nodes = [];
  late final List<List<(int, double)>> _edges = _buildGraph();

  List<List<(int, double)>> _buildGraph() {
    final edges = <List<(int, double)>>[];
    int add(Offset p) {
      for (var i = 0; i < _nodes.length; i++) {
        if ((_nodes[i] - p).distance < 6) return i;
      }
      _nodes.add(p);
      edges.add([]);
      return _nodes.length - 1;
    }

    for (final path in [...avenues, ...streets]) {
      for (var i = 1; i < path.points.length; i++) {
        final a = add(path.points[i - 1]), b = add(path.points[i]);
        final d = (_nodes[a] - _nodes[b]).distance;
        edges[a].add((b, d));
        edges[b].add((a, d));
      }
    }
    // Where a street ends near another path, it joins it.
    for (var i = 0; i < _nodes.length; i++) {
      for (var j = i + 1; j < _nodes.length; j++) {
        final d = (_nodes[i] - _nodes[j]).distance;
        if (d < 40 && !edges[i].any((e) => e.$1 == j)) {
          edges[i].add((j, d));
          edges[j].add((i, d));
        }
      }
    }
    return edges;
  }

  int _nearest(Offset p) {
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

  /// The walk from [from] to [to] along the avenues and streets (a shortest
  /// path over them), with both ends on it.
  @override
  List<Offset> route(Offset from, Offset to) {
    final edges = _edges;
    if (_nodes.isEmpty) return [from, to];
    final start = _nearest(from), goal = _nearest(to);
    final dist = List<double>.filled(_nodes.length, double.infinity);
    final prev = List<int>.filled(_nodes.length, -1);
    final done = List<bool>.filled(_nodes.length, false);
    dist[start] = 0;
    for (var round = 0; round < _nodes.length; round++) {
      var u = -1;
      for (var i = 0; i < _nodes.length; i++) {
        if (!done[i] && (u < 0 || dist[i] < dist[u])) u = i;
      }
      if (u < 0 || dist[u] == double.infinity || u == goal) break;
      done[u] = true;
      for (final (v, w) in edges[u]) {
        if (dist[u] + w < dist[v]) {
          dist[v] = dist[u] + w;
          prev[v] = u;
        }
      }
    }
    if (dist[goal] == double.infinity) return [from, to];
    final path = <Offset>[];
    for (var v = goal; v >= 0; v = prev[v]) {
      path.add(_nodes[v]);
    }
    return [from, ...path.reversed, to];
  }

  // --- Doorsteps (v1.543) ----------------------------------------------

  /// Points along every avenue and street, a few units apart.
  late final List<Offset> _streetSamples = [
    for (final path in [...avenues, ...streets])
      for (var i = 1; i < path.points.length; i++)
        for (var k = 0,
                n = math.max(
                    1,
                    ((path.points[i] - path.points[i - 1]).distance / 4)
                        .ceil());
            k < n;
            k++)
          Offset.lerp(path.points[i - 1], path.points[i], k / n)!,
  ];

  /// Where a scene that plays outside building [buildingId] stands (see
  /// GeoPlace.doorstep): the point of the streets nearest the building's
  /// middle, its door on the street; the building's middle when the plan
  /// has no street, and the market square's for a building not on it.
  Offset doorstepOf(String buildingId) {
    final b = building(buildingId);
    if (b == null) return anchorOf('');
    if (_streetSamples.isEmpty) return b.centre;
    var best = _streetSamples.first;
    for (final p in _streetSamples) {
      if ((p - b.centre).distanceSquared < (best - b.centre).distanceSquared) {
        best = p;
      }
    }
    return best;
  }

  /// [count] spots on the street round building [buildingId]'s doorstep,
  /// for the ways of a scene played outside it (v1.543): each at least
  /// [gap] from the doorstep and from one another, the nearest first, so
  /// the pins stand in the street around the door and not on one point.
  /// Where the streets near it give too few, the rest ring the doorstep.
  List<Offset> streetSpotsAround(String buildingId, int count,
      {double gap = 22}) {
    if (count <= 0) return const [];
    final door = doorstepOf(buildingId);
    final near = [
      for (final p in _streetSamples)
        if ((p - door).distance >= gap && (p - door).distance <= gap * 6) p
    ]..sort((a, b) =>
        (a - door).distanceSquared.compareTo((b - door).distanceSquared));
    final picked = <Offset>[];
    for (final p in near) {
      if (picked.length == count) break;
      if (picked.every((q) => (q - p).distance >= gap)) picked.add(p);
    }
    for (var k = 0; picked.length < count; k++) {
      final a = k * 2 * math.pi / math.max(count, 3);
      picked.add(door + Offset(math.cos(a), math.sin(a)) * gap * 1.5);
    }
    return picked;
  }
}

/// Every record of city_plans.json, by city id.
Map<String, CityPlanRecord> cityPlanRecordsFrom(Map<String, dynamic> raw) => {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is Map) key: CityPlanRecord.fromJson(key, value),
    };

/// The middle of [poly] (its points' mean).
Offset polygonCentre(List<Offset> poly) {
  if (poly.isEmpty) return Offset.zero;
  var x = 0.0, y = 0.0;
  for (final p in poly) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / poly.length, y / poly.length);
}

/// Whether [p] lies inside [poly] (even-odd).
bool pointInPolygonOffsets(Offset p, List<Offset> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

int _stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x3fffffff;
  }
  return math.max(0, h);
}
