// QA: every test that runs the playthrough simulator loads the same tables as
// the simulator screen does. Without training_paths.json the simulated
// levels never spend their stat picks, and the numbers come out inflated
// (Core's finding on the v1.473 L3: the boss mean 60 instead of 52, the Archon
// and Tallis well above their curve). A file that leaves one out on purpose
// carries `// sim-tables-ok: <table>: <why>` on the line of the call.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the simulator reads from its `tables` and from the stat picks.
const _required = ['expedition_steps', 'training_paths'];

void main() {
  test('every simulator test loads the tables the simulator needs', () {
    final problems = <String>[];
    var seen = 0;
    for (final entity in Directory('test').listSync()) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
      if (entity.path.endsWith('qa_sim_tables_test.dart')) continue;
      final source = entity.readAsStringSync();
      if (!source.contains('simulatePlaythroughs(')) continue;
      seen++;
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
        reason: 'Add the table to the file\'s list (the stat picks run only '
            'with training_paths), or mark it `// sim-tables-ok: <table>: '
            'why`:\n${problems.join('\n')}');
  });
}
