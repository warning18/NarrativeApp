// The cards on one table are always distinct gifts (the user's report of
// v2.10.x: "I have 3 times the same reward sometimes"; docs/feedback/
// tower-clan-offer-duplicates.jpg on the manager's branch). With the die in
// play full, every clan's gift skill finds no face and turns into a rank-up
// (towerRankUpFor); each named the die's best skill, so the three clans of
// floor 1 offered the same rank-up. A table now never holds two cards of
// the same kind and id: a later rank-up names the next best skill on the
// die, and when none is left the clan's next gift, a pool skill, or no card
// at all takes its place.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show maxSkillTier;
import 'package:narrative_data_app/data/tower/tower_bot.dart'
    show towerDataFromAssets;
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

const int _seeds = 500;
const _heroes = [
  ('human', 'warrior'),
  ('elf', 'mage'),
  ('dwarf', 'cleric'),
  ('human', 'rogue'),
  ('orc', 'ranger'),
];

/// The table's duplicates (kind and id), as text; empty when every card
/// is its own.
List<String> _duplicates(List<TowerReward> table) {
  final seen = <String>{};
  return [
    for (final c in table)
      if (!seen.add('${c.kind.name}:${c.id}')) '${c.kind.name}:${c.id}',
  ];
}

void main() {
  final data = towerDataFromAssets();
  final races = {...data.races.keys};
  final professions = {...data.professions.keys};
  final heroes = [
    for (final (race, profession) in _heroes)
      if (races.contains(race) && professions.contains(profession))
        (race, profession),
  ];

  TowerRun startOf(int seed, {Iterable<String> perks = const []}) {
    final (race, profession) = heroes[seed % heroes.length];
    return towerStart(
        seed: seed,
        raceId: race,
        professionId: profession,
        perks: perks,
        data: data);
  }

  test('the heroes of the test exist', () {
    expect(heroes, isNotEmpty);
  });

  // (a) The bug's case: the start's die is full, floor 1's clans are due.
  test('floor 1: the three clans never offer the same gift', () {
    var rankUpTables = 0;
    final bad = <String>[];
    for (var seed = 1; seed <= _seeds; seed++) {
      final run = startOf(seed);
      expect(run.clanPool.length, greaterThanOrEqualTo(3));
      final hero = towerHeroOf(run, data);
      final table = towerRunOfferFor(run, data, 1, hero, clansDue: true);
      final dup = _duplicates(table);
      if (dup.isNotEmpty) bad.add('seed $seed: $table');
      final ups = [
        for (final c in table)
          if (c.kind == TowerRewardKind.rankUp) c.id,
      ];
      expect(ups.toSet().length, ups.length, reason: 'seed $seed: $table');
      if (ups.length > 1) rankUpTables++;
      // Each clan offers at most once.
      final clans = [
        for (final c in table)
          if (c.clan.isNotEmpty) c.clan,
      ];
      expect(clans.toSet().length, clans.length, reason: 'seed $seed');
    }
    expect(bad, isEmpty, reason: bad.take(5).join('\n'));
    // The case is real: tables with several rank-ups are dealt.
    expect(rankUpTables, greaterThan(0));
  });

  // (b) Every other table that deals several cards.
  group('no table deals the same card twice', () {
    test('boon floors (and Fourth card\'s extra skill)', () {
      final bad = <String>[];
      final floors = towerBoonFloors.toList()..sort();
      for (var seed = 1; seed <= _seeds; seed++) {
        final run = startOf(seed,
            perks: seed.isEven ? const [towerPerkFourthCard] : const []);
        final hero = towerHeroOf(run, data);
        final floor = floors[seed % floors.length];
        final table = towerRunOfferFor(run, data, floor, hero);
        if (_duplicates(table).isNotEmpty) bad.add('seed $seed: $table');
      }
      expect(bad, isEmpty, reason: bad.take(5).join('\n'));
    });

    test('the stall\'s boon', () {
      final bad = <String>[];
      for (var seed = 1; seed <= _seeds; seed++) {
        final run = startOf(seed);
        final hero = towerHeroOf(run, data);
        final table = towerStallBoonFor(run, data, 1 + seed % 29, hero);
        if (_duplicates(table).isNotEmpty) bad.add('seed $seed: $table');
      }
      expect(bad, isEmpty, reason: bad.take(5).join('\n'));
    });

    test('a reroll of the clans\' table', () {
      final bad = <String>[];
      for (var seed = 1; seed <= _seeds; seed++) {
        final run = startOf(seed);
        final hero = towerHeroOf(run, data);
        var choosing = run.copyWith(
            status: TowerStatus.choosing,
            coins: 999,
            offer:
                towerRunOfferFor(run, data, run.floor, hero, clansDue: true));
        for (var i = 0; i < 3 && towerCanReroll(choosing); i++) {
          choosing = towerReroll(choosing, data, hero: hero);
          if (_duplicates(choosing.offer).isNotEmpty) {
            bad.add('seed $seed reroll $i: ${choosing.offer}');
          }
        }
      }
      expect(bad, isEmpty, reason: bad.take(5).join('\n'));
    });

    test('a shortcut\'s landing (any floor, clans due or by chance)', () {
      final bad = <String>[];
      for (var seed = 1; seed <= _seeds; seed++) {
        final run = startOf(seed);
        final hero = towerHeroOf(run, data);
        final floor = 2 + seed % 28;
        final table =
            towerRunOfferFor(run, data, floor, hero, clansDue: seed.isOdd);
        if (_duplicates(table).isNotEmpty) bad.add('seed $seed: $table');
      }
      expect(bad, isEmpty, reason: bad.take(5).join('\n'));
    });
  });

  // (c) A die with a single skill that can still rank up: at most one
  // rank-up on a table, the others another kind or no card.
  test('one rankable skill: at most one rank-up a table', () {
    var withRankUp = 0;
    for (var seed = 1; seed <= _seeds; seed++) {
      final run = startOf(seed);
      final hero = towerHeroOf(run, data);
      final onDie = hero.diceSkillAssignments.values.toSet().toList()..sort();
      if (onDie.isEmpty) continue;
      final view = towerHeroView(run, hero);
      final single = TowerHeroView(
        raceId: view.raceId,
        professionId: view.professionId,
        clanIds: view.clanIds,
        health: view.health,
        maxHealth: view.maxHealth,
        equippedItemIds: view.equippedItemIds,
        ownedDiceIds: view.ownedDiceIds,
        unlockedSkillIds: view.unlockedSkillIds,
        knownSpellIds: view.knownSpellIds,
        takenIds: view.takenIds,
        diceFaces: view.diceFaces,
        diceSkillAssignments: view.diceSkillAssignments,
        // Every skill on the die at the last tier but one.
        skillTiers: {for (final id in onDie.skip(1)) id: maxSkillTier},
      );
      final table = towerOfferFor(
        seed: seed,
        floor: 1,
        hero: single,
        clanPool: run.clanPool,
        clansDue: true,
        clans: data.clans,
        items: data.items,
        dice: data.dice,
        skills: data.skills,
        spells: data.spells,
      );
      expect(_duplicates(table), isEmpty, reason: 'seed $seed: $table');
      final ups = table.where((c) => c.kind == TowerRewardKind.rankUp);
      expect(ups.length, lessThanOrEqualTo(1), reason: 'seed $seed: $table');
      for (final c in ups) {
        expect(c.id, onDie.first, reason: 'seed $seed: $table');
      }
      if (ups.isNotEmpty) withRankUp++;
    }
    expect(withRankUp, greaterThan(0));
  });
}
