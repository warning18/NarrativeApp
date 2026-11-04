// The world as two long strips for a side-view camera (UX-2's parallax,
// docs/proposals/scene-transitions.md; Core's note,
// docs/proposals/scene-flow-status-and-strip.md): every place with a scene
// and every stop of a road has an x on its strip, the same on every launch.
//
// - The land strip is the zones end to end in the order the journey reaches
//   them ([stripZoneOrder]); the sea crossing is a strip of its own.
// - In a zone, its places (the world map's landmarks) follow one another in
//   story order, each at its road distance from the last (world_leg_path's
//   polyline length on the story chart); between two zones, the road
//   distance from the last place of one to the first of the next.
// - A town's districts are spread around the town's x in the order of
//   their first scene in the story file (the order the story reaches
//   them), inside the zone; a building stands at its district's x.
// - A road's named stops are spaced along it as world_leg_path spaces them.
//
// Pure: no widget, no provider. Nothing calls it yet (v1.811).

import 'dart:math' as math;

import 'geography.dart';
import 'map_charts.dart';
import 'story_repository.dart';
import 'world_leg_path.dart';
import 'world_map.dart';
import 'world_roads.dart';

/// Which strip a place is on.
enum StripKind { land, sea }

/// The zones in the order the journey reaches them: the land strip is the
/// land zones in this order, end to end; a zone of biome `sea` is on the
/// sea strip. A zone with a scene that is not here has no x (the test says
/// so).
const List<String> stripZoneOrder = [
  'alster_vale',
  'dune_sea',
  'saltmouth_headland',
  'open_water',
  'the_cove',
  'ashlands',
  'spring_terraces',
  'wrack_cliffs',
  'the_fen',
  'frost_road',
  'glass_shore',
  'lantern_cliffs',
];

/// The side-view kit a zone's biome paints (lib/widgets/side_view/): the
/// four of UX-2's panorama in its order along the land strip (desert, then
/// ruins, fen, frost), the sea cliffs' and the sea's. A biome with no kit of
/// its own takes the nearest: the arid coast and the Tear's glass shore the
/// desert's, the volcanic terraces the ruins'; the temperate vale has none
/// yet and takes the desert's, as a crossing does for a terrain it has no
/// scene for (land_crossing_screen.dart).
const Map<String, String> stripKitOfBiome = {
  'temperate': 'desert',
  'desert': 'desert',
  'arid_coast': 'desert',
  'ashlands': 'ruins',
  'volcanic': 'ruins',
  'fen': 'fen',
  'frost': 'frost',
  'tear': 'desert',
  'sea_cliffs': 'cliffs',
  'sea': 'sea',
};

/// The room at each open end of a strip, and around a zone's only place
/// when no road gives its distance to the next zone (in chart units).
const double stripMargin = 12;

/// How far a town's districts spread on either side of the town's x, at
/// most (chart units); less when its neighbours are nearer.
const double stripDistrictSpread = 8;

/// Where something is: its strip, its zone, its x on the strip and the kit
/// painted there.
class StripPosition {
  const StripPosition(this.strip, this.zoneId, this.x, this.kit);

  final StripKind strip;
  final String zoneId;
  final double x;
  final String kit;

  @override
  String toString() => 'StripPosition(${strip.name}, $zoneId, $x, $kit)';
}

/// One zone's stretch of its strip: from [start] to [end], the x of each
/// of its places (locations, districts, buildings) by id.
class RegionStrip {
  const RegionStrip({
    required this.zoneId,
    required this.strip,
    required this.biome,
    required this.kit,
    required this.start,
    required this.end,
    required this.places,
  });

  final String zoneId;
  final StripKind strip;
  final String biome;
  final String kit;
  final double start;
  final double end;
  final Map<String, double> places;

  double get length => end - start;

  /// The x of [placeId] on the strip, or null when it is not in this zone.
  double? positionOf(String placeId) => places[placeId];

  RegionStrip _withEnd(double end) => RegionStrip(
        zoneId: zoneId,
        strip: strip,
        biome: biome,
        kit: kit,
        start: start,
        end: end,
        places: places,
      );
}

/// Both strips: every zone's stretch, every place's and road stop's x.
class RegionStrips {
  RegionStrips._(this._zones, this._story, this._geo, this._stops);

