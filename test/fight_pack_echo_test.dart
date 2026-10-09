// An Echo in a pack fight (v1.182's dice rules): the face it copies is
// what plays, so a guard that echoes a strike is aimed like one, and the
// log speaks of a redirected blow only when its target really fell.
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
  testWidgets('an Echo that copies a strike is aimed like one', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // The player's one-face die strikes; every face of Vess's die is a
    // guard with Echo, so she plays the player's strike after them.
    final dice = _gamedata('dice.json');
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ...dice,
        'strike_test_die': {
          'diceName': 'strike_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Attack', 'value': 6, 'element': 'None'},
          ],
        },
        'vess_die': {
          ...dice['vess_die'] as Map<String, dynamic>,
          'faces': [
            for (var i = 0; i < 6; i++)
              {
                'type': 'Defend',
                'value': 5,
                'element': 'None',
                'keywords': ['echo'],
              },
          ],
        },
      }),
    });
    // Room for the test font's wide chips, and for the whole log at once.
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
          'ownedDiceIds': ['strike_test_die'],
          'equippedDiceId': 'strike_test_die',
          'maxHealth': 400,
          'currentHealth': 400,
          'recruitedAllies': [
            {'companionId': 'vess', 'currentHealth': 1 << 30},
          ],
          'activeAllyIds': ['vess'],
        })));
    // Two thugs, too sturdy to fall this round.
    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              additionalEnemyIds: const ['slum_thug'],
              additionalEnemies: {'slum_thug': thug},
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    await _tapWhenEnabled(tester, 'Roll Dice (2×)');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(tester, () => _shows('Round 2'));
    await _settle(tester);

    // The whole log, a tap on its ticker away: Vess's echoed strike landed
    // where she aimed it, and nobody was down to redirect it from.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('Vess: Attack (Echo)'), findsOneWidget);
    expect(_inLog('already down'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
