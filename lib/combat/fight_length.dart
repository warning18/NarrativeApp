// How long a fight lasts (docs/proposals/profession-clan-mechanics.md,
// v5.2, "Fight length: a menu tied to the world"): the default rules every
// fight plays, and the Tide where no rule of the place or the foe applies.
// Today's fights ran 7 rounds in chapter 1 to 30 in chapter 7, and a
// cleric's 39: these keep them near 10 to 12 without a cap.
//
// - Healing fatigue: each heal a member gives in a fight heals
//   [healFatigueStep] less than the one before, never under
//   [healFatigueFloor] (what made a healer's fights endless).
// - Execute: a foe struck this round and left under [executeShare] of its
//   health falls (never a boss).
// - Morale: a hurt foe (under [moraleFleeShare]) may flee, at
//   [moraleFleeChance] a round; a fled foe pays part of its spoils, as a
//   Skittish one does.
// - The pack breaks: when a pack's leader (its biggest, see
//   [packLeaderIndex]) falls, each other foe flees at [packBreakChance].
//   Neither in a boss's fight: its escort stands by it.
// - The Tide: from round [tideStartRound], blows grow each round, the
//   party's by [tidePartyStep], the enemies' by [tideEnemyStep] (by
//   [tideBossEnemyStep] in a boss's fight).
//
// Pure rules; the fight screen (fight_goals.dart, fight_rounds.dart) and
// the playthrough simulator (sim_combat.dart) play them.
import 'dart:math';

/// The round the Tide starts rising in.
const int tideStartRound = 8;

/// What each round of the Tide adds to the party's blows, and to the
/// enemies'.
const double tidePartyStep = 0.20;
const double tideEnemyStep = 0.10;

/// In a boss's fight the Tide grows the boss's side nearly as fast as the
/// party's: a boss stays the test it is (its own rule, an enrage, is to
/// come).
const double tideBossEnemyStep = 0.18;

/// How far the Tide has risen in [round]: 0 before [tideStartRound], 1 in
/// it, and one more each round after.
int tideLevel(int round) => max(0, round - tideStartRound + 1);

/// The factor on the party's blows in [round].
double tidePartyMultiplier(int round) => 1 + tidePartyStep * tideLevel(round);

/// The factor on the enemies' blows in [round] ([bossFight]: a boss is
/// in the fight).
double tideEnemyMultiplier(int round, {bool bossFight = false}) =>
    1 + (bossFight ? tideBossEnemyStep : tideEnemyStep) * tideLevel(round);

/// [damage] grown by the Tide in [round], for the party's blows or the
/// enemies' ([bossFight]: a boss is in the fight).
int tideDamage(int damage, int round,
    {required bool byParty, bool bossFight = false}) {
  if (damage <= 0 || tideLevel(round) == 0) return damage;
  final factor = byParty
      ? tidePartyMultiplier(round)
      : tideEnemyMultiplier(round, bossFight: bossFight);
  return (damage * factor).round();
}

/// What each heal given before takes off the next one, and how low it goes.
const double healFatigueStep = 0.05;
const double healFatigueFloor = 0.30;

/// The factor on a heal after [healsBefore] heals by the same member this
/// fight.
double healFatigueFactor(int healsBefore) =>
    max(healFatigueFloor, 1 - healFatigueStep * healsBefore);

/// [amount] healed after [healsBefore] heals by the same member (at least 1
/// when there is anything to heal).
int fatiguedHeal(int amount, int healsBefore) {
  if (amount <= 0) return amount;
  return max(1, (amount * healFatigueFactor(healsBefore)).round());
}

/// A foe struck under this share of its health falls.
const double executeShare = 0.10;

/// Whether a foe at [health] of [maxHealth], struck this round, falls. A
/// boss never does: its last phase is the fight's.
bool executes(
        {required int health, required int maxHealth, bool boss = false}) =>
    !boss && health > 0 && health < maxHealth * executeShare;

/// Under this share of its health, a foe that isn't a boss may flee, at
/// [moraleFleeChance] each round.
const double moraleFleeShare = 0.25;
const double moraleFleeChance = 0.5;

/// Whether a foe at [health] of [maxHealth] wavers.
bool wavers({required int health, required int maxHealth}) =>
    health > 0 && health < maxHealth * moraleFleeShare;

/// When a pack's leader falls, each other foe flees at this chance.
const double packBreakChance = 0.7;

/// The pack's leader: the biggest of [maxHealth] (the first on a tie)
/// among those that can lead ([eligible]: not a boss); null for a single
/// foe or no eligible one.
int? packLeaderIndex(List<int> maxHealth, List<bool> eligible) {
  if (maxHealth.length < 2) return null;
  int? best;
  for (var i = 0; i < maxHealth.length; i++) {
    if (!eligible[i]) continue;
    if (best == null || maxHealth[i] > maxHealth[best]) best = i;
  }
  return best;
}
