// Heat (v2.9.0, docs/simulation/tower-heat.md, the user's call on
// docs/proposals/tower-heat.md): five named curses, each level adding one
// to those below it. Each curse holds at its level and above and not below;
// Heat n + 1 opens with a win at Heat n; the heat and the highest won are
// saved; marks are raised 25% a level; Heat 0 is the climb as it was.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_clans.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

void main() {
  final data = towerDataFromAssets();
  List<TowerFloor> floors(int seed, int heat) =>
      towerFloorsFor(seed, data.enemies, events: towerEventsLive, heat: heat);
  TowerRun start(int seed, int heat, {String profession = 'rogue'}) =>
      towerStart(
          seed: seed,
          raceId: 'human',
          professionId: profession,
          heat: heat,
          data: data);
  TowerRun won(TowerRun run, {int? healthLeft}) => towerAfterFight(run, data,
      won: true, healthLeft: healthLeft ?? run.health);
  TowerReward gift(String clan) =>
      TowerReward(TowerRewardKind.skill, id: 'x', clan: clan);
  bool isPeak(int floor) => towerBudgetOf(floor).kind != TowerFloorKind.fight;
  const seeds = 40;

  test('the five levels: Embers, Smoke, Flame, Pyre, Ash', () {
    expect([for (final l in towerHeatLevels) l.id],
        ['embers', 'smoke', 'flame', 'pyre', 'ash']);
    expect([for (final l in towerHeatLevels) l.heat], [1, 2, 3, 4, 5]);
    expect(towerHeatLevelOf(0), isNull);
    expect(towerHeatLevelOf(3)!.nameKey, 'tower_heat_flame');
    expect(towerHeatLevelOf(5)!.lineKey, 'tower_heat_ash_line');
    expect([for (final l in towerHeatCursesOf(3)) l.id],
        ['embers', 'smoke', 'flame']);
    expect(towerHeatCursesOf(0), isEmpty);
  });

  group('Heat 0 is the climb as it was', () {
    test('the same floors as a run with no heat', () {
      for (var seed = 1; seed <= seeds; seed++) {
        final plain =
            towerFloorsFor(seed, data.enemies, events: towerEventsLive);
        final zero = floors(seed, 0);
        for (var i = 0; i < towerTop; i++) {
          expect(zero[i].extra, plain[i].extra);
          expect(zero[i].affixes, plain[i].affixes);
          expect(zero[i].elite, plain[i].elite);
          expect(zero[i].enemyIds, plain[i].enemyIds);
        }
      }
    });

    test('the bot plays the same run, and saves it the same', () {
      for (var seed = 1; seed <= 3; seed++) {
        final plain = playTowerRun(seed: seed, data: data, events: 2);
        final zero = playTowerRun(seed: seed, data: data, events: 2, heat: 0);
        expect(jsonEncode(zero.toJson()), jsonEncode(plain.toJson()));
        expect(plain.toJson().containsKey('heat'), isFalse);
      }
    });

    test('every lever reads as before', () {
      expect(towerRecoveryShareOf(0), towerRecoveryShare);
      expect(towerBoonFloorsOf(0), towerBoonFloors);
      expect(towerHeatEmptyFloorsOf(0), isEmpty);
      expect(towerPityOathFloorOf(0), towerPityOathFloor);
      expect(towerRivalStandingOf(0), towerRivalStanding);
      expect(towerHeatMarksOf(61, 0), 61);
      for (var f = 1; f <= towerTop; f++) {
        expect(towerHeatScaleOf(0, f), 1.0);
      }
    });
  });

  group('the curses, each at its level and above, not below', () {
    test('Embers: every foe ×1.05, the same foes', () {
      for (var seed = 1; seed <= seeds; seed++) {
        final zero = floors(seed, 0), one = floors(seed, 1);
        for (var i = 0; i < towerTop; i++) {
          expect(one[i].extra, closeTo(zero[i].extra * 1.05, 1e-12));
          expect(one[i].enemyIds, zero[i].enemyIds);
          expect(one[i].affixes, zero[i].affixes);
          expect(one[i].elite, zero[i].elite);
          expect(one[i].heat, 1);
        }
      }
    });

    test('Smoke: one forced affix more on every warden and boss only', () {
      for (var seed = 1; seed <= seeds; seed++) {
        final one = floors(seed, 1), two = floors(seed, 2);
        for (var i = 0; i < towerTop; i++) {
          final floor = i + 1;
          expect(two[i].affixes.length,
              one[i].affixes.length + (isPeak(floor) ? 1 : 0),
              reason: 'seed $seed floor $floor');
          // The affixes the floor had are kept, the new one added after.
          expect(two[i].affixes.take(one[i].affixes.length), one[i].affixes);
          expect(two[i].affixes.toSet(), hasLength(two[i].affixes.length));
        }
        // Wardens 5, 15, 25 and bosses 10, 20, 30.
        expect([
          for (final f in [5, 10, 15, 20, 25, 30]) two[f - 1].affixes
        ], everyElement(isNotEmpty));
      }
    });

    test('Flame: less healing after a floor, from Heat 3', () {
      expect(towerRecoveryShareOf(2), .15);
      expect(towerRecoveryShareOf(3), towerHeatRecoveryShare);
      expect(towerHeatRecoveryShare, lessThan(towerRecoveryShare));
      expect(towerRecoveryShareOf(5), towerHeatRecoveryShare);
      for (var seed = 1; seed <= 10; seed++) {
        int healed(int heat) =>
            won(start(seed, heat).copyWith(floor: 3), healthLeft: 1).health;
        expect(healed(2), healed(0));
        expect(healed(3), lessThan(healed(2)), reason: 'seed $seed');
        expect(healed(5), healed(3));
      }
    });

    test('Flame: Elites +.05 on the ordinary floors 11 to 29 only', () {
      var before = 0, after = 0;
      for (var seed = 1; seed <= 400; seed++) {
        final two = floors(seed, 2), three = floors(seed, 3);
        for (var i = 0; i < towerTop; i++) {
          final floor = i + 1;
          // The same draw: an Elite stays one; a new one only up high.
          if (two[i].elite) expect(three[i].elite, isTrue);
          if (floor < towerHeatUpperFloor || isPeak(floor)) {
            expect(three[i].elite, two[i].elite, reason: 'floor $floor');
          }
          if (two[i].elite) before++;
          if (three[i].elite) after++;
        }
      }
      expect(after, greaterThan(before));
      expect(towerEliteChanceOf(3, 12, .12), closeTo(.17, 1e-12));
      expect(towerEliteChanceOf(2, 12, .12), .12);
      expect(towerEliteChanceOf(5, 10, .12), .12);
    });

    test('Pyre: floors 13 and 23 give nothing, from Heat 4', () {
      expect(towerBoonFloorsOf(3), towerBoonFloors);
      expect(towerBoonFloorsOf(4), {5, 10, 15, 20, 25, 28});
      expect(towerHeatEmptyFloorsOf(3), isEmpty);
      expect(towerHeatEmptyFloorsOf(4), {13, 23});
      expect(towerHeatEmptyFloorsOf(5), {13, 23});
      bool boon(TowerRun run) =>
          run.offer.isNotEmpty &&
          run.offer.every((r) => r.clan.isEmpty) &&
          run.offer.any((r) =>
              r.kind == TowerRewardKind.die || r.kind == TowerRewardKind.spell);
      for (var seed = 1; seed <= 10; seed++) {
        for (final floor in [13, 23]) {
          final run = start(seed, 3).copyWith(floor: floor, taken: {
            1: const TowerReward(TowerRewardKind.clanOath, id: 'mire'),
          });
          expect(boon(won(run)), isTrue, reason: 'seed $seed floor $floor');
          // Option (a): no clan's offer in the boon's place either, nor the
          // late oath (an oath still open, standing to swear).
          for (final taken in [
            {1: const TowerReward(TowerRewardKind.clanOath, id: 'mire')},
            {1: gift('mire'), 2: gift('mire')},
          ]) {
            final pyre =
                won(start(seed, 4).copyWith(floor: floor, taken: taken));
            expect(pyre.offer, isEmpty, reason: 'seed $seed floor $floor');
          }
        }
        // The floors around them deal as at Heat 3.
        for (final floor in [12, 14, 22, 24]) {
          final taken = {1: gift('mire'), 2: gift('mire')};
          expect(
              won(start(seed, 4).copyWith(floor: floor, taken: taken))
                  .offer
                  .length,
              won(start(seed, 3).copyWith(floor: floor, taken: taken))
                  .offer
                  .length,
              reason: 'seed $seed floor $floor');
        }
      }
    });

    test('Pyre: the late oath from floor 18, not 15', () {
      expect(towerPityOathFloorOf(3), 15);
      expect(towerPityOathFloorOf(4), 18);
      List<TowerReward> oaths(int heat, int floor, int seed) =>
          won(start(seed, heat).copyWith(
                  floor: floor, taken: {1: gift('mire'), 2: gift('mire')}))
              .offer
              .where((r) => r.kind == TowerRewardKind.clanOath)
              .toList();
      for (var seed = 1; seed <= 5; seed++) {
        for (final floor in [16, 17]) {
          expect(oaths(3, floor, seed), hasLength(1));
          expect(oaths(4, floor, seed), isEmpty, reason: 'floor $floor');
        }
        for (final floor in [18, 19]) {
          expect(oaths(4, floor, seed),
              [const TowerReward(TowerRewardKind.clanOath, id: 'mire')]);
        }
      }
    });

    test('Ash: the upper Tower fiercer, and a gift costs each rival 2', () {
      for (var seed = 1; seed <= seeds; seed++) {
        final zero = floors(seed, 0), four = floors(seed, 4);
        final five = floors(seed, 5);
        for (var i = 0; i < towerTop; i++) {
          final floor = i + 1;
          expect(four[i].extra, closeTo(zero[i].extra * 1.05, 1e-12));
          expect(
              five[i].extra,
              closeTo(
                  zero[i].extra *
                      (floor >= towerHeatUpperFloor
                          ? towerHeatAshFoeScale
                          : towerHeatFoeScale),
                  1e-12),
              reason: 'floor $floor');
          expect(five[i].enemyIds, zero[i].enemyIds);
        }
      }
      expect(towerClanRipple('dominion', data.clans, heat: 4), {
        'dominion': 2,
        'vigil': -1,
        'mire': -1,
        'crows': 1,
        'penitents': -1
      });
      expect(towerClanRipple('dominion', data.clans, heat: 5), {
        'dominion': 2,
        'vigil': -2,
        'mire': -2,
        'crows': 1,
        'penitents': -2
      });
      // A run's standing reads its heat.
      final cards = {1: gift('mire'), 2: gift('dominion')};
      final four = start(1, 4).copyWith(taken: cards);
      final five = start(1, 5).copyWith(taken: cards);
      expect(towerStandingOf(four, data)['mire'], 1);
      expect(towerStandingOf(five, data)['mire'], 0);
    });

    test('the curses add up: Ash carries all five', () {
      for (var seed = 1; seed <= seeds; seed++) {
        final zero = floors(seed, 0), five = floors(seed, 5);
        for (var i = 0; i < towerTop; i++) {
          final floor = i + 1;
          expect(five[i].affixes.length,
              zero[i].affixes.length + (isPeak(floor) ? 1 : 0));
          if (zero[i].elite) expect(five[i].elite, isTrue);
        }
      }
      expect(towerRecoveryShareOf(5), towerHeatRecoveryShare);
      expect(towerBoonFloorsOf(5), isNot(contains(13)));
      expect(towerBoonFloorsOf(5), isNot(contains(23)));
      expect(towerHeatEmptyFloorsOf(5), towerHeatCutBoons);
      expect(towerPityOathFloorOf(5), towerHeatPityOathFloor);
      expect(towerRivalStandingOf(5), towerHeatRivalStanding);
    });
  });

  group('marks', () {
    test('+25% a level, rounded down', () {
      for (var heat = 0; heat <= towerHeatMax; heat++) {
        expect(towerMarksOf(towerTop, 0, heat: heat),
            (61 * (1 + .25 * heat)).floor());
      }
      expect(towerMarksOf(towerTop, 0, heat: 1), 76);
      expect(towerMarksOf(towerTop, 0, heat: 5), 137);
      expect(towerMarksOf(11, 0, heat: 2), 27);
      expect(towerHeatMarksFactor(3), 1.75);
    });

    test('a run earns them at its heat, the stores taken after', () {
      final run = start(3, 2).copyWith(floor: 12, marksSpent: 4);
      expect(run.marksEarned, towerMarksOf(11, 0, heat: 2));
      expect(run.marks, run.marksEarned - 4);
    });
  });

  group('the unlock rule', () {
    TowerRun ended(int heat, TowerStatus status) =>
        start(1, heat).copyWith(status: status, floor: towerTop);

    test('Heat n + 1 opens after a win at Heat n', () {
      var p = const TowerProgress();
      expect(p.heatWon, -1);
      expect(p.heatOpen, 0);
      expect(p.heatsOpen, [0]);
      expect(p.isHeatOpen(1), isFalse);
      p = p.afterRun(ended(0, TowerStatus.dead));
      expect(p.heatOpen, 0);
      p = p.afterRun(ended(0, TowerStatus.won));
      expect(p.heatWon, 0);
      expect(p.heatsOpen, [0, 1]);
      p = p.afterRun(ended(1, TowerStatus.won));
      expect(p.heatOpen, 2);
      // A win lower down never closes a level.
      p = p.afterRun(ended(0, TowerStatus.won));
      expect(p.heatOpen, 2);
      for (var h = 2; h <= towerHeatMax; h++) {
        p = p.afterRun(ended(h, TowerStatus.won));
      }
      expect(p.heatWon, 5);
      expect(p.heatOpen, towerHeatMax);
      expect(p.heatsOpen, [0, 1, 2, 3, 4, 5]);
    });

    test('an abandoned or lost climb opens nothing', () {
      var p = const TowerProgress(heatWon: 1);
      p = p.afterRun(ended(2, TowerStatus.abandoned));
      p = p.afterRun(ended(2, TowerStatus.dead));
      expect(p.heatOpen, 2);
    });
  });

  group('saves', () {
    test('a run keeps its heat; one saved before is Heat 0', () {
      for (var heat = 0; heat <= towerHeatMax; heat++) {
        final run = start(5, heat);
        final again = TowerRun.fromJson(
            jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
        expect(again.heat, heat);
        expect(again.copyWith(floor: 4).heat, heat);
      }
      final old = start(5, 3).toJson()..remove('heat');
      expect(TowerRun.fromJson(old).heat, 0);
      expect(start(5, 9).heat, towerHeatMax);
    });

    test('the record keeps the highest won; an old one with a win opens 1', () {
      const p = TowerProgress(wins: 3, heatWon: 2);
      expect(TowerProgress.fromJson(p.toJson()).heatWon, 2);
      expect(const TowerProgress().toJson().containsKey('heatWon'), isFalse);
      expect(TowerProgress.fromJson({'marks': 4}).heatWon, -1);
      final old = TowerProgress.fromJson({'marks': 4, 'wins': 1});
      expect(old.heatWon, 0);
      expect(old.heatOpen, 1);
    });
  });

  test('the bot climbs at a given heat', () {
    final run = playTowerRun(seed: 2, data: data, events: 2, heat: 4);
    expect(run.heat, 4);
    expect(run.isOver, isTrue);
    expect(run.marksEarned,
        towerMarksOf(run.heightCleared, run.refused.length, heat: 4));
  });
}
