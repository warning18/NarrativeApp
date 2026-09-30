import 'dart:math';

import 'combat_engine.dart';

/// Helpers for the dice tampering moves (see [DiceTamper] in
/// enemy_intent.dart) and for Luck nudges.

/// A Mirror hits back with the party's best blow of the round, but never
/// for less than [mirrorFloorShare] or more than [mirrorCapMultiplier] of
/// the enemy's own damage.
const double mirrorFloorShare = 0.5;
const double mirrorCapMultiplier = 2.0;

int mirrorDamage({required int bestPartyHit, required int enemyDamage}) {
  final floor = (enemyDamage * mirrorFloorShare).round();
  final cap = (enemyDamage * mirrorCapMultiplier).round();
  return bestPartyHit.clamp(floor, max(floor, cap));
}

/// [face] under a Curse: it keeps its number but strikes, with Pain (see
/// face_keywords.dart) -- a Guard, a Heal or a Mana face becomes an Attack
/// of the same number, and a skill keeps its skill.
DiceFaceResult cursedFace(DiceFaceResult face) {
  final struck = face.type == 'Defend' ||
          face.type == 'Heal' ||
          face.type == 'Mana' ||
          face.type == 'Empty'
      ? face.asBasic('Attack', value: max(1, face.value))
      : face;
  return struck.withKeywords({...struck.keywords, FaceKeyword.pain});
}

/// [face] under a Silence: a skill set on a basic face falls back to that
/// face; a skill face of its own lands blank.
DiceFaceResult silencedFace(DiceFaceResult face) {
  if (face.type != 'Skill') return face;
  if (face.isChanneled) return face.asBasic(face.channeledFrom);
  return face.asBasic('Empty', value: 0);
}

/// The face of a die a Curse picks: a random face that isn't already
/// cursed, or null when every face is.
int? curseTargetFace(int faceCount, Set<int> alreadyCursed, Random random) {
  final open = [
    for (var i = 0; i < faceCount; i++)
      if (!alreadyCursed.contains(i)) i,
  ];
  if (open.isEmpty) return null;
  return open[random.nextInt(open.length)];
}

/// The member whose die a Hex rolls again: the one whose landed face is
/// worth the most, by [worth] (member id → what the face deals, heals,
/// blocks and gives). Null when nothing landed.
String? hexVictim(Map<String, int> worth) {
  String? best;
  var bestWorth = -1;
  for (final entry in worth.entries) {
    if (entry.value > bestWorth) {
      best = entry.key;
      bestWorth = entry.value;
    }
  }
  return best;
}

/// Luck nudges (v1.182): every [luckPerNudge] points of the party's best
/// Luck give one nudge a fight, up to [maxNudges]. A nudge turns a landed
/// die to its opposite face.
const int luckPerNudge = 3;
const int maxNudges = 3;

int nudgesForLuck(int luck) => (luck ~/ luckPerNudge).clamp(0, maxNudges);

/// The face opposite [index] on a die of [faceCount] faces: the first and
/// the last, the second and the one before last, and so on (1 and 6, 2 and
/// 5, 3 and 4 on a six-sided die).
int oppositeFaceIndex(int index, int faceCount) =>
    faceCount <= 0 ? index : (faceCount - 1 - index).clamp(0, faceCount - 1);

/// The string keys of a tamper's name and rules line.
String tamperLabelKey(DiceTamper tamper) => 'tamper_${tamper.name}';
String tamperDescriptionKey(DiceTamper tamper) => 'tamper_${tamper.name}_desc';
