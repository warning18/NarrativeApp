// Signs (v1.192) in a fight, the pure half: what SignEffects does to a
// face's number, a strike, a spell, an enemy's blow, the health a member
// enters with, the gold a fight pays; the sea's signs on the Eel and her
// voyage; and the simulator lending a fight the signs and taking them back.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
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

  test('the simulator\'s walk clears expeditions and takes signs', () {
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    ({
      Map<String, ({int runs, int attempts, int won})> chapters,
      int signsTaken
    }) walk({required bool signs}) => simulateFightsByChapter(
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
              if (signs) ...['factions', 'signs'],
            ])
              name: _gamedata('$name.json'),
          },
          gameConfig: _gamedata('game_config.json'),
          runs: 4,
          seed: 3,
        );
    final signed = walk(signs: true);
    // Past the harbour's two expeditions (node 2900) and on to the end.
    expect(signed.chapters['Chapter 6']?.attempts, greaterThan(0));
    for (final chapter in signed.chapters.values) {
      expect(chapter.won, lessThanOrEqualTo(chapter.attempts));
    }
    expect(signed.signsTaken, greaterThanOrEqualTo(4 * 3),
        reason: 'odd levels and bosses bring signs');
    expect(walk(signs: false).signsTaken, 0);
  });
}
