import 'package:flutter/material.dart';

import '../combat/ship_combat.dart';

/// A ship in battle drawn as a pixel-art cutaway: the near side of the
/// hull is open and its four rooms show inside it, laid out as the battle
/// plays them (helm, guns and bulwark on the upper deck from stern to bow,
/// the hold beneath). The sprites live in `assets/visuals/ship_cutaways/`,
/// [spriteSize] pixels each, drawn facing right; the enemy's is mirrored so
/// the two ships face each other.
class ShipCutaway {
  const ShipCutaway._(this.id, this.rooms);

  final String id;

  /// Each room's box on the sprite, in sprite pixels, facing right.
  final Map<ShipRoom, Rect> rooms;

  static const Size spriteSize = Size(130, 84);

  static const rustyEel = ShipCutaway._('rusty_eel', {
    ShipRoom.helm: Rect.fromLTRB(12, 42, 42, 58),
    ShipRoom.guns: Rect.fromLTRB(44, 42, 69, 58),
    ShipRoom.bulwark: Rect.fromLTRB(71, 42, 98, 58),
    ShipRoom.hold: Rect.fromLTRB(12, 60, 98, 75),
  });
  static const raiderSkiff = ShipCutaway._('raider_skiff', {
    ShipRoom.helm: Rect.fromLTRB(16, 42, 43, 58),
    ShipRoom.guns: Rect.fromLTRB(45, 42, 68, 58),
    ShipRoom.bulwark: Rect.fromLTRB(70, 42, 94, 58),
    ShipRoom.hold: Rect.fromLTRB(16, 60, 94, 75),
  });
  static const corsairBrig = ShipCutaway._('corsair_brig', {
    ShipRoom.helm: Rect.fromLTRB(10, 42, 42, 58),
    ShipRoom.guns: Rect.fromLTRB(44, 42, 70, 58),
    ShipRoom.bulwark: Rect.fromLTRB(72, 42, 100, 58),
    ShipRoom.hold: Rect.fromLTRB(10, 60, 100, 75),
  });
  static const inquisitionCutter = ShipCutaway._('inquisition_cutter', {
    ShipRoom.helm: Rect.fromLTRB(12, 42, 41, 58),
    ShipRoom.guns: Rect.fromLTRB(43, 42, 68, 58),
    ShipRoom.bulwark: Rect.fromLTRB(70, 42, 96, 58),
    ShipRoom.hold: Rect.fromLTRB(12, 60, 96, 75),
  });
  static const voidBarge = ShipCutaway._('void_barge', {
    ShipRoom.helm: Rect.fromLTRB(10, 42, 44, 58),
    ShipRoom.guns: Rect.fromLTRB(46, 42, 74, 58),
    ShipRoom.bulwark: Rect.fromLTRB(76, 42, 106, 58),
    ShipRoom.hold: Rect.fromLTRB(10, 60, 106, 75),
  });

  static const enemies = [
    raiderSkiff,
    corsairBrig,
    inquisitionCutter,
    voidBarge,
  ];

  /// The enemy ship [id] (enemy_ships.json `shipName`) or, for one without
  /// a sprite of its own, the one nearest its size.
  static ShipCutaway forEnemy(String? id, ShipState ship) {
    for (final c in enemies) {
      if (c.id == id) return c;
    }
    final hull = ship.maxHull;
    if (hull <= 65) return raiderSkiff;
    if (hull <= 85) return corsairBrig;
    if (hull <= 110) return inquisitionCutter;
    return voidBarge;
  }

  /// How far the Eel has been refitted, 0 to 2, from her rooms' levels:
  /// a crow's nest at 2, iron plates on the bulwark at 3.
  static int refitOf(ShipState ship) {
    final levels = [for (final r in ShipRoom.values) ship.room(r).level];
    final mean = levels.reduce((a, b) => a + b) / levels.length;
    return mean >= 3
        ? 2
        : mean >= 2
            ? 1
            : 0;
  }

  /// The sprite for this ship: battered (holed, sails torn) below half
  /// its hull; the Eel's also by her [refit].
  String asset({required bool battered, int refit = 0}) {
    final level = id == rustyEel.id ? '_${refit.clamp(0, 2)}' : '';
    return 'assets/visuals/ship_cutaways/$id$level'
        '${battered ? '_battered' : ''}.png';
  }

