import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// What an enemy does with its turn (v1.162). Most turns are an [attack];
/// the other four change the fight's shape instead of just its numbers:
///
/// - [heal]: the enemy mends itself and doesn't swing.
/// - [guard]: it raises a guard that soaks the party's next hits.
/// - [charge]: it winds up; next turn the blow lands at double weight
///   unless the party breaks it first (see [chargeBroken]).
/// - [rally]: it rouses itself and every packmate to hit harder.
///
/// A skill says which with its `intent` field ('attack', 'heal', 'guard',
/// 'charge', 'rally'). A skill with no `intent` that only heals (no damageMod, a
/// healAmount) is a heal, so the player skills enemies borrow (Second
/// Wind, Stoneskin, Revive Prayer) mend the enemy instead of hitting.
enum EnemyIntent { attack, heal, guard, charge, rally }

EnemyIntent enemyIntentOf(Map<String, dynamic> skill) {
  switch (skill['intent']?.toString()) {
    // Said outright: an attack, even for a skill that only heals.
    case 'attack':
      return EnemyIntent.attack;
    case 'heal':
      return EnemyIntent.heal;
    case 'guard':
      return EnemyIntent.guard;
    case 'charge':
      return EnemyIntent.charge;
    case 'rally':
      return EnemyIntent.rally;
  }
  final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
  final heal = (skill['healAmount'] as num?)?.toInt() ?? 0;
  return damageMod == 0 && heal > 0 ? EnemyIntent.heal : EnemyIntent.attack;
}

/// A charged blow lands at this multiple of the move's normal damage
/// unless the skill sets its own `chargeMultiplier`.
const double defaultChargeMultiplier = 2.0;

/// A charge breaks when the party deals at least this share of the
/// enemy's max health to it within one round.
const double chargeBreakFraction = 0.25;

/// A guard is worth the enemy's own damage (times the skill's
/// `guardMultiplier`, 1.0 unless set) in block.
const double defaultGuardMultiplier = 1.0;

/// A rally raises the damage of the enemy and every living packmate by
/// this many percent, unless the skill sets its own `rallyPercent`.
const int defaultRallyPercent = 20;

/// No enemy is rallied more than this many times in one fight.
const int maxRallyStacks = 2;

/// Damage multiplier for a hit of the element an enemy is weak to, and for
/// one it resists.
const double weaknessMultiplier = 1.5;
const double resistanceMultiplier = 0.5;

List<String> enemyWeaknesses(Map<String, dynamic> enemy) =>
    ((enemy['weakTo'] as List?) ?? const []).map((e) => e.toString()).toList();

List<String> enemyResistances(Map<String, dynamic> enemy) =>
    ((enemy['resists'] as List?) ?? const []).map((e) => e.toString()).toList();

/// How [enemy] takes a hit of [element]: [weaknessMultiplier] when it's
/// weak to it, [resistanceMultiplier] when it resists it, 1 otherwise
/// ('None', a plain blow, is never either).
double elementMultiplierFor(Map<String, dynamic> enemy, String element) {
  if (element == 'None' || element.isEmpty) return 1.0;
  if (enemyWeaknesses(enemy).contains(element)) return weaknessMultiplier;
  if (enemyResistances(enemy).contains(element)) return resistanceMultiplier;
  return 1.0;
}

/// [damage] after [enemy]'s weakness or resistance to [element]. A hit that
/// did something still does at least 1.
int damageAfterElement(int damage, Map<String, dynamic> enemy, String element) {
  if (damage <= 0) return damage;
  final multiplier = elementMultiplierFor(enemy, element);
  if (multiplier == 1.0) return damage;
  return max(1, (damage * multiplier).round());
}

/// A hit on an enemy with a raised guard: the guard soaks what it can and
/// is worn down by it. Returns the damage that gets through and the guard
/// left.
({int damage, int guard}) damageThroughGuard(int damage, int guard) {
  if (guard <= 0 || damage <= 0) return (damage: damage, guard: guard);
  final soaked = min(guard, damage);
  return (damage: damage - soaked, guard: guard - soaked);
}

/// Whether a winding-up enemy loses its charged blow: hit for at least
/// [chargeBreakFraction] of its [maxHealth] this round, stunned, or struck
/// with an element it's weak to.
bool chargeBroken({
  required int damageThisRound,
  required int maxHealth,
  bool stunned = false,
  bool hitWeakness = false,
}) =>
    stunned ||
    hitWeakness ||
    (maxHealth > 0 && damageThisRound >= maxHealth * chargeBreakFraction);

/// An enemy's heal, scaled the way its health was: a heal written for a
/// 150 HP enemy mends proportionally more once the enemy has been scaled up
/// to the party's level. [baseMaxHealth] is the enemy's unscaled
/// `maxHealth` in enemies.json.
int scaledEnemyHeal(int heal, {required int maxHealth, int? baseMaxHealth}) {
  if (heal <= 0) return 0;
  final base = baseMaxHealth ?? maxHealth;
  if (base <= 0 || maxHealth <= base) return heal;
  return (heal * maxHealth / base).round();
}

/// Momentum after the party takes a hit (v1.162): a hit costs one point
/// instead of wiping the whole meter, so a party that trades blows can
/// still build to a surge.
int momentumAfterHit(int momentum) => max(0, momentum - 1);

/// Taunt (v1.162): whether a blow aimed at someone else goes to the party
/// member who kept the biggest Defend face this round instead. Only while
/// their guard holds: the first blow they take spends it, and the rest of
/// the enemies' blows go where they were aimed.
bool guardianTakesBlow({
  required bool guardianStanding,
  required int guardianBlock,
  required bool aimedAtGuardian,
}) =>
    guardianStanding && guardianBlock > 0 && !aimedAtGuardian;

/// An element's name in [language] ('Fire' → 'Feu'); the id itself when no
/// name is written for it.
String elementLabel(String element, AppLanguage language) {
  final key = 'element_name_${element.toLowerCase()}';
  final label = trFor(language, key);
  return label == key ? element : label;
}
