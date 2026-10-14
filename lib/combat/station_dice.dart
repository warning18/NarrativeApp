// Station dice (v1.218): at sea each hand has a die at their station, and
// the die shows only the faces that room can use -- the guns, the attack
// faces; the bulwark, the defend faces; the hold, heal and mana; the helm,
// stun and weaken. The die lands once a turn, on a face that depends only
// on the battle, the turn, the hand and the room (so moving a hand about
// cannot shake out a better roll), and what it lands on works for the turn
// as long as the hand stands there and is not busy.
import 'dart:math';

import '../utils/face_style.dart';
import 'combat_engine.dart' show DiceFaceResult;
import 'ship_combat.dart';

/// The kinds of face each station can use.
const Map<ShipRoom, Set<FaceKind>> stationFaceKinds = {
  ShipRoom.guns: {FaceKind.attack, FaceKind.poison},
  ShipRoom.bulwark: {FaceKind.defend},
  ShipRoom.hold: {FaceKind.heal, FaceKind.mana},
  ShipRoom.helm: {FaceKind.stun, FaceKind.weaken},
};

/// One face of a hand's die, with what it does (a Skill face reads as the
/// skill it casts).
class StationFace {
  const StationFace(this.face, this.kind);

  final DiceFaceResult face;
  final FaceKind kind;

  int get value => face.value;
}

/// A hand's die: every face it carries.
class CrewDie {
  const CrewDie(this.faces);

  final List<StationFace> faces;

  /// The faces [room] can use, in the die's order.
  List<StationFace> forRoom(ShipRoom room) => [
        for (final f in faces)
          if (stationFaceKinds[room]!.contains(f.kind)) f,
      ];
}

/// How a landed face works: a share of the round's shots (in or out) it
/// moves, from a twentieth to three tenths.
double stationShare(int value) => (value * 0.01).clamp(0.05, 0.30);

/// Hull a landed heal face patches when the round ends.
int stationPatch(int value) => (value ~/ 2).clamp(1, 10);

/// A die landed: the face it stopped on, or none when it carries no face
/// its room can use.
class StationRoll {
  const StationRoll(this.crewId, this.room, this.face);

  final String crewId;
  final ShipRoom room;
  final StationFace? face;

  FaceKind? get kind => face?.kind;
  int get value => face?.value ?? 0;
}

/// [die]'s landing for [crewId] at [room] on [turn] of the battle seeded
/// [seed].
StationRoll rollStationDie(
    CrewDie die, String crewId, ShipRoom room, int turn, int seed) {
  final faces = die.forRoom(room);
  if (faces.isEmpty) return StationRoll(crewId, room, null);
  final rng = Random(Object.hash(seed, turn, crewId, room.index) & 0x3fffffff);
  return StationRoll(crewId, room, faces[rng.nextInt(faces.length)]);
}
