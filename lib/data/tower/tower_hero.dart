// The Tower's hero (v1.845): a fresh character of the run's race and
// profession, rebuilt from the run alone (its start, the levels its floors
// gave, the cards it took), so the save holds no character and a reload
// can never drift from the run.

import 'dart:math';

import '../../combat/spells.dart';
import '../../combat/stat_rules.dart' show levelHealthGain, levelStatPicks;
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
    required Map<String, dynamic> dice,
    required this.skills,
    required this.items,
    required this.enemies,
    required this.spells,
    this.trainingPaths = const {},
  })  : dice = towerDiceTable(dice),
        spellSpecs = parseSpells(spells);

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

  /// The dice as the Tower rolls them: the game's, with the Tower's own
  /// faces of its three dice ([towerDiceTable], [towerDieFaces]).
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
/// unlocks, no potions (the flask and the bag come with the run,
/// [towerHeroOf]). [bag]: the start's dice go to the bag, the calling's own
/// die stays in play (a run with [TowerRun.dieChoice]); else the best is
/// rolled (simDieValue, a run saved before).
SimCharacter towerFreshHero(String raceId, String professionId,
    Iterable<String> unlockIds, TowerData data,
    {int unlocksOwned = 0, bool bag = false}) {
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
        _takeDie(hero, unlock.value, data, bag: bag);
      case TowerUnlockKind.startItem:
        _wear(hero, unlock.value, data);
      case TowerUnlockKind.clan:
      case TowerUnlockKind.profession:
        break;
    }
  }
  final people = towerPeoplePoints[raceId] ?? 0;
  if (people > 0) hero.addAbilities({hero.preferredStat: people});
  if (unlocksOwned > 0) {
    hero.maxHealth =
        (hero.maxHealth * (1 + towerHealthPerUnlock * unlocksOwned)).round();
    hero.currentHealth = hero.maxHealth;
  }
  return hero;
}

