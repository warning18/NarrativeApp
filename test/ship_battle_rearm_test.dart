// v1.158: a weapon that no longer reaches is put down when the range
// changes. Armed with a harpoon alongside, the Eel pulls away: the gun
// that still reaches is armed instead, so the enemy's rooms never invite
// a shot that cannot be fired.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

void main() {
  testWidgets('pulling away puts a harpoon down for a gun that reaches',
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
            id: 'harpoon',
            name: 'Harpoon',
            nameFr: 'Harpon',
            damage: 8,
            chargeTurns: 1,
            ranges: {ShipRange.close}),
        ShipWeapon(
            id: 'ballista',
            name: 'Ballista',
            nameFr: 'Baliste',
            damage: 12,
            chargeTurns: 1),
      ],
    );
    // No helm: the enemy never steers, so only the Eel moves.
    final enemy = buildEnemyShip(const {
      'maxHull': 80,
      'rooms': {'helm': 0, 'guns': 2, 'bulwark': 0, 'hold': 1},
      'weapons': [
        {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
      ],
    });
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
            ],
            foresight: false,
            random: Random(3),
            rules: const ShipBattleRules(seaEvents: false, weather: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    String stateOf(String weaponId) => tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(Key('ship_weapon_$weaponId')),
            matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join(' ');

    // Turn 1: close in, then end the turn.
    await tester.tap(find.byKey(const Key('ship_close_in')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ship_end_turn')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Close'), findsOneWidget);

    // Turn 2: alongside, the harpoon (first ready) comes up armed. Pull
    // away with it.
    expect(stateOf('harpoon'), contains('armed'));
    await tester.tap(find.byKey(const Key('ship_pull_away')));
    await tester.pump();
    expect(find.text('Medium range'), findsOneWidget);
    expect(stateOf('harpoon'), contains('out of reach'));
    expect(stateOf('ballista'), contains('armed'),
        reason: 'the gun that still reaches is armed instead');
  });
}
