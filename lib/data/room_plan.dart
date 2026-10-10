// The inside of a building drawn (v1.207): the rooms, their walls and
// doors, what stands in them, and the named spots the story puts the
// party and its ways at (the bar, the tables, the cage, the back door).
// Laid out from the building's kind and a seed, in the plan's own units
// (a 1000 x 1000 square), the same on every visit; the painter scales it
// to the map.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'place_plan.dart';

/// What a building is, as geography.json gives it (see geoBuildingKinds).
enum RoomKind {
  den,
  tavern,
  inn,
  house,
  hall,
  keep,
  temple,
  shop,
  warehouse,
  cellar,
  cave,
  tower,
  casino,
  barracks,
  library,
  prison,
  forge,
  theatre,
  baths,
  plain;

  static RoomKind of(String kind) => switch (kind) {
        'den' => den,
        'tavern' => tavern,
        'inn' => inn,
        'house' => house,
        'hall' => hall,
        'keep' => keep,
        'temple' => temple,
        'shop' => shop,
        'warehouse' => warehouse,
        'cellar' => cellar,
        'cave' => cave,
        'tower' => tower,
        'casino' => casino,
        'barracks' => barracks,
        'library' => library,
        'prison' => prison,
        'forge' => forge,
        'theatre' => theatre,
        'baths' => baths,
        _ => plain,
      };

  /// What a building's name says it is (v1.210): a 'Gilded Casino' is laid
  /// as a casino, 'North Barracks' as barracks, 'Saint Orla's Chapel' as a
  /// temple. The name decides when it holds one of these words (English or
  /// French); otherwise the kind the geography gives stands.
  static String resolve(String kind, String name) {
    for (final (resolved, words) in _nameWords) {
      if (RegExp('(?<![\\p{L}])($words)', caseSensitive: false, unicode: true)
          .hasMatch(name)) {
        return resolved;
      }
    }
    return kind;
  }

  static const List<(String, String)> _nameWords = [
    (
      'casino',
      'casino|gambling|gaming house|dice(?![\\p{L}])|cards(?![\\p{L}])'
    ),
    ('barracks', 'barrack|caserne|garrison|guardhouse|watchhouse'),
    ('prison', 'prison|gaol|jail|dungeon|geôle|cachot|bridewell'),
    (
      'temple',
      'temple|church|chapel|cathedral|shrine|abbey|sanctuary|monastery|chapelle|église|eglise|cathédrale|abbaye'
    ),
    ('library', 'library|archive|scriptorium|biblioth'),
    ('forge', 'forge|smithy|smith(?![\\p{L}])|foundry|forgeron'),
    ('theatre', 'theatre|theater|playhouse|opera|théâtre'),
    ('baths', 'bathhouse|baths|thermae|hammam|bains'),
    ('tavern', 'tavern|taproom|alehouse|taverne'),
    ('inn', 'inn(?![\\p{L}])|hostel|lodge|auberge'),
    ('tower', 'tower|tour(?![\\p{L}])|belfry'),
    ('keep', 'keep(?![\\p{L}])|donjon|citadel'),
    ('warehouse', 'warehouse|granary|entrepôt|entrepot'),
    ('cellar', 'cellar|crypt|cave(?![\\p{L}])|cellier'),
    ('shop', 'shop|market|boutique|apothecary|bakery|boulangerie'),
  ];

  /// Rough ground, not a built floor.
  bool get rough => this == cave;

  /// A stone floor, not boards.
  bool get stone =>
      this == hall ||
      this == keep ||
      this == temple ||
      this == cellar ||
      this == tower ||
      this == barracks ||
      this == prison ||
      this == forge ||
      this == baths ||
      this == cave;
}

/// One room of the building.
class Room {
  const Room(this.id, this.rect);
  final String id;
  final Rect rect;
}

/// A door in a wall: where, which way it opens (radians, 0 east, y down,
/// pointing out of the building or into the next room), and its name
/// ('door' for the front door, 'back' for the back door).
class RoomDoor {
  const RoomDoor(this.id, this.at, this.angle, {this.width = 44});
  final String id;
  final Offset at;
  final double angle;
  final double width;
}

enum FurnitureKind {
  table,
  longTable,
  bar,
  hearth,
  bed,
  cask,
  crate,
  pillar,
  altar,
  pew,
  shelf,
  cage,
  stair,
  strongbox,
  dais,
  railing,
  rock,
  counter,
  wheel,
  stage,
  pool,
  anvil,
  rack,
  desk,
  bench,
}

class Furniture {
  const Furniture(this.kind, this.centre, this.size, {this.angle = 0});
  final FurnitureKind kind;
  final Offset centre;
  final Size size;
  final double angle;

  Rect get rect =>
      Rect.fromCenter(center: centre, width: size.width, height: size.height);
}

/// The plan of one building, kept once laid.
class RoomPlan implements PlacePlan {
  RoomPlan._({
    required this.seed,
    required this.kind,
    required this.rooms,
    required this.walls,
    required this.doors,
    required this.furniture,
    required this.anchors,
    required this.outline,
  });

  final int seed;
  final RoomKind kind;
  final List<Room> rooms;

  /// The inner walls, as segments (the outline is the outer wall).
  final List<(Offset, Offset)> walls;
  final List<RoomDoor> doors;
  final List<Furniture> furniture;

  /// Where each named spot is: 'floor' is the middle of the main room,
  /// 'door' the front door, 'back' the back door, and the rest what the
  /// kind has (the bar, the tables, the hearth, the altar…).
  final Map<String, Offset> anchors;

  /// The outer wall, a closed polygon.
  final List<Offset> outline;

  static const Rect bounds = Rect.fromLTWH(0, 0, 1000, 1000);

  @override
  Rect get frame {
    var r = outline.first & Size.zero;
    for (final p in outline) {
      r = r.expandToInclude(p & Size.zero);
    }
    return r.inflate(48);
  }

  @override
  Offset anchorOf(String id) =>
      anchors[id] ?? anchors[''] ?? anchors['floor'] ?? bounds.center;

  /// Whether [spot] is one of this plan's.
  bool has(String spot) => anchors.containsKey(spot);

  /// Which door a way out of the building takes from [spot]: the back
  /// door from the back rooms when there is one, else the front door.
  String exitFrom(String spot) {
    if (!has('back')) return 'door';
    final at = anchorOf(spot);
    final front = _roomAt(anchorOf('door'));
    return _roomAt(at) == front ? 'door' : 'back';
  }

  Room? _roomAt(Offset p) {
    for (final room in rooms) {
      if (room.rect.inflate(1).contains(p)) return room;
    }
    return null;
  }

