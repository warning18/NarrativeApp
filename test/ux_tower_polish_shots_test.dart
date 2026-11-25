// PICTURES (UX_SHOTS=<folder>): the Tower polish on the real app at 360: the
// start screen's zone panes in ink, the fight without the 30-rung strip (the
// dice board keeps the room), the rail given up for a stall, and the numerals
// in the prose face. Run on main for "before" and on the branch for "after".
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
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final scene in ['start', 'fight', 'fightroll', 'stall']) {
    testWidgets('tower polish: $scene', skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final data = towerDataFromAssets();
      var run = towerStart(
          seed: 5, raceId: 'human', professionId: 'warrior', data: data);
      if (scene == 'stall') {
        // Landed on floor 11 with the store of floor 10 open.
        run = run.copyWith(floor: 11, store: 10, events: towerPeacefulEvents);
      }
      SharedPreferences.setMockInitialValues({
        if (scene != 'start') towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: const ProviderScope(child: MyApp())));
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
      if (scene != 'start') await tapKey('tower_continue');
      if (scene == 'fight' || scene == 'fightroll') {
        await tapKey('tower_fight');
        await settle(12);
        final enter = find.text('Enter Battle');
        if (enter.evaluate().isNotEmpty) {
          await tester.ensureVisible(enter);
          await tester.pump();
          await tester.tap(enter);
          await settle(14);
        }
        if (scene == 'fightroll') {
          await tester.tap(find.textContaining('Roll Dice').first);
          for (var i = 0; i < 36; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
      }
      if (scene == 'stall') await settle(20);
      expect(tester.takeException(), isNull);
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/$scene.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
