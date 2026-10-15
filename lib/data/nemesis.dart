// The nemesis (v5.2 step 6, docs/proposals/territory-power-nemesis.md):
// a clan the character keeps turning against does not just fade.
//
// - Who: at most one, the strongest main clan (power [nemesisMinPower] or
//   more) the character stands Hostile or Hunted with. It rises at a
//   chapter's turn ([updateNemesis]) and stays until the standing climbs
//   back to Wary, so it does not flicker at the border.
// - What it does: it hunts the character, sworn or not, at the Hunted
//   odds (rival_hunters.dart: its hunters share the alignment hunters' cap
//   and cooldown, mercy and betrayal); at war it takes your patron's
//   places first (clan_power.dart); it offers nothing (Hostile already
//   does that).
// - Breaking it ([breakNemesis], its quest's end, PR 5): a tier of power
//   lost, the hunt ended, and no nemesis from it for
//   [nemesisBreakChapters] chapters.
//
// Pure rules; the session (a chapter reached) and the playthrough
// simulator play them.
import '../l10n/app_locale.dart';
import 'clan_power.dart';
import 'factions.dart';

const int nemesisMinPower = risingPower;
const int nemesisBreakChapters = 2;

/// Whether [state]'s standing with [clanId] makes it a nemesis candidate:
/// Hostile or Hunted.
bool _turnedAgainst(PoliticsState state, String clanId, ClanData data) =>
    !state.tierOf(clanId, data).isAtLeast(StandingTier.resented);

/// The clan that would be the character's nemesis now, with no
/// hysteresis: the strongest main clan of power [nemesisMinPower] or more
/// stood Hostile or Hunted with, not fallen, not cooling down; '' for
/// none.
String nemesisCandidate(PoliticsState state, ClanData data, {int chapter = 0}) {
  var best = '';
  var bestPower = -1;
  for (final id in data.factions.keys) {
    if (!isMainClan(id, data) || state.fallen.contains(id)) continue;
    if ((state.nemesisCooldown[id] ?? 0) > chapter) continue;
    if (!_turnedAgainst(state, id, data)) continue;
    final power = powerOf(state, id, data);
    if (power < nemesisMinPower || power <= bestPower) continue;
    best = id;
    bestPower = power;
  }
  return best;
}

/// Whether the nemesis [clanId] lets go: the standing back at Wary or
/// better, or the clan fallen.
bool nemesisEnds(PoliticsState state, String clanId, ClanData data) =>
    state.fallen.contains(clanId) ||
    state.tierOf(clanId, data).isAtLeast(StandingTier.wary);

/// [state] with its nemesis brought up to date at [chapter]: the one held
/// kept until it ends ([nemesisEnds]), then the [nemesisCandidate]; the
/// news says when one rises or lets go.
PoliticsState updateNemesis(
  PoliticsState state,
  ClanData data, {
  int chapter = 0,
  int day = 0,
}) {
  var next = state;
  final held = state.nemesis;
  if (held.isNotEmpty) {
    if (!nemesisEnds(state, held, data)) return state;
    next = _told(next.copyWith(nemesis: ''), 'nemesis_end:$held',
        nemesisEndNews(data.faction(held)), chapter, day);
  }
  final rising = nemesisCandidate(next, data, chapter: chapter);
  if (rising.isEmpty || rising == held) return next;
  return _told(next.copyWith(nemesis: rising), 'nemesis:$rising',
      nemesisRiseNews(data.faction(rising)), chapter, day);
}

/// [state] with the nemesis [clanId] broken (its quest won): a tier of
/// power lost, the hunt over, and none from it for [nemesisBreakChapters].
PoliticsState breakNemesis(
  PoliticsState state,
  String clanId,
  ClanData data, {
  int chapter = 0,
  int day = 0,
}) {
  final power = powerOf(state, clanId, data);
  var next = addPower(state, clanId, -min25(power), data).copyWith(
    nemesis: state.nemesis == clanId ? '' : state.nemesis,
    nemesisCooldown: {
      ...state.nemesisCooldown,
      clanId: chapter + nemesisBreakChapters,
    },
  );
  next = _told(next, 'nemesis_end:$clanId',
      nemesisEndNews(data.faction(clanId)), chapter, day);
  return next;
}

/// A tier of [power]: 25, never more than there is.
int min25(int power) => power < risingPower ? power : risingPower;

PoliticsState _told(PoliticsState state, String id,
    ({String en, String fr}) text, int chapter, int day) {
  final news = [
    ...state.news,
    CoastNews(
      eventId: id,
      chapter: chapter,
      day: day,
      text: text.en,
      textFr: text.fr,
    ),
  ];
  return state.copyWith(
      news: news.length <= maxCoastNews
          ? news
          : news.sublist(news.length - maxCoastNews));
}

/// The news of [clan] making the character its nemesis.
({String en, String fr}) nemesisRiseNews(Faction? clan) => (
      en: '${clan?.nameFor(AppLanguage.en) ?? ''} have made you their '
          'nemesis. Their hunters are on your roads.',
      fr: 'Les gens ${clan?.nameOfFor(AppLanguage.fr) ?? ''} vous tiennent '
          'pour leur ennemi juré : leurs chasseurs sont sur vos routes.',
    );

/// The news of the nemesis [clan] letting go.
({String en, String fr}) nemesisEndNews(Faction? clan) => (
      en: '${clan?.nameFor(AppLanguage.en) ?? ''} no longer hunt you.',
      fr: 'Les gens ${clan?.nameOfFor(AppLanguage.fr) ?? ''} ne vous '
          'traquent plus.',
    );
