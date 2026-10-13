// The side-view engine (v1.286): a scene paints its layers, actors and every
// kind of weather without error, stands still with reduced motion, and the
// land crossing wears the desert kit on a desert route and only a strip of
// day and health on another.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('every weather paints over the desert kit', (tester) async {
    for (final kind in SideParticles.values) {
      await tester.pumpWidget(MaterialApp(
        home: SideViewScene(
          layers: desertLayers(progress: 0.5),
          actors: desertActors(),
          particles: kind,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: kind.name);
    }
  });

  testWidgets('with reduced motion the scene stands still', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: SideViewScene(
            layers: desertLayers(), particles: SideParticles.dust),
      ),
    ));
    // Nothing ticks: the frame settles at once.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  Future<void> crossing(WidgetTester tester, LandRoute route) async {
    SharedPreferences.setMockInitialValues({});
    final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home:
            LandCrossingScreen(route: route, events: events, random: Random(1)),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a desert crossing has its scene and keeps its health bar',
      (tester) async {
    final route = landRouteFor(
        _json('assets/gamedata/land_routes.json'), 'crash_to_sleeper')!;
    expect(route.biome, 'desert');
    await crossing(tester, route);
    expect(find.byKey(const Key('crossing_scene')), findsOneWidget);
    expect(find.byKey(const Key('crossing_health')), findsOneWidget);
  });

  testWidgets('a route with no kit yet keeps only the strip', (tester) async {
    final base = landRouteFor(
        _json('assets/gamedata/land_routes.json'), 'crash_to_sleeper')!;
    final marsh = LandRoute(
      id: base.id,
      name: base.name,
      nameFr: base.nameFr,
      from: base.from,
      to: base.to,
      roads: base.roads,
      days: base.days,
      biome: 'marsh',
      chapter: base.chapter,
      events: base.events,
    );
    await crossing(tester, marsh);
    expect(find.byKey(const Key('crossing_scene')), findsNothing);
    expect(find.byKey(const Key('crossing_health')), findsOneWidget);
  });
}
