// The context rules (v5.2 step 4, docs/proposals/profession-clan-mechanics.md
// "Fight length: a menu tied to the world"): one rule a fight, chosen by
// its place, on top of the default rules every fight plays and of the Tide
// (fight_length.dart), which rises under every rule. A boss's fight keeps
// the Tide's own boss step: that is its enrage.
//
// - Town guards: in a city, a town or a district, from [risingStartRound],
//   the watch breaks the fight up; the side ahead on health wins it, else
//   both walk away (nothing won, nothing lost).
// - The rising ground, from [risingStartRound], one level more each round:
//   - marsh mist (the reeds): both sides lose [mistTickStep] of their max
//     health a level, each round;
//   - desert heat (the dunes, the salt flats): both sides lose
//     [heatTickStep] a level, each round, and heal [heatHealFactor] as much;
//   - rising water (the waves, the cliffs) and the collapse (a hall): from
//     the Tide's round, the party strikes and heals [waterBlowStep] more a
//     level, the enemies strike [waterEnemyStep] more, up to
//     [waterMaxLevel] levels;
//   - sanctified ground (a holy place): heals fade [sanctifiedHealStep] a
//     level, and Light strikes [sanctifiedLightStep] harder a level.
// The ground wounds but never finishes: a tick leaves at least 1 health.
//
// Measured in docs/simulation/context-rules.md. Pure rules; the fight
// screen and the playthrough simulator play them.
import 'dart:math';

import 'field_anomaly.dart' show FightStage;
import 'fight_length.dart';

/// The rule a fight plays besides the default ones and the Tide.
enum ContextRule {
  tide,
  townGuards,
  marshMist,
  desertHeat,
  risingWater,
  sanctified,
}

/// The rule of a fight on [stage]: the watch in a city ([city]), a holy
/// place's ground ([holy]), the stage's own ground, and the Tide alone
/// where none of these applies or a boss is fought ([bossFight]).
ContextRule contextRuleFor({
  required FightStage stage,
  bool bossFight = false,
  bool city = false,
  bool holy = false,
}) {
  if (bossFight) return ContextRule.tide;
  if (city) return ContextRule.townGuards;
  if (holy) return ContextRule.sanctified;
  return switch (stage) {
    FightStage.reeds => ContextRule.marshMist,
    FightStage.dunes || FightStage.saltFlats => ContextRule.desertHeat,
    FightStage.waves ||
    FightStage.cliffs ||
    FightStage.hall =>
      ContextRule.risingWater,
    _ => ContextRule.tide,
  };
}

/// The place kinds where the watch keeps the peace.
const Set<String> guardedPlaceKinds = {'city', 'town', 'district'};

/// The round the ground starts rising in, and the watch comes. Its omen
/// comes the round before.
const int risingStartRound = 6;

/// How far the ground has risen in [round]: 0 before [risingStartRound],
/// 1 in it, one more each round after.
int risingLevel(int round) => max(0, round - risingStartRound + 1);

const double mistTickStep = 0.01;
const double heatTickStep = 0.01;
const double heatHealFactor = 0.8;
const double waterBlowStep = 0.10;

/// The enemies' share of the water: half the party's (a cleric's long
/// fights met it hardest).
const double waterEnemyStep = 0.05;

/// The water rises from the Tide's own round, and stops at this level.
const int waterStartRound = tideStartRound;
const int waterMaxLevel = 3;
const double sanctifiedHealStep = 0.10;
const double sanctifiedLightStep = 0.10;

/// How far the water has risen in [round]: 0 to [waterMaxLevel].
int waterLevel(int round) =>
    min(max(0, round - waterStartRound + 1), waterMaxLevel);

extension ContextRuleEffects on ContextRule {
  /// How far this rule has risen in [round] (0: not yet).
  int levelAt(int round) => switch (this) {
        ContextRule.tide => tideLevel(round),
        ContextRule.risingWater => waterLevel(round),
        _ => risingLevel(round),
      };

