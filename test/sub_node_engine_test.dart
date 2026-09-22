// Regression coverage for SubNodeEngine.filterEnemyPool -- the chapter gate
// that keeps a random excursion/expedition encounter from rolling an enemy
// the main story hasn't introduced yet. ExpeditionScreen used to build its
// own unfiltered enemy pool (only excluding already-unlocked ids), which
// meant a chapter-2 expedition could roll a chapter-5 endgame monster
// against a level-2 character -- exactly the shape of bug this file guards
// against now that both excursions and expeditions share this one helper.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';

void main() {
  group('filterEnemyPool', () {
    final enemies = {
      'tutorial_rat': {'minChapter': 1},
      'ch2_bandit': {'minChapter': 2},
      'ch5_horror': {'minChapter': 5},
      'no_min_chapter_set': <String, dynamic>{},
    };

    test('excludes enemies above the given chapter', () {
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const [],
        chapter: 2,
      );
      expect(pool, containsAll(['tutorial_rat', 'ch2_bandit']));
      expect(pool, isNot(contains('ch5_horror')));
    });

    test('a chapter-2 zone never rolls a chapter-5 enemy', () {
      // The exact regression this file exists to catch.
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const [],
        chapter: 2,
      );
      expect(pool, isNot(contains('ch5_horror')));
    });

    test('a missing minChapter defaults to 1 (always eligible)', () {
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const [],
        chapter: 1,
      );
      expect(pool, contains('no_min_chapter_set'));
    });

    test('already-unlocked enemies are excluded regardless of chapter', () {
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const ['tutorial_rat'],
        chapter: 5,
      );
      expect(pool, isNot(contains('tutorial_rat')));
      expect(pool, containsAll(['ch2_bandit', 'ch5_horror']));
    });

    test('a higher chapter includes every lower-tier enemy too', () {
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const [],
        chapter: 5,
      );
      expect(pool, containsAll(['tutorial_rat', 'ch2_bandit', 'ch5_horror']));
    });
  });

  group('buildNode pack rolling', () {
    final flavor = flavorFor(defaultMapTheme);

    test('a pack never includes a soloOnlyEnemyIds member', () {
      final pool = ['harbor_rat', 'street_bandit', 'inquisition_high_warden'];
      for (var seed = 0; seed < 500; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: pool,
        );
        for (final id in node.choices.first.triggerEnemyIds) {
          expect(soloOnlyEnemyIds.contains(id), isFalse);
        }
      }
    });

    test('a drawn pack always has 2 or 3 enemies', () {
      final pool = ['harbor_rat', 'street_bandit', 'dock_overseer'];
      var sawPack = false;
      for (var seed = 0; seed < 500; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: pool,
        );
        final ids = node.choices.first.triggerEnemyIds;
        if (ids.isNotEmpty) {
          sawPack = true;
          expect(ids.length, anyOf(2, 3));
        }
      }
      // Not a hard guarantee at any single seed, but virtually certain
      // across 500 trials at the documented ~15% combined draw rate --
      // if this ever flakes, the pack-rolling odds themselves changed.
      expect(sawPack, isTrue);
    });

    test('a pool of only solo-only enemies never produces a pack', () {
      final pool = ['inquisition_high_warden', 'hollow_court_zealot'];
      for (var seed = 0; seed < 200; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: pool,
        );
        expect(node.choices.first.triggerEnemyIds, isEmpty);
      }
    });

    test('maxPackSize 2 (chapters 1-2) never draws a 3-enemy pack', () {
      final pool = ['harbor_rat', 'street_bandit', 'dock_overseer'];
      var sawPack = false;
      for (var seed = 0; seed < 500; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: pool,
          maxPackSize: 2,
        );
        final ids = node.choices.first.triggerEnemyIds;
        if (ids.isNotEmpty) {
          sawPack = true;
          expect(ids.length, 2);
        }
      }
      expect(sawPack, isTrue);
    });

    test('an explicit packPool is the only source of pack members', () {
      final pool = ['harbor_rat', 'rat_matriarch', 'smuggler_captain'];
      for (var seed = 0; seed < 300; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: pool,
          packPool: const ['harbor_rat'],
        );
        for (final id in node.choices.first.triggerEnemyIds) {
          expect(id, 'harbor_rat');
        }
      }
    });
  });

  group('maxPackSizeFor / filterPackPool', () {
    test('packs are pairs through chapter 2 and up to three from chapter 3',
        () {
      expect(SubNodeEngine.maxPackSizeFor(1), 2);
      expect(SubNodeEngine.maxPackSizeFor(2), 2);
      expect(SubNodeEngine.maxPackSizeFor(3), 3);
      expect(SubNodeEngine.maxPackSizeFor(5), 3);
    });

    test('a pack never outnumbers the party, and is never smaller than a pair',
        () {
      expect(SubNodeEngine.maxPackSizeFor(5, partySize: 1), 2);
      expect(SubNodeEngine.maxPackSizeFor(5, partySize: 2), 2);
      expect(SubNodeEngine.maxPackSizeFor(5, partySize: 3), 3);
      expect(SubNodeEngine.maxPackSizeFor(2, partySize: 3), 2);
    });

    test('only packEligible, non-solo-only enemies may form a pack', () {
      final enemies = {
        'harbor_rat': {'packEligible': true},
        'rat_matriarch': {'packEligible': false},
        'no_flag_at_all': <String, dynamic>{},
        'inquisition_high_warden': {'packEligible': true},
      };
      final pool = SubNodeEngine.filterPackPool(
        enemies: enemies,
        enemyPool: enemies.keys.toList(),
      );
      expect(pool, ['harbor_rat']);
    });
  });
}
