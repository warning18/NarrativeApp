// The hulls in side view (side_ship.dart): every hull of ships.json draws
// in the sea scene, in every weather, flying or not, plain or dressed, and
// each sits at a sensible length.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/data/sail_powers.dart';
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

  testWidgets('every gun, plating and gear she can carry paints on every hull',
      (tester) async {
    const families = [
      'ballista',
      'chain',
      'grape',
      'carronade',
      'culverin',
      'fire_pots',
      'harpoon',
      'hunters_harpoon',
      'trophy_beak',
    ];
    const platings = ['plating', 'bracing', 'screens', 'trophy_plating'];
    const gears = [
      'stores',
      'orders',
      'helm',
      'gunnery',
      'hold',
      'command',
      'trophy_hull'
    ];
    for (final id in ships.keys) {
      final form = ShipForm.fromRecord(id, ships[id] as Map<String, dynamic>);
      for (var i = 0; i < gears.length; i++) {
        final dress = ShipDress(
          mounts: [
            for (var k = 0; k < 3; k++)
              ShipMount(
                  family: families[(i + k * 3) % families.length],
                  tier: 1 + k,
                  rarity: k == 2 ? 'epic' : 'common'),
          ],
          plating: ShipPlating(platings[i % platings.length], 1 + i % 3, 'x'),
          gear: gears[i],
        );
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body:
                SeaSideScene(waters: SeaWaters.open, ship: form, dress: dress),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$id with ${gears[i]}');
      }
    }
  });

  testWidgets('every painted sail power paints on every hull, one or four',
      (tester) async {
    const colours = [
      Color(0xFFB8862B),
      Color(0xFF3F7A5A),
      Color(0xFF6C7A8C),
      Color(0xFF2B2830),
      Color(0xFF7E57C2),
    ];
    for (final id in ships.keys) {
      final form = ShipForm.fromRecord(id, ships[id] as Map<String, dynamic>);
      for (final count in [1, 4]) {
        final dress = ShipDress(sigils: [
          for (var i = 0; i < count; i++)
            ShipSigil(SailPower.values[i % SailPower.values.length],
                colours[i % colours.length]),
        ]);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body:
                SeaSideScene(waters: SeaWaters.open, ship: form, dress: dress),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$id with $count');
      }
    }
    // Each power, alone, on the sloop.
    final sloop = ShipForm.fromRecord(
        'rusty_eel', ships['rusty_eel'] as Map<String, dynamic>);
    for (final power in SailPower.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SeaSideScene(
            waters: SeaWaters.open,
            ship: sloop,
            dress: ShipDress(sigils: [ShipSigil(power, colours[0])]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: power.name);
    }
  });

  test('she sits lower in the water only once she is half gone', () {
    expect(sideShipSink(1.0), 0);
    expect(sideShipSink(0.5), 0);
    expect(sideShipSink(0.3), inInclusiveRange(1, 3));
    expect(sideShipSink(0.0), 3);
  });

  testWidgets('every hull paints battered, from scorched to ablaze',
      (tester) async {
    for (final id in ships.keys) {
      final form = ShipForm.fromRecord(id, ships[id] as Map<String, dynamic>);
      for (final condition in [0.7, 0.45, 0.2, 0.0]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SeaSideScene(
              waters: SeaWaters.open,
              ship: form,
              condition: condition,
            ),
          ),
        ));
        for (var i = 0; i < 2; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull, reason: '$id at $condition');
      }
    }
  });

  test('every raider of the sea has her own hull, the skiff the fallback', () {
    for (final id in [
      'raider_skiff',
      'corsair_brig',
      'inquisition_cutter',
      'void_barge'
    ]) {
      final enemy = sideEnemyOf(id);
      expect(enemy.form.id, id);
      expect(sideShipLength(enemy.form), inInclusiveRange(24, 40));
    }
    expect(sideEnemyOf('brinejaw').form.id, 'raider_skiff');
    expect(sideEnemyOf(null).form.id, 'raider_skiff');
    expect(sideEnemyOf('void_barge').glow, isNotNull);
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
