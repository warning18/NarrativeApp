// The Tower's hero (v1.845): a fresh character of the run's race and
// profession, rebuilt from the run alone (its start, the levels its floors
// gave, the cards it took), so the save holds no character and a reload
// can never drift from the run.

import 'dart:math';

import '../../combat/spells.dart';
import '../../combat/stat_rules.dart'
    show damageStatOf, levelHealthGain, levelStatPicks;
import '../sim_combat.dart';
import '../sim_policy.dart' show simSkillAssignments;
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

/// The game's tables the Tower reads, by their file name in
/// assets/gamedata/ (races, professions, game_config, dice, skills, items,
/// enemies, spells).
class TowerData {
  TowerData({
    required this.races,
    required this.professions,
    required this.gameConfig,
    required this.dice,
    required this.skills,
    required this.items,
    required this.enemies,
    required this.spells,
  }) : spellSpecs = parseSpells(spells);

  /// From the tables keyed by file name (as `gameDbProvider` or a test
  /// reads them).
  factory TowerData.fromTables(Map<String, Map<String, dynamic>> tables) =>
      TowerData(
        races: tables['races'] ?? const {},
        professions: tables['professions'] ?? const {},
        gameConfig: tables['game_config'] ?? const {},
        dice: tables['dice'] ?? const {},
        skills: tables['skills'] ?? const {},
        items: tables['items'] ?? const {},
        enemies: tables['enemies'] ?? const {},
        spells: tables['spells'] ?? const {},
      );

  /// The tables [TowerData.fromTables] reads.
  static const List<String> tableNames = [
    'races',
    'professions',
    'game_config',
    'dice',
    'skills',
    'items',
    'enemies',
    'spells',
  ];

  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;
  final Map<String, dynamic> gameConfig;
  final Map<String, dynamic> dice;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> items;
  final Map<String, dynamic> enemies;
  final Map<String, dynamic> spells;
  final Map<String, SpellSpec> spellSpecs;

