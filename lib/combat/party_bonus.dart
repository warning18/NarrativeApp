import 'dart:math';

/// The party's edge going into a fight, applied on top of every stat:
///
/// * **Resolve** -- every defeat the same boss dealt the party comes back
///   as a stacking bonus against it (the Shroud has learned its shape),
///   [resolvePercentPerStack] of health and damage per loss, up to
///   [resolveStackCap] stacks. Read from `PlayerSession.bossDefeatCounts`,
///   which FightScreen fills on a lost boss fight.
/// * **The camp's works** -- houses.json `partyHealthBonus` and
///   `partyDamageBonus` (percent), the late-game gold sink: the Hearth-Hall,
///   the Banner Loft and the Shroud Shrine.
class PartyBonus {
  const PartyBonus({
    this.resolveStacks = 0,
    this.houseHealthPercent = 0,
    this.houseDamagePercent = 0,
  });

  static const PartyBonus none = PartyBonus();

  final int resolveStacks;
  final int houseHealthPercent;
  final int houseDamagePercent;

  int get resolvePercent => resolveStacks * resolvePercentPerStack;
  int get healthPercent => resolvePercent + houseHealthPercent;
  int get damagePercent => resolvePercent + houseDamagePercent;
  double get healthMultiplier => 1 + healthPercent / 100;
  double get damageMultiplier => 1 + damagePercent / 100;
  bool get isNone => healthPercent == 0 && damagePercent == 0;
  bool get hasHouseBonus => houseHealthPercent > 0 || houseDamagePercent > 0;

  /// A max health scaled by the bonus, never under 1.
  int scaleMaxHealth(int value) => max(1, (value * healthMultiplier).round());

  /// A current health scaled by the bonus (0 stays 0: a knocked-out
  /// companion is still knocked out).
  int scaleCurrentHealth(int value) => (value * healthMultiplier).round();

  int scaleDamage(int value) => (value * damageMultiplier).round();
}

/// Resolve never stacks past this many defeats.
const int resolveStackCap = 5;

/// Health and damage, in percent, per stack of Resolve.
const int resolvePercentPerStack = 5;

/// Resolve stacks against [enemyIds]: the most defeats any one of them has
/// dealt this run, capped. Regular enemies never appear in
/// [bossDefeatCounts], so a pack of them reads 0.
int resolveStacksFor(
    Map<String, int> bossDefeatCounts, Iterable<String> enemyIds) {
  var most = 0;
  for (final id in enemyIds) {
    most = max(most, bossDefeatCounts[id] ?? 0);
  }
  return min(resolveStackCap, most);
}

/// The percent bonuses the built camp works add up to.
({int health, int damage}) houseBonusesFor(
    Iterable<String> builtHouseIds, Map<String, dynamic> houses) {
  var health = 0;
  var damage = 0;
  for (final id in builtHouseIds) {
    final house = houses[id] as Map<String, dynamic>?;
    if (house == null) continue;
    health += (house['partyHealthBonus'] as num?)?.toInt() ?? 0;
    damage += (house['partyDamageBonus'] as num?)?.toInt() ?? 0;
  }
  return (health: health, damage: damage);
}

PartyBonus partyBonusFor({
  required Map<String, int> bossDefeatCounts,
  required Iterable<String> enemyIds,
  required Iterable<String> builtHouseIds,
  required Map<String, dynamic> houses,
}) {
  final works = houseBonusesFor(builtHouseIds, houses);
  return PartyBonus(
    resolveStacks: resolveStacksFor(bossDefeatCounts, enemyIds),
    houseHealthPercent: works.health,
    houseDamagePercent: works.damage,
  );
}
