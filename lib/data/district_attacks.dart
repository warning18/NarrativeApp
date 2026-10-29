// Attacks by rival clans (wave 18 step 2, item 1;
// docs/proposals/wave18-step2.md): at a chapter's territory turn a rival
// may attack a district it doesn't hold, and the district is under siege.
//
// - Who attacks: a main clan with [attackMinPower] power or more, against
//   a district held by a clan it is at odds with: a blood feud
//   ([attackOdds]: 35% a chapter), a war (20%) or hostile (10%); tense or
//   warmer, never. At most one attack a town a chapter, and none while the
//   town is under siege.
// - The siege lasts [siegeDays] days ([PoliticsState.sieges]), with its
//   flags set ([attackFlag], [attackByFlag]).
// - In the town: on a road at rest into or out of it, the defence scene
//   ([buildSiegeNode]): fight the attacker's hunter for the holder, join
//   the attackers (the district falls to them), or stand aside (the siege
//   runs its course). Each ends with its flag ([siegeOutcomeFlag]).
// - Elsewhere, or stood aside: when the siege runs out, it is settled on
//   power and influence ([attackerWinChance], kept between
//   [attackOddsFloor] and [attackOddsCeiling]) and arrives as news. A won
//   attack gives the district (givePlace, cause 'war'), with war's spoils
//   and losses ([warSpoils], [warLoss]).
//
// Pure rules; the session (a chapter reached, a road) and the playthrough
// simulator play them.
import 'dart:math';

import '../l10n/app_locale.dart';
import '../models/story_node.dart';
import 'clan_power.dart';
import 'district_influence.dart' show influenceIn;
import 'factions.dart';
import 'geography.dart';
import 'rival_hunters.dart' show rivalHunterPool;

/// A clan's chance a chapter to attack a district held by a clan at
/// [relation step](PoliticsState.relationStep): 1 a blood feud, 2 a war,
/// 3 hostile.
const Map<int, double> attackOdds = {1: 0.35, 2: 0.20, 3: 0.10};

/// The least power a clan attacks with.
const int attackMinPower = 10;

/// How long a siege lasts, in days.
const int siegeDays = 2;

/// The attacker's chance to take a district it besieges, settled away
/// from the party, is kept between these.
const double attackOddsFloor = 0.15;
const double attackOddsCeiling = 0.85;

/// The flag of a district under siege, and of who besieges it.
String attackFlag(String districtId) => 'attack_$districtId';
String attackByFlag(String districtId, String clanId) =>
    'attack_${districtId}_by_$clanId';

/// The flag a siege ends with in the party's hands: 'defended', 'joined'
/// or 'ignored'.
String siegeOutcomeFlag(String districtId, String how) =>
    'attack_${districtId}_$how';

/// The siege of a district: who attacks, who holds, the town, and the day
/// it runs out.
class DistrictSiege {
  const DistrictSiege({
    required this.districtId,
    required this.attacker,
    required this.holder,
    required this.cityId,
    required this.until,
    this.met = false,
  });

  final String districtId;
  final String attacker;
  final String holder;
  final String cityId;
  final int until;

  /// The party met it and stood aside: it runs its course.
  final bool met;

  Map<String, String> toEntry() => {
        'attacker': attacker,
        'holder': holder,
        'city': cityId,
        'until': '$until',
        if (met) 'met': '1',
      };

  static DistrictSiege? fromEntry(String districtId, Map<String, String> e) {
    final attacker = e['attacker'] ?? '';
    if (attacker.isEmpty) return null;
    return DistrictSiege(
      districtId: districtId,
      attacker: attacker,
      holder: e['holder'] ?? '',
      cityId: e['city'] ?? '',
      until: int.tryParse(e['until'] ?? '') ?? 0,
      met: e['met'] == '1',
    );
  }
}

