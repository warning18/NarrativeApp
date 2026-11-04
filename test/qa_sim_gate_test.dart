// QA guard for the CI gate of the statistical simulator tests
// (tool/sim_gate.txt, tool/shard_tests.py, .github/workflows/build_apk.yml).
//
// On a pull request that changes none of the gate's `trigger` paths, CI leaves
// the `gated` test files out of its shards. That is only safe while the
// triggers cover everything those tests read, so this holds the list:
//   * the gated files exist and have a shard weight;
//   * every trigger names something that exists (a typo would never fire);
//   * every lib/ file the gated tests import, directly or through other
//     files, is under a trigger, apart from the presentation folders below;
//   * the workflow only skips on a pull request (main always runs them), and
//     reads the changed paths from git.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Folders the gated tests import but whose files cannot change a rate: text,
/// colours, icons and painters. A change there is still compiled and read by
/// every other test.
const _presentation = [
  'lib/l10n/',
  'lib/theme/',
  'lib/utils/',
  'lib/widgets/',
];

({List<String> gated, List<String> triggers}) _gate() {
  final gated = <String>[];
  final triggers = <String>[];
  for (final raw in File('tool/sim_gate.txt').readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('gated ')) gated.add(line.substring(6).trim());
    if (line.startsWith('trigger ')) triggers.add(line.substring(8).trim());
  }
  return (gated: gated, triggers: triggers);
}

/// Every local file the Dart file [start] imports, exports or has as a part,
/// followed through the files it reaches.
Set<String> _closure(Iterable<String> start) {
  final seen = <String>{};
  final stack = [...start];
  final pattern = RegExp(r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true);
  while (stack.isNotEmpty) {
    final path = stack.removeLast();
    if (!seen.add(path)) continue;
    final file = File(path);
    if (!file.existsSync()) continue;
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      final target = m.group(1)!;
      if (target.startsWith('dart:')) continue;
      if (target.startsWith('package:narrative_data_app/')) {
        stack.add(
            'lib/${target.substring('package:narrative_data_app/'.length)}');
      } else if (!target.startsWith('package:')) {
        final dir = path.substring(0, path.lastIndexOf('/'));
        stack.add(Uri.parse('$dir/$target').normalizePath().path);
      }
    }
  }
  return seen;
}

void main() {
  final gate = _gate();

  test('the gated simulator tests exist and have a shard weight', () {
    expect(gate.gated, isNotEmpty);
    final weights =
        jsonDecode(File('test/shard_weights.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final name in gate.gated) {
      expect(File('test/$name').existsSync(), isTrue, reason: 'test/$name');
      expect(weights.containsKey(name), isTrue,
          reason: '$name needs a weight in test/shard_weights.json');
    }
  });

  test('every trigger names a path that exists', () {
    expect(gate.triggers, isNotEmpty);
    for (final prefix in gate.triggers) {
      final dir = Directory(prefix);
      final inFolder = dir.existsSync();
      final parent = prefix.contains('/')
          ? prefix.substring(0, prefix.lastIndexOf('/') + 1)
          : '';
      final parentDir = Directory(parent.isEmpty ? '.' : parent);
      final siblings = parentDir.existsSync()
          ? parentDir
              .listSync()
              .map((e) => e.path.replaceFirst('./', ''))
              .where((p) => p.startsWith(prefix))
          : const <String>[];
      expect(
          inFolder || File(prefix).existsSync() || siblings.isNotEmpty, isTrue,
          reason: 'trigger "$prefix" matches nothing, so it can never fire');
    }
  });

  test('the triggers cover every lib/ file the gated tests read', () {
    final reached = _closure(gate.gated.map((n) => 'test/$n'))
        .where((p) => p.startsWith('lib/'));
    expect(reached, isNotEmpty);
    final uncovered = reached
        .where((p) =>
            !gate.triggers.any(p.startsWith) &&
            !_presentation.any(p.startsWith))
        .toList()
      ..sort();
    expect(uncovered, isEmpty,
        reason: 'The gated tests import these files, but no trigger in '
            'tool/sim_gate.txt covers them: a change there would skip the '
            'tests on a pull request. Add a trigger (or, for presentation '
            'only, a folder to _presentation here):\n${uncovered.join('\n')}');
  });

  test('the workflow skips only on a pull request and uses the gate', () {
    final yml = File('.github/workflows/build_apk.yml').readAsStringSync();
    expect(yml, contains('--gate'));
    expect(yml, contains('--skip-gated'));
    expect(
        yml, contains(r'if [ "${{ github.event_name }}" = "pull_request" ]'));
    expect(yml, contains('fetch-depth: 2'));
    // The default is to run: the skip flag is set only when the gate says so.
    expect(yml, contains('gate=run'));
    expect(yml, contains(r'if [ "$gate" = "skip" ]'));
  });
}
