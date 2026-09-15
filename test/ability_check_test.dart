// Unit coverage for ability_check.dart's pure dice-roll logic -- the
// BG3/D&D-style "attempt" mechanic behind StoryChoice.checkAbility, as
// opposed to PlayerSession.meetsRequirements' hard, deterministic gates.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ability_check.dart';

import 'player_session_provider_test.dart' show baseSession;

void main() {
  group('abilityModifierFor', () {
    test('reads the matching stat off the session', () {
      final session = baseSession(strength: 3, dexterity: 5, charisma: 7);
      expect(abilityModifierFor('strength', session), 3);
      expect(abilityModifierFor('dexterity', session), 5);
      expect(abilityModifierFor('charisma', session), 7);
    });

    test('an unknown ability key is a zero bonus', () {
      final session = baseSession(strength: 10);
      expect(abilityModifierFor('nonsense', session), 0);
    });
  });

  group('rollAbilityCheck', () {
    test('a high roll plus modifier beats the DC', () {
      final session = baseSession(strength: 5);
      // A fixed Random seed that produces a roll high enough to guarantee
      // success given the +5 modifier and a modest DC.
      final result = rollAbilityCheck(
        ability: 'strength',
        dc: 10,
        session: session,
        random: _FixedRandom(19), // rolls 20 (nextInt(20) + 1)
      );
      expect(result.roll, 20);
      expect(result.modifier, 5);
      expect(result.total, 25);
      expect(result.success, isTrue);
      expect(result.isCriticalSuccess, isTrue);
      expect(result.isCriticalFail, isFalse);
    });

    test('a low roll plus modifier misses the DC', () {
      final session = baseSession(strength: 0);
      final result = rollAbilityCheck(
        ability: 'strength',
        dc: 10,
        session: session,
        random: _FixedRandom(0), // rolls 1
      );
      expect(result.roll, 1);
      expect(result.total, 1);
      expect(result.success, isFalse);
      expect(result.isCriticalFail, isTrue);
    });

    test('total meeting the DC exactly still succeeds', () {
      final session = baseSession(dexterity: 4);
      final result = rollAbilityCheck(
        ability: 'dexterity',
        dc: 14,
        session: session,
        random: _FixedRandom(9), // rolls 10
      );
      expect(result.total, 14);
      expect(result.success, isTrue);
    });
  });
}

/// A [Random] stub whose `nextInt` always returns the same value, so tests
/// can pin the d20 roll instead of depending on real randomness.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
