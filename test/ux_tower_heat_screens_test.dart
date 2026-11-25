// Tower Heat on its screens (v2.9.1): the door's picker is hidden until
// Embers opens, picks a level and locks the next; the chip on a floor opens
// the curse list; the end screen reads the level, the level opened and Ash
// conquered. Pictures with UX_SHOTS=<folder> (360 and 412, EN and FR).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

TowerRun _run(int heat, {TowerStatus status = TowerStatus.climbing}) =>
    TowerRun(
        seed: 1,
        raceId: 'human',
        professionId: 'warrior',
        floor: status == TowerStatus.won ? 30 : 7,
        health: 40,
        heat: heat,
        status: status);

// A save with no Heat won reads its wins as won at the plain climb.
String _progress(int heatWon) => jsonEncode(TowerProgress(
        marks: 120,
        bestFloor: 14,
        runs: 9,
        wins: heatWon < 0 ? 0 : 3,
        heatWon: heatWon)
    .toJson());

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester t, Widget screen,
    {Map<String, Object> prefs = const {},
    Size size = const Size(400, 2400)}) async {
  SharedPreferences.setMockInitialValues(prefs);
  usePhone(t, size);
  await t.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
  await _settle(t);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('the picker is hidden until Embers opens', (t) async {
    await _open(t, const TowerStartScreen(), prefs: {
      towerMarksPrefsKey: _progress(-1),
    });
    expect(find.byKey(const Key('tower_heat_0')), findsNothing);
  });

  testWidgets('the picker picks a level and shows the next one locked',
      (t) async {
    await _open(t, const TowerStartScreen(),
        prefs: {towerMarksPrefsKey: _progress(1)});
    // Embers and Smoke open (heatOpen 2), Flame locked.
    for (final h in [0, 1, 2, 3]) {
      expect(find.byKey(Key('tower_heat_$h')), findsOneWidget, reason: '$h');
    }
    expect(find.byKey(const Key('tower_heat_4')), findsNothing);
    expect(find.text('Win the top at Smoke to open'), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_heat_1')));
    await t.pump();
    expect(find.text('Marks ×1.25'), findsWidgets);
  });

  testWidgets('the chip opens the curse list, the newest tagged', (t) async {
    await _open(t, const TowerFloorScreen(), prefs: {
      towerRunPrefsKey: jsonEncode(_run(2).toJson()),
    });
    expect(find.byKey(const Key('tower_heat_chip')), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_heat_chip')));
    await _settle(t);
    expect(find.text('Curses in force this climb'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('the end screen: the level, the level opened, Ash conquered',
      (t) async {
    await _open(
        t,
        TowerEndScreen(
            run: _run(3, status: TowerStatus.won),
            progress: const TowerProgress(heatWon: 3),
            heatBefore: 2));
    expect(find.text('Flame · marks ×1.75'), findsOneWidget);
    expect(find.text('Pyre is open'), findsOneWidget);
    await _open(
        t,
        TowerEndScreen(
            run: _run(3, status: TowerStatus.won),
            progress: const TowerProgress(heatWon: 3),
            heatBefore: 3));
    expect(find.text('Pyre is open'), findsNothing);
    await _open(
        t,
        TowerEndScreen(
            run: _run(5, status: TowerStatus.won),
            progress: const TowerProgress(heatWon: 5),
            heatBefore: 4));
    expect(find.text('Ash conquered'), findsOneWidget);
    await _open(
        t,
        TowerEndScreen(
            run: _run(0, status: TowerStatus.dead),
            progress: const TowerProgress()));
    expect(find.byKey(const Key('tower_end_heat')), findsNothing);
  });

  Future<void> shot(WidgetTester t, String name, double w, Widget screen,
      {Map<String, Object> prefs = const {}, double h = 900}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final key = GlobalKey();
    t.view.physicalSize = Size(w, h);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(RepaintBoundary(
        key: key, child: ProviderScope(child: MaterialApp(home: screen))));
    await _settle(t);
    expect(t.takeException(), isNull, reason: name);
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await r.toImage(pixelRatio: 2);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
  }

  testWidgets('Tower Heat pictures', skip: shots == null, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (c) async => 1);
    for (final w in [412.0, 360.0]) {
      final n = w.toInt();
      await shot(t, 'door-$n', w, const TowerStartScreen(),
          prefs: {towerMarksPrefsKey: _progress(2)}, h: 1500);
      await shot(t, 'floor-$n', w, const TowerFloorScreen(),
          prefs: {towerRunPrefsKey: jsonEncode(_run(3).toJson())}, h: 900);
      await shot(
          t,
          'end-$n',
          w,
          TowerEndScreen(
              run: _run(3, status: TowerStatus.won),
              progress: const TowerProgress(marks: 330, bestFloor: 30, heatWon: 3),
              heatBefore: 2));
      await shot(
          t,
          'ash-$n',
          w,
          TowerEndScreen(
              run: _run(5, status: TowerStatus.won),
              progress: const TowerProgress(marks: 330, bestFloor: 30, heatWon: 5),
              heatBefore: 4));
    }
  });
}
