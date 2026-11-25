// The dice board in each state at 412 wide (UX_SHOTS=<folder> saves pictures):
// not rolled, rolling, rolled, picked, kept; no dark disc behind the die.
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
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/widgets/die_3d.dart' show DieBurstPainter;

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5,
    int? floor,
    int events = 0,
    double width = 412,
    double height = 860}) async {
  await tester.runAsync(loadAppFonts);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final data = towerDataFromAssets();
  var run = towerStart(
      seed: seed, raceId: 'human', professionId: 'warrior', data: data);
  if (floor != null) run = run.copyWith(floor: floor, events: events, crest: 0);
  SharedPreferences.setMockInitialValues({
    towerRunPrefsKey: jsonEncode(run.toJson()),
    'tutorial_enabled': false,
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
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

  Future<void> tapKey(String k) async {
    final f = find.byKey(Key(k));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await settle(10);
  }

  await settle(12);
  final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(
      () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
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
  return c;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  testWidgets('the dice board states', (tester) async {
    final key = GlobalKey();
    await _bootFight(tester, key, floor: 5);
    expect(tester.takeException(), isNull);

    Future<void> shot(String name) async {
      if (shots == null) return;
      Directory(shots).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/dice-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await tester.tap(find.byIcon(Icons.casino));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
      await shot('t${i.toString().padLeft(2, '0')}');
      // The landing burst is rings and sparks, never a filled disc.
      for (final burst in find.byKey(const ValueKey('die_burst')).evaluate()) {
        final painter = (burst.widget as CustomPaint).painter;
        expect(painter, isA<DieBurstPainter>());
        expect((painter! as DieBurstPainter).outline, isTrue);
      }
    }
    final tile = find.byWidgetPredicate((w) =>
        w.key is ValueKey &&
        '${(w.key as ValueKey).value}'.startsWith('die_tile_'));
    await tester.tap(tile.first);
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shot('picked');
    // No solid disc behind the die in any state: its burst is rings and sparks.
    expect(find.byKey(const ValueKey('die_burst')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // The state of the user's screenshot: floor 5, Overseer Renn, the dice rolled
  // and settled, one die tapped once (its target shown). No disc behind the die.
  testWidgets('a rolled die tapped once (Overseer Renn, floor 5)',
      (tester) async {
    final key = GlobalKey();
    await _bootFight(tester, key,
        seed: 2,
        floor: 5,
        height: double.tryParse(Platform.environment['SCREEN_H'] ?? '') ?? 860);
    expect(tester.takeException(), isNull);
    Future<void> shot(String name) async {
      if (shots == null) return;
      Directory(shots).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/dice-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await tester.tap(find.byIcon(Icons.casino));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shot('state-1-rolled');
    final tile = find.byWidgetPredicate((w) =>
        w.key is ValueKey &&
        '${(w.key as ValueKey).value}'.startsWith('die_tile_'));
    await tester.tap(tile.first);
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shot('state-2-tapped-once');
    // The plate under the dice is drawn larger from its foot: its dark archway
    // (a black ball behind the die on a short board) is cut off.
    expect(
        find.ancestor(
            of: find.byKey(const Key('fight_board_skin')),
            matching: find.byWidgetPredicate((w) =>
                w is Transform && w.transform.getMaxScaleOnAxis() > 1.3)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
