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

typedef _Group = ({
  List<String> gated,
  List<String> triggers,
  List<String> ignores
});

/// tool/sim_gate.txt, by group.
Map<String, _Group> _groups() {
  final found = <String, _Group>{};
  _Group? current;
  for (final raw in File('tool/sim_gate.txt').readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('group ')) {
      current = (gated: <String>[], triggers: <String>[], ignores: <String>[]);
      found[line.substring(6).trim()] = current;
    } else if (current != null) {
      if (line.startsWith('gated '))
        current.gated.add(line.substring(6).trim());
      if (line.startsWith('trigger ')) {
        current.triggers.add(line.substring(8).trim());
      }
      if (line.startsWith('ignore ')) {
        current.ignores.add(line.substring(7).trim());
      }
    }
  }
  return found;
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

/// The local files the Dart files [start] import themselves.
Set<String> _direct(Iterable<String> start) {
  final seen = <String>{};
  final pattern = RegExp(r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true);
  for (final path in start) {
    final file = File(path);
    if (!file.existsSync()) continue;
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      final target = m.group(1)!;
      if (target.startsWith('package:narrative_data_app/')) {
        seen.add(
            'lib/${target.substring('package:narrative_data_app/'.length)}');
      }
    }
  }
  return seen;
}

void main() {
  final groups = _groups();
  final gated = [for (final g in groups.values) ...g.gated];
  final triggers = [for (final g in groups.values) ...g.triggers];
  final ignores = [for (final g in groups.values) ...g.ignores];

  test('both groups are there, each with gated files and triggers', () {
    expect(groups.keys, containsAll(['simulator', 'screens']));
    for (final e in groups.entries) {
      expect(e.value.gated, isNotEmpty, reason: e.key);
      expect(e.value.triggers, isNotEmpty, reason: e.key);
    }
  });

  test('the gated tests exist and have a shard weight', () {
    expect(gated, isNotEmpty);
    final weights =
        jsonDecode(File('test/shard_weights.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final name in gated) {
      expect(File('test/$name').existsSync(), isTrue, reason: 'test/$name');
      expect(weights.containsKey(name), isTrue,
          reason: '$name needs a weight in test/shard_weights.json');
    }
  });

  test('every trigger and ignore names a path that exists', () {
    expect(triggers, isNotEmpty);
    for (final prefix in [...triggers, ...ignores]) {
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
          reason: '"$prefix" matches nothing, so it can never fire');
    }
  });

  test('the simulator triggers cover every lib/ file those tests read', () {
    final group = groups['simulator']!;
    final reached = _closure(group.gated.map((n) => 'test/$n'))
        .where((p) => p.startsWith('lib/'));
    expect(reached, isNotEmpty);
    final uncovered = reached
        .where((p) =>
            !group.triggers.any(p.startsWith) &&
            !_presentation.any(p.startsWith))
        .toList()
      ..sort();
    expect(uncovered, isEmpty,
        reason: 'The gated tests import these files, but no trigger in '
            'tool/sim_gate.txt covers them: a change there would skip the '
            'tests on a pull request. Add a trigger (or, for presentation '
            'only, a folder to _presentation here):\n${uncovered.join('\n')}');
  });

  test('the screens group ignores only folders its tests never import', () {
    final group = groups['screens']!;
    expect(group.ignores, isNotEmpty);
    // What the tests import themselves, and what their harness imports (not
    // what those reach in turn: the whole app imports the Tower's folders
    // through the main menu, and those compile in every other test).
    final reached = _direct([
      for (final n in group.gated) 'test/$n',
      'test/qa_smoke_harness.dart',
    ]).where((p) => p.startsWith('lib/'));
    expect(reached, isNotEmpty);
    // Each ignored folder lies inside a trigger (else it would be pointless).
    for (final prefix in group.ignores) {
      expect(group.triggers.any(prefix.startsWith), isTrue,
          reason: 'ignore $prefix is not inside any trigger');
    }
    final read = reached.where((p) => group.ignores.any(p.startsWith)).toList()
      ..sort();
    expect(read, isEmpty,
        reason:
            'The screen smoke tests now import these files themselves, which '
            'tool/sim_gate.txt ignores: a change there would skip them on a '
            'pull request. Remove the ignore:\n${read.join('\n')}');
    // Whatever draws a screen is a trigger: the folders of the screens, the
    // widgets, the text, the fonts and the data.
    for (final path in [
      'lib/screens/fight_screen.dart',
      'lib/widgets/poly_die.dart',
      'lib/l10n/app_strings.dart',
      'assets/gamedata/skills.json',
      'pubspec.yaml',
    ]) {
      expect(
          group.triggers.any(path.startsWith) &&
              !group.ignores.any(path.startsWith),
          isTrue,
          reason: '$path must run the screen smoke tests');
    }
  });

  test('the workflow skips only on a pull request and uses the gate', () {
    final yml = File('.github/workflows/build_apk.yml').readAsStringSync();
    expect(yml, contains('--changed'));
    expect(
        yml, contains(r'if [ "${{ github.event_name }}" = "pull_request" ]'));
    expect(yml, contains('fetch-depth: 2'));
    // The default is to run everything: the flag is set only on a pull
    // request, from the paths git lists as changed.
    expect(yml, contains(r'changed=""'));
    expect(yml, contains('git diff --name-only HEAD^1 HEAD'));
    expect(yml, isNot(contains('--skip-gated')));
  });
}
