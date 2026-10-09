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
        _ => plain,
      };

  /// Rough ground, not a built floor.
  bool get rough => this == cave;

  /// A stone floor, not boards.
  bool get stone =>
      this == hall ||
      this == keep ||
      this == temple ||
      this == cellar ||
      this == tower ||
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
      case RoomKind.plain:
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
