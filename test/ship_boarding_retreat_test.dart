// Running from the dice fight on the enemy's deck (v1.186.1): the boarders
// fall back aboard the Eel and cut the grapples. The sea battle goes on --
// the turn comes back, the boarding is spent -- rather than waiting for a
// fight result that never comes.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a retreat from a boarding fight hands the turn back',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Let the session's own load from storage finish first.
    await tester.runAsync(() async {
      container.read(playerSessionProvider);
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'gold': 100,
        })));

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
    // Its helm and bulwark down: the grapples hold, the rail is open.
    final enemy = buildEnemyShip(const {
      'maxHull': 80,
      'rooms': {'helm': 0, 'guns': 2, 'bulwark': 0, 'hold': 1},
      'weapons': [
        {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
      ],
    });
    ShipBattleOutcome? outcome;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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
            // A harbor rat to fight on the deck; they never board back.
            boarding: const BoardingProfile(crew: ['harbor_rat'], chance: 0),
            rules: const ShipBattleRules(
                range: false, weather: false, seaEvents: false, habits: false),
            onFinished: (o) => outcome = o,
          ),
        ),
      ),
    ));
    await _settle(tester);

    // The fight's data, loaded before the deck fight opens.
    await tester.runAsync(() async {
      for (final schema in [diceSchema, skillsSchema, itemsSchema]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
    await _settle(tester);

    final board = find.text('Board them');
    expect(board, findsOneWidget);
    await tester.tap(board);
    await _settle(tester);
    expect(find.byType(FightScreen), findsOneWidget);

    // On the deck: into the fight, then run from it.
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.pump();
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Retreat'));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    // Back at sea, the battle goes on: the turn is the player's again,
    // the boarding spent, and the retreat no concern of the story.
    expect(find.byType(FightScreen), findsNothing);
    expect(outcome, isNull);
    final endTurn = tester
        .widget<ButtonStyleButton>(find.byKey(const Key('ship_end_turn')));
    expect(endTurn.onPressed, isNotNull);
    expect(find.text('Board them'), findsNothing);
    expect(container.read(lastFightRetreatedProvider), isFalse);
    expect(container.read(playerSessionProvider).gold, lessThan(100));
  });
}
