import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import 'world_map.dart';

/// The world map drawn as a chart: the same places and road as
/// world_map.dart, laid out on one of three geographies, in the map's
/// three looks. Everything is in the map's own units
/// ([worldMapWidth] x [worldMapHeight]).
///
/// - [MapShape.continental]: one land wrapped round an inland sea; Alster
///   on the west arm, the Ashen Coast on the east, the Hollow Shore on the
///   northern cape.
/// - [MapShape.archipelago]: Alster is an island; the crossing is open
///   sea between the isles of the later chapters.
/// - [MapShape.delta]: Alster sits upstream on a great river whose mouths
///   fan into the sea; the later chapters lie on the far shore.
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
  });

  /// Each landmark's position, by id.
  final Map<String, Offset> places;

  /// Coastlines, each a closed loop drawn smooth.
  final List<List<Offset>> lands;

  /// Rivers and channels, each an open line drawn smooth.
  final List<List<Offset>> rivers;

  final List<ChartLabel> labels;

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

ChartGeography chartOf(MapShape shape) => switch (shape) {
      MapShape.continental => _continental,
      MapShape.archipelago => _archipelago,
      MapShape.delta => _delta,
    };

const _continental = ChartGeography(
  places: {
    'beggar': Offset(26, 140),
    'bridge': Offset(48, 124),
    'alley': Offset(30, 114),
    'square': Offset(68, 98),
    'market': Offset(80, 122),
    'hovel': Offset(14, 86),
    'hold': Offset(30, 60),
    'sewers': Offset(60, 70),
    'docks': Offset(96, 96),
    'tern': Offset(100, 70),
    'wharf': Offset(94, 44),
    'upper': Offset(66, 26),
    'berths': Offset(122, 40),
    'storm': Offset(136, 104),
    'camp': Offset(168, 140),
    'quarter': Offset(200, 94),
    'spire': Offset(224, 66),
    'grate': Offset(184, 116),
    'cloister': Offset(174, 160),
    'court': Offset(212, 146),
    'reliquary': Offset(238, 120),
    'heart': Offset(230, 164),
    'shore': Offset(210, 22),
  },
  lands: [
    [
      Offset(4, 8), Offset(60, 4), Offset(120, 6), Offset(180, 4), //
      Offset(236, 8), Offset(252, 30), Offset(250, 90), Offset(252, 150),
      Offset(240, 172), Offset(190, 172), Offset(162, 170),
      Offset(160, 150), Offset(154, 130), Offset(158, 104),
      Offset(162, 76), Offset(166, 48), Offset(150, 28), Offset(128, 24),
      Offset(114, 36), Offset(112, 60), Offset(106, 84), Offset(106, 110),
      Offset(112, 150), Offset(108, 172), Offset(60, 172), Offset(10, 168),
      Offset(4, 120), Offset(6, 60),
    ],
  ],
  rivers: [
    [
      Offset(40, 4),
      Offset(48, 34),
      Offset(56, 60),
      Offset(80, 84),
      Offset(104, 96)
    ],
    [Offset(230, 30), Offset(214, 60), Offset(212, 96), Offset(222, 130)],
  ],
  labels: [
    ChartLabel('ALSTER', 'ALSTER', 18, 150, 1),
    ChartLabel('the Narrow Sea', 'la Mer Étroite', 118, 160, 2, sea: true),
    ChartLabel('THE ASHEN COAST', 'LA CÔTE CENDRÉE', 172, 44, 3),
    ChartLabel('THE HOLLOW CAPE', 'LE CAP CREUX', 120, 6, 6),
  ],
);

