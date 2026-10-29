// The frost, fen and sea cliffs scene kits (wave 16, UX): each paints at
// every stage of the goal's approach with every kind of weather over it, the
// land crossing picks the kit by the route's terrain (and its weather
// by the terrain's), and UX_SHOTS=<folder> takes a picture of each.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/side_view/cliffs_kit.dart';
import 'package:narrative_data_app/widgets/side_view/fen_kit.dart';
import 'package:narrative_data_app/widgets/side_view/frost_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  final kits = <String, List<SideLayer> Function(double)>{
    'frost': (p) => frostLayers(progress: p),
    'fen': (p) => fenLayers(progress: p),
    'sea_cliffs': (p) => cliffsLayers(progress: p),
  };

  testWidgets('each kit paints at every stage and in every weather',
      (tester) async {
    for (final e in kits.entries) {
      for (final progress in [0.0, 0.5, 1.0]) {
        for (final kind in SideParticles.values) {
          await tester.pumpWidget(MaterialApp(
            home: SideViewScene(layers: e.value(progress), particles: kind),
          ));
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull,
              reason: '${e.key} $progress ${kind.name}');
        }
      }
    }
  });

  testWidgets('the crossing picks the kit and the weather by the terrain',
      (tester) async {
    expect(crossingSceneTerrains,
        containsAll(['desert', 'ruins', 'frost', 'fen', 'sea_cliffs']));
    expect(
        crossingParticles(terrain: 'frost', storm: false), SideParticles.snow);
    expect(crossingParticles(terrain: 'fen', storm: false), SideParticles.fog);
    expect(crossingParticles(terrain: 'sea_cliffs', storm: false),
        SideParticles.fog);
    // The sky's own weather still wins over the terrain's.
    expect(crossingParticles(terrain: 'fen', storm: false, sky: null),
        SideParticles.fog);

    SharedPreferences.setMockInitialValues({});
    final base = landRouteFor(
        _json('assets/gamedata/land_routes.json'), 'crash_to_sleeper')!;
    final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
    for (final terrain in kits.keys) {
      final route = LandRoute(
        id: base.id,
        name: base.name,
        nameFr: base.nameFr,
        from: base.from,
        to: base.to,
        roads: base.roads,
        days: base.days,
        biome: terrain,
        terrain: terrain,
        chapter: base.chapter,
        events: base.events,
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: LandCrossingScreen(
              route: route, events: events, random: Random(1)),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('crossing_scene')), findsOneWidget,
          reason: terrain);
      expect(tester.takeException(), isNull, reason: terrain);
    }
  });

  testWidgets('pictures of the kits (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(720, 1240);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Column(children: [
            for (final e in kits.entries)
              SideViewScene(
                  layers: e.value(0.6),
                  particles:
                      e.key == 'frost' ? SideParticles.snow : SideParticles.fog,
                  intensity: 0.5,
                  moving: false),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/side-view-biomes.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
