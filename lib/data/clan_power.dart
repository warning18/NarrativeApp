// Clan power and territory (v5.2 step 6, docs/proposals/
// territory-power-nemesis.md): standing is how a clan sees you; power is
// how strong it is, and the places it holds show it.
//
// - Power runs 0..100 per clan with a `power` in factions.json, starting
//   there. Tiers: Minor, Rising from 25, Dominant from 50, Ascendant from
//   75.
// - What moves it: a gift taken from it (+[giftPower], a legendary one
//   +[legendaryGiftPower]), a quest done for it (+[questPower]: its
//   outcome raises the clan's standing [questPowerStanding] or more),
//   politics events and story choices (`power`), and each chapter: +[holdingPower] a place it holds,
//   and -[neglectPower] for a main clan the character did nothing for (no
//   lower than [neglectFloor] under its start).
// - The places: geography.json's holders, then [PoliticsState.control]
//   as places change hands at a chapter's turn ([territoryTurn]), one
//   change a clan at most:
//   - a main clan risen a tier above where it started takes its next
//     claim, from no one or from a weaker holder;
//   - at war (relation step [warStep] or below), a clan [warLead] stronger
//     takes a place of the other's, its seat last;
//   - politics events and story choices give places (`control`).
//   Every change drops the old and new holders' relation a step and tells
//   the news. A clan that loses its last place has fallen: its power goes
//   to 0 until it takes a place again (its seat first).
//
// Pure rules; the session (a chapter reached) and the playthrough
// simulator play them.
import 'dart:math';

import '../l10n/app_locale.dart';
import 'factions.dart';
import 'geography.dart';

const int maxPower = 100;

enum PowerTier { minor, rising, dominant, ascendant }

const int risingPower = 25;
const int dominantPower = 50;
const int ascendantPower = 75;

const int giftPower = 2;
const int legendaryGiftPower = 4;
const int questPower = 5;

/// The standing a quest's outcome must raise with a clan to count as done
/// for it.
const int questPowerStanding = 5;
const int holdingPower = 1;
const int neglectPower = 5;
const int neglectFloor = 20;

/// The relation step at which two clans fight over places (2: War; 1 is a
/// blood feud).
const int warStep = 2;

/// How much stronger a clan at war must be to take a place.
const int warLead = 15;

PowerTier powerTierFor(int power) => power >= ascendantPower
    ? PowerTier.ascendant
    : power >= dominantPower
        ? PowerTier.dominant
        : power >= risingPower
            ? PowerTier.rising
            : PowerTier.minor;

/// Whether [clanId] has power at all (a `power` in factions.json).
bool hasPower(String clanId, ClanData data) =>
    (data.faction(clanId)?.startPower ?? 0) > 0;

/// Whether [clanId] is one of the main clans: power, and neglect.
bool isMainClan(String clanId, ClanData data) =>
    hasPower(clanId, data) && (data.faction(clanId)?.isClan ?? false);

/// [clanId]'s power now: moved, or where it starts.
int powerOf(PoliticsState state, String clanId, ClanData data) =>
    state.power[clanId] ?? data.faction(clanId)?.startPower ?? 0;

/// [state] with [clanId]'s power moved by [delta] (kept in 0..[maxPower]);
/// [helped]: the character did it, which spares the clan this chapter's
/// neglect. Unchanged for a faction with no power.
PoliticsState addPower(
  PoliticsState state,
  String clanId,
  int delta,
  ClanData data, {
  bool helped = false,
}) {
  if (!hasPower(clanId, data)) return state;
  final next = (powerOf(state, clanId, data) + delta).clamp(0, maxPower);
  return state.copyWith(
    power: {...state.power, clanId: next},
    helped: helped && !state.helped.contains(clanId)
        ? [...state.helped, clanId]
        : null,
  );
}

/// The power a gift of [rarity] (a SignRarity's name) taken from its clan
/// brings: the heroic ones, the legendary, more.
int giftPowerFor(String rarity) =>
    const {'heroic', 'legendary'}.contains(rarity.toLowerCase())
        ? legendaryGiftPower
        : giftPower;

