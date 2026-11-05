// The Tower's bot (v1.845): plays whole runs on the headless fight
// (simulateSimFight), for the tests and QA's balance batch (phase 2). It
// moves the run through the same functions the screens will
// (towerAfterFight, towerPick), so what it measures is the Tower itself.

import 'dart:io';
import 'dart:convert';

import '../sim_combat.dart';
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_progress.dart';
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_tables.dart';

/// The Tower's tables read from assets/gamedata/ (for tests and tools; the
/// app reads them from its own database).
TowerData towerDataFromAssets([String dir = 'assets/gamedata']) =>
    TowerData.fromTables({
      for (final name in TowerData.tableNames)
        name: jsonDecode(File('$dir/$name.json').readAsStringSync())
            as Map<String, dynamic>,
    });

/// Plays one whole run of [seed] with the unlocks of [progress] (none by
/// default, [towerAllUnlocked] for all) and returns it ended: won, or dead
/// on the floor it lost. The race, profession and clan are drawn by the
/// seed among those open, unless given.
TowerRun playTowerRun({
  required int seed,
  required TowerData data,
  TowerProgress progress = const TowerProgress(),
  String? raceId,
  String? professionId,
  String? clanId,
}) {
  final pick = towerRandom(seed, 0, TowerStream.start);
  T draw<T>(List<T> from) => from[pick.nextInt(from.length)];
  final races = data.races.keys.toList()..sort();
  final professions = progress.professions.toList()..sort();
  final clans = progress.clans.toList()..sort();
  var run = towerStart(
    seed: seed,
    raceId: raceId ?? draw(races),
    professionId: professionId ?? draw(professions),
    clanId: clanId ?? draw(clans),
    startUnlocks: progress.startUnlocks,
    unlocksOwned: progress.unlocksOwned,
    data: data,
  );
  final floors = towerFloorsFor(seed, data.enemies);
  while (!run.isOver) {
    final floor = floors[run.floor - 1];
    final hero = towerHeroOf(run, data);
    final outcome = simulateSimFight(
      character: hero,
      enemies: [
        for (final id in floor.enemyIds)
          MapEntry(id, data.enemies[id] as Map<String, dynamic>),
      ],
      chapter: floor.chapter,
      zoneMultiplier: floor.extraFor(run.professionId) *
          (floor.elite ? towerSimEliteMultiplier : 1.0),
      skills: data.skills,
      items: data.items,
      random: towerRandom(seed, floor.floor, TowerStream.fight),
    );
    run = towerAfterFight(run, data,
        won: outcome.won, healthLeft: hero.currentHealth);
    if (run.status == TowerStatus.choosing) {
      run = towerPick(run, data, towerBotChoice(run, data));
    }
  }
  return run;
}

/// The card the bot takes from [run]'s offer: a heal when below half
/// health, else the first of: its clan's die, gear better than what it
/// wears, a die, a skill, a spell, the clan's stat point, a heal.
int? towerBotChoice(TowerRun run, TowerData data) {
  if (run.offer.isEmpty) return null;
  final hero = towerHeroOf(run, data);
  int? find(bool Function(TowerReward r) test) {
    for (var i = 0; i < run.offer.length; i++) {
      if (test(run.offer[i])) return i;
    }
    return null;
  }

  if (hero.currentHealth < hero.maxHealth / 2) {
    final heal = find((r) => r.kind == TowerRewardKind.heal);
    if (heal != null) return heal;
  }
  int gear(String? id) {
    final item = data.items[id] as Map?;
    int n(String key) => (item?[key] as num?)?.toInt() ?? 0;
    return n('attackDamage') + n('damage') + n('armor');
  }

  bool better(TowerReward r) {
    final slot = (data.items[r.id] as Map?)?['equipSlot']?.toString();
    return gear(r.id) > gear(hero.equippedBySlot[slot]);
  }

  return find((r) => r.kind == TowerRewardKind.clanGift && r.id.isNotEmpty) ??
      find((r) => r.kind == TowerRewardKind.item && better(r)) ??
      find((r) => r.kind == TowerRewardKind.die) ??
      find((r) => r.kind == TowerRewardKind.skill) ??
      find((r) => r.kind == TowerRewardKind.spell) ??
      find((r) => r.kind == TowerRewardKind.clanGift) ??
      find((r) => r.kind == TowerRewardKind.heal) ??
      0;
}

/// A batch of [seeds] runs (QA's balance report): each run's floor
/// reached, and whether it won.
List<TowerRun> playTowerBatch(Iterable<int> seeds, TowerData data,
        {TowerProgress progress = const TowerProgress()}) =>
    [
      for (final seed in seeds)
        playTowerRun(seed: seed, data: data, progress: progress),
    ];
