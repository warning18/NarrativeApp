// A Monte Carlo of the sea beasts (v1.185) on the real data: the Rusty Eel
// as she is fitted when each beast's waters open, meeting it the first time
// (fighting to the end, or running at once) and hunting it later with the
// Harbor's harpoon, the wounds of an earlier meeting and the crew's edge.
//
// The first meeting is one to live through, not to win: running must
// work, and staying to fight a Leviathan or a Tide-Mother must cost. The
// hunt, prepared, must be winnable, and the harpoon must be what makes it
// so. The deck fights with the Tide-Mother's arms are a coin weighted to
// what the dice fights give at the rail.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/sea_beasts.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

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

final _midCrew = [
  _crew('player', player: true, dex: 4),
  _crew('kelda', str: 5),
  _crew('liora', dex: 6),
];
final _lateCrew = [
  _crew('player', player: true, dex: 4),
  _crew('grosh', str: 6),
  _crew('maren'),
  _crew('kelda'),
];

/// Where each beast is met: the fitting of those waters, the one a hunter
/// takes out (the harpoon in place of a gun), and the crew.
class _Waters {
  const _Waters(this.beast, this.fitting, this.hunting, this.crew);
  final String beast;
  final List<String> fitting;
  final List<String> hunting;
  final List<ShipCrew> crew;
}

final _waters = [
  _Waters('brinejaw', const ['ballista', 'harpoon_rack', 'iron_plating'],
      const ['ballista', 'hunters_harpoon', 'iron_plating'], _midCrew),
  _Waters(
      'pale_leviathan',
      const ['harpoon_rack', 'fire_pots', 'iron_plating', 'tar_sealed_hull'],
      const [
        'hunters_harpoon',
        'harpoon_rack',
        'iron_plating',
        'tar_sealed_hull'
      ],
      _lateCrew),
  _Waters(
      'tide_kraken',
      const ['harpoon_rack', 'fire_pots', 'iron_plating', 'tar_sealed_hull'],
      const [
        'hunters_harpoon',
        'harpoon_rack',
        'leviathan_bone_plating',
        'sharkskin_hull'
      ],
      _lateCrew),
];

class _Tally {
  int won = 0, lost = 0, escaped = 0, fled = 0, n = 0;
  double get winRate => won / n;
  double get fledRate => fled / n;
  double get lostRate => lost / n;
  @override
  String toString() => 'win ${(100 * won / n).round()}%'
      ' beast away ${(100 * escaped / n).round()}%'
      ' lost ${(100 * lost / n).round()}%'
      ' ran ${(100 * fled / n).round()}%';
}

/// Fights [battles] battles with the beast: [runAtOnce] turns tail from
/// the first turn; otherwise the crew fights to the end, stopping its heart
/// first, going for its fins with chain shot once it turns to flee, and
/// loosing the harpoon before anything else.
_Tally _meet(
  _Waters waters, {
  required List<String> parts,
  required BeastState state,
  required bool hunt,
  bool runAtOnce = false,
  int battles = 300,
}) {
  final record = _data('enemy_ships')[waters.beast] as Map<String, dynamic>;
  final eel = _data('ships')['rusty_eel'] as Map<String, dynamic>;
  final allParts = _data('ship_parts');
  final tally = _Tally();
  for (var seed = 0; seed < battles; seed++) {
    final rng = Random(seed * 31 + 7);
    final enemy = buildEnemyShip(record);
    final b = ShipBattle(
      player: buildPlayerShip(
          ship: eel, parts: allParts, installedPartIds: parts, currentHull: -1),
      enemy: enemy.copyWith(hull: beastStartHull(enemy.maxHull, state)),
      crew: waters.crew,
      random: Random(seed),
      boarding: boardingProfileFor(record),
      habit: habitFromName(record['habit']?.toString()),
      beast:
          BeastProfile.fromRecord(record, edge: beastEdge(state, hunt: hunt)),
    );
    for (var guard = 0; guard < 60 && !b.over; guard++) {
      b.autoStation();
      _orders(b);
      if (runAtOnce) {
        final away = stepToward(b.range, ShipRange.long);
        if (b.range != ShipRange.long && b.canMoveTo(away)) {
          b.maneuver(away);
        } else if (b.canRun) {
          b.runForIt();
        }
      } else {
        _reach(b);
        _volley(b, rng);
      }
      if (b.over) break;
      b.startEnemyPhase(quickOrders: rng.nextDouble() < 0.5);
      if (b.over) break;
      for (final w in b.enemyVolley) {
        b.fireEnemy(w);
        if (b.over) break;
      }
      if (b.over) break;
      final manned = b.enemyBoards();
      if (manned != null) {
        if (rng.nextDouble() < (manned ? 0.65 : 0.55)) {
          b.boardersRepelled();
        } else {
          b.boardersWon();
        }
      }
      b.endRound();
    }
    tally.n++;
    switch (b.end ?? BattleEnd.lost) {
      case BattleEnd.won || BattleEnd.boarded:
        tally.won++;
      case BattleEnd.lost:
        tally.lost++;
      case BattleEnd.escaped:
        tally.escaped++;
      case BattleEnd.fled:
        tally.fled++;
    }
  }
  return tally;
}

