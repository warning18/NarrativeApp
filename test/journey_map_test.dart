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

  group('focus frame', () {
    const frame = Rect.fromLTWH(0, 0, 1000, 800);

    test('close ways show a corner of the city, close up', () {
      final focus = journeyFocusFrame(
          frame, [const Offset(300, 300), const Offset(380, 340)]);
      expect(focus.width, lessThan(frame.width * 0.7));
      expect(focus.height, lessThan(frame.height * 0.7));
      expect(focus.contains(const Offset(300, 300)), isTrue);
      expect(focus.contains(const Offset(380, 340)), isTrue);
    });

    test('never smaller than half the frame, never outside it', () {
      final focus = journeyFocusFrame(frame, [const Offset(10, 790)]);
      expect(focus.width, greaterThanOrEqualTo(frame.width * 0.5));
      expect(focus.height, greaterThanOrEqualTo(frame.height * 0.5));
      expect(frame.contains(focus.topLeft), isTrue);
      expect(focus.right, lessThanOrEqualTo(frame.right));
      expect(focus.bottom, lessThanOrEqualTo(frame.bottom));
    });

    test('ways across the city show all of it; none shows the frame', () {
      final wide = journeyFocusFrame(
          frame, [const Offset(50, 60), const Offset(950, 740)]);
      expect(wide, frame);
      expect(journeyFocusFrame(frame, const []), frame);
    });
  });
}
