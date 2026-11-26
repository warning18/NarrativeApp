// PICTURES (UX_SHOTS=<folder>): the Tower fight as a whole phone screen at
// 412 x 915, header to the bottom buttons, mid-fight: the dice rolled and
// landed, the face row filled. A classic foe, a rival, a boss and an elite.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });
  tearDown(() => towerPanelLayout.value = null);

  for (final (name, shape, floor) in [
    ('classic', TowerPanelLayout.ordinary, 5),
    ('rival', TowerPanelLayout.rival, 1),
    ('boss', TowerPanelLayout.boss, 5),
    ('elite', TowerPanelLayout.elite, 1),
  ]) {
    testWidgets('fight full $name', skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      // No debug ribbon over the header's corner.
      WidgetsApp.debugAllowBannerOverride = false;
      towerPanelLayout.value = shape;
      final data = towerDataFromAssets();
      var run = towerStart(
          seed: 5, raceId: 'human', professionId: 'warrior', data: data);
      if (floor > 1) run = run.copyWith(floor: floor);
      SharedPreferences.setMockInitialValues({
        towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: ProviderScope(overrides: [
            fightRandomProvider.overrideWithValue(() => Random(1))
          ], child: const MyApp())));
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> tapKey(String k) async {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first);
        await settle(10);
      }

      await settle(12);
      final c =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() =>
          c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
      await settle(4);
      await tapKey('menu_tower');
      await tapKey('tower_continue');
      await tapKey('tower_fight');
      await settle(12);
      final enter = find.text('Enter Battle');
      if (enter.evaluate().isNotEmpty) {
        await tester.ensureVisible(enter);
        await tester.pump();
        await tester.tap(enter);
        await settle(14);
      }
      // Roll the dice and let them land: the face row fills.
      final roll = find.text('Roll Dice');
      if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
        await settle(40);
      }
      expect(tester.takeException(), isNull);
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/fight-$name-412x915.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
