// The Tower's bot (v1.845): plays whole runs on the headless fight
// (simulateSimFight), for the tests and QA's balance batch (phase 2). It
// moves the run through the same functions the screens will
// (towerAfterFight, towerPick), so what it measures is the Tower itself.

import 'dart:io';
import 'dart:convert';

import '../sim_combat.dart';
import '../training.dart' show statPickForShares;
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
/// on the floor it lost. The race and profession are drawn by the seed
/// among those open, unless given; it starts unsworn ([clanId] swears one
/// from the start) and takes the first oath it is offered.
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
    clanId: clanId ?? '',
    clanPool: clans,
    startUnlocks: progress.startUnlocks,
    unlocksOwned: progress.unlocksOwned,
    data: data,
  );
  final floors = towerFloorsFor(seed, data.enemies);
  while (!run.isOver) {
    final floor = floors[run.floor - 1];
    final hero = towerHeroOf(run, data);
    final maxHealth = hero.maxHealth;
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
        won: outcome.won,
        healthLeft: hero.currentHealth,
        potionsLeft: hero.potions,
        maxHealthBefore: maxHealth);
    if (run.status == TowerStatus.choosing) {
      // The level-up first, as the story's bot takes its picks.
      // Each step's hero built once and handed on (towerHeroOf replays the
      // whole run).
      while (towerPendingPicks(run) > 0) {
        final hero = towerHeroOf(run, data);
        final offer = towerStatPickOffer(run, data, hero: hero);
        if (offer.isEmpty) break;
        run = towerTakeStatPick(
            run,
            data,
            statPickForShares(
                offer,
                simBuildShares[run.professionId] ?? {hero.preferredStat: 1.0},
                hero.pickedPoints),
            offer: offer);
      }
      final hero = towerHeroOf(run, data);
      run = towerPick(run, data, towerBotChoice(run), hero: hero);
    }
  }
  return run;
}

/// The card the bot takes from [run]'s offer: the first of a clan's oath
/// (a player's habit), a skill (a boon's first: the measure of v1.860, a
/// die first left the ranger at 1 top in 70), a die, a spell.
int? towerBotChoice(TowerRun run) {
  if (run.offer.isEmpty) return null;
  int? find(bool Function(TowerReward r) test) {
    for (var i = 0; i < run.offer.length; i++) {
      if (test(run.offer[i])) return i;
    }
    return null;
  }

  return find((r) => r.kind == TowerRewardKind.clanOath) ??
      find((r) => r.kind == TowerRewardKind.skill) ??
      find((r) => r.kind == TowerRewardKind.die) ??
      find((r) => r.kind == TowerRewardKind.spell) ??
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
