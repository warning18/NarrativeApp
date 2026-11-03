// A clan die's asleep Resonance in the fight (v1.684): a grey mark on the
// hero's die (one fight per test file; the lit one is fight_resonance_mark_test).
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart'
    show settle, gamedata, pumpUntil, shows, tapWhenEnabled;
import 'support/pump.dart';

PoliticsState _politics(bool lit) {
  final data = ClanData.fromTables(
    factions: gamedata('factions.json'),
    subclans: gamedata('subclans.json'),
    relations: gamedata('relations.json'),
    titles: gamedata('titles.json'),
  );
  return setStandingValue(PoliticsState.empty, 'mire', lit ? 60 : -20, 'edit',
          data: data)
      .state
      .copyWith(swornFactionId: 'mire');
}

Future<void> _enter(WidgetTester tester, {required bool lit}) async {
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode(gamedata('dice.json')),
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
        'ownedDiceIds': ['court_die'],
        'equippedDiceId': 'court_die',
        'politics': _politics(lit).toJson(),
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
  testWidgets('an asleep Resonance shows grey', (tester) async {
    await _enter(tester, lit: false);
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    expect(find.byKey(const Key('die_resonance_asleep')), findsOneWidget);
    expect(find.byKey(const Key('die_resonance_lit')), findsNothing);
  });
}
