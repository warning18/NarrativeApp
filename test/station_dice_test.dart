// Station dice (v1.218, see combat/station_dice.dart): a hand's die shows
// only the faces its room can use, lands once a turn on a face that depends
// on the battle, the turn, the hand and the room, and works for the turn
// while the hand stays at the station.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/combat/station_dice.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/station_die.dart';

StationFace _face(FaceKind kind, int value, [int index = 0]) => StationFace(
      DiceFaceResult(
        faceIndex: index,
        faceName: '',
        type: kind.name,
        value: value,
        linkedSkillID: '',
        element: 'None',
      ),
      kind,
    );

ShipCrew _member(String id, {bool player = false}) => ShipCrew(
      id: id,
      name: id,
      strength: 3,
      dexterity: 3,
      constitution: 3,
      wisdom: 3,
      health: 40,
      maxHealth: 50,
      isPlayer: player,
    );

ShipState _ship({
  int hull = 100,
  List<ShipWeapon> weapons = const [],
}) =>
    ShipState(
      hull: hull,
      maxHull: 100,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values) room: const RoomState(level: 1)
      },
      weapons: weapons,
      repairsPerRound: 1,
    );

const _gun = ShipWeapon(
    id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 12, chargeTurns: 1);
const _slow = ShipWeapon(
    id: 'slow', name: 'Slow', nameFr: 'Lent', damage: 12, chargeTurns: 9);
const _theirGun = ShipWeapon(
    id: 'enemy_weapon_0',
    name: 'Their gun',
    nameFr: '',
    damage: 10,
    chargeTurns: 1);

/// The four hands start at helm (player), guns (kelda), bulwark (grosh),
/// hold (maren). [dice] gives some of them a die.
ShipBattle _battle(Map<String, CrewDie> dice,
        {ShipState? player, ShipState? enemy}) =>
    ShipBattle(
      player: player ?? _ship(weapons: const [_gun]),
      enemy: enemy ?? _ship(weapons: const [_theirGun]),
      crew: [
        _member('player', player: true),
        _member('kelda'),
        _member('grosh'),
        _member('maren'),
      ],
      random: Random(1),
      rules: ShipBattleRules.classic,
      crewDice: dice,
      diceSeed: 7,
    );

