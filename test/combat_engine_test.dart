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
import 'package:narrative_data_app/combat/status_effect.dart';

/// A [Random] stand-in that always returns the same [nextDouble] value, so
/// crit/dodge-roll tests can force a guaranteed hit or guaranteed miss
/// instead of depending on a fixed seed's empirical behavior.
class _FixedRandom implements Random {
  _FixedRandom(this._value);
  final double _value;
  @override
  double nextDouble() => _value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

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
      final result =
          resolvePlayerFace(face(type: 'Attack', value: 7), skills, 10);
      expect(result.damageDealt, 17);
      expect(result.healingDone, 0);
      expect(result.blockAmount, 0);
    });

    test('Defend face blocks for its value and deals no damage', () {
      final result =
          resolvePlayerFace(face(type: 'Defend', value: 12), skills, 10);
      expect(result.blockAmount, 12);
      expect(result.damageDealt, 0);
    });

    test('Heal face heals for its value', () {
      final result =
          resolvePlayerFace(face(type: 'Heal', value: 20), skills, 10);
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
        'heavy_attack': {
          'damageMod': 3,
          'damageMultiplier': 1.0,
          'healAmount': 0
        },
      };
      final result =
          resolvePlayerFace(face(type: 'Skill'), skillsWithHeavy, 10);
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

    test(
        'a Skill face whose skill sets inflictsStatus returns it on the '
        'result', () {
      const skillsWithStatus = <String, dynamic>{
        'venomous_ambush': {
          'damageMod': 20,
          'damageMultiplier': 1.8,
          'healAmount': 0,
          'inflictsStatus': 'Poison',
          'statusDuration': 3,
          'statusMagnitude': 6,
        },
      };
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'venomous_ambush'),
        skillsWithStatus,
        10,
      );
      expect(result.inflictedStatus, isNotNull);
      expect(result.inflictedStatus!.type, StatusEffectType.poison);
      expect(result.inflictedStatus!.remainingTurns, 3);
      expect(result.inflictedStatus!.magnitude, 6);
    });

    test('a Skill face with no inflictsStatus field returns null', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'power_strike'),
        skills,
        10,
      );
      expect(result.inflictedStatus, isNull);
    });

    test(
        'a statusDuration of 0 (or missing) never inflicts anything even '
        'if inflictsStatus is set', () {
      const skillsWithStatus = <String, dynamic>{
        'harmless': {
          'damageMod': 0,
          'damageMultiplier': 1.0,
          'healAmount': 0,
          'inflictsStatus': 'Stun',
          'statusDuration': 0,
        },
      };
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'harmless'),
        skillsWithStatus,
        10,
      );
      expect(result.inflictedStatus, isNull);
    });

    test('active Weaken reduces Attack/Skill damage and the message matches',
        () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 50),
      ];
      final attack = resolvePlayerFace(
        face(type: 'Attack', value: 10),
        skills,
        10,
        activeEffects: effects,
      );
      // (10 base + 10 value) halved by 50% Weaken = 10.
      expect(attack.damageDealt, 10);
      expect(attack.message, contains('10 damage'));

      final skillHit = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'power_strike'),
        skills,
        10,
        activeEffects: effects,
      );
      // Unweakened this is (10 + 5) * 2.0 = 30; halved = 15.
      expect(skillHit.damageDealt, 15);
    });

    test('Weaken never applies to Heal/Defend faces', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 100),
      ];
      final heal = resolvePlayerFace(face(type: 'Heal', value: 20), skills, 10,
          activeEffects: effects);
      expect(heal.healingDone, 20);
      final block = resolvePlayerFace(
          face(type: 'Defend', value: 12), skills, 10,
          activeEffects: effects);
      expect(block.blockAmount, 12);
    });

    test('wisdomHealBonus adds straight onto a Heal face\'s value', () {
      final result = resolvePlayerFace(
        face(type: 'Heal', value: 20),
        skills,
        10,
        wisdomHealBonus: 6,
      );
      expect(result.healingDone, 26);
    });

    test('wisdomHealBonus adds onto a healing Skill face', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'minor_heal'),
        skills,
        10,
        wisdomHealBonus: 6,
      );
      expect(result.healingDone, 21); // 15 + 6
    });

    test('wisdomHealBonus never applies to a Skill face with no healing', () {
      final result = resolvePlayerFace(
        face(type: 'Skill', linkedSkillID: 'power_strike'),
        skills,
        10,
        wisdomHealBonus: 6,
      );
      expect(result.healingDone, 0);
    });

    test('wisdomHealBonus never applies to damage-only faces', () {
      final result = resolvePlayerFace(
        face(type: 'Attack', value: 7),
        skills,
        10,
        wisdomHealBonus: 6,
      );
      expect(result.damageDealt, 17);
      expect(result.healingDone, 0);
    });

    group('critical hits', () {
      test('criticalChanceFor scales with luck and caps at 35', () {
        expect(criticalChanceFor(0), 5.0);
        expect(criticalChanceFor(10), 20.0);
        expect(criticalChanceFor(100), 35.0);
      });

      test('dodgeChanceFor scales with dexterity and caps at 30', () {
        expect(dodgeChanceFor(0), 5.0);
        expect(dodgeChanceFor(10), 20.0);
        expect(dodgeChanceFor(100), 30.0);
      });

      test('an Attack face crits when the roll lands under the chance', () {
        final result = resolvePlayerFace(
          face(type: 'Attack', value: 7),
          skills,
          10,
          luck: 10,
          random: _FixedRandom(0.0),
        );
        // rawDamage = 17; crit multiplier 1.5 rounded away from zero = 26.
        expect(result.damageDealt, 26);
        expect(result.isCritical, isTrue);
        expect(result.message, contains('Critical Hit'));
      });

      test('an Attack face does not crit when the roll lands over the chance',
          () {
        final result = resolvePlayerFace(
          face(type: 'Attack', value: 7),
          skills,
          10,
          luck: 10,
          random: _FixedRandom(0.99),
        );
        expect(result.damageDealt, 17);
        expect(result.isCritical, isFalse);
        expect(result.message, isNot(contains('Critical Hit')));
      });

      test('no random passed means no crit ever, regardless of luck', () {
        final result = resolvePlayerFace(
          face(type: 'Attack', value: 7),
          skills,
          10,
          luck: 100,
        );
        expect(result.damageDealt, 17);
        expect(result.isCritical, isFalse);
      });

      test('a Skill face crits its damage but never its healAmount', () {
        const skillsWithBoth = <String, dynamic>{
          'both': {
            'damageMod': 0,
            'damageMultiplier': 1.0,
            'healAmount': 5,
          },
        };
        final result = resolvePlayerFace(
          face(type: 'Skill', linkedSkillID: 'both'),
          skillsWithBoth,
          10,
          luck: 10,
          random: _FixedRandom(0.0),
        );
        // rawDamage = (10 + 0) * 1.0 = 10; crit multiplier 1.5 = 15.
        expect(result.damageDealt, 15);
        expect(result.healingDone, 5);
        expect(result.isCritical, isTrue);
      });

      test('Defend/Heal faces never report a critical hit', () {
        final defend = resolvePlayerFace(
          face(type: 'Defend', value: 12),
          skills,
          10,
          luck: 100,
          random: _FixedRandom(0.0),
        );
        expect(defend.isCritical, isFalse);

        final heal = resolvePlayerFace(
          face(type: 'Heal', value: 20),
          skills,
          10,
          luck: 100,
          random: _FixedRandom(0.0),
        );
        expect(heal.isCritical, isFalse);
      });
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
          {
            'skillID': 'never_happens',
            'condition': 'Chance',
            'chance': 0,
            'priority': 1
          },
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
        expect(result.damage, 10,
            reason: 'seed $seed produced the 0%-chance move');
      }
    });

    test('a Chance move at 100% always fires', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {
            'skillID': 'always_at_100',
            'condition': 'Chance',
            'chance': 100,
            'priority': 1
          },
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
        expect(result.damage, 15,
            reason: 'seed $seed did not produce the 100%-chance move');
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
      expect(atFullHealth.damage, 10,
          reason: 'should not fire above the health threshold');

      final atLowHealth = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 20,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(atLowHealth.damage, 50,
          reason: 'should fire at or below the health threshold');
    });

    test('OnLowHealth honors its chance once the health gate is open', () {
      Map<String, dynamic> enemyWithChance(int chance) => <String, dynamic>{
            'enemyName': 'Test Foe',
            'damage': 10,
            'skillMoves': [
              {
                'skillID': 'desperate_strike',
                'condition': 'OnLowHealth',
                'healthThreshold': 30,
                'chance': chance,
                'priority': 1,
              },
            ],
          };
      const skills = <String, dynamic>{
        'desperate_strike': {'damageMod': 40, 'damageMultiplier': 1.0},
      };
      for (var seed = 0; seed < 20; seed++) {
        final never = resolveEnemyMove(
          enemy: enemyWithChance(0),
          skills: skills,
          enemyCurrentHealth: 20,
          enemyMaxHealth: 100,
          random: Random(seed),
        );
        expect(never.damage, 10,
            reason: 'chance 0 must never fire, even below the threshold');
        final always = resolveEnemyMove(
          enemy: enemyWithChance(100),
          skills: skills,
          enemyCurrentHealth: 20,
          enemyMaxHealth: 100,
          random: Random(seed),
        );
        expect(always.damage, 50, reason: 'chance 100 always fires');
      }
    });

    test(
        'higher-priority move is checked first, but a match always wins the '
        'turn even without a resolvable skill (no fallthrough to lower moves)',
        () {
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

    test('a move whose skill sets inflictsStatus returns it on the result', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Plague Hound',
        'damage': 17,
        'skillMoves': [
          {'skillID': 'plague_bite', 'condition': 'Always', 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'plague_bite': {
          'damageMod': 4,
          'damageMultiplier': 1.0,
          'inflictsStatus': 'Poison',
          'statusDuration': 3,
          'statusMagnitude': 5,
        },
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(result.inflictedStatus, isNotNull);
      expect(result.inflictedStatus!.type, StatusEffectType.poison);
      expect(result.inflictedStatus!.remainingTurns, 3);
      expect(result.inflictedStatus!.magnitude, 5);
    });

    test('a resolved move reads its skill\'s healAmount through unchanged', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Void Stalker',
        'damage': 17,
        'skillMoves': [
          {'skillID': 'shadow_step', 'condition': 'Always', 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'shadow_step': {
          'damageMod': 0,
          'damageMultiplier': 0.0,
          'healAmount': 10,
        },
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(result.healAmount, 10);
    });

    test('a move whose skill has no healAmount field reads 0', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Plague Hound',
        'damage': 17,
        'skillMoves': [
          {'skillID': 'plague_bite', 'condition': 'Always', 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'plague_bite': {'damageMod': 4, 'damageMultiplier': 1.0},
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(result.healAmount, 0);
    });

    test('a plain base attack (no skillID) never inflicts a status', () {
      final enemy = <String, dynamic>{'enemyName': 'Plain Foe', 'damage': 10};
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: const {},
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
      );
      expect(result.inflictedStatus, isNull);
    });

    test(
        'the enemy\'s own active Weaken reduces its move damage, including '
        'the plain-attack fallback', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 50),
      ];
      final enemy = <String, dynamic>{
        'enemyName': 'Weakened Foe',
        'damage': 20
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: const {},
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
        activeEffects: effects,
      );
      expect(result.damage, 10);
    });

    test('the resolved move carries the underlying skill\'s element', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Test Foe',
        'damage': 10,
        'skillMoves': [
          {'skillID': 'fireball', 'condition': 'Always', 'priority': 1},
        ],
      };
      const skills = <String, dynamic>{
        'fireball': {
          'damageMod': 5,
          'damageMultiplier': 1.0,
          'element': 'Fire'
        },
      };
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: skills,
        enemyCurrentHealth: 100,
        enemyMaxHealth: 100,
        random: Random(1),
      );
      expect(result.element, 'Fire');
    });

    test('a plain base attack (no skillID) carries element None', () {
      final enemy = <String, dynamic>{'enemyName': 'Plain Foe', 'damage': 7};
      final result = resolveEnemyMove(
        enemy: enemy,
        skills: const {},
        enemyCurrentHealth: 50,
        enemyMaxHealth: 50,
        random: Random(1),
      );
      expect(result.element, 'None');
    });

    group('OnHitByElement condition', () {
      final enemy = <String, dynamic>{
        'enemyName': 'Iron Golem',
        'damage': 19,
        'skillMoves': [
          {
            'skillID': 'molten_backlash',
            'condition': 'OnHitByElement',
            'requiredElement': 'Fire',
            'priority': 5,
          },
        ],
      };
      const skills = <String, dynamic>{
        'molten_backlash': {'damageMod': 14, 'damageMultiplier': 1.4},
      };

      test('fires when the required element is in elementsHitThisRound', () {
        final result = resolveEnemyMove(
          enemy: enemy,
          skills: skills,
          enemyCurrentHealth: 100,
          enemyMaxHealth: 100,
          random: Random(1),
          elementsHitThisRound: {'Fire'},
        );
        // (baseDamage + damageMod * multiplier).round() = (19 + 19.6).round() = 39
        expect(result.damage, 39);
      });

      test(
          'does not fire when the element is absent, falling back to the '
          'plain attack', () {
        final result = resolveEnemyMove(
          enemy: enemy,
          skills: skills,
          enemyCurrentHealth: 100,
          enemyMaxHealth: 100,
          random: Random(1),
          elementsHitThisRound: {'Water'},
        );
        expect(result.damage, 19);
      });

      test('does not fire with no elementsHitThisRound at all (the default)',
          () {
        final result = resolveEnemyMove(
          enemy: enemy,
          skills: skills,
          enemyCurrentHealth: 100,
          enemyMaxHealth: 100,
          random: Random(1),
        );
        expect(result.damage, 19);
      });
    });
  });

  group('elementFieldPrefixes', () {
    test('covers every non-None element option', () {
      // Mirrors elementOptions in lib/gamedata/db_schema.dart minus 'None'
      // -- kept in sync by hand since the schema layer deliberately avoids
      // depending on gameplay code.
      expect(
        elementFieldPrefixes.keys.toSet(),
        {
          'Fire',
          'Wind',
          'Earth',
          'Water',
          'Electricity',
          'Void',
          'Ice',
          'Light',
        },
      );
    });
  });

  group('level scaling formulas', () {
    test('at level 1, every scaling function returns the base value unchanged',
        () {
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

  group('skill tiers', () {
    final baseSkill = {
      'damageMod': 10,
      'healAmount': 8,
      'damageMultiplier': 1.5,
    };

    test('tier 0 returns the skill unchanged', () {
      final result = applySkillTier(baseSkill, 0);
      expect(result['damageMod'], 10);
      expect(result['healAmount'], 8);
      expect(result['damageMultiplier'], 1.5);
    });

    test('each tier adds 25% to damageMod/healAmount and 0.1 to the multiplier',
        () {
      final tier1 = applySkillTier(baseSkill, 1);
      expect(tier1['damageMod'], 13); // 10 * 1.25 = 12.5 -> rounds to 13
      expect(tier1['healAmount'], 10); // 8 * 1.25 = 10
      expect(tier1['damageMultiplier'], closeTo(1.6, 0.0001));

      final tier3 = applySkillTier(baseSkill, 3);
      expect(tier3['damageMod'], 18); // 10 * 1.75 = 17.5 -> rounds to 18
      expect(tier3['healAmount'], 14); // 8 * 1.75 = 14
      expect(tier3['damageMultiplier'], closeTo(1.8, 0.0001));
    });

    test('never mutates the input map (enemies share the same skills db)', () {
      final original = Map<String, dynamic>.from(baseSkill);
      applySkillTier(baseSkill, 2);
      expect(baseSkill, original);
    });

    test('upgrade cost rises per tier (3, 6, 9)', () {
      expect(skillTierUpgradeCost(0), 3);
      expect(skillTierUpgradeCost(1), 6);
      expect(skillTierUpgradeCost(2), 9);
    });
  });

  group('professionLootAffinityBonus', () {
    test('a matching scalingStat grants the bonus', () {
      final staff = {'itemID': 'staff_t3', 'scalingStat': 'intelligence'};
      expect(professionLootAffinityBonus(staff, 'intelligence'), 20);
    });

    test('a non-matching scalingStat grants nothing', () {
      final staff = {'itemID': 'staff_t3', 'scalingStat': 'intelligence'};
      expect(professionLootAffinityBonus(staff, 'strength'), 0);
    });

    test('an empty preferredScalingStat (e.g. Cleric) never grants a bonus',
        () {
      final staff = {'itemID': 'staff_t3', 'scalingStat': 'intelligence'};
      expect(professionLootAffinityBonus(staff, ''), 0);
    });

    test('an item with no scalingStat field grants nothing', () {
      final potion = {'itemID': 'health_potion'};
      expect(professionLootAffinityBonus(potion, 'intelligence'), 0);
    });

    test('a null item grants nothing', () {
      expect(professionLootAffinityBonus(null, 'intelligence'), 0);
    });
  });

  group('forced criticals and alignment', () {
    final skills = <String, dynamic>{
      'smite': {
        'damageMod': 4,
        'damageMultiplier': 1.0,
        'healAmount': 0,
        'alignment': 'Good',
      },
      'ward': {
        'damageMod': 0,
        'damageMultiplier': 1.0,
        'healAmount': 20,
        'alignment': 'Good',
      },
    };
    DiceFaceResult face(
            {required String type, int value = 0, String skill = ''}) =>
        DiceFaceResult(
          faceIndex: 0,
          faceName: 'f',
          type: type,
          value: value,
          linkedSkillID: skill,
          element: 'None',
        );

    test('forceCritical lands a crit with no Luck and no RNG', () {
      final result = resolvePlayerFace(
          face(type: 'Attack', value: 6), skills, 10,
          forceCritical: true);
      expect(result.isCritical, isTrue);
      expect(result.damageDealt, criticalDamage(16));
    });

    test('a matching alignment strengthens a tagged skill by a quarter', () {
      final good = resolvePlayerFace(
          face(type: 'Skill', skill: 'smite'), skills, 10,
          alignmentLabel: 'Good');
      final neutral =
          resolvePlayerFace(face(type: 'Skill', skill: 'smite'), skills, 10);
      final evil = resolvePlayerFace(
          face(type: 'Skill', skill: 'smite'), skills, 10,
          alignmentLabel: 'Evil');
      expect(neutral.damageDealt, 14);
      expect(good.damageDealt, 18);
      expect(evil.damageDealt, 11);
    });

    test('the multiplier applies to a tagged heal too', () {
      final good = resolvePlayerFace(
          face(type: 'Skill', skill: 'ward'), skills, 10,
          alignmentLabel: 'Good');
      expect(good.healingDone, 25);
      final evil = resolvePlayerFace(
          face(type: 'Skill', skill: 'ward'), skills, 10,
          alignmentLabel: 'Evil');
      expect(evil.healingDone, 15);
    });
  });
}
