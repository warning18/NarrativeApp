import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import 'chart_worlds.dart';
import 'world_map.dart';

/// The world map drawn as a chart: the same places and road as
/// world_map.dart, laid out on one of three geographies, in the map's
/// three looks. Everything is in the map's own units
/// ([worldMapWidth] x [worldMapHeight]).
///
/// - [MapShape.continental] (A, the Two Shores): the Old Continent west,
///   the Ashen Continent east across the Narrow Sea, the Lantern Isles far
///   to the south, the tear off the north-eastern cape.
/// - [MapShape.archipelago] (B, the Ring, the default since v1.199): the
///   lands make a broken ring round an inner sea with the Lantern Isles at
///   its heart; the ring is broken in the north-east where the tear opened.
/// - [MapShape.delta] (C, the River and the Frost): one continent read
///   south to north, Alster upstream, the Frost Reach at the top, the
///   Lantern Isles west out at sea.
///
/// Each world (chart_worlds.dart, generated from the design) also carries
/// its lands' biome zones, its rivers, and, on the Ring, its mountain
/// ranges, villages, bridges, the clans' seats and the trade and quest
/// roads: the chart painter draws them, with coasts broken into bays and
/// headlands and terrain over each land (see chart_relief.dart).
enum MapShape { continental, archipelago, delta }

/// One region's name on the chart, shown once the story reaches
/// [chapter].
class ChartLabel {
  const ChartLabel(this.en, this.fr, this.x, this.y, this.chapter,
      {this.sea = false});
  final String en;
  final String fr;
  final double x;
  final double y;
  final int chapter;

  /// A body of water: set in italics.
  final bool sea;

  String text(AppLanguage language) => language == AppLanguage.fr ? fr : en;
}

/// A geography: where each place is, the land, the rivers and the names.
class ChartGeography {
  const ChartGeography({
    required this.places,
    required this.lands,
    required this.rivers,
    required this.labels,
    this.leftLabels = const {},
    this.zones = const [],
    this.ranges = const [],
    this.features = const [],
    this.tradeRoads = const [],
  });

  /// Each landmark's position, by id.
  final Map<String, Offset> places;

  /// Coastlines, each a closed loop drawn smooth.
  final List<List<Offset>> lands;

  /// Rivers and channels, each an open line drawn smooth.
  final List<List<Offset>> rivers;

  final List<ChartLabel> labels;

  /// The lands' biomes, each a polygon with a name (v1.199).
  final List<ChartZone> zones;

  /// The mountain ranges, each a line of peaks with a name.
  final List<ChartRange> ranges;

  /// Villages, works, bridges, stone giants, the clans' seats and the
  /// later quests' places: drawn once their land is reached.
  final List<ChartFeature> features;

  /// Trade and quest roads between places, in grey beside the story road.
  final List<(Offset, Offset)> tradeRoads;

  /// The zone [point] lies in, if any.
  ChartZone? zoneAt(Offset point) {
    for (final zone in zones) {
      if (pointInPolygon(point, zone.polygon)) return zone;
    }
    return null;
  }

  /// Places whose names go to the left of their mark, clear of a
  /// neighbour's (names near the right edge always do).
  final Set<String> leftLabels;

  /// Whether [landmark]'s name goes to the left of its mark.
  bool labelsLeft(Landmark landmark) =>
      leftLabels.contains(landmark.id) || of(landmark).dx > 180;

  /// Where [landmark] is on this chart (every landmark has a spot on
  /// each; see map_charts_test.dart). One without falls to the middle.
  Offset of(Landmark landmark) =>
      places[landmark.id] ??
      const Offset(worldMapWidth / 2, worldMapHeight / 2);
}

/// One biome land on the chart: its polygon, its name and where the name
/// sits. [biome] is a biomes.json id (temperate, desert, frost…).
class ChartZone {
  const ChartZone(
      this.biome, this.nameEn, this.nameFr, this.labelAt, this.polygon,
      {this.influence = const []});
  final String biome;

  /// The clans whose writ runs here, strongest first, each with how far
  /// it runs (0 to 1): the clans calque.
  final List<(String, double)> influence;
  final String nameEn;
  final String nameFr;
  final Offset labelAt;
  final List<Offset> polygon;
  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
}