  /// [damage] of [element], struck in [round] by the party ([byParty]) or
  /// an enemy ([bossFight]: a boss is in the fight; [enemyTideCap]: the
  /// level the enemies' Tide stops at, see fightTideCap): the Tide's, then
  /// the place's.
  int blow(int damage, int round,
      {required bool byParty,
      String element = 'None',
      bool bossFight = false,
      int? enemyTideCap}) {
    if (damage <= 0) return damage;
    final tided = tideDamage(damage, round,
        byParty: byParty, bossFight: bossFight, enemyCap: enemyTideCap);
    return switch (this) {
      ContextRule.risingWater => (tided *
              (1 +
                  (byParty ? waterBlowStep : waterEnemyStep) *
                      waterLevel(round)))
          .round(),
      ContextRule.sanctified => element == 'Light'
          ? (tided * (1 + sanctifiedLightStep * risingLevel(round))).round()
          : tided,
      _ => tided,
    };
  }

  /// [amount] healed in [round].
  int heal(int amount, int round) {
    if (amount <= 0) return amount;
    return switch (this) {
      ContextRule.desertHeat when risingLevel(round) > 0 =>
        (amount * heatHealFactor).round(),
      ContextRule.risingWater =>
        (amount * (1 + waterBlowStep * waterLevel(round))).round(),
      ContextRule.sanctified =>
        (amount * max(0.0, 1 - sanctifiedHealStep * risingLevel(round)))
            .round(),
      _ => amount,
    };
  }

  /// What the ground takes from a side of [maxHealth] in [round].
  int tick(int maxHealth, int round) {
    final level = risingLevel(round);
    if (level == 0) return 0;
    final step = switch (this) {
      ContextRule.marshMist => mistTickStep,
      ContextRule.desertHeat => heatTickStep,
      _ => 0.0,
    };
    return step == 0 ? 0 : max(1, (maxHealth * step * level).round());
  }

  /// Whether the watch breaks the fight up in [round].
  bool guardsCome(int round) =>
      this == ContextRule.townGuards && round >= risingStartRound;

  /// The l10n key stem of the rule's log lines (`context_<stem>_omen`,
  /// `context_<stem>_log`); null for the Tide, which has its own.
  String? get logStem => switch (this) {
        ContextRule.tide => null,
        ContextRule.townGuards => 'guards',
        ContextRule.marshMist => 'mist',
        ContextRule.desertHeat => 'heat',
        ContextRule.risingWater => 'water',
        ContextRule.sanctified => 'holy',
      };
}

/// [health] after the ground took [amount]: never under 1.
int afterTick(int health, int amount) =>
    health <= 1 ? health : max(1, health - amount);

/// Whether the party is ahead when the watch comes: its share of health
/// left ([partyHealth] of [partyMax]) above the enemies'.
bool partyAheadOnHealth({
  required int partyHealth,
  required int partyMax,
  required int enemyHealth,
  required int enemyMax,
}) =>
    partyMax > 0 &&
    (enemyMax <= 0 || partyHealth / partyMax > enemyHealth / enemyMax);

// --- Reinforcements (v5.2 step 6, PR 3) -------------------------------------
//
// In a place a clan holds (clan_power.dart's holderOf), from
// [reinforceStartRound] its people join the fight: on the party's side when
// the character stands Friend or better with the holder (each foe takes
// [_allyShare] of its max health a round), against it when the holder hunts
// the character or is their nemesis (the party takes [_foeShare] of its max
// health a round). On top of the fight's context rule; never in a boss's
// fight, and never the finishing blow (the execute is). Measured in
// docs/simulation/reinforcements.md.

/// Who joins a fight in a held place.
enum Reinforcement { none, allies, foes }

const int reinforceStartRound = 8;
const double _allyShare = 0.05;
const double _foeShare = 0.05;

/// Whether reinforcements come in [round] of a fight ([bossFight]: never).
bool reinforcementsCome(int round, {bool bossFight = false}) =>
    !bossFight && round >= reinforceStartRound;

/// What the allies strike a foe of [enemyMax] health for in [round] (0
/// before they come).
int allyStrike(int enemyMax, int round, {bool bossFight = false}) =>
    reinforcementsCome(round, bossFight: bossFight)
        ? max(1, (enemyMax * _allyShare).round())
        : 0;

/// What the holder's people strike a party member of [partyMax] health
/// for in [round] (0 before they come).
int foeStrike(int partyMax, int round, {bool bossFight = false}) =>
    reinforcementsCome(round, bossFight: bossFight)
        ? max(1, (partyMax * _foeShare).round())
        : 0;
