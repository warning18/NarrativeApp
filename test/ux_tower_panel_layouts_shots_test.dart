// PICTURES (UX_SHOTS=<folder>): the Tower fight's two fighter panels (the
// foe's and "You") in several layouts, on the real app at 412 wide:
// today, cut corners, a slanted gutter, offset with the foe breaking out of
// its frame, a burst edge (wardens and bosses: floor 5) and a brush-ink
// border. Names, HP, the Heat chip and the info buttons stay where they are.
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
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
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

  for (final (shape, floor, w) in [
    (TowerPanelLayout.ordinary, 1, 412.0),
    (TowerPanelLayout.elite, 1, 412.0),
    (TowerPanelLayout.bossTall, 5, 412.0),
    (TowerPanelLayout.bossFill, 5, 412.0),
    (TowerPanelLayout.bossSwap, 5, 412.0),
    (TowerPanelLayout.rivalPair, 1, 412.0),
    (TowerPanelLayout.rivalSlant, 1, 412.0),
    (TowerPanelLayout.rivalHead, 1, 412.0),
    (TowerPanelLayout.ordinary, 5, 412.0),
    (TowerPanelLayout.bossTall, 5, 360.0),
    (TowerPanelLayout.rivalSlant, 1, 360.0),
  ]) {
    testWidgets('panel layout ${shape.name} (floor $floor, $w)',
        skip: shots == null, (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
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
      tester.view.physicalSize = Size(w, 860);
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
      expect(tester.takeException(), isNull);
      Directory(shots!).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/layout-${shape.name}-f$floor-${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
