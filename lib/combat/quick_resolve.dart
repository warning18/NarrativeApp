/// Quick resolve (v1.213): a fight against enemies the party has beaten
/// many times plays itself, a roll and a confirm a round, until it ends or
/// the party is hurt. It is the same engine as a played fight, only the
/// choices are made for you and the animations are short, so every rule in
/// the fight holds.
///
/// Offered only when every enemy has been beaten at least
/// [quickResolveKills] times, the player is in good shape, and the fight is
/// an ordinary one (no boss, unique, hunt, ambush, lesson or story fight
/// with a defeat branch).
const int quickResolveKills = 5;

/// The share of the player's health under which a fight is not offered
/// quick resolve.
const double quickResolveMinHealth = 0.6;

/// The share of the player's health under which a quick resolve stops and
/// hands the fight back.
const double quickResolveStopHealth = 0.45;

/// True when a fight against [enemyIds] may be quick-resolved. [killCounts]
/// is the session's tally of enemies beaten, by id; [eligible] is the
/// caller's verdict on the fight itself; [healthShare] the player's health
/// as a share of their maximum.
bool quickResolveOffered({
  required List<String> enemyIds,
  required Map<String, int> killCounts,
  required bool eligible,
  required double healthShare,
}) {
  if (!eligible || enemyIds.isEmpty) return false;
  if (healthShare < quickResolveMinHealth) return false;
  return enemyIds.every((id) => (killCounts[id] ?? 0) >= quickResolveKills);
}

/// True when a running quick resolve should stop and hand the fight back:
/// the player is hurt, or a companion has fallen.
bool quickResolveShouldStop({
  required double playerHealthShare,
  required bool anyAllyDown,
}) =>
    playerHealthShare < quickResolveStopHealth || anyAllyDown;
