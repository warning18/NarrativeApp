// The Tower's rulesets side by side (rules 3, docs/simulation/
// tower-difficulty-survival.md: the survival curve, for new climbs only).
// A climb keeps the rules it began with: a rules-2 climb saved before
// rules 3 shipped plays on today's rules-2 numbers, a save without the
// field on rules 1, and a new climb on rules 3. The pins below were read
// on main v2.10.27 (rules 2 live), before rules 3 was built.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_levelup_loot.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';

/// A rules-2 climb mid-way, as v2.10.27 saved it: the bot's seed 21 with
/// every unlock (an orc mage), on floor 7, its floors 1 to 6 paid in Tower
/// XP, four Level Ups taken, six loot cards.
const _rules2Save =
    '{"seed":21,"race":"orc","profession":"mage","pool":["dominion",'
    '"vigil","compact","mire","crows","penitents"],"unlocks":["flame_die",'
    '"shield_t5","tide_die","sword_t4","tearglass_die"],"owned":10,'
    '"floor":7,"health":29,"status":"climbing","picks":[],"potions":3,'
    '"die":"apprentice_die","seen":["apprentice_die"],"crest":2,"events":2,'
    '"store":6,"coins":5,"coinsEarned":11,"rerolls":{"3":1,"5":1},'
    '"rules":2,"xp":{"1":3,"2":2,"3":2,"4":2,"5":4,"6":3},'
    '"levelUps":{"1":[{"kind":"skill","id":"heavy_attack","clan":"mire"}],'
    '"3":[{"kind":"skill","id":"orc_savage_cleave","clan":"mire"}],'
    '"5":[{"kind":"rankUp","id":"orc_berserk_rage","clan":"dominion"}],'
    '"6":[{"kind":"skill","id":"warden_bone_storm","clan":"penitents"}]},'
    '"loot":{"1":{"kind":"bundle","id":"p3a0","amount":2},'
    '"2":{"kind":"gear","id":"sword_t2"},"3":{"kind":"gear",'
    '"id":"shield_t2"},"4":{"kind":"gear","id":"staff_t2"},'
    '"5":{"kind":"purse","amount":2},"6":{"kind":"gear","id":"sword_t3"}}}';

