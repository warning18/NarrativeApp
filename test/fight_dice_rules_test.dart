// The dice's own rules on the fight screen (v1.182): a Luck nudge turns a
// landed die to its opposite face, and an enemy's Silence blanks the
// party's Skill faces for the round after.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

Future<void> _tapWhenEnabled(WidgetTester tester, String label) async {
  bool enabled() {
    final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    return button.evaluate().isNotEmpty &&
        (button.evaluate().first.widget as ButtonStyleButton).enabled;
  }

  await _pumpUntil(tester, enabled);
  expect(enabled(), isTrue, reason: '"$label" never became enabled');
  await tester.tap(find.text(label));
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a Luck nudge flips a die; a Silence blanks the next round',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'rogue',
          'ownedDiceIds': ['headsman_die'],
          'equippedDiceId': 'headsman_die',
          'gold': 100,
          // Two nudges (see nudgesForLuck).
          'luck': 7,
        })));
    // A thug that only ever silences the party, too sturdy to fall.
    final thug = {
      ..._enemy('slum_thug'),
      'maxHealth': 900,
      'skillMoves': [
        {'skillID': 'edict_of_silence', 'condition': 'Always', 'priority': 1},
      ],
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(find.text('Nudges 2'), findsOneWidget);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await tester.longPress(find.byKey(const ValueKey('die_tile_player')));
    await _settle(tester);
    expect(find.textContaining('Nudge to'), findsOneWidget);
    await tester.tap(find.textContaining('Nudge to'));
    await _pumpUntil(tester, () => _shows('Nudges 1'));
    expect(find.text('Nudges 1'), findsOneWidget);
    expect(_shows('Nudge:'), isTrue);

    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(tester, () => _shows('land blank this round'));
    expect(_shows('"Silence!"'), isTrue);
    expect(_shows('land blank this round'), isTrue);
    // The Silence shows over the round, next to the nudges left.
    expect(find.text('Silence'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