/// A mountain range: peaks drawn along [line], [size] units tall.
class ChartRange {
  const ChartRange(this.nameEn, this.nameFr, this.line, this.size,
      {this.snow = false, this.ember = false});
  final String nameEn;
  final String nameFr;
  final List<Offset> line;
  final double size;
  final bool snow;
  final bool ember;
  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
}

enum ChartFeatureKind { village, seat, bridge, giant, site }

/// Something on the chart beside the story's places: a village or works,
/// a clan's seat (ringed in [clan]'s colour, with a pennant), a bridge
/// turned by [angle], a stone giant, or a later quest's place ([site]).
class ChartFeature {
  const ChartFeature(this.kind, this.at, this.nameEn, this.nameFr,
      {this.noteEn = '',
      this.noteFr = '',
      this.clan = '',
      this.angle = 0,
      this.landmark = '',
      this.atSea = false});
  final ChartFeatureKind kind;
  final Offset at;
  final String nameEn;
  final String nameFr;
  final String noteEn;
  final String noteFr;

  /// For a seat: the clan's id (factions.json).
  final String clan;
  final double angle;

  /// For a seat that is also one of the story's landmarks: its id, so the
  /// name is not written twice.
  final String landmark;
  final bool atSea;
  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
  String note(AppLanguage language) =>
      language == AppLanguage.fr ? noteFr : noteEn;
}

/// Whether [p] lies inside [polygon] (even-odd).
bool pointInPolygon(Offset p, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i], b = polygon[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

ChartGeography chartOf(MapShape shape) => switch (shape) {
      MapShape.continental => chartWorldA,
      MapShape.archipelago => chartWorldB,
      MapShape.delta => chartWorldC,
    };

/// A look's colours for the chart.
class ChartPalette {
  const ChartPalette({
    required this.sea,
    required this.seaLine,
    required this.land,
    required this.coast,
    required this.river,
    required this.fog,
    required this.label,
    required this.place,
    required this.road,
    required this.ahead,
    required this.mark,
    required this.voidColor,
    required this.roofs,
  });

  final Color sea;
  final Color seaLine;
  final Color land;
  final Color coast;
  final Color river;
  final Color fog;

  /// Region names and uncharted notes.
  final Color label;

  /// Place names.
  final Color place;

  /// The road walked.
  final Color road;

  /// The way on to the next place.
  final Color ahead;

  /// Where the story is.
  final Color mark;

  /// The tear and what it touches.
  final Color voidColor;

  /// The little roofs of the towns.
  final Color roofs;

  static ChartPalette of(MapLook look) => switch (look) {
        MapLook.night => const ChartPalette(
            sea: Color(0xFF16323B),
            seaLine: Color(0xFF214552),
            land: Color(0xFF26232C),
            coast: Color(0xFF4A4552),
            river: Color(0xFF2E5868),
            fog: Color(0xFF141217),
            label: Color(0xFF6E6878),
            place: Color(0xFFC9C3B8),
            road: Color(0xFFF2C14E),
            ahead: Color(0xFF6E6878),
            mark: Color(0xFFF2C14E),
            voidColor: Color(0xFFA987EA),
            roofs: Color(0xFF34303C),
          ),
        MapLook.parchment => const ChartPalette(
            sea: Color(0xFFD6C7A1),
            seaLine: Color(0xFFC2B28A),
            land: Color(0xFFF1E6CC),
            coast: Color(0xFF8C7A57),
            river: Color(0xFF9FB0A6),
            fog: Color(0xFFE6DAB9),
            label: Color(0xFF8C7A57),
            place: Color(0xFF3A2E1F),
            road: Color(0xFF9B2A2A),
            ahead: Color(0xFF8C7A57),
            mark: Color(0xFF9B2A2A),
            voidColor: Color(0xFF6A4FB0),
            roofs: Color(0xFFD9C9A4),
          ),
        MapLook.shroud => const ChartPalette(
            sea: Color(0xFF18181B),
            seaLine: Color(0xFF26262B),
            land: Color(0xFF303036),
            coast: Color(0xFF45454C),
            river: Color(0xFF3A3A42),
            fog: Color(0xFF151518),
            label: Color(0xFF6E6E76),
            place: Color(0xFFCFCFD4),
            road: Color(0xFFE2E2E6),
            ahead: Color(0xFF6E6E76),
            mark: Color(0xFFB98CF0),
            voidColor: Color(0xFFB98CF0),
            roofs: Color(0xFF38383F),
          ),
      };
}
