// PICTURES (UX_SHOTS=<folder>): the clan offer with swipe to choose (v2.10.22):
// the middle card in front but none in hand, tap + Take, and a swipe up that
// takes a card at once. Frames every 40 ms for the GIFs.
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
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data);
  final gifts = start.copyWith(status: TowerStatus.choosing, offer: const [
    TowerReward(TowerRewardKind.skill, id: 'second_wind', clan: 'mire'),
    TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
    TowerReward(TowerRewardKind.skill, id: 'void_blast', clan: 'penitents'),
  ]);

  for (final mode in ['swipe', 'tap']) {
    testWidgets('clan offer, $mode', skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'tower_run_v1': jsonEncode(gifts.toJson()),
        'tutorial_enabled': false,
      });
      usePhone(tester, const Size(412, 900));
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
      for (var i = 0; i < 8; i++) {
        final level = find.byType(LevelUpScreen);
        if (level.evaluate().isNotEmpty) {
          Navigator.of(tester.element(level)).pop();
        }
        final take = find.byKey(const Key('loot_sheet_take'));
        if (take.evaluate().isNotEmpty) await tester.tap(take);
        await settle(5);
        if (find.byKey(const Key('tower_card_1')).evaluate().isNotEmpty) break;
      }
      final dir = '$shots/swipe-$mode';
      Directory(dir).createSync(recursive: true);
      var n = 0;
      Future<void> frame() async {
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/${(n++).toString().padLeft(3, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 5; i++) {
        await frame();
        await tester.pump(const Duration(milliseconds: 40));
      }
      if (mode == 'tap') {
        // Tap the left card, then Take.
        await tester.tap(find.byKey(const Key('tower_card_0')));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          await frame();
        }
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          await frame();
        }
        await tester.tap(find.byKey(const Key('tower_take')));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          await frame();
        }
      } else {
        // Swipe up the middle card.
        final g = await tester.startGesture(
            tester.getCenter(find.byKey(const Key('tower_card_1'))));
        for (var i = 0; i < 14; i++) {
          await g.moveBy(const Offset(0, -16));
          await tester.pump(const Duration(milliseconds: 30));
          await frame();
        }
        await g.up();
        for (var i = 0; i < 16; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          await frame();
        }
      }
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
