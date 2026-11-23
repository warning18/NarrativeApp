// The hero's step on the Tower's rail (UX_SHOTS=<folder>): frames of the head
// walking up one notch after a won fight, and up the stair's arrow after a
// won shortcut, on the real floor screen at 360 px and 412 px. Drawn only
// with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'dart:convert';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/pump.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/root/fl/sdk/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  TowerRun base(int seed, int floor) => TowerRun(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        health: 40,
        events: 1,
      );
  // The picks a run owes are taken, so no Level Up covers the screen.
  TowerRun settled(TowerRun r) {
    for (var g = 0; g < 64 && towerPendingPicks(r) > 0; g++) {
      final taken = towerTakeStatPick(r, data, 0);
      if (identical(taken, r)) break;
      r = taken;
    }
    return r;
  }

  (int, int) shortcutFloor() {
    for (var seed = 1; seed < 400; seed++) {
      for (var floor = 3; floor < 27; floor++) {
        if (towerEventKindOf(base(seed, floor)) == TowerEventKind.shortcut) {
          return (seed, floor);
        }
      }
    }
    throw StateError('none');
  }

  testWidgets('the step', skip: shots == null, (tester) async {
    await tester.runAsync(_loadFonts);
    final key = GlobalKey();
    Future<void> shot(String name) async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name.png').writeAsBytesSync(bytes);
    }

    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final width in [360.0, 412.0]) {
      for (final (name, taken) in [('step', false), ('stair', true)]) {
        final (seed, floor) = taken ? shortcutFloor() : (1, 11);
        var run = base(seed, floor);
        if (taken) run = run.copyWith(shortcut: true);
        run = settled(run);
        SharedPreferences.setMockInitialValues({
          'tower_run_v1': jsonEncode(run.toJson()),
        });
        usePhone(tester, Size(width, 700));
        final container = ProviderContainer(overrides: [
          towerDataProvider.overrideWith((ref) async => data),
        ]);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: const MaterialApp(home: TowerFloorScreen()),
          ),
        ));
        await settle();
        await shot('$name-${width.round()}-0');
        // The fight is won: the cards open and the head starts to climb.
        final won =
            settled(towerAfterFight(run, data, won: true, healthLeft: 30));
        await container.read(towerProvider.notifier).setRun(won);
        await tester.pump();
        var n = 1;
        for (final ms in [150, 250, 250, 250, 300]) {
          await tester.pump(Duration(milliseconds: ms));
          await shot('$name-${width.round()}-$n');
          n++;
        }
        await tester.pump(const Duration(seconds: 1));
      }
    }
  });
}