  /// The strips of [geo]'s places, laid out on [chart] (the story chart,
  /// `chartOf(MapShape.story)`), districts in the order of [story]'s scenes.
  factory RegionStrips.build({
    required Geography geo,
    required ChartGeography chart,
    required StoryData story,
  }) {
    final firstScene = _firstSceneOf(geo, story);
    final zones = <String, RegionStrip>{};
    // The last place laid on each strip: its zone, landmark and x.
    final last = <StripKind, ({String zone, String landmark, double x})>{};
    for (final zoneId in stripZoneOrder) {
      final zone = geo.place(zoneId);
      if (zone == null) continue;
      final kind = zone.biome == 'sea' ? StripKind.sea : StripKind.land;
      // Its places (the locations with a landmark) in story order.
      final locations = [
        for (final p in _descendants(geo, zoneId))
          if (p.level == GeoLevel.location && _landmarkOf(p) != null) p.id,
      ]..sort((a, b) => _storyRank(geo, a).compareTo(_storyRank(geo, b)));
      if (locations.isEmpty) continue;
      final landmarks = [
        for (final id in locations) _landmarkOf(geo.place(id)!)!,
      ];
      // The way in from the last place on this strip: half its road
      // distance on the last zone's stretch, half on this one's.
      final prev = last[kind];
      final double start, lead;
      if (prev == null) {
        start = 0;
        lead = stripMargin;
      } else {
        final half = _road(chart, prev.landmark, landmarks.first) / 2;
        zones[prev.zone] = zones[prev.zone]!._withEnd(prev.x + half);
        start = prev.x + half;
        lead = half;
      }
      final at = <double>[start + lead];
      for (var i = 1; i < locations.length; i++) {
        at.add(at.last + _road(chart, landmarks[i - 1], landmarks[i]));
      }
      final places = <String, double>{
        for (var i = 0; i < locations.length; i++) locations[i]: at[i],
      };
      zones[zoneId] = RegionStrip(
        zoneId: zoneId,
        strip: kind,
        biome: zone.biome,
        kit: stripKitOfBiome[zone.biome] ?? 'desert',
        start: start,
        end: at.last + stripMargin,
        places: places,
      );
      last[kind] = (zone: zoneId, landmark: landmarks.last, x: at.last);
    }
    // Once every stretch has its ends: a town's districts around it in
    // story order, kept off its neighbours and inside its zone; a building
    // at its district's x, else its town's.
    for (final strip in zones.values) {
      final towns = strip.places.entries.toList();
      for (var i = 0; i < towns.length; i++) {
        final at = towns[i].value;
        final room = [
          (at - strip.start) * 0.8,
          (strip.end - at) * 0.8,
          if (i > 0) (at - towns[i - 1].value) * 0.4,
          if (i < towns.length - 1) (towns[i + 1].value - at) * 0.4,
        ];
        final spread = math.min(stripDistrictSpread, room.reduce(math.min));
        final districts = [
          for (final p in geo.childrenOf(towns[i].key))
            if (p.level == GeoLevel.district) p.id,
        ]..sort((a, b) =>
            (firstScene[a] ?? _never).compareTo(firstScene[b] ?? _never));
        for (var k = 0; k < districts.length; k++) {
          strip.places[districts[k]] = districts.length == 1
              ? at
              : at - spread + 2 * spread * k / (districts.length - 1);
        }
      }
      for (final p in _descendants(geo, strip.zoneId)) {
        if (p.level != GeoLevel.building) continue;
        final holder = geo.ancestorAt(p.parent, GeoLevel.district) ??
            geo.ancestorAt(p.parent, GeoLevel.location);
        final x = holder == null ? null : strip.places[holder.id];
        if (x != null) strip.places[p.id] = x;
      }
    }
    final strips = RegionStrips._(zones, story, geo, {});
    strips._stops.addAll(strips._roadStops());
    return strips;
  }

  final Map<String, RegionStrip> _zones;
  final StoryData _story;
  final Geography _geo;
  final Map<String, StripPosition> _stops;

  /// Every zone's stretch, in [stripZoneOrder].
  List<RegionStrip> get zones => _zones.values.toList();

  /// The stretch of zone [regionId], or null when it has no place.
  RegionStrip? stripOf(String regionId) => _zones[regionId];

  /// Where [placeId] (a location, district or building) is.
  StripPosition? positionOfPlace(String placeId) {
    final zone = _geo.zoneOf(placeId);
    final strip = zone == null ? null : _zones[zone.id];
    final x = strip?.positionOf(placeId);
    if (strip == null || x == null) return null;
    return StripPosition(strip.strip, strip.zoneId, x, strip.kit);
  }

  /// Where scene [nodeId] happens; null for a scene that happens nowhere
  /// (the prologue, the making of the character).
  StripPosition? positionOfNode(String nodeId) {
    final place = _geo.placeOfNode(_story.nodeFor(nodeId));
    return place == null ? null : positionOfPlace(place.id);
  }

