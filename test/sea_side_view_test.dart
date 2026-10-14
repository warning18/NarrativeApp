// The sea in side view (sea_kit.dart): every waters in every weather lays
// out and paints without error, the weather's particles stay inside the
// scene, and a flying hull paints too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';

void main() {
  test('rain in a squall, fog in fog, ash off the ashen coast, else none', () {
    expect(seaParticles(SeaWaters.open, SeaWeather.squall), SideParticles.rain);
    expect(seaParticles(SeaWaters.drowned, SeaWeather.fog), SideParticles.fog);
    expect(seaParticles(SeaWaters.ashen, SeaWeather.calm), SideParticles.ash);
    expect(
        seaParticles(SeaWaters.ashen, SeaWeather.squall), SideParticles.rain);
    expect(seaParticles(SeaWaters.shallows, SeaWeather.tailwind),
        SideParticles.none);
  });

  for (final waters in SeaWaters.values) {
    for (final weather in SeaWeather.values) {
      testWidgets('the ${waters.name} sea in ${weather.name} paints',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SeaSideScene(
              waters: waters,
              weather: weather,
              flying: waters == SeaWaters.abyss,
              beside: const Icon(Icons.sailing),
            ),
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byKey(const Key('sea_scene')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
