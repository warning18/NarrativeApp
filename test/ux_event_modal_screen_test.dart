// The event modal on the floor screen (v2.10.44): a shortcut, a parley or a
// bargain is chosen in a sheet over the dimmed floor, a setback's check waits
// behind one button (Face it), the setback is announced by a line before its
// fight, and the floor rail stays on every one. With UX_SHOTS=<folder> it
// also saves the pictures.
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
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final shotKey = GlobalKey();
  final data = towerDataFromAssets();
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  /// A landing whose store is a bargain (a scan of seeds, as the store cards'
  /// test does).
  TowerRun bargainLanding() {
    for (var seed = 1; seed < 400; seed++) {
      for (var floor = 2; floor < 29; floor++) {
        if (floor % 5 == 0) continue;
        final start = towerStart(
                seed: seed,
                raceId: 'human',
                professionId: 'warrior',
                events: towerEventsLive,
                data: data)
            .copyWith(floor: floor);
        final run = start.copyWith(health: towerHeroOf(start, data).maxHealth);
        final landed = towerPick(
            towerAfterFight(run, data, won: true, healthLeft: run.health),
            data,
            null);
        if (towerStoreKindOf(landed) == TowerEventKind.bargain) return landed;
      }
    }
    throw StateError('no bargain landing');
  }

  /// The first floor, over the seeds, whose event is [kind].
  TowerRun floorOf(TowerEventKind kind) {
    if (kind == TowerEventKind.bargain) return bargainLanding();
    for (var seed = 1; seed < 400; seed++) {
      for (var floor = 2; floor < 28; floor++) {
        final run = towerStart(
                seed: seed,
                raceId: 'human',
                professionId: 'warrior',
                events: towerEventsLive,
                rules: 4,
                data: data)
            .copyWith(floor: floor);
        if (towerEventKindOf(run) == kind) {
          return run.copyWith(health: towerHeroOf(run, data).maxHealth);
        }
      }
    }
    throw StateError('no $kind floor');
  }

  Future<ProviderContainer> boot(
      WidgetTester tester, TowerRun run, double width, String lang) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': lang,
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 860);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: shotKey,
            child: const MaterialApp(
                debugShowCheckedModeBanner: false, home: TowerFloorScreen()))));
    await _settle(tester, 30);
    return ProviderScope.containerOf(
        tester.element(find.byType(TowerFloorScreen)));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (shots == null) return;
    await tester.runAsync(() async {
      final b =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final (kind, takeKey) in [
    (TowerEventKind.shortcut, 'tower_shortcut_take'),
    (TowerEventKind.parley, 'tower_parley_talk'),
    (TowerEventKind.bargain, 'tower_bargain_accept'),
  ]) {
    for (final (width, lang) in [(412.0, 'en'), (360.0, 'fr')]) {
      testWidgets('${kind.name}: a sheet on arrival ($width $lang)',
          (tester) async {
        final run = floorOf(kind);
        await boot(tester, run, width, lang);
        expect(find.byKey(const Key('tower_event_modal')), findsOneWidget);
        expect(find.byKey(Key(takeKey)), findsOneWidget);
        // The rail stays; the Fight button is not reachable under the sheet.
        expect(find.byKey(const Key('tower_fight')), findsNothing);
        expect(tester.takeException(), isNull);
        await shot(tester, 'modal-${kind.name}-$lang-${width.toInt()}');
      });
    }
  }

  testWidgets('a setback: a line before the fight, one button after it',
      (tester) async {
    final run = floorOf(TowerEventKind.test);
    final c = await boot(tester, run, 412, 'en');
    // Before the fight: the line, no sheet.
    expect(find.byKey(const Key('tower_event_recap')), findsOneWidget);
    expect(find.byKey(const Key('tower_event_modal')), findsNothing);
    await shot(tester, 'modal-setback-before');
    // The fight won and its tables taken: the check waits.
    var next = towerAfterFight(run, data, won: true, healthLeft: run.health);
    for (var i = 0; i < 6 && next.status == TowerStatus.choosing; i++) {
      if (next.checkPending) break;
      next = towerPick(next, data, next.offer.isEmpty ? null : 0);
    }
    expect(next.checkPending, isTrue);
    await c.read(towerProvider.notifier).setRun(next);
    await _settle(tester, 12);
    expect(find.byKey(const Key('tower_event_modal')), findsOneWidget);
    expect(find.byKey(const Key('tower_event_face')), findsOneWidget);
    await shot(tester, 'modal-setback-face');
    await tester.tap(find.byKey(const Key('tower_event_face')));
    await _settle(tester, 12);
    final after = c.read(towerProvider).value!.run!;
    expect(after.checkPending, isFalse);
    expect(find.byKey(const Key('tower_event_modal')), findsNothing);
    expect(find.byKey(const Key('tower_event_result')), findsOneWidget);
    await shot(tester, 'modal-setback-result');
  });
}
