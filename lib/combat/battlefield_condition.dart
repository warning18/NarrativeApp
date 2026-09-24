import 'dart:math';

import 'combat_engine.dart';

/// A one-off circumstance the whole fight happens under, announced on the
/// setup screen before the first die is rolled -- the "same enemy, not the
/// same fight" lever alongside enemy affixes. Rolled once per fight in
/// [rollBattlefieldCondition]; applied by FightScreen.
enum BattlefieldCondition {
  /// The enemies strike before the party's first roll, and nothing can be
  /// read off them that first round.
  ambush,

  /// Every telegraph reads one tier worse than the party's Perception
  /// would normally allow.
  dark,

  /// Pack fights only: at most [crampedMaxActingEnemies] enemies can reach
  /// the party each round; the rest hold back.
  cramped,

  /// Every Defend face the party rolls blocks [highGroundBlockMultiplier]
  /// times more.
  highGround,

  /// Every Heal face (and potion) restores [shrineHealMultiplier] times
  /// more.
  shrine,
}

/// Odds any given fight opens under a condition at all.
const double battlefieldConditionChance = 0.25;

const int crampedMaxActingEnemies = 2;
const double highGroundBlockMultiplier = 1.5;
const double shrineHealMultiplier = 1.5;

String conditionLabelKey(BattlefieldCondition condition) => switch (condition) {
      BattlefieldCondition.ambush => 'condition_ambush',
      BattlefieldCondition.dark => 'condition_dark',
      BattlefieldCondition.cramped => 'condition_cramped',
      BattlefieldCondition.highGround => 'condition_high_ground',
      BattlefieldCondition.shrine => 'condition_shrine',
    };

String conditionDescriptionKey(BattlefieldCondition condition) =>
    '${conditionLabelKey(condition)}_desc';

/// Added to the spoils-chest fortune roll for winning under [condition] --
/// the two that make the fight harder pay out; the two that help don't.
int conditionFortuneBonus(BattlefieldCondition? condition) =>
    switch (condition) {
      BattlefieldCondition.ambush || BattlefieldCondition.dark => 10,
      BattlefieldCondition.cramped => 5,
      _ => 0,
    };

/// Rolls this fight's condition, or null (the common case). Cramped only
/// makes sense against three or more enemies, so it's left out of the pool
/// for anything smaller.
BattlefieldCondition? rollBattlefieldCondition({
  required int enemyCount,
  required Random random,
  double chance = battlefieldConditionChance,
}) {
  if (random.nextDouble() >= chance) return null;
  final pool = <BattlefieldCondition>[
    BattlefieldCondition.ambush,
    BattlefieldCondition.dark,
    if (enemyCount >= 3) BattlefieldCondition.cramped,
    BattlefieldCondition.highGround,
    BattlefieldCondition.shrine,
  ];
  return pool[random.nextInt(pool.length)];
}

/// [tier] one step worse, for [BattlefieldCondition.dark].
TelegraphTier darkenedTier(TelegraphTier tier) => switch (tier) {
      TelegraphTier.full => TelegraphTier.category,
      TelegraphTier.category => TelegraphTier.target,
      TelegraphTier.target => TelegraphTier.none,
      TelegraphTier.none => TelegraphTier.none,
    };