/// The holder written on [place] itself: changed hands, or geography's.
String _ownHolder(GeoPlace place, PoliticsState state) =>
    state.control[place.id] ?? place.controller;

/// The faction that holds [placeId] now: the nearest holder up the chain
/// (a district takes its city's), with the places that changed hands; ''
/// for none. As Geography.heldBy, with no fall back to a country's ruler.
String holderOf(String? placeId, Geography geography, PoliticsState state) {
  for (final place in geography.pathOf(placeId).reversed) {
    final holder = _ownHolder(place, state);
    if (holder.isNotEmpty) return holder;
  }
  return '';
}

/// Every place with a holder of its own (place id -> faction), in the
/// geography's order.
Map<String, String> holdings(Geography geography, PoliticsState state) => {
      for (final place in geography.places.values)
        if (_ownHolder(place, state) case final holder when holder.isNotEmpty)
          place.id: holder,
    };

/// The places [clanId] holds, in the geography's order.
List<String> placesOf(
        String clanId, Geography geography, PoliticsState state) =>
    [
      for (final e in holdings(geography, state).entries)
        if (e.value == clanId) e.key,
    ];

/// How many of its claims [clanId] may hold at its power: a tier for each
/// tier risen above where it started; a fallen clan, one (its seat) once
/// Rising.
int claimsAllowed(PoliticsState state, String clanId, ClanData data) {
  final now = powerTierFor(powerOf(state, clanId, data)).index;
  if (state.fallen.contains(clanId)) {
    return now >= PowerTier.rising.index ? 1 : 0;
  }
  final start = powerTierFor(data.faction(clanId)?.startPower ?? 0).index;
  return max(0, now - start);
}

/// One place changing hands at a chapter's turn.
class TerritoryChange {
  const TerritoryChange({
    required this.placeId,
    required this.from,
    required this.to,
    required this.cause,
  });

  final String placeId;

  /// The holder before ('' for none).
  final String from;
  final String to;

  /// 'claim', 'war' or 'event'.
  final String cause;
}

/// [state] with [placeId] given to [to] ([cause]: 'claim', 'war',
/// 'event'), its news told and logged, the old holder's relation with the
/// new one a step down, and the fallen kept: a clan left with no place
/// falls (its power to 0); one taking a place rises again. Unchanged when
/// [to] holds it already.
PoliticsState givePlace(
  PoliticsState state,
  String placeId,
  String to, {
  required String cause,
  required ClanData data,
  required Geography geography,
  int chapter = 0,
  int day = 0,
  List<TerritoryChange>? changes,
}) {
  final place = geography.place(placeId);
  if (place == null || to.isEmpty) return state;
  final from = _ownHolder(place, state);
  if (from == to) return state;
  var next = state.copyWith(control: {...state.control, placeId: to});
  changes?.add(
      TerritoryChange(placeId: placeId, from: from, to: to, cause: cause));
  if (from.isNotEmpty) {
    next = shiftRelation(next, from, to, -1, 'territory:$placeId',
            data: data, chapter: chapter, day: day)
        .state;
  }
  final variant = placeId.codeUnits.fold(0, (a, b) => a + b) % 2;
  String told(AppLanguage language) => territoryNews(
        language,
        place: place.nameFor(language == AppLanguage.fr),
        to: data.faction(to),
        from: data.faction(from),
        fromClan: from.isNotEmpty && isMainClan(from, data),
        war: cause == 'war',
        variant: variant,
      );

  next = next.copyWith(news: [
    ...next.news,
    CoastNews(
      eventId: 'territory:$placeId',
      chapter: chapter,
      day: day,
      text: told(AppLanguage.en),
      textFr: told(AppLanguage.fr),
    ),
  ]);
  // The clan log (Narrative's 2e): "Kindly Hill: the Kindly Ones → the
  // Mire Courts."
  String logged(AppLanguage language) {
    final fr = language == AppLanguage.fr;
    final loser = from.isEmpty ? '—' : _name(data.faction(from), language);
    return '${place.nameFor(fr)}${fr ? '\u00a0:' : ':'} $loser → '
        '${_name(data.faction(to), language)}.';
  }

  next = withStandingLogEntry(
      next,
      StandingLogEntry(
        chapter: chapter,
        day: day,
        cause: 'territory',
        factionId: to,
        note: logged(AppLanguage.en),
        noteFr: logged(AppLanguage.fr),
      ));
  // The fallen: the old holder with nothing left falls; the new one rises.
  final fallen = [...next.fallen]..remove(to);
  if (from.isNotEmpty &&
      isMainClan(from, data) &&
      placesOf(from, geography, next).isEmpty &&
      !fallen.contains(from)) {
    fallen.add(from);
    next = next.copyWith(power: {...next.power, from: 0});
    String fell(AppLanguage language) => fallenNews(language,
        clan: data.faction(from),
        winner: data.faction(to),
        seat: place.nameFor(language == AppLanguage.fr),
        variant: variant);
    next = next.copyWith(news: [
      ...next.news,
      CoastNews(
        eventId: 'fallen:$from',
        chapter: chapter,
        day: day,
        text: fell(AppLanguage.en),
        textFr: fell(AppLanguage.fr),
      ),
    ]);
  }
  next = next.copyWith(fallen: fallen);
  final over = next.news.length - maxCoastNews;
  return over > 0 ? next.copyWith(news: next.news.sublist(over)) : next;
}

