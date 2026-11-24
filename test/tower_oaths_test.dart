// The Tower's clans offer their oaths (v1.855, the user's call): a run
// starts sworn to none. From the clans' offers (docs/simulation/
// tower-clan-offers.md) a clan's oath comes once its standing, raised by
// the gifts taken, reaches towerOathStep; sworn, the hero holds the clan's
// die at once and its standing in the fight, the first clan sworn the main
// one; one oath a run (the user's call), though an older save sworn to
// several keeps them all; an old save sworn at the start keeps its clan.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_crisis.dart' show mainClanOf;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();
  TowerRun start(int seed, {List<String>? pool}) => towerStart(
      seed: seed,
      raceId: 'human',
      professionId: 'warrior',
      clanPool: pool ?? towerStartClanPool,
      data: data);
  TowerRun won(TowerRun run) =>
      towerAfterFight(run, data, won: true, healthLeft: run.health);
  int oathIn(TowerRun run) =>
      run.offer.indexWhere((r) => r.kind == TowerRewardKind.clanOath);
  // [run] on floor [floor] with [clan]'s gifts taken below it up to the
  // oath's step (three gifts of +2).
  TowerRun due(TowerRun run, String clan, {int floor = 4}) => run.copyWith(
        floor: floor,
        taken: {
          ...run.taken,
          for (var f = floor - 3; f < floor; f++)
            f: TowerReward(TowerRewardKind.skill, id: 'gift$f', clan: clan),
        },
      );

  test('a new run is sworn to none; the first floor won deals the clans', () {
    for (var seed = 1; seed <= 20; seed++) {
      final run = start(seed);
      expect(run.clanIds, isEmpty);
      expect(run.mainClanId, '');
      final first = won(run);
      expect(first.offer, isNotEmpty, reason: 'seed $seed: always');
      for (final card in first.offer) {
        expect(towerStartClanPool, contains(card.clan));
      }
      expect(oathIn(first), -1, reason: 'no clan at the oath\'s step yet');
    }
  });

  test('sworn: its die at once, its standing in the fight; one a run', () {
    var run = won(due(start(4), 'mire'));
    expect(oathIn(run), 0);
    final clan = run.offer[oathIn(run)].id;
    expect(clan, 'mire');
    run = towerPick(run, data, oathIn(run));
    expect(run.clanIds, [clan]);
    final die = towerClanDieOf(clan, data.dice);
    if (die != null) {
      expect(towerHeroOf(run, data).ownedDice.keys, contains(die));
    }
    expect(mainClanOf(towerSessionOf(run, data).politics), clan);
    // Another clan brought to the oath's step: its oath never comes.
    run = due(run, 'dominion', floor: run.floor + 3);
    for (var guard = 0; guard < 6; guard++) {
      run = won(run);
      if (run.status != TowerStatus.choosing) break;
      expect(oathIn(run), -1, reason: 'one oath a run');
      run = towerPick(run, data, null);
    }
    expect(run.clanIds, [clan]);
  });

  test('an older save sworn to several keeps them, the first main', () {
    final run = start(5).copyWith(floor: 6, taken: {
      1: const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
      4: const TowerReward(TowerRewardKind.clanOath, id: 'dominion'),
    });
    final again = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(again.clanIds, ['mire', 'dominion']);
    final politics = towerSessionOf(again, data).politics;
    expect(mainClanOf(politics), 'mire');
    expect(politics.standings.keys, containsAll(again.clanIds));
    expect(again.oathsLeft, isEmpty);
  });

  test('every clan of the pool sworn: no oath is offered again', () {
    var run = won(due(start(9, pool: const ['mire']), 'mire'));
    run = towerPick(run, data, oathIn(run));
    expect(run.oathsLeft, isEmpty);
    for (var f = 0; f < 6 && run.status != TowerStatus.dead; f++) {
      run = won(run);
      if (run.status != TowerStatus.choosing) break;
      expect(oathIn(run), -1);
      run = towerPick(run, data, null);
    }
  });

  test('the save keeps the pool and the oaths; an old save keeps its clan', () {
    var run = won(due(start(6, pool: const ['crows', 'mire']), 'crows'));
    run = towerPick(run, data, oathIn(run));
    expect(run.clanIds, ['crows']);
    final again = TowerRun.fromJson(
        jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
    expect(again.clanPool, ['mire', 'crows']);
    expect(again.clanIds, run.clanIds);
    // A save from before v1.855: its clan sworn from the start.
    final old = run.toJson()
      ..remove('pool')
      ..['clan'] = 'vigil'
      ..['taken'] = <String, dynamic>{};
    final loaded = TowerRun.fromJson(old);
    expect(loaded.clanIds, ['vigil']);
    expect(loaded.clanPool, towerStartClanPool);
  });

  test('the bot swears to a clan it is offered, from its open pool', () {
    var sworn = 0, swornAll = 0;
    for (var seed = 1; seed <= 10; seed++) {
      final run = playTowerRun(seed: seed, data: data);
      expect(run.clanIds.length, lessThanOrEqualTo(1));
      expect(towerStartClanPool, containsAll(run.clanIds));
      if (run.clanIds.isNotEmpty) sworn++;
      final all =
          playTowerRun(seed: seed, data: data, progress: towerAllUnlocked);
      expect(all.clanIds.length, lessThanOrEqualTo(1));
      expect(towerClans, containsAll(all.clanIds));
      if (all.clanIds.isNotEmpty) swornAll++;
    }
    expect(sworn, greaterThan(0));
    expect(swornAll, greaterThan(0));
  });
}