  /// [room]'s box on a sprite drawn [width] wide, mirrored when [flip].
  Rect roomRect(ShipRoom room, double width, {required bool flip}) {
    final k = width / spriteSize.width;
    final r = rooms[room]!;
    final left = flip ? spriteSize.width - r.right : r.left;
    return Rect.fromLTWH(left * k, r.top * k, r.width * k, r.height * k);
  }
}

/// What is happening inside one room, drawn in the sprite's pixels over
/// its interior: the hands stationed there, a fire on the floor, the dark
/// of a room knocked out, water rising in a leaking hold.
class RoomArtPainter extends CustomPainter {
  const RoomArtPainter({
    required this.unit,
    this.crew = const [],
    this.onFire = false,
    this.down = false,
    this.water = 0,
    this.flip = false,
    required this.ember,
    required this.gold,
    required this.blood,
    required this.tide,
  });

  /// Screen pixels per sprite pixel.
  final double unit;

  /// The tunic colour of each hand standing in the room.
  final List<Color> crew;
  final bool onFire;
  final bool down;

  /// Rows of water in the hold (two a leak).
  final int water;

  /// The ship is mirrored: its crew face the other way.
  final bool flip;
  final Color ember, gold, blood, tide;

  static const _skin = Color(0xFFDEB28C);
  static const _hair = Color(0xFF3A2418);
  static const _dark = Color(0xFF141217);

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / unit).floor();
    final rows = (size.height / unit).floor();
    final paint = Paint()..isAntiAlias = false;
    void px(num x, num y, Color c, [num w = 1, num h = 1]) {
      if (x < 0 || y < 0 || x >= cols || y >= rows) return;
      paint.color = c;
      canvas.drawRect(
          Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit), paint);
    }

    // The floor is the room's last row.
    final floor = rows - 2;
    for (var i = 0; i < crew.length; i++) {
      // Hands stand along the floor from the far wall in.
      final x = flip ? cols - 6 - i * 6 : 2 + i * 6;
      final t = crew[i];
      px(x + 1, floor - 7, _hair, 2);
      px(x + 1, floor - 6, _skin, 2, 2);
      px(flip ? x + 1 : x + 2, floor - 6, _dark);
      px(x, floor - 4, t, 4, 3);
      px(flip ? x + 3 : x, floor - 2, _skin);
      px(x + 1, floor - 1, _hair, 2);
      px(x + 1, floor, _dark, 2);
    }
    if (onFire) {
      // Soot on the ceiling, flames along the floor.
      px(0, 0, _dark.withValues(alpha: 0.55), cols, 2);
      for (var x = 1; x < cols - 1; x++) {
        if ((x * 7) % 5 == 0) continue;
        final h = 1 + (x * 13 + 5) % 5;
        for (var j = 0; j < h; j++) {
          px(
              x,
              floor - j,
              j == 0
                  ? const Color(0xFFFFBE5A)
                  : j < h - 1
                      ? ember
                      : (x % 3 == 0 ? blood : gold));
        }
      }
    }
    if (water > 0) {
      final top = rows - water;
      px(0, top + 1, tide.withValues(alpha: 0.55), cols, water - 1);
      px(0, top, const Color(0xFF96DCD6).withValues(alpha: 0.85), cols);
      for (final x in [cols ~/ 5, cols ~/ 2, cols - cols ~/ 5]) {
        px(x, 2, const Color(0xFF96DCD6));
        px(x, 5, tide);
      }
    }
    if (down) {
      px(0, 0, _dark.withValues(alpha: 0.6), cols, rows);
      final cx = cols ~/ 2, cy = rows ~/ 2;
      for (var k = -3; k <= 3; k++) {
        px(cx + k, cy + k, blood);
        px(cx + k, cy - k, blood);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoomArtPainter old) =>
      old.unit != unit ||
      old.onFire != onFire ||
      old.down != down ||
      old.water != water ||
      old.flip != flip ||
      old.crew.length != crew.length ||
      !List.generate(crew.length, (i) => crew[i] == old.crew[i])
          .every((same) => same);
}