/// The sieges under way in [state].
List<DistrictSiege> siegesOf(PoliticsState state) => [
      for (final e in state.sieges.entries)
        if (DistrictSiege.fromEntry(e.key, e.value) case final siege?) siege,
    ];

/// The town [districtId] stands in, or ''.
String _cityOf(Geography geography, String districtId) =>
    geography.locationOf(districtId)?.id ?? '';

/// A chapter's attacks: for each town with districts held by a clan of
/// their own, the clans that may attack one (see the file's head), tried
/// in order of their odds (the worst relation first), at most one a town;
/// each attack starts a siege until [day] + [siegeDays]. Returns the state
/// with the sieges and the sieges begun.
({PoliticsState state, List<DistrictSiege> begun}) rollDistrictAttacks(
  PoliticsState state, {
  required ClanData data,
  required Geography geography,
  required int day,
  required Random random,
  int chapter = 0,
}) {
  final held = holdings(geography, state);
  final besieged = {for (final s in siegesOf(state)) s.cityId};
  // town -> (district, attacker, holder, odds), in the geography's order.
  final candidates = <String,
      List<({String district, String attacker, String holder, double odds})>>{};
  for (final MapEntry(key: placeId, value: holder) in held.entries) {
    final place = geography.place(placeId);
    if (place == null || place.level != GeoLevel.district) continue;
    final city = _cityOf(geography, placeId);
    if (city.isEmpty || besieged.contains(city)) continue;
    for (final clan in data.factions.keys) {
      if (clan == holder || !isMainClan(clan, data)) continue;
      if (state.fallen.contains(clan)) continue;
      if (powerOf(state, clan, data) < attackMinPower) continue;
      final step = state.relationStep(clan, holder, data);
      final odds = step == null ? null : attackOdds[step];
      if (odds == null) continue;
      (candidates[city] ??= []).add((
        district: placeId,
        attacker: clan,
        holder: holder,
        odds: odds,
      ));
    }
  }
  var next = state;
  final begun = <DistrictSiege>[];
  for (final MapEntry(key: city, value: list) in candidates.entries) {
    list.sort((a, b) {
      final byOdds = b.odds.compareTo(a.odds);
      if (byOdds != 0) return byOdds;
      final byDistrict = a.district.compareTo(b.district);
      return byDistrict != 0 ? byDistrict : a.attacker.compareTo(b.attacker);
    });
    for (final c in list) {
      if (random.nextDouble() >= c.odds) continue;
      final siege = DistrictSiege(
        districtId: c.district,
        attacker: c.attacker,
        holder: c.holder,
        cityId: city,
        until: day + siegeDays,
      );
      final place = geography.place(c.district)!;
      String told(AppLanguage language) => siegeBegunNews(
            language,
            district: place.nameFor(language == AppLanguage.fr),
            attacker: data.faction(c.attacker),
            holder: data.faction(c.holder),
          );
      next = next.copyWith(
        sieges: {...next.sieges, c.district: siege.toEntry()},
        news: [
          ...next.news,
          CoastNews(
            eventId: 'siege:${c.district}',
            chapter: chapter,
            day: day,
            text: told(AppLanguage.en),
            textFr: told(AppLanguage.fr),
          ),
        ],
      );
      begun.add(siege);
      break;
    }
  }
  return (state: next, begun: begun);
}

/// [state] with [districtId]'s siege lifted (settled one way or another).
PoliticsState clearSiege(PoliticsState state, String districtId) =>
    state.sieges.containsKey(districtId)
        ? state.copyWith(sieges: {...state.sieges}..remove(districtId))
        : state;

/// [state] after a siege scene's choice ([StoryPolitics.settleSiege]): the
/// district's siege lifted, or, for `<district>:aside`, marked met (it runs
/// its course and is settled when it runs out).
PoliticsState applySiegeChoice(PoliticsState state, String settle) {
  if (!settle.endsWith(asideSuffix)) return clearSiege(state, settle);
  final districtId = settle.substring(0, settle.length - asideSuffix.length);
  final entry = state.sieges[districtId];
  if (entry == null) return state;
  return state.copyWith(
    sieges: {
      ...state.sieges,
      districtId: {...entry, 'met': '1'},
    },
  );
}

