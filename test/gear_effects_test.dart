// Unit coverage for lib/combat/gear_effects.dart (item sets and unique
// effects) plus a data check on item_sets.json and the unique items.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

void main() {
  final items = _loadGamedata('items.json');
  final sets = parseItemSets(_loadGamedata('item_sets.json'));

  group('parseItemSets', () {
    test('reads both sets with their tiers in ascending piece order', () {
      expect(sets.keys, containsAll(['harborwatch', 'hollow_court']));
      final harbor = sets['harborwatch']!;
      expect(harbor.itemIds.length, 3);
      expect(harbor.tiers.map((t) => t.pieces), [2, 3]);
      expect(harbor.nameFor(AppLanguage.fr), 'Panoplie de la Garde du port');
      expect(harbor.tiers.first.dodgeChance, 5);
      expect(harbor.tiers.last.critChance, 8);
    });
  });

  group('gearEffectsFor', () {
    test('nothing worn, nothing gained', () {
      expect(gearEffectsFor(const [], items, sets).isEmpty, isTrue);
      expect(GearEffects.none.isEmpty, isTrue);
    });

    test('a single set piece grants no tier yet', () {
      final effects = gearEffectsFor(['harborwatch_cutlass'], items, sets);
      expect(effects.isEmpty, isTrue);
      expect(activeSetsFor(['harborwatch_cutlass'], sets).single.piecesWorn, 1);
    });

    test('two pieces reach the first tier, three reach both', () {
      final two = gearEffectsFor(
          ['harborwatch_cutlass', 'harborwatch_coat'], items, sets);
      expect(two.armor, 2);
      expect(two.dodgeChance, 5);
      expect(two.attackDamage, 0);
      final three = gearEffectsFor(
          ['harborwatch_cutlass', 'harborwatch_coat', 'harborwatch_lantern'],
          items,
          sets);
      expect(three.armor, 2);
      expect(three.dodgeChance, 5);
      expect(three.attackDamage, 4);
      expect(three.critChance, 8);
    });

    test('the Hollow Court set stacks thorns and lifesteal', () {
      final full = gearEffectsFor(
          ['hollow_court_blade', 'hollow_court_mantle', 'hollow_court_seal'],
          items,
          sets);
      expect(full.thorns, 4);
      expect(full.lifestealPercent, 10);
      expect(full.attackDamage, 8);
      expect(full.armor, 5);
    });

    test('unique effects read off the worn items', () {
      final effects = gearEffectsFor(
          ['bloodthorn_blade', 'thornmail_hauberk', 'phoenix_sigil'],
          items,
          sets);
      expect(effects.lifestealPercent, 20);
      expect(effects.thorns, 6);
      expect(effects.secondWind, isTrue);
      expect(effects.lifestealFor(50), 10);
      expect(effects.lifestealFor(0), 0);
      expect(gearEffectsFor(['siphon_wand'], items, sets).manaOnHit, 1);
    });

    test('a unique and a set tier add up', () {
      final effects = gearEffectsFor(
          ['thornmail_hauberk', 'hollow_court_blade', 'hollow_court_seal'],
          items,
          sets);
      expect(effects.thorns, 10);
      expect(effects.armor, 5);
    });
  });

  group('setForItem / uniqueEffectOf', () {
    test('finds a set by the item field or by membership', () {
      expect(
          setForItem('hollow_court_seal', items['hollow_court_seal'], sets)?.id,
          'hollow_court');
      expect(setForItem('sword_t3', items['sword_t3'], sets), isNull);
      expect(setForItem('harborwatch_coat', null, sets)?.id, 'harborwatch');
    });

    test('unique effect names parse and unknown ones do not', () {
      expect(uniqueEffectOf(items['bloodthorn_blade']), UniqueEffect.lifesteal);
      expect(uniqueEffectOf(items['sword_t3']), isNull);
      expect(uniqueEffectFromName('nonsense'), isNull);
      expect(uniqueEffectDescriptionKey(UniqueEffect.secondWind),
          'unique_second_wind_desc');
    });
  });

  group('item_sets.json and the unique items', () {
    test('every set piece exists, is equippable and carries its setId', () {
      for (final set in sets.values) {
        expect(set.tiers, isNotEmpty, reason: set.id);
        for (final id in set.itemIds) {
          final item = items[id] as Map<String, dynamic>?;
          expect(item, isNotNull, reason: '${set.id}: missing $id');
          expect(item!['isEquippable'], isTrue, reason: id);
          expect(item['setId'], set.id, reason: id);
          expect(item['lootChapter'], greaterThan(0), reason: id);
        }
        for (final tier in set.tiers) {
          expect(tier.description, isNotEmpty, reason: set.id);
          expect(tier.descriptionFr, isNotEmpty, reason: set.id);
        }
      }
    });

    test('every uniqueEffect on an item is a known effect with a value', () {
      var uniques = 0;
      for (final entry in items.entries) {
        final item = entry.value as Map<String, dynamic>;
        final name = item['uniqueEffect']?.toString() ?? '';
        if (name.isEmpty) continue;
        uniques++;
        expect(uniqueEffectFromName(name), isNotNull, reason: entry.key);
        expect(uniqueValueOf(item), greaterThan(0), reason: entry.key);
        expect(item['rarity'], 'Rare', reason: entry.key);
      }
      expect(uniques, greaterThanOrEqualTo(4));
    });
  });
}
