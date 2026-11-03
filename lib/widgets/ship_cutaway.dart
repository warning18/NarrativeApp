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
  /// a sprite of its own, the one nearest its size. The sea beasts (see
  /// sea_beasts.dart) have no sprite of their own yet and borrow one.
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
