// Towns tinted by the clan that rules them (wave 15, docs/proposals/
// town-ruler-colours.md): which clan rules each town and each of its
// districts now, and that clan's colours, for the maps to tint.
//
// - A town: a location of kind city, town or village, or any place with a
//   city plan (city_plans.json: that adds the cove camp).
// - Its ruler: the live holder (clan_power.dart's holderOf: its own, as
//   politics changed it, or the nearest up the chain). A town with no
//   holder takes the clan holding most of its districts; a tie, or none,
//   is neutral.
// - A district of a town: its own holder, else its town's (holderOf).
// - The colours: the clan's `color` in factions.json (the colour every
//   clan card and the chart's seats already draw), and [accent], the same
//   darkened for a border. A place no one rules takes [townNeutralColor].
//
// Pure rules; townRulersProvider (town_rulers_provider.dart) keeps it up
// to date with the politics.
import 'clan_power.dart';
import 'factions.dart';
import 'geography.dart';

/// The location kinds that count as a town.
const Set<String> _townKinds = {'city', 'town', 'village'};

/// The tint of a place no one rules (ARGB): a dull warm grey.
const int townNeutralColor = 0xFF7C766B;

/// How much darker the border of a tint is than its fill (0..1).
const double _townAccentShade = 0.35;

/// Why a place has the ruler it has.
enum TownRulerSource {
  /// A holder written on the place itself (geography.json or politics'
  /// `control`).
  own,

  /// The holder of a place above it (a district takes its town's).
  above,

  /// A town with no holder: the clan that holds most of its districts.
  districts,

  /// No one: neutral.
  none,
}

/// Who rules a town or one of its districts, and in what colours.
class TownRuler {
  const TownRuler({
    required this.placeId,
    required this.cityId,
    required this.clanId,
    required this.source,
    required this.color,
    required this.accent,
    this.isDistrict = false,
    this.mixed = false,
  });

  /// The town's or district's geography id.
  final String placeId;

  /// The town it belongs to: itself for a town.
  final String cityId;

  /// A district of [cityId], not the town itself.
  final bool isDistrict;

  /// The ruling faction's id (factions.json); '' for neutral.
  final String clanId;
  final TownRulerSource source;

  /// The fill (ARGB): the clan's colour, or [townNeutralColor].
  final int color;

  /// The border (ARGB): [color] darkened by [_townAccentShade].
  final int accent;

  /// A town only: one of its districts has another ruler than it.
  final bool mixed;

  bool get isNeutral => clanId.isEmpty;

  @override
  String toString() =>
      'TownRuler($placeId: ${clanId.isEmpty ? 'neutral' : clanId}, '
      '${source.name}${isDistrict ? ', district of $cityId' : ''}'
      '${mixed ? ', mixed' : ''})';
}

/// [argb] darkened by [shade] (0: unchanged, 1: black), alpha kept.
int shadeColor(int argb, [double shade = _townAccentShade]) {
  int channel(int shift) =>
      (((argb >> shift) & 0xFF) * (1 - shade)).round().clamp(0, 255);
  return (argb & 0xFF000000) |
      (channel(16) << 16) |
      (channel(8) << 8) |
      channel(0);
}

/// The fill of [clanId]'s towns: its factions.json colour, or
/// [townNeutralColor] for '' or a faction that doesn't exist.
int townColorOf(String clanId, Map<String, Faction> factions) => clanId.isEmpty
    ? townNeutralColor
    : factions[clanId]?.color ?? townNeutralColor;

/// The towns of [geography], in its order: the locations of a [_townKinds]
/// kind and the places with a city plan ([planIds]).
List<String> townIds(Geography geography,
    {Iterable<String> planIds = const []}) {
  final plans = planIds.toSet();
  return [
    for (final place in geography.places.values)
      if ((place.level == GeoLevel.location &&
              _townKinds.contains(place.kind)) ||
          plans.contains(place.id))
        place.id,
  ];
}

/// Who rules each town and each district of a town now (place id ->
/// [TownRuler]), towns in the geography's order, each followed by its
/// districts. [planIds]: the ids of city_plans.json.
Map<String, TownRuler> townRulers(
  Geography geography,
  PoliticsState politics,
  Map<String, Faction> factions, {
  Iterable<String> planIds = const [],
}) {
  final own = holdings(geography, politics);
  TownRuler ruler(
      String placeId, String cityId, String clanId, TownRulerSource source,
      {bool isDistrict = false, bool mixed = false}) {
    final color = townColorOf(clanId, factions);
    return TownRuler(
      placeId: placeId,
      cityId: cityId,
      clanId: clanId,
      source: clanId.isEmpty ? TownRulerSource.none : source,
      color: color,
      accent: shadeColor(color),
      isDistrict: isDistrict,
      mixed: mixed,
    );
  }

  final result = <String, TownRuler>{};
  for (final townId in townIds(geography, planIds: planIds)) {
    final districts = [
      for (final child in geography.childrenOf(townId))
        if (child.level == GeoLevel.district) child.id,
    ];
    var clanId = holderOf(townId, geography, politics);
    var source =
        own.containsKey(townId) ? TownRulerSource.own : TownRulerSource.above;
    if (clanId.isEmpty) {
      clanId = _mostHeld([for (final d in districts) own[d] ?? '']);
      source = TownRulerSource.districts;
    }
    final districtRulers = [
      for (final d in districts)
        ruler(
          d,
          townId,
          holderOf(d, geography, politics),
          own.containsKey(d) ? TownRulerSource.own : TownRulerSource.above,
          isDistrict: true,
        ),
    ];
    result[townId] = ruler(townId, townId, clanId, source,
        mixed: districtRulers.any((d) => d.clanId != clanId));
    for (final d in districtRulers) {
      result[d.placeId] = d;
    }
  }
  return result;
}

/// The clan that holds the most of [holders] ('' none), '' on a tie.
String _mostHeld(List<String> holders) {
  final counts = <String, int>{};
  for (final h in holders) {
    if (h.isNotEmpty) counts[h] = (counts[h] ?? 0) + 1;
  }
  if (counts.isEmpty) return '';
  final best = counts.values.reduce((a, b) => a > b ? a : b);
  final leaders = [
    for (final e in counts.entries)
      if (e.value == best) e.key,
  ];
  return leaders.length == 1 ? leaders.single : '';
}
