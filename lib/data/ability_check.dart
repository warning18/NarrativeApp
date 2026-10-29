import 'dart:math';

import '../providers/player_session_provider.dart';

/// The classic six D&D-style ability scores this game tracks on
/// [PlayerSession] (strength/dexterity/constitution/intelligence/wisdom,
/// plus the pre-existing charisma). Kept as plain strings on
/// [StoryChoice.checkAbility] rather than this enum — like every other
/// gameplay-code string key in this codebase (quest objective `type`,
/// a stat pick's gains in training_paths.json) — so story data never
/// needs to import gameplay code.
const List<String> abilityScoreKeys = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'charisma',
  'luck',
  'perception',
];

/// The bonus on a d20 an ability [score] gives a check, on the stat scale
/// (docs/proposals/stat-scale.md, "Story checks on the small scale"): 2,
/// and twice the square root of the score, rounded -- 0 gives 2, 1 gives
/// 4, 4 gives 6, 9 gives 8, 16 gives 10. A score below zero takes from the
/// 2. The root keeps a trained stat ahead of the story's DCs (10 to 16) as
/// they climb without passing them all; a natural 1 still fails (see
/// [checkPasses]).
int checkBonusFor(int score) =>
    score <= 0 ? 2 + score : 2 + (2 * sqrt(score)).round();

/// Whether a d20 [roll] with [modifier] meets [dc]: a natural 20 always
/// passes, a natural 1 always fails, any other roll when the total reaches
/// the DC.
bool checkPasses(int roll, int modifier, int dc) =>
    roll == 20 || (roll != 1 && roll + modifier >= dc);

/// [session]'s bonus on a d20 for [ability] (one of [abilityScoreKeys]):
/// [checkBonusFor] its current value.
int abilityModifierFor(String ability, PlayerSession session) =>
    checkBonusFor(abilityScoreFor(ability, session));

/// [session]'s current value for [ability] (one of [abilityScoreKeys]).
int abilityScoreFor(String ability, PlayerSession session) {
  switch (ability) {
    case 'strength':
      return session.strength;
    case 'dexterity':
      return session.dexterity;
    case 'constitution':
      return session.constitution;
    case 'intelligence':
      return session.intelligence;
    case 'wisdom':
      return session.wisdom;
    case 'charisma':
      return session.charisma;
    case 'luck':
      return session.luck;
    case 'perception':
      return session.perception;
    default:
      return 0;
  }
}

/// The outcome of one ability check: a d20 roll plus the character's
/// ability bonus, compared against a difficulty class (DC) — the BG3/D&D
/// "attempt" pattern, as opposed to [PlayerSession.meetsRequirements]'s
/// hard, deterministic threshold gates.
class AbilityCheckResult {
  const AbilityCheckResult({
    required this.ability,
    required this.roll,
    required this.modifier,
    required this.dc,
  });

  final String ability;

  /// The raw d20 roll, 1-20.
  final int roll;
  final int modifier;
  final int dc;

  int get total => roll + modifier;

  bool get success => checkPasses(roll, modifier, dc);

  /// A natural 20 always succeeds and a natural 1 always fails, mirroring
  /// D&D's critical roll convention — checked separately from [success] so
  /// the UI can call out a critical result even when the modifier alone
  /// would have decided it either way.
  bool get isCriticalSuccess => roll == 20;
  bool get isCriticalFail => roll == 1;
}

/// Rolls a d20, adds [session]'s bonus for [ability], and compares the
/// total against [dc]. [random] is injectable for tests; production
/// callers omit it and get a fresh roll each time.
AbilityCheckResult rollAbilityCheck({
  required String ability,
  required int dc,
  required PlayerSession session,
  Random? random,
}) {
  final rng = random ?? Random();
  final roll = rng.nextInt(20) + 1;
  return AbilityCheckResult(
    ability: ability,
    roll: roll,
    modifier: abilityModifierFor(ability, session),
    dc: dc,
  );
}

/// The chance a d20 plus [modifier] meets [dc], from 0.05 to 0.95 (a
/// check succeeds when the total reaches the DC, a natural 20 always and a
/// natural 1 never; see [checkPasses]).
double checkChance({required int modifier, required int dc}) =>
    (21 - (dc - modifier)).clamp(1, 19) / 20;
