// QA, the Tower's balance (phase 2 of docs/proposals/the-tower-wave.md): the
// seeded batch of Core's bot over the whole climb, and the guards that hold
// what the design asks of it (docs/proposals/tower-mechanics.md §11).
//
// The bot is Core's (lib/data/tower/tower_bot.dart: playTowerRun); this test
// only plays it, over seeds, with no unlocks and with all of them, and reads
// what it reaches. Nothing here changes a number of the Tower.
//
//   flutter test test/qa_tower_sim_test.dart            the guards (CI)
//   TOWER_SEEDS=2000 TOWER_FIRST=1 TOWER_OUT=build/tower.json \
//     flutter test test/qa_tower_sim_test.dart --plain-name batch
//   python3 tool/qa_tower_report.py build/tower.json   docs/qa/tower-balance.md
//
// TOWER_SEEDS (default 500) seeds from TOWER_FIRST (default 1) are played in
// each of the two cases; TOWER_OUT is where the batch's JSON goes.
// TOWER_EVENTS (default 1) is the floor events' version the bot plays
// (floor events PR 2: the curve is set with them on; 0, as before them).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

/// What the design asks of a naive bot (tower-mechanics.md §11): the median
/// floor it reaches, how many reach floor 20, how many win floor 30.
/// v1.848 (the user's calls on #834): the professions evened out, the median
/// moved to 17 and the top with no unlocks to about 10%.
// v1.855 (the user's call): no clan at the start, the clans offer their
// oaths on the way up (a die each, at once): floor 20 about 2 points more
// often (34.4% to 36.8% over the 500 guard seeds), the top unchanged.
// v1.860 (the user's call: the main game's spoils chest after every floor,
// a boon of a skill, a die or a spell on 5, 10, 15, 20 and 25, no heal
// cards): the median and the top hold, but more climbs end between 10 and
// 20 (floor 20 at 24.6% over the 500 guard seeds).
// Re-banded when the bot came to play the app's Tower fight (the user's
// call on the Tower review, docs/proposals/tower-mechanics-review.md §1.9:
// the clans' standings and the main die's Resonance, the floors' affixes
// rolled and forced, the real Elite, no goal, a weak face rerolled within
// the round's three rolls). No number of the Tower moved; the bot's batch
// did. Seeds 1 to 2000, no unlocks: median 17 to 18, floor 20 36.2% to
// 42.4%, the top 12.3% to 17.5% (the affixes and the Elite alone take it
// to 7.2%, the rerolls give back more); every unlock: the top 22.6% to
// 27.0%. On the 500 guard seeds: median 18, floor 20 45.2%, the top 21.0%,
// and 24.6% with every unlock. The bands sit around those, as wide as
// before.
// Re-banded when a die gained went to the bag (the Tower review §1.5: the
// hero keeps its calling's die, the bot tries a new one before it rolls
// it), the bot's fights lent the die's own skills as the app's are, and
// the three Tower dice got their Tower faces (§2.1 (c)). Seeds 1 to 2000,
// no unlocks: median 18 to 21, floor 20 42.4% to 52.5%, the top 17.5% to
// 22.1% (a mage 14.5% to 31.1%: it keeps its apprentice die); every
// unlock: the top 27.0% to 38.5%. On the 500 guard seeds: median 21,
// floor 20 52.8%, the top 23.0%, and 37.8% with every unlock. The bands
// sit around those, as wide as before.
// Re-banded for the Tower curve review (fix #5: less healing between
// floors, the foes 1.14 and the floors' extras re-spread, the bosses and
// wardens made peaks, the mage, warrior and rogue evened). Seeds 1 to 2000,
// no unlocks: median 21 to 17, floor 20 52.5% to 41.5%, the top 22.1% to
// 13.6%; every unlock: the top 38.5% to 28.7%. On the 500 guard seeds:
// median 17, floor 20 43.2%, the top 13.2%, and 30.8% with every unlock.
// The bands sit around those, as wide as before.
const _medianFloor = (min: 14, max: 20);
const _floor20 = (min: 0.33, max: 0.53);
const _topNone = (min: 0.07, max: 0.20);
const _topAll = (min: 0.23, max: 0.37);

/// The floor events' version the batch and the guards play (TOWER_EVENTS):
/// the foes' scale and the floors' extras of floor events PR 2 are set for
/// the climb with them on (docs/proposals/tower-snakes-and-ladders.md).
final _events = int.tryParse(Platform.environment['TOWER_EVENTS'] ?? '') ?? 1;

/// The first seeds of the in-suite batch (the full batch is TOWER_SEEDS).
const _guardSeeds = 500;

final _data = towerDataFromAssets();

List<TowerRun> _play(int first, int count, TowerProgress progress,
        {int? events}) =>
    [
      for (var seed = first; seed < first + count; seed++)
        playTowerRun(
            seed: seed,
            data: _data,
            progress: progress,
            events: events ?? _events),
    ];

