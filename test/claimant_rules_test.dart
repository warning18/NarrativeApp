// The claimants' rules (wave 17 item 1, "C, complete"): in a claimant's
// fight the enemies' Tide stops at level 6, each claimant mends itself once
// a fight, and the claimants have no resists (they keep their weaknesses).
// See docs/simulation/claimants-by-profession.md.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/combat/fight_length.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

const _claimants = ['claimant_vane', 'claimant_tallis', 'claimant_morrow'];

void main() {
  final enemies = _gamedata('enemies.json');
  final skills = _gamedata('skills.json');

  group('the Tide in a claimant\'s fight', () {
    test('the claimants stop the enemies\' Tide at level 6', () {
      for (final id in _claimants) {
        final record = enemies[id] as Map<String, dynamic>;
        expect(fightTideCap([record]), 6, reason: id);
      }
      // Nobody else sets a cap.
      final others = [
        for (final e in enemies.entries)
          if (!_claimants.contains(e.key)) e.value as Map<String, dynamic>,
      ];
      expect(fightTideCap(others), isNull);
      // The lowest cap of the fight's enemies holds.
      expect(
          fightTideCap([
            {'tideCap': 8},
            {'tideCap': 6},
            {},
          ]),
          6);
    });

    test('the enemies\' blows stop growing at the cap, the party\'s do not',
        () {
      // Round 13 is level 6: x2.08 in a boss's fight.
      expect(enemyTideLevel(13, cap: 6), 6);
      expect(enemyTideLevel(18, cap: 6), 6);
      expect(enemyTideLevel(18), 11);
      expect(enemyTideLevel(10, cap: 6), 3);
      expect(tideDamage(100, 13, byParty: false, bossFight: true, enemyCap: 6),
          208);
      expect(tideDamage(100, 18, byParty: false, bossFight: true, enemyCap: 6),
          208);
      expect(tideDamage(100, 18, byParty: false, bossFight: true), 298);
      expect(tideDamage(100, 18, byParty: true, enemyCap: 6), 320);
      expect(
          ContextRule.tide
              .blow(100, 18, byParty: false, bossFight: true, enemyTideCap: 6),
          208);
      expect(tideEnemyMultiplier(20, bossFight: true, cap: 6),
          closeTo(2.08, 1e-9));
    });
  });

  group('one heal a fight', () {
    test('the claimants heal once; their heal moves are what they lose', () {
      for (final id in _claimants) {
        final record = enemies[id] as Map<String, dynamic>;
        expect(healsOnce(record), isTrue, reason: id);
        final kept = withoutHealMoves(record, skills);
        final ids = [
          for (final m in kept['skillMoves'] as List) (m as Map)['skillID'],
        ];
        for (final m in record['skillMoves'] as List) {
          final skill = skills[(m as Map)['skillID']] as Map<String, dynamic>;
          final heals = ((skill['healAmount'] as num?) ?? 0) > 0;
          expect(ids.contains(m['skillID']), !heals,
              reason: '$id ${m['skillID']}');
        }
      }
      expect(healsOnce(enemies['slum_thug'] as Map<String, dynamic>), isFalse);
    });

    test('in the simulator, a once-healer mends itself once, then not again',
        () {
      final races = _gamedata('races.json');
      final professions = _gamedata('professions.json');
      // A foe that mends itself every turn it can, more than a plain blow
      // takes off: the hero can't win unless the heal stops.
      Map<String, dynamic> foe({required bool once}) => {
            ...enemies['slum_thug'] as Map<String, dynamic>,
            'maxHealth': 30,
            'damage': 1,
            'phases': const [],
            'resists': const [],
            'weakTo': const [],
            if (once) 'healsOnce': true,
            'skillMoves': [
              {'skillID': 'second_wind', 'condition': 'Always', 'priority': 1},
            ],
          };
      var onceWins = 0, everyWins = 0;
      for (var seed = 0; seed < 10; seed++) {
        SimCharacter hero() {
          final c = SimCharacter.create(
            raceId: 'dwarf',
            race: races['dwarf'] as Map<String, dynamic>,
            professionId: 'warrior',
            profession: professions['warrior'] as Map<String, dynamic>,
            gameConfig: _gamedata('game_config.json'),
            dice: _gamedata('dice.json'),
            spells: parseSpells(_gamedata('spells.json')),
          );
          c.diceFaces = [
            for (var i = 0; i < 6; i++)
              {
                'faceName': 'Jab',
                'type': 'Attack',
                'value': 2,
                'element': 'None',
              },
          ];
          c.diceSkillAssignments = {};
          return c;
        }

        SimFightOutcome fight(bool once) => simulateSimFight(
              character: hero(),
              enemies: [MapEntry('slum_thug', foe(once: once))],
              chapter: 1,
              skills: skills,
              items: _gamedata('items.json'),
              random: Random(seed),
              maxRounds: 30,
              clash: false,
            );
        if (fight(true).won) onceWins++;
        if (fight(false).won) everyWins++;
      }
      expect(onceWins, greaterThan(everyWins));
      expect(onceWins, 10);
    });
  });

  test('the claimants have no resists and keep their weaknesses', () {
    for (final id in _claimants) {
      final record = enemies[id] as Map<String, dynamic>;
      expect(record['resists'] ?? const [], isEmpty, reason: id);
      expect(record['weakTo'], isNotEmpty, reason: id);
    }
    expect((enemies['claimant_tallis'] as Map)['maxHealth'], 88);
    expect((enemies['claimant_morrow'] as Map)['maxHealth'], 148);
  });
}
