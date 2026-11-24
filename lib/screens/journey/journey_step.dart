// One way on from the scene (its step, its place view) and the icon,
// colour and words of each kind of step. Cut out of journey_screen.dart
// with no change.
part of '../journey_screen.dart';

/// One way on from the scene, as the map shows it.
class _Step {
  _Step({
    required this.choice,
    required this.kind,
    required this.slot,
    required this.label,
    required this.locked,
    required this.leadsTo,
    required this.onwardKinds,
    this.event,
    this.hazard,
    this.bearing,
    this.chartTarget,
    this.targetLandmark,
    this.route,
    this.questTie,
  });

  final StoryChoice choice;
  final JourneyStepKind kind;

  /// The glyph of its mark (see journey_glyph.dart): what the way is.
  late final JourneyGlyph glyph = journeyGlyphOf(choice, kind);

  /// Whether the way is tied to a quest, the main one or a side job.
  final JourneyQuestTie? questTie;
  JourneySlot slot;

  /// The choice's text, or why it is shut while it is.
  final String label;
  final bool locked;

  /// The place the step reaches, when it is not where the party stands.
  final String? leadsTo;

  /// What the step's own scene offers next, glimpsed through the fog: the
  /// kinds of its first few ways on.
  final List<JourneyStepKind> onwardKinds;

  /// What waits on the road to the step (see road_events.dart).
  final RoadEventKind? event;

  /// Which of the land's hazards a hazard on this road would be (v1.197),
  /// shown when [event] is one.
  final BiomeHazard? hazard;

  /// For a way to another place: its true direction from here on the
  /// world chart (radians, 0 east, clockwise), and where it is there.
  final double? bearing;
  final Offset? chartTarget;

  /// The landmark that way leads to, for a journey over the world chart.
  final String? targetLandmark;

  /// The roads and named stops along the way there (v1.254).
  final ChartRoute? route;

  /// Whether taking the step carries the party somewhere (v1.224): across a
  /// bridge, into another district or building, through a door, out along a
  /// road. A way that keeps the party where it stands (a word with the
  /// innkeeper, a stall, a scuffle in the square) leaves it on its mark.
  bool moves = false;

  /// What kind of action the choice is and whether it is acted out where the
  /// party stands (Core's choice_shape.dart).
  late ChoiceShape shape;

  /// What its card says beside the text, and its ring (Core's choiceTags).
  late ChoiceTags tags;

  /// Whether the way is a card under the map and not a pin on it (v1.407):
  /// in a place, a choice acted out here (a fight, a payment, a check, a
  /// decision) has no place of its own to point at.
  bool onCard = false;

  /// What the way's card, pin name, row and panel carry beside its words: a
  /// price, a check, a fight (see _stepTag; v1.854).
  ChoiceTag? tag;

  /// The district (or room spot) of the party's own place that taking this
  /// step brings it to, when it stays inside the place (v1.246).
  String? district;
}

/// The place the party stands in, as the map draws it up close (v1.181):
/// what kind of place, its seed, and where it is on the world chart.
class _PlaceView {
  const _PlaceView({
    required this.kind,
    required this.seed,
    required this.geography,
    required this.chartHere,
    required this.marks,
    this.biome,
    this.glyphs = const {},
    this.water = '',
    this.plan,
    this.chart,
    this.explored,
    this.room,
    this.hereDistrict = '',
    this.districtOfStep = const {},
    this.holderColor,
    this.loading = false,
  });

  final PlaceKind kind;
  final int seed;
  final ChartGeography geography;
  final Offset chartHere;

  /// The city's plan (v1.203, see city_plan_record.dart), when the place is a
  /// city, a town or a village of the geography: the party stands in
  /// [hereDistrict] ('' for the square), and the steps into its other
  /// districts ([districtOfStep], by step) sit where those districts are.
  final PlacePlan? plan;

  /// The city drawn as board 15's chart (v1.350), when Core has stored the
  /// city's plan (city_plans.json): the district's streets, lots and named
  /// buildings, the districts not yet found under fog ([explored]). The
  /// plan is then that record.
  final CityChart? chart;
  final Set<String>? explored;

  /// The inside of the building the scene is in (v1.207, see
  /// room_plan.dart), drawn instead of the streets: then [hereDistrict]
  /// is the party's spot in it and [districtOfStep] each way's spot.
  final RoomPlan? room;
  final String hereDistrict;
  final Map<int, String> districtOfStep;

  /// The districts' glyphs over the ways into them, by step (v1.199).
  final Map<int, String> glyphs;

  /// The place's water: 'river', 'shore' or ''.
  final String water;

  /// The places around on the chart, for the road between two of them.
  final List<ChartMark> marks;

  /// The land the place lies in (v1.197, see geography.dart): its ground
  /// is painted under the place.
  final Biome? biome;

