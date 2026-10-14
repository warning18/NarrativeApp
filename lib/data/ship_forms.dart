import 'dart:math' as math;
import 'dart:ui' show Offset, Path;

/// The Eel's hulls (ships.json), v1.228: what a hull looks like from above
/// -- its outline, its masts and the way each is rigged -- read off its
/// record. The sea fight draws the player's hull from this (see
/// TopShipPainter); the Harbor rebuilds her on another one.
enum HullKind {
  /// An ordinary hull.
  hull,

  /// Two slender hulls under one deck.
  twin,

  /// Plate and funnels, no sail.
  iron,

  /// A flying boat: twin gasbags on outriggers, a boiler and a screw.
  gasbag,

  /// A flying boat: rigid bat-wing sails and a furnace.
  batwing,

  /// A flying boat: iron and stone held up by lodestones.
  lodestone,

  /// A flying boat rowed on bone wings.
  bone,
}

HullKind hullKindFrom(Object? name) {
  for (final kind in HullKind.values) {
    if (kind.name == name) return kind;
  }
  return HullKind.hull;
}

/// How a mast is rigged, seen from above.
enum SailKind {
  /// Across the ship, bellied forward.
  square,

  /// Fore-and-aft, a long sail aft of its mast.
  gaff,

  /// A long slanting triangle.
  lateen,
}

SailKind sailKindFrom(Object? name) {
  for (final kind in SailKind.values) {
    if (kind.name == name) return kind;
  }
  return SailKind.square;
}

/// One mast: how it is rigged, where it stands along the hull (0 stern to
/// 1 bow) and how big its sail is, against the beam.
class ShipMast {
  const ShipMast(this.kind, this.at, this.size);
  final SailKind kind;
  final double at;
  final double size;
}

/// A hull's outline and rig, read off its ships.json record.
class ShipForm {
  const ShipForm({
    required this.id,
    required this.kind,
    required this.length,
    required this.beam,
    required this.u0,
    required this.a,
    required this.b,
    required this.tipw,
    required this.bowtip,
    required this.masts,
    required this.jibs,
    required this.oars,
    required this.castles,
    required this.beak,
    required this.flying,
  });

  factory ShipForm.fromRecord(String id, Map<String, dynamic> record) {
    final outline = (record['outline'] as Map?) ?? const {};
    double d(String key, double fallback) =>
        (outline[key] as num?)?.toDouble() ?? fallback;
    return ShipForm(
      id: id,
      kind: hullKindFrom(record['kind']),
      length: (record['length'] as num?)?.toDouble() ?? 1.0,
      beam: (record['beam'] as num?)?.toDouble() ?? 0.24,
      u0: d('u0', 0.5),
      a: d('a', 2.2),
      b: d('b', 1.7),
      tipw: d('tipw', 0.3),
      bowtip: d('bowtip', 0.0),
      masts: [
        for (final raw in (record['sailPlan'] as List?) ?? const [])
          if (raw is Map)
            ShipMast(
              sailKindFrom(raw['kind']),
              (raw['at'] as num?)?.toDouble() ?? 0.5,
              (raw['size'] as num?)?.toDouble() ?? 1.0,
            ),
      ],
      jibs: (record['jibs'] as num?)?.toInt() ?? 0,
      oars: (record['oars'] as num?)?.toInt() ?? 0,
      castles: [
        for (final raw in (record['castles'] as List?) ?? const [])
          if (raw is List && raw.length == 2)
            (
              (raw[0] as num).toDouble(),
              (raw[1] as num).toDouble(),
            ),
      ],
      beak: record['beak'] == true,
      flying: record['flying'] == true,
    );
  }

  final String id;
  final HullKind kind;

  /// Its drawn length of the box's width, and its beam of the box's width.
  final double length;
  final double beam;

  /// The outline: where the hull is widest (0 stern to 1 bow), how full the
  /// stern and the bow are (1 is a point, higher is blunter), and how wide
  /// the transom and the stem are, of the beam.
  final double u0, a, b, tipw, bowtip;
  final List<ShipMast> masts;
  final int jibs;
  final int oars;

  /// Raised stern and bow decks, as (from, to) along the hull.
  final List<(double, double)> castles;

  /// A long beak and a spritsail at the bow (a galleon).
  final bool beak;
  final bool flying;

  bool get sails => masts.isNotEmpty;

  /// The hull's half width at [u] (0 stern to 1 bow), of the full beam.
  double widthAt(double u) {
    if (u <= u0) {
      final t = (u0 - u) / u0;
      return tipw + (1 - tipw) * math.pow(1 - math.pow(t, a), 1 / a).toDouble();
    }
    final t = (u - u0) / (1 - u0);
    return bowtip +
        (1 - bowtip) * math.pow(1 - math.pow(t, b), 1 / b).toDouble();
  }

  /// The hull's outline for a ship [len] long from [x0], [beam] wide at
  /// [cy], scaled by [scale] across and from [from] to [to] along it.
  Path outline(double x0, double cy, double len, double beam,
      {double scale = 1.0, double from = 0.0, double to = 1.0, int n = 48}) {
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = from + (to - from) * i / n;
      final w = widthAt(u) * beam / 2 * scale;
      top.add(Offset(x0 + u * len, cy - w));
      bottom.add(Offset(x0 + u * len, cy + w));
    }
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in bottom.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}

/// The hull ids in the order the Harbor lists them: the cheapest first,
/// the flying boats last.
List<String> hullIdsInOrder(Map<String, dynamic> ships) {
  final ids = ships.keys.toList();
  int cost(String id) =>
      ((ships[id] as Map<String, dynamic>)['hullCost'] as num?)?.toInt() ?? 0;
  bool flying(String id) =>
      (ships[id] as Map<String, dynamic>)['flying'] == true;
  ids.sort((x, y) {
    if (flying(x) != flying(y)) return flying(x) ? 1 : -1;
    return cost(x).compareTo(cost(y));
  });
  return ids;
}

/// The hull of the player's ship: the record [hullId] names, else the Rusty
/// Eel's own, else the first on file.
Map<String, dynamic>? hullRecordOf(Map<String, dynamic> ships, String hullId) {
  final id = ships.containsKey(hullId)
      ? hullId
      : (ships.containsKey(defaultHullId)
          ? defaultHullId
          : (ships.keys.isEmpty ? null : ships.keys.first));
  return id == null ? null : ships[id] as Map<String, dynamic>?;
}

/// The hull the Eel starts on.
const String defaultHullId = 'rusty_eel';

/// Whether the shipwright builds [hull] yet: from its chapter on (or when it
/// is already owned).
bool hullUnlocked(Map<String, dynamic> hull, int chapter, bool owned) =>
    owned || ((hull['unlockChapter'] as num?)?.toInt() ?? 0) <= chapter;