  /// Where the road stop [stopId] (world_roads.dart) is: spaced along its
  /// road between the two places it joins; on a sea road from the land to
  /// a place at sea, on the sea strip between its edge and that place.
  StripPosition? positionOfStop(String stopId) => _stops[stopId];

  /// The x the camera passes on a move from [fromPlaceId] to [toPlaceId]
  /// (any places with an x), first to last: the start, each road stop on
  /// the way (along the shortest road route, as the map walks it) and the
  /// end. Empty when the two are on different strips: the crossing between
  /// the land and the sea plays that move.
  List<double> pathOn(String fromPlaceId, String toPlaceId) {
    final a = positionOfPlace(fromPlaceId), b = positionOfPlace(toPlaceId);
    if (a == null || b == null || a.strip != b.strip) return const [];
    final la = _landmarkOf(_geo.locationOf(fromPlaceId)!);
    final lb = _landmarkOf(_geo.locationOf(toPlaceId)!);
    final route =
        la == null || lb == null || la == lb ? null : roadRoute(la, lb);
    return [
      a.x,
      if (route != null)
        for (final stop in route.stops)
          if (_stops[stop.id] case final at? when at.strip == a.strip) at.x,
      b.x,
    ];
  }

  Map<String, StripPosition> _roadStops() {
    final out = <String, StripPosition>{};
    for (final road in worldRoads) {
      final a = _placeOfLandmark(road.a), b = _placeOfLandmark(road.b);
      if (a == null || b == null) continue;
      final n = road.stops.length;
      if (a.strip == b.strip) {
        for (var k = 0; k < n; k++) {
          final x = a.x + (b.x - a.x) * (k + 1) / (n + 1);
          final zone = _zones[_zoneAt(a, b, x)]!;
          out[road.stops[k].id] =
              StripPosition(a.strip, zone.zoneId, x, zone.kit);
        }
        continue;
      }
      // From the land to the sea: on the sea strip, from its edge that faces
      // the land's zone to the place at sea.
      final (land, sea, landId) =
          a.strip == StripKind.sea ? (b, a, road.b) : (a, b, road.a);
      final seaZone = _zones[sea.zoneId]!;
      final landFirst = stripZoneOrder.indexOf(land.zoneId) <
          stripZoneOrder.indexOf(sea.zoneId);
      final edge = landFirst ? seaZone.start : seaZone.end;
      final stops = road.stopsFrom(landId);
      for (var k = 0; k < n; k++) {
        final x = edge + (sea.x - edge) * (k + 1) / (n + 1);
        out[stops[k].id] = StripPosition(
          StripKind.sea,
          sea.zoneId,
          x,
          seaZone.kit,
        );
      }
    }
    return out;
  }

  /// The zone of x between two places a and b on one strip.
  String _zoneAt(StripPosition a, StripPosition b, double x) {
    for (final z in [a.zoneId, b.zoneId]) {
      final s = _zones[z]!;
      if (x >= s.start && x <= s.end) return z;
    }
    return a.zoneId;
  }

  StripPosition? _placeOfLandmark(String landmarkId) {
    final place = _geo.placeOfLandmark(landmarkId);
    return place == null ? null : positionOfPlace(place.id);
  }
}

/// The road distance from landmark [a] to [b] on [chart] (a straight line
/// when no road joins them).
double _road(ChartGeography chart, String a, String b) =>
    a == b ? 0 : worldLegPath(chart, a, b).length;

String? _landmarkOf(GeoPlace location) =>
    location.landmarks.isEmpty ? null : location.landmarks.first;

/// A location's place in the story: its landmark's index on the world map
/// (worldMapLandmarks are listed in story order).
int _storyRank(Geography geo, String locationId) {
  final landmark = _landmarkOf(geo.place(locationId)!);
  final i = worldMapLandmarks.indexWhere((l) => l.id == landmark);
  return i < 0 ? _never : i;
}

/// Every place under [id], depth first, in the file's order.
List<GeoPlace> _descendants(Geography geo, String id) => [
      for (final child in geo.childrenOf(id)) ...[
        child,
        ..._descendants(geo, child.id),
      ],
    ];

const int _never = 1 << 30;

/// The index, in the story file's order, of the first scene that happens
/// in each district (or a building in it).
Map<String, int> _firstSceneOf(Geography geo, StoryData story) {
  final first = <String, int>{};
  var i = 0;
  for (final node in story.nodes.values) {
    final district = geo.ancestorAt(
      geo.placeOfNode(node)?.id,
      GeoLevel.district,
    );
    if (district != null) first.putIfAbsent(district.id, () => i);
    i++;
  }
  return first;
}