/// What a Stand aside choice's [StoryPolitics.settleSiege] ends with.
const String asideSuffix = ':aside';

/// The attacker's chance to take the district of [siege] away from the
/// party: even, moved by the two clans' power and their influence there,
/// kept between [attackOddsFloor] and [attackOddsCeiling].
double attackerWinChance(
  PoliticsState state,
  DistrictSiege siege, {
  required ClanData data,
  required Geography geography,
}) {
  final power =
      powerOf(state, siege.attacker, data) - powerOf(state, siege.holder, data);
  final influence =
      influenceIn(state, geography, siege.districtId, siege.attacker) -
          influenceIn(state, geography, siege.districtId, siege.holder);
  return (0.5 + power / 100 + influence / 200).clamp(
    attackOddsFloor,
    attackOddsCeiling,
  );
}

/// [state] with [siege] settled away from the party (it ran out, or the
/// party stood aside): taken by the attacker with [attackerWinChance]
/// (givePlace, cause 'war', with war's spoils and losses), else held; the
/// news told either way, the siege lifted.
PoliticsState settleSiegeAway(
  PoliticsState state,
  DistrictSiege siege, {
  required ClanData data,
  required Geography geography,
  required Random random,
  int chapter = 0,
  int day = 0,
  List<TerritoryChange>? changes,
}) {
  var next = clearSiege(state, siege.districtId);
  final place = geography.place(siege.districtId);
  if (place == null) return next;
  // The holder may have changed since (an event, influence): the siege is
  // over with nothing to take.
  if (holderOf(siege.districtId, geography, next) != siege.holder) {
    return next;
  }
  final won = random.nextDouble() <
      attackerWinChance(next, siege, data: data, geography: geography);
  if (won) {
    next = givePlace(
      next,
      siege.districtId,
      siege.attacker,
      cause: 'war',
      data: data,
      geography: geography,
      chapter: chapter,
      day: day,
      changes: changes,
    );
    // War's news, in the siege's words.
    final last = next.news.lastOrNull;
    if (last != null && last.eventId == 'territory:${siege.districtId}') {
      String told(AppLanguage language) => siegeTakenNews(
            language,
            district: place.nameFor(language == AppLanguage.fr),
            attacker: data.faction(siege.attacker),
            holder: data.faction(siege.holder),
          );
      next = next.copyWith(
        news: [
          ...next.news.take(next.news.length - 1),
          CoastNews(
            eventId: last.eventId,
            chapter: last.chapter,
            day: last.day,
            text: told(AppLanguage.en),
            textFr: told(AppLanguage.fr),
          ),
        ],
      );
    }
    next = addPower(next, siege.attacker, warSpoils, data);
    if (!next.fallen.contains(siege.holder)) {
      next = addPower(next, siege.holder, -warLoss, data);
    }
    return next;
  }
  String told(AppLanguage language) => siegeHeldNews(
        language,
        district: place.nameFor(language == AppLanguage.fr),
        holder: data.faction(siege.holder),
        attacker: data.faction(siege.attacker),
      );
  return next.copyWith(
    news: [
      ...next.news,
      CoastNews(
        eventId: 'siege:${siege.districtId}',
        chapter: chapter,
        day: day,
        text: told(AppLanguage.en),
        textFr: told(AppLanguage.fr),
      ),
    ],
  );
}

/// The sieges of [state] run out by [day] (their last day gone).
List<DistrictSiege> expiredSieges(PoliticsState state, int day) => [
      for (final siege in siegesOf(state))
        if (day > siege.until) siege,
    ];

