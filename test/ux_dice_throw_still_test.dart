// v2.2 (UX-2): the dice board throws the dice (dice_throw.dart): a die is off
// its seat during the roll and on it after; with reduced motion it is on its
// seat at once and never in flight.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
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

import 'skill_fight_harness.dart'
    show gamedata, pumpUntil, settle, shows, tapWhenEnabled;
import 'support/pump.dart';

Future<void> _enter(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    // The dice thrown at 4x: the tests wait a quarter of the throw (the
    // default speed is proven by dice_speed_test).
    'combat_dice_speed': 'quad',
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'board_die': {
        'diceName': 'board_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 4,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, const Size(412, 860));
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
        'ownedDiceIds': ['board_die'],
        'equippedDiceId': 'board_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
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
  await pumpUntil(tester, () => shows('Roll Dice'));
}

void main() {
  testWidgets('reduced motion: no flight, the die is on its seat',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _enter(tester);
    await tapWhenEnabled(tester, 'Roll Dice');
    final tile = find.byKey(const ValueKey('die_tile_player'));
    await pumpUntil(tester, () => shows('Confirm'));
    await settle(tester);
    final rest = tester.getCenter(tile);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getCenter(tile), rest);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
