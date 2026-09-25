// A Monte Carlo of whole ship battles on the real data: the Rusty Eel as
// she is fitted at three points of the game against every enemy ship,
// under the battle before v1.153 (classic rules, a plain player) and the
// battle now (every rule, a player who uses the tools: range, shot,
// aim, orders, quick orders, focused fire). The deck fights of a boarding
// are a coin weighted to what the dice fights give at the rail.
//
// The new battle must stay winnable where the old one was, and not turn
// into a walkover either: each pairing's win rate stays within a band of
// the old one's, and the plain player under the new rules (who ignores
// every new tool) still wins most early fights.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The player wins a deck fight at the rail this often (more with a hand
/// in the hold when boarders come over).
const double _deckWin = 0.6;
const double _deckWinHoldManned = 0.7;

ShipCrew _crew(String id, {bool player = false, int dex = 3, int str = 3}) =>
    ShipCrew(
      id: id,
      name: id,
      strength: str,
      dexterity: dex,
      constitution: 3,
      wisdom: 3,
      health: 60,
      maxHealth: 60,
      isPlayer: player,
    );

class _Fitting {
  const _Fitting(this.name, this.parts, this.crew);
  final String name;
  final List<String> parts;
  final List<ShipCrew> crew;
}

final _fittings = [
  _Fitting('early', const [
    'ballista'
  ], [
    _crew('player', player: true, dex: 4),
    _crew('kelda', str: 5),
  ]),
  _Fitting('mid', const [
    'ballista',
    'harpoon_rack',
    'iron_plating'
  ], [
    _crew('player', player: true, dex: 4),
    _crew('kelda', str: 5),
    _crew('liora', dex: 6),
  ]),
  _Fitting('late', const [
    'harpoon_rack',
    'fire_pots',
    'iron_plating',
    'tar_sealed_hull'
  ], [
    _crew('player', player: true, dex: 4),
    _crew('grosh', str: 6),
    _crew('maren'),
    _crew('vess'),
  ]),
];

class _Tally {
  int won = 0, lost = 0, escaped = 0, boarded = 0, rounds = 0, hull = 0;
  int n = 0;
  double get winRate => won / max(1, n);
  @override
  String toString() => 'win ${(100 * winRate).toStringAsFixed(0).padLeft(3)}%'
      ' lost ${(100 * lost / n).toStringAsFixed(0).padLeft(3)}%'
      ' fled ${(100 * escaped / n).toStringAsFixed(0).padLeft(3)}%'
      ' boarded ${(100 * boarded / n).toStringAsFixed(0).padLeft(3)}%'
      ' rounds ${(rounds / n).toStringAsFixed(1).padLeft(4)}'
      ' hull left ${(hull / n).toStringAsFixed(0).padLeft(3)}%';
}

/// Plays one battle to the end. [tools]: the player uses the new tools.
BattleEnd _play({
  required ShipBattle b,
  required Random rng,
  required bool tools,
  required bool timed,
}) {
  for (var guard = 0; guard < 60 && !b.over; guard++) {
    b.autoStation();
    if (tools) _orders(b);
    _maneuver(b, tools: tools);
    if (tools) b.ammo = _ammoFor(b);
    // Fire every ready weapon at one room: focused fire.
    final room = _targetRoom(b);
    for (final w in List.of(b.player.weapons)) {
      if (b.over || !b.canFire(w)) continue;
      AimResult? aim;
      if (tools && rng.nextDouble() < 0.5) {
        final r = rng.nextDouble();
        aim = r < 0.4
            ? AimResult.perfect
            : r < 0.85
                ? AimResult.steady
                : AimResult.wide;
      }
      b.fire(w.id, room, aim: aim);
    }
    if (b.over) break;
    if (b.canBoardThem) {
      if (b.throwGrapples()) {
        if (rng.nextDouble() < _deckWin) {
          b.boardingWon();
          break;
        }
        b.boardingLost();
      }
    }
    b.startEnemyPhase(quickOrders: tools && timed && rng.nextDouble() < 0.6);
    if (b.over) break;
    for (final w in b.enemyVolley) {
      b.fireEnemy(w);
      if (b.over) break;
    }
    if (b.over) break;
    final manned = b.enemyBoards();
    if (manned != null) {
      if (rng.nextDouble() < (manned ? _deckWinHoldManned : _deckWin)) {
        b.boardersRepelled();
      } else {
        b.boardersWon();
      }
    }
    b.endRound();
  }
  return b.end ?? BattleEnd.lost;
}

void _orders(ShipBattle b) {
  final threat = b.enemy.weapons
      .where((w) => readyNextTurn(w, b.enemy) && b.inRange(w))
      .fold<int>(0, (sum, w) => sum + w.damage);
  for (final c in List.of(b.crew)) {
    if (!b.canOrder(c)) continue;
    final use = switch (orderFor(c)!) {
      CrewOrder.allHands =>
        b.player.rooms.values.where((r) => r.damage > 0).length >= 2,
      CrewOrder.brace => threat >= 14,
      CrewOrder.voidWard => threat >= 10,
      CrewOrder.bless => b.player.rooms.values.any((r) => r.onFire) ||
          b.crew.any((m) => m.health * 2 < m.maxHealth),
      CrewOrder.shoreUp => b.player.layers == 0,
      CrewOrder.markHelm =>
        b.enemyEvasion >= 20 && b.player.weapons.any(b.canFire),
      CrewOrder.cutRigging => threat >= 10,
      CrewOrder.eagleEye =>
        b.player.weapons.any((w) => b.canFire(w) && w.damage >= 20),
      CrewOrder.grapple => b.enemy.hull * 2 < b.enemy.maxHull,
    };
    if (use) b.giveOrder(c);
  }
}

