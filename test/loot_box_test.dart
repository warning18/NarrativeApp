// Unit coverage for the pure spoils-chest roll in lib/combat/loot_box.dart:
// the fortune-roll modifiers, the tier thresholds and floors, and the
// content rules (owned gear never drops, opposed-alignment gear never
// drops, the chapter window, pity/recent-drop bookkeeping).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/loot_box.dart';

Map<String, dynamic> _gear(String id,
        {String rarity = 'Common',
        int lootChapter = 1,
        String alignment = '',
        String scalingStat = ''}) =>
    {
      'id': id,
      'itemName': id,
      'itemType': 'Weapon',
      'isEquippable': true,
      'rarity': rarity,
      'lootChapter': lootChapter,
      'alignment': alignment,
      'scalingStat': scalingStat,
    };

final Map<String, dynamic> _items = {
  'sword_a': _gear('sword_a'),
  'sword_b': _gear('sword_b', rarity: 'Uncommon'),
  'relic_rare': _gear('relic_rare', rarity: 'Rare'),
  'late_rare': _gear('late_rare', rarity: 'Rare', lootChapter: 4),
  'holy': _gear('holy', rarity: 'Rare', alignment: 'Good'),
  'unholy': _gear('unholy', rarity: 'Rare', alignment: 'Evil'),
  'potion_minor': {'itemType': 'Potion', 'isEquippable': false},
  'potion_major': {'itemType': 'Potion', 'isEquippable': false},
  'antidote': {'itemType': 'Potion', 'isEquippable': false},
  'charm_x': {'itemType': 'Charm', 'rarity': 'Uncommon'},
  'tome_of_insight': {'itemType': 'Tome', 'rarity': 'Uncommon'},
  'tome_of_mastery': {'itemType': 'Tome', 'rarity': 'Rare'},
};