String _name(ClanData data, String id, bool fr) =>
    data.faction(id)?.nameFor(fr ? AppLanguage.fr : AppLanguage.en) ?? id;

/// The defence scene for [siege], met in its town: Defend (a fight with
/// the attacker's hunter, [enemies] for [chapter]: the siege broken),
/// Join the attackers (the district falls to them) or Stand aside (the
/// siege runs its course, settled when it runs out). Null when the
/// district is gone from [geography].
StoryNode? buildSiegeNode(
  PoliticsState state,
  DistrictSiege siege, {
  required ClanData data,
  required Geography geography,
  required Map<String, dynamic> enemies,
  required int chapter,
  required Random random,
}) {
  final place = geography.place(siege.districtId);
  if (place == null) return null;
  String fill(String line, bool fr) => line
      .replaceAll('{holder}', _name(data, siege.holder, fr))
      .replaceAll('{attacker}', _name(data, siege.attacker, fr))
      .replaceAll('{district}', place.nameFor(fr));
  final pool = rivalHunterPool(
    enemies: enemies,
    clanId: siege.attacker,
    chapter: max(chapter, 3),
  );
  final defender = pool.isEmpty ? null : pool[random.nextInt(pool.length)];
  final d = siege.districtId;
  return StoryNode(
    id: '$siegeNodePrefix${d}_${random.nextInt(1 << 30)}',
    description: fill(_siegeBodyEn, false),
    descriptionFr: fill(_siegeBodyFr, true),
    contextNote: fill(_siegeTitleEn, false),
    contextNoteFr: fill(_siegeTitleFr, true),
    choices: [
      if (defender != null)
        StoryChoice(
          text: fill('Defend {district}', false),
          textFr: fill('Défendre {district}', true),
          nextId: '',
          triggerEnemyId: defender,
          politics: StoryPolitics(
            standing: {siege.holder: siegeDefendStanding},
            power: {siege.attacker: -siegeDefendAttackerPower},
            flags: [siegeOutcomeFlag(d, 'defended')],
            settleSiege: d,
          ),
        ),
      StoryChoice(
        text: fill('Join {attacker}', false),
        textFr: fill('Rejoindre {attacker}', true),
        nextId: '',
        politics: StoryPolitics(
          standing: {
            siege.attacker: siegeJoinStanding,
            siege.holder: -siegeJoinStanding,
          },
          control: {d: siege.attacker},
          flags: [siegeOutcomeFlag(d, 'joined')],
          settleSiege: d,
        ),
      ),
      StoryChoice(
        text: 'Stand aside',
        textFr: 'Rester à l’écart',
        nextId: '',
        politics: StoryPolitics(
          flags: [siegeOutcomeFlag(d, 'ignored')],
          settleSiege: '$d$asideSuffix',
        ),
      ),
    ],
  );
}

/// The id prefix of the siege scenes, whose politics the story player
/// applies though they are met on a road.
const String siegeNodePrefix = 'district_siege_';
bool isSiegeNode(String? nodeId) =>
    nodeId?.startsWith(siegeNodePrefix) ?? false;

/// What holding a district against its attackers moves: the holder's
/// standing up, the attacker's power down.
const int siegeDefendStanding = 5;
const int siegeDefendAttackerPower = 5;

/// What joining the attackers moves: their standing up, the holder's down.
const int siegeJoinStanding = 5;

/// The siege of the party's town to meet on a road at rest: one whose
/// town [fromCity] or [toCity] is, not yet stood aside from.
DistrictSiege? siegeToMeet(
  PoliticsState state, {
  required String fromCity,
  required String toCity,
}) {
  for (final siege in siegesOf(state)) {
    if (siege.cityId.isEmpty || siege.met) continue;
    if (siege.cityId != fromCity && siege.cityId != toCity) continue;
    return siege;
  }
  return null;
}

String _clan(Faction? f, AppLanguage language, String en, String fr) =>
    f?.nameFor(language) ?? (language == AppLanguage.fr ? fr : en);

