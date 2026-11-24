// The Tower's fight in ink, part 3 (v1.1006): the real app at 360 and 320
// (UX_SHOTS=<folder>): the door, Continue, Fight, Enter Battle, then the board
// before and after the first roll. Pictures only.
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
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    // Each picture decodes its own sprites (a cached future from another
    // test's clock would never run here).
    InkSprites.reset();
  });

  for (final width in [360.0, 320.0]) {
    testWidgets('the Tower fight in ink $width', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      Directory(shots!).createSync(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final run = towerStart(
          seed: 5,
          raceId: 'human',
          professionId: 'warrior',
          data: towerDataFromAssets());
      SharedPreferences.setMockInitialValues({
        towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 780);
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

      Future<void> shoot(String name) async {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      Future<void> tapKey(String k) async {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first);
        await settle(10);
      }

      await settle(10);
      await tapKey('menu_tower');
      await tapKey('tower_continue');
      await tapKey('tower_fight');
      await settle(12);
      await shoot('fight-0-setup-${width.toInt()}');
      final enter = find.text('Enter Battle');
      if (enter.evaluate().isNotEmpty) {
        await tester.ensureVisible(enter);
        await tester.pump();
        await tester.tap(enter);
        await settle(14);
      }
      await shoot('fight-1-board-${width.toInt()}');
      final roll = find.textContaining('Roll Dice');
      if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
        await settle(25);
      }
      await shoot('fight-2-rolled-${width.toInt()}');
    });
  }
}
