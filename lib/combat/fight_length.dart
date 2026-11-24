// How long a fight lasts (docs/proposals/profession-clan-mechanics.md,
// v5.2, "Fight length: a menu tied to the world"): the default rules every
// fight plays, and the Tide where no rule of the place or the foe applies.
// Today's fights ran 7 rounds in chapter 1 to 30 in chapter 7, and a
// cleric's 39: these keep them near 10 to 12 without a cap.
//
// - Healing fatigue: each heal a member gives in a fight heals
//   [_healFatigueStep] less than the one before, never under
//   [_healFatigueFloor] (what made a healer's fights endless).
// - Execute: a foe struck this round and left under [executeShare] of its
//   health falls (never a boss).
// - Morale: a hurt foe (under [_moraleFleeShare]) may flee, at
//   [moraleFleeChance] a round; a fled foe pays part of its spoils, as a
//   Skittish one does.
// - The pack breaks: when a pack's leader (its biggest, see
//   [packLeaderIndex]) falls, each other foe flees at [packBreakChance].
//   Neither in a boss's fight: its escort stands by it.
// - The Tide: from round [tideStartRound], blows grow each round, the
//   party's by [tidePartyStep], the enemies' by [tideEnemyStep] (by
//   [tideBossEnemyStep] in a boss's fight). A boss whose record sets
//   `tideCap` (the claimants, wave 17) stops the enemies' share at that
//   level ([fightTideCap]); the party's keeps rising.
// - One heal: a boss whose record sets `healsOnce` (the claimants) mends
//   itself once a fight, by a phase or a move; then its heal moves leave
//   its list ([withoutHealMoves]) and its later phases heal nothing.
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

/// The enemies' Tide level in [round], stopped at [cap] when the fight has
/// one (see [fightTideCap]).
int enemyTideLevel(int round, {int? cap}) {
  final level = tideLevel(round);
  return cap == null ? level : min(level, cap);
}

/// The lowest `tideCap` among a fight's [enemies] records (claimants:
/// wave 17), or null when none sets one: the level the enemies' Tide stops
/// at in that fight.
int? fightTideCap(Iterable<Map<String, dynamic>> enemies) {
  int? cap;
  for (final e in enemies) {
    final c = (e['tideCap'] as num?)?.toInt();
    if (c != null && (cap == null || c < cap)) cap = c;
  }
  return cap;
}

/// The factor on the party's blows in [round].
double _tidePartyMultiplier(int round) => 1 + tidePartyStep * tideLevel(round);

/// The factor on the enemies' blows in [round] ([bossFight]: a boss is
/// in the fight; [cap]: the fight's [fightTideCap]).
double tideEnemyMultiplier(int round, {bool bossFight = false, int? cap}) =>
    1 +
    (bossFight ? tideBossEnemyStep : tideEnemyStep) *
        enemyTideLevel(round, cap: cap);

/// [damage] grown by the Tide in [round], for the party's blows or the
/// enemies' ([bossFight]: a boss is in the fight; [enemyCap]: the level
/// the enemies' Tide stops at, see [fightTideCap]).
int tideDamage(int damage, int round,
    {required bool byParty, bool bossFight = false, int? enemyCap}) {
  if (damage <= 0 || tideLevel(round) == 0) return damage;
  final factor = byParty
      ? _tidePartyMultiplier(round)
      : tideEnemyMultiplier(round, bossFight: bossFight, cap: enemyCap);
  return (damage * factor).round();
}

/// Whether the enemy [record] mends itself only once a fight (`healsOnce`,
/// the claimants since wave 17).
bool healsOnce(Map<String, dynamic> record) => record['healsOnce'] == true;

/// The enemy [record] without its heal moves: those whose skill in
/// [skills] mends (`healAmount` above 0). What a [healsOnce] enemy keeps
/// once its heal is spent.
Map<String, dynamic> withoutHealMoves(
    Map<String, dynamic> record, Map<String, dynamic> skills) {
  final moves = (record['skillMoves'] as List?) ?? const [];
  bool heals(Object? move) {
    final id = move is Map ? move['skillID']?.toString() : null;
    final skill = id == null ? null : skills[id];
    return skill is Map && ((skill['healAmount'] as num?) ?? 0) > 0;
  }

  return {
    ...record,
    'skillMoves': [
      for (final m in moves)
        if (!heals(m)) m
    ],
  };
}

/// What each heal given before takes off the next one, and how low it goes.
const double _healFatigueStep = 0.05;
const double _healFatigueFloor = 0.30;

/// The factor on a heal after [healsBefore] heals by the same member this
/// fight.
double healFatigueFactor(int healsBefore) =>
    max(_healFatigueFloor, 1 - _healFatigueStep * healsBefore);

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
const double _moraleFleeShare = 0.25;
const double moraleFleeChance = 0.5;

/// Whether a foe at [health] of [maxHealth] wavers.
bool wavers({required int health, required int maxHealth}) =>
    health > 0 && health < maxHealth * _moraleFleeShare;

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
