// Unit coverage for the pure combat-resolution functions in
// lib/combat/combat_engine.dart. Every bug this session's balance pass
// found (an enemy skill firing every turn instead of on a Chance roll, an
// achievement threshold off by one) was the same *shape* of mistake this
// file's logic is prone to: a condition, a priority order, or a scaling
// formula silently doing the wrong thing. Those were only ever caught by
// a hand-written Python port of this file, run manually and outside CI.
// This gives the real Dart logic the same scrutiny automatically.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';

void main() {
  group('rollDie', () {
    test('a single face is always returned regardless of weight', () {
      final faces = [
        {'faceName': 'Only Face', 'type': 'Attack', 'value': 5, 'weight': 3.0},
      ];
      final result = rollDie(faces, Random(1));
      expect(result.faceIndex, 0);
      expect(result.faceName, 'Only Face');
      expect(result.type, 'Attack');
      expect(result.value, 5);
    });

    test('a zero-weight face table falls back to the first face', () {
      final faces = [
        {'faceName': 'A', 'type': 'Attack', 'value': 1, 'weight': 0.0},
        {'faceName': 'B', 'type': 'Defend', 'value': 2, 'weight': 0.0},
      ];
      final result = rollDie(faces, Random(1));
      expect(result.faceName, 'A');
    });

    test('missing optional fields default sensibly', () {
      final faces = [
        {'faceName': 'Bare'},
      ];
      final result = rollDie(faces, Random(1));
      expect(result.type, 'Empty');
      expect(result.value, 0);
      expect(result.linkedSkillID, '');
      expect(result.element, 'None');
    });

    test('only ever returns faces present in the table', () {
      final faces = [
        {'faceName': 'A', 'type': 'Attack', 'value': 1, 'weight': 1.0},
        {'faceName': 'B', 'type': 'Defend', 'value': 2, 'weight': 1.0},
        {'faceName': 'C', 'type': 'Heal', 'value': 3, 'weight': 1.0},
      ];
      final seen = <String>{};
      final rng = Random(42);
      for (var i = 0; i < 200; i++) {
        seen.add(rollDie(faces, rng).faceName);
      }
      expect(seen, {'A', 'B', 'C'});
    });
  });

  group('resolvePlayerFace', () {
    const skills = <String, dynamic>{
      'power_strike': {
        'damageMod': 5,
        'damageMultiplier': 2.0,
        'healAmount': 0,
        'battleMessage': 'A crushing blow!',
      },
      'minor_heal': {
        'damageMod': 0,
        // A Skill face's damage is (baseDamage + damageMod) * damageMultiplier,
        // computed unconditionally -- damageMod:0 alone still lets baseDamage
        // through. Only a zero multiplier makes this a pure heal, no damage.
        'damageMultiplier': 0.0,
        'healAmount': 15,
        'battleMessage': 'Warmth spreads.',
      },
    };

    DiceFaceResult face({
      required String type,
      int value = 0,
      String linkedSkillID = '',
      int faceIndex = 0,
      String faceName = 'Face',
    }) =>
        DiceFaceResult(
          faceIndex: faceIndex,
          faceName: faceName,
          type: type,
          value: value,
          linkedSkillID: linkedSkillID,
          element: 'None',
        );

    test('Attack face adds its value to base damage', () {
      final result = resolvePlayerFace(face(type: 'Attack', value: 7), skills, 10);
      expect(result.damageDealt, 17);
      expect(result.healingDone, 0);
      expect(result.blockAmount, 0);
    });

    test('Defend face blocks for its value and deals no damage', () {
      final result = resolvePlayerFace(face(type: 'Defend', value: 12), skills, 10);
      expect(result.blockAmount, 12);
      expect(result.damageDealt, 0);
    });

    test('Heal face heals for its value', () {
      final result = resolvePlayerFace(face(type: 'Heal', value: 20), skills, 10);
      expect(result.healingDone, 20);
      expect(result.damageDealt, 0);
    });

    test('Skill face applies the linked skill\'s mod and multiplier', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'power_strike'),
        skills,
        10,
      );
      // (baseDamage + damageMod) * multiplier = (10 + 5) * 2.0 = 30
      expect(result.damageDealt, 30);
      expect(result.healingDone, 0);
    });

    test('Skill face with no linkedSkillID falls back to heavy_attack', () {
      const skillsWithHeavy = <String, dynamic>{
        'heavy_attack': {'damageMod': 3, 'damageMultiplier': 1.0, 'healAmount': 0},
      };
      final result = resolvePlayerFace(face(type: 'Skill'), skillsWithHeavy, 10);
      expect(result.damageDealt, 13);
    });

    test('Skill face referencing an unknown skill fizzles harmlessly', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'does_not_exist'),
        skills,
        10,
      );
      expect(result.damageDealt, 0);
      expect(result.healingDone, 0);
      expect(result.blockAmount, 0);
    });

    test('a healing skill reports healing and no damage', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'minor_heal'),
        skills,
        10,
      );
      expect(result.healingDone, 15);
      expect(result.damageDealt, 0);
    });

    test('Empty/unknown face type does nothing', () {
      final result = resolvePlayerFace(face(type: 'Empty'), skills, 10);
      expect(result.damageDealt, 0);
      expect(result.healingDone, 0);
      expect(result.blockAmount, 0);
    });
  });

  group('resolveEnemyMove', () {
    test('an Always-condition move with a valid skill always fires', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {
            'skillID': 'void_blast',
            'condition': 'Always',
            'priority': 1,
          },
        ],
      };
      const skills = <String, dynamic>{
        'void_blast': {'damageMod': 20, 'damageMultiplier': 1.0},
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(result.damage, 30); // baseDamage 10 + damageMod 20
    });

    test('a Chance move at 0% never fires (falls back to base attack)', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {'skillID': 'never_happens', 'condition': 'Chance', 'chance': 0, 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'never_happens': {'damageMod': 999, 'damageMultiplier': 1.0},
      };
      // Run many times: a 0% chance should never once produce the skill's
      // inflated damage, regardless of the RNG stream.
      for (var seed = 0; seed < 50; seed++) {
        final result = resolveEnemyMove(
          enemy: enemy,
          skills: skills,
          enemyCurrentHealth: 100,
          enemyMaxHealth: 100,
          random: Random(seed),
        );
        expect(result.damage, 10, reason: 'seed $seed produced the 0%-chance move');
      }
    });

    test('a Chance move at 100% always fires', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {'skillID': 'always_at_100', 'condition': 'Chance', 'chance': 100, 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'always_at_100': {'damageMod': 5, 'damageMultiplier': 1.0},
      };
      for (var seed = 0; seed < 50; seed++) {
        final result = resolveEnemyMove(
          enemy: enemy,
          skills: skills,
          enemyCurrentHealth: 100,
          enemyMaxHealth: 100,
          random: Random(seed),
        );
        expect(result.damage, 15, reason: 'seed $seed did not produce the 100%-chance move');
      }
    });

    test('OnLowHealth only fires at or below its threshold', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {
            'skillID': 'desperate_strike',
            'condition': 'OnLowHealth',
            'healthThreshold': 30,
            'priority': 1,
          },
        ],
      };
      const skills = <String, dynamic>{
        'desperate_strike': {'damageMod': 40, 'damageMultiplier': 1.0},
      };
      final atFullHealth = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(atFullHealth.damage, 10, reason: 'should not fire above the health threshold');

      final atLowHealth = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 20,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(atLowHealth.damage, 50, reason: 'should fire at or below the health threshold');
    });

    test('higher-priority move is checked first, but a match always wins the '
        'turn even without a resolvable skill (no fallthrough to lower moves)', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          // Matches (Always) but its skill isn't in the skills map --
          // matches the exact shape of a mis-keyed enemies.json entry.
          {'skillID': 'missing_skill', 'condition': 'Always', 'priority': 10},
          {'skillID': 'low_priority', 'condition': 'Always', 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'low_priority': {'damageMod': 999, 'damageMultiplier': 1.0},
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      // The first matching move consumes the turn even though its skill
      // doesn't resolve -- the enemy falls back to a plain attack, it does
      // NOT fall through to try the second, lower-priority move.
      expect(result.damage, 10);
    });

    test('with no skill moves at all, the enemy just uses base damage', () {
      final enemy = <String, dynamic>{'enemyName': 'Plain Foe', 'damage': 7};
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: const {},
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
      );
      expect(result.damage, 7);
    });
  });

  group('level scaling formulas', () {
    test('at level 1, every scaling function returns the base value unchanged', () {
      expect(scaledMaxHealth(100, 1), 100);
      expect(scaledDamage(20, 1), 20);
      expect(scaledReward(50, 1), 50);
    });

    test('scaledMaxHealth grows by 12% per level above 1', () {
      // 100 * (1 + 0.12 * 4) = 148
      expect(scaledMaxHealth(100, 5), 148);
    });

    test('scaledDamage grows by 8% per level above 1', () {
      // 20 * (1 + 0.08 * 4) = 26.4 -> rounds to 26
      expect(scaledDamage(20, 5), 26);
    });

    test('scaledReward grows by 10% per level above 1', () {
      // 50 * (1 + 0.10 * 4) = 70
      expect(scaledReward(50, 5), 70);
    });
  });
}