/// [one] or [many], as the French name of [f] is singular or plural.
String _agree(Faction? f, String one, String many) =>
    (f?.pluralFr ?? false) ? many : one;

/// "à la Veille Grise" (its `nameTo_fr`), else "à" and the name.
String _toFr(Faction? f, String fallback) {
  final to = f?.nameToFr ?? '';
  return to.isNotEmpty ? to : 'à ${f?.nameFor(AppLanguage.fr) ?? fallback}';
}

/// The news of a siege begun (Narrative's `district_attack_news`).
String siegeBegunNews(
  AppLanguage language, {
  required String district,
  Faction? attacker,
  Faction? holder,
}) {
  final a = _clan(attacker, language, 'The attackers', 'Les assaillants');
  final h = _clan(holder, language, 'Its people', 'Ses gens');
  return language == AppLanguage.fr
      ? '$a ${_agree(attacker, 'marche', 'marchent')} sur $district. '
          '$h ${_agree(holder, 'a', 'ont')} deux jours.'
      : '$a marches on $district. $h has two days.';
}

/// The news of a district taken by its besiegers (Narrative's
/// `district_attack_won`).
String siegeTakenNews(
  AppLanguage language, {
  required String district,
  Faction? attacker,
  Faction? holder,
}) {
  final a = _clan(attacker, language, 'The attackers', 'Les assaillants');
  return language == AppLanguage.fr
      ? '$a ${_agree(attacker, 'a', 'ont')} pris $district '
          '${_toFr(holder, 'ses gens')}.'
      : '$a took $district from ${_clan(holder, language, 'its people', '')}.';
}

/// The news of a siege the holder broke (Narrative's
/// `district_attack_held`).
String siegeHeldNews(
  AppLanguage language, {
  required String district,
  Faction? holder,
  Faction? attacker,
}) {
  final a = _clan(attacker, language, 'The attackers', 'Les assaillants');
  return language == AppLanguage.fr
      ? '$district a tenu bon. $a ${_agree(attacker, 'a', 'ont')} rebroussé '
          'chemin.'
      : '$district held. $a turned back.';
}

// --- Words for Narrative to reword (wave 18 step 2) ------------------------

const String _siegeTitleEn = 'Siege of {district}.';
const String _siegeTitleFr = 'Siège de {district}.';
const String _siegeBodyEn =
    'Smoke over the roofs. The gate bar is down. {attacker} against '
    '{holder}: the assault on {district} has begun. Nobody asks which side '
    'you are on. Everyone is watching.';
const String _siegeBodyFr =
    'De la fumée sur les toits. La barre de la porte est baissée. '
    '{attacker} contre {holder}\u00a0: l’assaut sur {district} a commencé. '
    'Personne ne vous demande votre camp. Tout le monde guette.';

/// [flags] with the siege flags in step with [state]'s sieges: each siege's
/// [attackFlag] and [attackByFlag] set, those of a siege that is over
/// dropped (its outcome flags stay). [flags] itself when nothing moved.
List<String> syncSiegeFlags(List<String> flags, PoliticsState state) {
  final live = <String>{
    for (final siege in siegesOf(state)) ...[
      attackFlag(siege.districtId),
      attackByFlag(siege.districtId, siege.attacker),
    ],
  };
  bool isSiegeFlag(String flag) =>
      flag.startsWith('attack_') &&
      !flag.endsWith('_defended') &&
      !flag.endsWith('_joined') &&
      !flag.endsWith('_ignored');
  final kept = [
    for (final flag in flags)
      if (!isSiegeFlag(flag) || live.contains(flag)) flag,
  ];
  final missing = [
    for (final flag in live)
      if (!kept.contains(flag)) flag,
  ];
  if (missing.isEmpty && kept.length == flags.length) return flags;
  return [...kept, ...missing];
}
