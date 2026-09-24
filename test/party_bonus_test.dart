// Resolve (a stacking bonus against a boss that has beaten the party) and
// the camp's works (houses with a party-wide health/damage bonus), the two
// sources of party_bonus.dart's PartyBonus, plus the shipped works data:
// three late houses priced in the thousands, each behind a flag the story
// sets.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/party_bonus.dart';
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
      expect(houseBonusesFor(const ['hut'], houses), (health: 0, damage: 0));
      expect(houseBonusesFor(const ['hall', 'loft'], houses),
          (health: 5, damage: 5));
      expect(houseBonusesFor(const ['hall', 'loft', 'shrine', 'ghost'], houses),
          (health: 10, damage: 10));
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
        expect(cost, greaterThanOrEqualTo(1500), reason: entry.key);
        expect(requiredFlagsOf(h), isNotEmpty, reason: entry.key);
        expect(h['description']?.toString() ?? '', isNotEmpty);
        total += cost;
      }
      expect(total, greaterThanOrEqualTo(8000),
          reason: 'together they sink most of a finished run\'s spare gold');
      // Together a small edge, not a new difficulty: the Sovereign stays
      // the fight of the game (at +10/+10 simulated parties beat it first
      // try 90% of the time, up from 65%).
      final all = houseBonusesFor(works.map((e) => e.key), shipped);
      expect(all, (health: 5, damage: 5));
    });
  });
}
