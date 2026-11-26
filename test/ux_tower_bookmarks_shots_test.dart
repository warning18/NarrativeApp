// PICTURES (UX_SHOTS=<folder>): the real bookmark views of the Tower floor at
// 412 and 360 (version A of each), over a mid-climb hero given gear, dice and
// nudges through the run's own cards.
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
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  final start = towerStart(
      seed: 5, raceId: 'human', professionId: 'warrior', data: data, rules: 2);
  // A climb on floor 7 with cards taken: gear, dice, skills that nudge.
  final run = start.copyWith(floor: 7, xp: {
    for (var f = 1; f < 7; f++) f: 2
  }, taken: {
    1: const TowerReward(TowerRewardKind.gear, id: 'sword_001'),
    2: const TowerReward(TowerRewardKind.gear, id: 'cloak_frostward'),
    3: const TowerReward(TowerRewardKind.gear, id: 'greaves_iron'),
    4: const TowerReward(TowerRewardKind.gear, id: 'boots_worn_leather'),
    5: const TowerReward(TowerRewardKind.die, id: 'flame_die'),
    6: const TowerReward(TowerRewardKind.die, id: 'frost_die'),
  }, levelUps: {
    2: const [TowerReward(TowerRewardKind.skill, id: 'fireball')],
    4: const [TowerReward(TowerRewardKind.skill, id: 'fireball')],
    6: const [TowerReward(TowerRewardKind.skill, id: 'shadow_step')],
  });

  for (final width in [412.0, 360.0]) {
    for (final which in ['closed', 'stats', 'gear', 'dice']) {
      testWidgets('bookmarks $which at ${width.toInt()}', skip: shots == null,
          (tester) async {
        await tester.runAsync(loadAppFonts);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('flutter_tts'), (call) async => 1);
        SharedPreferences.setMockInitialValues({
          'app_language': 'en',
          'tower_run_v1': jsonEncode(run.toJson()),
          'tutorial_enabled': false,
        });
        usePhone(tester, Size(width, width > 400 ? 900 : 800));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        final key = GlobalKey();
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: UniqueKey(),
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(container
                    .read(appPaletteProvider)
                    .schemeFor(Brightness.light)),
                home: const TowerFloorScreen()),
          ),
        ));
        Future<void> settle([int n = 8]) async {
          for (var i = 0; i < n; i++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 80)));
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle(30);
        if (which != 'closed') {
          await tester.tap(find.byKey(Key('tower_bookmark_$which')));
          await settle(10);
        }
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$which-${width.toInt()}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
