// Signs (v1.192) in a fight, the pure half: what SignEffects does to a
// face's number, a strike, a spell, an enemy's blow, the health a member
// enters with, the gold a fight pays; the sea's signs on the Eel and her
// voyage; the simulator lending a fight the signs and taking them back;
// the clans' Sworn boons (v1.194); and the simulator's two ways to grow,
// the offers and the old rules.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

SeaEvent _day(SeaEventKind kind) => SeaEvent(
      kind: kind,
      description: kind.name,
      descriptionFr: kind.name,
      choiceText: '',
      choiceTextFr: '',
    );

void main() {
  group('a face, a strike, a spell', () {
    const signs = SignEffects(
      strikeFlat: 2,
      strikeDamagePercent: 50,
      lowHealthDamagePercent: 20,
      firstRoundDamagePercent: 10,
      guardFlat: 2,
      guardBlockPercent: 20,
      mendPercent: 50,
      manaFlat: 1,
      spellDamagePercent: 20,
      spellCostLess: 1,
    );

    test('an Attack face adds its flat damage, then the share on it all', () {
      // (10 base + 4 face + 2) x 1.5 = 24; the engine adds the face's 4.
      expect(signs.strikeBase(10, 4, attackFace: true, percent: 50), 20);
      // A Skill face only has its base raised.
      expect(signs.strikeBase(10, 4, attackFace: false, percent: 30), 13);
      expect(SignEffects.none.strikeBase(10, 4, attackFace: true), 10);
    });

    test('the share: the Attack face\'s, low health, the first round', () {
      int percent({bool attack = true, int health = 100, bool first = false}) =>
          signs.strikePercentFor(
              attackFace: attack,
              currentHealth: health,
              maxHealth: 100,
              firstRound: first);
      expect(percent(), 50);
      expect(percent(attack: false), 0);
      expect(percent(health: 34), 70);
      expect(percent(health: 35), 50, reason: 'under 35%, not at it');
      expect(percent(first: true), 60);
    });

    test('Defend, Heal and Mana faces', () {
      expect(signs.guardValue(5), 8, reason: '(5 + 2) x 1.2 = 8.4');
      expect(signs.guardValue(0), 0);
      // (6 + 2 Wisdom) x 1.5 = 12, less the Wisdom the engine adds again.
      expect(signs.mendValue(6, 2), 10);
      expect(signs.manaValue(2), 3);
      expect(SignEffects.none.mendValue(6, 2), 6);
    });

    test('spells: more, and cheaper but never free', () {
      expect(signs.spellAmount(10), 12);
      expect(signs.spellCost(3), 2);
      expect(signs.spellCost(1), 1);
      expect(const SignEffects(spellCostLess: 5).spellCost(3), 1);
      expect(signs.spellCost(0), 0);
    });
  });

  group('the fight around it', () {
    test('a pact makes the enemies hit harder, and pays less', () {
      const cursed = SignEffects(
          enemyDamagePercent: 25, goldPercent: 10, goldPercentLoss: 50);
      expect(cursed.enemyDamage(10), 13);
      expect(SignEffects.none.enemyDamage(10), 10);
      expect(cursed.scaleGold(100), 60);
      expect(const SignEffects(goldPercentLoss: 200).scaleGold(50), 0);
      expect(const SignEffects(xpPercent: 10).scaleXp(100), 110);
      expect(const SignEffects(allyDamagePercent: 6).scaleAllyDamage(50), 53);
    });

    test('max health: full stays full, a wound stays, a curse takes a share',
        () {
      const signs = SignEffects(
          maxHealth: 9, partyMaxHealthPercent: 10, startHealthPercentLoss: 20);
      expect(signs.maxHealthFor(100), 119);
      expect(signs.maxHealthFor(100, partyWide: true), 110);
      expect(SignEffects.healthEntering(current: 100, base: 100, fightMax: 119),
          119);
      expect(SignEffects.healthEntering(current: 60, base: 100, fightMax: 119),
          60);
      expect(signs.afterStartCurse(119, 119), 95);
      expect(signs.afterStartCurse(10, 119), 1, reason: 'never the last point');
      expect(SignEffects.none.afterStartCurse(50, 100), 50);
    });

    test('gear-like signs lay over the gear', () {
      const gear = GearEffects(armor: 2, critChance: 5, thorns: 1);
      const signs = SignEffects(
        armor: 1,
        critChance: 3,
        dodgeChance: 2,
        lifestealPercent: 6,
        thorns: 2,
        manaOnHit: 1,
        secondWind: true,
      );
      final over = signs.over(gear);
      expect(over.armor, 3);
      expect(over.critChance, 8);
      expect(over.dodgeChance, 2);
      expect(over.lifestealPercent, 6);
      expect(over.thorns, 3);
      expect(over.manaOnHit, 1);
      expect(over.secondWind, isTrue);
    });

    test('mending: the party\'s share, block from overheal, after the fight',
        () {
      const signs = SignEffects(
          mendPartyPercent: 18, mendShield: 4, afterFightHealPercent: 5);
      expect(signs.mendShare(20), 4);
      expect(
          signs.shieldFromOverheal(
              healing: 10, currentHealth: 95, maxHealth: 100),
          4,
          reason: '5 spilled over, up to 4');
      expect(
          signs.shieldFromOverheal(
              healing: 10, currentHealth: 50, maxHealth: 100),
          0);
      expect(signs.afterFightHeal(120), 6);
      expect(SignEffects.none.afterFightHeal(120), 0);
    });

    test('a sign\'s status comes up at its odds', () {
      const chance = SignStatusChance(
        status: StatusEffect(
            type: StatusEffectType.stun, remainingTurns: 1, magnitude: 0),
        chance: 30,
      );
      final random = Random(5);
      var landed = 0;
      for (var i = 0; i < 10000; i++) {
        if (chance.rolls(random)) landed++;
      }
      expect(landed / 10000, closeTo(0.30, 0.02));
    });
  });

  group('at sea', () {
    test('a calm sign lets storms and raiders pass, never the rest', () {
      final days = [
        _day(SeaEventKind.storm),
        _day(SeaEventKind.calm),
        _day(SeaEventKind.raider),
        _day(SeaEventKind.beast),
      ];
      final none = applyVoyageCalm(days, 0, Random(1));
      expect(none.events, days);
      expect(none.calmed, 0);
      final all = applyVoyageCalm(days, 100, Random(1));
      expect(all.events.map((e) => e.kind),
          [SeaEventKind.calm, SeaEventKind.beast]);
      expect(all.calmed, 2);
      // A voyage never empties, but a shelter's extra day may pass.
      final storm = [_day(SeaEventKind.storm)];
      expect(applyVoyageCalm(storm, 100, Random(1)).events, storm);
      expect(applyVoyageCalm(storm, 100, Random(1), keepOne: false).events,
          isEmpty);
    });

    test('hull and gun signs lift the Eel', () {
      final ships = _gamedata('ships.json');
      final parts = _gamedata('ship_parts.json');
      final eel = ships['rusty_eel'] as Map<String, dynamic>;
      final gun = parts.entries
          .firstWhere((e) =>
              ((e.value as Map<String, dynamic>)['damageAmount'] as num? ?? 0) >
              0)
          .key;
      ShipState build({int hull = 0, int guns = 0}) => buildPlayerShip(
            ship: eel,
            parts: parts,
            installedPartIds: [gun],
            currentHull: -1,
            hullPercent: hull,
            gunPercent: guns,
          );
      final plain = build();
      final signed = build(hull: 10, guns: 10);
      expect(signed.maxHull, (plain.maxHull * 1.1).round());
      expect(signed.hull, signed.maxHull);
      expect(signed.weapons.single.damage,
          (plain.weapons.single.damage * 1.1).round());
    });
  });

  test('the simulator lends a fight the signs and takes them back', () {
    final c = SimCharacter.create(
      raceId: 'human',
      race: _gamedata('races.json')['human'] as Map<String, dynamic>,
      professionId: 'warrior',
      profession:
          _gamedata('professions.json')['warrior'] as Map<String, dynamic>,
      gameConfig: _gamedata('game_config.json'),
      dice: _gamedata('dice.json'),
      spells: parseSpells(_gamedata('spells.json')),
    );
    final health = c.maxHealth;
    final strength = c.strength;
    final rat = _gamedata('enemies.json')['harbor_rat'] as Map<String, dynamic>;
    final outcome = simulateSimFight(
      character: c,
      enemies: [MapEntry('harbor_rat', rat)],
      chapter: 1,
      skills: _gamedata('skills.json'),
      items: _gamedata('items.json'),
      random: Random(2),
      signs: const SignEffects(
        maxHealth: 20,
        strikeFlat: 3,
        killHeal: 5,
        stats: {'strength': 2},
      ),
    );
    expect(outcome.won, isTrue);
    expect(c.maxHealth, health);
    expect(c.currentHealth, lessThanOrEqualTo(health));
    expect(c.strength, strength);
    expect(c.signMaxMana, 0);
  });

  test('the simulator\'s walk clears expeditions; offers and the old rules',
      () {
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    ({
      Map<String, ({int runs, int attempts, int won})> chapters,
      int signsTaken,
      int offersTaken,
      int skillsLearned,
    }) walk({required bool signs, required SimProgression progression}) =>
        simulateFightsByChapter(
          story,
          tables: {
            for (final name in [
              'enemies',
              'dice',
              'skills',
              'items',
              'shops',
              'races',
              'professions',
              'spells',
              'item_sets',
              'zones',
              'skill_trees',
              if (signs) ...[
                'factions',
                'signs',
                'subclans',
                'relations',
                'titles',
              ],
            ])
              name: _gamedata('$name.json'),
          },
          gameConfig: _gamedata('game_config.json'),
          runs: 4,
          seed: 3,
          progression: progression,
        );
    final offers = walk(signs: true, progression: SimProgression.offers);
    // Past the harbour's two expeditions (node 2900) and on to the end.
    expect(offers.chapters['Chapter 6']?.attempts, greaterThan(0));
    for (final chapter in offers.chapters.values) {
      expect(chapter.won, lessThanOrEqualTo(chapter.attempts));
    }
    expect(offers.offersTaken, greaterThanOrEqualTo(4 * 10),
        reason: 'levels, bosses and chapters bring offers');
    expect(offers.signsTaken, greaterThan(0));
    final legacy = walk(signs: true, progression: SimProgression.legacy);
    expect(legacy.offersTaken, 0);
    expect(legacy.signsTaken, greaterThanOrEqualTo(4 * 3),
        reason: 'odd levels and bosses brought signs');
    expect(legacy.skillsLearned, greaterThan(0), reason: 'and skill points');
    expect(
        walk(signs: false, progression: SimProgression.legacy).signsTaken, 0);
  });

  group('the clans\' Sworn boons (v1.194)', () {
    test('summed like any sign, counted as written', () {
      final effects = signEffectsFor(const [], const {},
          alignment: 0,
          extra: [
            for (final kind in [
              SignEffectKind.writFace,
              SignEffectKind.intentLookahead,
              SignEffectKind.compactEdge,
              SignEffectKind.emberFace,
              SignEffectKind.poisonExtraTurns,
            ])
              SignEffect(kind: kind, value: 1),
            const SignEffect(kind: SignEffectKind.crowsPrice, value: 3),
          ]);
      expect(effects.writFace, 1);
      expect(effects.intentLookahead, 1);
      expect(effects.compactEdge, 1);
      expect(effects.emberFace, 1);
      expect(effects.poisonExtraTurns, 1);
      expect(effects.crowsPrice, 3);
      expect(effects.isEmpty, isFalse);
      // A count stays a count at any rarity and level.
      expect(
          const SignEffect(kind: SignEffectKind.writFace, value: 1)
              .scaled(SignRarity.heroic, 3)
              .value,
          1);
    });

    test('the Crow\'s Price stops at ten hits; poisons run longer', () {
      const crows = SignEffects(crowsPrice: 3, poisonExtraTurns: 1);
      expect(crows.crowsGold(4), 12);
      expect(crows.crowsGold(25), 3 * crowsPriceMaxHits);
      const poison = StatusEffect(
          type: StatusEffectType.poison, remainingTurns: 2, magnitude: 3);
      expect(crows.playerInflicted(poison).remainingTurns, 3);
      expect(crows.playerInflicted(poison).magnitude, 3);
      const stun = StatusEffect(
          type: StatusEffectType.stun, remainingTurns: 1, magnitude: 0);
      expect(crows.playerInflicted(stun).remainingTurns, 1);
      expect(SignEffects.none.playerInflicted(poison).remainingTurns, 2);
    });

    test('in the simulator, the Writ spares a blow and the Crows steal', () {
      SimCharacter warrior() => SimCharacter.create(
            raceId: 'human',
            race: _gamedata('races.json')['human'] as Map<String, dynamic>,
            professionId: 'warrior',
            profession: _gamedata('professions.json')['warrior']
                as Map<String, dynamic>,
            gameConfig: _gamedata('game_config.json'),
            dice: _gamedata('dice.json'),
            spells: parseSpells(_gamedata('spells.json')),
          );
      final brute =
          _gamedata('enemies.json')['harbor_rat'] as Map<String, dynamic>;
      var spared = 0;
      var plain = 0;
      var stolen = 0;
      for (var seed = 0; seed < 40; seed++) {
        final a = warrior();
        simulateSimFight(
          character: a,
          enemies: [MapEntry('harbor_rat', brute)],
          chapter: 1,
          skills: _gamedata('skills.json'),
          items: _gamedata('items.json'),
          random: Random(seed),
        );
        plain += a.maxHealth - a.currentHealth;
        final b = warrior();
        final outcome = simulateSimFight(
          character: b,
          enemies: [MapEntry('harbor_rat', brute)],
          chapter: 1,
          skills: _gamedata('skills.json'),
          items: _gamedata('items.json'),
          random: Random(seed),
          signs: const SignEffects(writFace: 3, crowsPrice: 3),
        );
        spared += b.maxHealth - b.currentHealth;
        stolen += outcome.goldStolen;
      }
      expect(spared, lessThan(plain), reason: 'blows cancelled');
      expect(stolen, greaterThan(0));
    });
  });

  group('the simulator\'s growth', () {
    final tables = SimGrowthTables(
      skills: _gamedata('skills.json'),
      skillTrees: _gamedata('skill_trees.json'),
      items: _gamedata('items.json'),
      spells: parseSpells(_gamedata('spells.json')),
      patrons: parsePatrons(_gamedata('factions.json')),
      signs: parseSigns(_gamedata('signs.json')),
      clans: ClanData.fromTables(
        factions: _gamedata('factions.json'),
        subclans: _gamedata('subclans.json'),
        relations: _gamedata('relations.json'),
        titles: _gamedata('titles.json'),
      ),
    );
    SimCharacter warrior() => SimCharacter.create(
          raceId: 'human',
          race: _gamedata('races.json')['human'] as Map<String, dynamic>,
          professionId: 'warrior',
          profession:
              _gamedata('professions.json')['warrior'] as Map<String, dynamic>,
          gameConfig: _gamedata('game_config.json'),
          dice: _gamedata('dice.json'),
          spells: parseSpells(_gamedata('spells.json')),
        );

    test('the old rules: points on the tree, a perk, a sign', () {
      final c = warrior();
      final growth =
          SimGrowth(mode: SimProgression.legacy, tables: tables, character: c);
      growth.levelsReached(1, 3);
      expect(growth.skillPoints, 2);
      expect(growth.perkPicks, 1);
      expect(growth.signPicks, 1);
      growth.settle(alignment: 0, flags: const [], random: Random(1));
      expect(growth.skillPoints, 0);
      expect(growth.skillsLearned, greaterThanOrEqualTo(1));
      expect(growth.perkRanks.values.fold<int>(0, (a, b) => a + b), 1);
      expect(c.heldSigns, hasLength(1));
      // The open Skill face of the starter die took the first skill.
      expect(c.diceSkillAssignments.containsKey('2'), isTrue);
    });

    test('the offers: one a level, a boss and a chapter, all taken', () {
      final c = warrior();
      final growth =
          SimGrowth(mode: SimProgression.offers, tables: tables, character: c);
      growth.levelsReached(1, 3);
      growth.bossBeaten();
      growth.chapterReached(1);
      growth.chapterReached(2);
      growth.chapterReached(2);
      expect(growth.pending, hasLength(4));
      growth.settle(alignment: 0, flags: const [], random: Random(2));
      expect(growth.pending, isEmpty);
      expect(growth.giftsTaken.values.fold<int>(0, (a, b) => a + b), 4);
      expect(growth.politics.standingLog, isNotEmpty);
      // The first offer fills the starter die's open face with a skill.
      expect(c.diceSkillAssignments.containsKey('2'), isTrue);
    });
  });
}
