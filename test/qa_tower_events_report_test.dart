// QA report: how often the Tower's floor events fire, and how they end, for
// the bot over a seed batch (floor events PR 1 and 2, v1.944).
//
// Inert unless TOWER_EVENTS_OUT=<file>; then the JSON of what the bot met. It
// reads the events from the bot's own card choice: after each floor won, the
// run's `lastEvent` is how that floor's event ended (a setback's test, a
// rival's rounds) and `shortcut` is the choice on that floor's shortcut. A
// shortcut taken and lost ends the run on that floor (status dead, shortcut
// true). TOWER_SEEDS (default 2000) from TOWER_FIRST (default 1); the events
// version is `towerEventsLive` unless TOWER_EVENTS is set.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final out = Platform.environment['TOWER_EVENTS_OUT'];
  test('the Tower events the bot meets (TOWER_EVENTS_OUT)', () {
    if (out == null) return;
    final seeds =
        int.tryParse(Platform.environment['TOWER_SEEDS'] ?? '') ?? 2000;
    final first = int.tryParse(Platform.environment['TOWER_FIRST'] ?? '') ?? 1;
    final events = int.tryParse(Platform.environment['TOWER_EVENTS'] ?? '') ??
        towerEventsLive;
    final data = towerDataFromAssets();
    final report = <String, dynamic>{
      'first': first,
      'count': seeds,
      'events': events,
      'cases': <String, dynamic>{},
    };
    for (final (name, progress) in [
      ('none', const TowerProgress()),
      ('all', towerAllUnlocked),
    ]) {
      final tally = <String, int>{};
      void add(String key) => tally[key] = (tally[key] ?? 0) + 1;
      // The shortcut's floor (the floor fought): taken, and lost there.
      final byFloor = <String, Map<String, int>>{
        'shortcut_taken': <String, int>{},
        'shortcut_lost': <String, int>{},
      };
      void addAt(String key, int floor) {
        final m = byFloor[key]!;
        m['$floor'] = (m['$floor'] ?? 0) + 1;
      }

      final rows = <Map<String, dynamic>>[];
      for (var seed = first; seed < first + seeds; seed++) {
        final run = playTowerRun(
          seed: seed,
          data: data,
          progress: progress,
          events: events,
          choice: (run) {
            final e = run.lastEvent;
            if (e != null) {
              add('${e.kind.name}_${e.passed ? 'passed' : 'failed'}');
            }
            if (run.parley != null) {
              add(run.parley! ? 'parley_talked_failed' : 'parley_fought');
            }
            if (run.shortcut != null) {
              add(run.shortcut! ? 'shortcut_taken_won' : 'shortcut_declined');
              if (run.shortcut!) addAt('shortcut_taken', run.floor);
            }
            return towerBotChoice(run);
          },
        );
        if (run.status == TowerStatus.dead && run.parley != null) {
          add(run.parley! ? 'parley_talked_failed_died' : 'parley_fought_died');
        }
        // The floors that held a parley, a merchant or a bargain, counted
        // from the draw (the floors the run reached), and the stores' use.
        final base = towerStart(
            seed: seed,
            raceId: run.raceId,
            professionId: run.professionId,
            events: events,
            data: data);
        for (var f = 1; f <= run.floorReached && f < towerTop; f++) {
          final kind = towerEventKindOf(base.copyWith(floor: f));
          if (kind == TowerEventKind.parley) add('parley_floors');
        }
        if (run.bought.isNotEmpty) add('runs_that_bought');
        for (final e in run.bought.entries) {
          add('stores_with_a_purchase');
          for (final id in e.value) {
            add('bought_$id');
          }
        }
        if (run.marksSpent > 0) add('runs_that_spent_marks');
        for (final cut in run.bargains.values) {
          add(cut > 0 ? 'bargain_signed' : 'bargain_refused');
        }
        if (!run.isOver) add('RUN_NOT_OVER');
        if (run.status == TowerStatus.dead && (run.shortcut ?? false)) {
          add('shortcut_taken_lost');
          addAt('shortcut_taken', run.floor);
          addAt('shortcut_lost', run.floor);
        }
        rows.add({
          'seed': seed,
          'status': run.status.name,
          'floorReached': run.floorReached,
          'setbacks': run.setbacks,
          'crest': run.crest,
          'marksSpent': run.marksSpent,
          'bought': run.bought.values.fold<int>(0, (n, v) => n + v.length),
          'bargains': run.bargains.length,
        });
      }
      (report['cases'] as Map<String, dynamic>)[name] = {
        'tally': tally,
        'byFloor': byFloor,
        'runs': rows,
      };
    }
    File(out).writeAsStringSync(jsonEncode(report));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