/// What a new [chapter] does to the clans' power and places: each place
/// held brings its holder [holdingPower]; each main clan the character did
/// nothing for loses [neglectPower] (no lower than [neglectFloor] under
/// its start); then claims, then wars, one change a clan at most. The
/// chapter's [PoliticsState.helped] is cleared.
({PoliticsState state, List<TerritoryChange> changes}) territoryTurn(
  PoliticsState state, {
  required ClanData data,
  required Geography geography,
  required int chapter,
  int day = 0,
}) {
  var next = state;
  // Holdings and neglect.
  final held = holdings(geography, next);
  final powers = <String, int>{};
  for (final id in data.factions.keys) {
    if (!hasPower(id, data)) continue;
    var value = powerOf(next, id, data);
    if (next.fallen.contains(id)) {
      powers[id] = value;
      continue;
    }
    value += holdingPower * held.values.where((h) => h == id).length;
    if (isMainClan(id, data) && !next.helped.contains(id)) {
      final floor = max(0, data.faction(id)!.startPower - neglectFloor);
      if (value > floor) value = max(floor, value - neglectPower);
    }
    powers[id] = value.clamp(0, maxPower);
  }
  next = next.copyWith(power: {...next.power, ...powers}, helped: const []);

  final changes = <TerritoryChange>[];
  final moved = <String>{};
  // The strongest first.
  final clans = [
    for (final id in data.factions.keys)
      if (isMainClan(id, data)) id,
  ]..sort((a, b) => powerOf(next, b, data).compareTo(powerOf(next, a, data)));

  bool free(String id) => !moved.contains(id);

  // Claims: a clan risen above where it started reaches for its next one.
  for (final id in clans) {
    if (!free(id)) continue;
    final faction = data.faction(id)!;
    final wanted = [
      if (next.fallen.contains(id) && faction.seat.isNotEmpty) faction.seat,
      ...faction.claims,
    ];
    final mine = placesOf(id, geography, next).toSet();
    final heldClaims = wanted.where(mine.contains).length;
    if (heldClaims >= claimsAllowed(next, id, data)) continue;
    for (final placeId in wanted) {
      if (mine.contains(placeId) || geography.place(placeId) == null) continue;
      final holder = holdings(geography, next)[placeId] ?? '';
      if (holder.isNotEmpty &&
          (!free(holder) ||
              powerOf(next, holder, data) >= powerOf(next, id, data))) {
        continue;
      }
      next = givePlace(next, placeId, id,
          cause: 'claim',
          data: data,
          geography: geography,
          chapter: chapter,
          day: day,
          changes: changes);
      moved
        ..add(id)
        ..add(holder);
      break;
    }
  }

  // Wars: the stronger takes a place, its claims first, the seat last.
  for (final id in clans) {
    if (!free(id)) continue;
    for (final other in clans) {
      if (other == id || !free(other)) continue;
      final step = next.relationStep(id, other, data);
      if (step == null || step > warStep) continue;
      if (powerOf(next, id, data) - powerOf(next, other, data) < warLead) {
        continue;
      }
      final theirs = placesOf(other, geography, next);
      if (theirs.isEmpty) continue;
      final seat = data.faction(other)?.seat ?? '';
      final claims = data.faction(id)?.claims ?? const [];
      final ordered = [
        ...theirs.where((p) => claims.contains(p) && p != seat),
        ...theirs.where((p) => !claims.contains(p) && p != seat),
        ...theirs.where((p) => p == seat),
      ];
      next = givePlace(next, ordered.first, id,
          cause: 'war',
          data: data,
          geography: geography,
          chapter: chapter,
          day: day,
          changes: changes);
      moved
        ..add(id)
        ..add(other);
      break;
    }
  }
  return (state: next, changes: changes);
}

