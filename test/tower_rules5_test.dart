// The Tower's rules 5 (docs/simulation/tower-early-floors.md, the user's
// call): on floors 1 to 3 of a climb begun on rules 5 the foes strike first
// (the app's ambush, forced), their damage grows with the hero's unlock
// health, their health is .85 of the curve's and the hero gets 25% of max
// health back after the floor. Floor 4 and up, and every climb begun on
// rules 1 to 4, as before.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/tower_fight_launcher.dart';

void main() {
  final data = towerDataFromAssets();
  final unlocks = towerAllUnlocked.unlocksOwned;

  TowerRun start(
          {int seed = 7,
          int rules = 5,
          int heat = 0,
          int unlocksOwned = 0,
          String raceId = 'human',
          String professionId = 'warrior'}) =>
      towerStart(
          seed: seed,
          raceId: raceId,
          professionId: professionId,
          unlocksOwned: unlocksOwned,
          events: towerEventsLive,
          heat: heat,
          rules: rules,
          data: data);

  /// The modifiers the app's fight is handed for [run] on [floor].
  EncounterModifiers modifiersOn(TowerRun run, int floor) {
    final at = run.copyWith(floor: floor);
    return towerFloorOf(at, data).modifiersFor(at.professionId,
        raceId: at.raceId, unlocksOwned: at.unlocksOwned);
  }

  group('the early floors', () {
    test('a new climb plays rules 5', () {
      expect(towerRulesLive, 5);
      expect(towerRulesMax, 5);
      expect(start(rules: towerRulesLive).rules, 5);
      expect(start(rules: 9).rules, 5);
    });

    test('floors 1 to 3 of a rules-5 climb open with the ambush', () {
      for (final seed in [1, 7, 42]) {
        final run = start(seed: seed, unlocksOwned: unlocks);
        for (var floor = 1; floor <= towerTop; floor++) {
          final m = modifiersOn(run, floor);
          expect(m.forcedCondition,
              floor <= 3 ? BattlefieldCondition.ambush : isNull,
              reason: 'seed $seed floor $floor');
          expect(m.damageMultiplier, floor <= 3 ? greaterThan(1.0) : 1.0,
              reason: 'seed $seed floor $floor');
          // The Tower's own settings stand.
          expect(m.tower && m.keepWounds && m.lossContinues, isTrue);
        }
      }
    });

    test('no early floors on rules 1 to 4', () {
      for (var rules = 1; rules <= 4; rules++) {
        final run = start(rules: rules, unlocksOwned: unlocks);
        for (var floor = 1; floor <= towerTop; floor++) {
          final m = modifiersOn(run, floor);
          expect(m.forcedCondition, isNull, reason: 'rules $rules f$floor');
          expect(m.damageMultiplier, 1.0, reason: 'rules $rules f$floor');
          expect(towerEarlyFloorOf(rules, floor), isFalse);
        }
      }
    });

    test('the app\'s fight screen carries the ambush and the damage', () {
      final run = start(unlocksOwned: unlocks);
      for (final floorNumber in [1, 3, 4]) {
        final at = run.copyWith(floor: floorNumber);
        final floor = towerFloorOf(at, data);
        final records = {
          for (final id in floor.enemyIds)
            id: (data.enemies[id] as Map).cast<String, dynamic>(),
        };
        final screen = towerFightScreen(at, floor, records).modifiers;
        final expected = floor.modifiersFor(at.professionId,
            raceId: at.raceId, unlocksOwned: at.unlocksOwned);
        expect(screen.forcedCondition, expected.forcedCondition);
        expect(screen.damageMultiplier, expected.damageMultiplier);
        expect(screen.difficultyMultiplier, expected.difficultyMultiplier);
        expect(screen.forcedCondition,
            floorNumber <= 3 ? BattlefieldCondition.ambush : isNull);
        expect(
            screen.damageMultiplier, floorNumber <= 3 ? greaterThan(2.0) : 1.0,
            reason: 'floor $floorNumber');
      }
    });

    test('the foes\' damage: ×1 with no unlocks, the unlock health with them',
        () {
      for (final p in towerProfessionScale.keys) {
        for (final r in data.races.keys) {
          expect(
              towerEarlyDamageFor(5, 1,
                  raceId: r, professionId: p, unlocksOwned: 0),
              1.0);
          final health = 1 + towerHealthPerUnlockFor(r, p, rules: 5) * unlocks;
          for (var floor = 1; floor <= 4; floor++) {
            expect(
                towerEarlyDamageFor(5, floor,
                    raceId: r, professionId: p, unlocksOwned: unlocks),
                floor <= 3
                    ? closeTo(pow(health, towerEarlyUnlockDamage), 1e-12)
                    : 1.0,
                reason: '$r $p floor $floor');
            expect(
                towerEarlyDamageFor(4, floor,
                    raceId: r, professionId: p, unlocksOwned: unlocks),
                1.0);
          }
        }
      }
      // A human warrior with every unlock: about ×2.2.
      expect(
          towerEarlyDamageFor(5, 2,
              raceId: 'human', professionId: 'warrior', unlocksOwned: unlocks),
          closeTo(2.17, .01));
      // With no unlocks the climb's modifiers carry none.
      expect(modifiersOn(start(), 1).damageMultiplier, 1.0);
      expect(
          modifiersOn(start(), 1).forcedCondition, BattlefieldCondition.ambush);
    });

    test('the early floors\' foes: .85 of the health, floor 4 as before', () {
      for (final p in towerProfessionScale.keys) {
        for (var floor = 0; floor <= towerTop; floor++) {
          final four = towerRulesScaleOf(4, p, floor: floor);
          expect(towerRulesScaleOf(5, p, floor: floor),
              closeTo(floor >= 1 && floor <= 3 ? four * .85 : four, 1e-12),
              reason: '$p floor $floor');
        }
      }
      // 3.0 / 4.2 / 4.5 become 2.55 / 3.57 / 3.83 (3.825).
      for (final (floor, scale) in [(1, 2.55), (2, 3.57), (3, 3.825)]) {
        expect(towerSurvivalScale[floor - 1] * towerEarlyScale,
            closeTo(scale, 1e-9));
      }
    });

    test('25% health back after floors 1 to 3, at every Heat', () {
      for (final heat in [0, 1, 2, 3, 4, 5]) {
        for (var floor = 1; floor <= towerTop; floor++) {
          expect(
              towerRecoveryShareFor(heat, rules: 5, floor: floor),
              floor <= 3
                  ? .25
                  : towerRecoveryShareFor(heat, rules: 4, floor: floor),
              reason: 'heat $heat floor $floor');
          expect(towerRecoveryShareFor(heat, rules: 4, floor: floor),
              towerRecoveryShareFor(heat, rules: 4));
        }
      }
      expect(towerRecoveryShareFor(0, rules: 4, floor: 1), .10);
      expect(
          towerRecoveryShareFor(3, rules: 4, floor: 1), towerHeatRecoveryShare);
    });

    test('a floor won heals 25% on rules 5 (Heat 0 and 3), as before on 4', () {
      for (final heat in [0, 3]) {
        for (final rules in [4, 5]) {
          final run = start(rules: rules, heat: heat, seed: 11);
          final hero = towerHeroOf(run, data);
          final after = towerAfterFight(run, data,
              won: true,
              healthLeft: 1,
              potionsLeft: run.potions,
              maxHealthBefore: hero.maxHealth);
          final max = towerHeroOf(after, data).maxHealth;
          final share = rules == 5
              ? .25
              : heat >= towerHeatFlame
                  ? towerHeatRecoveryShare
                  : .10;
          expect(
              after.health,
              (1 +
                      max -
                      hero.maxHealth +
                      (max * share).round() +
                      (max * towerSecondWindShareOf(run)).round())
                  .clamp(1, max),
              reason: 'rules $rules heat $heat');
        }
      }
    });

    test('the headless fight plays the ambush and the damage', () {
      final run = start();
      final floor = towerFloorOf(run, data);
      final enemies = [
        for (final id in floor.enemyIds)
          MapEntry(id, data.enemies[id] as Map<String, dynamic>),
      ];
      SimFightOutcome fight(int seed,
              {required bool ambush, required double damage}) =>
          simulateSimFight(
            character: towerHeroOf(run, data),
            enemies: enemies,
            chapter: floor.chapter,
            zoneMultiplier: floor.extraFor(run.professionId),
            skills: data.skills,
            items: data.items,
            random: Random(seed),
            ambush: ambush,
            damageMultiplier: damage,
          );
      var killedBeforeRolling = 0;
      for (var seed = 1; seed <= 30; seed++) {
        // The foes' turn before round 1: a blow 50 times stronger fells the
        // hero before its first roll.
        final ambushed = fight(seed, ambush: true, damage: 50);
        if (!ambushed.won && ambushed.rounds == 0) killedBeforeRolling++;
        // Without it the hero always rolls first.
        expect(fight(seed, ambush: false, damage: 50).rounds,
            greaterThanOrEqualTo(1));
        // At the plain damage the ambush alone never fells a full hero.
        expect(fight(seed, ambush: true, damage: 1).rounds,
            greaterThanOrEqualTo(1));
      }
      expect(killedBeforeRolling, greaterThan(10));
    });

    test('a rules-5 climb saves and loads, its early floors with it', () {
      final run = start(unlocksOwned: unlocks);
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
      expect(back.rules, 5);
      expect(back.unlocksOwned, unlocks);
      final a = modifiersOn(run, 2), b = modifiersOn(back, 2);
      expect(b.forcedCondition, BattlefieldCondition.ambush);
      expect(b.damageMultiplier, a.damageMultiplier);
      expect(b.difficultyMultiplier, a.difficultyMultiplier);
      // A rules-4 climb saved stays a rules-4 climb.
      final four = TowerRun.fromJson(jsonDecode(
              jsonEncode(start(rules: 4, unlocksOwned: unlocks).toJson()))
          as Map<String, dynamic>);
      expect(four.rules, 4);
      expect(modifiersOn(four, 2).forcedCondition, isNull);
    });

    test('the bot plays rules 5 to an end, rules 4 as its own', () {
      for (final rules in [4, 5]) {
        final run = playTowerRun(
            seed: 3,
            data: data,
            progress: towerAllUnlocked,
            events: towerEventsLive,
            rules: rules);
        expect(run.isOver, isTrue);
        expect(run.rules, rules);
      }
    });
  });

  test('towerAmbushFloor: floors 1-3 of a rules-5 run only', () {
    for (final rules in [1, 2, 3, 4, 5]) {
      for (var floor = 1; floor <= 6; floor++) {
        final run = TowerRun(
            seed: 1,
            raceId: 'human',
            professionId: 'warrior',
            floor: floor,
            health: 20,
            rules: rules);
        expect(towerAmbushFloor(run), rules >= 5 && floor <= 3,
            reason: 'rules $rules floor $floor');
      }
    }
  });
}
