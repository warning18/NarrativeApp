// The ship battle's rules beyond trading shots (see ship_battle.dart):
// range, weather, shot, aimed shots, focused fire, crew orders, enemy
// habits, leaks, the sea's events and quick orders.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

/// A Random that plays back the rolls it is given, then [fallback].
class _Rolls implements Random {
  _Rolls([this.doubles = const [], this.ints = const []]);

  final List<double> doubles;
  final List<int> ints;
  double fallback = 0.99;
  int _d = 0;
  int _i = 0;

  @override
  double nextDouble() => _d < doubles.length ? doubles[_d++] : fallback;

  @override
  int nextInt(int max) => _i < ints.length ? ints[_i++] % max : 0;

  @override
  bool nextBool() => false;
}

ShipState _ship({
  int hull = 100,
  int maxHull = 100,
  int layers = 0,
  Map<ShipRoom, int> levels = const {},
  List<ShipWeapon> weapons = const [],
  int crew = 1,
}) =>
    ShipState(
      hull: hull,
      maxHull: maxHull,
      layers: layers,
      rooms: {
        for (final room in ShipRoom.values)
          room: RoomState(level: levels[room] ?? 1),
      },
      weapons: weapons,
      repairsPerRound: crew,
    );

const _gun = ShipWeapon(
    id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 12, chargeTurns: 1);
const _gun2 = ShipWeapon(
    id: 'gun2', name: 'Gun 2', nameFr: 'Canon 2', damage: 12, chargeTurns: 1);
const _theirGun = ShipWeapon(
    id: 'enemy_weapon_0',
    name: 'Their gun',
    nameFr: '',
    damage: 10,
    chargeTurns: 1);

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

final _you = _member('player', player: true);

/// No weather, no sea events, no range, no habits, no leaks unless asked.
ShipBattle _battle({
  ShipState? player,
  ShipState? enemy,
  List<ShipCrew>? crew,
  Random? random,
  ShipBattleRules rules = ShipBattleRules.classic,
  EnemyHabit habit = EnemyHabit.none,
  BoardingProfile boarding = const BoardingProfile(),
}) =>
    ShipBattle(
      player: player ?? _ship(weapons: const [_gun]),
      enemy: enemy ??
          _ship(levels: const {ShipRoom.helm: 0}, weapons: const [_theirGun]),
      crew: crew ?? [_you],
      random: random ?? _Rolls(),
      rules: rules,
      habit: habit,
      boarding: boarding,
    );

