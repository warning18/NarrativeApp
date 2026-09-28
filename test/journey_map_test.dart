// The Journey tab's map: what each step shows and where the steps sit.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_map.dart';
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
}