int _median(List<int> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

double _share(List<TowerRun> runs, bool Function(TowerRun) test) =>
    runs.where(test).length / runs.length;

Map<String, dynamic> _json(TowerRun run) => {
      'seed': run.seed,
      'race': run.raceId,
      'profession': run.professionId,
      'clan': run.mainClanId,
      'clans': run.clanIds,
      'status': run.status.name,
      'floorReached': run.floorReached,
      'floorsCleared': run.floorsCleared,
      'marks': run.marks,
      'crest': run.crest,
      'setbacks': run.setbacks,
      'refused': run.refused.length,
      'spoils': run.spoils.values.fold<int>(0, (n, items) => n + items.length),
      'taken': {
        for (final e in run.taken.entries) '${e.key}': e.value.kind.name,
      },
    };

void main() {
  final none = _play(1, _guardSeeds, const TowerProgress());
  final all = _play(1, _guardSeeds, towerAllUnlocked);

  test('batch: the bot over TOWER_SEEDS seeds, with and without the unlocks',
      () {
    final out = Platform.environment['TOWER_OUT'];
    // Without TOWER_OUT this is not the report batch: nothing to do.
    if (out == null) return;
    final count =
        int.tryParse(Platform.environment['TOWER_SEEDS'] ?? '') ?? 500;
    final first = int.tryParse(Platform.environment['TOWER_FIRST'] ?? '') ?? 1;
    final cases = {
      'none': _play(first, count, const TowerProgress()),
      'all': _play(first, count, towerAllUnlocked),
    };
    File(out)
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'first': first,
        'count': count,
        'top': towerTop,
        'events': _events,
        'cases': {
          for (final e in cases.entries)
            e.key: [for (final r in e.value) _json(r)],
        },
      }));
  });

  // (That a run ends won or dead, that a seed gives the same tower and run,
  // and that every floor's foes are in their pool are held by Core's
  // test/tower_engine_test.dart: not repeated here.)
  test('a batch ends on the tower: floors 1 to $towerTop, no card left', () {
    for (final run in [...none, ...all]) {
      expect(run.floorReached, inInclusiveRange(1, towerTop),
          reason: 'seed ${run.seed}');
      expect(run.offer, isEmpty, reason: 'seed ${run.seed}: a card is left');
      if (run.status == TowerStatus.won) {
        expect(run.floorsCleared, towerTop, reason: 'seed ${run.seed}');
      }
    }
  });

  test(
      'the top is reachable: some run wins floor $towerTop, and no unlock '
      'is needed', () {
    expect(none.where((r) => r.status == TowerStatus.won), isNotEmpty,
        reason: 'no run of $_guardSeeds seeds, with no unlocks, wins the top');
    expect(all.where((r) => r.status == TowerStatus.won), isNotEmpty);
    // Every floor is fought by someone: the climb has no wall.
    final reached = {for (final r in none) r.floorReached};
    for (var floor = 1; floor <= towerTop; floor++) {
      expect(reached.any((f) => f >= floor), isTrue,
          reason: 'floor $floor is never reached');
    }
  });

  void balance(List<TowerRun> none, List<TowerRun> all) {
    String line(String name, List<TowerRun> runs) => '$name: median floor '
        '${_median([for (final r in runs) r.floorReached])}, floor 20 '
        '${(100 * _share(runs, (r) => r.floorReached >= 20)).toStringAsFixed(1)}'
        '%, top '
        '${(100 * _share(runs, (r) => r.status == TowerStatus.won)).toStringAsFixed(1)}%';
    final reason = '${line('none', none)}; ${line('all', all)}';
    final median = _median([for (final r in none) r.floorReached]);
    expect(median, inInclusiveRange(_medianFloor.min, _medianFloor.max),
        reason: reason);
    expect(_share(none, (r) => r.floorReached >= 20),
        inInclusiveRange(_floor20.min, _floor20.max),
        reason: reason);
    expect(_share(none, (r) => r.status == TowerStatus.won),
        inInclusiveRange(_topNone.min, _topNone.max),
        reason: reason);
    expect(_share(all, (r) => r.status == TowerStatus.won),
        inInclusiveRange(_topAll.min, _topAll.max),
        reason: reason);
    // The unlocks help, they do not rule: all of them never lowers the top.
    expect(_share(all, (r) => r.status == TowerStatus.won),
        greaterThanOrEqualTo(_share(none, (r) => r.status == TowerStatus.won)),
        reason: reason);
  }

  test('the balance holds what the design asks (tower-mechanics.md §11)', () {
    balance(none, all);
  });

  // Today's climb, the floor events off (towerEventsLive 0, floor events
  // PR 2): its own foes' scale, held by the same bands on the same seeds.
  test('the balance holds with the floor events off', () {
    if (_events == 0) return;
    balance(_play(1, _guardSeeds, const TowerProgress(), events: 0),
        _play(1, _guardSeeds, towerAllUnlocked, events: 0));
  });
}
