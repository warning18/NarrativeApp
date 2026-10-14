// The hulls in side view (side_ship.dart): every hull of ships.json draws
// in the sea scene, in every weather, flying or not, plain or dressed, and
// each sits at a sensible length.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/data/ship_forms.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/ship_dress.dart';
import 'package:narrative_data_app/widgets/side_view/side_ship.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> ships;

  setUpAll(() async {
    ships =
        jsonDecode(await rootBundle.loadString('assets/gamedata/ships.json'))
            as Map<String, dynamic>;
  });

  test('there are fourteen hulls, each a sensible length', () {
    expect(ships.length, 14);
    for (final entry in ships.entries) {
      final form =
          ShipForm.fromRecord(entry.key, entry.value as Map<String, dynamic>);
      final len = sideShipLength(form);
      expect(len, inInclusiveRange(24, 40), reason: entry.key);
    }
    final longboat = ShipForm.fromRecord(
        'longboat', ships['longboat'] as Map<String, dynamic>);
    final sloop = ShipForm.fromRecord(
        'rusty_eel', ships['rusty_eel'] as Map<String, dynamic>);
    expect(sideShipLength(longboat), lessThan(sideShipLength(sloop)));
  });

  testWidgets('every hull paints, plain and dressed, calm and in a squall',
      (tester) async {
    const dress = ShipDress(
      hull: Color(0xFF2E4A6B),
      trim: Color(0xFFC9A24A),
      cloth: Color(0xFFD9C8A0),
      clothPattern: 'stripes',
      clothPatternColor: Color(0xFFB03A2E),
      clothEdge: Color(0xFF6B4E10),
      figurehead: 'eel',
      figureheadColor: Color(0xFF3FB8B0),
    );
    for (final id in ships.keys) {
      final form = ShipForm.fromRecord(id, ships[id] as Map<String, dynamic>);
      for (final weather in [SeaWeather.calm, SeaWeather.squall]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SeaSideScene(
              waters: SeaWaters.open,
              weather: weather,
              ship: form,
              dress: weather == SeaWeather.squall ? dress : null,
            ),
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull,
            reason: '$id in ${weather.name}');
      }
    }
  });
}
