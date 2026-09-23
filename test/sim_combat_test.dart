// Unit coverage for lib/data/sim_combat.dart -- the in-app playthrough
// simulator's fight model: character creation mirrors startNewGame, Mana
// faces feed the pool, the caster policy spends it, a loss refills it, a
// shop visit buys gear, potions and the profession's spellbook.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';

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
  final races = _loadGamedata('races.json');
  final professions = _loadGamedata('professions.json');
  final gameConfig = _loadGamedata('game_config.json');
  final dice = _loadGamedata('dice.json');
  final skills = _loadGamedata('skills.json');
  final items = _loadGamedata('items.json');
  final shops = _loadGamedata('shops.json');
  final enemies = _loadGamedata('enemies.json');
  final spells = parseSpells(_loadGamedata('spells.json'));

  SimCharacter mage() => SimCharacter.create(
        raceId: 'human',
        race: races['human'] as Map<String, dynamic>,
        professionId: 'mage',
        profession: professions['mage'] as Map<String, dynamic>,
        gameConfig: gameConfig,
        dice: dice,
        spells: spells,
      );
  SimCharacter warrior() => SimCharacter.create(
        raceId: 'dwarf',
        race: races['dwarf'] as Map<String, dynamic>,
        professionId: 'warrior',
        profession: professions['warrior'] as Map<String, dynamic>,
        gameConfig: gameConfig,
        dice: dice,
        spells: spells,
      );

  group('SimCharacter.create', () {
    test('a Mage starts on the apprentice die with two spells and full mana',
        () {
      final c = mage();
      expect(c.diceFaces,
          (dice['apprentice_die'] as Map<String, dynamic>)['faces']);
      expect(c.knownSpells.map((s) => s.id),
          ['spell_arcane_bolt', 'spell_mana_ward']);
      expect(c.maxMana,
          maxManaFor(intelligence: c.intelligence, wisdom: c.wisdom));
      expect(c.mana, c.maxMana);
      expect(c.intelligence, greaterThanOrEqualTo(4));
      expect(c.diceSkillAssignments['4'], 'mage_arcane_missile');
      expect(c.unlockedSkillIds, contains('mage_arcane_missile'));
      expect(c.potions, (gameConfig['potionCount'] as num).toInt());
    });

    test('a Warrior starts on the starter die with no spells', () {
      final c = warrior();
      expect(
          c.diceFaces, (dice['starter_die'] as Map<String, dynamic>)['faces']);
      expect(c.knownSpells, isEmpty);
      expect(c.maxMana, 4);
    });
  });

  group('gainXp', () {
    test('levels through the app\'s thresholds and grows the preferred stat',
        () {
      final c = mage();
      final intelligence = c.intelligence;
      expect(c.gainXp(99), isFalse);
      expect(c.level, 1);
      expect(c.gainXp(1), isTrue);
      expect(c.level, 2);
      expect(c.intelligence, intelligence + 1);
      expect(c.currentHealth, c.maxHealth);
    });
  });

  group('simulateSimFight', () {
    test('a Mage casts Arcane Bolt against a harbor rat and wins', () {
      final c = mage();
      final outcome = simulateSimFight(
        character: c,
        enemies: [
          MapEntry('harbor_rat', enemies['harbor_rat'] as Map<String, dynamic>)
        ],
        chapter: 1,
        skills: skills,
        items: items,
        random: Random(7),
      );
      expect(outcome.won, isTrue);
      expect(outcome.spellsCast['spell_arcane_bolt'], greaterThanOrEqualTo(1));
      expect(c.fightsWon, 1);
      expect(c.spellsCast['spell_arcane_bolt'],
          outcome.spellsCast['spell_arcane_bolt']);
      expect(c.mana, lessThan(c.maxMana));
    });

    test('a loss refills health and mana like the app', () {
      final c = mage();
      c.currentHealth = 1;
      c.mana = 0;
      final outcome = simulateSimFight(
        character: c,
        enemies: [
          MapEntry('void_sovereign',
              enemies['void_sovereign'] as Map<String, dynamic>),
        ],
        chapter: 6,
        skills: skills,
        items: items,
        random: Random(3),
      );
      expect(outcome.won, isFalse);
      expect(c.fightsLost, 1);
      expect(c.currentHealth, c.maxHealth);
      expect(c.mana, c.maxMana);
      expect(c.statusEffects, isEmpty);
    });

    test('Mana faces feed the pool over many fights', () {
      final c = mage();
      var gained = 0;
      for (var i = 0; i < 20; i++) {
        final outcome = simulateSimFight(
          character: c,
          enemies: [
            MapEntry(
                'harbor_rat', enemies['harbor_rat'] as Map<String, dynamic>),
          ],
          chapter: 1,
          skills: skills,
          items: items,
          random: Random(100 + i),
        );
        gained += outcome.manaGained;
      }
      expect(gained, greaterThan(0));
      expect(c.manaGained, gained);
    });

    test('a spell-less Warrior casts nothing and still fights', () {
      final c = warrior();
      final outcome = simulateSimFight(
        character: c,
        enemies: [
          MapEntry('harbor_rat', enemies['harbor_rat'] as Map<String, dynamic>)
        ],
        chapter: 1,
        skills: skills,
        items: items,
        random: Random(11),
      );
      expect(outcome.spellsCast, isEmpty);
      expect(outcome.won, isTrue);
    });
  });

  group('visitShop', () {
    test('buys the profession\'s spellbook, potions and gear it can afford',
        () {
      final c = mage();
      final bazaar = shops['arcane_bazaar'] as Map<String, dynamic>;
      final left = c.visitShop(bazaar, items, dice, spells, 500);
      expect(left, lessThan(500));
      expect(c.knownSpells.map((s) => s.id), contains('spell_frost_bind'));
      expect(c.spellbooksBought, ['spell_frost_bind']);
      expect(c.equippedBySlot, isNotEmpty);
      final again = c.visitShop(bazaar, items, dice, spells, left);
      expect(c.spellbooksBought.length, 1, reason: 'never bought twice');
      expect(again, lessThanOrEqualTo(left));
    });

    test('another profession\'s spellbook is left on the shelf', () {
      final c = warrior();
      c.visitShop(shops['arcane_bazaar'] as Map<String, dynamic>, items, dice,
          spells, 500);
      expect(c.knownSpells, isEmpty);
      final forge = shops['weaponsmith_forge'] as Map<String, dynamic>;
      c.visitShop(forge, items, dice, spells, 500);
      expect(c.knownSpells.map((s) => s.id), contains('spell_war_shout'));
    });

    test('a caster swaps to the sage die where it is sold', () {
      final c = mage();
      c.visitShop(shops['arcane_academy'] as Map<String, dynamic>, items, dice,
          spells, 2000);
      expect(c.diceFaces, (dice['sage_die'] as Map<String, dynamic>)['faces']);
      expect(c.diceSkillAssignments, isEmpty);
    });
  });

  group('boss phases and gear in a simulated fight', () {
    test('the Void Sovereign crosses its phases against a strong character',
        () {
      var phases = 0;
      for (var seed = 0; seed < 12; seed++) {
        final c = warrior();
        c.level = 20;
        c.maxHealth = 700;
        c.currentHealth = 700;
        c.baseDamage = 80;
        c.baseArmor = 20;
        final outcome = simulateSimFight(
          character: c,
          enemies: [
            MapEntry('void_sovereign',
                enemies['void_sovereign'] as Map<String, dynamic>)
          ],
          chapter: 6,
          skills: skills,
          items: items,
          random: Random(seed),
        );
        phases += outcome.phasesEntered;
      }
      expect(phases, greaterThan(0));
    });

    test('worn gear feeds the character\'s numbers', () {
      final c = warrior();
      final sets = parseItemSets(_loadGamedata('item_sets.json'));
      c.equippedBySlot['Weapon'] = 'hollow_court_blade';
      c.equippedBySlot['Top'] = 'hollow_court_mantle';
      final bare = c.casterDamage(items, 'None');
      final withSets = c.casterDamage(items, 'None', itemSets: sets);
      expect(withSets, bare);
      c.equippedBySlot['Head'] = 'hollow_court_seal';
      expect(c.casterDamage(items, 'None', itemSets: sets),
          c.casterDamage(items, 'None') + 8);
      expect(c.armor(items, itemSets: sets), c.armor(items) + 5);
      expect(c.gearEffects(items, sets).lifestealPercent, 10);
    });

    test('New Game+ makes the same fight harder', () {
      var baseWins = 0;
      var plusWins = 0;
      for (var seed = 0; seed < 30; seed++) {
        for (final cycle in [0, 3]) {
          final c = warrior();
          c.level = 3;
          final outcome = simulateSimFight(
            character: c,
            enemies: [
              MapEntry(
                  'slum_thug', enemies['slum_thug'] as Map<String, dynamic>)
            ],
            chapter: 1,
            skills: skills,
            items: items,
            random: Random(seed),
            newGamePlusCycle: cycle,
          );
          if (outcome.won) {
            if (cycle == 0) {
              baseWins++;
            } else {
              plusWins++;
            }
          }
        }
      }
      expect(baseWins, greaterThanOrEqualTo(plusWins));
    });
  });
}
