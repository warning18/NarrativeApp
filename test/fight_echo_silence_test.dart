// An Echo first in line repeats last round's face under this round's rules
// (v1.182's dice rules): a Silence laid since blanks the skill it copies,
// and the copy is named once however many rounds it echoes.
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

/// [text] in the full log's sheet (the ticker under it shows the last two
/// lines again).
Finder _inLog(String text) => find.descendant(
    of: find.byType(BottomSheet), matching: find.textContaining(text));

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

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  testWidgets('an Echo plays under this round\'s Silence, named once',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // A one-face die: a strike with Echo, a Heavy Attack set on it.
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ..._gamedata('dice.json'),
        'echo_test_die': {
          'diceName': 'echo_test_die',
          'numberOfFaces': 1,
          'faces': [
            {
              'type': 'Attack',
              'value': 6,
              'element': 'None',
              'keywords': ['echo'],
            },
          ],
        },
      }),
    });
    // Room for the test font's wide chips once momentum is up, and for the
    // whole log at once.
    tester.view.physicalSize = const Size(600, 1600);
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
          'professionId': 'warrior',
          'ownedDiceIds': ['echo_test_die'],
          'equippedDiceId': 'echo_test_die',
          'diceSkillAssignments': {
            'echo_test_die': {'0': 'heavy_attack'},
          },
          'maxHealth': 400,
          'currentHealth': 400,
        })));
    // A thug that only ever silences the party, too sturdy to fall.
    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
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

    // Round 1: nothing to echo yet, so the face plays its Heavy Attack.
    // Rounds 2 and 3 are silenced: the echo of that Heavy Attack falls back
    // to the strike it was set on.
    for (var round = 1; round <= 3; round++) {
      await _tapWhenEnabled(tester, 'Roll Dice');
      await _pumpUntil(tester, () => _shows('Confirm'));
      await _tapWhenEnabled(tester, 'Confirm');
      await _pumpUntil(tester, () => _shows('land blank this round'));
      await _settle(tester);
    }

    // The whole log, a tap on its ticker away.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('You wind up and strike'), findsOneWidget);
    expect(_inLog('Attack (Echo)'), findsNWidgets(2));
    expect(_inLog('(Echo) (Echo)'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
