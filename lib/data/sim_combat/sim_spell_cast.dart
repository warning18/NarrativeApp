part of '../sim_combat.dart';

// The simulated hero's spell for the round (simulateSimFight's caster
// policy).

/// The caster policy, one spell a round at most: heal below half, cleanse
/// an affliction, the strongest affordable damage spell (keeping the
/// cheapest heal's cost in reserve unless the spell finishes an enemy),
/// block against a heavy combined swing, a hex on an enemy that will live
/// long enough to feel it. Returns the block granted this round. [signs]
/// lower the costs, lift what spells deal and heal, and add their status.
int _castSpellIfWorth(
  SimCharacter c,
  List<_SimEnemy> ens,
  Map<String, dynamic> items,
  Random random,
  Map<String, int> casts, {
  Map<String, ItemSet> itemSets = const {},
  SignEffects signs = SignEffects.none,
  bool clash = false,
  bool react = true,
  int round = 0,
  int Function(int)? healed,
  int Function(int raw, String element)? partyBlow,
  bool ashWell = false,
  double fullWellMultiplier = 1,
  double fullWellHealShare = 0,
  double spellLifeShare = 0,
  int spellDiscount = 0,
  int fireReactionTimes = 1,
  bool lingeringHex = false,
  void Function()? onSpellHit,
}) {
  final living = ens.where((e) => e.isAlive).toList();
  if (c.knownSpells.isEmpty || living.isEmpty || c.mana <= 0) return 0;

  int costOf(SpellSpec spell) => max(
      1,
      (ashWell
              ? ashWellSpellCost(signs.spellCost(spell.manaCost))
              : signs.spellCost(spell.manaCost)) -
          spellDiscount);
  int amountOf(SpellSpec spell) {
    final amount = spellAmountFor(
      spell,
      intelligence: c.intelligence,
      wisdom: c.wisdom,
      strength: c.strength,
      level: c.level,
      casterDamage: c.casterDamage(items, spell.element, itemSets: itemSets),
    );
    return spell.effect == SpellEffectKind.damage ||
            spell.effect == SpellEffectKind.heal
        ? signs.spellAmount(amount)
        : amount;
  }

  void cast(SpellSpec spell) {
    c.mana -= costOf(spell);
    casts[spell.id] = (casts[spell.id] ?? 0) + 1;
  }

  final affordable = c.knownSpells.where((s) => costOf(s) <= c.mana).toList();
  if (affordable.isEmpty) return 0;

  if (c.currentHealth < 0.5 * c.maxHealth) {
    final heals = affordable
        .where((s) => s.effect == SpellEffectKind.heal)
        .toList()
      ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
    if (heals.isNotEmpty) {
      final amount = amountOf(heals.first);
      c.currentHealth = min(
        c.maxHealth,
        c.currentHealth + (healed?.call(amount) ?? amount),
      );
      cast(heals.first);
      return 0;
    }
  }

  if (c.statusEffects.isNotEmpty) {
    final cleanse = affordable
        .where((s) => s.effect == SpellEffectKind.cleanse)
        .firstOrNull;
    if (cleanse != null) {
      c.statusEffects = [];
      cast(cleanse);
      return 0;
    }
  }

  final reserve = c.knownSpells
      .where((s) => s.effect == SpellEffectKind.heal)
      .map(costOf)
      .fold<int?>(null, (m, v) => m == null ? v : min(m, v));
  final boss = living.any((e) => soloOnlyEnemyIds.contains(e.id));
  final damageSpells = affordable
      .where((s) => s.effect == SpellEffectKind.damage)
      .toList()
    ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
  // The Burden-Bearer: a spell from a full Well hits harder.
  final fullWell = c.mana >= c.maxMana ? fullWellMultiplier : 1.0;
  for (final spell in damageSpells) {
    final raw = (amountOf(spell) * fullWell).round();
    final amount = partyBlow?.call(raw, spell.element) ?? raw;
    final killable = living.where((e) => e.health <= amount).toList();
    final List<_SimEnemy> targets;
    if (spell.target == SpellTarget.allEnemies) {
      if (living.length < 2 && killable.isEmpty && !boss) continue;
      targets = living;
    } else {
      targets = [
        killable.isNotEmpty
            ? killable.reduce((a, b) => a.damage >= b.damage ? a : b)
            : living.reduce((a, b) => a.damage >= b.damage ? a : b),
      ];
    }
    if (killable.isEmpty &&
        reserve != null &&
        c.mana - costOf(spell) < reserve) {
      continue;
    }
    final rawStatus = spellStatusFor(spell, level: c.level);
    final status =
        rawStatus != null && lingeringHex ? lingered(rawStatus) : rawStatus;
    for (final e in targets) {
      final before = e.health;
      if (clash) {
        e.landHit(amount, spell.element, round,
            react: react,
            reactionTimes: spell.element == 'Fire' ? fireReactionTimes : 1);
      } else {
        e.health = max(0, e.health - e.takeHit(amount, spell.element));
      }
      // The Tempest Toll: the spell takes back a share as health; the
      // Spire-Fallen's full-Well spell heals too; the Whisper Ledger steals.
      final dealtHere = before - e.health;
      final healShare = spellLifeShare + (fullWell > 1 ? fullWellHealShare : 0);
      if (healShare > 0 && dealtHere > 0) {
        c.currentHealth =
            min(c.maxHealth, c.currentHealth + (dealtHere * healShare).round());
      }
      if (dealtHere > 0) onSpellHit?.call();
      if (spell.element != 'None') e.elementsHit.add(spell.element);
      if (status != null && e.isAlive) {
        e.statusEffects = applyStatusEffect(
          e.statusEffects,
          signs.playerInflicted(status),
        );
      }
      // A spell sign's status, on every enemy the spell reaches.
      for (final chance in signs.spellStatuses) {
        if (e.isAlive && chance.rolls(random)) {
          e.statusEffects = applyStatusEffect(e.statusEffects, chance.status);
        }
      }
    }
    cast(spell);
    return 0;
  }

  final threat = living.fold(0, (sum, e) => sum + e.damage);
  if (threat >= 0.35 * c.currentHealth ||
      (living.length >= 2 && threat >= 0.25 * c.maxHealth)) {
    final blocks = affordable
        .where((s) => s.effect == SpellEffectKind.block)
        .toList()
      ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
    if (blocks.isNotEmpty) {
      cast(blocks.first);
      return amountOf(blocks.first);
    }
  }

  for (final spell in affordable.where(
    (s) => s.effect == SpellEffectKind.status,
  )) {
    final rawStatus = spellStatusFor(spell, level: c.level);
    if (rawStatus == null) continue;
    final status = lingeringHex ? lingered(rawStatus) : rawStatus;
    final candidates = living
        .where(
          (e) =>
              e.health >
                  2 * c.casterDamage(items, 'None', itemSets: itemSets) &&
              !e.statusEffects.any((x) => x.type == status.type),
        )
        .toList();
    if (candidates.isEmpty) continue;
    final target = candidates.reduce((a, b) => a.health >= b.health ? a : b);
    target.statusEffects = applyStatusEffect(target.statusEffects, status);
    for (final chance in signs.spellStatuses) {
      if (chance.rolls(random)) {
        target.statusEffects = applyStatusEffect(
          target.statusEffects,
          chance.status,
        );
      }
    }
    cast(spell);
    return 0;
  }
  return 0;
}
