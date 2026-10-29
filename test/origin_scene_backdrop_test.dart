// The pictures behind "A Life Before This One"'s memories (v1.560): each of
// the fourteen memories has a place, and every place draws at the phone's
// width without a hitch.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/origin_stories.dart';
import 'package:narrative_data_app/screens/origin_stories_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/origin_scene_backdrop.dart';
import 'support/fonts.dart';

void main() {
  final ids = <String>{
    for (final race in const ['human', 'elf', 'dwarf', 'orc', 'voidkin'])
      for (final profession in const [
        'warrior',
        'mage',
        'rogue',
        'cleric',
        'ranger'
      ])
        for (final m
            in originMemoriesFor(raceId: race, professionId: profession))
          m.id,
  };

  test('fourteen memories, fourteen places', () {
    expect(ids.length, 14);
    expect(originBackdrops.keys.toSet(), ids,
        reason: 'one row for each memory, none for a memory that is gone');
  });

  test('an unknown memory still gets a place', () {
    expect(originBackdropOf('no_such_memory').kind, 'house');
  });

  for (final id in ids) {
    testWidgets('$id draws at 320 and 390 px', (tester) async {
      for (final width in [320.0, 390.0]) {
        tester.view.physicalSize = Size(width, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: OriginSceneBackdrop(memoryId: id)),
        ));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(OriginSceneBackdrop), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$id at $width');
      }
    });
  }

  // Pictures for the PR (UX_SHOTS=<folder>): the fourteen places, and one page.
  testWidgets('pictures of the fourteen places and a page (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(loadAppFonts);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = buildAppTheme(const ColorScheme.dark());
    final sheet = GlobalKey();
    final order = ids.toList();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: const Color(0xFF17151B),
        body: RepaintBoundary(
          key: sheet,
          child: ColoredBox(
            color: const Color(0xFF17151B),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final id in order)
                SizedBox(
                  width: 292,
                  child: Column(children: [
                    SizedBox(
                        height: 150,
                        child: OriginSceneBackdrop(memoryId: id, height: 150)),
                    Text(id,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          sheet.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/life-scenes-places.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    // One page, as the player sees it.
    tester.view.physicalSize = const Size(390, 900);
    final page = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: RepaintBoundary(
          key: page,
          child: const OriginStoriesScreen(
              raceId: 'voidkin', professionId: 'ranger'),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          page.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/life-scenes-page.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
