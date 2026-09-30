// A sea beast in the battle panel (v1.185): its rooms named for a body
// (fins, hide, jaws, heart), and what it is about to do shown under its
// name. It has no sprite of its own yet: it borrows the ship nearest its
// size.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/sea_beasts.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

ShipState _ship({int hull = 100, int maxHull = 100}) => ShipState(
      hull: hull,
      maxHull: maxHull,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values) room: const RoomState(level: 2),
      },
      weapons: const [
        ShipWeapon(
            id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 5, chargeTurns: 1),
      ],
    );

void main() {
  testWidgets('the beast\'s body, and what it is about to do', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: _ship(),
            // A beast's size: it borrows the void barge's sprite.
            enemy: _ship(hull: 200, maxHull: 240),
            shipName: 'The Rusty Eel',
            enemyName: 'The Pale Leviathan',
            enemyShipId: 'pale_leviathan',
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
            rules: const ShipBattleRules(seaEvents: false),
            beast: const BeastProfile(regen: 7, diveEvery: 3, edge: 15),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    final sprite =
        tester.widget<Image>(find.byKey(const Key('ship_sprite_enemy')));
    expect((sprite.image as AssetImage).assetName,
        'assets/visuals/ship_cutaways/void_barge.png');
    for (final title in ['FINS', 'HIDE', 'JAWS', 'HEART']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Dives in 2'), findsOneWidget);
    expect(find.text('Heals 7 a round'), findsOneWidget);
    expect(find.byKey(const Key('beast_edge')), findsOneWidget);
    expect(find.byKey(const Key('beast_turning')), findsNothing);
    expect(find.byKey(const Key('beast_tethered')), findsNothing);
  });
}