void main() {
  test('a die shows only the faces its room can use', () {
    final die = CrewDie([
      _face(FaceKind.attack, 6),
      _face(FaceKind.defend, 4),
      _face(FaceKind.heal, 5),
      _face(FaceKind.mana, 2),
      _face(FaceKind.stun, 0),
      _face(FaceKind.weaken, 3),
      _face(FaceKind.poison, 3),
      _face(FaceKind.empty, 0),
    ]);
    List<FaceKind> kinds(ShipRoom r) =>
        [for (final f in die.forRoom(r)) f.kind];
    expect(kinds(ShipRoom.guns), [FaceKind.attack, FaceKind.poison]);
    expect(kinds(ShipRoom.bulwark), [FaceKind.defend]);
    expect(kinds(ShipRoom.hold), [FaceKind.heal, FaceKind.mana]);
    expect(kinds(ShipRoom.helm), [FaceKind.stun, FaceKind.weaken]);
  });

  test('the landing depends only on battle, turn, hand and room', () {
    final die =
        CrewDie([for (var i = 0; i < 6; i++) _face(FaceKind.attack, i + 1, i)]);
    final a = rollStationDie(die, 'kelda', ShipRoom.guns, 3, 7);
    final b = rollStationDie(die, 'kelda', ShipRoom.guns, 3, 7);
    expect(a.face, same(b.face));
    // Over many turns every face comes up.
    final seen = {
      for (var t = 1; t <= 60; t++)
        rollStationDie(die, 'kelda', ShipRoom.guns, t, 7).face!.value,
    };
    expect(seen.length, 6);
    // A die with nothing for the room lands blank.
    final blank = rollStationDie(die, 'kelda', ShipRoom.hold, 1, 7);
    expect(blank.face, isNull);
    expect(blank.kind, isNull);
  });

  test('an attack face at the guns lifts the Eel\'s shots', () {
    final dice = {
      'kelda': CrewDie([_face(FaceKind.attack, 20)]),
    };
    final plain = _battle(const {});
    final boosted = _battle(dice);
    expect(boosted.stationGunFactor, closeTo(1.2, 1e-9));
    expect(plain.stationGunFactor, 1.0);
    final base = plain.preview('gun', ShipRoom.guns)!.hullDamage;
    final more = boosted.preview('gun', ShipRoom.guns)!.hullDamage;
    expect(more, greaterThan(base));
  });

  test('a poison face lifts them by half as much', () {
    final b = _battle({
      'kelda': CrewDie([_face(FaceKind.poison, 20)]),
    });
    expect(b.stationGunFactor, closeTo(1.1, 1e-9));
  });

  test('defend at the bulwark and weaken at the helm take a share off', () {
    final b = _battle({
      'grosh': CrewDie([_face(FaceKind.defend, 20)]),
      'player': CrewDie([_face(FaceKind.weaken, 10)]),
    });
    expect(b.stationWardFactor, closeTo(0.8 * 0.9, 1e-9));
  });

  test('a hand moved off their station takes the die with them', () {
    final b = _battle({
      'kelda': CrewDie([_face(FaceKind.attack, 20)]),
    });
    expect(b.stationGunFactor, greaterThan(1.0));
    // Kelda to the hold: the guns are Maren's, with no die.
    b.station('kelda', ShipRoom.hold);
    expect(b.stationGunFactor, 1.0);
    // And in the hold her attack faces are blank.
    expect(b.stationRoll('kelda')!.face, isNull);
  });

  test('a busy hand rolls nothing for the turn', () {
    final b = _battle({
      'kelda': CrewDie([_face(FaceKind.attack, 20)]),
    });
    b.busyRooms = {ShipRoom.guns};
    expect(b.stationGunFactor, 1.0);
  });

  test('a heal face at the hold patches the hull when the round ends', () {
    ShipBattle make(Map<String, CrewDie> dice) =>
        _battle(dice, player: _ship(hull: 50, weapons: const [_gun]));
    final plain = make(const {})..endRound();
    final healed = make({
      'maren': CrewDie([_face(FaceKind.heal, 10)]),
    })
      ..endRound();
    expect(healed.player.hull - plain.player.hull, 5);
    expect(healed.log.any((l) => l.key == 'ship_log_hull_patched' && l.n == 5),
        isTrue);
  });

  test('a mana face at the hold winds the slowest gun a step', () {
    ShipBattle make(Map<String, CrewDie> dice) =>
        _battle(dice, player: _ship(weapons: const [_gun, _slow]));
    final plain = make(const {})..endRound();
    final wound = make({
      'maren': CrewDie([_face(FaceKind.mana, 4)]),
    })
      ..endRound();
    int charge(ShipBattle b) => b.weaponById('slow')!.charge;
    expect(charge(wound) - charge(plain), 1);
  });

  test('a stun face at the helm costs the enemy\'s best gun a step', () {
    final plain = _battle(const {})..startEnemyPhase();
    final stunned = _battle({
      'player': CrewDie([_face(FaceKind.stun, 0)]),
    })
      ..startEnemyPhase();
    expect(plain.enemy.weapons.first.isReady, isTrue);
    expect(stunned.enemy.weapons.first.charge,
        plain.enemy.weapons.first.charge - 1);
    expect(stunned.enemyVolley, isEmpty);
    expect(plain.enemyVolley, isNotEmpty);
    expect(stunned.log.any((l) => l.key == 'ship_log_dice_stun'), isTrue);
  });

  testWidgets('the station die lands on its face and rolls again on a new turn',
      (tester) async {
    final die = CrewDie([
      _face(FaceKind.attack, 9, 0),
      _face(FaceKind.attack, 5, 1),
    ]);
    Widget app(int turn, StationRoll roll) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: StationDie(
                die: die,
                roll: roll,
                turn: turn,
                accent: Colors.teal,
                size: 40,
              ),
            ),
          ),
        );
    final first = rollStationDie(die, 'kelda', ShipRoom.guns, 1, 7);
    await tester.pumpWidget(app(1, first));
    expect(find.byType(Die3D), findsOneWidget);
    // Tumbling to the landed face, then at rest.
    expect(tester.widget<Die3D>(find.byType(Die3D)).rolling, isTrue);
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.widget<Die3D>(find.byType(Die3D)).rolling, isFalse);
    expect(tester.widget<Die3D>(find.byType(Die3D)).faces.first.color,
        FaceKind.attack.color);
    // A new turn tumbles it again.
    await tester
        .pumpWidget(app(2, rollStationDie(die, 'kelda', ShipRoom.guns, 2, 7)));
    expect(tester.widget<Die3D>(find.byType(Die3D)).rolling, isTrue);
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('a room with no face for the die shows a pale blank cube',
      (tester) async {
    final die = CrewDie([_face(FaceKind.attack, 9)]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: StationDie(
            die: die,
            roll: rollStationDie(die, 'kelda', ShipRoom.hold, 1, 7),
            turn: 1,
            accent: Colors.teal,
            still: true,
          ),
        ),
      ),
    ));
    final cube = tester.widget<Die3D>(find.byType(Die3D));
    expect(cube.dim, isTrue);
    expect(cube.fx, isNull);
  });

  testWidgets('on the Eel, a hand with a die has it at their station',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localizedDbProvider(diceSchema)
            .overrideWithValue(const AsyncValue.data({
          'gunner_die': {
            'faces': [
              {'faceName': 'Shot', 'type': 'Attack', 'value': 8},
              {'faceName': 'Guard', 'type': 'Defend', 'value': 4},
            ],
          },
        })),
        localizedDbProvider(companionsSchema)
            .overrideWithValue(const AsyncValue.data({
          'kelda': {'signatureDiceId': 'gunner_die'},
        })),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: _ship(weapons: const [_gun]),
            enemy: _ship(weapons: const [_slow]),
            shipName: 'The Rusty Eel',
            enemyName: 'Raider',
            crew: [_member('player', player: true), _member('kelda')],
            foresight: false,
            random: Random(4),
            rules: const ShipBattleRules(seaEvents: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    // Kelda mans the guns, the player the helm (who has no die here).
    expect(find.byKey(const ValueKey('station_die_kelda')), findsOneWidget);
    expect(find.byKey(const ValueKey('station_die_player')), findsNothing);
    // Her die is on the guns tile.
    expect(
        find.descendant(
            of: find.byKey(const Key('ship_room_eel_guns')),
            matching: find.byKey(const ValueKey('station_die_kelda'))),
        findsOneWidget);
  });
}
