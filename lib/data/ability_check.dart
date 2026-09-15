import 'dart:math';

import '../providers/player_session_provider.dart';

/// The classic six D&D-style ability scores this game tracks on
/// [PlayerSession] (strength/dexterity/constitution/intelligence/wisdom,
/// plus the pre-existing charisma). Kept as plain strings on
/// [StoryChoice.checkAbility] rather than this enum — like every other
/// gameplay-code string key in this codebase (quest objective `type`,
/// `PlayerSessionNotifier.spendStatPoint`'s `stat`) — so story data never
/// needs to import gameplay code.
const List<String> abilityScoreKeys = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'charisma',
];

/// [session]'s current value for [ability] (one of [abilityScoreKeys]),
/// used as a flat bonus on a d20 roll — not a D&D-style 8-20 score
/// converted to a modifier, since every stat here already starts at 0 and
/// grows in small increments (race/profession bonuses, stat points), the
/// same way [PlayerSession.luck] already works as a direct bonus on the
/// combat loot roll.
int abilityModifierFor(String ability, PlayerSession session) {
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

  bool get success => total >= dc;

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