const _archipelago = ChartGeography(
  places: {
    'beggar': Offset(32, 130),
    'bridge': Offset(58, 124),
    'alley': Offset(40, 110),
    'square': Offset(60, 96),
    'market': Offset(80, 114),
    'hovel': Offset(22, 84),
    'hold': Offset(42, 64),
    'sewers': Offset(64, 78),
    'docks': Offset(92, 100),
    'tern': Offset(112, 72),
    'wharf': Offset(118, 50),
    'upper': Offset(58, 42),
    'berths': Offset(138, 36),
    'storm': Offset(150, 100),
    'camp': Offset(184, 106),
    'quarter': Offset(206, 86),
    'spire': Offset(226, 62),
    'grate': Offset(160, 140),
    'cloister': Offset(172, 160),
    'court': Offset(192, 146),
    'reliquary': Offset(226, 130),
    'heart': Offset(234, 156),
    'shore': Offset(220, 20),
  },
  lands: [
    // Alster.
    [
      Offset(14, 60), Offset(40, 32), Offset(76, 34), Offset(92, 60), //
      Offset(100, 96), Offset(94, 126), Offset(70, 146), Offset(36, 150),
      Offset(12, 128), Offset(8, 94),
    ],
    // Tern Row and the wharf.
    [
      Offset(102, 62),
      Offset(112, 42),
      Offset(128, 44),
      Offset(128, 62),
      Offset(118, 82),
      Offset(104, 80),
    ],
    // The Ashen isle.
    [
      Offset(172, 100),
      Offset(190, 70),
      Offset(214, 48),
      Offset(238, 50),
      Offset(244, 72),
      Offset(226, 100),
      Offset(198, 116),
      Offset(176, 116),
    ],
    // The Hollow isle.
    [
      Offset(148, 140),
      Offset(160, 128),
      Offset(186, 132),
      Offset(204, 146),
      Offset(196, 166),
      Offset(170, 170),
      Offset(152, 160),
    ],
    // The reliquary isle.
    [
      Offset(214, 124),
      Offset(236, 116),
      Offset(250, 136),
      Offset(246, 166),
      Offset(226, 168),
      Offset(214, 146),
    ],
    // The Hollow Shore.
    [
      Offset(196, 22),
      Offset(212, 8),
      Offset(240, 10),
      Offset(248, 26),
      Offset(230, 34),
      Offset(206, 34),
    ],
  ],
  rivers: [
    [Offset(46, 38), Offset(52, 70), Offset(76, 92), Offset(98, 100)],
  ],
  labels: [
    ChartLabel('ALSTER', 'ALSTER', 20, 164, 1),
    ChartLabel('the Grey Water', 'l’Eau Grise', 118, 124, 2, sea: true),
    ChartLabel('THE ASHEN ISLE', 'L’ÎLE CENDRÉE', 136, 84, 3),
    ChartLabel('THE HOLLOW ISLES', 'LES ÎLES CREUSES', 88, 166, 4),
    ChartLabel('THE HOLLOW SHORE', 'LE RIVAGE CREUX', 128, 12, 6),
  ],
);

const _delta = ChartGeography(
  places: {
    'beggar': Offset(24, 84),
    'bridge': Offset(54, 52),
    'alley': Offset(44, 70),
    'square': Offset(62, 42),
    'market': Offset(62, 96),
    'hovel': Offset(14, 56),
    'hold': Offset(34, 18),
    'sewers': Offset(84, 52),
    'docks': Offset(96, 96),
    'tern': Offset(122, 84),
    'wharf': Offset(124, 122),
    'upper': Offset(112, 40),
    'berths': Offset(176, 166),
    'storm': Offset(204, 152),
    'camp': Offset(196, 114),
    'quarter': Offset(214, 88),
    'spire': Offset(240, 34),
    'grate': Offset(176, 78),
    'cloister': Offset(148, 72),
    'court': Offset(164, 44),
    'reliquary': Offset(236, 102),
    'heart': Offset(208, 56),
    'shore': Offset(232, 162),
  },
  lands: [
    [
      Offset(0, 0), Offset(256, 0), Offset(256, 94), Offset(236, 112), //
      Offset(212, 128), Offset(196, 144), Offset(176, 158),
      Offset(160, 176), Offset(0, 176),
    ],
    // The bar beyond the tear.
    [
      Offset(216, 158),
      Offset(232, 150),
      Offset(250, 156),
      Offset(246, 170),
      Offset(226, 172),
    ],
  ],
  rivers: [
    // The river through Alster, then its three mouths.
    [
      Offset(0, 22),
      Offset(36, 40),
      Offset(70, 64),
      Offset(100, 84),
      Offset(128, 106),
      Offset(146, 128)
    ],
    [Offset(146, 128), Offset(156, 152), Offset(166, 170)],
    [Offset(146, 128), Offset(172, 140), Offset(194, 148)],
    [Offset(146, 128), Offset(176, 120), Offset(216, 122)],
  ],
  labels: [
    ChartLabel('ALSTER', 'ALSTER', 10, 140, 1),
    ChartLabel('the Mouths', 'les Bouches', 112, 158, 2, sea: true),
    ChartLabel('the Grey Bay', 'la Baie Grise', 178, 170, 2, sea: true),
    ChartLabel('THE ASHEN BANK', 'LA RIVE CENDRÉE', 150, 30, 3),
  ],
  leftLabels: {'wharf'},
);

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