  /// Straight across a room; through the doorway between two rooms.
  @override
  List<Offset> route(Offset from, Offset to) {
    final a = _roomAt(from), b = _roomAt(to);
    if (a == null || b == null || a == b) return [from, to];
    for (final door in doors) {
      if (door.id == 'door' || door.id == 'back') continue;
      final r1 = _roomAt(
          door.at + Offset(math.cos(door.angle), math.sin(door.angle)) * 12);
      final r2 = _roomAt(
          door.at - Offset(math.cos(door.angle), math.sin(door.angle)) * 12);
      if ((r1 == a && r2 == b) || (r1 == b && r2 == a)) {
        return [from, door.at, to];
      }
    }
    return [from, to];
  }

  static final Map<String, RoomPlan> _cache = {};

  static RoomPlan of({required int seed, required String kind}) =>
      _cache['$seed:$kind'] ??= _lay(seed, RoomKind.of(kind));

  // ------------------------------------------------------------------ lay

  static RoomPlan _lay(int seed, RoomKind kind) {
    // The kinds laid in their own functions (v1.210), and the variants a
    // seed picks for a temple and an inn.
    final variant = seed.abs() % 3;
    switch (kind) {
      case RoomKind.casino:
        return _casino(seed);
      case RoomKind.barracks:
        return _barracks(seed);
      case RoomKind.library:
        return _library(seed);
      case RoomKind.prison:
        return _prison(seed);
      case RoomKind.forge:
        return _forge(seed);
      case RoomKind.theatre:
        return _theatre(seed);
      case RoomKind.baths:
        return _baths(seed);
      case RoomKind.temple when variant == 1:
        return _cruciform(seed);
      case RoomKind.temple when variant == 2:
        return _rotunda(seed);
      case RoomKind.inn when variant == 1:
        return _courtyardInn(seed);
      default:
        break;
    }
    final rng = math.Random(seed);
    final rooms = <Room>[];
    final walls = <(Offset, Offset)>[];
    final doors = <RoomDoor>[];
    final furniture = <Furniture>[];
    final anchors = <String, Offset>{};
    List<Offset> outline;

    void table(Offset c, {double r = 34}) =>
        furniture.add(Furniture(FurnitureKind.table, c, Size(r * 2, r * 2)));
    void put(FurnitureKind k, Offset c, double w, double h,
            {double angle = 0}) =>
        furniture.add(Furniture(k, c, Size(w, h), angle: angle));

    switch (kind) {
      case RoomKind.den:
        // A tavern at the front, the gaming room behind, the counting
        // room off it, a gallery over the floor.
        final box = const Rect.fromLTWH(180, 110, 640, 780);
        outline = _corners(box);
        final front = Rect.fromLTRB(box.left, 560, box.right, box.bottom);
        final back = Rect.fromLTRB(box.left, box.top, box.right, 560);
        final counting =
            Rect.fromLTRB(box.right - 180, box.top, box.right, box.top + 170);
        rooms
          ..add(Room('front', front))
          ..add(Room('back', back))
          ..add(Room('counting', counting));
        // The wall between the rooms, with its doorway.
        walls
          ..add((Offset(box.left, 560), Offset(box.left + 230, 560)))
          ..add((Offset(box.left + 290, 560), Offset(box.right, 560)))
          ..add((
            Offset(counting.left, counting.top),
            Offset(counting.left, counting.bottom - 70)
          ))
          ..add((
            Offset(counting.left, counting.bottom),
            Offset(counting.right, counting.bottom)
          ));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 56))
          ..add(RoomDoor('back', Offset(box.left + 420, box.top), -math.pi / 2))
          ..add(RoomDoor('inner', Offset(box.left + 260, 560), -math.pi / 2,
              width: 60))
          ..add(RoomDoor(
              'counting', Offset(counting.left, counting.bottom - 35), 0,
              width: 50));
        // The front: the bar along the left wall, tables, the stair.
        put(FurnitureKind.bar, Offset(box.left + 48, front.center.dy + 20), 56,
            220);
        table(Offset(box.left + 230, front.top + 90));
        table(Offset(box.left + 390, front.top + 110));
        table(Offset(box.left + 300, front.bottom - 110));
        table(Offset(box.left + 470, front.bottom - 90));
        put(FurnitureKind.stair, Offset(box.right - 50, front.center.dy), 60,
            120);
        // The back: four gaming tables, the cage, the gallery's rail.
        final gx = [box.left + 170, box.left + 400];
        final gy = [back.top + 190, back.top + 360];
        for (final x in gx) {
          for (final y in gy) {
            table(
                Offset(
                    x + rng.nextDouble() * 8 - 4, y + rng.nextDouble() * 8 - 4),
                r: 40);
          }
        }
        put(FurnitureKind.cage, Offset(box.left + 60, back.top + 60), 80, 80);
        put(FurnitureKind.railing, Offset(box.left + 215, back.top + 28), 310,
            6);
        put(FurnitureKind.strongbox,
            Offset(counting.right - 50, counting.top + 50), 44, 32);
        put(FurnitureKind.counter,
            Offset(counting.center.dx - 10, counting.bottom - 60), 100, 28);
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 60)
          ..['back'] = Offset(box.left + 420, box.top + 60)
          ..['bar'] = Offset(box.left + 120, front.center.dy + 20)
          ..['tables'] = Offset(box.left + 285, back.top + 190)
          ..['floor'] = Offset(box.left + 285, back.top + 365)
          ..['front'] = Offset(front.center.dx + 20, front.center.dy)
          ..['cage'] = Offset(box.left + 130, back.top + 90)
          ..['gallery'] = Offset(box.left + 200, back.top + 75)
          ..['counting'] =
              Offset(counting.center.dx - 10, counting.center.dy + 10)
          ..['strongbox'] = Offset(counting.right - 90, counting.top + 60)
          ..['stairs'] = Offset(box.right - 110, front.center.dy);
      case RoomKind.tavern || RoomKind.inn:
        final box = const Rect.fromLTWH(190, 160, 620, 680);
        outline = _corners(box);
        final room =
            Rect.fromLTRB(box.left, box.top + 170, box.right, box.bottom);
        final kitchen =
            Rect.fromLTRB(box.left, box.top, box.right, box.top + 170);
        rooms
          ..add(Room('room', room))
          ..add(Room('kitchen', kitchen));
        walls
          ..add((
            Offset(box.left, kitchen.bottom),
            Offset(box.left + 300, kitchen.bottom)
          ))
          ..add((
            Offset(box.left + 360, kitchen.bottom),
            Offset(box.right, kitchen.bottom)
          ));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 56))
          ..add(RoomDoor('back', Offset(box.right - 90, box.top), -math.pi / 2))
          ..add(RoomDoor(
              'inner', Offset(box.left + 330, kitchen.bottom), -math.pi / 2,
              width: 60));
        put(FurnitureKind.bar, Offset(box.right - 50, room.top + 150), 56, 240);
        put(FurnitureKind.hearth, Offset(box.left + 30, room.center.dy), 50,
            110);
        for (final (x, y) in [
          (170.0, 110.0),
          (340.0, 90.0),
          (160.0, 300.0),
          (360.0, 290.0),
          (260.0, 440.0)
        ]) {
          table(Offset(box.left + x + rng.nextDouble() * 10,
              room.top + y + rng.nextDouble() * 10));
        }
        put(FurnitureKind.stair, Offset(box.right - 50, room.bottom - 90), 60,
            110);
        put(FurnitureKind.longTable,
            Offset(kitchen.center.dx - 100, kitchen.center.dy), 200, 50);
        if (kind == RoomKind.inn) {
          put(FurnitureKind.bed, Offset(kitchen.right - 110, kitchen.center.dy),
              60, 110);
        }
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 60)
          ..['back'] = Offset(box.right - 90, box.top + 60)
          ..['bar'] = Offset(box.right - 130, room.top + 150)
          ..['hearth'] = Offset(box.left + 110, room.center.dy)
          ..['tables'] = Offset(box.left + 260, room.top + 200)
          ..['floor'] = Offset(room.center.dx - 40, room.center.dy)
          ..['stairs'] = Offset(box.right - 120, room.bottom - 90)
          ..['kitchen'] = Offset(kitchen.center.dx, kitchen.center.dy)
          ..['rooms'] = Offset(box.right - 120, room.bottom - 90);
      case RoomKind.house:
        final box = const Rect.fromLTWH(230, 240, 540, 520);
        outline = _corners(box);
        final hall =
            Rect.fromLTRB(box.left, box.top, box.left + 320, box.bottom);
        final chamber =
            Rect.fromLTRB(box.left + 320, box.top, box.right, box.bottom);
        rooms
          ..add(Room('hall', hall))
          ..add(Room('chamber', chamber));
        walls
          ..add(
              (Offset(hall.right, box.top), Offset(hall.right, box.top + 180)))
          ..add((
            Offset(hall.right, box.top + 240),
            Offset(hall.right, box.bottom)
          ));
        doors
          ..add(RoomDoor(
              'door', Offset(hall.center.dx, box.bottom), math.pi / 2,
              width: 50))
          ..add(RoomDoor(
              'back', Offset(hall.center.dx - 60, box.top), -math.pi / 2,
              width: 40))
          ..add(RoomDoor('inner', Offset(hall.right, box.top + 210), 0,
              width: 60));
        put(FurnitureKind.hearth, Offset(box.left + 28, hall.center.dy), 46,
            100);
        put(FurnitureKind.longTable,
            Offset(hall.center.dx + 20, hall.center.dy + 20), 150, 54);
        put(FurnitureKind.bed, Offset(chamber.center.dx + 30, chamber.top + 90),
            70, 120);
        put(FurnitureKind.crate,
            Offset(chamber.right - 50, chamber.bottom - 60), 50, 50);
        anchors
          ..['door'] = Offset(hall.center.dx, box.bottom - 60)
          ..['back'] = Offset(hall.center.dx - 60, box.top + 60)
          ..['hearth'] = Offset(box.left + 100, hall.center.dy)
          ..['table'] = Offset(hall.center.dx + 20, hall.center.dy - 70)
          ..['floor'] = Offset(hall.center.dx + 20, hall.center.dy + 90)
          ..['bed'] = Offset(chamber.center.dx + 30, chamber.top + 190)
          ..['chamber'] = Offset(chamber.center.dx, chamber.center.dy + 40);
      case RoomKind.hall || RoomKind.keep:
        final box = const Rect.fromLTWH(220, 90, 560, 820);
        outline = _corners(box);
        final nave =
            Rect.fromLTRB(box.left, box.top + 150, box.right, box.bottom);
        final dais = Rect.fromLTRB(box.left, box.top, box.right, box.top + 150);
        rooms
          ..add(Room('hall', nave))
          ..add(Room('dais', dais));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 80))
          ..add(RoomDoor('side', Offset(box.right, nave.center.dy), 0))
          ..add(RoomDoor(
              'inner', Offset(box.center.dx, dais.bottom), -math.pi / 2,
              width: 200));
        for (var i = 0; i < 4; i++) {
          final y = nave.top + 110 + i * 170.0;
          put(FurnitureKind.pillar, Offset(box.left + 90, y), 40, 40);
          put(FurnitureKind.pillar, Offset(box.right - 90, y), 40, 40);
        }
        put(FurnitureKind.longTable, Offset(box.center.dx, nave.center.dy + 40),
            90, 420);
        put(FurnitureKind.dais, Offset(box.center.dx, dais.center.dy), 380,
            100);
        if (kind == RoomKind.keep) {
          put(FurnitureKind.stair, Offset(box.left + 50, nave.bottom - 100), 60,
              120);
        }
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 70)
          ..['side'] = Offset(box.right - 70, nave.center.dy)
          ..['table'] = Offset(box.center.dx - 110, nave.center.dy + 40)
          ..['floor'] = Offset(box.center.dx, nave.bottom - 190)
          ..['dais'] = Offset(box.center.dx, dais.center.dy + 90)
          ..['throne'] = Offset(box.center.dx, dais.center.dy + 90)
          ..['stairs'] = Offset(box.left + 120, nave.bottom - 100);
      case RoomKind.temple:
        final box = const Rect.fromLTWH(230, 90, 540, 820);
        outline = _corners(box);
        final nave =
            Rect.fromLTRB(box.left, box.top + 200, box.right, box.bottom);
        final choir =
            Rect.fromLTRB(box.left, box.top, box.right, box.top + 200);
        rooms
          ..add(Room('nave', nave))
          ..add(Room('choir', choir));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 80))
          ..add(RoomDoor('side', Offset(box.left, nave.top + 120), math.pi))
          ..add(RoomDoor(
              'inner', Offset(box.center.dx, choir.bottom), -math.pi / 2,
              width: 240));
        for (var i = 0; i < 6; i++) {
          final y = nave.top + 80 + i * 90.0;
          put(FurnitureKind.pew, Offset(box.center.dx - 110, y), 160, 22);
          put(FurnitureKind.pew, Offset(box.center.dx + 110, y), 160, 22);
        }
        put(FurnitureKind.altar, Offset(box.center.dx, choir.top + 80), 120,
            50);
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 70)
          ..['side'] = Offset(box.left + 70, nave.top + 120)
          ..['pews'] = Offset(box.center.dx, nave.center.dy)
          ..['floor'] = Offset(box.center.dx, nave.bottom - 120)
          ..['altar'] = Offset(box.center.dx, choir.top + 150)
          ..['chapel'] = Offset(box.right - 80, choir.center.dy);
      case RoomKind.shop:
        final box = const Rect.fromLTWH(230, 220, 540, 560);
        outline = _corners(box);
        final front =
            Rect.fromLTRB(box.left, box.top + 200, box.right, box.bottom);
        final store =
            Rect.fromLTRB(box.left, box.top, box.right, box.top + 200);
        rooms
          ..add(Room('shop', front))
          ..add(Room('store', store));
        walls
          ..add((
            Offset(box.left, store.bottom),
            Offset(box.right - 220, store.bottom)
          ))
          ..add((
            Offset(box.right - 160, store.bottom),
            Offset(box.right, store.bottom)
          ));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 56))
          ..add(RoomDoor('back', Offset(box.left + 80, box.top), -math.pi / 2))
          ..add(RoomDoor(
              'inner', Offset(box.right - 190, store.bottom), -math.pi / 2,
              width: 60));
        put(FurnitureKind.counter, Offset(box.center.dx, front.top + 80), 300,
            40);
        put(FurnitureKind.shelf, Offset(box.left + 24, front.center.dy + 40),
            30, 260);
        put(FurnitureKind.shelf, Offset(box.right - 24, front.center.dy + 40),
            30, 260);
        for (var i = 0; i < 4; i++) {
          put(FurnitureKind.crate,
              Offset(store.left + 70 + i * 90.0, store.center.dy), 50, 50);
        }
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 60)
          ..['back'] = Offset(box.left + 80, box.top + 60)
          ..['counter'] = Offset(box.center.dx, front.top + 170)
          ..['floor'] = Offset(box.center.dx, front.center.dy + 80)
          ..['shelves'] = Offset(box.left + 110, front.center.dy + 40)
          ..['store'] = Offset(store.center.dx + 80, store.center.dy);
      case RoomKind.warehouse:
        final box = const Rect.fromLTWH(170, 160, 660, 680);
        outline = _corners(box);
        rooms.add(Room('floor', box));
        doors
          ..add(RoomDoor('door', Offset(box.center.dx, box.bottom), math.pi / 2,
              width: 120))
          ..add(
              RoomDoor('back', Offset(box.right, box.top + 120), 0, width: 80));
        for (var i = 0; i < 12; i++) {
          final c = Offset(
              box.left + 90 + (i % 4) * 160.0 + rng.nextDouble() * 20,
              box.top + 110 + (i ~/ 4) * 170.0 + rng.nextDouble() * 20);
          put(FurnitureKind.crate, c, 70, 70, angle: rng.nextDouble() * 0.3);
        }
        for (var i = 0; i < 5; i++) {
          put(FurnitureKind.cask,
              Offset(box.left + 60, box.bottom - 80 - i * 70.0), 50, 50);
        }
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 70)
          ..['back'] = Offset(box.right - 80, box.top + 120)
          ..['crates'] = Offset(box.center.dx, box.center.dy)
          ..['floor'] = Offset(box.center.dx, box.bottom - 170)
          ..['loft'] = Offset(box.right - 90, box.bottom - 90);
      case RoomKind.cellar || RoomKind.cave:
        // Rough walls round one or two chambers.
        outline = _rough(const Rect.fromLTWH(200, 160, 600, 680), rng,
            kind == RoomKind.cave ? 40 : 14);
        final main = const Rect.fromLTWH(220, 400, 560, 420);
        final deep = const Rect.fromLTWH(220, 180, 560, 220);
        rooms
          ..add(Room('main', main))
          ..add(Room('deep', deep));
        doors.add(RoomDoor('door', Offset(500, 840), math.pi / 2, width: 60));
        if (kind == RoomKind.cellar) {
          put(FurnitureKind.stair, Offset(500, 780), 70, 100);
          for (var i = 0; i < 6; i++) {
            put(FurnitureKind.cask,
                Offset(260 + (i % 3) * 70.0, 460 + (i ~/ 3) * 70.0), 56, 56);
          }
          for (var i = 0; i < 3; i++) {
            put(FurnitureKind.crate, Offset(700, 460 + i * 80.0), 60, 60);
          }
        } else {
          for (var i = 0; i < 9; i++) {
            put(
                FurnitureKind.rock,
                Offset(
                    240 + rng.nextDouble() * 520, 200 + rng.nextDouble() * 600),
                30 + rng.nextDouble() * 40,
                24 + rng.nextDouble() * 30,
                angle: rng.nextDouble() * math.pi);
          }
        }
        anchors
          ..['door'] = const Offset(500, 760)
          ..['casks'] = const Offset(330, 530)
          ..['floor'] = const Offset(520, 600)
          ..['deep'] = const Offset(500, 290)
          ..['dark'] = const Offset(500, 290);
      case RoomKind.tower:
        outline = _circle(const Offset(500, 500), 300, 28);
        rooms.add(Room('round', const Rect.fromLTWH(220, 220, 560, 560)));
        doors.add(
            RoomDoor('door', const Offset(500, 800), math.pi / 2, width: 50));
        put(FurnitureKind.stair, const Offset(500, 500), 140, 140, angle: 0.3);
        put(FurnitureKind.hearth, const Offset(260, 500), 44, 90);
        anchors
          ..['door'] = const Offset(500, 720)
          ..['floor'] = const Offset(380, 640)
          ..['stairs'] = const Offset(600, 440)
          ..['top'] = const Offset(600, 440)
          ..['hearth'] = const Offset(330, 500);
      case RoomKind.plain ||
            RoomKind.casino ||
            RoomKind.barracks ||
            RoomKind.library ||
            RoomKind.prison ||
            RoomKind.forge ||
            RoomKind.theatre ||
            RoomKind.baths:
        final box = const Rect.fromLTWH(250, 250, 500, 500);
        outline = _corners(box);
        rooms.add(Room('room', box));
        doors.add(RoomDoor(
            'door', Offset(box.center.dx, box.bottom), math.pi / 2,
            width: 56));
        anchors
          ..['door'] = Offset(box.center.dx, box.bottom - 60)
          ..['floor'] = box.center;
    }
    anchors[''] = anchors['floor']!;
    return RoomPlan._(
      seed: seed,
      kind: kind,
      rooms: rooms,
      walls: walls,
      doors: doors,
      furniture: furniture,
      anchors: anchors,
      outline: outline,
    );
  }

  // ------------------------------------------------- the other layouts

  /// The gaming house of the rich: a wheel ringed with card tables on a
  /// wide floor, the cashier, two private rooms and the vault behind.
  static RoomPlan _casino(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(140, 90, 720, 820);
    b.room('floor', Rect.fromLTRB(box.left, 330, box.right, box.bottom));
    b.room('cashier', Rect.fromLTRB(box.left, box.top, 340, 330));
    b.room('vip1', Rect.fromLTRB(340, box.top, 520, 330));
    b.room('vip2', Rect.fromLTRB(520, box.top, 700, 330));
    b.room('vault', Rect.fromLTRB(700, box.top, box.right, 330));
    b.hwall(
        330, box.left, box.right, [(250, 60), (430, 60), (610, 60), (780, 50)]);
    for (final x in [340.0, 520.0, 700.0]) {
      b.vwall(x, box.top, 330);
    }
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 70);
    b.door('back', Offset(240, box.top), -math.pi / 2, width: 50);
    b.door('cashier', const Offset(250, 330), -math.pi / 2, width: 60);
    b.door('vip1', const Offset(430, 330), -math.pi / 2, width: 60);
    b.door('vip2', const Offset(610, 330), -math.pi / 2, width: 60);
    b.door('vault', const Offset(780, 330), -math.pi / 2, width: 50);
    b.put(FurnitureKind.wheel, const Offset(500, 560), 150, 150);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      b.table(Offset(500 + math.cos(a) * 270, 560 + math.sin(a) * 130), r: 40);
    }
    b.put(FurnitureKind.bar, const Offset(180, 780), 50, 160);
    b.put(FurnitureKind.stair, Offset(box.right - 40, 780), 60, 110);
    b.put(FurnitureKind.counter, const Offset(680, 868), 150, 26);
    b.put(FurnitureKind.counter, const Offset(235, 200), 130, 26);
    b.put(FurnitureKind.strongbox, const Offset(305, 130), 44, 32);
    b.table(const Offset(430, 205), r: 40);
    b.table(const Offset(610, 205), r: 40);
    b.put(FurnitureKind.bench, const Offset(430, 298), 100, 24);
    b.put(FurnitureKind.bench, const Offset(610, 298), 100, 24);
    for (final c in const [
      Offset(740, 130),
      Offset(820, 130),
      Offset(780, 205)
    ]) {
      b.put(FurnitureKind.strongbox, c, 44, 32);
    }
    b.anchors
      ..['door'] = const Offset(500, 850)
      ..['back'] = const Offset(240, 140)
      ..['floor'] = const Offset(500, 720)
      ..['wheel'] = const Offset(500, 455)
      ..['tables'] = const Offset(700, 495)
      ..['bar'] = const Offset(260, 780)
      ..['stairs'] = const Offset(750, 780)
      ..['cloak'] = const Offset(680, 825)
      ..['cashier'] = const Offset(240, 270)
      ..['cage'] = const Offset(240, 270)
      ..['vip'] = const Offset(430, 262)
      ..['vip2'] = const Offset(610, 262)
      ..['vault'] = const Offset(780, 270)
      ..['strongbox'] = const Offset(780, 270);
    return b.finish(seed, RoomKind.casino, _corners(box));
  }

  /// The caserne: the guardroom at the door, the long dormitory of bunks
  /// round a mess table, the armoury and the officers' rooms behind.
  static RoomPlan _barracks(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(190, 60, 620, 880);
    b.room('guard', Rect.fromLTRB(box.left, 720, box.right, box.bottom));
    b.room('dorm', Rect.fromLTRB(box.left, 270, box.right, 720));
    b.room('armoury', Rect.fromLTRB(box.left, box.top, 420, 270));
    b.room('officers', Rect.fromLTRB(420, box.top, box.right, 270));
    b.hwall(720, box.left, box.right, [(500, 100)]);
    b.hwall(270, box.left, box.right, [(300, 60), (610, 60)]);
    b.vwall(420, box.top, 270);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 80);
    b.door('back', Offset(box.right, 485), 0, width: 60);
    b.door('inner', const Offset(500, 720), -math.pi / 2, width: 100);
    b.door('armoury', const Offset(300, 270), -math.pi / 2, width: 60);
    b.door('officers', const Offset(610, 270), -math.pi / 2, width: 60);
    b.put(FurnitureKind.desk, const Offset(330, 830), 150, 34);
    b.put(FurnitureKind.rack, const Offset(214, 800), 24, 110);
    b.put(FurnitureKind.rack, const Offset(786, 800), 24, 110);
    b.put(FurnitureKind.bench, const Offset(670, 890), 130, 26);
    for (var i = 0; i < 5; i++) {
      final y = 325 + i * 80.0;
      b.put(FurnitureKind.bed, Offset(235, y), 56, 70);
      b.put(FurnitureKind.bed, Offset(305, y), 56, 70);
      if (i != 2) b.put(FurnitureKind.bed, Offset(765, y), 56, 70);
      b.put(FurnitureKind.bed, Offset(695, y), 56, 70);
    }
    b.put(FurnitureKind.longTable, const Offset(500, 495), 70, 300);
    b.put(FurnitureKind.rack, const Offset(300, 86), 190, 22);
    b.put(FurnitureKind.rack, const Offset(214, 180), 22, 120);
    b.put(FurnitureKind.crate, const Offset(340, 215), 50, 50);
    b.put(FurnitureKind.crate, const Offset(385, 160), 50, 50);
    b.put(FurnitureKind.hearth, const Offset(450, 170), 44, 80);
    b.put(FurnitureKind.desk, const Offset(540, 190), 110, 34);
    b.put(FurnitureKind.bed, const Offset(730, 150), 70, 120);
    b.anchors
      ..['door'] = const Offset(500, 880)
      ..['back'] = const Offset(770, 485)
      ..['floor'] = const Offset(500, 800)
      ..['guard'] = const Offset(640, 770)
      ..['desk'] = const Offset(330, 885)
      ..['dorm'] = const Offset(390, 485)
      ..['bunks'] = const Offset(390, 400)
      ..['mess'] = const Offset(600, 490)
      ..['armoury'] = const Offset(300, 190)
      ..['officers'] = const Offset(560, 235);
    return b.finish(seed, RoomKind.barracks, _corners(box));
  }

  /// A library: shelves in stacks with an aisle between, tables to read
  /// at, the librarian's counter, a locked archive and the scriptorium.
  static RoomPlan _library(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(170, 110, 660, 780);
    b.room('hall', Rect.fromLTRB(box.left, 330, box.right, box.bottom));
    b.room('archive', Rect.fromLTRB(box.left, box.top, 470, 330));
    b.room('scriptorium', Rect.fromLTRB(470, box.top, box.right, 330));
    b.hwall(330, box.left, box.right, [(320, 50), (650, 60)]);
    b.vwall(470, box.top, 330);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 60);
    b.door('back', const Offset(700, 110), -math.pi / 2, width: 50);
    b.door('archive', const Offset(320, 330), -math.pi / 2, width: 50);
    b.door('scriptorium', const Offset(650, 330), -math.pi / 2, width: 60);
    b.put(FurnitureKind.shelf, const Offset(192, 610), 30, 440);
    for (final x in [300.0, 330.0, 420.0, 450.0]) {
      b.put(FurnitureKind.shelf, Offset(x, 520), 28, 260);
    }
    b.put(FurnitureKind.longTable, const Offset(640, 470), 220, 56);
    b.put(FurnitureKind.longTable, const Offset(640, 600), 220, 56);
    b.put(FurnitureKind.counter, const Offset(650, 800), 130, 30);
    b.put(FurnitureKind.shelf, const Offset(320, 134), 260, 26);
    b.put(FurnitureKind.shelf, const Offset(192, 230), 30, 180);
    b.put(FurnitureKind.strongbox, const Offset(440, 150), 44, 32);
    b.put(FurnitureKind.desk, const Offset(570, 230), 110, 44);
    b.put(FurnitureKind.desk, const Offset(720, 230), 110, 44);
    b.put(FurnitureKind.hearth, const Offset(805, 290), 46, 70);
    b.anchors
      ..['door'] = const Offset(500, 830)
      ..['back'] = const Offset(700, 165)
      ..['floor'] = const Offset(540, 720)
      ..['stacks'] = const Offset(375, 520)
      ..['reading'] = const Offset(640, 535)
      ..['counter'] = const Offset(650, 850)
      ..['archive'] = const Offset(320, 230)
      ..['strongbox'] = const Offset(440, 205)
      ..['scriptorium'] = const Offset(520, 170);
    return b.finish(seed, RoomKind.library, _corners(box));
  }

  /// A prison: the guardroom at the door, then a corridor between two
  /// rows of barred cells.
  static RoomPlan _prison(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(280, 90, 440, 820);
    b.room('corridor', Rect.fromLTRB(440, box.top, 560, 700));
    b.room('guard', Rect.fromLTRB(box.left, 700, box.right, box.bottom));
    b.hwall(700, box.left, 440);
    b.hwall(700, 560, box.right);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 70);
    b.door('back', Offset(box.center.dx, box.top), -math.pi / 2, width: 50);
    b.door('inner', const Offset(500, 700), -math.pi / 2, width: 120);
    for (var i = 0; i < 5; i++) {
      final top = 90 + 122.0 * i;
      final mid = top + 61;
      final left = Rect.fromLTRB(280, top, 440, top + 122);
      final right = Rect.fromLTRB(560, top, 720, top + 122);
      b.room('cell${i + 1}', left);
      b.room('cell${i + 6}', right);
      if (i > 0) {
        b.hwall(top, 280, 440);
        b.hwall(top, 560, 720);
      }
      b.put(FurnitureKind.cage, Offset(440, mid), 12, 56);
      b.put(FurnitureKind.cage, Offset(560, mid), 12, 56);
      b.put(FurnitureKind.bed, Offset(316, mid), 46, 90);
      b.put(FurnitureKind.bed, Offset(684, mid), 46, 90);
      b.anchors['cell${i + 1}'] = Offset(385, mid);
      b.anchors['cell${i + 6}'] = Offset(615, mid);
    }
    for (var i = 0; i < 5; i++) {
      final mid = 151 + 122.0 * i;
      b.vwall(440, 90 + 122.0 * i, 90 + 122.0 * (i + 1), [(mid, 60)]);
      b.vwall(560, 90 + 122.0 * i, 90 + 122.0 * (i + 1), [(mid, 60)]);
    }
    b.put(FurnitureKind.desk, const Offset(400, 800), 150, 34);
    b.put(FurnitureKind.rack, const Offset(302, 790), 24, 100);
    b.put(FurnitureKind.bench, const Offset(650, 860), 130, 26);
    b.put(FurnitureKind.hearth, const Offset(690, 790), 40, 90);
    b.anchors
      ..['door'] = const Offset(500, 850)
      ..['back'] = const Offset(500, 150)
      ..['floor'] = const Offset(500, 420)
      ..['cells'] = const Offset(500, 300)
      ..['guard'] = const Offset(580, 810)
      ..['desk'] = const Offset(400, 860);
    return b.finish(seed, RoomKind.prison, _corners(box));
  }

  /// A smithy: a wide door onto the working floor, the forge, the anvil
  /// and the quench trough, a store behind.
  static RoomPlan _forge(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(200, 200, 600, 600);
    b.room('forge', Rect.fromLTRB(box.left, 360, box.right, box.bottom));
    b.room('store', Rect.fromLTRB(box.left, box.top, box.right, 360));
    b.hwall(360, box.left, box.right, [(340, 70)]);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 130);
    b.door('back', const Offset(200, 280), math.pi, width: 50);
    b.door('inner', const Offset(340, 360), -math.pi / 2, width: 70);
    b.put(FurnitureKind.hearth, const Offset(690, 410), 150, 56);
    b.put(FurnitureKind.anvil, const Offset(500, 520), 60, 34);
    b.put(FurnitureKind.pool, const Offset(320, 470), 100, 44);
    b.put(FurnitureKind.rack, const Offset(224, 640), 22, 150);
    b.put(FurnitureKind.rack, const Offset(776, 640), 22, 150);
    b.put(FurnitureKind.crate, const Offset(740, 480), 46, 46);
    b.put(FurnitureKind.crate, const Offset(740, 730), 50, 50);
    b.put(FurnitureKind.shelf, const Offset(500, 222), 400, 26);
    b.put(FurnitureKind.crate, const Offset(700, 300), 50, 50);
    b.put(FurnitureKind.crate, const Offset(750, 300), 50, 50);
    b.put(FurnitureKind.cask, const Offset(560, 300), 50, 50);
    b.anchors
      ..['door'] = const Offset(500, 740)
      ..['back'] = const Offset(270, 280)
      ..['floor'] = const Offset(500, 650)
      ..['anvil'] = const Offset(500, 580)
      ..['forge'] = const Offset(690, 475)
      ..['trough'] = const Offset(320, 525)
      ..['store'] = const Offset(450, 290);
    return b.finish(seed, RoomKind.forge, _corners(box));
  }

  /// A playhouse: the foyer, rows of benches either side of an aisle, the
  /// pit rail, the stage with a dressing room and a props room beside it.
  static RoomPlan _theatre(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(150, 90, 700, 820);
    b.room('foyer', Rect.fromLTRB(box.left, 780, box.right, box.bottom));
    b.room('house', Rect.fromLTRB(box.left, 330, box.right, 780));
    b.room('stage', Rect.fromLTRB(310, box.top, 690, 330));
    b.room('dressing', Rect.fromLTRB(box.left, box.top, 310, 330));
    b.room('props', Rect.fromLTRB(690, box.top, box.right, 330));
    b.hwall(780, box.left, box.right, [(500, 110)]);
    b.hwall(330, box.left, 310);
    b.hwall(330, 690, box.right);
    b.vwall(310, box.top, 330, [(250, 50)]);
    b.vwall(690, box.top, 330, [(250, 50)]);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 90);
    b.door('back', Offset(box.right, 170), 0, width: 50);
    b.door('inner', const Offset(500, 780), -math.pi / 2, width: 110);
    b.door('dressing', const Offset(310, 250), 0, width: 50);
    b.door('props', const Offset(690, 250), 0, width: 50);
    b.put(FurnitureKind.stage, const Offset(500, 205), 380, 160);
    b.put(FurnitureKind.railing, const Offset(500, 330), 380, 6);
    for (var row = 0; row < 7; row++) {
      final y = 440 + row * 50.0;
      for (final x in [250.0, 380.0, 620.0, 750.0]) {
        b.put(FurnitureKind.bench, Offset(x, y), 120, 24);
      }
    }
    b.put(FurnitureKind.counter, const Offset(400, 850), 140, 28);
    b.put(FurnitureKind.shelf, const Offset(172, 210), 30, 160);
    b.put(FurnitureKind.desk, const Offset(235, 135), 100, 34);
    b.put(FurnitureKind.crate, const Offset(730, 140), 50, 50);
    b.put(FurnitureKind.crate, const Offset(790, 300), 50, 50);
    b.put(FurnitureKind.crate, const Offset(730, 300), 50, 50);
    b.anchors
      ..['door'] = const Offset(500, 860)
      ..['back'] = const Offset(810, 170)
      ..['floor'] = const Offset(500, 600)
      ..['stage'] = const Offset(500, 265)
      ..['pit'] = const Offset(500, 380)
      ..['seats'] = const Offset(380, 565)
      ..['tickets'] = const Offset(400, 810)
      ..['dressing'] = const Offset(235, 240)
      ..['props'] = const Offset(770, 235);
    return b.finish(seed, RoomKind.theatre, _corners(box));
  }

  /// Baths: a changing hall at the door, the great pool between pillars,
  /// a hot room and a cold room behind it.
  static RoomPlan _baths(int seed) {
    final b = _B();
    const box = Rect.fromLTWH(160, 130, 680, 740);
    b.room('changing', Rect.fromLTRB(box.left, 650, box.right, box.bottom));
    b.room('pool', Rect.fromLTRB(box.left, 330, box.right, 650));
    b.room('hot', Rect.fromLTRB(box.left, box.top, 460, 330));
    b.room('cold', Rect.fromLTRB(460, box.top, box.right, 330));
    b.hwall(650, box.left, box.right, [(500, 110)]);
    b.hwall(330, box.left, box.right, [(310, 60), (690, 60)]);
    b.vwall(460, box.top, 330);
    b.door('door', Offset(box.center.dx, box.bottom), math.pi / 2, width: 60);
    b.door('back', Offset(box.right, 520), 0, width: 50);
    b.door('inner', const Offset(500, 650), -math.pi / 2, width: 110);
    b.door('hot', const Offset(310, 330), -math.pi / 2, width: 60);
    b.door('cold', const Offset(690, 330), -math.pi / 2, width: 60);
    b.put(FurnitureKind.pool, const Offset(500, 490), 400, 180);
    for (final c in const [
      Offset(330, 375),
      Offset(670, 375),
      Offset(330, 605),
      Offset(670, 605)
    ]) {
      b.put(FurnitureKind.pillar, c, 40, 40);
    }
    b.put(FurnitureKind.bench, const Offset(260, 790), 160, 26);
    b.put(FurnitureKind.bench, const Offset(740, 790), 160, 26);
    b.put(FurnitureKind.counter, const Offset(700, 700), 130, 28);
    b.put(FurnitureKind.pool, const Offset(330, 235), 140, 100);
    b.put(FurnitureKind.hearth, const Offset(190, 230), 46, 100);
    b.put(FurnitureKind.pool, const Offset(620, 235), 140, 100);
    b.put(FurnitureKind.shelf, const Offset(815, 230), 28, 120);
    b.anchors
      ..['door'] = const Offset(500, 810)
      ..['back'] = const Offset(790, 520)
      ..['floor'] = const Offset(240, 520)
      ..['pool'] = const Offset(500, 625)
      ..['hot'] = const Offset(330, 305)
      ..['cold'] = const Offset(620, 305)
      ..['changing'] = const Offset(500, 740)
      ..['counter'] = const Offset(700, 745);
    return b.finish(seed, RoomKind.baths, _corners(box));
  }

  /// A temple in a cross: nave, transepts, a choir and altar at the head.
  static RoomPlan _cruciform(int seed) {
    final b = _B();
    b.room('nave', const Rect.fromLTRB(380, 560, 620, 910));
    b.room('crossing', const Rect.fromLTRB(380, 360, 620, 560));
    b.room('choir', const Rect.fromLTRB(380, 90, 620, 360));
    b.room('west', const Rect.fromLTRB(180, 360, 380, 560));
    b.room('east', const Rect.fromLTRB(620, 360, 820, 560));
    b.door('door', const Offset(500, 910), math.pi / 2, width: 80);
    b.door('side', const Offset(820, 460), 0, width: 60);
    for (var i = 0; i < 4; i++) {
      final y = 610 + i * 75.0;
      b.put(FurnitureKind.pew, Offset(437, y), 90, 22);
      b.put(FurnitureKind.pew, Offset(563, y), 90, 22);
    }
    b.put(FurnitureKind.altar, const Offset(500, 150), 120, 50);
    b.put(FurnitureKind.pew, const Offset(430, 270), 24, 130);
    b.put(FurnitureKind.pew, const Offset(570, 270), 24, 130);
    b.put(FurnitureKind.altar, const Offset(225, 460), 50, 120, angle: 0);
    b.put(FurnitureKind.pillar, const Offset(740, 440), 56, 56);
    b.put(FurnitureKind.pew, const Offset(740, 520), 150, 22);
    b.anchors
      ..['door'] = const Offset(500, 850)
      ..['side'] = const Offset(780, 460)
      ..['pews'] = const Offset(500, 700)
      ..['floor'] = const Offset(500, 770)
      ..['crossing'] = const Offset(500, 460)
      ..['altar'] = const Offset(500, 235)
      ..['chapel'] = const Offset(320, 460);
    return b.finish(seed, RoomKind.temple, [
      const Offset(380, 90),
      const Offset(620, 90),
      const Offset(620, 360),
      const Offset(820, 360),
      const Offset(820, 560),
      const Offset(620, 560),
      const Offset(620, 910),
      const Offset(380, 910),
      const Offset(380, 560),
      const Offset(180, 560),
      const Offset(180, 360),
      const Offset(380, 360),
    ]);
  }

  /// A round shrine: a ring of pillars, the altar in the middle.
  static RoomPlan _rotunda(int seed) {
    final b = _B();
    b.room('round', const Rect.fromLTRB(200, 200, 800, 800));
    b.door('door', const Offset(500, 830), math.pi / 2, width: 70);
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      b.put(
          FurnitureKind.pillar,
          const Offset(500, 500) + Offset(math.cos(a), math.sin(a)) * 235,
          44,
          44);
    }
    b.put(FurnitureKind.altar, const Offset(500, 470), 100, 50);
    for (final y in [600.0, 670.0]) {
      b.put(FurnitureKind.pew, Offset(400, y), 130, 20);
      b.put(FurnitureKind.pew, Offset(600, y), 130, 20);
    }
    b.anchors
      ..['door'] = const Offset(500, 770)
      ..['floor'] = const Offset(500, 640)
      ..['pews'] = const Offset(400, 635)
      ..['altar'] = const Offset(500, 395);
    return b.finish(
        seed, RoomKind.temple, _circle(const Offset(500, 500), 330, 32));
  }

  /// An inn round a yard: the taproom along the street, bedrooms in one
  /// wing and the kitchen in the other, the yard open between them.
  static RoomPlan _courtyardInn(int seed) {
    final b = _B();
    b.room('taproom', const Rect.fromLTRB(130, 520, 870, 850));
    b.room('bedrooms', const Rect.fromLTRB(130, 150, 330, 520));
    b.room('kitchen', const Rect.fromLTRB(670, 150, 870, 520));
    b.hwall(520, 130, 330, [(230, 50)]);
    b.hwall(520, 670, 870, [(770, 50)]);
    b.door('door', const Offset(500, 850), math.pi / 2, width: 60);
    b.door('back', const Offset(500, 520), -math.pi / 2, width: 80);
    b.door('bedrooms', const Offset(230, 520), -math.pi / 2, width: 50);
    b.door('kitchen', const Offset(770, 520), -math.pi / 2, width: 50);
    b.put(FurnitureKind.bar, const Offset(700, 570), 240, 50);
    b.put(FurnitureKind.hearth, const Offset(160, 690), 46, 110);
    for (final c in const [
      Offset(290, 590),
      Offset(290, 740),
      Offset(420, 680),
      Offset(620, 740),
      Offset(780, 740)
    ]) {
      b.table(c);
    }
    for (final c in const [
      Offset(180, 230),
      Offset(280, 230),
      Offset(180, 420),
      Offset(280, 420)
    ]) {
      b.put(FurnitureKind.bed, c, 60, 110);
    }
    b.put(FurnitureKind.hearth, const Offset(840, 300), 46, 100);
    b.put(FurnitureKind.longTable, const Offset(760, 400), 150, 46);
    b.put(FurnitureKind.crate, const Offset(720, 200), 50, 50);
    b.put(FurnitureKind.cask, const Offset(790, 200), 46, 46);
    b.anchors
      ..['door'] = const Offset(500, 790)
      ..['back'] = const Offset(500, 575)
      ..['floor'] = const Offset(500, 730)
      ..['bar'] = const Offset(700, 640)
      ..['hearth'] = const Offset(240, 690)
      ..['tables'] = const Offset(350, 665)
      ..['rooms'] = const Offset(230, 330)
      ..['stairs'] = const Offset(230, 330)
      ..['kitchen'] = const Offset(770, 330);
    return b.finish(seed, RoomKind.inn, [
      const Offset(130, 150),
      const Offset(330, 150),
      const Offset(330, 520),
      const Offset(670, 520),
      const Offset(670, 150),
      const Offset(870, 150),
      const Offset(870, 850),
      const Offset(130, 850),
    ]);
  }

  static List<Offset> _corners(Rect r) =>
      [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];

  static List<Offset> _circle(Offset c, double r, int n) => [
        for (var i = 0; i < n; i++)
          c +
              Offset(math.cos(i * 2 * math.pi / n),
                      math.sin(i * 2 * math.pi / n)) *
                  r,
      ];

  /// A box's edges broken into an uneven wall.
  static List<Offset> _rough(Rect r, math.Random rng, double amp) {
    final pts = <Offset>[];
    final corners = _corners(r);
    for (var i = 0; i < 4; i++) {
      final a = corners[i], b = corners[(i + 1) % 4];
      const n = 7;
      for (var k = 0; k < n; k++) {
        final t = k / n;
        final p = a + (b - a) * t;
        final out = Offset((b - a).dy, -(b - a).dx) / (b - a).distance;
        pts.add(k == 0 ? p : p + out * (rng.nextDouble() - 0.5) * 2 * amp);
      }
    }
    return pts;
  }
}

