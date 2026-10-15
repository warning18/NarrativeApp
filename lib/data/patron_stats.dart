// The patron's passive stats (v5.2 step 5, docs/proposals/
// profession-clan-mechanics.md "Passive stat points per level"): each
// level reached, the clan you stand best with (your patron, at Friendly or
// better; the sworn one first) adds to your stats, on top of the level's
// own reward and the training offer, so a clan pulls your stats as well as
// your mechanic.
//
// - Friendly or Friend: +1 to its first stat ([patronStatsOf]).
// - Trusted: +1 to its first stat and its second in turn (the second on
//   even levels).
// - Sworn: as Trusted, and +[swornPatronHealth] max health.
// One point a level: two, as first designed, won the late bosses 13 to 16
// points more often than their curve (boss_balance_test).
// - The Open Hand, once its banner is raised: +1 to your strongest stat.
// One patron only: no stacking across clans. Points given stay.
//
// Pure rules; the session (a level reached) and the playthrough simulator
// play them.
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
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
/// at Friendly or better (the first of [patronStatsOf] on a tie); '' for
/// none. A clan never moved with stands at its start, under Friendly, so
/// the standings kept are enough.
String statPatron(PoliticsState state) {
  if (state.swornFactionId.isNotEmpty &&
      patronStatsOf.containsKey(state.swornFactionId)) {
    return state.swornFactionId;
  }
  var best = '';
  var bestValue = double.negativeInfinity;
  for (final id in patronStatsOf.keys) {
    final value = state.standings[id];
    if (value == null) continue;
    if (!standingTierFor(value).isAtLeast(StandingTier.friendly)) continue;
    if (value > bestValue) {
      best = id;
      bestValue = value;
    }
  }
  return best;
}

/// What reaching [level] gives: stat points by stat name, and max health.
/// [stats]: the character's stats now (the Open Hand reads the strongest);
/// [openHand]: its banner raised.
({Map<String, int> stats, int maxHealth}) patronLevelGains(
  PoliticsState state, {
  int level = 1,
  Map<String, int> stats = const {},
  bool openHand = false,
}) {
  final gains = <String, int>{};
  var health = 0;
  final patron = statPatron(state);
  if (patron.isNotEmpty) {
    final mine = patronStatsOf[patron]!;
    final tier = standingTierFor(state.standings[patron] ?? 0);
    final second = tier.isAtLeast(StandingTier.trusted) && level.isEven;
    gains[mine[second ? 1 : 0]] = 1;
    if (tier == StandingTier.sworn) health = swornPatronHealth;
  }
  if (openHand && stats.isNotEmpty) {
    final strongest =
        stats.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    gains[strongest] = (gains[strongest] ?? 0) + 1;
  }
  return (stats: gains, maxHealth: health);
}

/// [gains] (stat points by stat, and max health) in [language]:
/// "+1 Strength, +1 Charisma, +5 max health".
String patronGainsText(
    ({Map<String, int> stats, int maxHealth}) gains, AppLanguage language) {
  return [
    for (final MapEntry(:key, :value) in gains.stats.entries)
      '+$value ${trFor(language, '${key}_label')}',
    if (gains.maxHealth > 0)
      trFor(language, 'patron_max_health')
          .replaceAll('{n}', '${gains.maxHealth}'),
  ].join(', ');
}

/// The patron's gifts at a level-up, logged on the clan log (cause
/// `patron:<clan>`, the gains in its note); [state] unchanged when there
/// is nothing to log.
PoliticsState logPatronGains(
  PoliticsState state,
  String patron,
  ({Map<String, int> stats, int maxHealth}) gains, {
  int chapter = 0,
  int day = 0,
}) {
  if (gains.stats.isEmpty && gains.maxHealth == 0) return state;
  return withStandingLogEntry(
      state,
      StandingLogEntry(
        chapter: chapter,
        day: day,
        cause: patron.isEmpty ? 'patron' : 'patron:$patron',
        factionId: patron,
        note: patronGainsText(gains, AppLanguage.en),
        noteFr: patronGainsText(gains, AppLanguage.fr),
      ));
}
