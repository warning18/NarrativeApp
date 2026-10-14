// A sea beast in the battle panel (v1.185, on the sea from above since
// v1.186): its rooms named for a body (fins, hide, jaws, heart), and what
// it is about to do shown under its name (no dive foretold while its fins
// are torn). It has no look of its own yet: it borrows the ship nearest
// its size.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/sea_beasts.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';

ShipState _ship({int hull = 100, int maxHull = 100, int finsTorn = 0}) =>
    ShipState(
      hull: hull,
      maxHull: maxHull,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values)
          room:
              RoomState(level: 2, damage: room == ShipRoom.helm ? finsTorn : 0),
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
    Widget panel({int finsTorn = 0}) => ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShipBattlePanel(
                key: ValueKey(finsTorn),
                player: _ship(),
                // A beast has a body of its own, drawn from above.
                enemy: _ship(hull: 200, maxHull: 240, finsTorn: finsTorn),
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
        );
    await tester.pumpWidget(panel());
    await tester.pump();

    final sprite =
        tester.widget<CustomPaint>(find.byKey(const Key('ship_sprite_enemy')));
    expect((sprite.painter! as TopShipPainter).look, TopShipLook.paleLeviathan);
    expect(TopShipLook.paleLeviathan.beast, TopBeast.leviathan);
    for (final title in ['FINS', 'HIDE', 'JAWS', 'HEART']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Dives in 2'), findsOneWidget);
    expect(find.text('Heals 7 a round'), findsOneWidget);
    expect(find.byKey(const Key('beast_edge')), findsOneWidget);
    expect(find.byKey(const Key('beast_turning')), findsNothing);
    expect(find.byKey(const Key('beast_tethered')), findsNothing);

    // Its fins torn, it cannot dive: no dive is foretold.
    await tester.pumpWidget(panel(finsTorn: 2));
    await tester.pump();
    expect(find.byKey(const Key('beast_dive')), findsNothing);
    expect(find.text('Heals 7 a round'), findsOneWidget);
  });
}
