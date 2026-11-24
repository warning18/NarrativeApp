// The balance batch on several cores (Wave 5): N full playthroughs split in
// slices that run side by side in isolates, each slice numbering its runs
// from its first (simulatePlaythroughs' firstRun), so the batch plays
// exactly the runs one long batch would. Skipped unless SIM_BATCH_OUT names
// the JSON file to write:
//
//   SIM_BATCH_OUT=/tmp/batch.json SIM_BATCH_RUNS=100 SIM_BATCH_SEED=1 \
//   SIM_BATCH_POLICY=typical SIM_BATCH_CORES=4 \
//   flutter test test/sim_batch_test.dart
//
// The plan is the balance reports' (docs/simulation/): the goals in turn,
// the professions rotating after each round of them. Each run is one row:
// its profession, goal, ending, final die, level, gold, fights won and
// lost, rounds, the Tear Herald beaten or not, the politics events fired.
// A smaller check, always on, proves the slicing: two slices of a short
// batch are the same runs as the batch in one piece.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/sim_policy.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

/// Runs [first] .. [first] + [count] - 1 of the batch, as rows.
List<Map<String, dynamic>> _slice({
  required int first,
  required int count,
  required int seed,
  required SimPolicy policy,
}) {
  final tables = simTables();
  final professions = tables['professions']!.keys.toList()..sort();
  const goals = SimStrategy.values;
  final plan = [
    for (var i = first; i < first + count; i++)
      (
        strategy: goals[i % goals.length],
        raceId: null as String?,
        professionId:
            professions[(i ~/ goals.length) % professions.length] as String?,
      ),
  ];
  final runs = simulatePlaythroughs(simStory(),
      tables: tables,
      gameConfig: simGameConfig(),
      plan: plan,
      seed: seed,
      policy: policy,
      firstRun: first);
  return [
    for (var i = 0; i < runs.length; i++)
      {
        'run': first + i,
        'profession': runs[i].professionId,
        'goal': runs[i].strategy.name,
        'ended': runs[i].endedHow,
        'chapter': runs[i].furthestChapter,
        'die': runs[i].die,
        'level': runs[i].finalLevel,
        'gold': runs[i].finalGold,
        'won': runs[i].fightsWon,
        'lost': runs[i].fightsLost,
        'rounds': runs[i].roundsFought,
        'herald': (runs[i].enemiesFought['tear_herald'] ?? 0) >
            (runs[i].enemiesLost['tear_herald'] ?? 0),
        'events': runs[i].politics.firedEvents.keys.toList()..sort(),
      },
  ];
}

/// The batch of [runs] in [cores] slices, side by side, in run order.
Future<List<Map<String, dynamic>>> _batch({
  required int runs,
  required int seed,
  required SimPolicy policy,
  required int cores,
}) async {
  final size = (runs / cores).ceil();
  final slices = [
    for (var first = 0; first < runs; first += size)
      Isolate.run(() => _slice(
          first: first,
          count: first + size > runs ? runs - first : size,
          seed: seed,
          policy: policy)),
  ];
  return [for (final s in await Future.wait(slices)) ...s];
}

void main() {
  test('a batch in slices plays the same runs as in one piece', () async {
    final whole =
        _slice(first: 0, count: 4, seed: 5, policy: SimPolicy.typical);
    final sliced =
        await _batch(runs: 4, seed: 5, policy: SimPolicy.typical, cores: 2);
    expect(jsonEncode(sliced), jsonEncode(whole));
  });

  final out = Platform.environment['SIM_BATCH_OUT'];
  test('the balance batch on several cores', skip: out == null, () async {
    final env = Platform.environment;
    final runs = int.parse(env['SIM_BATCH_RUNS'] ?? '100');
    final seed = int.parse(env['SIM_BATCH_SEED'] ?? '1');
    final cores = int.parse(
        env['SIM_BATCH_CORES'] ?? '${Platform.numberOfProcessors.clamp(1, 4)}');
    final policies = [
      for (final name
          in (env['SIM_BATCH_POLICY'] ?? 'typical,competent').split(','))
        SimPolicy.values.byName(name.trim()),
    ];
    final result = <String, dynamic>{
      'runs': runs,
      'seed': seed,
      'cores': cores,
    };
    for (final policy in policies) {
      final watch = Stopwatch()..start();
      result[policy.name] =
          await _batch(runs: runs, seed: seed, policy: policy, cores: cores);
      result['${policy.name}Seconds'] = watch.elapsed.inMilliseconds / 1000;
    }
    File(out!).writeAsStringSync(jsonEncode(result));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
