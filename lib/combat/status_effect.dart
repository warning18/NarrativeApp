/// The three status effects combat supports today. Kept as a closed set
/// (rather than a fully generic effect system) because that's what every
/// caller actually needs to distinguish on: which stat bleeds every turn
/// (Poison), whose turn disappears (Stun), or how hard a hit lands
/// (Weaken) — see [StatusEffect.magnitude] for how each one reads it.
enum StatusEffectType { poison, stun, weaken }

/// Parses a `skills.json`/`enemies.json` `inflictsStatus` string value
/// ("Poison"/"Stun"/"Weaken") into a [StatusEffectType], or null for an
/// absent/empty/unrecognized value — the caller's cue that this skill or
/// move doesn't inflict anything.
StatusEffectType? statusEffectTypeFromString(String? value) {
  switch (value) {
    case 'Poison':
      return StatusEffectType.poison;
    case 'Stun':
      return StatusEffectType.stun;
    case 'Weaken':
      return StatusEffectType.weaken;
    default:
      return null;
  }
}

/// One active affliction on a combatant, on either side of a fight.
/// Immutable — [tick] returns a new instance rather than mutating in
/// place, so the fight screen's per-member effect lists stay in charge of
/// when a list actually changes.
class StatusEffect {
  const StatusEffect({
    required this.type,
    required this.remainingTurns,
    this.magnitude = 0,
  });

  final StatusEffectType type;

  /// Turns left, counting the one about to resolve. An effect is dropped
  /// once this reaches 0 after [tick].
  final int remainingTurns;

  /// Poison: flat damage dealt at the start of each of the afflicted
  /// combatant's rounds. Weaken: percent (0-100) reduction applied to every
  /// hit the afflicted combatant lands while it's active. Unused by Stun —
  /// a turn is either skipped or it isn't, there's no strength to it.
  final int magnitude;

  StatusEffect tick() => StatusEffect(
        type: type,
        remainingTurns: remainingTurns - 1,
        magnitude: magnitude,
      );
}

/// Applies [incoming], replacing any existing effect of the same type
/// rather than stacking with it — landing a second Poison hit on an
/// already-poisoned target refreshes its duration/magnitude to the new hit
/// instead of compounding into an ever-growing tick, which would make
/// dogpiling a single status trivially dominant over any other tactic.
List<StatusEffect> applyStatusEffect(
    List<StatusEffect> current, StatusEffect incoming) {
  return [
    for (final effect in current)
      if (effect.type != incoming.type) effect,
    incoming,
  ];
}

/// Total Poison damage to apply this round, from every Poison effect
/// active on the combatant. [applyStatusEffect] never leaves more than one
/// of the same type active at once, but this stays a sum rather than
/// assuming that.
int poisonDamageFor(List<StatusEffect> effects) => effects
    .where((e) => e.type == StatusEffectType.poison)
    .fold(0, (sum, e) => sum + e.magnitude);

bool isStunned(List<StatusEffect> effects) =>
    effects.any((e) => e.type == StatusEffectType.stun);

/// Reduces [damage] by however much active Weaken effects currently cut it
/// — unchanged with none active. Magnitude is a percent reduction, summed
/// across effects and clamped to 100 so a poorly-authored value (or several
/// stacked from different sources) can't flip the result negative.
int applyWeaken(int damage, List<StatusEffect> effects) {
  final totalPercent = effects
      .where((e) => e.type == StatusEffectType.weaken)
      .fold(0, (sum, e) => sum + e.magnitude)
      .clamp(0, 100);
  if (totalPercent <= 0) return damage;
  return (damage * (1 - totalPercent / 100)).round();
}

/// Shortens [effect]'s duration by [wisdom]'s resistance — 1 round off per
/// 5 points of Wisdom, rounded down. Never drops it below 1 round: Wisdom
/// makes a status wear off faster, it doesn't grant outright immunity, so
/// even a very high-Wisdom character still feels an affliction land.
StatusEffect applyWisdomResistance(StatusEffect effect, int wisdom) {
  if (wisdom <= 0) return effect;
  final reduced = effect.remainingTurns - (wisdom ~/ 5);
  return StatusEffect(
    type: effect.type,
    remainingTurns: reduced < 1 ? 1 : reduced,
    magnitude: effect.magnitude,
  );
}

/// Advances every effect in [effects] by one round, dropping any that have
/// now expired. Called once per combatant per round, at the point their
/// own turn ends — so a freshly-applied effect always gets its full stated
/// duration of turns before counting down at all.
List<StatusEffect> tickStatusEffects(List<StatusEffect> effects) {
  return [
    for (final ticked in effects.map((e) => e.tick()))
      if (ticked.remainingTurns > 0) ticked,
  ];
}
