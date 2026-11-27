// PICTURES (UX_SHOTS=<folder>): the Stats and Dice bookmarks with their extras.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start = towerStart(
      seed: 5,
      raceId: 'human',
      professionId: 'warrior',
      data: data,
      rules: towerSurvivalRules);
  final run = start.copyWith(floor: 7, taken: {
    1: const TowerReward(TowerRewardKind.gear, id: 'sword_001'),
    5: const TowerReward(TowerRewardKind.die, id: 'flame_die'),
  }, levelUps: {
    2: const [TowerReward(TowerRewardKind.skill, id: 'fireball')],
  });

  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('bookmark extras pictures', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'tower_run_v1': jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    usePhone(tester, const Size(412, 900));
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: key,
            child: const MaterialApp(
                debugShowCheckedModeBanner: false, home: TowerFloorScreen()))));
    Future<void> settle([int n = 10]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await settle(30);
    await tester.tap(find.byKey(const Key('tower_bookmark_stats')));
    await settle();
    await shot('extras-stats');
    await tester.tap(find.byKey(const Key('tower_bookmark_dice')));
    await settle();
    await tester.tap(find.byKey(const Key('tower_die_flame_die')));
    await settle(4);
    await shot('extras-dice');
  });
}