/// What a layout is assembled in.
class _B {
  final rooms = <Room>[];
  final walls = <(Offset, Offset)>[];
  final doors = <RoomDoor>[];
  final furniture = <Furniture>[];
  final anchors = <String, Offset>{};

  void room(String id, Rect r) => rooms.add(Room(id, r));

  void door(String id, Offset at, double angle, {double width = 44}) =>
      doors.add(RoomDoor(id, at, angle, width: width));

  void put(FurnitureKind k, Offset c, double w, double h, {double angle = 0}) =>
      furniture.add(Furniture(k, c, Size(w, h), angle: angle));

  void table(Offset c, {double r = 34}) =>
      put(FurnitureKind.table, c, r * 2, r * 2);

  /// A wall along y from x0 to x1, broken by gaps at (centre, width).
  void hwall(double y, double x0, double x1,
      [List<(double, double)> gaps = const []]) {
    var from = x0;
    for (final (c, w) in [...gaps]..sort((a, b) => a.$1.compareTo(b.$1))) {
      if (c - w / 2 > from) walls.add((Offset(from, y), Offset(c - w / 2, y)));
      from = c + w / 2;
    }
    if (x1 > from) walls.add((Offset(from, y), Offset(x1, y)));
  }

  /// A wall along x from y0 to y1, broken by gaps at (centre, width).
  void vwall(double x, double y0, double y1,
      [List<(double, double)> gaps = const []]) {
    var from = y0;
    for (final (c, w) in [...gaps]..sort((a, b) => a.$1.compareTo(b.$1))) {
      if (c - w / 2 > from) walls.add((Offset(x, from), Offset(x, c - w / 2)));
      from = c + w / 2;
    }
    if (y1 > from) walls.add((Offset(x, from), Offset(x, y1)));
  }

  RoomPlan finish(int seed, RoomKind kind, List<Offset> outline) {
    anchors[''] = anchors['floor']!;
    return RoomPlan._(
      seed: seed,
      kind: kind,
      rooms: rooms,
      walls: walls,
      doors: doors,
      furniture: furniture,
      anchors: anchors,
      outline: outline,
    );
  }
}
