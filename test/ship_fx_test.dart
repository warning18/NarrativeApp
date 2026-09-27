// The ship battle's particles: shots, hits and the sinking ship play for
// both sides without getting in the battle's way, and reduced motion
// skips them, sinking and all.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/widgets/ship_fx.dart';

Widget _panel({required bool still, required void Function(bool) done}) {
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
          damage: 40,
          chargeTurns: 1),
    ],
  );
  final enemy = buildEnemyShip(const {
    'maxHull': 30,
    'rooms': {'helm': 0, 'guns': 1, 'bulwark': 0, 'hold': 0},
    'weapons': [
      {'weaponName': 'Gun', 'damage': 4, 'chargeTurns': 1},
    ],
  });
  return ProviderScope(
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: child!,
      ),
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
          habit: EnemyHabit.marksman,
          rules: const ShipBattleRules(seaEvents: false),
          onFinished: (o) => done(o.won),
        ),
      ),
    ),
  );
}

/// Fires the ballista (armed at the start of each turn) at the enemy's hold, round after round, until the
/// battle ends; returns how long the result took after the last shot.
Future<Duration> _fightToTheEnd(WidgetTester tester, bool Function() over,
    {required Duration step}) async {
  for (var round = 0; round < 12; round++) {
    await tester.tap(find.byKey(const Key('ship_room_enemy_hold')));
    var waited = Duration.zero;
    for (var i = 0; i < 40 && !over(); i++) {
      await tester.pump(step);
      waited += step;
    }
    if (over()) return waited;
    await tester.tap(find.byKey(const Key('ship_end_turn')));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  fail('the battle never ended');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tall(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('shots fly both ways and the loser sinks before the result',
      (tester) async {
    await tall(tester);
    bool? won;
    await tester.pumpWidget(_panel(still: false, done: (w) => won = w));
    await tester.pump();
    expect(find.byType(ShipFxLayer), findsOneWidget);

    final waited = await _fightToTheEnd(tester, () => won != null,
        step: const Duration(milliseconds: 100));
    expect(won, isTrue);
    // The shot's flight, then the enemy going down.
    expect(waited, greaterThanOrEqualTo(const Duration(milliseconds: 1400)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion, nothing is drawn and nothing waits',
      (tester) async {
    await tall(tester);
    bool? won;
    await tester.pumpWidget(_panel(still: true, done: (w) => won = w));
    await tester.pump();
    final layer = find.descendant(
        of: find.byType(ShipFxLayer), matching: find.byType(CustomPaint));
    expect(layer, findsNothing);

    final waited = await _fightToTheEnd(tester, () => won != null,
        step: const Duration(milliseconds: 100));
    expect(won, isTrue);
    expect(waited, lessThan(const Duration(milliseconds: 400)));
  });
}
