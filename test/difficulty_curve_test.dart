import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/loot_box.dart';

void main() {
  group('chapterDifficultyMultiplier', () {
    test('chapter 1 is the baseline and each chapter adds the step', () {
      expect(chapterDifficultyMultiplier(1), 1.0);
      expect(chapterDifficultyMultiplier(2), closeTo(1.12, 1e-9));
      expect(chapterDifficultyMultiplier(3), closeTo(1.24, 1e-9));
      expect(chapterDifficultyMultiplier(6), closeTo(1.60, 1e-9));
    });

    test('damage climbs half as fast as health', () {
      expect(damageShareOf(1.0), 1.0);
      expect(damageShareOf(1.24), closeTo(1.12, 1e-9));
      expect(damageShareOf(1.6), closeTo(1.3, 1e-9));
      expect(
          damageShareOf(chapterDifficultyMultiplier(4) * zoneTierMultiplier(3)),
          closeTo(1 + (1.36 * 1.2 - 1) / 2, 1e-9));
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
