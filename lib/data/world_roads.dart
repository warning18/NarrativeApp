// The world's fixed roads (v1.246): the map is fixed, so the party goes from
// one landmark to the next only along a road, and every road passes named
// stops (a bridge, a gate, a ford) the Journey map can name as it goes by.
// Roads join landmarks by id, not by position, so they hold on every chart
// geography (see map_charts.dart), each of which routes the line between its
// own landmark positions.
import '../l10n/app_locale.dart';

/// How a road is travelled.
enum RoadKind { land, sea }

/// A named place along a road, between its two landmarks.
class RoadStop {
  const RoadStop(this.id, this.nameEn, this.nameFr);

  final String id;
  final String nameEn;
  final String nameFr;

  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
}

/// A road between two landmarks, with its stops in order from [a] to [b].
class WorldRoad {
  const WorldRoad(this.id, this.a, this.b, this.stops,
      {this.kind = RoadKind.land});

  final String id;

  /// The landmark ids at the two ends.
  final String a;
  final String b;
  final RoadKind kind;

  /// The stops passed, in order from [a] to [b].
  final List<RoadStop> stops;

  /// The landmark at the other end from [landmarkId].
  String other(String landmarkId) => landmarkId == a ? b : a;

  /// Whether [landmarkId] is one of the ends.
  bool joins(String landmarkId) => landmarkId == a || landmarkId == b;

  /// The stops in the order met when walking from [landmarkId].
  List<RoadStop> stopsFrom(String landmarkId) =>
      landmarkId == a ? stops : stops.reversed.toList();
}

/// One stretch of a route: [road] walked from landmark [from] to [to].
class RouteLeg {
  const RouteLeg(this.road, this.from, this.to);

  final WorldRoad road;
  final String from;
  final String to;

  /// The stops of this leg, in the order met.
  List<RoadStop> get stops => road.stopsFrom(from);
}

/// The way along the roads from one landmark to another.
class RoadRoute {
  const RoadRoute(this.legs);

  final List<RouteLeg> legs;

  /// Every landmark passed, the first and last included.
  List<String> get places =>
      legs.isEmpty ? const [] : [legs.first.from, for (final l in legs) l.to];

  /// Every stop met on the way, in order, leaving out the landmarks.
  List<RoadStop> get stops => [for (final l in legs) ...l.stops];

  bool get isEmpty => legs.isEmpty;
}

const _tallowSteps =
    RoadStop('tallow_steps', 'Tallow Steps', 'Les marches du Suif');
const _cobblersRow =
    RoadStop('cobblers_row', 'Cobblers’ Row', 'La rue des Cordonniers');
const _dyersGate =
    RoadStop('dyers_gate', 'The Dyers’ Gate', 'La porte des Teinturiers');
const _menderStall =
    RoadStop('mender_stall', 'The Mender’s Stall', 'L’étal du Rapetasseur');
const _wardensLane =
    RoadStop('wardens_lane', 'The Warden’s Lane', 'La ruelle du Gardien');
const _ironGrate = RoadStop('iron_grate', 'The Iron Grate', 'La grille de fer');
const _cisternSteps =
    RoadStop('cistern_steps', 'The Cistern Steps', 'Les marches de la citerne');
const _fishmarket = RoadStop('fishmarket', 'The Fishmarket', 'La criée');
const _chandlersRow =
    RoadStop('chandlers_row', 'Chandlers’ Row', 'La rue des Chandeliers');
const _harbourChain =
    RoadStop('harbour_chain', 'The Harbour Chain', 'La chaîne du port');
const _paintedSails =
    RoadStop('painted_sails', 'The Painted Sails', 'Les voiles peintes');
const _duneCairn =
    RoadStop('dune_cairn', 'The Dune Cairn', 'Le cairn des dunes');
const _dryWadi = RoadStop('dry_wadi', 'The Dry Wadi', 'L’oued à sec');
const _caravanFord =
    RoadStop('caravan_ford', 'The Caravan Ford', 'Le gué des caravanes');
const _saltMarker =
    RoadStop('salt_marker', 'The Salt Marker', 'La borne de sel');
const _tollhouse = RoadStop('tollhouse', 'The Tollhouse', 'Le poste de péage');
const _tideWall = RoadStop('tide_wall', 'The Tide Wall', 'Le mur de marée');
const _ropewalk = RoadStop('ropewalk', 'The Ropewalk', 'La corderie');
const _breakersStair = RoadStop(
    'breakers_stair', 'The Breakers’ Stair', 'L’escalier des démolisseurs');
const _lastLight = RoadStop('last_light', 'The Last Light', 'Le dernier feu');
const _openWater = RoadStop('open_water', 'The Open Water', 'Le large');
const _landfallRock =
    RoadStop('landfall_rock', 'Landfall Rock', 'Le rocher de l’arrivée');
