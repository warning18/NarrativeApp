// Regression coverage for SubNodeEngine.filterEnemyPool -- the chapter gate
// that keeps a random excursion/expedition encounter from rolling an enemy
// the main story hasn't introduced yet. ExpeditionScreen used to build its
// own unfiltered enemy pool (only excluding already-unlocked ids), which
// meant a chapter-2 expedition could roll a chapter-5 endgame monster
// against a level-2 character -- exactly the shape of bug this file guards
// against now that both excursions and expeditions share this one helper.

import 'package:flutter_test/flutter_test.dart';

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
}
