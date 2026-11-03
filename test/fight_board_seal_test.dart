// The fight's slots, dice board and kept row (combat redesign A''): three
// equal slots a side, a head and icons for each fighter, a tap on a die to
// pick it (its line to the target shows) and a second to keep it, a double
// tap on the kept row to put it back, the keep final after a new roll, and
// the pop-in of an effect icon.
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
    show settle, gamedata, pumpUntil, shows, tapWhenEnabled;
import 'support/pump.dart';

Future<void> _enter(WidgetTester tester, {bool vica = false}) async {
  SharedPreferences.setMockInitialValues({
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
        if (vica) ...{
          'recruitedAllies': [
            {'companionId': 'vica', 'currentHealth': 24}
          ],
          'activeAllyIds': ['vica'],
        },
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
  testWidgets('a keep is final once a new roll is made', (tester) async {
    await _enter(tester, vica: true);
    await tapWhenEnabled(tester, 'Roll Dice (2×)');
    await pumpUntil(tester, () => shows('Confirm'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    expect(find.byKey(const ValueKey('kept_die_player')), findsOneWidget);

    // Reroll the other die: the keep is sealed (a padlock) and stays.
    await tapWhenEnabled(tester, 'Reroll (2)');
    await pumpUntil(tester, () => shows('Reroll (1)'));
    await settle(tester);
    final kept = find.byKey(const ValueKey('kept_die_player'));
    expect(kept, findsOneWidget);
    expect(find.byIcon(Icons.lock), findsWidgets);
    // A tap on it says why it stays; it does not come back.
    await tester.tap(kept);
    await settle(tester);
    expect(find.text('Locked for this round: a new roll has been made.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('kept_die_player')), findsOneWidget);
    expect(find.byKey(const ValueKey('die_tile_player')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
