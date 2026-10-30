// "Qui combat ?" (v1.670): with three companions able to fight, the setup
// offers the pick; two at most go, a third can't be checked until one is
// freed, the pick fields exactly those, and "keep as my party" seats them.
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
        'recruitedAllies': [
          for (final id in ['vica', 'sable', 'maren'])
            {'companionId': id, 'currentHealth': 24}
        ],
        'activeAllyIds': ['vica', 'sable'],
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
}

void main() {
  testWidgets('the sheet offers the bench; two seats; keep seats the pick',
      (tester) async {
    await _enter(tester);
    final card = find.byKey(const Key('fight_pick_card'));
    await tester.scrollUntilVisible(card, 200,
        scrollable: find.byType(Scrollable).first);
    expect(card, findsOneWidget);
    CheckboxListTile box(String id) =>
        tester.widget(find.byKey(Key('fight_pick_$id')));
    // The seated two are checked; the third cannot be until one is freed.
    expect(box('vica').value, isTrue);
    expect(box('sable').value, isTrue);
    expect(box('maren').value, isFalse);
    expect(box('maren').onChanged, isNull);
    await tester.tap(find.byKey(const Key('fight_pick_sable')));
    await settle(tester);
    expect(box('sable').value, isFalse);
    await tester.tap(find.byKey(const Key('fight_pick_maren')));
    await settle(tester);
    expect(box('maren').value, isTrue);
    // Keep as my party: the session's seats follow the pick.
    await tester.tap(find.byKey(const Key('fight_pick_keep')));
    await settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(container.read(playerSessionProvider).activeAllyIds.toSet(),
        {'vica', 'maren'});
  });
}