const _coveSteps =
    RoadStop('cove_steps', 'The Cove Path', 'Le sentier de la crique');
const _ashGate = RoadStop('ash_gate', 'The Ash Gate', 'La porte des Cendres');
const _cinderRoad =
    RoadStop('cinder_road', 'The Cinder Road', 'La route des braises');
const _cloisterRoofs =
    RoadStop('cloister_roofs', 'The Cloister Roofs', 'Les toits du cloître');
const _smugglersTrail = RoadStop(
    'smugglers_trail', 'The Smugglers’ Trail', 'Le sentier des contrebandiers');
const _dryWeir = RoadStop('dry_weir', 'The Dry Weir', 'Le déversoir à sec');
const _redGate = RoadStop('red_gate', 'The Red Gate', 'La porte rouge');
const _greySands = RoadStop('grey_sands', 'The Grey Sands', 'Les sables gris');
const _musterField =
    RoadStop('muster_field', 'The Muster Field', 'Le champ de rassemblement');
const _inkedSteps =
    RoadStop('inked_steps', 'The Inked Steps', 'Les marches d’encre');
const _hillTrack =
    RoadStop('hill_track', 'The Hill Track', 'Le chemin de la colline');
const _drownedCauseway =
    RoadStop('drowned_causeway', 'The Drowned Causeway', 'La chaussée noyée');
const _tideFlats = RoadStop('tide_flats', 'The Tide Flats', 'Les vasières');
const _silentBell =
    RoadStop('silent_bell', 'The Silent Bell', 'La cloche muette');
const _pilgrimsMile =
    RoadStop('pilgrims_mile', 'The Pilgrims’ Mile', 'Le mille des pèlerins');
const _tearStair =
    RoadStop('tear_stair', 'The Tear Stair', 'L’escalier de la déchirure');
const _longWayBack =
    RoadStop('long_way_back', 'The Long Way Back', 'Le long retour');
const _frostPass = RoadStop('frost_pass', 'The Frost Pass', 'Le col du givre');
const _giantsStair =
    RoadStop('giants_stair', 'The Giants’ Stair', 'L’escalier des géants');
const _mootRoad = RoadStop('moot_road', 'The Moot Road', 'La route du Moot');
const _whiteQuay = RoadStop('white_quay', 'The White Quay', 'Le quai blanc');
const _hollowBeach =
    RoadStop('hollow_beach', 'The Hollow Beach', 'La plage creuse');
const _glassShoals =
    RoadStop('glass_shoals', 'The Glass Shoals', 'Les hauts-fonds de verre');
const _hullsReach =
    RoadStop('hulls_reach', 'The Hulls’ Reach', 'Le chenal des coques');
const _lanternCrossing = RoadStop(
    'lantern_crossing', 'The Lantern Crossing', 'La traversée de la Lanterne');
const _lastMile = RoadStop('last_mile', 'The Last Mile', 'Le dernier mille');

