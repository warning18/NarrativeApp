// The Journey tab's map: what each step shows and where the steps sit.
import 'dart:convert';
import 'dart:io';

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/data/journey_relief.dart';
import 'package:narrative_data_app/models/story_node.dart';

StoryChoice _choice(Map<String, dynamic> json) =>
    StoryChoice.fromJson({'text': 'Go', 'next_id': '100', ...json});

void main() {
  group('step kinds', () {
    test('each kind of choice shows as its own step', () {
      expect(journeyStepKindOf(_choice({})), JourneyStepKind.road);
      expect(journeyStepKindOf(_choice({'next_id': 'END'})),
          JourneyStepKind.ending);
      expect(journeyStepKindOf(_choice({'mainQuest': true})),
          JourneyStepKind.mainQuest);
      expect(journeyStepKindOf(_choice({'launchZoneId': 'z_old_mill'})),
          JourneyStepKind.expedition);
      expect(journeyStepKindOf(_choice({'triggerEnemyId': 'harbor_rat'})),
          JourneyStepKind.fight);
      expect(
          journeyStepKindOf(_choice({
            'checkAbility': 'strength',
            'challengeSuccessesNeeded': 3,
            'challengeMaxFailures': 2,
          })),
          JourneyStepKind.challenge);
      expect(journeyStepKindOf(_choice({'checkAbility': 'wisdom'})),
          JourneyStepKind.check);
      expect(journeyStepKindOf(_choice({'unlockShopId': 'shop_a'})),
          JourneyStepKind.shop);
      expect(journeyStepKindOf(_choice({'unlockQuestId': 'q_a'})),
          JourneyStepKind.quest);
      expect(journeyStepKindOf(_choice({'travelPlaceId': '3200'})),
          JourneyStepKind.travel);
      expect(
          journeyStepKindOf(_choice({'healAmount': 10})), JourneyStepKind.rest);
      // Losing health is no rest.
      expect(journeyStepKindOf(_choice({'healAmount': -10})),
          JourneyStepKind.road);
    });

    test('danger shows before what a place offers', () {
      expect(
          journeyStepKindOf(
              _choice({'triggerEnemyId': 'harbor_rat', 'unlockShopId': 's'})),
          JourneyStepKind.fight);
      expect(
          journeyStepKindOf(
              _choice({'checkAbility': 'charisma', 'unlockQuestId': 'q'})),
          JourneyStepKind.check);
      expect(
          journeyStepKindOf(
              _choice({'mainQuest': true, 'travelPlaceId': '3200'})),
          JourneyStepKind.mainQuest);
    });
  });

  group('layout', () {
    test('rows hold at most three steps, the fuller rows nearest', () {
      expect(journeyRowSizes(0), isEmpty);
      expect(journeyRowSizes(1), [1]);
      expect(journeyRowSizes(3), [3]);
      expect(journeyRowSizes(4), [2, 2]);
      expect(journeyRowSizes(5), [3, 2]);
      expect(journeyRowSizes(7), [3, 2, 2]);
      expect(journeyRowSizes(8), [3, 3, 2]);
      expect(journeyRowSizes(12), [3, 3, 3, 3]);
    });

    test('one slot per step, none on top of another, all on the map', () {
      for (var count = 1; count <= 16; count++) {
        final slots = journeySlots(count);
        expect(slots, hasLength(count), reason: '$count steps');
        expect(slots.toSet(), hasLength(count), reason: '$count steps');
        for (final slot in slots) {
          expect(slot.x, inInclusiveRange(0.08, 0.92));
        }
        // Steps in one row keep a clear gap between them.
        for (final a in slots) {
          for (final b in slots) {
            if (identical(a, b) || a.row != b.row) continue;
            expect((a.x - b.x).abs(), greaterThan(0.2),
                reason: '$count steps, row ${a.row}');
          }
        }
      }
    });

    test('a single step sits straight ahead', () {
      expect(journeySlots(1), [const JourneySlot(row: 0, x: 0.5)]);
    });

    test('a far row sits between the steps of the row before it', () {
      final slots = journeySlots(6);
      final near = [
        for (final s in slots)
          if (s.row == 0) s.x
      ];
      final far = [
        for (final s in slots)
          if (s.row == 1) s.x
      ];
      for (final x in far) {
        for (final y in near) {
          expect((x - y).abs(), greaterThan(0.1), reason: '$x over $y');
        }
      }
    });

    test('the choices keep their order, nearest row first', () {
      final slots = journeySlots(5);
      expect([for (final s in slots) s.row], [0, 0, 0, 1, 1]);
      expect(slots[0].x, lessThan(slots[1].x));
      expect(slots[1].x, lessThan(slots[2].x));
      expect(slots[3].x, lessThan(slots[4].x));
    });
  });

  test('every choice in the story finds a step kind and a slot', () {
    final story = json.decode(
            File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
        as Map<String, dynamic>;
    var biggest = 0;
    for (final raw in story.values) {
      final choices = ((raw as Map<String, dynamic>)['choices'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      if (choices.length > biggest) biggest = choices.length;
      for (final choice in choices) {
        journeyStepKindOf(StoryChoice.fromJson(choice));
      }
    }
    expect(journeySlots(biggest), hasLength(biggest));
  });

  group('the chapter behind the party', () {
    StoryNode node(String id, List<Map<String, dynamic>> choices) =>
        StoryNode.fromJson(id, {'description': id, 'choices': choices});
    final nodes = {
      '1900': node('1900', [
        {'text': 'To the harbour', 'next_id': '2001'},
      ]),
      '2001': node('2001', [
        {'text': 'Head toward the wharf', 'next_id': '2005'},
      ]),
      '2005': node('2005', [
        {'text': 'Disembark', 'next_id': '2015'},
        {
          'text': 'Sneak',
          'next_id': '2020',
          'checkAbility': 'dexterity',
          'failNextId': '2025'
        },
      ]),
      '2025': node('2025', [
        {'text': 'Visit the stalls', 'next_id': '2025'},
        {'text': 'Walk on', 'next_id': '2030'},
      ]),
    };

    test('reads back through the chapter, the latest scene first', () {
      final past = journeyChapterPast(
        history: ['1900', '2001', '2005', '2025', '2025'],
        currentNodeId: '2030',
        nodeFor: (id) => nodes[id],
      );
      expect([for (final s in past.steps) s.nodeId], ['2025', '2005', '2001']);
      // The way out of each, even through a failed roll.
      expect([for (final s in past.steps) s.wayTaken?.text],
          ['Walk on', 'Sneak', 'Head toward the wharf']);
      // Chapter 1's last scene is not part of chapter 2's road.
      expect(past.reachesStart, isTrue);
    });

    test('a scene with no choice leading on keeps no way taken', () {
      final past = journeyChapterPast(
        history: ['2001'],
        currentNodeId: '2999',
        nodeFor: (id) => nodes[id],
      );
      expect(past.steps.single.wayTaken, isNull);
    });

    test('a long chapter keeps only the latest scenes', () {
      final past = journeyChapterPast(
        history: [for (var i = 0; i < 60; i++) '${2100 + i}'],
        currentNodeId: '2200',
        nodeFor: (id) => null,
        limit: 10,
      );
      expect(past.steps, hasLength(10));
      expect(past.steps.first.nodeId, '2159');
      expect(past.reachesStart, isFalse);
    });
  });

  group('relief', () {
    test('heights stay between 0 and 1 and are the same every time', () {
      for (var i = 0; i < 400; i++) {
        final x = i * 37.3 - 3000, y = i * -21.7 + 900;
        final h = reliefHeight(x, y);
        expect(h, inInclusiveRange(0, 1));
        expect(reliefHeight(x, y), h);
      }
    });

    test('the land rises and falls gently', () {
      var steepest = 0.0;
      var low = 1.0, high = 0.0;
      for (var y = -600.0; y < 600; y += 7) {
        for (var x = -300.0; x < 300; x += 7) {
          final h = reliefHeight(x, y);
          low = h < low ? h : low;
          high = h > high ? h : high;
          final step = (reliefHeight(x + 2, y) - h).abs();
          steepest = step > steepest ? step : steepest;
        }
      }
      // Hills and hollows both, and no cliff between two close points.
      expect(high - low, greaterThan(0.4));
      expect(steepest, lessThan(0.05));
    });

    test('contours follow their level and join up', () {
      const area = Rect.fromLTWH(-200, -200, 400, 400);
      for (final level in reliefLevels) {
        final segments = reliefContour(
            area: area, level: level, height: reliefHeight, cell: 10);
        for (final (a, b) in segments) {
          for (final p in [a, b]) {
            expect(area.inflate(0.01).contains(p), isTrue);
            // A crossing sits on the level, give or take the grid.
            expect((reliefHeight(p.dx, p.dy) - level).abs(), lessThan(0.06));
          }
          // No segment jumps across the map.
          expect((a - b).distance, lessThan(10 * 1.5));
        }
      }
    });

    test('a peak is higher than the land around it', () {
      const area = Rect.fromLTWH(-1200, -1200, 2400, 2400);
      final peaks = reliefPeaks(area: area, height: reliefHeight);
      expect(peaks, isNotEmpty);
      for (final p in peaks) {
        final top = reliefHeight(p.dx, p.dy);
        expect(top, greaterThan(0.7));
        for (final d in [const Offset(30, 0), const Offset(0, -30)]) {
          expect(reliefHeight(p.dx + d.dx, p.dy + d.dy), lessThan(top));
        }
      }
    });
  });
}