void main() {
  group('weather', () {
    test('rolls calm, tailwind, crosswind, squall and fog by weight', () {
      expect(weatherFor(0), SeaWeather.calm);
      expect(weatherFor(0.399), SeaWeather.calm);
      expect(weatherFor(0.40), SeaWeather.tailwind);
      expect(weatherFor(0.549), SeaWeather.tailwind);
      expect(weatherFor(0.55), SeaWeather.crosswind);
      expect(weatherFor(0.70), SeaWeather.squall);
      expect(weatherFor(0.85), SeaWeather.fog);
      expect(weatherFor(0.999), SeaWeather.fog);
    });

    test('changes evasion; the Wind-Knot makes a crosswind the Eel\'s', () {
      final ship = _ship(levels: const {ShipRoom.helm: 2});
      int ev(SeaWeather w, {required bool eel, bool knot = false}) =>
          battleEvasion(ship, weather: w, eel: eel, windKnot: knot);
      expect(ev(SeaWeather.calm, eel: true), 16);
      expect(ev(SeaWeather.tailwind, eel: true), 26);
      expect(ev(SeaWeather.tailwind, eel: false), 16);
      expect(ev(SeaWeather.crosswind, eel: true), 26);
      expect(ev(SeaWeather.crosswind, eel: false), 26);
      expect(ev(SeaWeather.crosswind, eel: true, knot: true), 26);
      expect(ev(SeaWeather.crosswind, eel: false, knot: true), 16);
      expect(ev(SeaWeather.fog, eel: false), 21);
      expect(tailwindFor(SeaWeather.crosswind, windKnot: true), isTrue);
      expect(tailwindFor(SeaWeather.crosswind), isFalse);
    });

    test('a squall starts no fire and puts every fire out at round end', () {
      final b = _battle(
          player: _ship(weapons: const [_gun]),
          enemy: _ship(levels: const {ShipRoom.helm: 0, ShipRoom.guns: 3}));
      b.weather = SeaWeather.squall;
      b.ammo = ShipAmmo.heated;
      final shot = b.fire('gun', ShipRoom.guns)!;
      expect(shot.landed, isTrue);
      expect(shot.fireStarted, isFalse);
      // A fire already burning goes out before it burns.
      b.enemy = b.enemy
          .withRoom(ShipRoom.hold, const RoomState(level: 1, onFire: true));
      final hull = b.enemy.hull;
      b.startEnemyPhase();
      b.enemy = b.enemy
          .withRoom(ShipRoom.hold, const RoomState(level: 1, onFire: true));
      b.endRound();
      expect(b.enemy.room(ShipRoom.hold).onFire, isFalse);
      expect(b.enemy.room(ShipRoom.hold).damage, 0);
      expect(b.enemy.hull, hull);
      expect(b.log.any((l) => l.key == 'ship_log_squall_quench'), isTrue);
    });
  });

  group('range', () {
    test('far apart is harder to hit, close is easier, never below 0', () {
      final ship = _ship(levels: const {ShipRoom.helm: 2});
      expect(battleEvasion(ship, range: ShipRange.long, eel: true), 26);
      expect(battleEvasion(ship, range: ShipRange.close, eel: true), 6);
      final dead = _ship(levels: const {ShipRoom.helm: 0});
      expect(battleEvasion(dead, range: ShipRange.close, eel: true), 0);
      final fast = _ship(levels: const {ShipRoom.helm: 6});
      expect(
          battleEvasion(fast,
              range: ShipRange.long, weather: SeaWeather.tailwind, eel: true),
          maxBattleEvasion);
    });

    test('a weapon fires only at the ranges it reaches', () {
      const harpoon = ShipWeapon(
          id: 'harpoon',
          name: 'Harpoon',
          nameFr: '',
          damage: 22,
          chargeTurns: 1,
          ranges: {ShipRange.close, ShipRange.medium});
      final b = _battle(
          player: _ship(weapons: const [harpoon]),
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, habits: false));
      expect(b.canFire(b.player.weapons.single), isTrue);
      b.range = ShipRange.long;
      expect(b.canFire(b.player.weapons.single), isFalse);
      expect(b.fire('harpoon', ShipRoom.guns), isNull);
      expect(b.player.weapons.single.isReady, isTrue,
          reason: 'a weapon out of reach keeps its charge');
    });

    test('the weapon ranges in the data are what the parts say', () {
      final parts = json.decode(
              File('assets/gamedata/ship_parts.json').readAsStringSync())
          as Map<String, dynamic>;
      ShipWeapon weapon(String id) =>
          ShipWeapon.fromPart(id, parts[id] as Map<String, dynamic>);
      expect(weapon('ballista').ranges, ShipRange.values.toSet());
      expect(
          weapon('harpoon_rack').ranges, {ShipRange.close, ShipRange.medium});
      expect(weapon('fire_pots').ranges, {ShipRange.close});
    });

    test('the helm hand closes in once a turn and spends the turn on it', () {
      final b = _battle(
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, habits: false));
      expect(b.stations[ShipRoom.helm], 'player');
      expect(b.helmsman, isNotNull);
      expect(b.canMoveTo(ShipRange.long), isTrue);
      b.maneuver(ShipRange.close);
      expect(b.range, ShipRange.close);
      expect(b.helmsman, isNull, reason: 'busy at the wheel');
      expect(b.canMoveTo(ShipRange.medium), isFalse, reason: 'once a turn');
    });

    test('a tailwind turns her without a hand; no helm hand, no maneuver', () {
      final b = _battle(
          crew: const [],
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, habits: false));
      expect(b.canManeuver, isFalse);
      b.weather = SeaWeather.tailwind;
      expect(b.canManeuver, isTrue);
      final crewed = _battle(
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, habits: false));
      crewed.weather = SeaWeather.tailwind;
      crewed.maneuver(ShipRange.long);
      expect(crewed.helmsman, isNotNull);
    });

    test('an enemy steers toward the range it likes, by its helm', () {
      expect(enemySteerChance(_ship(levels: const {ShipRoom.helm: 1})),
          closeTo(0.3, 1e-9));
      expect(enemySteerChance(_ship(levels: const {ShipRoom.helm: 3})),
          closeTo(0.9, 1e-9));
      expect(enemySteerChance(_ship(levels: const {ShipRoom.helm: 5})),
          closeTo(0.9, 1e-9));
      expect(stepToward(ShipRange.long, ShipRange.close), ShipRange.medium);
      final healthy = _ship();
      final hurt = _ship(hull: 40);
      expect(preferredRange(EnemyHabit.flee, healthy), ShipRange.close);
      expect(preferredRange(EnemyHabit.flee, hurt), ShipRange.long);
      expect(preferredRange(EnemyHabit.marksman, healthy), ShipRange.long);
      expect(preferredRange(EnemyHabit.ram, healthy), ShipRange.close);
      expect(preferredRange(EnemyHabit.boarder, healthy), ShipRange.close);
      expect(preferredRange(EnemyHabit.none, healthy), ShipRange.medium);

      // A marksman at medium range, the steer roll made: it pulls away.
      final rolls = _Rolls();
      final b = _battle(
          enemy: _ship(levels: const {ShipRoom.helm: 2}),
          random: rolls,
          habit: EnemyHabit.marksman,
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      rolls.fallback = 0.1;
      b.startEnemyPhase();
      expect(b.range, ShipRange.long);
    });
  });

  group('shot', () {
    test('chain tears the helm, grape and heated trade hull for effect', () {
      final target = _ship(
          levels: const {ShipRoom.helm: 3, ShipRoom.guns: 3, ShipRoom.hold: 2});
      ShotOutcome shoot(ShipAmmo ammo, ShipRoom room) => resolveShot(
          target: target,
          weapon: _gun,
          room: room,
          evasionPercent: 0,
          roll: 0.5,
          mods: ammoMods(ammo));
      final chain = shoot(ShipAmmo.chain, ShipRoom.guns);
      expect(chain.hullDamage, 6);
      expect(chain.helmDamage, 1);
      expect(chain.target.room(ShipRoom.helm).damage, 1);
      expect(chain.target.room(ShipRoom.guns).damage, 1);
      final onHelm = shoot(ShipAmmo.chain, ShipRoom.helm);
      expect(onHelm.target.room(ShipRoom.helm).damage, 2);
      expect(shoot(ShipAmmo.grape, ShipRoom.guns).hullDamage, 6);
      final heated = shoot(ShipAmmo.heated, ShipRoom.guns);
      expect(heated.hullDamage, 9);
      expect(heated.fireStarted, isTrue);
      expect(shoot(ShipAmmo.round, ShipRoom.guns).hullDamage, 12);
    });

    test('grapeshot costs the enemy a repair for two rounds', () {
      final b = _battle(
          enemy: _ship(
              levels: const {ShipRoom.helm: 0, ShipRoom.guns: 3},
              weapons: const [_theirGun]));
      b.ammo = ShipAmmo.grape;
      b.fire('gun', ShipRoom.guns);
      expect(b.grapeLeft, grapeRounds);
      final damaged = b.enemy.room(ShipRoom.guns).damage;
      b.startEnemyPhase();
      expect(b.enemy.room(ShipRoom.guns).damage, damaged,
          reason: 'a crew of one, cut down: no repair');
      for (final w in b.enemyVolley) {
        b.fireEnemy(w);
      }
      b.endRound();
      expect(b.grapeLeft, 1);
    });
  });

  group('aim and focus', () {
    test('the aim bar: a critical in the middle, wide at the edges', () {
      expect(aimResultFor(0.5), AimResult.perfect);
      expect(aimResultFor(0.62), AimResult.perfect);
      expect(aimResultFor(0.38), AimResult.perfect);
      expect(aimResultFor(0.63), AimResult.steady);
      expect(aimResultFor(0.85), AimResult.steady);
      expect(aimResultFor(0.86), AimResult.wide);
      expect(aimResultFor(0), AimResult.wide);
      expect(aimResultFor(1), AimResult.wide);
    });

    test('a perfect aim cannot be slipped and hits harder; wide misses', () {
      final enemy = _ship(levels: const {ShipRoom.helm: 3, ShipRoom.guns: 4});
      final b = _battle(
          player: _ship(weapons: const [_gun, _gun2]),
          enemy: enemy,
          random: _Rolls([0.0]));
      final perfect = b.fire('gun', ShipRoom.guns, aim: AimResult.perfect)!;
      expect(perfect.landed, isTrue, reason: 'a roll of 0 would slip it');
      expect(perfect.hullDamage, 18);
      expect(perfect.roomDamage, 2);
      final wide = b.fire('gun2', ShipRoom.guns, aim: AimResult.wide)!;
      expect(wide.landed, isFalse);
      expect(b.player.weapons.every((w) => !w.isReady), isTrue);
    });

    test('a room hit again this turn loses an extra pip', () {
      final b = _battle(
          player: _ship(weapons: const [_gun, _gun2]),
          enemy: _ship(levels: const {ShipRoom.helm: 0, ShipRoom.guns: 4}));
      expect(b.preview('gun', ShipRoom.guns)!.roomDamage, 1);
      final first = b.fire('gun', ShipRoom.guns)!;
      expect(first.roomDamage, 1);
      expect(b.preview('gun2', ShipRoom.guns)!.roomDamage, 2);
      final second = b.fire('gun2', ShipRoom.guns)!;
      expect(second.roomDamage, 2);
      expect(b.log.any((l) => l.key == 'ship_log_focus'), isTrue);
    });
  });

  group('crew orders', () {
    test('each crew member has an order; the player calls all hands', () {
      expect(orderFor(_you), CrewOrder.allHands);
      for (final entry in companionOrders.entries) {
        expect(orderFor(_member(entry.key)), entry.value);
      }
      expect(orderFor(_member('stranger')), isNull);
      final companions = json.decode(
              File('assets/gamedata/companions.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(companions.keys.toSet(), companionOrders.keys.toSet(),
          reason: 'every companion gives an order');
    });

    test('all hands mends every damaged room a pip, once a battle', () {
      final b = _battle();
      b.player = b.player
          .withRoom(ShipRoom.guns, const RoomState(level: 2, damage: 2))
          .withRoom(ShipRoom.helm, const RoomState(level: 1, damage: 1));
      expect(b.canOrder(_you), isTrue);
      b.giveOrder(_you);
      expect(b.player.room(ShipRoom.guns).damage, 1);
      expect(b.player.room(ShipRoom.helm).damage, 0);
      expect(b.canOrder(_you), isFalse);
    });

    test('Kelda braces: the volley costs half the hull', () {
      final kelda = _member('kelda');
      final b = _battle(crew: [_you, kelda]);
      b.giveOrder(kelda);
      b.startEnemyPhase();
      final shot = b.fireEnemy(b.enemyVolley.single)!;
      expect(shot.hullDamage, 5);
    });

    test('Vess turns the first shot aside', () {
      final vess = _member('vess');
      final b = _battle(crew: [_you, vess]);
      b.giveOrder(vess);
      b.startEnemyPhase();
      expect(b.fireEnemy(b.enemyVolley.single), isNull);
      expect(b.player.hull, 100);
      expect(b.enemy.weapons.single.isReady, isFalse, reason: 'it fired');
    });

    test('Malrik marks their helmsman; Sable cuts their rigging', () {
      final malrik = _member('malrik');
      final sable = _member('sable');
      final b = _battle(
          crew: [_you, malrik, sable],
          enemy: _ship(levels: const {
            ShipRoom.helm: 3
          }, weapons: const [
            ShipWeapon(
                id: 'e',
                name: 'E',
                nameFr: '',
                damage: 8,
                chargeTurns: 3,
                charge: 2),
          ]));
      expect(b.enemyEvasion, 24);
      b.giveOrder(malrik);
      expect(b.enemyEvasion, 0);
      b.giveOrder(sable);
      expect(b.enemy.weapons.single.charge, 1);
    });

    test('Liora\'s eagle eye makes the next shot a critical, then is spent',
        () {
      final liora = _member('liora');
      final b = _battle(
          crew: [_you, liora],
          player: _ship(weapons: const [_gun, _gun2]),
          enemy: _ship(levels: const {ShipRoom.helm: 3, ShipRoom.guns: 4}),
          random: _Rolls([0.0, 0.0]));
      b.giveOrder(liora);
      final shot = b.fire('gun', ShipRoom.guns)!;
      expect(shot.landed, isTrue);
      expect(shot.hullDamage, 18);
      expect(b.eagleEye, isFalse);
      expect(b.fire('gun2', ShipRoom.guns)!.dodged, isTrue);
    });

    test('Maren blesses the deck; Tobin shores up the bulwark', () {
      final maren = _member('maren');
      final tobin = _member('tobin');
      final b = _battle(crew: [_you, maren, tobin]);
      b.player = b.player
          .withRoom(ShipRoom.hold, const RoomState(level: 1, onFire: true))
          .withRoom(ShipRoom.bulwark, const RoomState(level: 1, damage: 1));
      b.giveOrder(maren);
      expect(b.player.room(ShipRoom.hold).onFire, isFalse);
      expect(b.crew.every((c) => c.health == 50), isTrue);
      b.giveOrder(tobin);
      expect(b.player.room(ShipRoom.bulwark).damage, 0);
      expect(b.player.layers, 1);
    });

    test('Grosh grapples: side by side, shields or not, and they hold', () {
      final grosh = _member('grosh');
      final b = _battle(
          crew: [_you, grosh],
          enemy: _ship(layers: 1, levels: const {ShipRoom.helm: 3}),
          boarding: const BoardingProfile(crew: ['bandit'], chance: 0.3),
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      expect(b.canBoardThem, isFalse);
      b.giveOrder(grosh);
      expect(b.range, ShipRange.close);
      expect(b.canBoardThem, isTrue);
      expect(b.throwGrapples(), isTrue);
    });
  });

  group('enemy habits', () {
    test('a hurt runner far off gets away, unless its helm is out', () {
      final b = _battle(
          enemy: _ship(hull: 30, levels: const {ShipRoom.helm: 2}),
          habit: EnemyHabit.flee,
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      b.range = ShipRange.long;
      b.startEnemyPhase();
      expect(b.end, BattleEnd.escaped);

      final pinned = _battle(
          enemy: _ship(hull: 30, levels: const {ShipRoom.helm: 0}),
          habit: EnemyHabit.flee,
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      pinned.range = ShipRange.long;
      pinned.startEnemyPhase();
      expect(pinned.end, isNull);
    });

    test('a rammer rams once alongside: hull through shields, and a leak', () {
      final b = _battle(
          player: _ship(layers: 1, weapons: const [_gun]),
          enemy: _ship(levels: const {ShipRoom.helm: 1}),
          habit: EnemyHabit.ram,
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      b.range = ShipRange.close;
      b.startEnemyPhase();
      expect(b.player.hull, 100 - ramHullDamage);
      expect(b.player.leaks, 1);
      expect(b.rammed, isTrue);
      b.endRound();
      b.range = ShipRange.close;
      final hull = b.player.hull;
      b.startEnemyPhase();
      expect(b.player.hull, hull, reason: 'once a battle');
    });

    test('a marksman shoots the crew, and hurts them more', () {
      final kelda = _member('kelda');
      final b = _battle(
          crew: [kelda],
          habit: EnemyHabit.marksman,
          rules: const ShipBattleRules(
              range: false, weather: false, seaEvents: false));
      expect(b.plan[_theirGun.id], ShipRoom.helm, reason: 'Kelda stands there');
      b.startEnemyPhase();
      b.fireEnemy(b.enemyVolley.single);
      expect(b.crew.single.health,
          40 - (crewInjuryFor(_theirGun) * marksmanInjuryFactor).round());
    });

    test('a boarder comes over every third round alongside, twice at most', () {
      final b = _battle(
          player: _ship(layers: 1, weapons: const [_gun]),
          habit: EnemyHabit.boarder,
          boarding: const BoardingProfile(crew: ['wisp'], chance: 0),
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      b.range = ShipRange.close;
      expect(b.enemyBoards(), isNull, reason: 'round 1');
      b.turn = 3;
      expect(b.enemyBoards(), isNotNull, reason: 'shields up or not');
      b.turn = 6;
      expect(b.enemyBoards(), isNotNull);
      b.turn = 9;
      expect(b.enemyBoards(), isNull, reason: 'twice at most');
    });

    test('nobody boards across open water', () {
      final b = _battle(
          player: _ship(levels: const {ShipRoom.bulwark: 0}),
          boarding: const BoardingProfile(crew: ['bandit'], chance: 1),
          rules: const ShipBattleRules(weather: false, seaEvents: false));
      expect(bulwarkOpen(b.player), isTrue);
      expect(b.enemyBoards(), isNull, reason: 'medium range');
      b.range = ShipRange.close;
      expect(b.enemyBoards(), isNotNull);
    });

    test('every enemy ship in the data has a habit and a crew to match', () {
      final ships = json.decode(
              File('assets/gamedata/enemy_ships.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final entry in ships.entries) {
        final record = entry.value as Map<String, dynamic>;
        final habit = habitFromName(record['habit']?.toString());
        expect(habit, isNot(EnemyHabit.none), reason: entry.key);
        if (habit == EnemyHabit.boarder) {
          expect(boardingProfileFor(record).canBoard, isTrue);
        }
      }
    });
  });

  group('leaks', () {
    test('a heavy hit on the hold holes it; three leaks at most', () {
      var ship = _ship(levels: const {ShipRoom.hold: 9});
      ShotOutcome hit(int damage) => resolveShot(
          target: ship,
          weapon: ShipWeapon(
              id: 'w', name: 'W', nameFr: '', damage: damage, chargeTurns: 1),
          room: ShipRoom.hold,
          evasionPercent: 0,
          roll: 0.5);
      expect(hit(leakHullThreshold - 1).leakOpened, isFalse);
      for (var i = 0; i < 4; i++) {
        final shot = hit(leakHullThreshold);
        expect(shot.leakOpened, i < maxLeaks);
        ship = shot.target;
      }
      expect(ship.leaks, maxLeaks);
    });

    test('each leak costs hull at the end of the round', () {
      final ship = _ship().copyWith(leaks: 2);
      final result = endRound(ship);
      expect(result.flooded, 2 * leakHullDamagePerRound);
      expect(result.ship.hull, 100 - 2 * leakHullDamagePerRound);
    });

    test('a hold hand bails a leak after the fire, before the repairs', () {
      final hand = _member('hand');
      var ship = _ship().copyWith(leaks: 1).withRoom(
          ShipRoom.hold, const RoomState(level: 2, damage: 1, onFire: true));
      var turn = crewTurn(ship, {ShipRoom.hold: hand});
      expect(turn.work.single.fireOut, isTrue);
      ship = turn.ship;
      turn = crewTurn(ship, {ShipRoom.hold: hand});
      expect(turn.work.single.leakBailed, isTrue);
      expect(turn.ship.leaks, 0);
      turn = crewTurn(turn.ship, {ShipRoom.hold: hand});
      expect(turn.work.single.roomRepaired, isTrue);
    });

    test('the enemy crew plugs a leak after its fires', () {
      final ship = _ship(crew: 2).copyWith(leaks: 1).withRoom(
          ShipRoom.guns, const RoomState(level: 1, damage: 1, onFire: true));
      final result = enemyMaintenance(ship);
      expect(result.firesOut, [ShipRoom.guns]);
      expect(result.leaksPlugged, 1);
      expect(result.repaired, isEmpty);
      expect(enemyMaintenance(ship, penalty: 1).leaksPlugged, 0);
    });
  });

  group('the sea', () {
    ShipBattle calm() => _battle(
        player: _ship(layers: 1, weapons: const [_gun]),
        enemy: _ship(
            hull: 60,
            maxHull: 100,
            layers: 1,
            levels: const {ShipRoom.helm: 0},
            weapons: const [_theirGun]),
        rules: const ShipBattleRules(
            range: false, weather: false, habits: false, flooding: false));

    test('nothing comes in the first round', () {
      final b = calm();
      (b.random as _Rolls).fallback = 0.0;
      b.endRound();
      expect(b.log.any((l) => l.key.startsWith('ship_event_')), isFalse);
    });

    test('a rogue wave takes a layer off both ships', () {
      final b = calm();
      b.turn = 2;
      final rolls = b.random as _Rolls;
      rolls.fallback = 0.0;
      b.endRound();
      expect(b.log.any((l) => l.key == 'ship_event_rogue_wave'), isTrue);
      expect(b.player.layers, 0);
      expect(b.enemy.layers, 0);
    });

    test('a sea creature goes for the ship lower in the water', () {
      final b = _battle(
          enemy: _ship(hull: 60, levels: const {ShipRoom.helm: 0}),
          random: _Rolls([0.0], [1]),
          rules: const ShipBattleRules(
              range: false, weather: false, habits: false, flooding: false));
      b.turn = 2;
      b.endRound();
      expect(b.enemy.hull, 60 - seaCreatureHull);
      expect(b.enemy.room(ShipRoom.hold).damage, 1);
      expect(b.player.hull, 100);
    });

    test('a drifting wreck takes the next enemy shot', () {
      // The enemy's aim takes the first roll; the sea the second.
      final b = _battle(
          random: _Rolls([0.99, 0.0], [2]),
          rules: const ShipBattleRules(
              range: false, weather: false, habits: false, flooding: false));
      b.turn = 2;
      b.endRound();
      expect(b.wreck, isTrue);
      b.startEnemyPhase();
      expect(b.fireEnemy(b.enemyVolley.single), isNull);
      expect(b.player.hull, 100);
      expect(b.wreck, isFalse);
    });
  });

  test('quick orders: +10% evasion against the volley that follows', () {
    final b = _battle(rules: ShipBattleRules.classic);
    final before = b.playerEvasion;
    b.startEnemyPhase(quickOrders: true);
    expect(b.playerEvasion, before + quickOrdersEvasion);
    for (final w in b.enemyVolley) {
      b.fireEnemy(w);
    }
    b.endRound();
    expect(b.playerEvasion, before, reason: 'for that volley only');
  });
}
