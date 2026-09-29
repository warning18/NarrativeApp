// Detours as choices (v1.162): a way round a fight, a gamble on a cache, a
// rest traded for a purse; random draws that keep their dangers; flavor
// lines that don't come straight back round.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  final flavor = flavorFor(MapTheme.ashenStreets);

  List<StoryNode> draw({int chapter = 1, int count = 300}) => [
        for (var seed = 0; seed < count; seed++)
          SubNodeEngine.buildNode(
            random: Random(seed),
            flavor: flavor,
            shopPool: const [],
            enemyPool: const ['rat'],
            packPool: const ['rat'],
            chapter: chapter,
          ),
      ];

  test('a cache can be taken or gambled on', () {
    final caches = draw(chapter: 3)
        .where((n) => n.choices.first.goldMod > 0 && n.choices.length == 2)
        .toList();
    expect(caches, isNotEmpty);
    for (final node in caches) {
      final take = node.choices.first;
      final dig = node.choices.last;
      expect(take.hasAbilityCheck, isFalse);
      expect(dig.checkAbility, 'perception');
      expect(dig.checkDC, SubNodeEngine.detourCheckDc(3));
      expect(dig.goldMod,
          (take.goldMod * SubNodeEngine.digDeeperMultiplier).round());
    }
  });

  test('a rest can be traded for a purse', () {
    final rests =
        draw(chapter: 2).where((n) => n.choices.first.healAmount > 0).toList();
    expect(rests, isNotEmpty);
    for (final node in rests) {
      expect(node.choices.first.healAmount, SubNodeEngine.restHealFor(2));
      final scavenge = node.choices.last;
      expect(scavenge.checkAbility, 'luck');
      expect(scavenge.goldMod, greaterThan(0));
      expect(scavenge.healAmount, 0);
    }
  });

  test('finds and rests grow with the chapter; checks get harder', () {
    expect(SubNodeEngine.treasureGoldFor(1, 10), 10);
    expect(SubNodeEngine.treasureGoldFor(3, 10), 20);
    expect(SubNodeEngine.restHealFor(1), 20);
    expect(SubNodeEngine.restHealFor(4), 50);
    expect(SubNodeEngine.detourCheckDc(1), 10);
    expect(SubNodeEngine.detourCheckDc(5), 14);
  });

  test('a sneak past a pack is harder than past one enemy', () {
    final fights =
        draw(chapter: 2).where((n) => n.choices.first.triggersCombat);
    final solo = fights
        .firstWhere((n) => n.choices.first.allTriggerEnemyIds.length == 1);
    final pack =
        fights.firstWhere((n) => n.choices.first.allTriggerEnemyIds.length > 1);
    expect(solo.choices.last.checkDC, SubNodeEngine.detourCheckDc(2));
    expect(pack.choices.last.checkDC, SubNodeEngine.detourCheckDc(2) + 2);
  });

  test('a sneak gone wrong is an ambush', () {
    const sneak = StoryChoice(
      text: 'Slip past',
      nextId: 'x',
      triggerEnemyId: 'rat',
      checkAbility: 'dexterity',
      checkDC: 10,
      avoidFightOnSuccess: true,
      forcedCondition: 'ambush',
    );
    expect(EncounterModifiers.fromChoice(sneak).forcedCondition,
        BattlefieldCondition.ambush);
    final round = StoryChoice.fromJson(sneak.toJson());
    expect(round.avoidFightOnSuccess, isTrue);
    expect(round.forcedCondition, 'ambush');
    expect(
        EncounterModifiers.fromChoice(const StoryChoice(text: 'x', nextId: 'y'))
            .forcedCondition,
        isNull);
  });

  test('beaten enemies stay in the draw, new ones come three times as often',
      () {
    final enemies = {
      'harbor_rat': {'minChapter': 1, 'packEligible': true},
      'slum_thug': {'minChapter': 1, 'packEligible': true},
    };
    final fresh = SubNodeEngine.weightedEnemyPool(
        enemies: enemies, unlockedEnemyIds: const [], chapter: 1);
    expect(fresh.where((id) => id == 'harbor_rat'), hasLength(3));
    final met = SubNodeEngine.weightedEnemyPool(
        enemies: enemies, unlockedEnemyIds: const ['harbor_rat'], chapter: 1);
    expect(met.where((id) => id == 'harbor_rat'), hasLength(1));
    expect(met.where((id) => id == 'slum_thug'), hasLength(3));
    final allMet = SubNodeEngine.weightedEnemyPool(
        enemies: enemies,
        unlockedEnemyIds: const ['harbor_rat', 'slum_thug'],
        chapter: 1);
    expect(allMet, isNotEmpty, reason: 'the road never runs dry');
  });

  test('the same flavor line does not come straight back round', () {
    final lines = [
      for (var seed = 0; seed < 40; seed++)
        SubNodeEngine.buildNode(
          random: Random(seed * 7919),
          flavor: flavor,
          shopPool: const [],
          enemyPool: const [],
        ).description,
    ];
    var immediateRepeats = 0;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i] == lines[i - 1]) immediateRepeats++;
    }
    expect(immediateRepeats, 0);
  });
}
