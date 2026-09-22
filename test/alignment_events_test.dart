// Unit coverage for the alignment layer: who is hunted, how often, which
// hunter shows up, and the temptation offers -- lib/data/alignment_events.dart.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/ally_state.dart';

final Map<String, dynamic> _enemies = {
  'harbor_rat': {'minChapter': 1},
  'angel_sentinel': {'hunterAlignment': 'Evil', 'hunterTier': 1},
  'angel_judicator': {'hunterAlignment': 'Evil', 'hunterTier': 2},
  'demon_imp': {'hunterAlignment': 'Good', 'hunterTier': 1},
  'demon_tormentor': {'hunterAlignment': 'Good', 'hunterTier': 2},
};

void main() {
  group('huntedSideFor', () {
    test('a Good character is hunted by demons, an Evil one by angels', () {
      expect(
          huntedSideFor(alignmentScore: 20, activeQuestIds: const []), 'Good');
      expect(
          huntedSideFor(alignmentScore: -20, activeQuestIds: const []), 'Evil');
      expect(
          huntedSideFor(alignmentScore: 5, activeQuestIds: const []), isNull);
    });

    test('a temptation quest opens the hunt for a Neutral character', () {
      expect(huntedSideFor(alignmentScore: 0, activeQuestIds: [lightQuestId]),
          'Good');
      expect(huntedSideFor(alignmentScore: 0, activeQuestIds: [darkQuestId]),
          'Evil');
    });
  });

  test('hunter odds rise with the score and cap', () {
    expect(hunterChanceFor(20), hunterBaseChance);
    expect(hunterChanceFor(40), closeTo(hunterBaseChance + 0.04, 1e-9));
    expect(hunterChanceFor(400), hunterChanceCap);
  });

  test('tier-2 hunters wait for chapter 3', () {
    expect(hunterPoolFor(enemies: _enemies, side: 'Evil', chapter: 1),
        ['angel_sentinel']);
    expect(hunterPoolFor(enemies: _enemies, side: 'Evil', chapter: 3).toSet(),
        {'angel_sentinel', 'angel_judicator'});
    expect(hunterPoolFor(enemies: _enemies, side: 'Good', chapter: 2),
        ['demon_imp']);
  });

  test('hunters never enter the ordinary random pool', () {
    final pool = SubNodeEngine.filterEnemyPool(
        enemies: _enemies, unlockedEnemyIds: const [], chapter: 5);
    expect(pool, ['harbor_rat']);
  });

  test('an ambush node carries the hunter and the ambush flag', () {
    final node = buildHunterAmbushNode(
        enemies: _enemies, side: 'Good', chapter: 1, random: Random(1));
    expect(node, isNotNull);
    final choice = node!.choices.single;
    expect(choice.triggerEnemyId, 'demon_imp');
    expect(choice.isHunterAmbush, isTrue);
    expect(node.descriptionFr, isNotEmpty);
  });

  group('temptations', () {
    test('every temptation has two answers that pull in some direction', () {
      for (var seed = 0; seed < 50; seed++) {
        final node = buildTemptationNode(
            activeQuestIds: const [],
            completedQuestIds: const [],
            random: Random(seed));
        expect(node, isNotNull);
        expect(node!.choices.length, 2);
        final moves = node.choices.any((c) =>
            c.alignmentMod != 0 ||
            c.goldMod != 0 ||
            (c.questIDToProgress ?? '').isNotEmpty);
        expect(moves, isTrue);
      }
    });

    test('a quest already taken is never offered again', () {
      for (var seed = 0; seed < 100; seed++) {
        final node = buildTemptationNode(
            activeQuestIds: [lightQuestId],
            completedQuestIds: [darkQuestId],
            random: Random(seed));
        for (final choice in node!.choices) {
          expect(choice.questIDToProgress, isNull);
        }
      }
    });
  });

  group('maybeAlignmentEvent', () {
    test('is silent when disabled', () {
      for (var seed = 0; seed < 100; seed++) {
        expect(
            maybeAlignmentEvent(
              alignmentScore: -50,
              activeQuestIds: const [],
              completedQuestIds: const [],
              enemies: _enemies,
              chapter: 3,
              random: Random(seed),
              enabled: false,
            ),
            isNull);
      }
    });

    test(
        'an Evil character only ever meets angels, a Neutral one only temptations',
        () {
      var ambushes = 0;
      var temptations = 0;
      for (var seed = 0; seed < 500; seed++) {
        final evil = maybeAlignmentEvent(
          alignmentScore: -30,
          activeQuestIds: const [],
          completedQuestIds: const [],
          enemies: _enemies,
          chapter: 3,
          random: Random(seed),
        );
        if (evil != null) {
          ambushes++;
          final id = evil.single.choices.single.triggerEnemyId;
          expect(id, anyOf('angel_sentinel', 'angel_judicator'));
        }
        final neutral = maybeAlignmentEvent(
          alignmentScore: 0,
          activeQuestIds: const [],
          completedQuestIds: const [],
          enemies: _enemies,
          chapter: 3,
          random: Random(seed),
        );
        if (neutral != null) {
          temptations++;
          expect(neutral.single.choices.length, 2);
        }
      }
      expect(ambushes, inInclusiveRange(30, 110));
      expect(temptations, inInclusiveRange(25, 85));
    });
  });

  group('alignment multipliers', () {
    test('a matching skill is stronger, an opposed one weaker', () {
      final good = {'alignment': 'Good'};
      expect(alignmentSkillMultiplier(good, 'Good'), alignedSkillMultiplier);
      expect(alignmentSkillMultiplier(good, 'Evil'), opposedSkillMultiplier);
      expect(alignmentSkillMultiplier(good, 'Neutral'), 1.0);
      expect(alignmentSkillMultiplier({'alignment': ''}, 'Good'), 1.0);
      expect(alignmentSkillMultiplier(null, 'Good'), 1.0);
    });

    test('opposed gear is rejected, matching gear pays its bonus', () {
      final relic = {
        'alignment': 'Good',
        'alignedAttackBonus': 4,
        'alignedArmorBonus': 2,
      };
      expect(meetsItemAlignment(relic, 'Evil'), isFalse);
      expect(meetsItemAlignment(relic, 'Neutral'), isTrue);
      expect(meetsItemAlignment(relic, 'Good'), isTrue);
      final items = {'relic': relic};
      final matched = alignmentGearBonusFor(['relic'], items, 'Good');
      expect(matched.damageBonus, 4);
      expect(matched.armorBonus, 2);
      final neutral = alignmentGearBonusFor(['relic'], items, 'Neutral');
      expect(neutral.damageBonus, 0);
      expect(neutral.armorBonus, 0);
    });
  });
}
