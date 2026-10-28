// One picture of the fight as it is today, for the fixed-size review
// (docs/proposals/fight-fixed-sizes.md). Drawn only with UX_SHOTS (a folder)
// and FIGHT_OUT (the file's name); the party and the foes come from
// FIGHT_ALLIES (0 to 3), FIGHT_ENEMIES (ids, comma separated) and FIGHT_SIZE
// ("412x860"). One scene per run: the gamedata's asset loads do not come back
// in a second test's clock (see fight_hero_harness.dart).
//   UX_SHOTS=/tmp/shots FIGHT_OUT=fight-1 FIGHT_ALLIES=3 \
//     FIGHT_ENEMIES=white_soldier flutter test test/ux_fight_size_shots_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'fight_hero_harness.dart' show saveFightShot;
import 'skill_fight_harness.dart' show settle, gamedata, pumpUntil, shows;

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final out = Platform.environment['FIGHT_OUT'];
  if (shots == null || out == null) {
    test('the fight picture is drawn only with UX_SHOTS and FIGHT_OUT', () {});
    return;
  }

  testWidgets('the fight, $out', (tester) async {
    await tester.runAsync(_loadFonts);
    final allies = int.parse(Platform.environment['FIGHT_ALLIES'] ?? '0');
    final enemyIds =
        (Platform.environment['FIGHT_ENEMIES'] ?? 'white_soldier').split(',');
    final dims = (Platform.environment['FIGHT_SIZE'] ?? '412x860').split('x');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
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
    tester.view.physicalSize =
        Size(double.parse(dims[0]), double.parse(dims[1]));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    const crew = ['kelda', 'sable', 'maren'];
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 8,
          'ownedDiceIds': ['info_die'],
          'equippedDiceId': 'info_die',
          'maxHealth': 400,
          'currentHealth': 400,
          'perception': 8,
          'builtHouseIds': ['keldas_hall', 'barracks_annex'],
          'activeAllyIds': crew.take(allies).toList(),
          'recruitedAllies': [
            for (final id in crew.take(allies))
              {'companionId': id, 'currentHealth': 1 << 30},
          ],
        })));
    final enemies = gamedata('enemies.json');
    Map<String, dynamic> tough(String id) => {
          ...enemies[id] as Map<String, dynamic>,
          'maxHealth': 900,
          'guile': 0,
          'skillMoves': <dynamic>[],
        };
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: enemyIds.first,
                  enemy: tough(enemyIds.first),
                  additionalEnemyIds: enemyIds.skip(1).toList(),
                  additionalEnemies: {
                    for (final id in enemyIds.skip(1)) id: tough(id),
                  },
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay),
                )));
    await settle(tester);
    await pumpUntil(tester, () => shows('Enter Battle'));
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.pump();
    await tester.tap(find.text('Enter Battle'));
    await settle(tester);
    await pumpUntil(tester, () => shows('Roll Dice'));
    await saveFightShot(tester, out);
  });
}
