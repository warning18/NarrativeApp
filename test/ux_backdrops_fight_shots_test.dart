// UX picture tool (not a guard): the real fight screen (setup, then the
// battle) on a chosen stage, with the app's fonts, for the backdrops review.
// One fight per run (the suite keeps one fight per file):
//   UX_SHOTS=<folder> UX_TAG=after-dunes UX_STAGE=dunes [UX_NODE=2010] \
//     flutter test test/ux_backdrops_fight_shots_test.dart
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
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart' show settle, gamedata, pumpUntil, shows;
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _shot(WidgetTester tester, String dir, String name) async {
  await tester.runAsync(() async {
    RenderObject? node = tester.renderObject(find.byType(FightScreen));
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    final image = await (node! as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'fight';
  final stageName = Platform.environment['UX_STAGE'] ?? 'fields';
  final nodeId = (Platform.environment['UX_NODE'] ?? '').isEmpty
      ? null
      : Platform.environment['UX_NODE'];
  testWidgets('a real fight on $stageName', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'dark',
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
    usePhone(tester, const Size(412, 890));
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
        })));
    if (nodeId != null) {
      container.read(storyPlayProvider.notifier).jumpTo(nodeId);
      await settle(tester);
    }
    final enemy = {
      ...gamedata('enemies.json')['sore_loser'] as Map<String, dynamic>,
      'maxHealth': 900,
      'guile': 0,
      'skillMoves': <dynamic>[],
    };
    final stage = FightStage.values.firstWhere((s) => s.name == stageName);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'sore_loser',
                  enemy: enemy,
                  modifiers: EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay,
                      forcedStage: stage),
                )));
    await settle(tester);
    await pumpUntil(tester, () => shows('Enter Battle'));
    await _shot(tester, dir, '$tag-setup');
    await tester.tap(find.text('Enter Battle'));
    await settle(tester);
    await pumpUntil(tester, () => shows('Roll Dice'));
    await _shot(tester, dir, '$tag-battle');
  });
}