/// The range the player steers for: where a ready weapon reaches, and
/// side by side when the enemy's rail is open to board. With [tools]: after
/// a fleeing ship, and off a rammer's line until it has rammed.
void _maneuver(ShipBattle b, {required bool tools}) {
  if (!b.rules.range) return;
  ShipRange? want;
  final outOfReach = [
    for (final w in b.player.weapons)
      if (w.isReady && !b.inRange(w)) w,
  ];
  if (outOfReach.isNotEmpty) {
    final w = outOfReach.first;
    want = ShipRange.values.where(w.reaches).reduce((a, c) =>
        (a.index - b.range.index).abs() <= (c.index - b.range.index).abs()
            ? a
            : c);
  } else if (b.boarding.canBoard &&
      !b.boardingSpent &&
      (bulwarkOpen(b.enemy) ||
          b.player.weapons
                  .where((w) => w.isReady && w.reaches(ShipRange.close))
                  .length >=
              max(b.enemy.layers, b.enemy.room(ShipRoom.bulwark).working))) {
    // The rail is open, or this turn's shots will break it open: come
    // alongside to board.
    want = ShipRange.close;
  } else if (tools && b.habit == EnemyHabit.flee && isFleeing(b.enemy)) {
    want = ShipRange.close;
  } else if (tools &&
      b.habit == EnemyHabit.ram &&
      !b.rammed &&
      b.range == ShipRange.close) {
    want = ShipRange.medium;
  }
  if (want == null || want == b.range) return;
  final to = stepToward(b.range, want);
  if (b.canMoveTo(to)) b.maneuver(to);
}

ShipAmmo _ammoFor(ShipBattle b) {
  final helm = b.enemy.room(ShipRoom.helm);
  if ((b.habit == EnemyHabit.flee || b.habit == EnemyHabit.marksman) &&
      !helm.isDown) {
    return ShipAmmo.chain;
  }
  if (b.enemy.repairsPerRound >= 2 && b.grapeLeft == 0) return ShipAmmo.grape;
  return ShipAmmo.round;
}

ShipRoom _targetRoom(ShipBattle b) {
  for (final room in [ShipRoom.guns, ShipRoom.helm, ShipRoom.bulwark]) {
    if (!b.enemy.room(room).isDown) return room;
  }
  return ShipRoom.hold;
}

Map<String, Map<String, _Tally>> _run({
  required ShipBattleRules rules,
  required bool tools,
  required int battles,
}) {
  final ships = _data('ships');
  final parts = _data('ship_parts');
  final enemies = _data('enemy_ships');
  final eel = ships['rusty_eel'] as Map<String, dynamic>;
  final results = <String, Map<String, _Tally>>{};
  for (final fitting in _fittings) {
    for (final entry in enemies.entries) {
      final record = entry.value as Map<String, dynamic>;
      final tally = _Tally();
      for (var seed = 0; seed < battles; seed++) {
        final rng = Random(seed * 7919 + 17);
        final b = ShipBattle(
          player: buildPlayerShip(
              ship: eel,
              parts: parts,
              installedPartIds: fitting.parts,
              currentHull: -1),
          enemy: buildEnemyShip(record),
          crew: fitting.crew,
          random: Random(seed),
          boarding: boardingProfileFor(record),
          habit: habitFromName(record['habit']?.toString()),
          rules: rules,
        );
        final end = _play(b: b, rng: rng, tools: tools, timed: true);
        tally.n++;
        tally.rounds += b.turn;
        switch (end) {
          case BattleEnd.won:
            tally.won++;
            tally.hull += 100 * b.player.hull ~/ b.player.maxHull;
          case BattleEnd.boarded:
            tally.won++;
            tally.boarded++;
            tally.hull += 100 * b.player.hull ~/ b.player.maxHull;
          case BattleEnd.escaped:
            tally.escaped++;
            tally.hull += 100 * b.player.hull ~/ b.player.maxHull;
          case BattleEnd.lost:
            tally.lost++;
        }
      }
      (results[fitting.name] ??= {})[entry.key] = tally;
    }
  }
  return results;
}

void main() {
  const battles = 400;
  late final Map<String, Map<String, _Tally>> classic;
  late final Map<String, Map<String, _Tally>> plain;
  late final Map<String, Map<String, _Tally>> skilled;

  setUpAll(() {
    classic =
        _run(rules: ShipBattleRules.classic, tools: false, battles: battles);
    plain =
        _run(rules: const ShipBattleRules(), tools: false, battles: battles);
    skilled =
        _run(rules: const ShipBattleRules(), tools: true, battles: battles);
    final out = StringBuffer();
    for (final fitting in classic.keys) {
      for (final enemy in classic[fitting]!.keys) {
        out
          ..writeln('$fitting vs $enemy')
          ..writeln('  classic  ${classic[fitting]![enemy]}')
          ..writeln('  plain    ${plain[fitting]![enemy]}')
          ..writeln('  skilled  ${skilled[fitting]![enemy]}');
      }
    }
    // ignore: avoid_print
    print(out);
  });

  test('the new battle stays within reach of the old one', () {
    for (final fitting in classic.keys) {
      for (final enemy in classic[fitting]!.keys) {
        final old = classic[fitting]![enemy]!.winRate;
        final now = skilled[fitting]![enemy]!.winRate;
        expect(now, greaterThanOrEqualTo(old - 0.15),
            reason: '$fitting vs $enemy: $now vs $old before');
        expect(now, lessThanOrEqualTo(old + 0.30),
            reason: '$fitting vs $enemy: $now vs $old before');
      }
    }
  });

  test('a player who ignores the new tools still wins the early fights', () {
    expect(
        plain['early']!['raider_skiff']!.winRate +
            plain['early']!['raider_skiff']!.escaped / battles,
        greaterThan(0.5));
  });
}
