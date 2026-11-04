// QA: every test that runs the simulator loads the tables the simulator
// screen does, and gets them from one place, test/support/sim_world.dart.
// Without training_paths.json the simulated levels never spend their stat
// picks and the numbers come out inflated (Core's finding on the v1.473 L3:
// the boss mean 60 instead of 52). Without politics_events.json no politics
// event fires (v1.513). Without companions.json the hero walks without Vica,
// who joins every hero since v1.601.
//
// A test calls `simTables()`. One that builds its own map carries every table
// in `_required` or, on the line of its call,
// `// sim-tables-ok: <table>: <why>`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/sim_world.dart';

/// What the simulator needs beyond the stat picks: the tables a test that
/// builds its own map must name.
const _required = [
  'expedition_steps',
  'training_paths',
  'politics_events',
  'companions',
];

/// The simulator's entry points.
final _calls = RegExp(r'simulate(Playthroughs|FightsByChapter)\(');

void main() {
  test('every simulator test loads the tables the simulator needs', () {
    final problems = <String>[];
    var seen = 0;
    for (final entity in Directory('test').listSync()) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
      if (entity.path.endsWith('qa_sim_tables_test.dart')) continue;
      final source = entity.readAsStringSync();
      if (!_calls.hasMatch(source)) continue;
      seen++;
      if (source.contains('simTables(')) continue;
      for (final table in _required) {
        final loaded = source.contains("'$table'");
        final excused = source.contains('sim-tables-ok: $table');
        if (!loaded && !excused) {
          problems.add('${entity.path}: no \'$table\' in its tables');
        }
      }
    }
    expect(seen, greaterThan(10), reason: 'the scan found the simulator tests');
    expect(problems, isEmpty,
        reason: 'Use simTables() from test/support/sim_world.dart, or add the '
            'table to the file\'s list, or mark it `// sim-tables-ok: '
            '<table>: why`:\n${problems.join('\n')}');
  });

  test('the shared list holds every table the simulator reads', () {
    final screen = File('lib/screens/playthrough_simulator_screen.dart')
        .readAsStringSync();
    final read = {
      for (final m in RegExp(r"table\('([a-z_]+)'\)").allMatches(screen))
        m.group(1)!,
    };
    expect(read, isNotEmpty);
    expect(simTableNames.toSet(), containsAll(read),
        reason: 'the simulator reads a table sim_world.dart does not load');
    expect(simTableNames.toSet().difference(read), isEmpty,
        reason: 'sim_world.dart loads a table the simulator does not read');
    expect(simTableNames, containsAll(_required));
  });
}