  /// The colour of the clan that holds the place now (v1.406), red when it
  /// is the party's nemesis: the ground takes a faint wash of it.
  final Color? holderColor;

  /// A city, a town or a village whose stored plan has not loaded yet: its
  /// ground shows alone until the chart replaces it (N11), not a plan that
  /// is not the city's.
  final bool loading;

  /// The same place for a map that draws only the steps [keep] lists (by
  /// their place in the list of steps): the glyphs and districts follow.
  _PlaceView pinned(List<int> keep) => _PlaceView(
        kind: kind,
        seed: seed,
        geography: geography,
        chartHere: chartHere,
        marks: marks,
        biome: biome,
        glyphs: {
          for (var j = 0; j < keep.length; j++)
            if (glyphs[keep[j]] case final glyph?) j: glyph,
        },
        water: water,
        plan: plan,
        chart: chart,
        explored: explored,
        loading: loading,
        room: room,
        hereDistrict: hereDistrict,
        districtOfStep: {
          for (var j = 0; j < keep.length; j++)
            if (districtOfStep[keep[j]] case final d?) j: d,
        },
        holderColor: holderColor,
      );
}

/// A seed from [text] that is the same on every run.
int _stableSeed(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// A scene with more cards than this is a hub: its choices go on rings and
/// chips, a list for each, not a list of cards.
const int _hubCards = 4;

/// A hub's rings, in the order of the chips: a fight, a talk or a
/// decision, a check or a payment.
const _ringOrder = [
  ChoiceGroup.fight,
  ChoiceGroup.talkDecide,
  ChoiceGroup.checksPay,
];

/// A road event's badge on its step (see road_events.dart): a hazard's
/// is its own (see hazardIcon).
IconData _eventIcon(RoadEventKind kind, {BiomeHazard? hazard}) =>
    switch (kind) {
      RoadEventKind.champion => Icons.military_tech,
      RoadEventKind.shrine => Icons.spa_outlined,
      RoadEventKind.caravan => Icons.storefront,
      RoadEventKind.hazard =>
        hazard == null ? Icons.warning_amber_rounded : hazardIcon(hazard),
    };

Color _eventColour(RoadEventKind kind, InkColors ink) => switch (kind) {
      RoadEventKind.champion => ink.blood,
      RoadEventKind.shrine => ink.heal,
      RoadEventKind.caravan => ink.gold,
      RoadEventKind.hazard => ink.ember,
    };

IconData _iconFor(JourneyStepKind kind) => switch (kind) {
      JourneyStepKind.ending => Icons.auto_stories_outlined,
      JourneyStepKind.mainQuest => Icons.flag_outlined,
      JourneyStepKind.expedition => Icons.explore_outlined,
      JourneyStepKind.fight => Icons.sports_martial_arts,
      JourneyStepKind.challenge => Icons.casino,
      JourneyStepKind.check => Icons.casino_outlined,
      JourneyStepKind.shop => Icons.storefront_outlined,
      JourneyStepKind.quest => Icons.chat_bubble_outline,
      JourneyStepKind.travel => Icons.sailing_outlined,
      JourneyStepKind.rest => Icons.bedtime_outlined,
      JourneyStepKind.road => Icons.signpost_outlined,
    };

String _kindKey(JourneyStepKind kind) => 'journey_kind_${kind.name}';

/// The colour a step of [kind] is drawn in: danger in blood and ember,
/// rolls and voyages in tide, what a place offers in gold. The Shroud
/// look keeps colour for the Void alone, and the main quest's mark.
Color _colorFor(JourneyStepKind kind, InkColors ink, ChartPalette palette,
    {required bool greyed}) {
  if (greyed) {
    return switch (kind) {
      JourneyStepKind.ending => palette.voidColor,
      JourneyStepKind.mainQuest => palette.mark,
      _ => palette.place,
    };
  }
  return switch (kind) {
    JourneyStepKind.ending => ink.voidColor,
    JourneyStepKind.mainQuest => palette.mark,
    JourneyStepKind.expedition => ink.ember,
    JourneyStepKind.fight => ink.blood,
    JourneyStepKind.challenge || JourneyStepKind.check => ink.tide,
    JourneyStepKind.shop || JourneyStepKind.quest => ink.gold,
    JourneyStepKind.travel => ink.tide,
    JourneyStepKind.rest => ink.heal,
    JourneyStepKind.road => palette.place,
  };
}

CityWayKind _cityWayKindOf(JourneyStepKind kind) => switch (kind) {
      JourneyStepKind.fight => CityWayKind.fight,
      JourneyStepKind.check || JourneyStepKind.challenge => CityWayKind.check,
      JourneyStepKind.shop => CityWayKind.shop,
      JourneyStepKind.quest || JourneyStepKind.mainQuest => CityWayKind.quest,
      _ => CityWayKind.road,
    };
