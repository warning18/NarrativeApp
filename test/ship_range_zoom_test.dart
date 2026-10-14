// The sea seen from the masthead (v1.218): the farther apart the ships lie,
// the smaller each is drawn and the wider the water between them, so being
// close or far reads at a glance.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

ShipState _ship({List<ShipWeapon> weapons = const []}) => ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {for (final r in ShipRoom.values) r: const RoomState(level: 1)},
      weapons: weapons,
    );

void main() {
  test('the ships shrink as the range grows', () {
    expect(seaZoomFor(ShipRange.close), 1.0);
    expect(seaZoomFor(ShipRange.medium), lessThan(seaZoomFor(ShipRange.close)));
    expect(seaZoomFor(ShipRange.long), lessThan(seaZoomFor(ShipRange.medium)));
    // Small enough to see, large enough to tap.
    expect(seaZoomFor(ShipRange.long), greaterThanOrEqualTo(0.6));
  });

  Future<({double width, double gap}) Function()> pumpPanel(
      WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: _ship(),
            enemy: _ship(),
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
            rules: const ShipBattleRules(seaEvents: false, weather: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    return () {
      final enemy =
          tester.getRect(find.byKey(const Key('ship_room_enemy_guns')));
      final eel = tester.getRect(find.byKey(const Key('ship_room_eel_guns')));
      return (width: eel.width, gap: eel.top - enemy.bottom);
    };
  }

  // The ships glide for 700 ms; the sea's own clock never stops, so step.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('pulling away shrinks the ships and opens the water',
      (tester) async {
    final look = await pumpPanel(tester);
    final medium = look();
    await tester.tap(find.byKey(const Key('ship_pull_away')));
    await settle(tester);
    final far = look();
    expect(far.width, lessThan(medium.width));
    expect(far.gap, greaterThan(medium.gap));
  });

  testWidgets('closing in grows the ships and shuts the water', (tester) async {
    final look = await pumpPanel(tester);
    final medium = look();
    await tester.tap(find.byKey(const Key('ship_close_in')));
    await settle(tester);
    final near = look();
    expect(near.width, greaterThan(medium.width));
    expect(near.gap, lessThan(medium.gap));
  });
}
