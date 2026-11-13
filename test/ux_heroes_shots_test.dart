// The real fight screen with each hero figure (UX_SHOTS=<folder>), light and
// dark. Drawn only with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

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
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

import 'package:narrative_data_app/widgets/fight_sprites.dart';
import 'support/fonts.dart';
import 'skill_fight_harness.dart' show gamedata, settle, shows;
import 'support/pump.dart';

bool _dark = false;
final _boundary = GlobalKey();
final _rounds = <int>[];
Future<void> _enter(WidgetTester tester,
    {List<SideLayer>? land,
    double w = 412,
    String id = 'slum_thug',
    String race = 'human',
    String calling = 'warrior',
    List<String> more = const []}) async {
  SharedPreferences.setMockInitialValues({
    // The dice thrown at 4x: the tests wait a quarter of the throw (the
    // default speed is proven by dice_speed_test).
    'combat_dice_speed': 'quad',
    if (_dark) 'app_theme_mode': 'dark',
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
  usePhone(tester, Size(w, 860));
  await tester.pumpWidget(RepaintBoundary(
      key: _boundary,
      child: ProviderScope(
          overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
          child: const MyApp())));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': race,
        'professionId': calling,
        'ownedDiceIds': ['board_die'],
        'equippedDiceId': 'board_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  final thug = {
    ...gamedata('enemies.json')[id] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: id,
                landLayers: land,
                enemy: thug,
                onRound: _rounds.add,
                additionalEnemyIds: more,
                additionalEnemies: {
                  for (final m in more)
                    m: {
                      ...gamedata('enemies.json')[m] as Map<String, dynamic>,
                      'maxHealth': 900,
                      'skillMoves': <dynamic>[]
                    }
                },
                modifiers: const EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  Future<void> until(bool Function() f, [int n = 150]) async {
    for (var i = 0; i < n && !f(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await until(() => shows('Enter Battle'));
  for (var i = 0; i < 12; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _heroes = <(String, String)>[
  ('human', 'warrior'),
  ('human', 'mage'),
  ('human', 'rogue'),
  ('human', 'cleric'),
  ('human', 'ranger'),
  ('dwarf', 'warrior'),
  ('orc', 'warrior'),
  ('elf', 'mage'),
];

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(FightSpriteImages.reset);
  for (final (race, calling) in _heroes) {
    for (final dark in [false, true]) {
      testWidgets('$race $calling dark=$dark', skip: shots == null,
          (tester) async {
        _dark = dark;
        await loadAppFonts();
        await _enter(tester,
            id: 'brine_jack', race: race, calling: calling, w: 412);
        await tester.ensureVisible(find.text('Enter Battle'));
        await tester.pump();
        await tester.tap(find.text('Enter Battle'));
        for (var i = 0; i < 14; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 80)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        late List<int> bytes;
        await tester.runAsync(() async {
          final b = _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
        });
        Directory(shots!).createSync(recursive: true);
        File('$shots/hero-$race-$calling-${dark ? 'dark' : 'light'}.png')
            .writeAsBytesSync(bytes);
      });
    }
  }
}
