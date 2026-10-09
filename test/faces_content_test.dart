import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The faces of the intrigues and the standing-aware lines of the people
/// (v1.210) name only people, factions and subclans that exist.
void main() {
  final npcs = _table('npcs');
  final intrigues = _table('intrigues');
  final factions = _table('factions');
  final subclans = _table('subclans');

  test('every npcId named by an intrigue stage or outcome is a person', () {
    final missing = <String>[];
    intrigues.forEach((id, raw) {
      final rec = raw as Map<String, dynamic>;
      for (final key in ['stages', 'outcomes']) {
        for (final item in rec[key] as List) {
          final npc = (item as Map<String, dynamic>)['npcId'] as String?;
          if (npc != null && npc.isNotEmpty && !npcs.containsKey(npc)) {
            missing.add('$id.$key -> $npc');
          }
        }
      }
    });
    expect(missing, isEmpty);
  });

  test('the two placed intrigues name a face on every stage they show', () {
    for (final id in ['hooded_lantern', 'dying_lantern_bearer']) {
      final stages = (intrigues[id] as Map)['stages'] as List;
      final named = stages
          .where((s) => ((s as Map)['npcId'] as String? ?? '').isNotEmpty)
          .length;
      expect(named, greaterThanOrEqualTo(5), reason: id);
    }
  });

  test('conditioned states use known factions and subclans, in both languages',
      () {
    final problems = <String>[];
    npcs.forEach((id, raw) {
      for (final s in (raw as Map<String, dynamic>)['states'] as List) {
        final state = s as Map<String, dynamic>;
        final cond = state['conditions'] as Map<String, dynamic>?;
        if (cond == null) continue;
        for (final key in ['standingAtLeast', 'standingAtMost']) {
          for (final f in ((cond[key] ?? const {}) as Map).keys) {
            if (!factions.containsKey(f)) problems.add('$id: faction $f');
          }
        }
        for (final sc in ((cond['marks'] ?? const {}) as Map).keys) {
          if (!subclans.containsKey(sc)) problems.add('$id: subclan $sc');
        }
        if ((state['line'] as String? ?? '').isEmpty ||
            (state['line_fr'] as String? ?? '').isEmpty) {
          problems.add('$id: a conditioned line lacks a language');
        }
        if ((state['flag'] as String? ?? '').isEmpty && cond.isEmpty) {
          problems.add('$id: a state with no flag and no condition');
        }
      }
    });
    expect(problems, isEmpty);
  });
}
