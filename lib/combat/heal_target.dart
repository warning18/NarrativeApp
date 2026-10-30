// Who a Heal face mends (the user's rule, v1.663): the party member the
// healer aims it at, by default the most wounded one standing. The fight
// screen (fight_rounds.dart) and the simulator (sim_combat.dart) both pick
// the default here.

/// A party member's health, for [defaultHealTarget].
typedef HealthOf = ({int current, int max});

/// The index in [members] a heal from [members][[healer]] goes to by
/// default: the standing member (health above 0) with the lowest share of
/// their health, the healer on a tie. -1 when nobody stands.
int defaultHealTarget(List<HealthOf> members, int healer) {
  var best = -1;
  var bestShare = double.infinity;
  // The healer first, so a tie stays with them.
  for (final i in [healer, for (var i = 0; i < members.length; i++) i]) {
    if (i < 0 || i >= members.length) continue;
    final m = members[i];
    if (m.current <= 0 || m.max <= 0) continue;
    final share = m.current / m.max;
    if (share < bestShare) {
      best = i;
      bestShare = share;
    }
  }
  return best;
}