void main() {
  group('fortune roll', () {
    test('a plain fight has no modifiers', () {
      expect(fortuneModifiersFor(const LootContext(chapter: 1)), isEmpty);
      expect(fortuneRollFor(const LootContext(chapter: 1), 42), 42);
    });

    test('luck weighs 2 per point for the player, 1 for the best ally', () {
      final roll = fortuneRollFor(
          const LootContext(chapter: 1, playerLuck: 5, bestAllyLuck: 3), 10);
      expect(roll, 10 + 10 + 3);
    });

    test('every bonus stacks additively', () {
      const ctx = LootContext(
        chapter: 2,
        isElite: true,
        enemyCount: 3,
        flawless: true,
        rounds: 2,
        finalBlowCritical: true,
        affixCount: 2,
        conditionBonus: 10,
        pityStreak: 2,
      );
      expect(fortuneRollFor(ctx, 0), 25 + 12 + 8 + 8 + 8 + 16 + 10 + 30);
    });

    test('a fight past two rounds earns no swift bonus', () {
      expect(fortuneRollFor(const LootContext(chapter: 1, rounds: 3), 0), 0);
    });
  });

  group('tiers', () {
    test('thresholds bucket the roll', () {
      expect(tierForRoll(39), ChestTier.wooden);
      expect(tierForRoll(40), ChestTier.iron);
      expect(tierForRoll(69), ChestTier.iron);
      expect(tierForRoll(70), ChestTier.silver);
      expect(tierForRoll(99), ChestTier.silver);
      expect(tierForRoll(100), ChestTier.gold);
      expect(tierForRoll(124), ChestTier.gold);
      expect(tierForRoll(125), ChestTier.voidTier);
    });

    test('an Elite is never below Silver, a boss never below Gold', () {
      expect(
          finalTierFor(
              const LootContext(chapter: 1, isElite: true), ChestTier.wooden),
          ChestTier.silver);
      expect(
          finalTierFor(const LootContext(chapter: 1, hasBossOrUnique: true),
              ChestTier.iron),
          ChestTier.gold);
      expect(
          finalTierFor(const LootContext(chapter: 1, hasBossOrUnique: true),
              ChestTier.voidTier),
          ChestTier.voidTier);
    });

    test('a first kill is never below Iron', () {
      expect(
          finalTierFor(
              const LootContext(chapter: 1, firstKill: true), ChestTier.wooden),
          ChestTier.iron);
    });

    test('a hunt floor and a fled Skittish shift apply in that order', () {
      expect(
          finalTierFor(const LootContext(chapter: 1, tierFloor: ChestTier.gold),
              ChestTier.wooden),
          ChestTier.gold);
      expect(
          finalTierFor(
              const LootContext(chapter: 1, tierShift: -1), ChestTier.silver),
          ChestTier.iron);
      expect(
          finalTierFor(
              const LootContext(chapter: 1, tierShift: -1), ChestTier.wooden),
          ChestTier.wooden);
    });
  });

  group('gear pool', () {
    test('owned gear and opposed-alignment gear never appear', () {
      final weights = gearWeightsFor(
        const LootContext(
            chapter: 1, alignmentLabel: 'Good', ownedItemIds: ['relic_rare']),
        _items,
        ChestTier.gold,
      );
      expect(weights.containsKey('relic_rare'), isFalse);
      expect(weights.containsKey('unholy'), isFalse);
      expect(weights.containsKey('holy'), isTrue);
      // Matching alignment doubles the weight.
      expect(weights['holy'], 20);
    });

    test('the chapter window keeps late rares out and old commons aged out',
        () {
      final early =
          gearWeightsFor(const LootContext(chapter: 1), _items, ChestTier.gold);
      expect(early.containsKey('late_rare'), isFalse);
      final late =
          gearWeightsFor(const LootContext(chapter: 5), _items, ChestTier.iron);
      // sword_a is a chapter-1 Common: aged out by chapter 5.
      expect(late.containsKey('sword_a'), isFalse);
    });

    test('a signature drop weighs 3x, 6x on a first kill', () {
      final normal = gearWeightsFor(
          const LootContext(chapter: 1, signatureItemIds: ['sword_a']),
          _items,
          ChestTier.iron);
      expect(normal['sword_a'], 30);
      final first = gearWeightsFor(
          const LootContext(
              chapter: 1, signatureItemIds: ['sword_a'], firstKill: true),
          _items,
          ChestTier.iron);
      expect(first['sword_a'], 60);
    });

    test('rarity bands follow the tier', () {
      expect(
          gearWeightsFor(const LootContext(chapter: 1), _items, ChestTier.iron)
              .keys,
          ['sword_a']);
      expect(
          gearWeightsFor(const LootContext(chapter: 1), _items, ChestTier.gold)
              .keys
              .toSet(),
          {'sword_b', 'relic_rare', 'holy', 'unholy'});
    });
  });

  group('rollLootBox', () {
    test('never drops the same gear twice in one chest, nor owned gear', () {
      for (var seed = 0; seed < 300; seed++) {
        final result = rollLootBox(
          const LootContext(
              chapter: 2,
              playerLuck: 8,
              ownedItemIds: ['sword_a'],
              isElite: true),
          _items,
          Random(seed),
        );
        final gear = result.itemIds
            .where((id) => _items[id]['isEquippable'] == true)
            .toList();
        expect(gear.toSet().length, gear.length, reason: 'seed $seed');
        expect(gear, isNot(contains('sword_a')));
        expect(result.gold, greaterThan(0));
        expect(result.itemIds.length, lessThanOrEqualTo(4));
      }
    });

    test('a Void chest always leads with a rare or a tome', () {
      for (var seed = 0; seed < 100; seed++) {
        final result = rollLootBox(
          const LootContext(chapter: 3, tierFloor: ChestTier.voidTier),
          _items,
          Random(seed),
        );
        expect(result.tier, ChestTier.voidTier);
        expect(result.itemIds, isNotEmpty);
        final first = result.itemIds.first;
        final item = _items[first] as Map<String, dynamic>;
        expect(item['rarity'] == 'Rare' || item['itemType'] == 'Tome', isTrue,
            reason: 'seed $seed led with $first');
      }
    });

    test('a full telegraph read adds a slot', () {
      var withExtra = 0;
      var without = 0;
      for (var seed = 0; seed < 100; seed++) {
        withExtra += rollLootBox(
                const LootContext(
                    chapter: 1,
                    tierFloor: ChestTier.silver,
                    fullTelegraphRead: true),
                _items,
                Random(seed))
            .itemIds
            .length;
        without += rollLootBox(
                const LootContext(chapter: 1, tierFloor: ChestTier.silver),
                _items,
                Random(seed))
            .itemIds
            .length;
      }
      expect(withExtra, greaterThan(without));
    });
  });

  group('bookkeeping', () {
    test('pity grows on Wooden, holds on Iron, resets on Silver+', () {
      expect(nextPityStreak(2, ChestTier.wooden), 3);
      expect(nextPityStreak(2, ChestTier.iron), 2);
      expect(nextPityStreak(2, ChestTier.silver), 0);
      expect(nextPityStreak(2, ChestTier.voidTier), 0);
    });

    test('recent drops keep only the last three', () {
      expect(nextRecentLootIds(['a', 'b'], ['c', 'd']), ['b', 'c', 'd']);
      expect(nextRecentLootIds([], ['a']), ['a']);
    });
  });
}
