// Resolve (a stacking bonus against a boss that has beaten the party) and
// the camp's works (houses with a party-wide health/damage bonus), the two
// sources of party_bonus.dart's PartyBonus, plus the shipped works data:
// three late houses priced in the thousands, each behind a flag the story
// sets.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/party_bonus.dart';
import 'package:narrative_data_app/data/materials.dart';
import 'package:narrative_data_app/data/zone_gating.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative under ${Directory.current.path}');
}

void main() {
  group('Resolve', () {
    test('stacks with the defeats a boss dealt, capped', () {
      expect(resolveStacksFor(const {}, const ['void_sovereign']), 0);
      expect(
          resolveStacksFor(const {'void_sovereign': 2}, const ['harbor_rat']),
          0);
      expect(
          resolveStacksFor(
              const {'void_sovereign': 2}, const ['void_sovereign']),
          2);
      expect(
          resolveStacksFor(
              const {'void_sovereign': 9}, const ['void_sovereign']),
          resolveStackCap);
      expect(resolveStacksFor(const {'a': 1, 'b': 3}, const ['a', 'b']), 3,
          reason: 'a pack reads the boss beaten most often');
    });

    test('each stack is a small, equal edge on health and damage', () {
      const bonus = PartyBonus(resolveStacks: 2);
      expect(bonus.healthPercent, 2 * resolvePercentPerStack);
      expect(bonus.damagePercent, 2 * resolvePercentPerStack);
      expect(bonus.scaleMaxHealth(100), 110);
      expect(bonus.scaleDamage(20), 22);
      expect(bonus.scaleCurrentHealth(0), 0,
          reason: 'a knocked-out companion stays knocked out');
      expect(bonus.isNone, isFalse);
      expect(PartyBonus.none.isNone, isTrue);
      expect(PartyBonus.none.scaleMaxHealth(37), 37);
    });
  });

  group("the camp's works", () {
    final houses = {
      'hut': {'buildCost': 10},
      'hall': {'buildCost': 1500, 'partyHealthBonus': 5},
      'loft': {'buildCost': 2500, 'partyDamageBonus': 5},
      'shrine': {
        'buildCost': 4000,
        'partyHealthBonus': 5,
        'partyDamageBonus': 5,
      },
    };

    test('built works add up; unbuilt and unknown ones do not', () {
      expect(houseBonusesFor(const ['hut'], houses),
          (health: 0, damage: 0, companionHealth: 0));
      expect(houseBonusesFor(const ['hall', 'loft'], houses),
          (health: 5, damage: 5, companionHealth: 0));
      expect(houseBonusesFor(const ['hall', 'loft', 'shrine', 'ghost'], houses),
          (health: 10, damage: 10, companionHealth: 0));
    });

    test("the Barracks Annex: the companions' own health, +40% (v1.668)", () {
      final shipped = _loadJson('assets/gamedata/houses.json');
      expect(houseBonusesFor(const ['barracks_annex'], shipped),
          (health: 0, damage: 0, companionHealth: 40));
      final bonus = partyBonusFor(
        bossDefeatCounts: const {},
        enemyIds: const [],
        builtHouseIds: const ['barracks_annex'],
        houses: shipped,
      );
      // The companions only: the party's own bonus is untouched.
      expect(bonus.healthPercent, 0);
      expect(bonus.scaleCompanionMaxHealth(50), 70);
      expect(PartyBonus.none.scaleCompanionMaxHealth(50), 50);
      // No house adds a fighting seat any more.
      for (final h in shipped.values) {
        expect((h as Map)['partyCapacityBonus'], isNull);
      }
    });

    test('Resolve and the works combine into one party bonus', () {
      final bonus = partyBonusFor(
        bossDefeatCounts: const {'void_archon': 1},
        enemyIds: const ['void_archon'],
        builtHouseIds: const ['shrine'],
        houses: houses,
      );
      expect(bonus.resolveStacks, 1);
      expect(bonus.healthPercent, 10);
      expect(bonus.damagePercent, 10);
      expect(bonus.hasHouseBonus, isTrue);
      expect(bonus.healthMultiplier, closeTo(1.10, 1e-9));
    });

    test('the shipped works cost thousands and wait on the story', () {
      final shipped = _loadJson('assets/gamedata/houses.json');
      final works = shipped.entries.where((e) {
        final h = e.value as Map<String, dynamic>;
        return ((h['partyHealthBonus'] as num?) ?? 0) > 0 ||
            ((h['partyDamageBonus'] as num?) ?? 0) > 0;
      }).toList();
      expect(works.map((e) => e.key).toSet(),
          {'hearth_hall', 'banner_loft', 'shroud_shrine'});
      var total = 0;
      for (final entry in works) {
        final h = entry.value as Map<String, dynamic>;
        final cost = (h['buildCost'] as num).toInt();
        // Gold and materials since v1.281.0 (gold down a third, each work
        // needing its tier's rare, see materials.dart).
        expect(cost, greaterThanOrEqualTo(1000), reason: entry.key);
        expect(
            materialCountsOf(h, 'materialCost').keys.any((id) => {
                  for (final t in materialTiers.values)
                    if (t.rare != null) t.rare!,
                }.contains(id)),
            isTrue,
            reason: '${entry.key} needs a rare material');
        expect(requiredFlagsOf(h), isNotEmpty, reason: entry.key);
        expect(h['description']?.toString() ?? '', isNotEmpty);
        total += cost;
      }
      // 4 600 once the Shroud Shrine costs 2 000 (so that it comes
      // in its tier's chapters, see sim_houses_test.dart).
      expect(total, greaterThanOrEqualTo(4500),
          reason: 'together they sink most of a finished run\'s spare gold');
      // Together a small edge, not a new difficulty: the Sovereign stays
      // the fight of the game (at +10/+10 simulated parties beat it first
      // try 90% of the time, up from 65%).
      final all = houseBonusesFor(works.map((e) => e.key), shipped);
      expect(all, (health: 5, damage: 5, companionHealth: 0));
    });
  });
}
