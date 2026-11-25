// QA guard (v2.9.0, Tower Heat: Embers, Smoke, Flame, Pyre, Ash). Written
// from the changelog's numbers, not from Core's constants, so a retune of
// either is seen: each level applies its curse and every curse below it, and
// no curse below its level; the marks rise a quarter a level; a win at Heat n
// opens Heat n + 1 (and a loss, or a lower win, opens nothing); a Heat not
// open starts at the highest open one; and the bot's top falls from Heat to
// Heat while every Heat can still be won.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

void main() {
  final data = towerDataFromAssets();
  const seeds = 60;
  const heats = [0, 1, 2, 3, 4, 5];
  List<TowerFloor> floors(int seed, int heat) =>
      towerFloorsFor(seed, data.enemies, events: towerEventsLive, heat: heat);
  bool peak(int floor) => towerBudgetOf(floor).kind != TowerFloorKind.fight;

  test('five levels, in order, each with a name and a curse line', () {
    expect([for (final l in towerHeatLevels) l.id],
        ['embers', 'smoke', 'flame', 'pyre', 'ash']);
    expect([for (final l in towerHeatLevels) l.heat], [1, 2, 3, 4, 5]);
    expect(towerHeatMax, 5);
    for (final h in heats) {
      expect([
        for (final l in towerHeatCursesOf(h)) l.heat
      ], [
        for (var i = 1; i <= h; i++) i
      ], reason: 'Heat $h carries the curses of the levels up to it');
    }
  });

  test('Embers and Ash: the foes x1.05 from Heat 1, x1.12 from floor 11 at 5',
      () {
    for (var seed = 1; seed <= seeds; seed++) {
      final plain = floors(seed, 0);
      for (final h in heats) {
        final at = floors(seed, h);
        for (var f = 1; f <= towerTop; f++) {
          // Pyre's x1.04 on floors 11 to 30 from Heat 4, on top.
          final scale = (h == 0
                  ? 1.0
                  : h == 5 && f >= 11
                      ? 1.12
                      : 1.05) *
              (h >= 4 && f >= 11 ? 1.04 : 1.0);
          expect(at[f - 1].extra, closeTo(plain[f - 1].extra * scale, 1e-9),
              reason: 'seed $seed Heat $h floor $f');
        }
      }
    }
  });

  test(
      'Smoke: one more affix on every warden and boss from Heat 2, no more '
      'on the ordinary floors', () {
    for (var seed = 1; seed <= seeds; seed++) {
      final one = floors(seed, 1);
      for (final h in [2, 3, 4, 5]) {
        final at = floors(seed, h);
        for (var f = 1; f <= towerTop; f++) {
          if (peak(f)) {
            expect(at[f - 1].affixes.length, one[f - 1].affixes.length + 1,
                reason: 'seed $seed Heat $h floor $f (a peak)');
          } else if (h == 2) {
            // Heat 2 adds no affix to an ordinary floor.
            expect(at[f - 1].affixes, one[f - 1].affixes,
                reason: 'seed $seed Heat $h floor $f');
          }
        }
      }
      // Below Smoke nothing is added to the peaks.
      final zero = floors(seed, 0);
      for (var f = 1; f <= towerTop; f++) {
        expect(one[f - 1].affixes.length, zero[f - 1].affixes.length,
            reason: 'seed $seed floor $f: Embers adds an affix');
      }
    }
  });

  test('Flame: healing 15% to 5% from Heat 3, more Elites from floor 11', () {
    expect([for (final h in heats) towerRecoveryShareOf(h)],
        [.15, .15, .15, .05, .05, .05]);
    var below = 0, aboveTwo = 0, aboveThree = 0;
    for (var seed = 1; seed <= 200; seed++) {
      final two = floors(seed, 2), three = floors(seed, 3);
      for (var f = 1; f < towerTop; f++) {
        if (peak(f)) continue;
        if (f < 11) {
          if (two[f - 1].elite != three[f - 1].elite) below++;
        } else {
          if (two[f - 1].elite) aboveTwo++;
          if (three[f - 1].elite) aboveThree++;
        }
      }
    }
    expect(below, 0, reason: 'Flame changes the Elites below floor 11');
    expect(aboveThree, greaterThan(aboveTwo),
        reason: 'Flame brings no more Elites from floor 11 '
            '($aboveTwo at Heat 2, $aboveThree at Heat 3)');
  });

  test('Pyre: no boon on floors 13 and 23, the late oath from floor 18', () {
    for (final h in heats) {
      final boons = towerBoonFloorsOf(h);
      expect(boons.contains(13), h < 4, reason: 'Heat $h floor 13');
      expect(boons.contains(23), h < 4, reason: 'Heat $h floor 23');
      // The other boon floors stay.
      expect(boons.containsAll({5, 10, 15, 20, 25, 28}), isTrue,
          reason: 'Heat $h lost a boon floor besides 13 and 23');
      if (h >= 4) {
        expect(towerPityOathFloorOf(h), 18);
      } else {
        expect(towerPityOathFloorOf(h), 15, reason: 'Heat $h');
      }
    }
  });

  test('Ash: a gift costs each rival clan 2 standing, 1 below Heat 5', () {
    expect(
        [for (final h in heats) towerRivalStandingOf(h)], [1, 1, 1, 1, 1, 2]);
  });

  test('the marks rise a quarter a level, rounded down: x1 to x2.25', () {
    expect([for (final h in heats) towerHeatMarksOf(100, h)],
        [100, 125, 150, 175, 200, 225]);
    expect([for (final h in heats) towerHeatMarksOf(61, h)],
        [61, 76, 91, 106, 122, 137]);
    expect(towerHeatMarksFactor(5), closeTo(2.25, 1e-9));
    // A run banks them: the same climb pays more at a higher Heat.
    for (final h in heats) {
      expect(towerMarksOf(30, 2, heat: h),
          towerHeatMarksOf(towerMarksOf(30, 2), h),
          reason: 'Heat $h');
    }
    final run = playTowerRun(
        seed: 3, data: data, progress: towerAllUnlocked, events: 2, heat: 3);
    expect(run.marksEarned,
        towerMarksOf(run.heightCleared, run.refused.length, heat: 3));
    expect(
        run.marksEarned,
        greaterThanOrEqualTo(
            towerMarksOf(run.heightCleared, run.refused.length)));
  });

  group('a win at Heat n opens Heat n + 1', () {
    // A run of each outcome at each Heat, from the bot with every unlock.
    TowerRun? find(int heat, TowerStatus status) {
      for (var seed = 1; seed <= 400; seed++) {
        final r = playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: 2,
            heat: heat);
        if (r.status == status) return r;
      }
      return null;
    }

    test('each Heat is won by someone, and the win opens the next', () {
      var progress = const TowerProgress();
      expect(progress.heatsOpen, [0]);
      for (final h in heats) {
        expect(progress.isHeatOpen(h), isTrue, reason: 'Heat $h is not open');
        expect(progress.isHeatOpen(h + 1), isFalse,
            reason: 'Heat ${h + 1} is open before Heat $h is won');
        final won = find(h, TowerStatus.won);
        expect(won, isNotNull, reason: 'no bot climb of 400 wins Heat $h');
        expect(won!.heat, h);
        progress = progress.afterRun(won);
        expect(progress.heatWon, h);
        expect(progress.heatOpen, h == 5 ? 5 : h + 1,
            reason: 'a win at Heat $h opens the wrong Heat');
      }
      expect(progress.heatsOpen, heats);
    });

    test('a loss, or a win below the best, opens nothing', () {
      final lost = find(2, TowerStatus.dead)!;
      var progress = const TowerProgress().afterRun(find(1, TowerStatus.won)!);
      expect(progress.heatOpen, 2);
      progress = progress.afterRun(lost);
      expect(progress.heatWon, 1, reason: 'a loss at Heat 2 opened Heat 3');
      progress = progress.afterRun(find(0, TowerStatus.won)!);
      expect(progress.heatWon, 1, reason: 'a win at Heat 0 closed a Heat');
      expect(progress.heatOpen, 2);
      // A run not over changes nothing.
      expect(identical(progress.afterRun(playUnfinished()), progress), isTrue);
    });

    test('the heat is saved: the run, the progress, and an old save', () {
      final won = find(4, TowerStatus.won)!;
      expect(TowerRun.fromJson(jsonDecode(jsonEncode(won.toJson()))).heat, 4);
      final progress = const TowerProgress().afterRun(won);
      final back = TowerProgress.fromJson(
          jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>);
      expect(back.heatWon, 4);
      expect(back.heatOpen, 5);
      // A save from before Heat: no win opens nothing, a win opens Heat 1.
      final old = progress.toJson()..remove('heatWon');
      expect(TowerProgress.fromJson({...old, 'wins': 0}).heatOpen, 0);
      expect(TowerProgress.fromJson({...old, 'wins': 2}).heatOpen, 1);
      // A run at Heat 0 writes nothing new.
      expect(find(0, TowerStatus.won)!.toJson().containsKey('heat'), isFalse);
    });
  });

  test('a Heat not open starts at the highest open one', () async {
    Future<TowerController> opened() async {
      final c = TowerController();
      for (var i = 0; i < 50 && c.state.value == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return c;
    }

    Future<int> startAt(int heatWon, int asked) async {
      SharedPreferences.setMockInitialValues({
        if (heatWon >= 0)
          towerMarksPrefsKey: jsonEncode(const TowerProgress()
              .copyWith(wins: 1, heatWon: heatWon)
              .toJson()),
      });
      final c = await opened();
      final run = await c.start(
          data: data, raceId: 'human', professionId: 'warrior', heat: asked);
      c.dispose();
      return run.heat;
    }

    expect(await startAt(-1, 3), 0, reason: 'no win: Heat 3 is shut');
    expect(await startAt(2, 3), 3);
    expect(await startAt(2, 5), 3);
    expect(await startAt(5, 5), 5);
    expect(await startAt(1, 0), 0);
  });

  test('the bot climbs lower at every Heat, and every Heat can be won', () {
    const climbs = 150;
    final top = <double>[];
    for (final h in heats) {
      var won = 0;
      for (var seed = 1; seed <= climbs; seed++) {
        final r = playTowerRun(
            seed: seed,
            data: data,
            progress: towerAllUnlocked,
            events: 2,
            heat: h);
        if (r.status == TowerStatus.won) won++;
      }
      top.add(won / climbs);
      expect(won, greaterThan(0), reason: 'Heat $h cannot be won');
    }
    for (final h in [1, 2, 3, 4, 5]) {
      // The top never rises with the Heat by more than the seeds' noise.
      expect(top[h], lessThanOrEqualTo(top[h - 1] + .06),
          reason: 'the top at Heat $h (${top[h]}) is above Heat ${h - 1} '
              '(${top[h - 1]}): $top');
    }
    expect(top[5], lessThan(top[0] - .08),
        reason: 'Heat 5 is not harder than Heat 0: $top');
  }, timeout: const Timeout(Duration(minutes: 8)));
}

/// A run begun and not over.
TowerRun playUnfinished() => towerStart(
    seed: 1,
    raceId: 'human',
    professionId: 'warrior',
    data: towerDataFromAssets());
