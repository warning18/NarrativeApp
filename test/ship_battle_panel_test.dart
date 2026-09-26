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

    // Load chain shot.
    await tester.tap(find.byKey(const Key('ship_ammo_chain')));
    await tester.pump();
    final chain =
        tester.widget<ChoiceChip>(find.byKey(const Key('ship_ammo_chain')));
    expect(chain.selected, isTrue);

    // Kelda's order, from the crew sheet: brace. Spent once given.
    await tester.tap(find.byKey(const Key('ship_crew_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ship_crew_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ship_order_brace')));
    await tester.pump();
    expect(find.textContaining('Brace!'), findsWidgets);
    final brace =
        tester.widget<ActionChip>(find.byKey(const Key('ship_order_brace')));
    expect(brace.onPressed, isNull);
    // Kelda moves to the hold from the sheet.
    await tester.tap(find.byKey(const Key('ship_station_kelda_hold')));
    await tester.pump();
    Navigator.of(tester.element(find.byKey(const Key('ship_crew_sheet'))))
        .pop();
    await tester.pumpAndSettle();
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
}
