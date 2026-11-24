// The intrigue hints (Narrative's P1c): each of the ten intrigues with a
// Hook has one line pointing at its Clue, on a node every route passes,
// shown to a banner bearer until the Clue is taken, and one reminder in a
// later camp, shown once the Clue is held until the Hook (or a later stage)
// is reached. Both sit at the lowest priority, so a callback cap drops them
// first.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final parsed = <String, StoryNode>{};
  StoryNode node(String id) =>
      parsed[id] ??= StoryNode.fromJson(id, dag[id] as Map<String, dynamic>);

  // intrigue: (clue host, flag that hides the clue hint, reminder camp)
  const hints = {
    'hooded_lantern': ('2010', 'hub_2015_informant', '3001_camp'),
    'dying_lantern_bearer': ('2005', null, '3001_camp'),
    'broken_charter': ('2015', 'hub_2015_dominion_blades', '4999_camp'),
    'double_ledger': ('2015', 'hub_2015_route_sold', '4999_camp'),
    'the_returned': ('2015', 'hub_2015_child_tongue', '4999_camp'),
    'admiraltys_silence': ('2015', 'hub_2015_survivor', '4999_camp'),
    'relic_road': ('2015', 'hub_2015_bundle', '4999_camp'),
    'unwatched_hour': ('3005', 'hub_3100_new_moon', '6002_camp'),
    'lanternbearers_will': ('3005', 'hub_6100_will_scribe', '7001'),
    'taken_names': (
      '3005_clan_vigil_1',
      'intrigue_taken_names_stage_1',
      '7001'
    ),
  };

  for (final MapEntry(key: id, value: (host, hideFlag, camp))
      in hints.entries) {
    test('$id: a clue hint, then a reminder until the Hook', () {
      final clue = node(host)
          .flagCallbacks
          .where((c) =>
              c.flag == 'void_banner_bearer' &&
              c.priority < 0 &&
              (hideFlag == null
                  ? c.unlessFlags.isEmpty
                  : c.unlessFlags.contains(hideFlag)))
          .toList();
      expect(clue, hasLength(1), reason: '$host has no hint for $id');
      expect(clue.single.line.fr, isNotEmpty);

      final stage1 = intrigueStageFlag(id, 1);
      final reminder = node(camp)
          .flagCallbacks
          .where((c) => c.flag == stage1 && c.priority < 0)
          .single;
      expect(reminder.line.fr, isNotEmpty);
      final shown = node(camp).firedCallbacks([stage1]);
      expect(shown, contains(reminder));
      for (var n = 2; n <= 6; n++) {
        expect(node(camp).firedCallbacks([stage1, intrigueStageFlag(id, n)]),
            isNot(contains(reminder)),
            reason: 'stage $n');
      }
    });
  }

  test('a capped camp drops the reminders before any earlier line', () {
    final camp = node('7001');
    final cap = camp.callbackCap!;
    final others = [
      for (final c in camp.flagCallbacks)
        if (c.priority >= 0) c.flag
    ].take(cap).toList();
    final fired = camp.firedCallbacks([
      ...others,
      intrigueStageFlag('lanternbearers_will', 1),
      intrigueStageFlag('taken_names', 1),
    ]);
    expect(fired, hasLength(cap));
    expect(fired.every((c) => c.priority >= 0), isTrue);
  });
}
