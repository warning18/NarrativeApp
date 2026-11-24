// The simulator's truth on face keywords (Wave 5): its fights play Growth
// as the fight screen does (a face gains growthStep each time it is played),
// and the dice it picks are valued with their keywords (simFaceValue): Pain
// twice the blow less the health it costs, Cleave its splash, Pierce what a
// guard would take, Steady its point, Growth what it gains in a fight. The
// Headsman, which fights well but was valued below the starter die, now
// ranks above it.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/face_keywords.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_policy.dart';

Map<String, dynamic> _loadGamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _face(String type, int value,
        [List<String> keywords = const [], double weight = 1.0]) =>
    {
      'faceName': type,
      'type': type,
      'value': value,
      'weight': weight,
      'element': 'None',
      if (keywords.isNotEmpty) 'keywords': keywords,
    };

void main() {
  final races = _loadGamedata('races.json');
  final professions = _loadGamedata('professions.json');
  final gameConfig = _loadGamedata('game_config.json');
  final dice = _loadGamedata('dice.json');
  final skills = _loadGamedata('skills.json');
  final items = _loadGamedata('items.json');
  final enemies = _loadGamedata('enemies.json');
  final spells = parseSpells(_loadGamedata('spells.json'));

  group('in the fights', () {
    SimCharacter hero(Map<String, dynamic> face) {
      final c = SimCharacter.create(
        raceId: 'dwarf',
        race: races['dwarf'] as Map<String, dynamic>,
        professionId: 'warrior',
        profession: professions['warrior'] as Map<String, dynamic>,
        gameConfig: gameConfig,
        dice: dice,
        spells: spells,
      );
      c.diceFaces = [for (var i = 0; i < 6; i++) Map.of(face)];
      c.diceSkillAssignments = {};
      return c;
    }

    // A foe that only takes blows: plain light hits, a lot of health.
    final foe = {
      ...enemies['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 90,
      'damage': 0,
      'skillMoves': const [],
    };

    SimFightOutcome fight(SimCharacter c, int seed) => simulateSimFight(
          character: c,
          enemies: [MapEntry('slum_thug', foe)],
          chapter: 1,
          skills: skills,
          items: items,
          random: Random(seed),
          maxRounds: 40,
        );

    test('a Growth face gains a point each time it is played', () {
      for (var seed = 0; seed < 8; seed++) {
        final plain = fight(hero(_face('Attack', 1)), seed);
        final growth = fight(hero(_face('Attack', 1, ['growth'])), seed);
        expect(plain.won, isTrue, reason: 'seed $seed');
        expect(growth.won, isTrue, reason: 'seed $seed');
        // Every face grows: the same foe falls in fewer rounds.
        expect(growth.rounds, lessThan(plain.rounds), reason: 'seed $seed');
      }
    });
  });

  group('the value of a face', () {
    double value(Map<String, dynamic> face,
            {List<Map<String, dynamic>>? faces, int maxHealth = 0}) =>
        simFaceValue(faces ?? [face], 0, const {}, skills,
            damage: 8, maxHealth: maxHealth);

    test('Pain: twice the blow, less the health it costs', () {
      // 2 x (8 + 2) less 8% of 100 health at 0.7 a point.
      expect(value(_face('Attack', 2, ['pain']), maxHealth: 100),
          closeTo(2 * 10 - painHealthShare * 100 * 0.7, 1e-9));
      // Without the hero's health: simHealthPerDamage x damage.
      expect(value(_face('Attack', 2, ['pain'])),
          closeTo(20 - painHealthShare * 8 * simHealthPerDamage * 0.7, 1e-9));
    });

    test('Cleave, Pierce and Steady on a strike', () {
      expect(value(_face('Attack', 2, ['cleave'])),
          closeTo(10 * (1 + cleaveSplashShare * simCleaveOthers), 1e-9));
      expect(value(_face('Attack', 2, ['pierce'])),
          closeTo(10 * (1 + simPierceKept), 1e-9));
      expect(value(_face('Attack', 2, ['steady'])), 8 + 2 + steadyBonus);
      expect(value(_face('Defend', 2, ['steady'])),
          closeTo((2 + steadyBonus) * 0.8, 1e-9));
    });

    test('Growth: what the face gains over a fight, more on a small die', () {
      final d4 = [
        for (var i = 0; i < 4; i++) _face('Attack', 2, ['growth'])
      ];
      const uses = simFightRounds / 4;
      expect(value(d4.first, faces: d4),
          closeTo(10 + growthStep * (uses - 1) / 2, 1e-9));
      // On a d12 a face is played less than once a fight: nothing gained.
      final d12 = [
        for (var i = 0; i < 12; i++) _face('Attack', 2, ['growth'])
      ];
      expect(value(d12.first, faces: d12), 10);
    });

    test('a plain face is worth what it was', () {
      expect(value(_face('Attack', 2)), 10);
      expect(value(_face('Defend', 2)), closeTo(1.6, 1e-9));
      expect(value(_face('Heal', 2)), closeTo(1.4, 1e-9));
    });
  });

  test('the Headsman ranks above the starter die at every damage', () {
    List<Map<String, dynamic>> facesOf(String id) => [
          for (final f in ((dice[id] as Map)['faces'] as List))
            (f as Map).cast<String, dynamic>(),
        ];
    for (final damage in [6, 8, 10, 12]) {
      final headsman = simDieValue(facesOf('headsman_die'), const {}, skills,
          damage: damage);
      final starter =
          simDieValue(facesOf('starter_die'), const {}, skills, damage: damage);
      expect(headsman, greaterThan(starter), reason: 'damage $damage');
    }
  });
}
