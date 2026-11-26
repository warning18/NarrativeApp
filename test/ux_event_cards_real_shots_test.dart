// PICTURES (UX_SHOTS=<folder>): the real Tower event cards at 412 and 360
// (each button with its own outcome under it) and the real d20 of a check
// (frames for a GIF, set UX_SCENE=check).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/screens/tower/tower_event_card.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart'
    show TowerNight;
import 'package:narrative_data_app/theme/stitched_ink.dart'
    show buildAppTheme, stitchedInkScheme;

import 'support/fonts.dart';

const _shortcut = TowerEventView(
    kind: TowerEventKind.shortcut,
    floor: 4,
    revisit: false,
    setbacksLeft: 2,
    skip: 2,
    landsOn: 7,
    elite: true,
    lossEndsRun: true);
const _parley = TowerEventView(
    kind: TowerEventKind.parley,
    floor: 4,
    revisit: false,
    setbacksLeft: 2,
    ability: 'charisma',
    dc: 12,
    modifier: 3,
    chance: 0.6,
    landsOn: 6,
    forgoes: ['spoils', 'card', 'heal']);
const _setback = TowerEventView(
    kind: TowerEventKind.test,
    floor: 4,
    revisit: false,
    setbacksLeft: 2,
    ability: 'strength',
    dc: 12,
    modifier: 3,
    chance: 0.6,
    fallTo: 3,
    gain: 1,
    picksBeforeCheck: 1);
const _bargain = TowerEventView(
    kind: TowerEventKind.bargain,
    floor: 4,
    revisit: false,
    setbacksLeft: 2,
    maxHealthCost: 6,
    stat: 'strength',
    points: 1);

TowerEventResult _result(bool pass) => TowerEventResult(
    kind: TowerEventKind.parley,
    roll: pass ? 14 : 6,
    total: pass ? 17 : 9,
    ability: 'charisma',
    modifier: 3,
    dc: 12,
    passed: pass,
    from: 4,
    to: pass ? 6 : 4);

Future<void> _shot(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _show(
    WidgetTester tester, GlobalKey key, double w, double h, Widget card) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
      home: RepaintBoundary(
        key: key,
        child: TowerNight(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(padding: const EdgeInsets.all(16), child: card),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final scene = Platform.environment['UX_SCENE'] ?? 'cards';

  testWidgets('event cards', skip: shots == null || scene != 'cards',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    for (final w in [412.0, 360.0]) {
      final n = w.toInt();
      final cards = <String, (TowerEventCard, double)>{
        'shortcut': (TowerEventCard(_shortcut, onShortcut: (_) {}), 440),
        'parley': (TowerEventCard(_parley, onParley: (_) {}), 500),
        'setback': (const TowerEventCard(_setback), 290),
        'bargain': (TowerEventCard(_bargain, onBargain: (_) {}), 440),
      };
      for (final e in cards.entries) {
        await _show(tester, key, w, e.value.$2, e.value.$1);
        await _shot(tester, key, '$shots/${e.key}-$n.png');
      }
    }
  });

  testWidgets('check frames', skip: shots == null || scene != 'check',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    for (final pass in [true, false]) {
      await _show(tester, key, 412, 270, TowerEventResultLine(_result(pass)));
      var n = 0;
      final dir = '$shots/${pass ? 'pass' : 'fail'}';
      for (var i = 0; i < 30; i++) {
        await _shot(
            tester, key, '$dir/f${(n++).toString().padLeft(2, '0')}.png');
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