/// Every road of the world. Each branch of the story that moves the party
/// from one landmark to another follows one of these (the content test
/// `world_roads_test.dart` keeps it so), and every landmark is on a road
/// that leads to every other.
const List<WorldRoad> worldRoads = [
  // Alster: the slums, the quay, and the way out through the Waste.
  WorldRoad('beggar_alley', 'beggar', 'alley', [_tallowSteps]),
  WorldRoad('beggar_bridge', 'beggar', 'bridge', [_cobblersRow]),
  WorldRoad('alley_hovel', 'alley', 'hovel', [_dyersGate]),
  WorldRoad('bridge_hovel', 'bridge', 'hovel', [_menderStall]),
  WorldRoad('hovel_hold', 'hovel', 'hold', [_wardensLane]),
  WorldRoad('hold_sewers', 'hold', 'sewers', [_ironGrate]),
  WorldRoad('sewers_hovel', 'sewers', 'hovel', [_cisternSteps]),
  WorldRoad('hovel_docks', 'hovel', 'docks', [_fishmarket, _chandlersRow]),
  WorldRoad('docks_crash', 'docks', 'crash', [_harbourChain, _paintedSails],
      kind: RoadKind.sea),
  WorldRoad('crash_sleeper', 'crash', 'sleeper', [_duneCairn]),
  WorldRoad('sleeper_wells', 'sleeper', 'wells', [_dryWadi]),
  WorldRoad('wells_upper', 'wells', 'upper', [_caravanFord, _saltMarker]),
  // Saltmouth and the crossing.
  WorldRoad('upper_wharf', 'upper', 'wharf', [_tollhouse, _tideWall]),
  WorldRoad('wharf_tern', 'wharf', 'tern', [_ropewalk]),
  WorldRoad('wharf_berths', 'wharf', 'berths', [_breakersStair]),
  WorldRoad('berths_storm', 'berths', 'storm', [_lastLight],
      kind: RoadKind.sea),
  WorldRoad('storm_camp', 'storm', 'camp', [_openWater, _landfallRock],
      kind: RoadKind.sea),
  // The Ashen Coast, from the camp.
  WorldRoad('camp_quarter', 'camp', 'quarter', [_coveSteps, _ashGate]),
  WorldRoad('quarter_emberwick', 'quarter', 'emberwick', [_cinderRoad]),
  WorldRoad('emberwick_spire', 'emberwick', 'spire', [_cloisterRoofs]),
  WorldRoad('camp_spire', 'camp', 'spire', [_smugglersTrail, _dryWeir]),
  WorldRoad('quarter_akagiri', 'quarter', 'akagiri', [_redGate]),
  WorldRoad('akagiri_shore', 'akagiri', 'shore', [_greySands]),
  WorldRoad('camp_battle', 'camp', 'battle', [_musterField]),
  WorldRoad('battle_shore', 'battle', 'shore', [_lastMile]),
  // The south: the hill, the drowned cloister, the Hollow Court.
  WorldRoad('camp_court', 'camp', 'court', [_inkedSteps]),
  WorldRoad('camp_kindly', 'camp', 'kindly', [_hillTrack]),
  WorldRoad('kindly_cloister', 'kindly', 'cloister', [_drownedCauseway]),
  WorldRoad('cloister_wrack', 'cloister', 'wrack', [_tideFlats]),
  WorldRoad('cloister_court', 'cloister', 'court', [_silentBell]),
  // The north: the Reliquary and the giants' country.
  WorldRoad('camp_reliquary', 'camp', 'reliquary', [_pilgrimsMile]),
  WorldRoad('reliquary_heart', 'reliquary', 'heart', [_tearStair]),
  WorldRoad('camp_heart', 'camp', 'heart', [_longWayBack]),
  WorldRoad('reliquary_rimewell', 'reliquary', 'rimewell', [_frostPass]),
  WorldRoad('rimewell_highhearth', 'rimewell', 'highhearth', [_giantsStair]),
  WorldRoad('highhearth_greyhithe', 'highhearth', 'greyhithe', [_mootRoad]),
  WorldRoad('greyhithe_anchorage', 'greyhithe', 'anchorage', [_whiteQuay]),
  WorldRoad('greyhithe_shore', 'greyhithe', 'shore', [_hollowBeach]),
  // By sea from the camp.
  WorldRoad('anchorage_wreck', 'anchorage', 'wreck', [_glassShoals],
      kind: RoadKind.sea),
  WorldRoad('camp_wreck', 'camp', 'wreck', [_hullsReach], kind: RoadKind.sea),
  WorldRoad('camp_candlehold', 'camp', 'candlehold', [_lanternCrossing],
      kind: RoadKind.sea),
];

/// The roads that end at [landmarkId].
List<WorldRoad> roadsAt(String landmarkId) => [
      for (final r in worldRoads)
        if (r.joins(landmarkId)) r
    ];

/// The road that joins [a] and [b] directly, if there is one.
WorldRoad? roadBetween(String a, String b) {
  for (final road in worldRoads) {
    if (road.joins(a) && road.joins(b) && a != b) return road;
  }
  return null;
}

/// The shortest way along the roads from [from] to [to] (a leg weighs one,
/// and one more for each stop on it, so a road with more to pass is a longer
/// way), or null when no road leads there. Two ways of equal length: the one
/// whose roads come first in [worldRoads].
RoadRoute? roadRoute(String from, String to) {
  if (from == to) return const RoadRoute([]);
  final cost = <String, int>{from: 0};
  final via = <String, RouteLeg>{};
  final open = <String>[from];
  while (open.isNotEmpty) {
    open.sort((x, y) => cost[x]!.compareTo(cost[y]!));
    final here = open.removeAt(0);
    if (here == to) break;
    for (final road in worldRoads) {
      if (!road.joins(here)) continue;
      final next = road.other(here);
      final c = cost[here]! + 1 + road.stops.length;
      if (cost[next] == null || c < cost[next]!) {
        cost[next] = c;
        via[next] = RouteLeg(road, here, next);
        open.add(next);
      }
    }
  }
  if (!via.containsKey(to)) return null;
  final legs = <RouteLeg>[];
  for (var at = to; at != from; at = via[at]!.from) {
    legs.add(via[at]!);
  }
  return RoadRoute(legs.reversed.toList());
}
