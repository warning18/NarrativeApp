// Shared by the fight-hero tests (each in its own file: the gamedata's asset
// loads do not come back in a second test's clock): enters a fight on a
// phone of [size], and saves a screenshot with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

import 'skill_fight_harness.dart' show settle, gamedata, pumpUntil, shows;
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> enterFight(WidgetTester tester,
    {required Size size,
    int perception = 8,
    String enemyId = 'slum_thug'}) async {
  if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  SharedPreferences.setMockInitialValues({
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'info_die': {
        'diceName': 'info_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 10,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, size);
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
        'ownedDiceIds': ['info_die'],
        'equippedDiceId': 'info_die',
        'maxHealth': 400,
        'currentHealth': 400,
        'perception': perception,
      })));
  final thug = {
    ...gamedata('enemies.json')[enemyId] as Map<String, dynamic>,
    'maxHealth': 900,
    'guile': 0,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: enemyId,
                enemy: thug,
                modifiers: const EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  // On a small phone the button waits below the fold.
  await pumpUntil(tester, () => shows('Enter Battle'));
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await pumpUntil(tester, () => shows('Roll Dice'));
}

/// UX_SHOTS (a folder): saves the screen as it is.
Future<void> saveFightShot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    RenderObject? node = tester.renderObject(find.byType(FightScreen));
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    final image = await (node! as RenderRepaintBoundary).toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
