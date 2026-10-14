// The hero in side view (side_sprite.dart): the ronin's frames load from
// assets/visuals/walker, walk, stand, and face either way; the desert scene
// paints her at the head of the party.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<int>> frame(double t, {bool moving = true, bool east = true}) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    SideSprites.paint(canvas, 4, 30, 60, t, moving: moving, east: east);
    return rec.endRecording().toImage(240, 260).then(
        (img) async => (await img.toByteData())!.buffer.asUint8List().toList());
  }

  testWidgets('the ronin loads, walks, stands and turns', (tester) async {
    SideSprites.reset();
    expect(SideSprites.loaded, isFalse);
    await tester.runAsync(() => SideSprites.preload(rootBundle));
    expect(SideSprites.loaded, isTrue);
    final a = await tester.runAsync(() => frame(0.0));
    final b = await tester.runAsync(() => frame(0.25));
    final standing = await tester.runAsync(() => frame(0.0, moving: false));
    final west = await tester.runAsync(() => frame(0.0, east: false));
    expect(a, isNot(equals(b)), reason: 'the walk steps');
    expect(a, isNot(equals(standing)), reason: 'standing is its own frame');
    expect(a, isNot(equals(west)), reason: 'she can face west');
    // She is drawn: not an empty picture.
    expect(a!.any((v) => v != 0), isTrue);
  });

  testWidgets('before the images are in, nothing is painted and no error',
      (tester) async {
    SideSprites.reset();
    final rec = ui.PictureRecorder();
    expect(SideSprites.paint(Canvas(rec), 4, 30, 60, 0), isFalse);
    rec.endRecording();
  });

  testWidgets('the desert scene paints with her at its head', (tester) async {
    SideSprites.reset();
    await tester.runAsync(() => SideSprites.preload(rootBundle));
    for (final moving in [true, false]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SideViewScene(
            layers: desertLayers(progress: 0.3),
            actors: desertActors(moving: moving),
            moving: moving,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
  });

  // Not a check: the picture the author looks at.
  testWidgets('picture', (tester) async {
    final out = Platform.environment['CITY_SHOTS'];
    if (out == null) return;
    SideSprites.reset();
    await tester.runAsync(() => SideSprites.preload(rootBundle));
    tester.view.physicalSize = const Size(780, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final moving in [true, false]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SideViewScene(
              layers: desertLayers(progress: 0.3),
              actors: desertActors(moving: moving),
              moving: moving,
              height: 190,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/ronin_${moving ? 'walk' : 'idle'}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  });
}
