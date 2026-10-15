// The patron's passive stats (v5.2 step 5, docs/proposals/
// profession-clan-mechanics.md "Passive stat points per level"): each
// level reached, the clan you stand best with (your patron, at Friendly or
// better; the sworn one first) adds to your stats, on top of the level's
// own reward and the training offer, so a clan pulls your stats as well as
// your mechanic.
//
// - Friendly or Friend: +1 to its first stat ([patronStatsOf]).
// - Trusted: +1 to its first stat and +1 to its second.
// - Sworn: as Trusted, and +[swornPatronHealth] max health.
// - The Open Hand, once its banner is raised: +1 to your strongest stat.
// One patron only: no stacking across clans. Points given stay.
//
// Pure rules; the session (a level reached) and the playthrough simulator
// play them.
import 'factions.dart';

/// Each clan's two stats, the first given from Friendly, the second from
/// Trusted.
const Map<String, List<String>> patronStatsOf = {
  'dominion': ['strength', 'charisma'],
  'vigil': ['constitution', 'perception'],
  'compact': ['constitution', 'strength'],
  'mire': ['dexterity', 'luck'],
  'crows': ['strength', 'dexterity'],
  'penitents': ['wisdom', 'intelligence'],
};

/// What a sworn patron adds to max health each level.
const int swornPatronHealth = 5;

/// The patron of [state]: the sworn clan, else the clan stood highest with
/// at Friendly or better (the first in the data on a tie); '' for none.
String statPatron(PoliticsState state, ClanData data) {
  if (state.swornFactionId.isNotEmpty &&
      patronStatsOf.containsKey(state.swornFactionId)) {
    return state.swornFactionId;
  }
  var best = '';
  var bestValue = double.negativeInfinity;
  for (final id in data.factions.keys) {
    if (!patronStatsOf.containsKey(id)) continue;
    final value = state.standingOf(id, data);
    if (!standingTierFor(value).isAtLeast(StandingTier.friendly)) continue;
    if (value > bestValue) {
      best = id;
      bestValue = value;
    }
  }
  return best;
}

/// What one level reached gives: stat points by stat name, and max
/// health. [stats]: the character's stats now (the Open Hand reads the
/// strongest); [openHand]: its banner raised.
({Map<String, int> stats, int maxHealth}) patronLevelGains(
  PoliticsState state,
  ClanData data, {
  Map<String, int> stats = const {},
  bool openHand = false,
}) {
  final gains = <String, int>{};
  var health = 0;
  final patron = statPatron(state, data);
  if (patron.isNotEmpty) {
    final mine = patronStatsOf[patron]!;
    final tier = state.tierOf(patron, data);
    gains[mine[0]] = 1;
    if (tier.isAtLeast(StandingTier.trusted)) {
      gains[mine[1]] = (gains[mine[1]] ?? 0) + 1;
    }
    if (tier == StandingTier.sworn) health = swornPatronHealth;
  }
  if (openHand && stats.isNotEmpty) {
    final strongest =
        stats.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    gains[strongest] = (gains[strongest] ?? 0) + 1;
  }
  return (stats: gains, maxHealth: health);
}
