// The ship battle panel's new controls: the weather and range strip,
// closing in, the shot chips, a crew order, and an aimed shot from a
// long press on an enemy room. Also the log's tidying of ship names.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

void main() {
  group('tidyShipLine', () {
    test('a name with its own article reads right in English', () {
      expect(
          tidyShipLine(
              'Ballista hits the The Rusty Eel\'s hold for 8', AppLanguage.en),
          'Ballista hits the Rusty Eel\'s hold for 8');
      expect(tidyShipLine('The The Rusty Eel closes in', AppLanguage.en),
          'The Rusty Eel closes in');
      expect(tidyShipLine('The Raider Skiff slips it', AppLanguage.en),
          'The Raider Skiff slips it');
    });

    test('French contracts de and à with the article, and elides', () {
      expect(
          tidyShipLine(
              'Baliste touche la cale de Le Rusty Eel pour 8', AppLanguage.fr),
          'Baliste touche la cale du Rusty Eel pour 8');
      expect(
          tidyShipLine(
              'Le grain éteint les feux de Esquif de pillards', AppLanguage.fr),
          'Le grain éteint les feux d’Esquif de pillards');
      expect(tidyShipLine('Le Rusty Eel se rapproche', AppLanguage.fr),
          'Le Rusty Eel se rapproche');
      expect(
          tidyShipLine(
              'Une chose énorme surgit sous Le Rusty Eel !', AppLanguage.fr),
          'Une chose énorme surgit sous le Rusty Eel !');
    });
  });

  testWidgets('range, shot, orders and the aimed shot work from the panel',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final player = ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values) room: const RoomState(level: 1),
      },
      weapons: const [
        ShipWeapon(
            id: 'ballista',
            name: 'Ballista',
            nameFr: 'Baliste',
            damage: 12,
            chargeTurns: 1),
      ],
    );
    final enemy = buildEnemyShip(const {
      'maxHull': 80,
      'rooms': {'helm': 0, 'guns': 2, 'bulwark': 0, 'hold': 1},
      'weapons': [
        {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
      ],
    });
    ShipBattleOutcome? outcome;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: player,
            enemy: enemy,
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: const [
              ShipCrew(
                id: 'player',
                name: 'Ada',
                strength: 3,
                dexterity: 3,
                constitution: 3,
                wisdom: 3,
                health: 50,
                maxHealth: 50,
                isPlayer: true,
              ),
              ShipCrew(
                id: 'kelda',
                name: 'Kelda',
                strength: 5,
                dexterity: 2,
                constitution: 4,
                wisdom: 2,
                health: 60,
                maxHealth: 60,
              ),
            ],
            foresight: false,
            random: Random(4),
            habit: EnemyHabit.marksman,
            rules: const ShipBattleRules(seaEvents: false),
            onFinished: (o) => outcome = o,
          ),
        ),
      ),
    ));
    await tester.pump();

    // The sea between the ships: the weather, the range, the enemy's habit.
    expect(find.byKey(const Key('ship_sea_strip')), findsOneWidget);
    expect(find.byKey(const Key('ship_range_bar')), findsOneWidget);
    expect(find.byKey(const Key('ship_enemy_habit')), findsOneWidget);
    expect(find.text('Medium range'), findsOneWidget);

    // Close in: the helm hand spends the turn on it.
    await tester.tap(find.byKey(const Key('ship_close_in')));
    await tester.pump();
    expect(find.text('Close'), findsOneWidget);
    expect(find.textContaining('closes in'), findsOneWidget);

    // No shot to pick: each weapon fires its own.
    expect(find.byKey(const Key('ship_ammo_chain')), findsNothing);

    // Kelda's order, on the sea: brace, given from the hold or the
    // bulwark. One tap sends her there and gives it; spent once given.
    expect(find.byKey(const Key('ship_crew_skills')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ship_order_brace')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ship_order_brace')));
    await tester.pump();
    expect(find.textContaining('Brace!'), findsWidgets);
    final brace =
        tester.widget<InkWell>(find.byKey(const Key('ship_order_brace')));
    expect(brace.onTap, isNull);
    // Held, the die tells what the order does and from where.
    await tester.longPress(find.byKey(const Key('ship_order_brace')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ship_order_sheet')), findsOneWidget);
    expect(find.textContaining('Given from:'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('ship_order_sheet'))))
        .pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The crew sheet still moves hands.
    await tester.tap(find.byKey(const Key('ship_crew_button')));
    // The sea never settles: let the sheet slide.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ship_crew_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ship_station_kelda_hold')));
    await tester.pump();
    Navigator.of(tester.element(find.byKey(const Key('ship_crew_sheet'))))
        .pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ship_crew_sheet')), findsNothing);

    // Hold an enemy room to take aim; the bar sweeps; fire.
    await tester.longPress(find.byKey(const Key('ship_room_enemy_guns')));
    await tester.pump();
    expect(find.byKey(const Key('ship_aim_bar')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('ship_aim_fire')));
    await tester.pump();
    expect(find.byKey(const Key('ship_aim_bar')), findsNothing);
    expect(find.textContaining(RegExp(r'Ballista (hits|goes wide)|slips')),
        findsOneWidget);
    expect(outcome, isNull);
  });

  testWidgets('the crew are placed before the first round', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ShipCrew hand(String id, {bool player = false}) => ShipCrew(
          id: id,
          name: id,
          strength: 3,
          dexterity: 3,
          constitution: 3,
          wisdom: 3,
          health: 50,
          maxHealth: 50,
          isPlayer: player,
        );
    final player = ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {for (final r in ShipRoom.values) r: const RoomState(level: 2)},
      weapons: const [
        ShipWeapon(
            id: 'ballista',
            name: 'Ballista',
            nameFr: 'Baliste',
            damage: 12,
            chargeTurns: 1),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: player,
            enemy: buildEnemyShip(const {
              'maxHull': 80,
              'rooms': {'helm': 0, 'guns': 2, 'bulwark': 0, 'hold': 1},
              'weapons': [
                {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
              ],
            }),
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: [hand('player', player: true), hand('kelda')],
            foresight: false,
            random: Random(4),
            turnSeconds: 20,
            placeCrew: true,
            rules: const ShipBattleRules(seaEvents: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('ship_placement')), findsOneWidget);
    expect(find.byKey(const Key('ship_end_turn')), findsNothing);

    // Tap Kelda, then the helm: she takes it.
    await tester.tap(find.byKey(const Key('ship_place_kelda')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ship_room_eel_helm')));
    await tester.pump();
    Finder at(String room) => find.descendant(
        of: find.byKey(const Key('ship_place_kelda')),
        matching: find.text(room));
    expect(at('Helm'), findsOneWidget);

    // Orders first: she goes where her brace is given.
    await tester.tap(find.byKey(const Key('ship_place_skills')));
    await tester.pump();
    expect(at('Helm'), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('ship_place_kelda')),
            matching: find.textContaining(RegExp('^(Bulwark|Hold)\$'))),
        findsOneWidget);

    // The clock does not run while placing; it starts with the battle.
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const Key('ship_placement')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ship_start_battle')));
    await tester.pump();
    expect(find.byKey(const Key('ship_placement')), findsNothing);
    expect(find.byKey(const Key('ship_end_turn')), findsOneWidget);
    expect(find.byKey(const Key('ship_order_brace')), findsOneWidget);
  });
}
