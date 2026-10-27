// The Smugglers' Wharf lists fewer entries at once (v1.578): the harbor
// master's four errands come one at a time, the two doors off the wharf are
// one row that retires when both are seen, and the three ways past Vane are
// one row. Every old scene and flag is still reachable.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _json(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative');
}

void main() {
  final dag = _json('assets/Cleaned_Narrative_DAG.json');
  final nodes = {
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  };
  final plan = (_json('assets/gamedata/city_plans.json')['saltmouth']
      as Map<String, dynamic>);
  final anchors =
      (plan['anchors'] as Map<String, dynamic>).cast<String, String>();
  final district = {
    for (final b in plan['buildings'] as List)
      (b as Map<String, dynamic>)['id'] as String: b['district'] as String,
  };
  final hub = nodes['2015']!;

  List<String> visible(Set<String> flags) => [
        for (final c in hub.choices)
          if (!c.isHiddenFor(flags) &&
              district[anchors[c.nextId]] == 'saltmouth_wharf')
            c.nextId,
      ];

  test('a new game sees at most five entries at the wharf', () {
    final start = visible({});
    expect(start.length, lessThanOrEqualTo(5), reason: '$start');
    // The harbor master's work: one job at a time, the first one now.
    expect(start, contains('2015_dockside'));
    for (final later in ['2015_rats', '2015_bandits', '2015_smuggler']) {
      expect(start, isNot(contains(later)));
    }
    expect(start, contains('2015_doors'));
    expect(start, contains('2015_vane'));
    // The three ways past Vane are no longer rows of the hub.
    for (final way in ['2030', '2040', '2011']) {
      expect(start, isNot(contains(way)));
    }
  });

  test('the harbor master\'s work comes in order, each retiring in turn', () {
    final flags = <String>{};
    for (final step in [
      ['2015_dockside', 'hub_2015_dockside'],
      ['2015_rats', 'hub_2015_rats'],
      ['2015_bandits', 'hub_2015_bandits'],
      ['2015_smuggler', 'hub_2015_smuggler'],
    ]) {
      final harbor = visible(flags)
          .where((id) => const {
                '2015_dockside',
                '2015_rats',
                '2015_bandits',
                '2015_smuggler'
              }.contains(id))
          .toList();
      expect(harbor, [step[0]]);
      flags.add(step[1]);
    }
    expect(visible(flags).where((id) => id.startsWith('2015_s')), isEmpty);
  });

  test('the doors: each way once, the row retires after both', () {
    final doors = nodes['2015_doors']!;
    bool shows(String next, Set<String> f) =>
        doors.choices.any((c) => c.nextId == next && !c.isHiddenFor(f));
    expect(shows('2015_alleys_door', {}), isTrue);
    expect(shows('2015_ternrow_door', {}), isTrue);
    expect(shows('2015_alleys_door', {'hub_2015_alleys_door'}), isFalse);

    // Whichever door goes first, the second one's end sets the done flag.
    for (final order in [
      ['2015_alleys_door', '2015_ternrow_door'],
      ['2015_ternrow_door', '2015_alleys_door'],
    ]) {
      final flags = <String>{};
      for (var i = 0; i < 2; i++) {
        final door = nodes[order[i]]!;
        final ends = door.choices.where((c) => !c.isHiddenFor(flags)).toList();
        expect(ends, isNotEmpty, reason: order[i]);
        for (final end in ends) {
          expect(end.nextId, i == 0 ? '2015_doors' : '2015', reason: order[i]);
          expect(end.flagsToAdd.contains('wharf_doors_done'), i == 1);
        }
        flags.addAll(ends.first.flagsToAdd);
      }
      expect(visible(flags), isNot(contains('2015_doors')));
    }
  });

  test('the Tern Row door still opens Tern\'s Toll, whichever way', () {
    final quests = [
      for (final c in nodes['2015_ternrow_door']!.choices)
        if (c.unlockQuestId != null) c.unlockQuestId,
    ];
    expect(quests, ['q_ch2_terns_toll', 'q_ch2_terns_toll']);
  });

  test('Vane\'s three ways are still there, with a way back', () {
    final vane = nodes['2015_vane']!;
    expect(vane.choices.map((c) => c.nextId), ['2030', '2040', '2011', '2015']);
    expect(vane.facing, 'vane_quartermaster');
  });
}
