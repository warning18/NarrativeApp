// The Tower's engine (v1.845, docs/proposals/tower-mechanics.md): the same
// seed builds the same tower and plays the same run; every floor's foes
// come from its pool; a run always ends, won or dead, and earns its marks;
// the run and the marks round-trip through their own save, apart from the
// story's.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/fight_numbers.dart'
    show potionHealAmount;
import 'package:narrative_data_app/data/sim_combat.dart' show SimCharacter;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/providers/save_game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();
  final seeds = List.generate(20, (i) => i + 1);

  group('the floors', () {
    test('the same seed builds the same 30 floors; another seed others', () {
      String tower(int seed) => [
            for (final f in towerFloorsFor(seed, data.enemies))
              '${f.floor}:${f.enemyIds.join('+')}:${f.affixes}:${f.elite}',
          ].join(' ');
      expect(tower(7), tower(7));
      expect(tower(7), isNot(tower(8)));
      expect(towerFloorsFor(7, data.enemies), hasLength(towerTop));
    });

    test('every floor\'s foes are in its pool; bosses and wardens their own',
        () {
      for (final seed in seeds) {
        for (final f in towerFloorsFor(seed, data.enemies)) {
          expect(f.enemyIds, isNotEmpty);
          for (final id in f.enemyIds) {
            expect(data.enemies, contains(id), reason: id);
          }
          switch (f.kind) {
            case TowerFloorKind.boss:
              expect(f.enemyIds, [towerBosses[f.floor]]);
            case TowerFloorKind.warden:
              expect(towerWardens[f.floor], contains(f.enemyIds.single));
            case TowerFloorKind.fight:
              final pool = towerPoolOf(f.chapter, data.enemies);
              expect(pool, containsAll(f.enemyIds.toSet()),
                  reason: '${f.floor}');
              // Elites are alone; a pack leader only leads a pack.
              if (f.elite) expect(f.isPack, isFalse);
          }
        }
      }
      // The pool keeps out the story's duels and the companions turned.
      final pool = towerPoolOf(8, data.enemies);
      expect(pool, isNot(contains('kelda_turned')));
      expect(pool, isNot(contains('claimant_morrow')));
      expect(pool, isNot(contains('kraken_arm')));
      // A floor 10, 20 and 30 for each boss Narrative named.
      expect(towerBosses.keys, [10, 20, 30]);
      expect(towerBosses[30], 'void_sovereign');
    });

    test('a floor fights with the Tower\'s context: no scene, no chest', () {
      final floor = towerFloorsFor(3, data.enemies)[11];
      final m = floor.modifiersFor('warrior');
      expect(m.tower, isTrue);
      expect(m.chapter, floor.chapter);
      expect(m.difficultyMultiplier,
          closeTo(floor.extra * .90 * towerFoeScale, 1e-9));
      expect(floor.modifiersFor('mage').difficultyMultiplier,
          closeTo(floor.extra * .72 * towerFoeScale, 1e-9));
      expect(m.forcedAffixes, floor.affixes);
      expect(m.lossContinues, isTrue);
      expect(m.keepWounds, isTrue);
    });
  });

  group('a run', () {
    test('the same seed plays the same run, and every run ends', () {
      for (final seed in seeds) {
        final run = playTowerRun(seed: seed, data: data);
        expect(run.isOver, isTrue, reason: '$seed');
        expect(run.status, anyOf(TowerStatus.won, TowerStatus.dead));
        expect(jsonEncode(playTowerRun(seed: seed, data: data).toJson()),
            jsonEncode(run.toJson()),
            reason: '$seed');
      }
    });

    test('a loss ends the run and earns its marks', () {
      final run = seeds
          .map((s) => playTowerRun(seed: s, data: data))
          .firstWhere((r) => r.status == TowerStatus.dead && r.floor > 1);
      expect(run.floorsCleared, run.floor - 1);
      expect(run.marks, towerMarksOf(run.floorsCleared, run.refused.length));
      expect(run.marks, greaterThan(0));
      final progress = const TowerProgress().afterRun(run);
      expect(progress.marks, run.marks);
      expect(progress.runs, 1);
      expect(progress.bestFloor, run.floor);
      // An ended run moves no further.
      expect(towerAfterFight(run, data, won: true, healthLeft: 9), same(run));
      expect(towerPick(run, data, 0), same(run));
    });

    test('the marks: a floor, a warden, a boss, the top', () {
      expect(towerMarksOf(0, 0), 0);
      expect(towerMarksOf(11, 0), 11 + 2 + 5);
      expect(towerMarksOf(towerTop, 0), 61);
      expect(towerMarksOf(towerTop, 3), 64);
    });

    test(
        'a won floor drops its spoils; a boon floor offers a skill, a die '
        'and a spell; never gold', () {
      var run = towerStart(
          seed: 5,
          raceId: 'human',
          professionId: 'warrior',
          clanId: 'dominion',
          data: data);
      run = towerAfterFight(run, data, won: true, healthLeft: run.health);
      expect(run.status, TowerStatus.choosing);
      // The story's chest: its gear and potions only, never its gold.
      final spoils = run.spoils[1]!;
      expect(spoils, isNotEmpty);
      for (final id in spoils) {
        final item = data.items[id] as Map;
        expect(item['isEquippable'] == true || item['itemType'] == 'Potion',
            isTrue,
            reason: id);
      }
      // Floors 1 to 4 bring no boon: at most a clan's oath.
      expect(
          run.offer.every((r) => r.kind == TowerRewardKind.clanOath), isTrue);
      for (var floor = 1; floor < 5; floor++) {
        if (floor > 1) {
          run = towerAfterFight(run, data, won: true, healthLeft: run.health);
        }
        final before = run.refused.length;
        final offered = run.offer.isNotEmpty;
        run = towerPick(run, data, null);
        // Nothing on the table refuses nothing.
        expect(run.refused.length, before + (offered ? 1 : 0));
      }
      run = towerAfterFight(run, data, won: true, healthLeft: run.health);
      expect(run.floor, 5);
      expect(run.offer.map((r) => r.kind).toSet(),
          {TowerRewardKind.skill, TowerRewardKind.die, TowerRewardKind.spell});
      // Picking takes the card to the next floor; refusing earns a mark.
      final picked = towerPick(run, data, 0);
      expect(picked.floor, 6);
      expect(picked.status, TowerStatus.climbing);
      expect(picked.taken[5], run.offer.first);
      final refused = towerPick(run, data, null);
      expect(refused.refused, contains(5));
      expect(refused.marks, run.marks + towerMarksPerRefusal);
    });

    test('the bag keeps the spoils\' potions past the flask', () {
      var run = towerStart(
          seed: 3, raceId: 'human', professionId: 'warrior', data: data);
      run = run.copyWith(potions: 2);
      final flask = towerHeroOf(run, data).potions - 2;
      // A fight that drank the flask and one more: the bag holds one.
      run = towerAfterFight(run, data,
          won: true, healthLeft: run.health, potionsLeft: 1);
      final looted =
          run.spoils[1]!.fold(0, (n, id) => n + (towerSpoilsPotions[id] ?? 0));
      expect(run.potions, min(towerBagCap, 1 + looted));
      expect(towerHeroOf(run, data).potions, flask + run.potions);
      // The save keeps the spoils and the bag.
      final back = TowerRun.fromJson(run.toJson());
      expect(back.spoils, run.spoils);
      expect(back.potions, run.potions);
    });

    test('a hero handed on is the hero towerHeroOf builds', () {
      // The bot builds each step's hero once and hands it on (v1.864):
      // the moves must come out as they do when they build it themselves.
      for (var seed = 1; seed <= 6; seed++) {
        var run = towerStart(
            seed: seed, raceId: 'human', professionId: 'mage', data: data);
        for (var floor = 1; floor <= 6 && !run.isOver; floor++) {
          final before = towerHeroOf(run, data).maxHealth;
          final a = towerAfterFight(run, data,
              won: true, healthLeft: run.health, maxHealthBefore: before);
          expect(
              a.toJson(),
              towerAfterFight(run, data, won: true, healthLeft: run.health)
                  .toJson());
          run = a;
          while (towerPendingPicks(run) > 0) {
            final hero = towerHeroOf(run, data);
            final offer = towerStatPickOffer(run, data, hero: hero);
            expect(offer, towerStatPickOffer(run, data));
            run = towerTakeStatPick(run, data, 1, offer: offer);
          }
          final pick = run.offer.isEmpty ? null : 0;
          final handed =
              towerPick(run, data, pick, hero: towerHeroOf(run, data));
          expect(handed.toJson(), towerPick(run, data, pick).toJson());
          run = handed;
        }
      }
    });

    test('the bag holds 5 potions; what the chest gives past them heals', () {
      // v1.865: the bag is capped, the rest drunk at once at the story's
      // potion heal.
      var checked = 0;
      for (var seed = 1; seed <= 30; seed++) {
        final run = towerStart(
                seed: seed,
                raceId: 'human',
                professionId: 'warrior',
                data: data)
            .copyWith(potions: towerBagCap);
        final full = towerAfterFight(run, data,
            won: true, healthLeft: 1, potionsLeft: towerBagCap + 1);
        final looted = full.spoils[1]!
            .fold<int>(0, (n, id) => n + (towerSpoilsPotions[id] ?? 0));
        if (looted == 0) continue;
        checked++;
        expect(full.potions, towerBagCap);
        // The same chest into an empty bag: all of it kept, none drunk.
        final empty = towerAfterFight(run.copyWith(potions: 0), data,
            won: true, healthLeft: 1, potionsLeft: 1);
        expect(empty.spoils[1], full.spoils[1]);
        expect(empty.potions, looted);
        expect(
            full.health,
            min(towerHeroOf(full, data).maxHealth,
                empty.health + looted * potionHealAmount));
      }
      expect(checked, greaterThan(3));
    });

    test('no chest is empty: every slot gear or a potion', () {
      for (var seed = 1; seed <= 40; seed++) {
        for (final floor in towerFloorsFor(seed, data.enemies).take(12)) {
          final drop =
              towerSpoilsFor(seed: seed, floor: floor, items: data.items);
          expect(drop, isNotEmpty, reason: 'seed $seed floor ${floor.floor}');
        }
      }
    });

    test('leaving ends the run with what it earned', () {
      final run = towerAbandon(towerStart(
          seed: 1,
          raceId: 'elf',
          professionId: 'mage',
          clanId: 'mire',
          data: data));
      expect(run.status, TowerStatus.abandoned);
      expect(run.isOver, isTrue);
      expect(run.marks, 0);
    });
  });

  group('the save', () {
    test('a run round-trips, mid-choice, with the same hero', () {
      var run = playTowerRun(seed: 4, data: data);
      // Replay to a floor with cards on the table.
      run = towerStart(
          seed: 4,
          raceId: run.raceId,
          professionId: run.professionId,
          clanId: run.mainClanId,
          data: data);
      run = towerAfterFight(run, data, won: true, healthLeft: run.health - 3);
      run = towerPick(run, data, 1);
      run = towerAfterFight(run, data, won: true, healthLeft: run.health - 2);
      final again = TowerRun.fromJson(
          jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(again.toJson()), jsonEncode(run.toJson()));
      expect(again.offer, run.offer);
      final a = towerHeroOf(run, data), b = towerHeroOf(again, data);
      expect(b.maxHealth, a.maxHealth);
      expect(b.currentHealth, a.currentHealth);
      expect(b.level, a.level);
      expect(b.equippedItemIds, a.equippedItemIds);
      expect(b.diceId, a.diceId);
    });

    test('its own keys: banked on a run\'s end, apart from the story\'s',
        () async {
      SharedPreferences.setMockInitialValues(
          {'saved_game_slot_1': '{"story":"kept"}'});
      final save = await TowerSave.open();
      final run = towerStart(
          seed: 2,
          raceId: 'dwarf',
          professionId: 'rogue',
          clanId: 'penitents',
          data: data);
      await save.saveRun(run);
      expect(jsonEncode(save.loadRun()!.toJson()), jsonEncode(run.toJson()));
      final dead = playTowerRun(seed: 2, data: data);
      final progress = await save.endRun(dead);
      expect(progress.marks, dead.marks);
      expect(save.loadRun(), isNull);
      expect(save.loadProgress().marks, dead.marks);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('saved_game_slot_1'), '{"story":"kept"}');
      // Deleting every story save leaves the Tower's alone.
      await save.saveRun(run);
      await SavedGamesNotifier().deleteAll();
      expect(prefs.getString(towerMarksPrefsKey), isNotNull);
      expect(prefs.getString(towerRunPrefsKey), isNotNull);
      expect(prefs.getString('saved_game_slot_1'), isNull);
    });
  });

  group('the unlocks', () {
    test('bought for their marks, in order, once', () {
      var p = const TowerProgress(marks: 25);
      expect(p.professions, {'warrior', 'mage', 'rogue'});
      expect(p.clans, {'dominion', 'mire', 'penitents'});
      expect(p.canBuy('tide_die'), isFalse, reason: 'needs the Flame Die');
      p = p.buy('flame_die');
      expect(p.marks, 15);
      expect(p.unlocked, {'flame_die'});
      expect(p.buy('flame_die'), same(p), reason: 'bought already');
      p = p.buy('cleric');
      expect(p.professions, contains('cleric'));
      expect(p.canBuy('tide_die'), isFalse, reason: '0 marks left');
      expect(p.startUnlocks, ['flame_die']);
      expect(towerUnlocks.fold(0, (a, u) => a + u.cost), 210);
      expect(towerAllUnlocked.professions, containsAll(['cleric', 'ranger']));
      expect(towerAllUnlocked.clans, hasLength(6));
    });

    test('a start die is owned and a start item worn from floor 1', () {
      final run = towerStart(
          seed: 3,
          raceId: 'human',
          professionId: 'warrior',
          clanId: 'crows',
          startUnlocks: towerAllUnlocked.startUnlocks,
          data: data);
      final hero = towerHeroOf(run, data);
      expect(hero.ownedDice.keys,
          containsAll(['flame_die', 'tide_die', 'tearglass_die']));
      expect(hero.ownedItemIds, containsAll(['shield_t5', 'sword_t4']));
      expect(hero.equippedItemIds, isNotEmpty);
    });
  });

  test('the bot climbs: some seed passes floor 10, runs are quick', () {
    final watch = Stopwatch()..start();
    final runs = playTowerBatch(List.generate(40, (i) => i + 1), data);
    final perRun = watch.elapsedMilliseconds / runs.length;
    final floors = runs.map((r) => r.floorReached).toList()..sort();
    expect(floors.last, greaterThan(10), reason: '$floors');
    expect(floors[floors.length ~/ 2], greaterThan(3), reason: '$floors');
    expect(perRun, lessThan(500), reason: '$perRun ms a run');
  });

  // The difficulty review's finding 3 (v1.922): a human or voidkin climber
  // starts with points in the calling's damage stat, and its base damage;
  // the other peoples start as the story's character does.
  test('humans and voidkin start with their Tower points', () {
    int stat(SimCharacter c) => switch (c.preferredStat) {
          'strength' => c.strength,
          'dexterity' => c.dexterity,
          'intelligence' => c.intelligence,
          _ => c.wisdom,
        };
    for (final race in data.races.keys) {
      for (final profession in ['warrior', 'mage', 'rogue']) {
        final story = SimCharacter.create(
          raceId: race,
          race: data.races[race] as Map<String, dynamic>,
          professionId: profession,
          profession: data.professions[profession] as Map<String, dynamic>,
          gameConfig: data.gameConfig,
          dice: data.dice,
          spells: data.spellSpecs,
        );
        final tower = towerFreshHero(race, profession, const [], data);
        final points = towerPeoplePoints[race] ?? 0;
        expect(stat(tower) - stat(story), points, reason: '$race $profession');
        if (points == 0) {
          expect(tower.baseDamage, story.baseDamage, reason: race);
        } else {
          expect(tower.baseDamage, greaterThanOrEqualTo(story.baseDamage));
        }
      }
    }
    expect(towerPeoplePoints, {'human': 2, 'voidkin': 3});
  });
}
