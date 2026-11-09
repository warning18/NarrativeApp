// The Tower's clans offer their oaths (v1.855, the user's call): a run
// starts sworn to none; the first floor won always offers a clan's oath,
// and later offers may, while a clan of the run's pool is left; sworn, the
// hero holds the clan's die at once and its standing in the fight, the
// first clan sworn the main one; several clans may be sworn; the clan's
// gifts (stat points) come only once a clan is sworn; an old save sworn
// at the start keeps its clan.
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

  test('a new run is sworn to none; the first floor won offers an oath', () {
    for (var seed = 1; seed <= 20; seed++) {
      final run = start(seed);
      expect(run.clanIds, isEmpty);
      expect(run.mainClanId, '');
      final first = won(run);
      final oaths =
          first.offer.where((r) => r.kind == TowerRewardKind.clanOath);
      expect(oaths, hasLength(1), reason: 'seed $seed: one oath, always');
      expect(towerStartClanPool, contains(oaths.single.id));
      // After the spoils, the oath alone (v1.860: no cards beside it).
      expect(first.offer, hasLength(1));
    }
  });

  test('sworn: its die at once, its standing in the fight; the first main', () {
    var run = won(start(4));
    final clan = run.offer[oathIn(run)].id;
    run = towerPick(run, data, oathIn(run));
    expect(run.clanIds, [clan]);
    final die = towerClanDieOf(clan, data.dice);
    if (die != null) {
      expect(towerHeroOf(run, data).ownedDice.keys, contains(die));
    }
    expect(mainClanOf(towerSessionOf(run, data).politics), clan);
    // Climb until another clan offers its oath, and swear to it too.
    for (var guard = 0; guard < 40 && run.clanIds.length < 2; guard++) {
      run = won(run);
      if (run.status != TowerStatus.choosing) break;
      final i = oathIn(run);
      expect(i == -1 || run.offer[i].id != clan, isTrue,
          reason: 'a clan sworn is not offered again');
      run = towerPick(run, data, i == -1 ? null : i);
    }
    expect(run.clanIds, hasLength(2));
    expect(run.clanIds.first, clan, reason: 'the first sworn stays main');
    final politics = towerSessionOf(run, data).politics;
    expect(mainClanOf(politics), clan);
    expect(politics.standings.keys, containsAll(run.clanIds));
  });

  test('every clan of the pool sworn: no oath is offered again', () {
    var run = start(9, pool: const ['mire']);
    run = won(run);
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
    var run = won(start(6, pool: const ['crows', 'mire']));
    run = towerPick(run, data, oathIn(run));
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

  test('the bot swears to the clans it is offered, from its open pool', () {
    final run = playTowerRun(seed: 3, data: data);
    expect(run.clanIds, isNotEmpty);
    expect(towerStartClanPool, containsAll(run.clanIds));
    final all = playTowerRun(seed: 3, data: data, progress: towerAllUnlocked);
    expect(towerClans, containsAll(all.clanIds));
  });
}
