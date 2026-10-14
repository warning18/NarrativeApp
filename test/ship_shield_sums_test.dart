// The ship battle panel shows the sums of the enemy's shield: how many
// layers stand, how many shots it takes to get one through (fewer at the
// bulwark), and a flag when the guns ready now can do it this turn.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

ShipWeapon _ballista(String id) => ShipWeapon(
    id: id, name: 'Ballista', nameFr: 'Baliste', damage: 12, chargeTurns: 1);

Future<void> _pump(WidgetTester tester, List<ShipWeapon> guns) async {
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
    weapons: guns,
  );
  final enemy = buildEnemyShip(const {
    'maxHull': 80,
    'rooms': {'helm': 0, 'guns': 1, 'bulwark': 2, 'hold': 1},
    'weapons': [
      {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
    ],
  });
  expect(enemy.layers, 2);
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
          random: Random(4),
          rules: const ShipBattleRules(seaEvents: false, range: false),
          onFinished: (_) {},
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('one gun: the layers and the shots to get through, no salvo',
      (tester) async {
    await _pump(tester, [_ballista('b1')]);
    final sums = tester.widget<Text>(find.byKey(const Key('ship_shield_sums')));
    expect(sums.data,
        '2 shield layers: 3 shots to get through (2 at the bulwark)');
    expect(find.byKey(const Key('ship_salvo_ready')), findsNothing);
  });

  testWidgets('two guns ready: the salvo is flagged', (tester) async {
    await _pump(tester, [_ballista('b1'), _ballista('b2')]);
    expect(find.byKey(const Key('ship_shield_sums')), findsOneWidget);
    expect(find.byKey(const Key('ship_salvo_ready')), findsOneWidget);
  });
}
