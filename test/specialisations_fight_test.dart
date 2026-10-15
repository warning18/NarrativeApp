// The main clans' specialisations on the fight screen (specialisations.dart):
// a Berserker's Attack face is a Pain strike, and the life it costs is
// logged; the same warrior without the gift strikes plainly. One fight per
// test, as the other fight tests do.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart';

/// One round of a warrior holding [specIds], whose only face is an Attack,
/// against a sturdy thug; then the log.
Future<void> _playAttackRound(WidgetTester tester, List<String> specIds) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final dice = gamedata('dice.json');
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...dice,
      'spec_test_die': {
        'diceName': 'spec_test_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 4,
            'element': 'None',
          },
        ],
      },
    }),
  });
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: const MyApp()));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['spec_test_die'],
        'equippedDiceId': 'spec_test_die',
        'maxHealth': 400,
        'currentHealth': 400,
        'specIds': specIds,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(MaterialPageRoute<bool>(
      builder: (_) => FightScreen(
            enemyId: 'slum_thug',
            enemy: thug,
            modifiers: const EncounterModifiers(
                forcedCondition: BattlefieldCondition.highGround,
                forcedGoal: FightGoal.slay),
          )));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await tapWhenEnabled(tester, 'Roll Dice');
  await pumpUntil(tester, () => shows('Confirm'));
  await tapWhenEnabled(tester, 'Confirm');
  await pumpUntil(tester, () => shows('Round 2'));
  await settle(tester);
  await tester.tap(find.byIcon(Icons.unfold_more));
  await settle(tester);
}

void main() {
  testWidgets('a Berserker\'s Attack face is a Pain strike', (tester) async {
    await _playAttackRound(tester, ['berserker']);
    expect(inLog('Pain: '), findsWidgets);
  });
}