void _orders(ShipBattle b) {
  final threat = b.enemy.weapons
      .where((w) => readyNextTurn(w, b.enemy) && b.inRange(w))
      .fold<int>(0, (sum, w) => sum + w.damage);
  for (final c in List.of(b.crew)) {
    // A hand goes to their order's room to give it, as a player would.
    if (!b.orderWorks(c)) continue;
    final use = switch (orderFor(c)!) {
      CrewOrder.allHands =>
        b.player.rooms.values.where((r) => r.damage > 0).length >= 2,
      CrewOrder.brace => threat >= 14 || b.roundsToDive == 0,
      CrewOrder.voidWard => threat >= 10,
      CrewOrder.bless => b.player.rooms.values.any((r) => r.onFire) ||
          b.crew.any((m) => m.health * 2 < m.maxHealth),
      CrewOrder.shoreUp => b.player.layers == 0,
      CrewOrder.markHelm => b.enemyEvasion >= 20 && b.anyShotReady,
      CrewOrder.cutRigging => threat >= 10,
      CrewOrder.eagleEye =>
        b.player.weapons.any((w) => b.canFire(w) && w.damage >= 20),
      CrewOrder.grapple => false,
    };
    if (use) b.orderFromStation(c);
  }
}

/// Steers to where a ready weapon reaches.
void _reach(ShipBattle b) {
  final out = [
    for (final w in b.player.weapons)
      if (w.isReady && !b.inRange(w)) w,
  ];
  if (out.isEmpty) return;
  final want = ShipRange.values.where(out.first.reaches).reduce((a, c) =>
      (a.index - b.range.index).abs() <= (c.index - b.range.index).abs()
          ? a
          : c);
  final to = stepToward(b.range, want);
  if (b.canMoveTo(to)) b.maneuver(to);
}

void _volley(ShipBattle b, Random rng) {
  final fins = b.enemy.room(ShipRoom.helm);
  ShipRoom room;
  // Each weapon fires its own shot (ship_parts.json `ammo`).
  if (b.beastTurning && !b.tethered && !fins.isDown) {
    room = ShipRoom.helm;
  } else {
    room = [
      ShipRoom.hold,
      ShipRoom.guns,
      ShipRoom.helm
    ].firstWhere((r) => !b.enemy.room(r).isDown, orElse: () => ShipRoom.helm);
  }
  final weapons = List.of(b.player.weapons)
    ..sort((a, c) => c.tetherRounds.compareTo(a.tetherRounds));
  for (final w in weapons) {
    if (b.over || !b.canFire(w)) continue;
    AimResult? aim;
    if (rng.nextDouble() < 0.5) {
      final r = rng.nextDouble();
      aim = r < 0.4
          ? AimResult.perfect
          : r < 0.85
              ? AimResult.steady
              : AimResult.wide;
    }
    b.fire(w.id, room, aim: aim);
  }
}

void main() {
  final first = <String, _Tally>{};
  final ran = <String, _Tally>{};
  final hunted = <String, _Tally>{};
  final huntedBare = <String, _Tally>{};

  setUpAll(() {
    final out = StringBuffer();
    for (final w in _waters) {
      final maxHull = (_data('enemy_ships')[w.beast]
          as Map<String, dynamic>)['maxHull'] as int;
      // A hunt after one meeting that left it as wounded as it can be.
      final scarred = BeastState(
          seen: true, encounters: 1, wounds: (maxHull * maxWoundShare).round());
      first[w.beast] =
          _meet(w, parts: w.fitting, state: const BeastState(), hunt: false);
      ran[w.beast] = _meet(w,
          parts: w.fitting,
          state: const BeastState(),
          hunt: false,
          runAtOnce: true);
      hunted[w.beast] = _meet(w, parts: w.hunting, state: scarred, hunt: true);
      huntedBare[w.beast] =
          _meet(w, parts: w.fitting, state: scarred, hunt: true);
      out
        ..writeln(w.beast)
        ..writeln('  first meeting, fought  ${first[w.beast]}')
        ..writeln('  first meeting, ran     ${ran[w.beast]}')
        ..writeln('  hunt with the harpoon  ${hunted[w.beast]}')
        ..writeln('  hunt without it        ${huntedBare[w.beast]}');
    }
    // ignore: avoid_print
    print(out);
  });

  test('running from a beast at once gets the Eel away', () {
    for (final w in _waters) {
      expect(ran[w.beast]!.fledRate, greaterThanOrEqualTo(0.9),
          reason: w.beast);
    }
  });

  test('the first meeting is one to live through, not to win', () {
    for (final w in _waters) {
      expect(first[w.beast]!.winRate, lessThanOrEqualTo(0.65), reason: w.beast);
    }
    for (final id in ['pale_leviathan', 'tide_kraken']) {
      expect(first[id]!.lostRate, greaterThanOrEqualTo(0.5), reason: id);
    }
  });

  test('a prepared hunt is winnable, and the harpoon is what makes it so', () {
    for (final w in _waters) {
      final hunt = hunted[w.beast]!;
      expect(hunt.winRate, inInclusiveRange(0.6, 0.99), reason: w.beast);
      expect(hunt.winRate, greaterThan(huntedBare[w.beast]!.winRate),
          reason: '${w.beast}: the harpoon helps');
    }
  });
}
