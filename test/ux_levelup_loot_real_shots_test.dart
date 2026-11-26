// PICTURES (UX_SHOTS=<folder>): the real Tower tables of rules 2 at 412 and
// 360: the Level Up (ribbon, the fan in the approved card styles, the radar
// beside the held card's words), the floor loot and its spoils summary.
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

  TowerRun table(TowerTableKind kind, List<TowerReward> offer) =>
      start.copyWith(
          status: TowerStatus.choosing, table: kind, floor: 6, offer: offer);

  final scenes = <String, TowerRun>{
    'levelup': table(TowerTableKind.levelUp, const [
      TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
      TowerReward(TowerRewardKind.skill, id: 'fireball'),
      TowerReward(TowerRewardKind.spell, id: 'spell_ember_wave'),
    ]),
    'loot': table(TowerTableKind.loot, const [
      TowerReward(TowerRewardKind.gear, id: 'armor_leather'),
      TowerReward(TowerRewardKind.bundle, id: 'p2a1'),
      TowerReward(TowerRewardKind.purse, amount: 2),
    ]),
  };

  for (final width in [412.0, 360.0]) {
    for (final e in scenes.entries) {
      testWidgets('${e.key} at ${width.toInt()}', skip: shots == null,
          (tester) async {
        await tester.runAsync(loadAppFonts);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('flutter_tts'), (call) async => 1);
        SharedPreferences.setMockInitialValues({
          'app_language': 'en',
          'tower_run_v1': jsonEncode(e.value.toJson()),
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

        Future<void> shot(String name) async {
          await tester.runAsync(() async {
            final b = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await b.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/$name-${width.toInt()}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }

        await settle(30);
        await tester.pump(const Duration(milliseconds: 400));
        await shot('${e.key}-start');
        await tester.tap(find.byKey(const Key('tower_card_1')));
        await settle(8);
        await shot('${e.key}-held');
        if (e.key == 'levelup') {
          // The clan gift in hand, with its banner as a bookmark.
          await tester.tap(find.byKey(const Key('tower_card_0')));
          await settle(8);
          await shot('levelup-clan-held');
        }
        if (e.key == 'loot') {
          await tester.tap(find.byKey(const Key('tower_take')));
          await settle(12);
          await shot('loot-spoils');
        }
      });
    }
  }
}
