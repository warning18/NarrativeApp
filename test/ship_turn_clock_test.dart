// A ship battle's turns run against the clock: 20 seconds on the Rusty
// Eel, more with a Speaking Tube. When the clock runs out the turn ends as
// it stands, and a weapon not fired keeps its charge.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final ships = _data('ships');
  final parts = _data('ship_parts');
  final eel = ships['rusty_eel'] as Map<String, dynamic>;

  group('turn seconds', () {
    test('the Eel has 20; a Speaking Tube adds 8', () {
      expect(
          shipTurnSeconds(
              ship: eel, parts: parts, installedPartIds: const ['ballista']),
          20);
      expect(
          shipTurnSeconds(
              ship: eel,
              parts: parts,
              installedPartIds: const ['ballista', 'speaking_tube']),
          28);
      // A part counted twice is still one part.
      expect(
          shipTurnSeconds(
              ship: eel,
              parts: parts,
              installedPartIds: const ['speaking_tube', 'speaking_tube']),
          28);
    });

    test('a ship with no figure gets the default; never past the cap', () {
      expect(
          shipTurnSeconds(
              ship: const {}, parts: const {}, installedPartIds: const []),
          defaultTurnSeconds);
      expect(
          shipTurnSeconds(ship: const {
            'turnSeconds': 50
          }, parts: const {
            'a': {'turnSecondsBonus': 30}
          }, installedPartIds: const [
            'a'
          ]),
          maxTurnSeconds);
    });

    test('the Speaking Tube is a utility part, in both languages', () {
      final tube = parts['speaking_tube'] as Map<String, dynamic>;
      expect(tube['slotType'], 'Utility');
      expect(tube['turnSecondsBonus'], greaterThan(0));
      expect(tube['partName_fr'], isNotEmpty);
      expect(tube['description_fr'], isNotEmpty);
    });
  });

  testWidgets('when the clock runs out the turn ends and the guns keep charge',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final player = buildPlayerShip(
      ship: eel,
      parts: parts,
      installedPartIds: const ['ballista'],
      currentHull: -1,
    );
    // A raider whose single gun takes a long charge: nothing is fired at
    // the Eel while the clock is watched.
    final enemy = buildEnemyShip(const {
      'maxHull': 80,
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
                id: 'you',
                name: 'You',
                strength: 1,
                dexterity: 1,
                constitution: 1,
                wisdom: 1,
                health: 50,
                maxHealth: 50,
                isPlayer: true,
              ),
            ],
            foresight: false,
            random: Random(1),
            turnSeconds: 3,
            onFinished: (o) => outcome = o,
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('ship_turn_clock')), findsOneWidget);
    expect(find.text('3 s'), findsOneWidget);
    expect(find.textContaining('Round 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 s'), findsOneWidget);

    // The clock runs out: the turn ends without a shot, the ballista held,
    // and the next turn starts on a fresh clock.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Round 2'), findsOneWidget);
    expect(find.textContaining('holds her fire'), findsOneWidget);
    expect(find.text('3 s'), findsOneWidget, reason: 'a fresh clock');
    expect(outcome, isNull);
  });

  testWidgets('an untimed battle shows no clock', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final player = buildPlayerShip(
      ship: eel,
      parts: parts,
      installedPartIds: const ['ballista'],
      currentHull: -1,
    );
    final enemy = buildEnemyShip(const {'maxHull': 80});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: player,
            enemy: enemy,
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: const [],
            foresight: false,
            random: Random(1),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 30));
    expect(find.byKey(const Key('ship_turn_clock')), findsNothing);
    expect(find.textContaining('Round 1'), findsOneWidget);
  });
}
