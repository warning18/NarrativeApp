// Regression coverage for SubNodeEngine.filterEnemyPool -- the chapter gate
// that keeps a random excursion/expedition encounter from rolling an enemy
// the main story hasn't introduced yet. ExpeditionScreen used to build its
// own unfiltered enemy pool (only excluding already-unlocked ids), which
// meant a chapter-2 expedition could roll a chapter-5 endgame monster
// against a level-2 character -- exactly the shape of bug this file guards
// against now that both excursions and expeditions share this one helper.
// filterQuestPool is the same idea for quests: a quest written for one
// alignment (Tobin's vigil, Malrik's cut) is never offered to another.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';

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

    test('a story-only enemy is never a random draw nor a pack member', () {
      final withSoldier = {
        ...enemies,
        'white_soldier': {'minChapter': 1, 'packEligible': true},
      };
      final pool = SubNodeEngine.filterEnemyPool(
        enemies: withSoldier,
        unlockedEnemyIds: const [],
        chapter: 6,
      );
      expect(pool, isNot(contains('white_soldier')));
      expect(storyOnlyEnemyIds, contains('white_soldier'));
      final pack = SubNodeEngine.filterPackPool(
        enemies: withSoldier,
        enemyPool: const ['white_soldier', 'tutorial_rat'],
      );
      expect(pack, isNot(contains('white_soldier')));
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

  group('filterQuestPool', () {
    final quests = {
      'q_open': {'chapter': 4, 'requiredAlignment': 'Neutral'},
      'q_untagged': {'chapter': 4},
      'q_good_only': {'chapter': 4, 'requiredAlignment': 'Good'},
      'q_evil_only': {'chapter': 4, 'requiredAlignment': 'Evil'},
      'q_next_chapter': {'chapter': 5, 'requiredAlignment': 'Good'},
    };
    List<String> pool(String alignment,
            {List<String> unlocked = const [],
            List<String> completed = const []}) =>
        SubNodeEngine.filterQuestPool(
          quests: quests,
          chapter: 4,
          unlockedQuestIds: unlocked,
          completedQuestIds: completed,
          alignmentLabel: alignment,
        );

    test('a Neutral character is never offered an aligned recruit quest', () {
      expect(pool('Neutral'), unorderedEquals(['q_open', 'q_untagged']));
    });

    test('the Good get the Good quest, the Evil the Evil one, never both', () {
      expect(pool('Good'),
          unorderedEquals(['q_open', 'q_untagged', 'q_good_only']));
      expect(pool('Evil'),
          unorderedEquals(['q_open', 'q_untagged', 'q_evil_only']));
    });

    test('unlocked, completed and other-chapter quests stay out', () {
      expect(pool('Good', unlocked: ['q_open'], completed: ['q_good_only']),
          ['q_untagged']);
      expect(pool('Good'), isNot(contains('q_next_chapter')));
    });

    test('the shipped recruit quests carry the gate their nodes carry', () {
      final shipped = jsonDecode(
              File('assets/gamedata/quests.json').existsSync()
                  ? File('assets/gamedata/quests.json').readAsStringSync()
                  : File('../assets/gamedata/quests.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(
          SubNodeEngine.questMeetsAlignment(
              shipped['q_ch4_tobins_vigil'] as Map<String, dynamic>, 'Evil'),
          isFalse);
      expect(
          SubNodeEngine.questMeetsAlignment(
              shipped['q_ch4_tobins_vigil'] as Map<String, dynamic>, 'Good'),
          isTrue);
      expect(
          SubNodeEngine.questMeetsAlignment(
              shipped['q_ch5_malriks_cut'] as Map<String, dynamic>, 'Neutral'),
          isFalse);
      expect(
          SubNodeEngine.questMeetsAlignment(
              shipped['q_ch5_malriks_cut'] as Map<String, dynamic>, 'Evil'),
          isTrue);
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

  group('hunts', () {
    final flavor = flavorFor(defaultMapTheme);
    final enemies = {
      'harbor_rat': {'enemyName': 'Harbor Rat', 'packEligible': true},
      'street_bandit': {'enemyName': 'Street Bandit', 'packEligible': true},
    };

    test('buildHuntNodes yields a trail then a named quarry fight', () {
      final nodes = SubNodeEngine.buildHuntNodes(
        quarryId: 'street_bandit',
        quarryBaseName: 'Street Bandit',
        random: Random(7),
      );
      expect(nodes.length, 2);
      expect(nodes.first.choices.single.triggersCombat, isFalse);
      final fight = nodes.last.choices.single;
      expect(fight.triggerEnemyId, 'street_bandit');
      expect(fight.huntName, isNotEmpty);
      expect(fight.huntAffixes.length, 2);
      expect(fight.chestFloor, 'gold');
      expect(nodes.last.description, contains(fight.huntName!));
    });

    test('withHunts splices a hunt right after the first pack fight', () {
      const pack = StoryNode(
        id: 'p',
        description: 'pack',
        choices: [
          StoryChoice(
              text: 'Fight',
              nextId: '',
              triggerEnemyIds: ['harbor_rat', 'street_bandit']),
        ],
      );
      const rest = StoryNode(
        id: 'r',
        description: 'rest',
        choices: [StoryChoice(text: 'Rest', nextId: '', healAmount: 20)],
      );
      final chain = SubNodeEngine.withHunts(
        [rest, pack, rest],
        enemies: enemies,
        random: Random(3),
        flavor: flavor,
        chance: 1.0,
      );
      expect(chain.length, 5);
      expect(chain[1].id, 'p');
      expect(chain[3].choices.single.huntName, isNotEmpty);
      expect(chain[4].id, 'r');
    });

    test('a chain without a pack fight is returned untouched', () {
      const rest = StoryNode(
        id: 'r',
        description: 'rest',
        choices: [StoryChoice(text: 'Rest', nextId: '', healAmount: 20)],
      );
      final chain = SubNodeEngine.withHunts(
        [rest],
        enemies: enemies,
        random: Random(3),
        flavor: flavor,
        chance: 1.0,
      );
      expect(chain.single.id, 'r');
    });
  });
}
