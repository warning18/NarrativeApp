// A city drawn as a real old city (v1.308): crooked blocks cut into lots, a
// river with an island and bridges, canals, a star of avenues, an arena,
// squares, a wall -- seen from above, in the Map look's chart colours. This
// file is the plan as the painter reads it; city_chart_painter.dart draws
// it and city_chart_view.dart lets the player zoom in and out of it.
//
// The record is plain JSON (see docs/proposals/city-chart.md for its shape).
// Until the game's own per-city records land, Saltmouth's comes from a stub
// generated offline (assets/visuals/city/saltmouth_stub.json).
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../data/city_plan_record.dart';

/// What a way does, as the pin on its building says it.
enum CityWayKind { quest, fight, check, shop, road }

CityWayKind _wayKind(String raw) => switch (raw) {
      'quest' => CityWayKind.quest,
      'fight' => CityWayKind.fight,
      'check' => CityWayKind.check,
      'shop' => CityWayKind.shop,
      _ => CityWayKind.road,
    };

/// A district: a quarter of the city with its own colour and ambiance.
class CityChartDistrict {
  const CityChartDistrict({
    required this.id,
    required this.name,
    required this.colour,
    required this.blocks,
    required this.lots,
    required this.ridges,
    required this.box,
    required this.centre,
  });

  final String id;
  final String name;
  final Color colour;

  /// The district's blocks, merged: what the wash and the fog cover.
  final Path blocks;

  /// Every house lot of the district as one path, and the ridge lines of
  /// their roofs as another (drawn only when zoomed in).
  final Path lots;
  final Path ridges;

  /// The view that frames the district, in plan units.
  final Rect box;

  /// Where its name and mark sit.
  final Offset centre;
}

/// A building the story stands at.
class CityChartBuilding {
  const CityChartBuilding({
    required this.key,
    required this.district,
    required this.name,
    required this.shape,
    required this.round,
    required this.quiet,
    required this.at,
    required this.ridge,
    this.story = true,
  });

  final String key;

  /// Drawn as one of the buildings the story stands at (a hall, a temple,
  /// one a way is pinned on); the rest are only houses of the district's
  /// lots.
  final bool story;

  /// Index into [CityChart.districts].
  final int district;
  final String name;
  final Path shape;
  final bool round;

  /// A spot (a notice board, a slip) rather than a house: no roof, no name.
  final bool quiet;
  final Offset at;
  final (Offset, Offset) ridge;
}

/// A way of the story, pinned on a building.
class CityChartWay {
  const CityChartWay({
    required this.id,
    required this.district,
    required this.kind,
    required this.name,
    required this.building,
  });

  final String id;
  final int district;
  final CityWayKind kind;
  final String name;

  /// The building's key.
  final String building;
}

/// A service of the town pinned on its plan (wave 14): a notice board, the
/// market, a tavern, a temple, a forge, a harbour. Fixed, not a way of the
/// story; its [opens] says whether anything opens there yet.
class CityChartService {
  const CityChartService({
    required this.id,
    required this.kind,
    required this.at,
    required this.district,
    this.opens = true,
  });

  final String id;

  /// notice_board, market, tavern, temple, forge or harbour.
  final String kind;

  /// On the plan, in the plan's own units.
  final Offset at;

  /// The district's id.
  final String district;
  final bool opens;
}

/// A line of the plan with its width: a river, a canal, an avenue, a street.
class CityChartStroke {
  const CityChartStroke(this.path, this.width, {this.main = false});
  final Path path;
  final double width;

  /// An avenue (the star from the gates and the market) rather than a lane.
  final bool main;
}

/// A way to pin on a city chart, as the host reads it from the story: its
/// own id, the district it stands in, what it is, what it is called and
/// the scene it leads to (the plan's anchors are keyed by it).
class CityWayInput {
  const CityWayInput({
    required this.id,
    required this.districtId,
    required this.kind,
    required this.name,
    required this.sceneId,
  });

  final String id;
  final String districtId;
  final CityWayKind kind;
  final String name;
  final String sceneId;
}

class CityChart {
  CityChart._({
    required this.name,
    required this.width,
    required this.height,
    required this.sea,
    required this.ground,
    required this.wall,
    required this.towers,
    required this.avenues,
    required this.squares,
    required this.water,
    required this.bridges,
    required this.arena,
    required this.arenaInner,
    required this.districts,
    required this.buildings,
    required this.ways,
    required this.lanterns,
    required this.stalls,
    required this.boats,
    required this.trees,
    required this.piers,
    this.waterways = const [],
    this.roads = const [],
    this.islands,
  });

