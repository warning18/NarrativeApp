// PICTURES (UX_SHOTS=<folder>): the real Level Up screen of the Tower at 412
// and 360 wide, in both versions of the stats area: the list (bars) and the
// radar, with a pick chosen and not. Real numbers: the Tower hero's session
// and statPickPreviewOf, not typed in.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/tower_level_up_session.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/widgets/level_up_art.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() => levelUpStatsView.value = LevelUpStatsView.list);

  // One plate each: the levels 3, 4 and 5 of a warrior.
  for (final level in [3, 4, 5]) {
    testWidgets('level up plate of level $level', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(412, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = towerDataFromAssets();
      final paths = trainingPathsFrom(jsonDecode(
              File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);
      var run = towerStart(
          seed: 5, raceId: 'human', professionId: 'warrior', data: data);
      // Floor after floor (the cards taken, the calling's picks with them)
      // until the next win gives the level asked for.
      for (var n = 0; n < 40; n++) {
        final won =
            towerAfterFight(run, data, won: true, healthLeft: run.health);
        if (towerLevelAfter(won.heightCleared) >= level) {
          run = won;
          break;
        }
        run = towerPick(won, data, null);
      }
      final levelUp = TowerLevelUpSession(run, data);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
              key: key,
              child: levelUp.wrap(const LevelUpScreen(
                  doneLabelKey: 'tower_continue', tower: true))),
        ),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.tap(find.byKey(const Key('stat_pick_offer_1')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(shots!).createSync(recursive: true);
        File('$shots/level-up-plate-level-$level.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }

  for (final (race, calling, wins) in [
    ('human', 'warrior', 3),
    ('elf', 'mage', 4),
  ]) {
    for (final view in LevelUpStatsView.values) {
      for (final w in [412.0, 360.0]) {
        testWidgets('level up $calling ${view.name} $w', skip: shots == null,
            (tester) async {
          await tester.runAsync(loadAppFonts);
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = Size(w, 1500);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          levelUpStatsView.value = view;
          final data = towerDataFromAssets();
          final paths = trainingPathsFrom(jsonDecode(
              File('assets/gamedata/training_paths.json')
                  .readAsStringSync()) as Map<String, dynamic>);
          var run = towerStart(
              seed: 5, raceId: race, professionId: calling, data: data);
          for (var i = 0; i < wins; i++) {
            run = towerAfterFight(run, data, won: true, healthLeft: run.health);
          }
          final levelUp = TowerLevelUpSession(run, data);
          final key = GlobalKey();
          await tester.pumpWidget(ProviderScope(
            overrides: [
              trainingPathsProvider.overrideWith((ref) async => paths)
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: RepaintBoundary(
                  key: key,
                  child: levelUp.wrap(const LevelUpScreen(
                      doneLabelKey: 'tower_continue', tower: true))),
            ),
          ));
          Future<void> settle() async {
            for (var i = 0; i < 10; i++) {
              await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 20)));
              await tester.pump(const Duration(milliseconds: 30));
            }
          }

          Future<void> shoot(String name) async {
            await tester.runAsync(() async {
              final render = key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 2);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              Directory(shots!).createSync(recursive: true);
              File('$shots/$name.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
            });
          }

          await settle();
          await tester.tap(find.byKey(const Key('stat_pick_offer_1')));
          await settle();
          await shoot('level-up-$calling-${view.name}-${w.toInt()}');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
