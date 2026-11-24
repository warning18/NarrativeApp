// Pictures only (UX_SHOTS=<folder>): the Tower fight's dice thrown, the real
// app at 360, a frame every 50 ms from the tap on Roll Dice to Confirm.
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
    InkSprites.reset();
  });

  testWidgets('the Tower fight, dice thrown', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    final dir = Directory('$shots/tower')..createSync(recursive: true);
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
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: const ProviderScope(child: MyApp())));

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
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/$name.png')
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
    final enter = find.text('Enter Battle');
    if (enter.evaluate().isNotEmpty) {
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
      await settle(14);
    }
    await shoot('f000');
    final roll = find.textContaining('Roll Dice');
    await tester.tap(roll.first);
    final times = <double>[];
    for (var i = 1; i < 120; i++) {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 50));
      times.add(sw.elapsedMicroseconds / 1000);
      await shoot('f${i.toString().padLeft(3, '0')}');
      if (find.textContaining('Confirm').evaluate().isNotEmpty && i > 8) {
        for (var k = 0; k < 6; k++) {
          await tester.pump(const Duration(milliseconds: 50));
          await shoot('f${(i + k + 1).toString().padLeft(3, '0')}');
        }
        break;
      }
    }
    File('${dir.path}/frames_in_order.txt').writeAsStringSync(times.map((t) => t.toStringAsFixed(1)).join(' '));
    times.sort();
    File('${dir.path}/frame_ms.txt').writeAsStringSync(
        'median ${times[times.length ~/ 2].toStringAsFixed(2)} ms, '
        'p95 ${times[(times.length * 0.95).floor()].toStringAsFixed(2)} ms, '
        'max ${times.last.toStringAsFixed(2)} ms over ${times.length} frames '
        '(build+layout+paint of the whole screen, no raster, this machine)\n');
    final dice = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('die_tile_'));
    File('${dir.path}/dice_count.txt')
        .writeAsStringSync('${dice.evaluate().length}\n');
  });
}
