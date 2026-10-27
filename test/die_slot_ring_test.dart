// The loadout shows a die as a ring of slots, one per face, whatever its
// size: a d4 to a d20 fit a phone, no round slot over another, the first at the
// top, and the middle names the size.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/screens/skills/die_slot_ring.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Read the data once, outside any test's fake clock: the bundle keeps the
  // first read, and one begun inside a test never finishes for the next.
  setUpAll(() async {
    for (final schema in [diceSchema, skillsSchema, itemsSchema]) {
      await rootBundle.loadString(schema.assetPath);
    }
  });

  test('slots shrink as the die grows, and never touch', () {
    var last = double.infinity;
    for (final n in [4, 6, 8, 10, 12, 20]) {
      final side = ringSlotSide(n, 380);
      final radius = ringRadius(n, side);
      expect(side, lessThanOrEqualTo(last), reason: 'd$n');
      last = side;
      // Neighbours' centres are at least a slot and a gap apart.
      final apart = (ringSpot(0, n) - ringSpot(1, n)).distance * radius;
      expect(apart, greaterThanOrEqualTo(side + 5.9), reason: 'd$n');
      // The ring fits the width.
      expect(2 * radius + side, lessThanOrEqualTo(380.5), reason: 'd$n');
    }
    expect(ringSlotSide(6, 380), ringSlotMax);
    expect(ringSlotSide(12, 380), greaterThanOrEqualTo(ringSlotCompact));
    expect(ringSlotSide(20, 380), lessThan(ringSlotCompact));
    expect(ringSlotSide(20, 380), greaterThan(44));
  });

  // A d4 (stone), a d6 (starter), a d8 (flame), a d10 (storm), a d12
  // (tempest) and the d20 (gambler), on a phone.
  for (final (id, n) in [
    ('stone_die', 4),
    ('starter_die', 6),
    ('flame_die', 8),
    ('storm_die', 10),
    ('tempest_die', 12),
    ('gambler_die', 20),
  ]) {
    testWidgets('a d$n is a ring of $n slots ($id)', (tester) async {
      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflows.add(details.exceptionAsString());
        } else {
          previous?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = previous);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(412, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiceLoadoutScreen()),
      ));
      await _settle(tester);
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': [id],
            'equippedDiceId': id,
            'unlockedSkillIds': ['warrior_shield_bash'],
            'diceSkillAssignments': {
              id: {'0': 'warrior_shield_bash'},
            },
          })));
      await _settle(tester);

      expect(find.byKey(const Key('die_slot_ring')), findsOneWidget);
      final rects = [
        for (var i = 0; i < n; i++)
          tester.getRect(find.byKey(Key('face_slot_$i'))),
      ];
      expect(find.byKey(Key('face_slot_$n')), findsNothing);
      for (var i = 0; i < n; i++) {
        expect(rects[i].left, greaterThanOrEqualTo(0), reason: 'face $i');
        expect(rects[i].right, lessThanOrEqualTo(412), reason: 'face $i');
        // Round slots: their circles stay apart.
        for (var j = i + 1; j < n; j++) {
          expect((rects[i].center - rects[j].center).distance,
              greaterThanOrEqualTo(rects[i].width),
              reason: '$i and $j');
        }
      }
      // The first face at the top, the next to its right.
      expect(rects[0].top, lessThan(rects[1].top));
      expect(rects[1].center.dx, greaterThan(rects[0].center.dx));
      // The middle names the size and the faces with a skill.
      expect(
          find.descendant(
              of: find.byKey(const Key('die_ring_center')),
              matching: find.text('d$n')),
          findsOneWidget);
      expect(find.textContaining('/$n with a skill'), findsOneWidget);
      // A tap on the last slot turns the die to it.
      await tester.tap(find.byKey(Key('face_slot_${n - 1}')),
          warnIfMissed: false);
      await _settle(tester);
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  }
}
