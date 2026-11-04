// Shared by the issue #694 tests (QA): a fight whose only face is given,
// against a thug, opened and entered. One fight per test file, as the
// other fight tests do.
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
import 'support/pump.dart';

/// Waits for the game data to load: every test here starts the app anew
/// (the harness's [settle] waits long only on a file's first call).
Future<void> loadApp(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens a fight of a [professionId] whose only face is [face] against a
/// thug of [enemyHealth], and enters it.
Future<ProviderContainer> openQa694Fight(
  WidgetTester tester, {
  String professionId = 'warrior',
  Map<String, dynamic> face = const {
    'faceName': 'Strike',
    'type': 'Attack',
    'value': 4,
    'element': 'None',
  },
  int enemyHealth = 900,
  Map<String, dynamic> session = const {},
  PlayerSessionNotifier Function()? notifier,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'qa694_die': {
        'diceName': 'qa694_die',
        'numberOfFaces': 1,
        'faces': [face],
      },
    }),
  });
  usePhone(tester, const Size(600, 1600));
  await tester.pumpWidget(ProviderScope(overrides: [
    fightRandomProvider.overrideWithValue(() => Random(7)),
    if (notifier != null)
      playerSessionProvider.overrideWith((ref) => notifier()),
  ], child: const MyApp()));
  await loadApp(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': professionId,
        'ownedDiceIds': ['qa694_die'],
        'equippedDiceId': 'qa694_die',
        'maxHealth': 400,
        'currentHealth': 400,
        ...session,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': enemyHealth,
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
  await loadApp(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  return container;
}

ButtonStyleButton? buttonLabelled(String label) {
  final found = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  return found.evaluate().isEmpty
      ? null
      : found.evaluate().first.widget as ButtonStyleButton;
}
