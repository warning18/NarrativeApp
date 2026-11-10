// A party of three d20 heroes (two companions with a d20) at 320 px: the solids
// are capped so their tiles stand apart inside the board (v1.903).
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

import 'skill_fight_harness.dart' show gamedata, pumpUntil, settle, shows;
import 'support/pump.dart';

Future<void> _enter(
    WidgetTester tester, double width, GlobalKey boundary) async {
  final dice = gamedata('dice.json');
  Map<String, dynamic> twenty(String id) => {
        'diceName': id,
        'numberOfFaces': 20,
        'faces': [
          for (var i = 0; i < 20; i++)
            {
              'faceName': 'Face $i',
              'type': i % 4 == 0 ? 'Defend' : (i % 4 == 1 ? 'Heal' : 'Attack'),
              'value': 1 + i % 9,
              'element': 'None'
            },
        ],
      };
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...dice,
      'holy_die': twenty('holy_die'),
      'shadow_die': twenty('shadow_die'),
    }),
  });
  usePhone(tester, Size(width, 1300));
  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: RepaintBoundary(key: boundary, child: const MyApp())));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['gambler_die'],
        'equippedDiceId': 'gambler_die',
        'maxHealth': 400,
        'currentHealth': 400,
        'recruitedAllies': [
          {'companionId': 'maren', 'currentHealth': 24},
          {'companionId': 'sable', 'currentHealth': 24}
        ],
        'activeAllyIds': ['maren', 'sable'],
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
  await tester.ensureVisible(find.text('Enter Battle'));
  await tester.pump();
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await pumpUntil(tester, () => shows('Roll Dice'));
}

void main() {
  testWidgets('three d20 heroes at 320 px stand apart inside the board',
      (tester) async {
    final boundary = GlobalKey();
    await _enter(tester, 320, boundary);
    bool rollEnabled() {
      final b = find.ancestor(
          of: find.textContaining('Roll Dice'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      return b.evaluate().isNotEmpty &&
          (b.evaluate().first.widget as ButtonStyleButton).enabled;
    }

    await pumpUntil(tester, rollEnabled);
    await tester.tap(find.textContaining('Roll Dice').first);
    await pumpUntil(tester, () => shows('Confirm'));
    await tester.pump(const Duration(seconds: 2));
    final tiles =
        find.byWidgetPredicate((x) => '${x.key}'.startsWith("[<'die_tile_"));
    final rects = [
      for (final e in tiles.evaluate()) tester.getRect(find.byWidget(e.widget))
    ];
    expect(rects.length, 3);
    for (final r in rects) {
      // The solid takes at most 38% of the board's width, so its tile is
      // narrower than the lone d20's 111 px.
      expect(r.width, lessThanOrEqualTo(100));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    }
    expect(tester.takeException(), isNull);
  });
}
