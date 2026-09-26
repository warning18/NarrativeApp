// v1.158: the ship battle's rules explained one at a time, the first time
// each comes up (the range, the enemy's habit, aimed shots…), each once;
// and the aimed-shot setting: off, a long press on a room does nothing.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

ShipState _eel() => ShipState(
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

ShipState _raider() => buildEnemyShip(const {
      'maxHull': 80,
      'rooms': {'helm': 0, 'guns': 2, 'bulwark': 0, 'hold': 1},
      'weapons': [
        {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
      ],
    });

const _you = ShipCrew(
  id: 'player',
  name: 'Ada',
  strength: 3,
  dexterity: 3,
  constitution: 3,
  wisdom: 3,
  health: 50,
  maxHealth: 50,
  isPlayer: true,
);

Widget _panel({required bool tips, EnemyHabit habit = EnemyHabit.marksman}) =>
    ProviderScope(
      overrides: [tutorialAutoShowProvider.overrideWithValue(tips)],
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: _eel(),
            enemy: _raider(),
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: const [_you],
            foresight: false,
            random: Random(5),
            habit: habit,
            rules: const ShipBattleRules(seaEvents: false, weather: false),
            onFinished: (_) {},
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  testWidgets('each rule is explained once, one at a time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_panel(tips: true));
    await _settle(tester);

    // The range first, then the enemy's habit, then aimed shots.
    for (final id in ['ship_range', 'ship_habit_marksman', 'ship_aim']) {
      expect(find.byKey(Key('ship_tip_$id')), findsOneWidget, reason: id);
      expect(find.byKey(const Key('ship_tip_ok')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ship_tip_ok')));
      await _settle(tester);
      expect(find.byKey(Key('ship_tip_$id')), findsNothing);
    }
    expect(find.textContaining('How Raider fights'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('tutorial_seen_topics'),
        containsAll(['tip:ship_range', 'tip:ship_habit_marksman']));

    // A new battle: what was explained stays explained.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_panel(tips: true));
    await _settle(tester);
    expect(find.byKey(const Key('ship_tip_ship_range')), findsNothing);
    expect(find.byKey(const Key('ship_tip_ship_aim')), findsNothing);
  });

  testWidgets('with aimed shots off, holding a room does not aim',
      (tester) async {
    SharedPreferences.setMockInitialValues({'ship_aimed_shots': 'off'});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_panel(tips: false));
    await _settle(tester);
    expect(find.byTooltip('Tap a ready weapon, then the room to hit.'),
        findsOneWidget);
    await tester.longPress(find.byKey(const Key('ship_room_enemy_guns')));
    await tester.pump();
    expect(find.byKey(const Key('ship_aim_bar')), findsNothing);
    // A tap still fires.
    await tester.tap(find.byKey(const Key('ship_room_enemy_guns')));
    await tester.pump();
    expect(find.textContaining(RegExp(r'Ballista (hits|goes wide)|slips')),
        findsOneWidget);
  });
}
