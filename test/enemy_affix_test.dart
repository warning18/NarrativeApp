// Unit coverage for enemy affixes and battlefield conditions (pure roll
// helpers) in lib/combat/enemy_affix.dart and battlefield_condition.dart.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/enemy_affix.dart';

void main() {
  group('rollEncounterAffixes', () {
    test('a boss or unique never gets an affix', () {
      for (var seed = 0; seed < 200; seed++) {
        final rolled = rollEncounterAffixes(
          enemyIds: ['inquisition_high_warden'],
          isElite: false,
          random: Random(seed),
          soloChance: 1.0,
        );
        expect(rolled.single, isEmpty);
      }
    });

    test('a solo Elite never gets an affix', () {
      for (var seed = 0; seed < 100; seed++) {
        final rolled = rollEncounterAffixes(
          enemyIds: ['harbor_rat'],
          isElite: true,
          random: Random(seed),
          soloChance: 1.0,
        );
        expect(rolled.single, isEmpty);
      }
    });

    test('a solo enemy never rolls Pack Leader', () {
      for (var seed = 0; seed < 300; seed++) {
        final rolled = rollEncounterAffixes(
          enemyIds: ['harbor_rat'],
          isElite: false,
          random: Random(seed),
          soloChance: 1.0,
        );
        expect(rolled.single.length, 1);
        expect(rolled.single, isNot(contains(EnemyAffix.packLeader)));
      }
    });

    test('a pack has at most one Pack Leader', () {
      var sawLeader = false;
      for (var seed = 0; seed < 300; seed++) {
        final rolled = rollEncounterAffixes(
          enemyIds: ['harbor_rat', 'harbor_rat', 'street_bandit'],
          isElite: false,
          random: Random(seed),
          packChance: 1.0,
        );
        final leaders = rolled
            .where((affixes) => affixes.contains(EnemyAffix.packLeader))
            .length;
        expect(leaders, lessThanOrEqualTo(1));
        if (leaders == 1) sawLeader = true;
      }
      expect(sawLeader, isTrue);
    });

    test('the default chance leaves most enemies plain', () {
      var affixed = 0;
      for (var seed = 0; seed < 1000; seed++) {
        if (rollEncounterAffixes(
                enemyIds: ['harbor_rat'], isElite: false, random: Random(seed))
            .single
            .isNotEmpty) {
          affixed++;
        }
      }
      expect(affixed, inInclusiveRange(120, 280));
    });
  });

  test('a named variant gets two distinct affixes, never Skittish or Leader',
      () {
    for (var seed = 0; seed < 100; seed++) {
      final affixes = rollNamedVariantAffixes(Random(seed));
      expect(affixes.length, 2);
      expect(affixes.toSet().length, 2);
      expect(affixes, isNot(contains(EnemyAffix.skittish)));
      expect(affixes, isNot(contains(EnemyAffix.packLeader)));
    }
  });

  test('affixFromName round-trips every affix', () {
    for (final affix in EnemyAffix.values) {
      expect(affixFromName(affix.name), affix);
    }
    expect(affixFromName('nope'), isNull);
  });

  group('strikeDamageAfterAffixes', () {
    test('an Armored enemy shrugs off the flat reduction from an Attack face',
        () {
      expect(strikeDamageAfterAffixes(12, 'Attack', armored: true),
          12 - armoredFlatReduction);
      expect(
          strikeDamageAfterAffixes(armoredFlatReduction, 'Attack',
              armored: true),
          1);
      expect(strikeDamageAfterAffixes(2, 'Attack', armored: true), 1);
    });

    test('a Skill face goes through Armored whole', () {
      expect(strikeDamageAfterAffixes(12, 'Skill', armored: true), 12);
    });

    test('an unarmored enemy takes the face as rolled', () {
      expect(strikeDamageAfterAffixes(12, 'Attack', armored: false), 12);
      expect(strikeDamageAfterAffixes(1, 'Attack', armored: false), 1);
    });

    test('nothing dealt stays nothing', () {
      expect(strikeDamageAfterAffixes(0, 'Attack', armored: true), 0);
      expect(strikeDamageAfterAffixes(0, 'Defend', armored: false), 0);
    });
  });

  group('battlefield conditions', () {
    test('Cramped only rolls against three or more enemies', () {
      for (var seed = 0; seed < 300; seed++) {
        final solo = rollBattlefieldCondition(
            enemyCount: 1, random: Random(seed), chance: 1.0);
        expect(solo, isNot(BattlefieldCondition.cramped));
      }
      var sawCramped = false;
      for (var seed = 0; seed < 300; seed++) {
        if (rollBattlefieldCondition(
                enemyCount: 3, random: Random(seed), chance: 1.0) ==
            BattlefieldCondition.cramped) {
          sawCramped = true;
        }
      }
      expect(sawCramped, isTrue);
    });

    test('the default chance leaves most fights plain', () {
      var withCondition = 0;
      for (var seed = 0; seed < 1000; seed++) {
        if (rollBattlefieldCondition(enemyCount: 2, random: Random(seed)) !=
            null) {
          withCondition++;
        }
      }
      expect(withCondition, inInclusiveRange(170, 330));
    });

    test('Darkness reads one tier worse and bottoms out at none', () {
      expect(darkenedTier(TelegraphTier.full), TelegraphTier.category);
      expect(darkenedTier(TelegraphTier.category), TelegraphTier.target);
      expect(darkenedTier(TelegraphTier.target), TelegraphTier.none);
      expect(darkenedTier(TelegraphTier.none), TelegraphTier.none);
    });

    test('only the harder conditions pay a fortune bonus', () {
      expect(conditionFortuneBonus(BattlefieldCondition.ambush), 10);
      expect(conditionFortuneBonus(BattlefieldCondition.dark), 10);
      expect(conditionFortuneBonus(BattlefieldCondition.cramped), 5);
      expect(conditionFortuneBonus(BattlefieldCondition.highGround), 0);
      expect(conditionFortuneBonus(BattlefieldCondition.shrine), 0);
      expect(conditionFortuneBonus(null), 0);
    });
  });
}
