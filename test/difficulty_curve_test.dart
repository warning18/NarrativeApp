import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/loot_box.dart';

void main() {
  group('chapterDifficultyMultiplier', () {
    test('chapter 1 is the baseline and each chapter adds the step', () {
      expect(chapterDifficultyMultiplier(1), 1.0);
      expect(chapterDifficultyMultiplier(2), closeTo(1.15, 1e-9));
      expect(chapterDifficultyMultiplier(3), closeTo(1.30, 1e-9));
      expect(chapterDifficultyMultiplier(6), closeTo(1.75, 1e-9));
    });

    test('damage climbs half as fast as health', () {
      expect(damageShareOf(1.0), 1.0);
      expect(damageShareOf(1.3), closeTo(1.15, 1e-9));
      expect(damageShareOf(1.6), closeTo(1.3, 1e-9));
      expect(
          damageShareOf(chapterDifficultyMultiplier(4) * zoneTierMultiplier(3)),
          closeTo(1 + (1.45 * 1.2 - 1) / 2, 1e-9));
    });

    test('a chapter below 1 (unknown node) is treated as chapter 1', () {
      expect(chapterDifficultyMultiplier(0), 1.0);
      expect(chapterDifficultyMultiplier(-3), 1.0);
    });

    test('rewards climb more gently than difficulty', () {
      for (var chapter = 2; chapter <= 6; chapter++) {
        expect(chapterRewardMultiplier(chapter),
            lessThan(chapterDifficultyMultiplier(chapter)));
        expect(chapterRewardMultiplier(chapter), greaterThan(1.0));
      }
      expect(chapterRewardMultiplier(1), 1.0);
    });
  });

  group('difficultyCurveFor', () {
    test('a regular enemy\'s floor ramps over the first three chapters', () {
      expect(enemyHealthBaseMultiplier(1), 1.15);
      expect(enemyHealthBaseMultiplier(2), 1.25);
      expect(enemyHealthBaseMultiplier(3), 1.35);
      expect(enemyHealthBaseMultiplier(6), 1.35);
      expect(enemyHealthBaseMultiplier(0), 1.15);
      expect(enemyDamageBaseMultiplier(1), 1.10);
      expect(enemyDamageBaseMultiplier(2), 1.15);
      expect(enemyDamageBaseMultiplier(5), 1.20);
      final curve = difficultyCurveFor(chapter: 1);
      expect(curve.health, closeTo(1.15, 1e-9));
      expect(curve.damage, closeTo(1.10, 1e-9));
      final later = difficultyCurveFor(chapter: 3, zoneMultiplier: 1.2);
      expect(later.health, closeTo(1.35 * 1.30 * 1.2, 1e-9));
      expect(later.damage, closeTo(1.20 * damageShareOf(1.30 * 1.2), 1e-9));
    });

    test('a boss takes its own lighter floor: its phases do the rest', () {
      final boss = difficultyCurveFor(chapter: 1, isBoss: true);
      expect(boss.health, bossHealthBaseMultiplier);
      expect(boss.damage, bossDamageBaseMultiplier);
      expect(bossHealthBaseMultiplier, lessThan(enemyHealthBaseMultiplier(1)));
      expect(bossDamageBaseMultiplier, lessThan(enemyDamageBaseMultiplier(1)));
      expect(
          difficultyCurveFor(chapter: 4, isBoss: true).health,
          closeTo(
              bossHealthBaseMultiplier * chapterDifficultyMultiplier(4), 1e-9));
    });

    test('every New Game+ cycle scales health and damage alike', () {
      expect(newGamePlusMultiplier(0), 1.0);
      expect(newGamePlusMultiplier(1), closeTo(1 + newGamePlusStep, 1e-9));
      expect(newGamePlusMultiplier(-2), 1.0);
      final plus = difficultyCurveFor(chapter: 1, newGamePlusCycle: 2);
      final base = difficultyCurveFor(chapter: 1);
      expect(
          plus.health / base.health, closeTo(newGamePlusMultiplier(2), 1e-9));
      expect(
          plus.damage / base.damage, closeTo(newGamePlusMultiplier(2), 1e-9));
    });

    test('isBossEnemy reads phases and the solo-only list', () {
      expect(isBossEnemy('harbor_rat', {'maxHealth': 10}), isFalse);
      expect(isBossEnemy('void_sovereign', {}), isTrue);
      expect(
          isBossEnemy('bone_warden', {
            'phases': [
              {'healthThreshold': 50}
            ]
          }),
          isTrue);
      expect(isBossEnemy('bone_warden', {'phases': []}), isFalse);
    });
  });

  group('zoneTierMultiplier', () {
    test('tier 1 is neutral, each tier past it adds a tenth', () {
      expect(zoneTierMultiplier(1), 1.0);
      expect(zoneTierMultiplier(2), closeTo(1.1, 1e-9));
      expect(zoneTierMultiplier(3), closeTo(1.2, 1e-9));
      expect(zoneTierMultiplier(0), 1.0);
    });
  });

  group('EncounterModifiers', () {
    test('none is the default and carries no chapter', () {
      expect(EncounterModifiers.none.isDefault, isTrue);
      expect(EncounterModifiers.none.chapter, isNull);
      expect(EncounterModifiers.none.difficultyMultiplier, 1.0);
    });

    test('copyWith stamps a chapter and tier without touching the rest', () {
      const hunt = EncounterModifiers(
        namedEnemyName: 'Merrick',
        chestTierFloor: ChestTier.gold,
        rewardMultiplier: 1.5,
        healthMultiplier: 1.2,
        isHunt: true,
      );
      final stamped = hunt.copyWith(chapter: 3, difficultyMultiplier: 1.2);
      expect(stamped.chapter, 3);
      expect(stamped.difficultyMultiplier, closeTo(1.2, 1e-9));
      expect(stamped.namedEnemyName, 'Merrick');
      expect(stamped.chestTierFloor, ChestTier.gold);
      expect(stamped.rewardMultiplier, 1.5);
      expect(stamped.healthMultiplier, 1.2);
      expect(stamped.isHunt, isTrue);
      expect(stamped.isDefault, isFalse);
      // A stamped default is no longer the default.
      expect(EncounterModifiers.none.copyWith(chapter: 2).isDefault, isFalse);
    });

    test('zoneBoss guarantees Gold, pays half again, and is flagged', () {
      final boss =
          EncounterModifiers.zoneBoss(chapter: 3, difficultyMultiplier: 1.2);
      expect(boss.isZoneBoss, isTrue);
      expect(boss.chestTierFloor, ChestTier.gold);
      expect(boss.rewardMultiplier, 1.5);
      expect(boss.chapter, 3);
      expect(boss.difficultyMultiplier, closeTo(1.2, 1e-9));
      expect(boss.isHunt, isFalse);
      expect(boss.isHunterAmbush, isFalse);
      expect(boss.forcedAffixes, isEmpty);
    });
  });
}
