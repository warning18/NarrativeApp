// The fight's log in play mode (v1.685): no block above the Roll bar, one
// history icon at the top that opens the full log, and every status an icon
// tile on one row.
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
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart'
    show settle, gamedata, pumpUntil, shows, tapWhenEnabled;
import 'support/pump.dart';

Future<void> _enter(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'app_mode': 'inGame',
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
  testWidgets('no log block in play mode; the history icon opens it',
      (tester) async {
    await _enter(tester);
    expect(find.byKey(const Key('fight_log_button')), findsOneWidget);
    expect(find.byIcon(Icons.unfold_more), findsNothing);
    final tiles = find.byType(FightStatusTile);
    expect(tiles, findsWidgets);
    final tops = {
      for (final e in tiles.evaluate())
        tester.getTopLeft(find.byWidget(e.widget)).dy.round()
    };
    expect(tops, hasLength(1), reason: 'one row of tiles');

    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tester.tap(find.byKey(const Key('fight_log_button')));
    await settle(tester);
    expect(find.text('Battle log'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(find.byKey(const Key('fight_log_unread')), findsNothing);
  });
}
