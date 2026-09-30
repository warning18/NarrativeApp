// The late chapters' set pieces (v1.176): a timed chase out of the
// Court's catacombs, the siege of the camp in waves, the Hollow Shore
// crossed unseen, and a sea battle with the Crusade's last cutter -- and
// the clock that runs over a timed scene's choices.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/widgets/timed_choice_bar.dart';

void main() {
  final raw =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final nodes = {
    for (final entry in raw.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };

  test('a timed scene keeps its clock and its fallback through a save', () {
    final node = StoryNode.fromJson('t', const {
      'description': 'Run.',
      'time_limit': 15,
      'timeout_choice': 1,
      'choices': [
        {'text': 'Left', 'next_id': 'a'},
        {'text': 'Right', 'next_id': 'b'},
      ],
    });
    expect(node.isTimed, isTrue);
    expect(node.timeoutChoiceOrNull!.text, 'Right');
    final back = StoryNode.fromJson('t', node.toJson());
    expect(back.timeLimit, 15);
    expect(back.timeoutChoice, 1);
    expect(nodes['2001']!.isTimed, isFalse);
    expect(nodes['2001']!.toJson(), isNot(contains('time_limit')));
  });

  test('every timed scene falls back on a way it offers', () {
    final timed = nodes.values.where((n) => n.isTimed).toList();
    expect(timed.map((n) => n.id),
        containsAll(['5006_chase', '6002_siege', '6002_siege_2']));
    for (final node in timed) {
      expect(node.timeoutChoice, inInclusiveRange(0, node.choices.length - 1),
          reason: node.id);
      final fallback = node.timeoutChoiceOrNull!;
      expect(fallback.showIfFlags, isEmpty, reason: node.id);
      expect(passThroughChoiceOf(node, const []), isNull, reason: node.id);
    }
  });

  test('the chase leaves the catacombs by three roads, all out', () {
    for (final choice in nodes['5005']!.choices) {
      expect(choice.nextId, '5006_chase');
    }
    final chase = nodes['5006_chase']!;
    expect(chase.choices, hasLength(3));
    expect(chase.timeoutChoiceOrNull!.triggersCombat, isTrue,
        reason: 'dithering lets them catch up');
    for (final choice in chase.choices) {
      expect(choice.nextId, '6001');
      if (choice.hasAbilityCheck) expect(choice.failNextId, '5006_cornered');
    }
    expect(nodes['5006_cornered']!.choices.single.triggersCombat, isTrue);
  });

  test('the siege comes in waves, and every way through it ends at camp', () {
    final siege = nodes['6002_siege']!;
    final second = nodes['6002_siege_2']!;
    expect(siege.choices.where((c) => c.triggersCombat), isNotEmpty);
    expect(second.choices.where((c) => c.hasSkillChallenge), isNotEmpty);
    final reached = <String>{};
    void walk(String id) {
      if (!reached.add(id) || id == '6002_camp') return;
      for (final choice in nodes[id]!.choices) {
        walk(choice.nextId);
        if (choice.failNextId != null) walk(choice.failNextId!);
      }
    }

    walk('6002_siege');
    expect(reached, contains('6002_siege_breach'));
    expect(reached, contains('6002_camp'));
    expect(reached.where((id) => !id.startsWith('6002')), isEmpty);
    // What the party did there is told back at the camp.
    final told = nodes['6002_camp']!.flagCallbacks.map((c) => c.flag).toSet();
    for (final id in reached) {
      for (final choice in nodes[id]?.choices ?? const <StoryChoice>[]) {
        for (final flag in choice.flagsToAdd) {
          expect(told, contains(flag), reason: '$id: $flag');
        }
      }
    }
  });

  test('the shore is crossed by skill challenges or by force', () {
    final approach = nodes['7002_approach']!;
    expect(approach.choices.where((c) => c.hasSkillChallenge), hasLength(2));
    expect(approach.choices.where((c) => c.triggersCombat), hasLength(1));
    for (final choice in approach.choices) {
      expect(choice.nextId, '7002_confront');
      if (choice.hasSkillChallenge) expect(choice.failNextId, '7002_alarm');
    }
    expect(nodes['7002_alarm']!.choices.single.nextId, '7002_confront');
  });

  test('the Anchorage offers a sea battle with the Crusade’s last cutter', () {
    final cutter =
        nodes['7100']!.choices.singleWhere((c) => c.triggersShipBattle);
    expect(journeyStepKindOf(cutter), JourneyStepKind.fight);
    expect(cutter.nextId, '7100_cutter');
    expect(cutter.loseNextId, '7100_cutter_lost');
    expect(cutter.hideIfFlags, ['hub_7100_cutter']);
    final ships =
        jsonDecode(File('assets/gamedata/enemy_ships.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final node in nodes.values) {
      for (final choice in node.choices) {
        if (!choice.triggersShipBattle) continue;
        expect(ships, contains(choice.shipBattleId), reason: node.id);
        expect(nodes, contains(choice.loseNextId), reason: node.id);
      }
    }
    for (final id in ['7100_cutter', '7100_cutter_lost']) {
      final back = nodes[id]!.choices.single;
      expect(back.nextId, '7100');
      expect(back.flagsToAdd, ['hub_7100_cutter']);
    }
  });

  testWidgets('the clock runs out once, and only while it is on screen',
      (tester) async {
    var outs = 0;
    // Two bars for one scene, as the Story and Journey tabs have: [shown]
    // is the one on screen, the other is taken down.
    Widget bar({required bool active, String shown = 'story'}) => ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimedChoiceBar(
                key: ValueKey(shown),
                scene: timedSceneKey('6002_siege', 40),
                seconds: 4,
                active: active,
                label: 'Choose',
                onTimeout: () => outs++,
              ),
            ),
          ),
        );

    await tester.pumpWidget(bar(active: false));
    await tester.pump(const Duration(seconds: 10));
    expect(outs, 0);
    expect(find.text('4s'), findsOneWidget);

    await tester.pumpWidget(bar(active: true));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2s'), findsOneWidget);
    // Paused, it keeps its time.
    await tester.pumpWidget(bar(active: false));
    await tester.pump(const Duration(seconds: 10));
    expect(outs, 0);
    // The scene's other bar (the Journey tab's, or one built again after
    // reading full screen) goes on from there, not from the start.
    await tester.pumpWidget(bar(active: true, shown: 'journey'));
    await tester.pump();
    expect(find.text('2s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(bar(active: true));
    await tester.pump();
    expect(find.text('1s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(outs, 1);
    // Run out, it stays run out: no bar takes the way a second time.
    await tester.pumpWidget(bar(active: true, shown: 'journey'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('0s'), findsOneWidget);
    expect(outs, 1);
  });
}
