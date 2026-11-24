// The Tower in ink, part 4 (v2.0.0): the spoils, the cards (boon or oath), the
// level up and the calling pick, the real screens at 360 and 320
// (UX_SHOTS=<folder>). Pictures only.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester, [int n = 14]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, String name, double width, Widget app,
      {required Map<String, Object> prefs,
      double height = 900,
      bool walk = false}) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(
        {...prefs, 'tutorial_enabled': false});
    final key = GlobalKey();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ProviderScope(overrides: [
          towerDataProvider.overrideWith((ref) async => towerDataFromAssets()),
        ], child: app)));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await shoot(tester, key, name);
    if (name.startsWith('calling')) {
      final climb = find.byKey(const Key('tower_climb'));
      if (climb.evaluate().isNotEmpty) {
        await tester.ensureVisible(climb);
        await tester.pump();
        await tester.tap(climb);
        await settle(tester, 10);
        await shoot(tester, key, '$name-pick');
      }
    }
    if (walk) {
      // the level up first (a pick is owed): back out of it to the spoils,
      // then Take to the cards.
      final lvl = find.byType(LevelUpScreen);
      if (lvl.evaluate().isNotEmpty) {
        Navigator.of(tester.element(lvl)).pop();
        await settle(tester, 8);
      }
      await shoot(tester, key, '$name-spoils');
      final take = find.byKey(const Key('loot_sheet_take'));
      if (take.evaluate().isNotEmpty) {
        await tester.ensureVisible(take);
        await tester.pump();
        await tester.tap(take);
        await settle(tester, 8);
        await shoot(tester, key, '$name-cards');
      }
    }
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('the Tower in ink: the end of a floor', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final data = towerDataFromAssets();
    TowerRun won(int floor) {
      final start = towerStart(
              seed: 5, raceId: 'human', professionId: 'warrior', data: data)
          .copyWith(floor: floor);
      final run = start.copyWith(health: towerHeroOf(start, data).maxHealth);
      return towerAfterFight(run, data, won: true, healthLeft: run.health);
    }

    for (final width in [360.0, 320.0]) {
      final w = width.toInt();
      Future<void> floor(String name, TowerRun r) => show(tester, '$name-$w',
          width, const MaterialApp(home: TowerFloorScreen()),
          prefs: {towerRunPrefsKey: jsonEncode(r.toJson())},
          height: 1000,
          walk: true);
      await floor('levelup', won(3));
      await show(tester, 'calling-$w', width,
          const MaterialApp(home: TowerStartScreen()),
          prefs: const {}, height: 900);
    }
  });
}
