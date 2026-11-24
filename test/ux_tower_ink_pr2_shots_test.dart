// The Tower in ink, second part (v1.1005): the climb's real screens, 360 and
// 320 wide (UX_SHOTS=<folder>): the floor (a fight floor, a warden, a boss),
// each event (setback, rival, shortcut, parley, stall, bargain) and the dice
// panel with its face strip. Pictures only.
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
import 'package:narrative_data_app/data/tower/tower_dice.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/tower/tower_dice_panel.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, String name, double width, Widget app,
      {Map<String, Object> prefs = const {},
      double height = 780,
      TowerData? data}) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(prefs);
    final key = GlobalKey();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ProviderScope(overrides: [
          if (data != null) towerDataProvider.overrideWith((ref) async => data),
        ], child: app)));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await shoot(tester, key, name);
    await tester.pumpWidget(const SizedBox());
  }

  List<Map<String, dynamic>> faces() => [
        for (var i = 1; i <= 6; i++)
          {'type': i.isEven ? 'Defend' : 'Attack', 'value': i},
      ];

  testWidgets('the Tower in ink: the climb', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});

    TowerRun runAt(int seed, int floor, {int events = 0}) => TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 41,
        events: events,
        status: TowerStatus.climbing);

    // The first seed whose floor (or landing) meets each kind of event.
    final peaceful = towerDataFromAssets();
    TowerRun landing(int seed, int floor) {
      final start = towerStart(
              seed: seed,
              raceId: 'human',
              professionId: 'warrior',
              events: towerPeacefulEvents,
              data: peaceful)
          .copyWith(floor: floor);
      final run =
          start.copyWith(health: towerHeroOf(start, peaceful).maxHealth);
      final won =
          towerAfterFight(run, peaceful, won: true, healthLeft: run.health);
      return towerPick(won, peaceful, null);
    }

    final found = <TowerEventKind, TowerRun>{};
    for (var seed = 1; seed < 300 && found.length < 6; seed++) {
      for (var f = 2; f < 29; f++) {
        for (final run in [
          towerStart(
                  seed: seed,
                  raceId: 'human',
                  professionId: 'warrior',
                  events: towerPeacefulEvents,
                  data: peaceful)
              .copyWith(floor: f, health: 41),
          landing(seed, f),
        ]) {
          final kind = towerEventOf(run, peaceful)?.kind;
          if (kind != null && !found.containsKey(kind)) found[kind] = run;
        }
      }
    }

    Map<String, Object> saved(TowerRun r) =>
        {towerRunPrefsKey: jsonEncode(r.toJson())};
    for (final width in [360.0, 320.0]) {
      final w = width.toInt();
      Future<void> floor(String name, TowerRun r) => show(tester, '$name-$w',
          width, const MaterialApp(home: TowerFloorScreen()),
          prefs: saved(r), height: 900, data: towerDataFromAssets());
      await floor('floor-fight', runAt(3, 7));
      await floor('floor-warden', runAt(3, 5));
      await floor('floor-boss', runAt(3, 10));
      for (final e in found.entries) {
        await floor('event-${e.key.name}', e.value);
      }
      await show(
          tester,
          'dice-$w',
          width,
          MaterialApp(
              home: TowerNight(
                  child: Scaffold(
                      body: SingleChildScrollView(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: TowerDicePanel(
                                dice: [
                                  TowerDieView(
                                      id: 'apprentice_die',
                                      faces: faces(),
                                      inPlay: true,
                                      resonates: false,
                                      isNew: false),
                                  TowerDieView(
                                      id: 'flame_die',
                                      faces: faces(),
                                      inPlay: false,
                                      resonates: true,
                                      isNew: true),
                                  TowerDieView(
                                      id: 'ward_die',
                                      faces: faces().sublist(0, 4),
                                      inPlay: false,
                                      resonates: false,
                                      isNew: false),
                                ],
                                onChoose: (_) {},
                                onSeen: (_) {},
                              )))))),
          height: 400);
    }
  });
}
