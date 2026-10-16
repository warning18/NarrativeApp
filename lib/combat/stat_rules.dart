// What the abilities do in a fight (docs/proposals/stat-scale.md, option
// C, the user's decisions): each profession has one damage stat, and every
// point of it gained after the hero is made is +1 damage; Constitution is
// health, Dexterity dodge, Perception a warrior's block (and a ranger's or
// rogue's second source of crit and dodge), Wisdom the mana pool, Luck
// crits and the rarity of a pick. The fight's numbers are on the small
// scale (a hero starts with 20 to 30 health and hits for about 4), so one
// point shows.
//
// Pure: the session applies the gains (PlayerSessionNotifier), the fight
// and the simulator read the chances.
import 'dart:math';

/// The health one point of Constitution gives.
const int healthPerConstitution = 5;

/// The max health each level brings by itself.
const int levelHealthGain = 4;

/// The stat picks each level brings (docs/proposals/stat-scale.md: one a
/// level, its rarity drawn, see drawStatPick).
const int levelStatPicks = 1;

/// The ability that raises a profession's damage, '' for none: Strength
/// for a warrior, Dexterity for a ranger or a rogue, Intelligence for a
/// mage or a cleric.
String damageStatOf(String? professionId) => switch (professionId) {
      'warrior' => 'strength',
      'ranger' || 'rogue' => 'dexterity',
      'mage' || 'cleric' => 'intelligence',
      _ => '',
    };

/// The base damage and max health [gains] (ability -> points) bring to a
/// hero of [professionId], beside the abilities themselves: +1 base damage
/// per point of the damage stat, [healthPerConstitution] per point of
/// Constitution. A lost point takes as much away.
({int baseDamage, int maxHealth}) abilityGainEffects(
    Map<String, int> gains, String? professionId) {
  final stat = damageStatOf(professionId);
  return (
    baseDamage: stat.isEmpty ? 0 : gains[stat] ?? 0,
    maxHealth: (gains['constitution'] ?? 0) * healthPerConstitution,
  );
}

/// Dodge (0-100): 5% and [dodgePerDexterity] a point of Dexterity, at most
/// [dodgeCap].
const double dodgePerDexterity = 2;
const double dodgeCap = 30;

/// Critical hits (0-100): 5% and [critPerLuck] a point of Luck, at most
/// [critCap] (gear's own bonus may go a little past it, see
/// combat_engine.dart).
const double critPerLuck = 1.5;
const double critCap = 35;

/// A ranger's or a rogue's Perception: a second, smaller source of crit and
/// dodge, after Dexterity -- this much of each a point.
const double perceptionCritPerPoint = 1;
const double perceptionDodgePerPoint = 1;

/// Whether [professionId] reads a fight with its eyes (a ranger, a rogue):
/// its Perception adds to its crit and dodge.
bool sharpEyed(String? professionId) =>
    professionId == 'ranger' || professionId == 'rogue';

/// The crit chance a ranger's or rogue's Perception adds (0 for the others).
double perceptionCritBonus(String? professionId, int perception) =>
    sharpEyed(professionId) ? max(0, perception) * perceptionCritPerPoint : 0;

/// The dodge chance a ranger's or rogue's Perception adds (0 for the
/// others); inside [dodgeCap] with Dexterity's.
double perceptionDodgeBonus(String? professionId, int perception) =>
    sharpEyed(professionId) ? max(0, perception) * perceptionDodgePerPoint : 0;

/// A warrior's block (0-100): [blockPerPerception] a point of Perception,
/// at most [blockCap]; a blocked blow loses half (see [blockedBlow]). 0 for
/// every other profession.
const double blockPerPerception = 3;
const double blockCap = 30;

double blockChanceFor(String? professionId, int perception) =>
    professionId == 'warrior'
        ? min(blockCap, max(0, perception) * blockPerPerception)
        : 0;

/// What is left of a blow of [damage] a warrior blocks: half, rounded down.
int blockedBlow(int damage) => damage ~/ 2;