  List<Map<String, dynamic>> facesOf(String dieId) =>
      ((dice[dieId] as Map?)?['faces'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      const [];
}

/// A new hero of [raceId] and [professionId] with the start unlocks
/// [unlockIds] in hand (their dice owned, their items worn): level 1, full
/// health with [towerHealthPerUnlock] more for each of the [unlocksOwned]
/// unlocks, no potions (the heal cards stand in for them).
SimCharacter towerFreshHero(String raceId, String professionId,
    Iterable<String> unlockIds, TowerData data,
    {int unlocksOwned = 0}) {
  final hero = SimCharacter.create(
    raceId: raceId,
    race: data.races[raceId] as Map<String, dynamic>? ?? const {},
    professionId: professionId,
    profession:
        data.professions[professionId] as Map<String, dynamic>? ?? const {},
    gameConfig: data.gameConfig,
    dice: data.dice,
    spells: data.spellSpecs,
  )..potions = 0;
  for (final id in unlockIds) {
    final unlock = towerUnlockOf(id);
    if (unlock == null) continue;
    switch (unlock.kind) {
      case TowerUnlockKind.startDie:
        _takeDie(hero, unlock.value, data);
      case TowerUnlockKind.startItem:
        _wear(hero, unlock.value, data);
      case TowerUnlockKind.clan:
      case TowerUnlockKind.profession:
        break;
    }
  }
  if (unlocksOwned > 0) {
    hero.maxHealth =
        (hero.maxHealth * (1 + towerHealthPerUnlock * unlocksOwned)).round();
    hero.currentHealth = hero.maxHealth;
  }
  return hero;
}

/// [hero] raised to [level]: each level its health ([levelHealthGain], the
/// wound kept, not healed) and its stat pick in its damage stat.
void towerLevelTo(SimCharacter hero, int level) {
  while (hero.level < level) {
    hero.level++;
    hero.maxHealth += levelHealthGain;
    hero.currentHealth += levelHealthGain;
    hero.addAbilities({hero.preferredStat: levelStatPicks});
  }
}

/// [reward] given to [hero].
void towerApplyReward(SimCharacter hero, TowerReward reward, TowerData data) {
  switch (reward.kind) {
    case TowerRewardKind.item:
      _wear(hero, reward.id, data);
    case TowerRewardKind.die:
      _takeDie(hero, reward.id, data);
    case TowerRewardKind.skill:
      hero.unlockedSkillIds.add(reward.id);
      hero.diceSkillAssignments = simSkillAssignments(
          faces: hero.diceFaces,
          current: hero.diceSkillAssignments,
          unlocked: hero.unlockedSkillIds,
          skills: data.skills);
    case TowerRewardKind.spell:
      final spell = data.spellSpecs[reward.id];
      if (spell != null && !hero.knownSpells.any((s) => s.id == reward.id)) {
        hero.knownSpells.add(spell);
      }
    case TowerRewardKind.heal:
      hero.currentHealth = min(hero.maxHealth,
          hero.currentHealth + (hero.maxHealth * reward.amount / 100).round());
    case TowerRewardKind.clanGift:
      if (reward.id.isNotEmpty) {
        _takeDie(hero, reward.id, data);
      } else {
        final stat = damageStatOf(hero.professionId);
        hero.addAbilities(
            {stat.isEmpty ? hero.preferredStat : stat: reward.amount});
      }
  }
}

void _wear(SimCharacter hero, String itemId, TowerData data) {
  final item = data.items[itemId] as Map<String, dynamic>?;
  if (item == null) return;
  final slot = item['equipSlot']?.toString() ?? '';
  if (slot.isEmpty) return;
  hero.ownedItemIds.add(itemId);
  final worn = hero.equippedBySlot[slot];
  if (worn == null || _gearScore(itemId, data) >= _gearScore(worn, data)) {
    hero.equippedBySlot[slot] = itemId;
  }
}

int _gearScore(String itemId, TowerData data) {
  final item = data.items[itemId] as Map?;
  int n(String key) => (item?[key] as num?)?.toInt() ?? 0;
  return n('attackDamage') + n('damage') + n('armor');
}

void _takeDie(SimCharacter hero, String dieId, TowerData data) {
  final faces = data.facesOf(dieId);
  if (faces.isEmpty) return;
  hero.ownedDice[dieId] = faces;
  hero.rollBestDie(data.skills);
}

/// The run's hero now: rebuilt from [run]'s start, the levels of the
/// floors it cleared and the cards it took, with the run's health.
SimCharacter towerHeroOf(TowerRun run, TowerData data) {
  final hero = towerFreshHero(
      run.raceId, run.professionId, run.startUnlocks, data,
      unlocksOwned: run.unlocksOwned);
  for (var floor = 1; floor <= run.floorsCleared; floor++) {
    towerLevelTo(hero, towerBudgetOf(floor).levelAfter);
    final card = run.taken[floor];
    if (card != null) towerApplyReward(hero, card, data);
  }
  hero.currentHealth = run.health.clamp(0, hero.maxHealth);
  hero.mana = hero.maxMana;
  hero.potions = towerFlask + run.unlocksOwned ~/ towerUnlocksPerPotion;
  return hero;
}

/// What the offer reads of [hero] in [run].
TowerHeroView towerHeroView(TowerRun run, SimCharacter hero) => TowerHeroView(
      raceId: run.raceId,
      professionId: run.professionId,
      clanId: run.clanId,
      health: hero.currentHealth,
      maxHealth: hero.maxHealth,
      equippedItemIds: hero.equippedItemIds.toSet(),
      ownedDiceIds: hero.ownedDice.keys.toSet(),
      unlockedSkillIds: hero.unlockedSkillIds,
      knownSpellIds: {for (final s in hero.knownSpells) s.id},
      takenIds: {
        for (final r in run.taken.values)
          if (r.id.isNotEmpty) r.id,
      },
    );
