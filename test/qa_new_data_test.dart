// QA: the data the waves of v1.665 to v1.696 added, read as data (the L3 on
// v1.696, docs/qa/l3-1.696.0.md): the clans' dice, the hero's spoken replies,
// and the stage a scene forces for its fight.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/field_anomaly.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final graph = _json('assets/Cleaned_Narrative_DAG.json');
  Iterable<(String, int, Map<String, dynamic>)> choices() sync* {
    for (final e in graph.entries) {
      final list = (e.value as Map)['choices'] as List;
      for (var i = 0; i < list.length; i++) {
        yield (e.key, i, list[i] as Map<String, dynamic>);
      }
    }
  }

  test('each main clan has exactly one die, and only a main clan has one', () {
    final factions = _json('assets/gamedata/factions.json');
    final main = [
      for (final e in factions.entries)
        if (e.value is Map && (e.value as Map)['kind'] == 'clan') e.key,
    ];
    expect(main.length, 6);
    final dice = _json('assets/gamedata/dice.json');
    final byClan = <String, List<String>>{};
    for (final e in dice.entries) {
      final clan = (e.value as Map)['clan']?.toString() ?? '';
      if (clan.isNotEmpty) byClan.putIfAbsent(clan, () => []).add(e.key);
    }
    expect(byClan.keys.toSet(), main.toSet(),
        reason: 'every main clan has a die, nobody else does');
    for (final e in byClan.entries) {
      expect(e.value.length, 1, reason: '${e.key} gives one die: ${e.value}');
    }
  });

  test('the hero\'s spoken replies: both languages, short, never a copy', () {
    var seen = 0;
    final problems = <String>[];
    for (final (node, i, c) in choices()) {
      final en = c['reply'] as String?;
      final fr = c['reply_fr'] as String?;
      if (en == null && fr == null) continue;
      seen++;
      final where = '$node choice $i';
      if (en == null || en.trim().isEmpty) {
        problems.add('$where: reply_fr without a reply');
        continue;
      }
      if (fr == null || fr.trim().isEmpty) {
        problems.add('$where: reply without a reply_fr');
        continue;
      }
      if (en.length > 60 || fr.length > 60) {
        problems.add('$where: longer than 60 characters, the balloon is small');
      }
      if (en.trim() == fr.trim()) problems.add('$where: the French is a copy');
      if (en.trim() == (c['text'] as String).trim()) {
        problems.add('$where: the reply repeats the choice text');
      }
    }
    expect(seen, greaterThanOrEqualTo(40),
        reason: 'the replies written so far');
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('a scene that forces a stage names one the fight knows', () {
    final stages = {for (final s in FightStage.values) s.name};
    expect(stages.length, greaterThanOrEqualTo(21),
        reason: 'the thirteen older stages and the eight of v1.665');
    final bad = <String>[];
    for (final (node, i, c) in choices()) {
      final stage = c['forcedStage'] as String?;
      if (stage != null && stage.isNotEmpty && !stages.contains(stage)) {
        bad.add('$node choice $i: $stage');
      }
    }
    expect(bad, isEmpty, reason: 'unknown stages (known: $stages): $bad');
  });

  test('every newer stage borrows an older stage that has its own rules', () {
    for (final s in FightStage.values) {
      expect(s.kin.kin, s.kin,
          reason: '${s.name} borrows from ${s.kin.name}, which borrows again');
    }
  });
}
