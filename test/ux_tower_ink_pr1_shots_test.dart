// The Tower in ink, first part (v1.1004): the real screens, 360 and 320 wide
// (UX_SHOTS=<folder>): the door (with a run to continue, and without), the
// marks, the end of a lost run and of a won one, and the Tower's button on the
// main menu. Pictures only.
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
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';

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
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, String name, double width, Widget app,
      {Map<String, Object> prefs = const {}, double height = 780}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final key = GlobalKey();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: ProviderScope(child: app)));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await shoot(tester, key, name);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('the Tower in ink: the first screens', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    const run = TowerRun(
        seed: 1,
        raceId: 'human',
        professionId: 'warrior',
        floor: 7,
        health: 41,
        status: TowerStatus.climbing);
    const lost = TowerRun(
        seed: 1,
        raceId: 'human',
        professionId: 'warrior',
        floor: 7,
        health: 0,
        status: TowerStatus.dead);
    const won = TowerRun(
        seed: 1,
        raceId: 'human',
        professionId: 'warrior',
        floor: 30,
        health: 20,
        status: TowerStatus.won);
    final progress = {
      towerMarksPrefsKey: jsonEncode(
          const TowerProgress(marks: 120, bestFloor: 14, runs: 9, wins: 3)
              .toJson()),
    };
    for (final width in [360.0, 320.0]) {
      final w = width.toInt();
      await show(tester, 'start-run-$w', width,
          const MaterialApp(home: TowerStartScreen()),
          prefs: {...progress, towerRunPrefsKey: jsonEncode(run.toJson())},
          height: 900);
      await show(tester, 'start-new-$w', width,
          const MaterialApp(home: TowerStartScreen()),
          prefs: progress, height: 900);
      await show(tester, 'marks-$w', width,
          const MaterialApp(home: TowerMarksScreen()),
          prefs: {
            towerMarksPrefsKey: jsonEncode(const TowerProgress(
                marks: 134,
                bestFloor: 14,
                runs: 9,
                wins: 3,
                unlocked: {'flame_die'}).toJson())
          },
          height: 1500);
      await show(
          tester,
          'end-lost-$w',
          width,
          const MaterialApp(
              home: TowerEndScreen(
                  run: lost,
                  progress: TowerProgress(marks: 134, bestFloor: 14))));
      await show(
          tester,
          'end-won-$w',
          width,
          const MaterialApp(
              home: TowerEndScreen(
                  run: won,
                  progress: TowerProgress(marks: 330, bestFloor: 30))));
    }
    await show(tester, 'menu-360', 360, const MyApp(), height: 900);
  });
}