/// [hero] raised to [level]: each level its health ([levelHealthGain], the
/// wound kept, not healed); its stat pick waits for the player
/// (towerPendingPicks). Returns the levels gained.
int towerLevelTo(SimCharacter hero, int level) {
  var gained = 0;
  while (hero.level < level) {
    hero.level++;
    gained++;
    hero.maxHealth += levelHealthGain;
    hero.currentHealth += levelHealthGain;
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

/// [reward] given to [hero]. [bag]: a die gained goes to the bag, the one
/// in play stays (a run with [TowerRun.dieChoice]); else it is rolled when
/// the simulator's worth rates it higher (a run saved before).
void towerApplyReward(SimCharacter hero, TowerReward reward, TowerData data,
    {bool bag = false}) {
  switch (reward.kind) {
    case TowerRewardKind.die:
      _takeDie(hero, reward.id, data, bag: bag);
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
    case TowerRewardKind.clanOath:
      // Sworn: the clan's die at once (the user's call: in the bag, with
      // [bag]); its standing is the session's (towerSessionOf).
      if (towerClanDieOf(reward.id, data.dice) case final die?) {
        _takeDie(hero, die, data, bag: bag);
      }
  }
}

/// A floor's spoils [itemIds] given to [hero]: its gear worn when better.
void towerWearSpoils(
    SimCharacter hero, Iterable<String> itemIds, TowerData data) {
  for (final id in itemIds) {
    _wear(hero, id, data);
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

void _takeDie(SimCharacter hero, String dieId, TowerData data,
    {bool bag = false}) {
  final faces = data.facesOf(dieId);
  if (faces.isEmpty) return;
  hero.ownedDice[dieId] = faces;
  if (!bag) hero.rollBestDie(data.skills);
}

/// [hero] rolling its owned die [dieId] from now on, its skills placed
/// afresh on its faces (simSkillAssignments); as it is when [dieId] is the
/// die in play already, or not owned.
void towerRollDie(SimCharacter hero, String dieId, TowerData data) {
  if (dieId == hero.diceId) return;
  final faces = hero.ownedDice[dieId];
  if (faces == null) return;
  hero
    ..diceId = dieId
    ..diceFaces = faces
    ..diceSkillAssignments = simSkillAssignments(
        faces: faces,
        current: const {},
        unlocked: hero.unlockedSkillIds,
        skills: data.skills);
}

/// The run's hero now: rebuilt from [run]'s start, the levels of the
/// floors it cleared (its height, TowerRun.heightCleared: a fall keeps
/// them, floor events PR 1) and the cards it took, with the run's health.
///
/// The die in play is [TowerRun.dieChoice]: the dice gained wait in the
/// bag, and the chosen one, when it is not the calling's own, is rolled
/// with its skills placed afresh. A run saved before has none: each die
/// gained is rolled when the simulator's worth rates it higher, as then.
///
/// A rebuild goes on from the longest run of floors already built for this
/// [data] (v1.880): each floor's hero is kept, as a copy (SimCharacter.copy),
/// under all that made it (the run's start; each floor's picks, spoils and
/// card), so a move rebuilds only the floors it changed, not the climb.
SimCharacter towerHeroOf(TowerRun run, TowerData data) {
  final built = _builtHeroes[data] ??= {};
  // A run that chooses its die keeps the dice gained in the bag.
  final bag = run.dieChoice != null;
  // Each floor's key: all that the hero after it depends on.
  final keys = <String>[
    '${run.seed}|${run.raceId}|${run.professionId}|'
        '${run.startUnlocks.join(',')}|${run.unlocksOwned}|${run.taken[0]}'
        '${bag ? '|bag' : ''}',
  ];
  final picksAt = <List<int>>[const []];
  var level = 1, pick = 0;
  for (var floor = 1; floor <= run.heightCleared; floor++) {
    final next = max(level, towerBudgetOf(floor).levelAfter);
    final from = min(pick, run.statPicks.length);
    pick += (next - level) * levelStatPicks;
    level = next;
    final picks = run.statPicks.sublist(from, min(pick, run.statPicks.length));
    picksAt.add(picks);
    keys.add('${keys.last}#$floor:${picks.join(',')}:'
        '${(run.spoils[floor] ?? const []).join(',')}:${run.taken[floor]}');
  }
  // The longest run of floors already built.
  var floor = keys.length - 1;
  while (floor >= 0 && !built.containsKey(keys[floor])) {
    floor--;
  }
  late SimCharacter hero;
  if (floor >= 0) {
    hero = built[keys[floor]]!.copy();
    pick = 0;
    for (var f = 1; f <= floor; f++) {
      pick += picksAt[f].length;
    }
  } else {
    hero = towerFreshHero(run.raceId, run.professionId, run.startUnlocks, data,
        unlocksOwned: run.unlocksOwned, bag: bag);
    // A clan sworn at the start: its oath on floor 0 (towerStart).
    if (run.taken[0] case final oath?) {
      towerApplyReward(hero, oath, data, bag: bag);
    }
    _keep(built, keys[0], hero);
    floor = 0;
    pick = 0;
  }
  for (floor++; floor <= run.heightCleared; floor++) {
    towerLevelTo(hero, towerBudgetOf(floor).levelAfter);
    // The floor's level-up picks, taken before its cards (towerPick waits
    // for them): each drawn as the hero stands then.
    for (final index in picksAt[floor]) {
      final offer = towerStatPickDraw(hero, run.seed, pick, data);
      if (index >= 0 && index < offer.length) {
        towerTakePickOn(hero, offer[index]);
      }
      pick++;
    }
    // The floor's spoils (v1.860): its gear worn when better.
    towerWearSpoils(hero, run.spoils[floor] ?? const [], data);
    final card = run.taken[floor];
    if (card != null) towerApplyReward(hero, card, data, bag: bag);
    _keep(built, keys[floor], hero);
  }
  // The die the player chose (the floors' heroes are kept on the calling's
  // own, so a new choice rebuilds nothing).
  if (run.dieChoice case final die?) towerRollDie(hero, die, data);
  hero.currentHealth = run.health.clamp(0, hero.maxHealth);
  hero.mana = hero.maxMana;
  // The flask, filled every floor, and the bag the spoils filled.
  hero.potions =
      towerFlask + run.unlocksOwned ~/ towerUnlocksPerPotion + run.potions;
  return hero;
}

/// The heroes built so far, by [TowerData] (towerHeroOf): each floor's,
/// under its key.
final Expando<Map<String, SimCharacter>> _builtHeroes = Expando();

/// The most floors kept for one [TowerData]: a batch of climbs keeps about
/// thirty a climb; past this the oldest go first.
const int _builtHeroesKept = 4096;

void _keep(Map<String, SimCharacter> built, String key, SimCharacter hero) {
  if (built.length >= _builtHeroesKept) built.remove(built.keys.first);
  built[key] = hero.copy();
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
