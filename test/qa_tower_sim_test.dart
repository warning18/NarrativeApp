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
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

/// What the design asks of a naive bot (tower-mechanics.md §11): the median
/// floor it reaches, how many reach floor 20, how many win floor 30.
const _medianFloor = (min: 12, max: 16);
const _floor20 = (min: 0.25, max: 0.35);
const _topNone = (min: 0.05, max: 0.10);
const _topAll = (min: 0.15, max: 0.25);

/// The first seeds of the in-suite batch (the full batch is TOWER_SEEDS).
const _guardSeeds = 500;

final _data = towerDataFromAssets();

List<TowerRun> _play(int first, int count, TowerProgress progress) => [
      for (var seed = first; seed < first + count; seed++)
        playTowerRun(seed: seed, data: _data, progress: progress),
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
      'clan': run.clanId,
      'status': run.status.name,
      'floorReached': run.floorReached,
      'floorsCleared': run.floorsCleared,
      'marks': run.marks,
      'refused': run.refused.length,
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

  test('the balance holds what the design asks (tower-mechanics.md §11)', () {
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
  });
}
