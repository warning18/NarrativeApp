// The desert road crossing, painted beside today's (UX_SHOTS=<folder>): the
// scene as the crossing builds it (hour stars and wash, the party walking),
// at three scroll positions, by day and at dusk, 360 and 412 wide, today's
// code kit over the painted one; and a strip of frames for the scroll GIF.
// Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/desert_pictures.dart';
import 'package:narrative_data_app/widgets/side_view/kit_hour.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the desert crossing', skip: shots == null, (tester) async {
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(DesertPictures.preload);
    expect(DesertPictures.loaded, isTrue);
    final key = GlobalKey();

    Future<List<int>> grab() async {
      late List<int> bytes;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      return bytes;
    }

    Future<void> show(double width, DayPhase phase, bool painted) async {
      tester.view.physicalSize = Size(width, 190);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final layers =
          painted ? crossingLayers('desert', 0.5) : desertLayers(progress: 0.5);
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SideViewScene(
            height: 190,
            layers: withHourStars(layers, phase),
            overlay: hourWash(phase),
            actors: desertActors(figures: 2),
            particles: SideParticles.shimmer,
            intensity: 0.6,
          ),
        ),
      ));
    }

    for (final width in [360.0, 412.0]) {
      for (final (phase, name) in [
        (DayPhase.day, 'day'),
        (DayPhase.dusk, 'dusk'),
      ]) {
        for (final painted in [false, true]) {
          await show(width, phase, painted);
          for (final (i, seconds) in [0.1, 4.0, 4.0].indexed) {
            await tester.pump(Duration(milliseconds: (seconds * 1000).round()));
            File('$shots/desert-${width.round()}-$name-${painted ? 'painted' : 'today'}-$i.png')
                .writeAsBytesSync(await grab());
          }
        }
      }
    }

    // Frames for the scroll GIF: the painted scene by day, every 0.25 s.
    await show(412, DayPhase.day, true);
    for (var i = 0; i < 48; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      File('$shots/frames/f${i.toString().padLeft(2, '0')}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(await grab());
    }
  });
}
