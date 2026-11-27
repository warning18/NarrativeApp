// PICTURES (UX_SHOTS=<folder>): the health numbers on the Tower fight bars,
// today / A inside the bar / B above it, in every panel layout.
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
import 'package:narrative_data_app/data/tower/tower_tables.dart'
    show towerEventsLive;
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart'
    show TowerHpNumbers, towerHpNumbers;
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5,
    int? floor,
    int events = 0,
    double width = 412,
    bool stopAtFloor = false,
    bool stopAtMenu = false,
    int settleSeconds = 0}) async {
  await tester.runAsync(loadAppFonts);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final data = towerDataFromAssets();
  var run = towerStart(
      seed: seed,
      raceId: 'human',
      professionId: Platform.environment['SHOT_JOB'] ?? 'warrior',
      data: data);
  if (floor != null) run = run.copyWith(floor: floor, events: events, crest: 0);
  SharedPreferences.setMockInitialValues({
    towerRunPrefsKey: jsonEncode(run.toJson()),
    'tutorial_enabled': false,
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 860);
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
  if (stopAtMenu) {
    await settle(settleSeconds * 10);
    return c;
  }
  await tapKey('tower_continue');
  if (stopAtFloor) return c;
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
  for (final (layout, floor, seed) in [
    ('classic', 3, 5),
    ('elite', 4, 3),
    ('boss', 5, 16),
    ('rival', 2, 1),
  ]) {
    for (final mode in TowerHpNumbers.values) {
      testWidgets('hp $layout ${mode.name}', skip: shots == null,
          (tester) async {
        towerHpNumbers = mode;
        addTearDown(() => towerHpNumbers = TowerHpNumbers.none);
        final key = GlobalKey();
        await _bootFight(tester, key,
            floor: floor, seed: seed, events: towerEventsLive);
        for (var i = 0; i < 20; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/hp-$layout-${mode.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