// --- The news (Narrative's docs/proposals/territory-texts.md, 2a to 2d) ---

String _name(Faction? f, AppLanguage language) => f?.nameFor(language) ?? '';

/// "du Dominion de la Lanterne": the French lines speak of a clan through
/// its `nameOf`, so no article or agreement goes wrong.
String _of(Faction? f, AppLanguage language) => f?.nameOfFor(language) ?? '';

/// The news of a place changing hands: taken by [to] (from no one, from
/// another clan [fromClan] in a [war], or from a minor holder), in
/// [language], one of two ways ([variant]).
String territoryNews(
  AppLanguage language, {
  required String place,
  required Faction? to,
  required Faction? from,
  bool fromClan = false,
  bool war = false,
  int variant = 0,
}) {
  final en = language != AppLanguage.fr;
  final winner = _name(to, language);
  final loser = _name(from, language);
  if (war && from != null) {
    return en
        ? (variant == 0
            ? 'War: $winner took $place from $loser.'
            : '$loser lost $place to $winner, and neither side is pretending '
                'it was an accident.')
        : (variant == 0
            ? 'Guerre\u00a0: $place est aux mains ${_of(to, language)}, au '
                'détriment ${_of(from, language)}.'
            : '$place n’est plus aux mains ${_of(from, language)} mais '
                '${_of(to, language)}, et personne ne fait semblant d’y voir '
                'un accident.');
  }
  if (from != null && !fromClan) {
    return en
        ? '$place has new masters. $winner did not ask.'
        : '$place a de nouveaux maîtres\u00a0: les gens ${_of(to, language)} '
            'n’ont rien demandé à personne.';
  }
  return en
      ? (variant == 0
          ? '$winner hold $place now.'
          : 'The banners over $place have changed: it is $winner’s now.')
      : (variant == 0
          ? '$place est désormais aux mains ${_of(to, language)}.'
          : 'Les bannières ont changé sur $place\u00a0: ce sont celles '
              '${_of(to, language)} désormais.');
}

/// The news of [clan] falling: [winner] took its last place, [seat].
String fallenNews(
  AppLanguage language, {
  required Faction? clan,
  required Faction? winner,
  required String seat,
  int variant = 0,
}) {
  final en = language != AppLanguage.fr;
  final name = _name(clan, language);
  final taker = _name(winner, language);
  return en
      ? (variant == 0
          ? '$name has fallen: $taker holds $seat.'
          : '$seat is $taker’s. $name has no place left to stand.')
      : (variant == 0
          ? 'Chute ${_of(clan, language)}\u00a0: $seat est aux mains '
              '${_of(winner, language)}.'
          : '$seat est aux mains ${_of(winner, language)}. Il ne reste plus '
              'un pouce de terrain aux gens ${_of(clan, language)}.');
}
