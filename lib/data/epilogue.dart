// The epilogue map (wave 18 step 2, item 4): at the ending, who holds each
// big town and its districts, and how the town's holder came to hold it.
//
// - The holders: town_rulers.dart's, as the maps tint them today.
// - How: the latest change of the town, or of one of its districts, to its
//   ruler in the clan log ([StandingLogEntry.how], givePlace's cause): by
//   influence (a district won by influence, or the town by its districts)
//   or by war (any other cause). No such change and the ruler it started
//   with: its seat. A change the capped log dropped reads as war.
// - The line: Narrative's, per town and how
//   (docs/proposals/wave18-step2-text.md §3); Alster stays quiet.
//
// Pure rules; UX draws the map.
import '../l10n/app_locale.dart';
import 'factions.dart';
import 'geography.dart';
import 'throne.dart' show midSentenceName;
import 'town_rulers.dart';

/// The big towns the epilogue names, in the order it names them.
const List<String> epilogueTowns = [
  'saltmouth',
  'ashen_quarter',
  'black_reliquary',
];

/// The seven big towns of the world chart, in the story's order: what the
/// epilogue map (UX) lists, one line each. Only [epilogueTowns] have a line
/// of Narrative's; the others read a short tag for how.
const List<String> epilogueBigTowns = [
  'alster',
  'saltmouth',
  'ashen_quarter',
  'drowned_cloister',
  'black_reliquary',
  'white_anchorage',
  'candlehold',
];

/// How a town's holder came to hold it.
enum EpilogueHow { war, influence, seat, none }

/// A big town at the ending: its holder ('' for none), how, and who holds
/// each of its districts (district id -> clan id, '' for none).
class EpilogueTown {
  const EpilogueTown({
    required this.townId,
    required this.clanId,
    required this.how,
    required this.districts,
    this.name = '',
    this.nameFr = '',
  });

  final String townId;

  /// The town's name, in English and French.
  final String name;
  final String nameFr;
  final String clanId;
  final EpilogueHow how;
  final Map<String, String> districts;
}

/// The causes of givePlace that count as influence.
const Set<String> _byInfluence = {'influence', 'town'};

/// Each of [epilogueTowns] in [geography] at the ending of [politics] (see
/// the file's notes).
List<EpilogueTown> epilogueHoldings(PoliticsState politics, Geography geography,
    {List<String> towns = epilogueTowns}) {
  final now = townRulers(geography, politics, const {});
  final start = townRulers(geography, PoliticsState.empty, const {});
  return [
    for (final townId in towns)
      if (geography.place(townId) != null)
        _town(townId, politics, geography, now, start),
  ];
}

EpilogueTown _town(
  String townId,
  PoliticsState politics,
  Geography geography,
  Map<String, TownRuler> now,
  Map<String, TownRuler> start,
) {
  final clanId = now[townId]?.clanId ?? '';
  final districts = {
    for (final d in geography.childrenOf(townId))
      if (d.level == GeoLevel.district) d.id: now[d.id]?.clanId ?? '',
  };
  final places = {townId, ...districts.keys};
  EpilogueHow how;
  if (clanId.isEmpty) {
    how = EpilogueHow.none;
  } else {
    final last = politics.standingLog.lastWhere(
        (e) =>
            e.cause == 'territory' &&
            e.factionId == clanId &&
            places.contains(e.placeId),
        orElse: () => const StandingLogEntry(chapter: 0, day: 0, cause: ''));
    if (last.cause.isNotEmpty) {
      how = _byInfluence.contains(last.how)
          ? EpilogueHow.influence
          : EpilogueHow.war;
    } else {
      how = (start[townId]?.clanId ?? '') == clanId
          ? EpilogueHow.seat
          : EpilogueHow.war;
    }
  }
  final place = geography.place(townId);
  return EpilogueTown(
      townId: townId,
      clanId: clanId,
      how: how,
      districts: districts,
      name: place?.nameFor(false) ?? townId,
      nameFr: place?.nameFor(true) ?? townId);
}

/// The epilogue's line for [town] in [language] (Narrative's), '' for a
/// town it has none for.
String epilogueLine(EpilogueTown town, ClanData data, AppLanguage language) {
  final fr = language == AppLanguage.fr;
  final faction = data.faction(town.clanId);
  final name = faction?.nameFor(language) ?? town.clanId;
  final mid = midSentenceName(name);
  final plural = faction?.pluralFr ?? false;
  String agree(String one, String many) => plural ? many : one;
  // « à la Veille Grise », « au Pacte des Cendres ».
  final toFr = (faction?.nameToFr ?? '').isNotEmpty
      ? faction!.nameToFr
      : 'à ${midSentenceName(name)}';
  if (town.how == EpilogueHow.none) {
    final place = fr ? town.nameFr : town.name;
    return fr
        ? 'Aucun clan ne tient $place. Elle ne répond à personne.'
        : 'No clan holds $place. It answers to no one.';
  }
  switch ((town.townId, town.how)) {
    case ('saltmouth', EpilogueHow.war):
      return fr
          ? '$name ${agree('a', 'ont')} pris Bouche-de-Sel par la force, un '
              'quai après l’autre.'
          : '$name took Saltmouth by force, one quay at a time.';
    case ('saltmouth', EpilogueHow.influence):
      return fr
          ? '$name ${agree('a', 'ont')} gagné Bouche-de-Sel sans un coup : '
              'dettes, faveurs et patience.'
          : '$name won Saltmouth without a blow: debts, favours, and patience.';
    case ('saltmouth', EpilogueHow.seat):
      return fr
          ? 'Bouche-de-Sel était $toFr dès le début, et l’est restée.'
          : 'Saltmouth was $mid’s from the start, and stayed so.';
    case ('ashen_quarter', EpilogueHow.war):
      return fr
          ? '$name ${agree('a', 'ont')} pris le Quartier des Cendres à même '
              'la cendre.'
          : '$name took the Ashen Quarter from the ash up.';
    case ('ashen_quarter', EpilogueHow.influence):
      return fr
          ? '$name ${agree('a', 'ont')} pris le Quartier des Cendres en étant '
              '${agree('celui', 'ceux')} qui ${agree('est resté', 'sont restés')}.'
          : '$name took the Ashen Quarter by being the one who stayed.';
    case ('ashen_quarter', EpilogueHow.seat):
      return fr
          ? 'Le Quartier des Cendres était $toFr, qui l’${agree('a', 'ont')} '
              'gardé.'
          : 'The Ashen Quarter was $mid’s own, and it kept it.';
    case ('black_reliquary', EpilogueHow.war):
      return fr
          ? '$name ${agree('a', 'ont')} pris le Reliquaire rue gelée après rue '
              'gelée.'
          : '$name took the Reliquary street by frozen street.';
    case ('black_reliquary', EpilogueHow.influence):
      return fr
          ? '$name ${agree('a', 'ont')} tenu le Reliquaire, parce que les morts '
              'ne se fiaient à nul autre.'
          : '$name held the Reliquary because the dead would trust no one '
              'else.';
    case ('black_reliquary', EpilogueHow.seat):
      return fr
          ? 'Le Reliquaire était $toFr avant la déchirure, et la déchirure n’y '
              'a rien changé.'
          : 'The Reliquary was $mid’s before the tear, and the tear did not '
              'change that.';
  }
  return '';
}
