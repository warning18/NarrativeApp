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

Future<void> _enter(WidgetTester tester) async {
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

Finder _keyStarting(String prefix) =>
    find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'$prefix"));

void main() {
  testWidgets('slots, pop-in, pick, keep and put back', (tester) async {
    await _enter(tester);
    // Three equal slots a side; one fighter a side leaves two empty each.
    expect(find.byKey(const Key('fight_empty_slot')), findsNWidgets(4));
    final party = tester.getSize(find.byKey(const Key('party_slot_player')));
    final enemy = tester.getSize(_keyStarting('enemy_slot_'));
    expect(party, enemy);
    expect(party.height, 72);

    // An effect icon (the warrior's Fury) opens its pop-in; a tap closes it.
    final fury = _keyStarting('fight_effect_fury_');
    expect(fury, findsOneWidget);
    await tester.tap(fury);
    await settle(tester);
    expect(find.byKey(const Key('fight_effect_popin')), findsOneWidget);
    expect(find.textContaining('heavy blow'), findsOneWidget);
    await tester.tapAt(const Offset(5, 500));
    await settle(tester);
    expect(find.byKey(const Key('fight_effect_popin')), findsNothing);

    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await settle(tester);
    expect(find.byKey(const ValueKey('die_tile_player')), findsOneWidget);
    expect(find.byKey(const Key('fight_aim_line')), findsNothing);

    // A tap picks the die: a ring, and the line to its target.
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    expect(find.byKey(const Key('die_picked_player')), findsOneWidget);
    expect(find.byKey(const Key('fight_aim_line')), findsOneWidget);
    expect(find.byKey(const ValueKey('kept_die_player')), findsNothing);

    // The second keeps it: gone from the board, small in the kept row.
    await tester.tap(find.byKey(const ValueKey('die_tile_player')));
    await settle(tester);
    expect(find.byKey(const ValueKey('die_tile_player')), findsNothing);
    expect(find.byKey(const ValueKey('kept_die_player')), findsOneWidget);
    expect(find.byKey(const Key('fight_aim_line')), findsNothing);

    // A double tap before any new roll puts it back on the board.
    final kept = find.byKey(const ValueKey('kept_die_player'));
    await tester.tap(kept);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(kept);
    await settle(tester);
    expect(find.byKey(const ValueKey('die_tile_player')), findsOneWidget);
    expect(find.byKey(const ValueKey('kept_die_player')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
