// The hero walking the desert road (UX_SHOTS=<folder>, UX_HERO=race:calling):
// the crossing as the screen builds it, the hero walking and standing, by day
// and at dusk, 412 wide. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/desert_pictures.dart';
import 'package:narrative_data_app/widgets/side_view/kit_hour.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final hero = (Platform.environment['UX_HERO'] ?? 'human:warrior').split(':');

  testWidgets('the hero on the desert road', skip: shots == null,
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Directory(shots!).createSync(recursive: true);
    SideSprites.reset();
    await tester.runAsync(DesertPictures.preload);
    final key = GlobalKey();
    tester.view.physicalSize = const Size(412, 190);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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

    for (final (phase, name) in [
      (DayPhase.day, 'day'),
      (DayPhase.dusk, 'dusk')
    ]) {
      for (final moving in [true, false]) {
        SideSprites.reset();
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // The notifier reads what was saved when it is first read: let it
        // finish before the hero is set.
        container.read(playerSessionProvider);
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson(
                {'raceId': hero[0], 'professionId': hero[1]})));
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SideViewScene(
                height: 190,
                layers: withHourStars(crossingLayers('desert', 0.5), phase),
                overlay: hourWash(phase),
                actors: desertActors(moving: moving, figures: 2),
                moving: moving,
                particles: SideParticles.shimmer,
                intensity: 0.6,
              ),
            ),
          ),
        ));
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)));
          await tester.pump(const Duration(milliseconds: 150));
        }
        File('$shots/walk-${hero[0]}-${hero[1]}-$name-${moving ? 'walk' : 'stand'}.png')
            .writeAsBytesSync(await grab());
      }
    }
  });
}
