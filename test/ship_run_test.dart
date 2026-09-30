// Running for it at sea (v1.184): far off, with a hand at the helm, the
// Eel turns tail instead of firing, and three turns of it (two with the
// wind behind her) take her out of the fight.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

/// Every roll comes up 0: the enemy always steers, never misses its aim.
class _Zero implements Random {
  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

ShipState _ship({Map<ShipRoom, int> levels = const {}}) => ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values)
          room: RoomState(level: levels[room] ?? 1),
      },
      weapons: const [
        ShipWeapon(
            id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 5, chargeTurns: 1),
      ],
      repairsPerRound: 1,
    );

const _you = ShipCrew(
  id: 'player',
  name: 'You',
  strength: 3,
  dexterity: 3,
  constitution: 3,
  wisdom: 3,
  health: 40,
  maxHealth: 50,
  isPlayer: true,
);

ShipBattle _battle({
  Map<ShipRoom, int> enemyLevels = const {ShipRoom.helm: 0},
  EnemyHabit habit = EnemyHabit.none,
  bool canFlee = true,
}) =>
    ShipBattle(
      player: _ship(),
      enemy: _ship(levels: enemyLevels),
      crew: const [_you],
      random: _Zero(),
      habit: habit,
      rules: const ShipBattleRules(weather: false, seaEvents: false),
      canFlee: canFlee,
    );

void _nextRound(ShipBattle b) {
  b.startEnemyPhase();
  for (final weapon in b.enemyVolley) {
    b.fireEnemy(weapon);
  }
  b.endRound();
}

void main() {
  test('only far off, and three turns of it take the Eel away', () {
    final b = _battle();
    expect(b.canRun, isFalse, reason: 'the ships start at medium range');
    b.range = ShipRange.long;
    expect(b.canRun, isTrue);
    b.runForIt();
    expect(b.escape, 1);
    expect(b.canRun, isFalse, reason: 'once a turn');
    expect(b.canFire(b.player.weapons.first), isFalse,
        reason: 'no gun fires in a turn she runs');
    _nextRound(b);
    b.runForIt();
    expect(b.escape, 2);
    _nextRound(b);
    b.runForIt();
    expect(b.end, BattleEnd.fled);
    expect(b.log.last.key, 'ship_log_fled');
  });

  test('a tailwind carries her two turns of it', () {
    final b = _battle()
      ..range = ShipRange.long
      ..weather = SeaWeather.tailwind;
    b.runForIt();
    expect(b.escape, 2);
    expect(b.busyRooms, isNot(contains(ShipRoom.helm)));
  });

  test('a gun fired this turn, or no helm, means no running', () {
    final fired = _battle()..range = ShipRange.long;
    fired.fired = true;
    expect(fired.canRun, isFalse);

    final story = _battle(canFlee: false)..range = ShipRange.long;
    expect(story.canRun, isFalse);
  });

  test('an enemy that closes the gap sets the run back a turn', () {
    final b =
        _battle(enemyLevels: const {ShipRoom.helm: 3}, habit: EnemyHabit.ram)
          ..range = ShipRange.long;
    b.runForIt();
    expect(b.escape, 1);
    b.startEnemyPhase();
    expect(b.range, ShipRange.medium);
    expect(b.escape, 0);
    expect(b.log.any((l) => l.key == 'ship_log_run_caught'), isTrue);
  });
}
