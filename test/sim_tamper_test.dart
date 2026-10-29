// The simulator's fight lays the enemies' Hex, Silence and Curse on the
// hero's die as the fight screen does (fight_dice_rules `_applyTamper`,
// `_tampered`, `_springHex`): a Silence blanks the next round's skill
// faces, a Hex rolls the next die again unless it landed Steady, and a
// Curse makes a face a Pain strike for the rest of the fight.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/sim_combat.dart';

Map<String, dynamic> _loadGamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final races = _loadGamedata('races.json');
  final professions = _loadGamedata('professions.json');
  final gameConfig = _loadGamedata('game_config.json');
  final dice = _loadGamedata('dice.json');
  final skills = _loadGamedata('skills.json');
  final items = _loadGamedata('items.json');
  final enemies = _loadGamedata('enemies.json');
  final spells = parseSpells(_loadGamedata('spells.json'));

  // A warrior (no spells) on a die of six copies of [face].
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

  // An enemy whose every turn is [skillId] (no move: plain light blows).
  Map<String, dynamic> enemy(String? skillId, {int maxHealth = 40}) => {
        ...enemies['slum_thug'] as Map<String, dynamic>,
        'maxHealth': maxHealth,
        'damage': 1,
        'skillMoves': [
          if (skillId != null)
            {'skillID': skillId, 'condition': 'Always', 'priority': 1},
        ],
      };

  SimFightOutcome fight(SimCharacter c, Map<String, dynamic> foe, int seed,
          {int maxRounds = 12}) =>
      simulateSimFight(
        character: c,
        enemies: [MapEntry('slum_thug', foe)],
        chapter: 1,
        skills: skills,
        items: items,
        random: Random(seed),
        maxRounds: maxRounds,
      );

  const skillFace = {
    'faceName': 'Heavy Blow',
    'type': 'Skill',
    'value': 0,
    'linkedSkillID': 'heavy_attack',
    'element': 'None',
  };

  test('a Silence blanks the skill faces of the round after it', () {
    for (var seed = 0; seed < 10; seed++) {
      // Plain blows: the skill die wins well within the rounds.
      expect(fight(hero(skillFace), enemy(null), seed).won, isTrue);
      // Silenced every turn, it lands only round 1's blow and runs out.
      final silenced = fight(hero(skillFace), enemy('edict_of_silence'), seed);
      expect(silenced.won, isFalse);
      expect(silenced.rounds, 12);
    }
  });

  test('a Silence leaves a skill set on a basic face its basic face', () {
    for (var seed = 0; seed < 10; seed++) {
      final c = hero(const {
        'faceName': 'Slash',
        'type': 'Attack',
        'value': 3,
        'element': 'None',
      });
      c.diceSkillAssignments = {
        for (var i = 0; i < 6; i++) '$i': 'heavy_attack',
      };
      expect(fight(c, enemy('edict_of_silence'), seed).won, isTrue);
    }
  });

  test('a Curse turns a guard face into a Pain strike', () {
    const guard = {
      'faceName': 'Guard',
      'type': 'Defend',
      'value': 1,
      'element': 'None',
    };
    for (var seed = 0; seed < 10; seed++) {
      // A die of guards never wounds a foe that only silences...
      expect(
          fight(hero(guard), enemy('edict_of_silence'), seed, maxRounds: 30)
              .won,
          isFalse);
      // ...but cursed face by face, it strikes and wins.
      expect(fight(hero(guard), enemy('rotting_mark'), seed, maxRounds: 30).won,
          isTrue);
    }
  });

  test('a Hex rolls the die again, unless it landed Steady', () {
    // Against a die of Attack faces a Silence changes nothing, so a Hex
    // that takes no die plays out the same fight, roll for roll.
    Map<String, dynamic> attack({required bool steady}) => {
          'faceName': 'Slash',
          'type': 'Attack',
          'value': 2,
          'element': 'None',
          if (steady) 'keywords': ['steady'],
        };
    ({bool won, int rounds, int health}) play(
        Map<String, dynamic> face, String move, int seed) {
      final c = hero(face);
      final outcome = fight(c, enemy(move, maxHealth: 60), seed);
      return (
        won: outcome.won,
        rounds: outcome.rounds,
        health: c.currentHealth
      );
    }

    var differs = 0;
    for (var seed = 0; seed < 20; seed++) {
      final steady = attack(steady: true);
      expect(play(steady, 'hex_of_ill_luck', seed),
          play(steady, 'edict_of_silence', seed));
      final plain = attack(steady: false);
      if (play(plain, 'hex_of_ill_luck', seed) !=
          play(plain, 'edict_of_silence', seed)) {
        differs++;
      }
    }
    // A plain die is rolled again, so the dice run differently.
    expect(differs, greaterThan(0));
  });
}
