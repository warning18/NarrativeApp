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
      'heal_die': {
        'diceName': 'heal_die',
        'numberOfFaces': 1,
        'faces': [
          {'faceName': 'Mend', 'type': 'Heal', 'value': 6, 'element': 'None'},
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
        'ownedDiceIds': ['heal_die'],
        'equippedDiceId': 'heal_die',
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
  testWidgets('a heal die aims at the ally a tap on their slot picks',
      (tester) async {
    await _enter(tester, vica: true);
    await tapWhenEnabled(tester, 'Roll Dice (2×)');
    await pumpUntil(tester, () => shows('Confirm'));
    await settle(tester);
    // Pick the hero's heal die: a line to the member it will mend.
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    expect(find.byKey(const Key('fight_aim_line')), findsOneWidget);
    // A tap on Vica's slot aims the heal at her, and the pick stays.
    await tester.tap(find.byKey(const Key('party_slot_vica')));
    await settle(tester);
    expect(find.byKey(const Key('die_picked_player')), findsOneWidget);
    await tapWhenEnabled(tester, 'Confirm');
    await pumpUntil(tester, () => shows('mends Vica'));
    expect(find.textContaining('mends Vica', findRichText: true), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
