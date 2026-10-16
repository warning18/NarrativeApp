// What the party meets on a land crossing walks in from the right and stops
// in front of it (lib/widgets/side_view/encounter_figure.dart): which
// events put a figure on the road, how the walk runs, and that the scene
// paints it. UX_SHOTS=<dir> saves the picture.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/encounter_figure.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void main() {
  test('the events that put a figure on the road, and the art it wears', () {
    // The patrol is Inquisition soldiers: their art.
    expect(roadEncounterFigure('inquisition_patrol')!.sprite?.id,
        'inquisition_soldier_02');
    // The scavengers' fight is with an enemy that has no art yet: a
    // placeholder (sprite null), not nothing.
    final scavengers =
        roadEncounterFigure('scavengers', fightEnemyId: 'wreck_scavenger');
    expect(scavengers, isNotNull);
    expect(scavengers!.sprite, isNull);
    // A fight with an enemy that has art wears it.
    expect(roadEncounterFigure('x', fightEnemyId: 'white_soldier')!.sprite?.id,
        'white_soldier');
    // Events that name nobody put nobody on the road.
    for (final id in ['sandstorm', 'feral_dogs', 'water_seller', 'spring']) {
      expect(roadEncounterFigure(id), isNull, reason: id);
    }
  });

  test(
      'it walks in over 1.4 s, easing to a stop; with animations off it is '
      'already there', () {
    final walk = EncounterWalk(sprite: null);
    expect(walk.progressAt(10), 0);
    expect(walk.progressAt(10.7), inInclusiveRange(0.5, 0.9));
    expect(walk.progressAt(10 + EncounterWalk.walkSeconds), 1);
    expect(walk.progressAt(30), 1);
    expect(EncounterWalk(sprite: null, animate: false).progressAt(0), 1);
  });

  testWidgets('the scene paints the patrol walking in, then standing',
      (tester) async {
    SideSprites.reset();
    FightSpriteImages.reset();
    final set = roadEncounterFigure('inquisition_patrol')!.sprite!;
    await tester.runAsync(() async {
      await SideSprites.preload(rootBundle);
      await FightSpriteImages.load(set, bundle: rootBundle);
    });
    final out = Platform.environment['UX_SHOTS'];
    tester.view.physicalSize = const Size(780, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final walk = EncounterWalk(sprite: set);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: SideViewScene(
            layers: desertLayers(progress: 0.3),
            actors: desertActors(moving: false, encounter: walk),
            moving: false,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(FightSpriteImages.idleOf(set), isNotNull);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(walk.progressAt(0), isNonNegative);
    expect(tester.takeException(), isNull);
    if (out != null) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/encounter-patrol.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  });
}
