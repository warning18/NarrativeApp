import 'dart:math';

import 'ability_check.dart';
import '../providers/player_session_provider.dart';

/// The outcome of one round within a [SkillChallengeResult] — just the
/// underlying [AbilityCheckResult], named for readability at call sites.
class SkillChallengeRound {
  const SkillChallengeRound(this.check);

  final AbilityCheckResult check;

  bool get success => check.success;
}

/// The outcome of a full skill challenge: every round rolled, in order, and
/// whether the player reached [SkillChallengeRound]-counted successes
/// before failures ran out.
class SkillChallengeResult {
  const SkillChallengeResult({required this.rounds, required this.success});

  final List<SkillChallengeRound> rounds;
  final bool success;
}

/// Resolves a full skill challenge in one call: roll after roll against
/// [ability]/[dc], stopping the moment the player has [successesNeeded]
/// successes (a win) or [maxFailures] failures (a loss). Unlike a single
/// [rollAbilityCheck], this rewards sticking with a bad start — a failure
/// early on doesn't end the attempt, it just narrows the margin — which is
/// the whole point of offering it as a distinct choice from a one-shot
/// check.
///
/// Returns every round rolled (not just the final tally) so callers — the
/// UI in particular — can replay the sequence rather than only knowing the
/// end state. [random] is injectable for tests; production callers omit it.
SkillChallengeResult resolveSkillChallenge({
  required String ability,
  required int dc,
  required int successesNeeded,
  required int maxFailures,
  required PlayerSession session,
  Random? random,
}) {
  final rng = random ?? Random();
  final rounds = <SkillChallengeRound>[];
  var successes = 0;
  var failures = 0;
  while (successes < successesNeeded && failures < maxFailures) {
    final check = rollAbilityCheck(
      ability: ability,
      dc: dc,
      session: session,
      random: rng,
    );
    rounds.add(SkillChallengeRound(check));
    if (check.success) {
      successes++;
    } else {
      failures++;
    }
  }
  return SkillChallengeResult(
    rounds: rounds,
    success: successes >= successesNeeded,
  );
}
