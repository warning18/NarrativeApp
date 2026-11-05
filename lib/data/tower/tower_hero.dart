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
import '../training.dart';
import 'tower_floors.dart' show TowerStream, towerRandom;
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
    this.trainingPaths = const {},
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
        trainingPaths: trainingPathsFrom(tables['training_paths'] ?? const {}),
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
    'training_paths',
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

  /// The level-up's training paths (training_paths.json): the stat picks
  /// the player takes (v1.857, the main game's level-up).
  final Map<String, TrainingPath> trainingPaths;

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
/// wound kept, not healed); with [autoPicks] (a save from before v1.857)
/// its stat pick in its damage stat, else the pick waits for the player
/// (towerPendingPicks). Returns the levels gained.
int towerLevelTo(SimCharacter hero, int level, {bool autoPicks = true}) {
  var gained = 0;
  while (hero.level < level) {
    hero.level++;
    gained++;
    hero.maxHealth += levelHealthGain;
    hero.currentHealth += levelHealthGain;
    if (autoPicks) hero.addAbilities({hero.preferredStat: levelStatPicks});
  }
  return gained;
}

/// The hero's abilities as the stat picks read them.
Map<String, int> _abilitiesOf(SimCharacter hero) => {
      'strength': hero.strength,
      'dexterity': hero.dexterity,
      'constitution': hero.constitution,
      'intelligence': hero.intelligence,
      'wisdom': hero.wisdom,
      'perception': hero.perception,
      'luck': hero.luck,
      'charisma': hero.charisma,
    };

/// The [n]th stat pick of the run of [seed] (from 0), as [hero] stands
/// before it: the main game's own draw (drawStatPick, three offers and one
/// rarity), from the run's own stream so a replay draws the same.
List<StatPickOffer> towerStatPickDraw(
        SimCharacter hero, int seed, int n, TowerData data) =>
    drawStatPick(
      paths: data.trainingPaths,
      random: towerRandom(seed, n + 1, TowerStream.pick),
      professionId: hero.professionId,
      raceId: hero.raceId,
      luck: hero.luck,
      taken: hero.trainingTaken,
      stats: _abilitiesOf(hero),
    );

/// [pick] taken by [hero]: its gains, its path counted (as the session's
/// takeStatPick and the simulator's takeStatPicks).
void towerTakePickOn(SimCharacter hero, StatPickOffer pick) {
  hero.trainingTaken[pick.pathId] = (hero.trainingTaken[pick.pathId] ?? 0) + 1;
  for (final MapEntry(:key, :value) in pick.gains.entries) {
    hero.pickedPoints[key] = (hero.pickedPoints[key] ?? 0) + value;
  }
  hero.addAbilities(pick.gains);
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
    case TowerRewardKind.clanOath:
      // Sworn: the clan's die at once (the user's call); its standing is
      // the session's (towerSessionOf).
      if (towerClanDieOf(reward.id, data.dice) case final die?) {
        _takeDie(hero, die, data);
      }
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
  var pick = 0;
  for (var floor = 1; floor <= run.floorsCleared; floor++) {
    final gained = towerLevelTo(hero, towerBudgetOf(floor).levelAfter,
        autoPicks: run.autoPicks);
    // The floor's level-up picks, taken before its cards (towerPick waits
    // for them): each drawn as the hero stands then.
    if (!run.autoPicks) {
      for (var i = 0; i < gained * levelStatPicks; i++, pick++) {
        if (pick >= run.statPicks.length) break;
        final offer = towerStatPickDraw(hero, run.seed, pick, data);
        final index = run.statPicks[pick];
        if (index >= 0 && index < offer.length) {
          towerTakePickOn(hero, offer[index]);
        }
      }
    }
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
      clanIds: run.clanIds,
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