  final String name;
  final double width;
  final double height;

  Rect get bounds => Rect.fromLTWH(0, 0, width, height);

  final Path sea;
  final Path ground;
  final Path wall;
  final List<Offset> towers;
  final Path avenues;
  final Path squares;
  final Path water;
  final Path bridges;
  final Path arena;
  final Path arenaInner;
  final List<CityChartDistrict> districts;
  final List<CityChartBuilding> buildings;
  final List<CityChartWay> ways;
  final List<Offset> lanterns;
  final List<Offset> stalls;
  final List<(Offset, double)> boats;
  final List<Offset> trees;
  final List<Rect> piers;

  /// Rivers, canals, avenues and streets drawn as lines (a record gives them
  /// so; the stub gives them as shapes above).
  final List<CityChartStroke> waterways;
  final List<CityChartStroke> roads;

  /// Islands in the water, drawn over it.
  final Path? islands;

  CityChartDistrict? districtById(String id) {
    for (final d in districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  CityChartBuilding? buildingOf(CityChartWay way) {
    for (final b in buildings) {
      if (b.key == way.building) return b;
    }
    return null;
  }

  /// The ways pinned in district [id].
  List<CityChartWay> waysIn(String id) => [
        for (final w in ways)
          if (districts[w.district].id == id) w,
      ];

  static Future<CityChart> load(AssetBundle bundle, String asset) async =>
      CityChart.fromJson(
          jsonDecode(await bundle.loadString(asset)) as Map<String, dynamic>);

  /// The colours the districts wear, in the order the plan lists them.
  static const List<Color> districtColours = [
    Color(0xFF7FA6D8),
    Color(0xFFE8B94E),
    Color(0xFF3FB8B0),
    Color(0xFFD98A3C),
    Color(0xFFD9544D),
    Color(0xFF9A6BFF),
    Color(0xFF6BBF59),
    Color(0xFFC77DBA),
  ];

  /// The chart of a stored city plan (see city_plan_record.dart), with the
  /// names the districts go by ([districtNames], by geography id) and the
  /// [ways] the story gives: each is pinned on the building its scene is
  /// anchored to. A building a way is pinned on, and every hall and temple,
  /// is drawn as itself; the rest are the houses of the district's lots.
  factory CityChart.fromRecord(
    CityPlanRecord record, {
    required Map<String, String> districtNames,
    List<CityWayInput> ways = const [],
    bool french = false,
    String name = '',
  }) {
    Path polygon(List<Offset> pts, [Path? into]) {
      final path = into ?? Path();
      if (pts.length < 3) return path;
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    Path line(List<Offset> pts, [Path? into]) {
      final path = into ?? Path();
      if (pts.length < 2) return path;
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    final ids = record.districts.keys.toList();
    final index = {for (final (i, id) in ids.indexed) id: i};

    // The ways, each on its building.
    final pinned = <String, String>{};
    final chartWays = <CityChartWay>[];
    for (final w in ways) {
      final d = index[w.districtId];
      if (d == null) continue;
      final b = record.buildingOfWay(w.sceneId, w.districtId);
      if (b == null) continue;
      pinned[b.id] = w.name;
      chartWays.add(CityChartWay(
          id: w.id, district: d, kind: w.kind, name: w.name, building: b.id));
    }

    // The buildings: the story's own, and the lots of the rest.
    final lots = List.generate(ids.length, (_) => Path());
    final ridges = List.generate(ids.length, (_) => Path());
    final buildings = <CityChartBuilding>[];
    for (final b in record.buildings) {
      final d = index[b.district];
      if (d == null || b.shape.length < 3) continue;
      final story = b.notable || pinned.containsKey(b.id);
      final ridge = _ridgeOf(b.shape);
      if (!story) {
        polygon(b.shape, lots[d]);
        ridges[d]
          ..moveTo(ridge.$1.dx, ridge.$1.dy)
          ..lineTo(ridge.$2.dx, ridge.$2.dy);
      }
      final written = record.nameOf(b.id, french: french);
      buildings.add(CityChartBuilding(
        key: b.id,
        district: d,
        name: written.isNotEmpty ? written : (pinned[b.id] ?? ''),
        shape: polygon(b.shape),
        round: false,
        quiet: false,
        at: b.centre,
        ridge: ridge,
        story: story,
      ));
    }

    final districts = <CityChartDistrict>[
      for (final (i, id) in ids.indexed)
        () {
          final shape = record.districts[id]!;
          final path = polygon(shape.shape);
          var box = path.getBounds().inflate(14);
          // Never a sliver: at least a block or two across.
          final cx = box.center.dx, cy = box.center.dy;
          final hw = math.max(box.width / 2, 90.0);
          final hh = math.max(box.height / 2, 90.0);
          box = Rect.fromLTRB(cx - hw, cy - hh, cx + hw, cy + hh);
          return CityChartDistrict(
            id: id,
            name: districtNames[id] ?? id,
            colour: districtColours[i % districtColours.length],
            blocks: path,
            lots: lots[i],
            ridges: ridges[i],
            box: box,
            centre: shape.label,
          );
        }(),
    ];

    // The ground inside the town: the districts together.
    var ground = Path();
    for (final d in districts) {
      ground = Path.combine(PathOperation.union, ground, d.blocks);
    }

    final bridges = Path();
    for (final b in record.bridges) {
      final a = b.angleDegrees * math.pi / 180;
      final m = Matrix4.identity()
        ..translateByDouble(b.at.dx, b.at.dy, 0, 1)
        ..rotateZ(a);
      bridges.addPath(
          Path()
            ..addRect(Rect.fromCenter(
                center: Offset.zero, width: b.length, height: 13)),
          Offset.zero,
          matrix4: m.storage);
    }

    var islands = Path();
    for (final i in record.islands) {
      polygon(i, islands);
    }

    // Squares: the arena is a ring of stone round a sand floor; the others
    // are open ground.
    final squares = Path();
    var arena = Path(), arenaInner = Path();
    for (final sq in record.squares) {
      if (sq.kind == 'arena') {
        arena = polygon(sq.shape);
        final c = sq.centre;
        arenaInner = polygon([
          for (final p in sq.shape) c + (p - c) * 0.62,
        ]);
      } else {
        polygon(sq.shape, squares);
      }
    }

    final wall = Path();
    for (final run in record.wallRuns) {
      line(run, wall);
    }

    return CityChart._(
      name: name,
      width: CityPlanRecord.bounds.width,
      height: CityPlanRecord.bounds.height,
      sea: polygon(record.sea),
      ground: ground,
      wall: wall,
      towers: record.towers,
      avenues: Path(),
      squares: squares,
      water: Path(),
      bridges: bridges,
      arena: arena,
      arenaInner: arenaInner,
      districts: districts,
      buildings: buildings,
      ways: chartWays,
      lanterns: const [],
      stalls: const [],
      boats: const [],
      trees: const [],
      piers: const [],
      waterways: [
        for (final r in [...record.rivers, ...record.canals])
          CityChartStroke(line(r.points), r.width),
      ],
      roads: [
        for (final r in record.streets)
          CityChartStroke(line(r.points), r.width),
        for (final r in record.avenues)
          CityChartStroke(line(r.points), r.width, main: true),
      ],
      islands: islands,
    );
  }

  /// The roof's ridge: a line through the middle along the longer side.
  static (Offset, Offset) _ridgeOf(List<Offset> poly) {
    var best = 0.0;
    var a = poly.first, b = poly.last;
    for (var i = 0; i < poly.length; i++) {
      final p = poly[i], q = poly[(i + 1) % poly.length];
      final d = (q - p).distance;
      if (d > best) {
        best = d;
        a = p;
        b = q;
      }
    }
    final c = polygonCentre(poly);
    final dir = (b - a) / math.max(best, 0.001);
    final half = best / 2;
    return (c - dir * half, c + dir * half);
  }

  static const String saltmouthStub = 'assets/visuals/city/saltmouth_stub.json';

  factory CityChart.fromJson(Map<String, dynamic> j) {
    List<double> nums(Object? raw) =>
        [for (final v in raw as List) (v as num).toDouble()];
    Path ringPath(Path p, List<double> flat) {
      if (flat.length < 6) return p;
      p.moveTo(flat[0], flat[1]);
      for (var i = 2; i + 1 < flat.length; i += 2) {
        p.lineTo(flat[i], flat[i + 1]);
      }
      p.close();
      return p;
    }

    // Rings fill even-odd: the island is a hole in the river.
    Path shape(Object? raw) {
      final p = Path()..fillType = PathFillType.evenOdd;
      for (final r in (raw as List? ?? const [])) {
        ringPath(p, nums(r));
      }
      return p;
    }

    Offset pt(Object? raw) {
      final n = nums(raw);
      return Offset(n[0], n[1]);
    }

    Color hex(String s) =>
        Color(0xFF000000 | int.parse(s.substring(1), radix: 16));

    final raw = (j['districts'] as List).cast<Map<String, dynamic>>();
    final lotsBy = List.generate(raw.length, (_) => Path());
    final ridgesBy = List.generate(raw.length, (_) => Path());
    for (final l in (j['lots'] as List).cast<Map<String, dynamic>>()) {
      final d = l['d'] as int;
      ringPath(lotsBy[d], nums(l['r']));
      final g = nums(l['g']);
      ridgesBy[d]
        ..moveTo(g[0], g[1])
        ..lineTo(g[2], g[3]);
    }

    final buildings = [
      for (final b in (j['buildings'] as List).cast<Map<String, dynamic>>())
        CityChartBuilding(
          key: b['key'] as String,
          district: b['d'] as int,
          name: b['name'] as String,
          shape: ringPath(Path(), nums(b['r'])),
          round: b['round'] as bool,
          quiet: b['quiet'] as bool,
          at: pt(b['at']),
          ridge: () {
            final g = nums(b['g']);
            return (Offset(g[0], g[1]), Offset(g[2], g[3]));
          }(),
        ),
    ];

    // A district's frame: its buildings the story stands at, with a margin.
    final districts = <CityChartDistrict>[];
    for (var i = 0; i < raw.length; i++) {
      final d = raw[i];
      final at = [
        for (final b in buildings)
          if (b.district == i) b.at,
      ];
      final seed = pt(d['seed']);
      var x0 = seed.dx, x1 = seed.dx, y0 = seed.dy, y1 = seed.dy;
      for (final a in at) {
        x0 = a.dx < x0 ? a.dx : x0;
        x1 = a.dx > x1 ? a.dx : x1;
        y0 = a.dy < y0 ? a.dy : y0;
        y1 = a.dy > y1 ? a.dy : y1;
      }
      final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
      final hw = ((x1 - x0) / 2 + 44).clamp(95.0, 400.0);
      final hh = ((y1 - y0) / 2 + 44).clamp(95.0, 400.0);
      districts.add(CityChartDistrict(
        id: d['id'] as String,
        name: d['name'] as String,
        colour: hex(d['colour'] as String),
        blocks: shape(d['blocks']),
        lots: lotsBy[i],
        ridges: ridgesBy[i],
        box: Rect.fromLTRB(cx - hw, cy - hh, cx + hw, cy + hh),
        centre: seed,
      ));
    }

    final marks = j['marks'] as Map<String, dynamic>;
    List<Offset> points(String k) => [for (final p in marks[k] as List) pt(p)];
    final wall = Path();
    final wallFlat = nums(j['wall']);
    wall.moveTo(wallFlat[0], wallFlat[1]);
    for (var i = 2; i + 1 < wallFlat.length; i += 2) {
      wall.lineTo(wallFlat[i], wallFlat[i + 1]);
    }
    wall.close();
    final arena = j['arena'] as List;
    return CityChart._(
      name: j['name'] as String,
      width: (j['w'] as num).toDouble(),
      height: (j['h'] as num).toDouble(),
      sea: shape(j['sea']),
      ground: shape(j['ground']),
      wall: wall,
      towers: [for (final t in j['towers'] as List) pt(t)],
      avenues: shape(j['avenues']),
      squares: shape(j['squares']),
      water: shape(j['water']),
      bridges: shape(j['bridges']),
      arena: ringPath(Path(), nums(arena[0])),
      arenaInner: ringPath(Path(), nums(arena[1])),
      districts: districts,
      buildings: buildings,
      ways: [
        for (final w in (j['ways'] as List).cast<Map<String, dynamic>>())
          CityChartWay(
            id: w['id'] as String,
            district: w['d'] as int,
            kind: _wayKind(w['kind'] as String),
            name: w['name'] as String,
            building: w['at'] as String,
          ),
      ],
      lanterns: points('lanterns'),
      stalls: points('stalls'),
      boats: [
        for (final b in marks['boats'] as List)
          (pt(b), ((b as List)[2] as num).toDouble()),
      ],
      trees: points('trees'),
      piers: [
        for (final p in marks['piers'] as List)
          Rect.fromLTWH((p as List)[0].toDouble(), p[1].toDouble(),
              p[2].toDouble(), (p[3] as num).toDouble()),
      ],
    );
  }
}
