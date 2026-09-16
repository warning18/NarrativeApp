// Unit coverage for lib/combat/status_effect.dart -- the pure
// Poison/Stun/Weaken bookkeeping behind fight_screen.dart's turn loop.
// Kept separate from combat_engine_test.dart since this module has no
// dependency on dice faces, skills, or enemy data at all.

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/status_effect.dart';

void main() {
  group('statusEffectTypeFromString', () {
    test('parses the three known values', () {
      expect(statusEffectTypeFromString('Poison'), StatusEffectType.poison);
      expect(statusEffectTypeFromString('Stun'), StatusEffectType.stun);
      expect(statusEffectTypeFromString('Weaken'), StatusEffectType.weaken);
    });

    test('null, empty, or unrecognized values all return null', () {
      expect(statusEffectTypeFromString(null), isNull);
      expect(statusEffectTypeFromString(''), isNull);
      expect(statusEffectTypeFromString('None'), isNull);
      expect(statusEffectTypeFromString('poison'), isNull); // case-sensitive
    });
  });

  group('applyStatusEffect', () {
    test('adds a new effect to an empty list', () {
      const incoming = StatusEffect(
          type: StatusEffectType.poison, remainingTurns: 3, magnitude: 5);
      final result = applyStatusEffect(const [], incoming);
      expect(result, [incoming]);
    });

    test(
        'refreshes (replaces) an existing effect of the same type rather '
        'than stacking it', () {
      const original = StatusEffect(
          type: StatusEffectType.poison, remainingTurns: 1, magnitude: 2);
      const incoming = StatusEffect(
          type: StatusEffectType.poison, remainingTurns: 3, magnitude: 9);
      final result = applyStatusEffect([original], incoming);
      expect(result.length, 1);
      expect(result.single.remainingTurns, 3);
      expect(result.single.magnitude, 9);
    });

    test('effects of different types coexist', () {
      const poison = StatusEffect(
          type: StatusEffectType.poison, remainingTurns: 2, magnitude: 4);
      const stun = StatusEffect(type: StatusEffectType.stun, remainingTurns: 1);
      final result = applyStatusEffect([poison], stun);
      expect(result, containsAll([poison, stun]));
      expect(result.length, 2);
    });
  });

  group('poisonDamageFor', () {
    test('sums magnitude across every Poison effect present', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.poison, remainingTurns: 2, magnitude: 5),
        StatusEffect(type: StatusEffectType.stun, remainingTurns: 1),
      ];
      expect(poisonDamageFor(effects), 5);
    });

    test('is 0 with no active Poison effect', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 30),
      ];
      expect(poisonDamageFor(effects), 0);
      expect(poisonDamageFor(const []), 0);
    });
  });

  group('isStunned', () {
    test('true only when a Stun effect is present', () {
      expect(
          isStunned(const [
            StatusEffect(type: StatusEffectType.stun, remainingTurns: 1)
          ]),
          isTrue);
      expect(
          isStunned(const [
            StatusEffect(
                type: StatusEffectType.poison, remainingTurns: 1, magnitude: 5)
          ]),
          isFalse);
      expect(isStunned(const []), isFalse);
    });
  });

  group('applyWeaken', () {
    test('unchanged damage with no active Weaken effect', () {
      expect(applyWeaken(100, const []), 100);
    });

    test('reduces damage by the summed percent magnitude', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 30),
      ];
      expect(applyWeaken(100, effects), 70);
    });

    test('multiple Weaken effects sum their percentages', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 20),
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 1, magnitude: 15),
      ];
      // 35% off 100 -> 65
      expect(applyWeaken(100, effects), 65);
    });

    test('clamps a combined percent above 100 so damage never goes negative',
        () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 2, magnitude: 80),
        StatusEffect(
            type: StatusEffectType.weaken, remainingTurns: 1, magnitude: 80),
      ];
      expect(applyWeaken(100, effects), 0);
    });
  });

  group('tickStatusEffects', () {
    test('decrements remainingTurns by 1', () {
      const effects = [
        StatusEffect(
            type: StatusEffectType.poison, remainingTurns: 3, magnitude: 5),
      ];
      final result = tickStatusEffects(effects);
      expect(result.single.remainingTurns, 2);
      expect(result.single.magnitude, 5); // magnitude untouched
    });

    test('drops an effect once its remainingTurns reaches 0', () {
      const effects = [
        StatusEffect(type: StatusEffectType.stun, remainingTurns: 1),
        StatusEffect(
            type: StatusEffectType.poison, remainingTurns: 3, magnitude: 5),
      ];
      final result = tickStatusEffects(effects);
      expect(result.length, 1);
      expect(result.single.type, StatusEffectType.poison);
      expect(result.single.remainingTurns, 2);
    });

    test('an empty list stays empty', () {
      expect(tickStatusEffects(const []), isEmpty);
    });
  });
}