void main() {
  final data = towerDataFromAssets();

  String gift(TowerReward c) =>
      '${c.kind.name}:${c.id}${c.amount == 0 ? '' : '*${c.amount}'}';

  /// [run] played [floors] floors on: each fight won with 60% of the
  /// health it began with left, the first card of every table taken; what
  /// the player would see after each step.
  List<String> trace(TowerRun run, int floors) {
    final out = <String>[];
    for (var i = 0; i < floors && run.status == TowerStatus.climbing; i++) {
      final hero = towerHeroOf(run, data);
      final floor = towerFloorOf(run, data);
      out.add('f${floor.floor} lvl ${hero.level} '
          'pending ${towerLevelUpsPending(run)} '
          'extra ${floor.extraFor(run.professionId).toStringAsFixed(4)}');
      run = towerAfterFight(run, data,
          won: true,
          healthLeft: (hero.currentHealth * .6).round(),
          potionsLeft: run.potions,
          maxHealthBefore: hero.maxHealth);
      final after = towerHeroOf(run, data);
      out.add('  won: lvl ${after.level} max ${after.maxHealth} '
          'hp ${run.health} xp ${towerXpOf(run)} coins ${run.coins}');
      for (var g = 0; run.status == TowerStatus.choosing && g < 10; g++) {
        out.add('  ${run.table?.name}: ${run.offer.map(gift).join(' ')}');
        run = towerPick(run, data, 0);
      }
      final h = towerHeroOf(run, data);
      out.add('  str ${h.strength} dex ${h.dexterity} '
          'con ${h.constitution} int ${h.intelligence} wis ${h.wisdom} '
          'per ${h.perception} max ${h.maxHealth} hp ${run.health} '
          'potions ${run.potions}');
    }
    return out;
  }

  /// A whole bot climb, as the pins read it.
  String climb(int seed, int rules, TowerProgress progress) {
    final r = playTowerRun(
        seed: seed,
        data: data,
        progress: progress,
        events: towerEventsLive,
        rules: rules);
    final ups = rules >= 2 ? towerLevelUpsTaken(r) : r.statPicks.length;
    return '${r.rules} ${r.status.name} ${r.floorReached} ${r.floorsCleared} '
        '$ups ${r.coinsEarned} ${r.health} ${r.marks}';
  }

  group('a rules-2 climb saved before rules 3', () {
    final run =
        TowerRun.fromJson(jsonDecode(_rules2Save) as Map<String, dynamic>);

    test('loads on rules 2, every field kept', () {
      expect(run.rules, 2);
      expect(run.floor, 7);
      expect(run.xp, {1: 3, 2: 2, 3: 2, 4: 2, 5: 4, 6: 3});
      expect(run.levelUps.keys, [1, 3, 5, 6]);
      expect(run.loot, hasLength(6));
      // Today's rules-2 numbers: 2 XP at the start, 4 a level.
      expect(towerXpOf(run), 2 + 16);
      expect(towerHeroOf(run, data).level, 5);
      expect(towerLevelUpsPending(run), 0);
      expect(towerRulesScaleOf(run.rules, run.professionId, floor: 7),
          towerRulesScaleOf(2, run.professionId));
      // Saved again, still rules 2.
      expect(
          TowerRun.fromJson(
                  jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>)
              .rules,
          2);
    });

    test('its next floors play as on v2.10.27', () {
      expect(trace(run, 6), [
        'f7 lvl 5 pending 0 extra 0.2710',
        '  won: lvl 6 max 37 hp 26 xp 20 coins 6',
        '  loot: gear:greaves_studded purse:*2 bundle:p3a0*2',
        '  levelUp: skill:archon_eclipse rankUp:orc_berserk_rage die:headsman_die',
        '  str 3 dex 0 con 2 int 3 wis 1 per 3 max 37 hp 26 potions 3',
        'f8 lvl 6 pending 0 extra 0.2559',
        '  won: lvl 6 max 37 hp 22 xp 22 coins 7',
        '  loot: gear:staff_t3 bundle:p1a1*1 gear:spear_t3',
        '  str 3 dex 0 con 2 int 3 wis 1 per 3 max 37 hp 22 potions 3',
        'f9 lvl 6 pending 0 extra 0.2559',
        '  won: lvl 7 max 40 hp 22 xp 24 coins 8',
        '  loot: gear:dagger_t3 gear:boots_tidewalker gear:spear_t3',
        '  levelUp: rankUp:orc_berserk_rage rankUp:archon_eclipse spell:spell_ember_wave',
        '  str 3 dex 0 con 2 int 4 wis 1 per 3 max 40 hp 22 potions 3',
        'f10 lvl 7 pending 0 extra 0.3914',
        '  won: lvl 8 max 43 hp 22 xp 28 coins 13',
        '  loot: purse:*2 gear:artifact_moon_shard gear:helm_iron_cap',
        '  levelUp: rankUp:orc_berserk_rage rankUp:archon_eclipse die:pilgrim_die',
        '  str 3 dex 0 con 2 int 4 wis 1 per 3 max 43 hp 22 potions 3',
        'f11 lvl 8 pending 0 extra 0.2520',
        '  won: lvl 8 max 43 hp 19 xp 30 coins 17',
        '  loot: gear:boots_iron_shod purse:*2 gear:blackened_fang',
        '  str 3 dex 0 con 2 int 4 wis 1 per 3 max 43 hp 19 potions 3',
        'f12 lvl 8 pending 0 extra 0.2520',
        '  won: lvl 9 max 46 hp 21 xp 32 coins 19',
        '  loot: bundle:p4a0*3 gear:boots_bone_laced gear:saint_reliquary',
        '  levelUp: rankUp:archon_eclipse rankUp:mage_channel spell:spell_ember_wave',
        '  str 3 dex 0 con 2 int 4 wis 1 per 3 max 46 hp 45 potions 5',
      ]);
    });

    test('the bot climbs on rules 2 and 1 play as on v2.10.27', () {
      expect(climb(21, 2, towerAllUnlocked), '2 dead 15 14 9 31 0 21');
      expect(climb(12, 1, const TowerProgress()), '1 won 30 30 17 82 58 61');
      expect(climb(7, 2, const TowerProgress()), '2 dead 24 23 14 64 0 37');
    });
  });

  group('rules 1 and 3', () {
    test('a save without the field is rules 1', () {
      final old = towerStart(
          seed: 12, raceId: 'human', professionId: 'warrior', data: data);
      expect(old.rules, 1);
      final json = old.toJson()..remove('rules');
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(back.rules, 1);
      // Rules 1: the spoils chest and the stat picks, no Tower XP.
      final after =
          towerAfterFight(back, data, won: true, healthLeft: back.health);
      expect(after.spoils[1], isNotNull);
      expect(after.xp, isEmpty);
      expect(towerPendingPicks(after), greaterThan(0));
    });

    test('a new climb is rules 3, and keeps it saved and loaded', () {
      expect(towerRulesLive, 3);
      expect(towerSurvivalRules, 3);
      final run = towerStart(
          seed: 4,
          raceId: 'human',
          professionId: 'rogue',
          rules: towerRulesLive,
          data: data);
      expect(run.rules, 3);
      final back = TowerRun.fromJson(
          jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
      expect(back.rules, 3);
      expect(towerXpOf(back), 0);
      // The same seed's foes: harder on rules 3 than on rules 2 on floor 1.
      final two = towerFloorsFor(4, data.enemies, rules: 2).first;
      final three = towerFloorsFor(4, data.enemies, rules: 3).first;
      expect(three.extraFor('rogue'), greaterThan(two.extraFor('rogue')));
    });

    test('a rules-2 and a rules-3 hero of the same climb are not mixed up', () {
      // towerHeroOf keeps the heroes it built: the same seed, race and
      // unlocks on rules 2 and 3 give two heroes.
      TowerRun of(int rules) => towerStart(
          seed: 30,
          raceId: 'human',
          professionId: 'mage',
          unlocksOwned: 10,
          rules: rules,
          data: data);
      final two = towerHeroOf(of(2), data).maxHealth;
      final three = towerHeroOf(of(3), data).maxHealth;
      expect(three, greaterThan(two));
      expect(towerHeroOf(of(2), data).maxHealth, two);
    });
  });
}
