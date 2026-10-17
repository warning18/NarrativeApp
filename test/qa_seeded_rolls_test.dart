// QA: a test that rolls a check must seed it. Since v1.458 a natural 1 always
// fails an ability check and a natural 20 always passes, so a test that rolls
// with an unseeded Random (or expects a high score to always pass) fails
// about one run in twenty. This reads every test file and flags
//   - an unseeded `Random()`,
//   - a call of rollAbilityCheck or resolveSkillChallenge with no `random:`,
//   - a VoyageScreen, LandCrossingScreen, ExpeditionScreen or
//     SkillChallengeScreen built with no `debugRandom:` / `random:` (each rolls its checks with a Random of its
//     own when none is given).
// A line that has to do either carries `// unseeded-ok` with its reason.
// (A widget test that taps a check choice in the story player rolls through
// storyCheckRandomProvider: override it with ProviderScope(overrides: [
// storyCheckRandomProvider.overrideWithValue(Random(1))]). Not seen here.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _rollers = [
  'rollAbilityCheck(',
  'resolveSkillChallenge(',
  'VoyageScreen(',
  'LandCrossingScreen(',
  'ExpeditionScreen(',
  'SkillChallengeScreen(',
];

/// The problems in [source], as `line: what`.
List<String> unseededRolls(String source) {
  final problems = <String>[];
  final lines = source.split('\n');
  int lineOf(int index) => '\n'.allMatches(source.substring(0, index)).length;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('unseeded-ok')) continue;
    if (RegExp(r'\bRandom\(\)').hasMatch(line) &&
        !line.trimLeft().startsWith('//')) {
      problems.add('${i + 1}: an unseeded Random()');
    }
  }
  for (final roller in _rollers) {
    var from = 0;
    while (true) {
      final at = source.indexOf(roller, from);
      if (at < 0) break;
      from = at + roller.length;
      // Not the definition or a comment.
      final lineStart = source.lastIndexOf('\n', at) + 1;
      final before = source.substring(lineStart, at);
      if (before.trimLeft().startsWith('//')) continue;
      var depth = 1, end = from;
      while (end < source.length && depth > 0) {
        final c = source[end++];
        if (c == '(') depth++;
        if (c == ')') depth--;
      }
      final call = source.substring(at, end);
      final line = lines[lineOf(at)];
      if (!call.contains('andom:') && !line.contains('unseeded-ok')) {
        problems.add('${lineOf(at) + 1}: ${roller.replaceAll('(', '')} '
            'with no random:');
      }
    }
  }
  return problems;
}

void main() {
  test('the scan itself sees an unseeded roll and lets a seeded one pass', () {
    expect(
        unseededRolls('final r = Random();\n'
            'rollAbilityCheck(ability: "a", dc: 1, session: s);\n'
            'resolveSkillChallenge(ability: "a", dc: 1, session: s,\n'
            '    successesNeeded: 1, maxFailures: 1);\n'
            'home: VoyageScreen(fromPortId: "a", toPortId: "b"),\n'
            'LandCrossingScreen(route: r, events: e);\n'
            'SkillChallengeScreen(ability: "a", dc: 1);'),
        hasLength(6));
    expect(
        unseededRolls('final r = Random(7);\n'
            'rollAbilityCheck(ability: "a", dc: 1, session: s, random: r);\n'
            'resolveSkillChallenge(ability: "a", dc: 1, session: s,\n'
            '    successesNeeded: 1, maxFailures: 1, random: r);\n'
            'VoyageScreen(fromPortId: "a", debugRandom: Random(1)),\n'
            'LandCrossingScreen(route: r, events: e, random: Random(1));\n'
            'SkillChallengeScreen(ability: "a", dc: 1, random: Random(1));\n'
            'final x = Random(); // unseeded-ok: only picks a name'),
        isEmpty);
  });

  test('no test file rolls a check without a seed', () {
    final found = <String>[];
    for (final entity in Directory('test').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('qa_seeded_rolls_test.dart')) continue;
      for (final problem in unseededRolls(entity.readAsStringSync())) {
        found.add('${entity.path}:$problem');
      }
    }
    expect(found, isEmpty,
        reason: 'Seed the roll (Random(7)), or mark the line `// unseeded-ok` '
            'with why:\n${found.join('\n')}');
  });
}
