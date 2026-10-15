// The context rules (v5.2 step 4, docs/proposals/profession-clan-mechanics.md
// "Fight length: a menu tied to the world"): one rule a fight, chosen by
// the place or the foe, on top of the default rules every fight plays
// (fight_length.dart). The Tide is what a fight meets when none applies.
//
// - Boss enrage: from [enrageRound], a boss strikes [enrageMultiplier]
//   times as hard.
// - Town guards: in a city, from [risingStartRound], the watch breaks the
//   fight up; the side ahead on health wins it, else both walk away.
// - The rising ground, from [risingStartRound], one level more each round:
//   - marsh mist (the reeds): both sides lose [mistTickStep] of their max
//     health a level, each round;
//   - desert heat (the dunes, the salt flats): both sides lose
//     [heatTickStep] a level, each round, and heal [heatHealFactor] as much;
//   - rising water (the waves, the cliffs) and the collapse (a hall): both
//     sides strike [waterBlowStep] harder a level;
//   - sanctified ground (a holy place): heals fade [sanctifiedHealStep] a
//     level, and Light strikes [sanctifiedLightStep] harder a level.
// The ground wounds but never finishes: a tick leaves at least 1 health.
//
// Pure rules; the fight screen and the playthrough simulator play them.
import 'dart:math';

import 'field_anomaly.dart' show FightStage;
import 'fight_length.dart';

/// The rule a fight plays besides the default ones.
enum ContextRule {
  tide,
  bossEnrage,
  townGuards,
  marshMist,
  desertHeat,
  risingWater,
  sanctified,
}

/// The rule of a fight on [stage]: a boss's enrage first ([bossFight]),
/// then the watch in a city ([city]), a holy place's ground ([holy]), the
/// stage's own ground, and the Tide where none of these applies.
ContextRule contextRuleFor({
  required FightStage stage,
  bool bossFight = false,
  bool city = false,
  bool holy = false,
}) {
  if (bossFight) return ContextRule.bossEnrage;
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

/// The round the ground starts rising in, and the watch comes.
const int risingStartRound = 6;

/// How far the ground has risen in [round]: 0 before [risingStartRound],
/// 1 in it, one more each round after.
int risingLevel(int round) => max(0, round - risingStartRound + 1);

const double mistTickStep = 0.01;
const double heatTickStep = 0.01;
const double heatHealFactor = 0.8;
const double waterBlowStep = 0.10;
const double sanctifiedHealStep = 0.10;
const double sanctifiedLightStep = 0.10;

const int enrageRound = 10;
const double enrageMultiplier = 1.5;

extension ContextRuleEffects on ContextRule {
  /// [damage] of [element], struck in [round] by the party ([byParty]) or
  /// an enemy ([bossFight]: a boss is in the fight).
  int blow(int damage, int round,
      {required bool byParty,
      String element = 'None',
      bool bossFight = false}) {
    if (damage <= 0) return damage;
    final level = risingLevel(round);
    return switch (this) {
      ContextRule.tide =>
        tideDamage(damage, round, byParty: byParty, bossFight: bossFight),
      ContextRule.bossEnrage => !byParty && round >= enrageRound
          ? (damage * enrageMultiplier).round()
          : damage,
      ContextRule.risingWater => (damage * (1 + waterBlowStep * level)).round(),
      ContextRule.sanctified => element == 'Light'
          ? (damage * (1 + sanctifiedLightStep * level)).round()
          : damage,
      _ => damage,
    };
  }

  /// [amount] healed in [round].
  int heal(int amount, int round) {
    if (amount <= 0) return amount;
    final level = risingLevel(round);
    if (level == 0) return amount;
    return switch (this) {
      ContextRule.desertHeat => (amount * heatHealFactor).round(),
      ContextRule.sanctified =>
        (amount * max(0.0, 1 - sanctifiedHealStep * level)).round(),
      _ => amount,
    };
  }

  /// What the ground takes from a side of [maxHealth] at [round]'s end.
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
}

/// [health] after the ground took [amount]: never under 1.
int afterTick(int health, int amount) =>
    health <= 1 ? health : max(1, health - amount);
