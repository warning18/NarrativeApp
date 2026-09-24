// Unit coverage for skill_challenge.dart's pure multi-round resolver --
// the "push your luck" mechanic behind StoryChoice.hasSkillChallenge, as
// opposed to ability_check.dart's single-roll rollAbilityCheck.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/skill_challenge.dart';

import 'player_session_provider_test.dart' show baseSession;

void main() {
  group('resolveSkillChallenge', () {
    test(
        'wins the moment successesNeeded is reached, even with failures '
        'mixed in along the way', () {
      final session = baseSession(luck: 0);
      // DC 10, rolls (as 1-20): 3 (fail), 15 (success), 4 (fail), 16
      // (success) -- needs 2 successes, tolerates up to 3 failures, so it
      // should stop the instant the 2nd success lands, without rolling a
      // 5th time.
      final result = resolveSkillChallenge(
        ability: 'luck',
        dc: 10,
        successesNeeded: 2,
        maxFailures: 3,
        session: session,
        random: _SequenceRandom([2, 14, 3, 15, 19]),
      );
      expect(result.rounds, hasLength(4));
      expect(result.rounds.map((r) => r.success), [false, true, false, true]);
      expect(result.success, isTrue);
    });

    test(
        'loses the moment maxFailures is reached, even short of '
        'successesNeeded', () {
      final session = baseSession(luck: 0);
      // DC 10, rolls: 3 (fail), 4 (fail) -- maxFailures 2 is hit on the
      // 2nd roll, well short of the 3 successes needed, so it should stop
      // there rather than rolling again.
      final result = resolveSkillChallenge(
        ability: 'luck',
        dc: 10,
        successesNeeded: 3,
        maxFailures: 2,
        session: session,
        random: _SequenceRandom([2, 3, 19, 19, 19]),
      );
      expect(result.rounds, hasLength(2));
      expect(result.rounds.map((r) => r.success), [false, false]);
      expect(result.success, isFalse);
    });

    test('a 1-success/1-failure challenge is decided by a single roll', () {
      final session = baseSession(luck: 0);
      final won = resolveSkillChallenge(
        ability: 'luck',
        dc: 10,
        successesNeeded: 1,
        maxFailures: 1,
        session: session,
        random: _SequenceRandom([15]), // rolls 16 -- success
      );
      expect(won.rounds, hasLength(1));
      expect(won.success, isTrue);

      final lost = resolveSkillChallenge(
        ability: 'luck',
        dc: 10,
        successesNeeded: 1,
        maxFailures: 1,
        session: session,
        random: _SequenceRandom([2]), // rolls 3 -- failure
      );
      expect(lost.rounds, hasLength(1));
      expect(lost.success, isFalse);
    });

    test('every round records the real roll and modifier used', () {
      final session = baseSession(luck: 4);
      final result = resolveSkillChallenge(
        ability: 'luck',
        dc: 12,
        successesNeeded: 1,
        maxFailures: 1,
        session: session,
        random: _SequenceRandom([7]), // rolls 8
      );
      final round = result.rounds.single;
      expect(round.check.roll, 8);
      expect(round.check.modifier, 4);
      expect(round.check.total, 12);
      expect(round.success, isTrue); // 12 meets DC 12
    });
  });
}

/// A [Random] stub that returns each of [values] in turn from `nextInt`,
/// so a test can pin an entire sequence of rolls instead of just one.
class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) => values[_index++];

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
