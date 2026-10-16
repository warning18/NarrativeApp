import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/encounter_text.dart';
import '../data/clan_power.dart' show holderOf;
import '../data/geography.dart';
import '../data/choice_shape.dart';
import '../data/city_plan.dart';
import '../data/place_plan.dart';
import '../data/room_plan.dart';
import '../data/journey_map.dart';
import '../data/scene_flow.dart';
import '../data/journey_relief.dart';
import '../data/map_charts.dart' show ChartGeography, ChartPalette, chartOf;
import '../data/road_chart.dart';
import '../data/narration_tokens.dart';
import '../data/party_trail.dart';
import '../data/quest_hints.dart' show mainQuestIdsOf;
import '../data/road_events.dart';
import '../data/story_repository.dart';
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/app_mode_provider.dart';
import '../data/camp_state.dart' show canReturnToCampFrom;
import '../providers/chapter_loop_provider.dart';
import '../providers/city_provider.dart';
import '../providers/clans_provider.dart' show factionsProvider;
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/detour_scene_band.dart';
import '../widgets/biome_backdrop.dart';
import '../widgets/choice_card.dart';
import '../widgets/choice_rings.dart';
import '../widgets/clan_power_block.dart' show holderTint;
import '../providers/climate_provider.dart';
import '../data/weather_effects.dart';
import '../widgets/weather_chip.dart';
import '../widgets/room_plan_painter.dart';
import '../widgets/chart_map_painter.dart' show ChartFog;
import '../widgets/calques_sheet.dart';
import '../widgets/journey_world_map.dart';
import '../widgets/geography_widgets.dart';
import '../widgets/journey_fx.dart';
import '../widgets/journey_glyph.dart';
import '../widgets/journey_banner_pin.dart';
import '../widgets/city_chart/city_chart.dart';
import '../widgets/city_chart/city_chart_painter.dart';
import '../widgets/city_chart/city_chart_view.dart';
import '../widgets/city_plan_painter.dart';
import '../widgets/journey_place.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/camp_travel.dart' show CampReturnButton, TravelOnList;
import '../widgets/pixel_sprite.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/timed_choice_bar.dart';
import 'journal_screen.dart';
import 'city_chart_screen.dart';
import 'full_map_screen.dart';
import 'story_player_screen.dart'
    show
        StoryPlayerScreen,
        EchoLine,
        composeNarrationParts,
        isStoryChoiceLocked,
        noteShownEchoes,
        storyChoiceLockedText,
        takeStoryChoice;

export '../providers/home_tab_provider.dart' show journeyTabIndex;

/// The Journey tab: the story and the map in one. The scene the story is
/// on reads at the top (double-tap it to read it full screen); under it a
/// chart of the road, with the chapter's earlier scenes below the party
/// (scroll down to them), the party where it stands, and each way on
/// ahead as a step on the map. Tapping a step says what it holds; Go (or
/// a second tap) walks the party there and takes it, exactly as its
/// choice under the story would.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(storyDataProvider).when(
          data: (story) => _JourneyView(story: story),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${tr(ref, 'failed_to_load_story')}: $error'),
            ),
          ),
        );
  }
}

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
  });

  final PlaceKind kind;
  final int seed;
  final ChartGeography geography;
  final Offset chartHere;

  /// The city's plan (v1.203, see city_plan.dart), when the place is a
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

class _JourneyView extends ConsumerStatefulWidget {
  const _JourneyView({required this.story});

  final StoryData story;

  @override
  ConsumerState<_JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends ConsumerState<_JourneyView>
    with TickerProviderStateMixin {
  /// The scene the selection and the chart belong to; a new scene clears
  /// the one and draws a new other.
  String? _sceneKey;
  int? _selected;

  /// A way picked on the city plan, to select on the map once its step is built.
  StoryChoice? _cityPick;

  /// The steps the map draws as pins (the others are cards under it), by
  /// their place in the list of steps.
  List<int> _pinIdx = const [];

  /// The ring whose list is open in a sheet (a hub's choices are grouped by
  /// kind, v1.419), and the card being taken while the others dim.
  String? _ringOpen;
  int? _pressed;

  /// A scene with more cards than this is a hub: its choices go on rings and
  /// chips, a list for each, not a list of cards.
  static const int _hubCards = 4;

  /// The scene a step is being taken from, while the party walks there
  /// and its choice plays out: the map waits on it meanwhile. Kept by
  /// scene, so the scene the story moves on to never waits on a step cut
  /// short.
  String? _takingFrom;
  bool get _busy => _takingFrom != null && _takingFrom == _sceneKey;

  /// Where the party stands on the world chart, and under what name (v1.245):
  /// kept from scene to scene, so a scene the story carries the party to
  /// without a walk (a fight lost, a roll failed, the travel list) starts
  /// from where it was.
  Offset? _partyChart;
  String _partyName = '';
  String? _partyLandmark;

  /// The road the party is carried along, with what is said of it, shown
  /// over the map until it ends or is tapped.
  _Transit? _transit;

  /// Where the party stood inside the place it was last shown in (v1.246):
  /// the plan it stood on (the city's or a room's) and its district or spot.
  /// A scene the story carries it to along no walk, in the same place, has
  /// it travel the streets from there ([_arriveFrom], until shown once).
  String? _partyPlan;
  String _partyDistrict = '';
  String? _arriveFrom;

  /// A new scene's lone step is still to be picked for the player.
  bool _autoPickPending = false;
  GlobalKey<_JourneyChartState> _chartKey = GlobalKey();

  /// How far out the map is looked at (v1.199): the place, its land, or
  /// the world; and the place last tapped on the chart.
  JourneyMapLevel _level = JourneyMapLevel.place;
  Landmark? _lookedAt;

  /// The whole town in view instead of the district (v1.350): the rung
  /// between the district and the world, for a place with a city plan.
  bool _townView = false;

  /// Whether the place the map shows has a city plan to look at whole
  /// (set while building).
  bool _canTown = false;

  /// The chart of the city's stored plan, kept while its words hold.
  CityChart? _cityChart;
  String _cityChartKey = '';

  /// The district the map is framed on in a city drawn as board 15's chart
  /// (null: the party's own), and a count that asks the chart to frame it
  /// again.
  String? _cityFocus;
  int _cityFocusToken = 0;

  CityChartText _cityText() => CityChartText(
        wholeCity: tr(ref, 'city_whole'),
        unexplored: tr(ref, 'city_unexplored'),
        go: tr(ref, 'city_go'),
        walk: tr(ref, 'city_walk'),
        here: tr(ref, 'city_here'),
        zoomIn: tr(ref, 'city_zoom_in'),
        zoomOut: tr(ref, 'city_zoom_out'),
        waysOne: tr(ref, 'city_ways_one'),
        waysMany: tr(ref, 'city_ways_many'),
        kinds: {
          CityWayKind.quest: tr(ref, 'city_kind_quest'),
          CityWayKind.fight: tr(ref, 'city_kind_fight'),
          CityWayKind.check: tr(ref, 'city_kind_check'),
          CityWayKind.shop: tr(ref, 'city_kind_shop'),
          CityWayKind.road: tr(ref, 'city_kind_road'),
        },
      );

  /// The town in view or the district (the chart frames it again).
  void _setTown(bool town, {bool resetFocus = false}) {
    setState(() {
      _townView = town;
      _cityFocusToken++;
      if (resetFocus) _cityFocus = null;
    });
  }

  /// A way's sheet (board 15): what it is and Go; the pin and the row open
  /// the same.
  void _openWay(int i, List<_Step> steps, bool french) {
    setState(() => _selected = i);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepDetail(
                step: steps[i],
                busy: _busy,
                french: french,
                isExcursion: false,
                onGo: steps[i].locked
                    ? null
                    : () {
                        Navigator.of(sheet).pop();
                        _take(i, steps[i]);
                      },
              ),
              TextButton(
                key: const ValueKey('journey_city_not_now'),
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text(tr(ref, 'journey_city_not_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The scale of a pinch on the place's map (see _lookOut): the streets
  /// shrink under the fingers, and the chart opens where they were left.
  double _pinch = 1;
  bool _pinching = false;

  /// Whether the scene is inside a building (v1.207), and whether the
  /// map looks out at the streets from it: the room is one level in from
  /// the streets, the streets one in from the land.
  bool _sceneInside = false;
  bool _outside = false;

  /// The zoom the chart opens at when the streets are left (v1.201.1):
  /// the pinch's own scale carried over, so nothing jumps.
  double? _enterZoom;

  /// The streets growing back under the chart when they are looked at
  /// again (v1.201.1).
  late final AnimationController _arrive = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360), value: 1);

  /// Looks out from the streets at the land (v1.201): a pinch in on the
  /// place's map or its − button; zooming back in on the place returns.
  /// [from] is the streets' scale when left, the chart's zoom to open at.
  void _lookOut({double from = 1}) {
    if (_level != JourneyMapLevel.place) return;
    if (_sceneInside && !_outside) {
      // Out of the building first: the streets round it.
      setState(() {
        _outside = true;
        _pinch = 1;
        _pinching = false;
      });
      _arrive.forward(from: 0);
      return;
    }
    // From a district, the whole town comes first; the world after it.
    if (_canTown && !_townView) {
      _setTown(true);
      setState(() {
        _pinch = 1;
        _pinching = false;
      });
      return;
    }
    setState(() {
      _townView = false;
      _enterZoom = (JourneyWorldMapZoom.max * from)
          .clamp(JourneyWorldMapZoom.land, JourneyWorldMapZoom.max);
      _level = JourneyMapLevel.land;
      _lookedAt = null;
      _pinch = 1;
      _pinching = false;
    });
  }

  /// A tab of the level strip (v1.350): the district, the whole town, or
  /// the world, in one tap.
  void _goLevel(_LevelTab tab) {
    switch (tab) {
      case _LevelTab.district:
        if (_level != JourneyMapLevel.place) {
          _arriveAtStreets(town: false);
        } else if (_townView) {
          _setTown(false, resetFocus: true);
        } else {
          // Already on a district: frame the party's own again.
          setState(() => _cityFocus = null);
          _setTown(false);
        }
      case _LevelTab.town:
        if (_level != JourneyMapLevel.place) {
          _arriveAtStreets();
        } else if (_canTown && !_townView) {
          _setTown(true);
        }
      case _LevelTab.world:
        if (_level == JourneyMapLevel.place) {
          setState(() {
            _townView = false;
            _enterZoom = null;
            _level = JourneyMapLevel.world;
            _lookedAt = null;
            _pinch = 1;
            _pinching = false;
          });
        } else if (_level == JourneyMapLevel.land) {
          setState(() => _level = JourneyMapLevel.world);
        }
    }
  }

  /// Back to the streets from the chart: they grow in from small. A
  /// scene inside a building shows the streets round it first.
  void _arriveAtStreets({bool town = true}) {
    setState(() {
      // Down from the world the town is met first (the ladder runs both
      // ways); a tab asks for the district itself.
      _townView = town && _canTown;
      _cityFocusToken++;
      if (!town) _cityFocus = null;
      _level = JourneyMapLevel.place;
      _lookedAt = null;
      _outside = _sceneInside;
    });
    _arrive.forward(from: 0);
  }

  /// In through the door: the room grows in from the streets (v1.207).
  void _goInside() {
    setState(() {
      _outside = false;
      _pinch = 1;
      _pinching = false;
    });
    _arrive.forward(from: 0);
  }

  /// The other places known, each with its "Go".
  void _showTravelOn(String fromNodeId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr(ref, 'travel_on_title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TravelOnList(fromNodeId: fromNodeId),
            ],
          ),
        ),
      ),
    );
  }

  /// Each landmark where a shop opens; read once per story.
  Set<String>? _shopPlaces;
  StoryData? _shopPlacesOf;

  Set<String> _shopsFor(StoryData story) {
    if (_shopPlaces != null && identical(_shopPlacesOf, story)) {
      return _shopPlaces!;
    }
    _shopPlacesOf = story;
    return _shopPlaces = shopPlacesOf(story);
  }

  /// The calques sheet: one calque over the chart at a time, or none.
  Future<void> _showCalques() => showCalquesSheet(context, ref);

  /// The scene read full screen (double-tap on it, again to come back).
  bool _reading = false;

  /// How far the land has moved under the party: each walk carries it on
  /// by the road walked, so the hills stay where they were as the next
  /// scene's map takes over.
  Offset _terrainShift = Offset.zero;

  /// The place and chapter the map last showed: reaching a new place
  /// stamps its name on the map, a new chapter burns its map open.
  String? _shownPlace;
  int? _shownChapter;
  String? _stamp;
  bool _burn = false;

  /// Counts the times the tab is opened from another: the map unrolls.
  int _unroll = 0;

  /// Each landmark's kind of place, from the settlements the story puts
  /// there (a town's hub, a camp); read once per story.
  Map<String, String>? _placeKinds;
  StoryData? _placeKindsOf;

  Map<String, String> _kindsFor(StoryData story) {
    if (_placeKinds != null && identical(_placeKindsOf, story)) {
      return _placeKinds!;
    }
    _placeKindsOf = story;
    return _placeKinds = placeKindsOf(story);
  }

  /// The jolt going into a fight: the map shakes and its edges run red.
  late final AnimationController _jolt = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void dispose() {
    _jolt.dispose();
    _arrive.dispose();
    super.dispose();
  }

  String _sceneKeyOf(StoryPlayState play) =>
      '${play.activeExcursionNode?.id ?? play.currentNodeId}'
      '_${play.isInExcursion}_${play.history.length}';

  Future<void> _take(int index, _Step step) async {
    // The scene the step was drawn for.
    final before = _sceneKey;
    if (_busy || step.locked || before == null) return;
    setState(() {
      _takingFrom = before;
      _pressed = index;
    });
    // Where the party stands before it sets out.
    final home = _partyChart;
    final homePlan = _partyPlan, homeDistrict = _partyDistrict;
    final homeLandmark = _partyLandmark;
    // The story moved on meanwhile (the walk cut short with its map): the
    // step is no longer one to take.
    bool moved() => _sceneKeyOf(ref.read(storyPlayProvider)) != before;
    Offset? walked;
    var taken = false;
    try {
      final chart = _chartKey.currentState;
      // A choice done here (a card) has a beat at the party's mark instead
      // of a walk: a ring in its kind's colour and its icon rising.
      if (chart != null &&
          step.onCard &&
          !MediaQuery.of(context).disableAnimations) {
        await chart.playBeat(
            _groupColor(step.tags.group, InkColors.of(context)), _iconOf(step));
        if (!mounted || moved()) return;
      }
      // Only a way that carries the party somewhere walks it there; a word
      // with the innkeeper or a scuffle in the square leaves it on its mark.
      if (chart != null &&
          step.moves &&
          !MediaQuery.of(context).disableAnimations) {
        walked = await chart.walkTo(_pinIdx.indexOf(index));
      }
      if (!mounted || moved()) return;
      if (walked != null) _terrainShift += walked;
      // The party has walked to where the step leads: it stands there from
      // now on, whatever the scene after turns out to be.
      final reached = step.chartTarget;
      if (step.moves && reached != null) {
        _partyChart = reached;
        _partyLandmark = step.targetLandmark ?? _partyLandmark;
        // Another place: its own plan, not this one's streets.
        _partyPlan = null;
      } else if (step.moves && step.district != null) {
        _partyDistrict = step.district!;
      }
      if (step.kind == JourneyStepKind.fight ||
          step.kind == JourneyStepKind.expedition) {
        if (!MediaQuery.of(context).disableAnimations) {
          await _jolt.forward(from: 0);
        }
        if (!mounted || moved()) return;
      }
      await takeStoryChoice(context, ref, step.choice);
      taken = true;
    } finally {
      if (mounted) {
        // A choice that keeps the story where it was (a shop, a fight
        // fled) brings the party back to its mark.
        final stayed = _sceneKeyOf(ref.read(storyPlayProvider)) == before;
        if (stayed) {
          // The party walks back along the road it took (v1.245), and
          // stands where it set out from again.
          final chart = _chartKey.currentState;
          if (chart != null) await chart.walkBack();
          if (mounted) {
            if (walked != null) _terrainShift -= walked;
            _partyChart = home;
            _partyPlan = homePlan;
            _partyDistrict = homeDistrict;
            _partyLandmark = homeLandmark;
          }
        }
        if (mounted) {
          setState(() {
            if (_takingFrom == before) _takingFrom = null;
            _pressed = null;
            // The choice moved the story on: the new scene is read full
            // screen, and Continue brings the map back.
            if (taken && !stayed) _reading = true;
          });
        }
      }
    }
  }

  /// Reads the scene full screen, or comes back to the map; not while the
  /// party walks, whose map would go from under it.
  void _read(bool reading) {
    if (_busy) return;
    setState(() => _reading = reading);
  }

  void _tap(int index, _Step step) {
    if (_busy) return;
    if (_selected == index && !step.locked) {
      _take(index, step);
      return;
    }
    setState(() => _selected = index);
  }

  /// The height of the panel under the map: a way picked fills it as it
  /// did; with choices acted out here, the cards get more of the screen.
  /// Whether the scene being played is a written detour (see
  /// detour_scene_band.dart): its ways are all cards.
  bool _writtenDetour = false;

  double _panelHeight(double area, List<_Step> steps) {
    final plain = math.min(124.0, math.max(104.0, area * 0.26));
    final cards = steps.where((s) => s.onCard).length;
    if ((_level != JourneyMapLevel.place && !_writtenDetour) || cards == 0) {
      return plain;
    }
    // On a short phone the map keeps its room and the cards scroll; a taller
    // one gives them more, up to three cards.
    final room = ((area - 430) * 0.4).clamp(0.0, 90.0);
    return math.max(plain, math.min(plain + room, 66.0 * 3 + 8));
  }

  /// The tag a card carries: a price, an alignment shift, a check or the
  /// kind of fight, whichever the choice has first (Core's choiceTags).
  ChoiceTag? _cardTag(_Step step, InkColors ink) {
    final c = step.choice;
    final tags = step.tags;
    String signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
    if (tags.cost > 0) {
      return ChoiceTag('${tags.cost} ${tr(ref, 'gold_label')}', ink.gold);
    }
    if (tags.alignment != 0) {
      return ChoiceTag(
          '${tr(ref, 'alignment_label')} ${signed(tags.alignment)}',
          ink.voidColor);
    }
    if (c.hasAbilityCheck) {
      return ChoiceTag(
          '${tr(ref, '${c.checkAbility}_label')} DC ${c.checkDC ?? 10}',
          ink.tide);
    }
    if (step.shape.action == ChoiceAction.fight) {
      return ChoiceTag(tr(ref, 'journey_kind_fight'), ink.blood);
    }
    return null;
  }

  /// The icon of a choice done here: its glyph (a fight, a roll, a shop), or
  /// for a plain decision or word, the action's own (the road's signpost
  /// would say it leads somewhere).
  IconData _iconOf(_Step step) {
    if (step.kind != JourneyStepKind.road) return step.glyph.icon;
    return switch (step.shape.action) {
      ChoiceAction.talk => Icons.chat_bubble_outline,
      ChoiceAction.decide => Icons.balance,
      ChoiceAction.pay => Icons.paid_outlined,
      ChoiceAction.sneak => Icons.visibility_off_outlined,
      ChoiceAction.attempt => Icons.casino_outlined,
      ChoiceAction.evade => Icons.directions_run,
      _ => step.glyph.icon,
    };
  }

  /// A hub's rings, in the order of the chips: a fight, a talk or a
  /// decision, a check or a payment.
  static const _ringOrder = [
    ChoiceGroup.fight,
    ChoiceGroup.talkDecide,
    ChoiceGroup.checksPay,
  ];

  Color _groupColor(ChoiceGroup g, InkColors ink) => switch (g) {
        ChoiceGroup.fight => ink.blood,
        ChoiceGroup.talkDecide => ink.tide,
        ChoiceGroup.checksPay => ink.voidColor,
        ChoiceGroup.go => ink.ash,
      };

  /// The steps of ring [id] (a [ChoiceGroup]'s name, or 'ways' for the pins),
  /// by their place in the list of steps.
  List<int> _ringSteps(List<_Step> steps, String id) => [
        for (var i = 0; i < steps.length; i++)
          if (id == 'ways'
              ? !steps[i].onCard
              : steps[i].onCard && steps[i].tags.group.name == id)
            i,
      ];

  /// The rings of a hub: one for each kind with choices, with their icons.
  List<ChoiceRing> _rings(List<_Step> steps, InkColors ink) => [
        for (final g in _ringOrder)
          if (_ringSteps(steps, g.name).isNotEmpty)
            ChoiceRing(
              id: g.name,
              label: tr(ref, 'choice_group_${g.name}'),
              count: _ringSteps(steps, g.name).length,
              color: _groupColor(g, ink),
              icons: [
                for (final i in _ringSteps(steps, g.name)) _iconOf(steps[i]),
              ],
            ),
      ];

  bool _isHub(List<_Step> steps) =>
      steps.where((s) => s.onCard).length > _hubCards;

  /// The panel under the map in a place (design 1 of
  /// docs/proposals/inplace-choices.md): every choice acted out here is a
  /// card, the pin picked (if one is) leading with its own detail. A hub
  /// (design 3) shows a chip for each ring instead, and a "Ways" chip for
  /// the pins: a tap opens that list.
  Widget _choicePanel(
      List<_Step> steps, _Step? selected, bool french, StoryData story) {
    final ink = InkColors.of(context);
    final palette = ChartPalette.of(ref.watch(mapLookProvider));
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value;
    final hub = _isHub(steps);
    return ListView(
      key: const ValueKey('journey_choice_cards'),
      padding: EdgeInsets.zero,
      children: [
        if (selected != null && !selected.onCard) ...[
          _StepDetail(
            step: selected,
            busy: _busy,
            french: french,
            isExcursion: false,
            onGo: () => _take(_selected!, selected),
          ),
          const SizedBox(height: 6),
        ],
        if (hub) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ring in _rings(steps, ink))
                ChoiceGroupChip(
                  key: ValueKey('choice_chip_${ring.id}'),
                  label: ring.label,
                  count: ring.count,
                  color: ring.color,
                  onTap: () => _openList(ring.id, steps, french, story),
                ),
              if (_ringSteps(steps, 'ways').isNotEmpty)
                ChoiceGroupChip(
                  key: const ValueKey('choice_chip_ways'),
                  label: tr(ref, 'choice_ways_chip'),
                  count: _ringSteps(steps, 'ways').length,
                  color: Theme.of(context).colorScheme.onSurface,
                  onTap: () => _openList('ways', steps, french, story),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(tr(ref, 'choice_hub_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
          ),
        ] else
          for (var i = 0; i < steps.length; i++)
            if (steps[i].onCard)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _cardFor(i, steps[i], french, ink, palette, enemies,
                    identical(selected, steps[i])),
              ),
      ],
    );
  }

  /// Whether the map shows a banner for any of [steps] (not a card, not a
  /// round mark of a fight or a roll).
  bool _hasBannerPins(List<_Step> steps) => [
        for (final i in _pinIdx)
          if (i < steps.length &&
              journeyPinCatOf(steps[i].kind, steps[i].questTie) != null)
            i
      ].isNotEmpty;

  /// The key button at the map's top right: what the banners mean.
  Widget _legendButton(ChartPalette palette) => Positioned(
        right: 8,
        top: 8,
        child: _MapButton(
          key: const Key('journey_legend_key'),
          icon: Icons.vpn_key_outlined,
          tip: tr(ref, 'journey_legend_tip'),
          palette: palette,
          onTap: () => showJourneyLegend(context),
        ),
      );

  /// A ring's list (or the pins', "ways") in a sheet over the lower half of
  /// the screen: a tap picks a card (a pin lights its road on the map above)
  /// and a second tap does it. The ring stays lit on the map meanwhile.
  Future<void> _openList(
      String id, List<_Step> steps, bool french, StoryData story) async {
    if (_busy) return;
    setState(() => _ringOpen = id);
    final ink = InkColors.of(context);
    final palette = ChartPalette.of(ref.read(mapLookProvider));
    final enemies = ref.read(localizedDbProvider(enemiesSchema)).value;
    final title = id == 'ways'
        ? tr(ref, 'choice_ways_chip')
        : tr(ref, 'choice_group_$id');
    final members = _ringSteps(steps, id);
    final color = id == 'ways'
        ? Theme.of(context).colorScheme.onSurface
        : _groupColor(ChoiceGroup.values.firstWhere((g) => g.name == id), ink);
    final taken = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
      barrierColor: Colors.black26,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
                child: Row(
                  children: [
                    Icon(Icons.circle_outlined, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$title · ${members.length}',
                          style: Theme.of(sheet)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontFamily: InkFonts.display, color: color)),
                    ),
                    IconButton(
                      key: const ValueKey('choice_sheet_close'),
                      onPressed: () => Navigator.of(sheet).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final i in members)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _cardFor(
                          i,
                          steps[i],
                          french,
                          ink,
                          palette,
                          enemies,
                          _selected == i,
                          onTap: () {
                            if (_selected == i && !steps[i].locked) {
                              Navigator.of(sheet).pop(i);
                              return;
                            }
                            setState(() => _selected = i);
                            setSheet(() {});
                          },
                          onGo: () => Navigator.of(sheet).pop(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _ringOpen = null);
    if (taken != null && mounted && taken < steps.length) {
      _take(taken, steps[taken]);
    }
  }

  Widget _cardFor(int i, _Step step, bool french, InkColors ink,
      ChartPalette palette, Map<String, dynamic>? enemies, bool picked,
      {VoidCallback? onTap, VoidCallback? onGo}) {
    final choice = step.choice;
    final ids = choice.allTriggerEnemyIds;
    final roster =
        enemies == null || ids.isEmpty || ids.any((id) => id.startsWith('@'))
            ? null
            : enemyRoster(ids, enemies);
    final to = step.tags.destination;
    final cat = journeyPinCatOf(step.kind, step.questTie);
    return Opacity(
      // The choice taken stays lit; the others dim while it plays out.
      opacity: _busy && _pressed != null && _pressed != i ? 0.45 : 1,
      child: ChoiceCard(
        key: ValueKey('journey_choice_card_$i'),
        icon: step.onCard ? _iconOf(step) : step.glyph.icon,
        leading: step.onCard || cat == null
            ? null
            : BannerPin(
                cat: cat,
                color: cat.colorOn(ink,
                    dark: Theme.of(context).brightness == Brightness.dark),
                dark: Theme.of(context).brightness == Brightness.dark,
                scale: 0.8,
                lit: picked,
              ),
        // The card sits on the app's page, not on the map: the map's own pale
        // road colour would vanish on a light page.
        color: switch (step.kind) {
          JourneyStepKind.road =>
            Theme.of(context).colorScheme.onSurfaceVariant,
          JourneyStepKind.mainQuest => ink.gold,
          _ => _colorFor(step.kind, ink, palette, greyed: false),
        },
        text: step.label,
        notes: [
          if (roster != null && !step.locked)
            tr(ref, 'choice_fight_roster').replaceAll('{roster}', roster),
        ],
        leadsTo: to != null && !step.locked ? to.nameFor(french) : null,
        tag: step.locked ? null : _cardTag(step, ink),
        selected: picked,
        locked: step.locked,
        busy: _busy,
        goLabel: tr(ref, 'journey_go'),
        goKey: const ValueKey('journey_go'),
        onTap: _busy ? null : (onTap ?? () => _tap(i, step)),
        onGo: onGo ?? () => _take(i, step),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final play = ref.watch(storyPlayProvider);
    final session = ref.watch(playerSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final look = ref.watch(mapLookProvider);
    final palette = ChartPalette.of(look);
    final node = play.activeExcursionNode ?? story.nodeFor(play.currentNodeId);

    // Opened from another tab: the map unrolls.
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (next == journeyTabIndex && previous != journeyTabIndex) {
        setState(() => _unroll++);
      }
    });

    final sceneKey = _sceneKeyOf(play);
    final newScene = sceneKey != _sceneKey;
    if (newScene) {
      _sceneKey = sceneKey;
      _selected = null;
      _autoPickPending = true;
      _chartKey = GlobalKey();
      _outside = false;
    }

    final tools = [
      IconButton(
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        tooltip: tr(ref, 'journal_title'),
        visualDensity: VisualDensity.compact,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JournalScreen()),
        ),
      ),
    ];

    // In a city with a plan: the city plan, a page of its own, from which a
    // way is picked (it comes back selected on the map) or the party walks
    // to another district.
    if (ref.watch(currentCityProvider) != null &&
        !(ref.read(storyPlayProvider).isInExcursion)) {
      tools.add(IconButton(
        key: const ValueKey('journey_city_plan'),
        icon: const Icon(Icons.map_outlined, size: 20),
        tooltip: tr(ref, 'city_plan_tooltip'),
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          final picked = await Navigator.of(context).push<StoryChoice>(
            MaterialPageRoute(builder: (_) => const CityChartScreen()),
          );
          if (picked == null || !mounted) return;
          setState(() => _cityPick = picked);
        },
      ));
    }

    if (node == null) {
      return _EndedPanel(
        title: tr(ref, 'trail_cold_title'),
        message: tr(ref, 'trail_cold_message'),
      );
    }

    final detour = !play.isInExcursion
        ? null
        : [
            switch (play.excursionOriginFor(french)) {
              null => tr(ref, 'detour'),
              final origin => '${tr(ref, 'detour_on_the_way')} “$origin”',
            },
            if (node.contextNoteFor(french) case final note?) note,
          ].join(' ');

    // Read full screen, the scene has the tab to itself.
    if (_reading) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              Expanded(
                child: _ScenePanel(
                  key: ValueKey('journey_reading_$sceneKey'),
                  story: story,
                  node: node,
                  french: french,
                  folded: false,
                  reading: true,
                  onFold: (_) {},
                  onReading: _read,
                  detour: detour,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('journey_continue'),
                  onPressed: () => _read(false),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(tr(ref, 'journey_continue')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Where the party stands.
    final hereLandmark =
        play.isInExcursion ? null : landmarkOfScene(play.currentNodeId);
    final standing =
        currentLandmark(play.currentNodeId, play.history) ?? hereLandmark;
    final hereName = play.isInExcursion
        ? tr(ref, 'detour')
        : node.settlement?.nameFor(french) ?? standing?.name(language) ?? '';
    final chapter = chapterOfNode(play.currentNodeId);
    if (newScene) {
      // A place not shown before is stamped on the map; a new chapter
      // burns its map open. The first map the tab shows does neither.
      _stamp = _shownPlace != null &&
              !play.isInExcursion &&
              hereName.isNotEmpty &&
              hereName != _shownPlace
          ? hereName
          : null;
      _burn = _shownChapter != null && chapter != _shownChapter;
      if (!play.isInExcursion) _shownPlace = hereName;
      _shownChapter = chapter;
    }

    // Where the party stands in the world's places (v1.197): the place,
    // the lands above it, and its land's biome.
    final world = ref.watch(geographyProvider);
    final herePlace = play.isInExcursion
        ? null
        : world.placeOfNode(story.nodeFor(play.currentNodeId)) ??
            world.placeOfLandmark(standing?.id);
    final herePath = world.pathOf(herePlace?.id);
    BiomeHazard? hazardOn(StoryChoice choice) => roadHazardFor(
          world.roadBiome(story, play.currentNodeId, choice.nextId),
          fromNodeId: play.currentNodeId,
          toNodeId: choice.nextId,
          historyLength: play.history.length,
        );

    // The place up close, when the party stands at one the world chart
    // knows (not on a detour): where it is and what the ways out point at.
    final geography = chartOf(ref.watch(mapShapeProvider));
    final placeLandmark = play.isInExcursion ? null : standing;
    final chartHere =
        placeLandmark == null ? null : geography.of(placeLandmark);
    // The sky over the party (v1.204): what falls on the map, and the
    // ground's climate the town is laid out for.
    final skyHere = ref.watch(skyHereProvider);
    final sky = skyHere?.today();
    // A choice behind a politics gate that fails (v1.196) is hidden, or
    // shut with its locked text.
    final gateWorld = ref.watch(coastGateWorldProvider);
    final choices = node.choices
        .where((c) => !choiceHiddenFor(c, session, gateWorld))
        .toList();
    final ended = choices.isEmpty || isStoryEnding(node);
    final mainQuestOpen =
        ref.watch(chapterProgressProvider)?.mainQuestOpen ?? true;
    // A choice acted out where the party stands is a card under the map, not
    // a pin on it (v1.407): in a place up close, only the plain ways on keep
    // their marks, spread over the room the marks leave.
    final shapes = [
      for (final c in choices)
        choiceShape(node, c, story: story, geography: world),
    ];
    final slots = journeySlots(choices.length);
    // What waits on each road is known before the party sets out (see
    // road_events.dart); Edit Mode's roads hold nothing.
    final reached = ref.watch(reachedChapterProvider);
    final condition = ref.watch(chapterConditionProvider);
    final eventsOn =
        !play.isInExcursion && ref.watch(appModeProvider) != AppMode.edit;
    // The scene each way really lands on (v1.224): the plain scenes the
    // story reads straight through are passed on the way, so the party
    // walks to where the last of them is, and the map never jumps.
    final reading = ref.watch(appModeProvider) != AppMode.edit;
    final mainQuestIds = mainQuestIdsOf(
        ref.watch(localizedDbProvider(questsSchema)).value ?? const {});
    String endOf(StoryChoice c) => play.isInExcursion || c.isEnding || !reading
        ? c.nextId
        : readThroughEnd(
            c.nextId,
            nodeFor: story.nodeFor,
            flags: session.flags,
            hidden: (x, held) => choiceHiddenFor(
                x, session.copyWith(flags: held.toList()), gateWorld),
            travels: (from, to) => world.travelsBetween(story, from, to),
            blocked: (x, held) => isStoryChoiceLocked(
                x, story, session.copyWith(flags: held.toList()),
                world: gateWorld),
          );
    // Once per build: every use below reads the same scene.
    final ends = {for (final c in choices) c: endOf(c)};
    final rawSteps = [
      for (var i = 0; i < choices.length; i++)
        () {
          final choice = choices[i];
          final shut =
              choice.mainQuest && !play.isInExcursion && !mainQuestOpen;
          // A detour's payment the purse can't make is shut here as under
          // the story (see isStoryChoiceLocked), and says why.
          final locked = shut ||
              isStoryChoiceLocked(choice, story, session,
                  isExcursion: play.isInExcursion, world: gateWorld);
          final lockedText = locked
              ? storyChoiceLockedText(ref, choice, session,
                  isExcursion: play.isInExcursion,
                  french: french,
                  mainQuestShut: shut)
              : null;
          final target = play.isInExcursion || choice.isEnding
              ? null
              : landmarkOfScene(ends[choice]!);
          // A way to another landmark points out of the square; only one
          // that leaves the location (the city, not one of its districts)
          // is a journey over the world chart (v1.197).
          final elsewhere = target != null && target.id != standing?.id;
          final travels = elsewhere &&
              world.travelsBetween(story, play.currentNodeId, choice.nextId);
          // The roads and stops that way takes over the world chart.
          final route = travels && standing != null
              ? chartRoadsBetween(geography, standing.id, target.id, language)
              : null;
          return _Step(
            choice: choice,
            kind: journeyStepKindOf(choice),
            slot: slots[i],
            label: (lockedText?.isNotEmpty ?? false)
                ? lockedText!
                : choice.textFor(french),
            locked: locked,
            leadsTo: target != null && target.id != standing?.id
                ? target.name(language)
                : null,
            onwardKinds: play.isInExcursion || choice.isEnding
                ? const []
                : <JourneyStepKind>{
                    for (final next in story.nodeFor(ends[choice]!)?.choices ??
                        const <StoryChoice>[])
                      if (!choiceHiddenFor(next, session, gateWorld))
                        journeyStepKindOf(next),
                  }.take(3).toList(),
            event: !eventsOn || locked || choice.isEnding
                ? null
                : roadEventFor(
                    story: story,
                    fromNodeId: play.currentNodeId,
                    toNodeId: choice.nextId,
                    historyLength: play.history.length,
                    chapter: reached,
                    oddsFactor: (condition?.roadEventOdds ?? 1) *
                        WeatherEffects.of(skyHere?.today().kind).roadOdds,
                    championShare: condition?.championShare ?? 0.4,
                    shrineShare: condition?.shrineShare ?? 0.3,
                    hazardShare: hazardShareFor(world.roadBiome(
                        story, play.currentNodeId, choice.nextId)),
                    world: world,
                  ),
            hazard: hazardOn(choice),
            // A way out leaves by the first stop of its road (v1.256), not
            // straight at where it ends.
            bearing: chartHere != null && elsewhere
                ? ((route != null && route.points.length > 1
                            ? route.points[1]
                            : geography.of(target)) -
                        chartHere)
                    .direction
                : null,
            chartTarget:
                chartHere != null && travels ? geography.of(target) : null,
            targetLandmark: travels ? target.id : null,
            route: route,
            questTie: journeyQuestTieOf(
              choice,
              active: {...session.activeQuestIds},
              done: {...session.completedQuestIds},
              mainIds: mainQuestIds,
            ),
          );
        }(),
    ];
    final discovered =
        discoveredLandmarkIds([...play.history, play.currentNodeId]);
    // The place drawn up close is the location (v1.197): a city keeps
    // the one plan and look from district to district, so only a journey
    // changes the map.
    final hereLocation = world.locationOf(herePlace?.id);
    // The city's plan (v1.203): a city, a town or a village of the
    // geography is drawn as one, its districts on it; the roads out to the
    // nearest other places give it its gates.
    CityPlan? plan;
    final districtOfStep = <int, String>{};
    final citySize = switch (hereLocation?.kind) {
      'city' => CitySize.city,
      'town' => CitySize.town,
      'village' => CitySize.village,
      _ => null,
    };
    if (hereLocation != null && citySize != null && chartHere != null) {
      final others = [
        for (final l in worldMapLandmarks)
          if (world.locationOf(world.placeOfLandmark(l.id)?.id)?.id !=
              hereLocation.id)
            geography.of(l),
      ]..sort((a, b) => (a - chartHere)
          .distanceSquared
          .compareTo((b - chartHere).distanceSquared));
      plan = CityPlan.of(
        seed: _stableSeed(hereLocation.id),
        size: citySize,
        water: hereLocation.water,
        districts: [
          for (final d in world.childrenOf(hereLocation.id))
            if (d.level == GeoLevel.district) CityDistrict(d.id, d.glyph),
        ],
        exitBearings: [
          for (final p in others.take(3)) (p - chartHere).direction,
        ],
        climate: skyHere == null ? null : CityClimate.of(skyHere.ground),
      );
      for (var i = 0; i < choices.length; i++) {
        final place = world.placeOfNode(story.nodeFor(ends[choices[i]]!));
        if (place == null || place.id == herePlace?.id) continue;
        if (world.locationOf(place.id)?.id != hereLocation.id) continue;
        districtOfStep[i] = place.level == GeoLevel.district ? place.id : '';
      }
    }
    // The city's stored plan (Core's city_plans.json, board 15): the plan
    // the ways are laid on and the chart drawn under them.
    PlacePlan? cityPlan = plan;
    final cityDistrictOf = <int, String>{};
    final hereDistrictOf = ref.watch(partyDistrictProvider);
    CityChart? cityChart;
    Set<String>? foundDistricts;
    // A scene inside a building (the Blind Beggar) keeps its room; looking
    // out of it shows the city's chart, with a button back in (v1.425).
    if (plan != null && hereLocation != null) {
      final record = ref.watch(cityPlanRecordsProvider).value?[hereLocation.id];
      if (record != null) {
        cityPlan = record;
        // Each way is pinned in its district; one that leaves the city
        // stands where the party does.
        final ownDistrict = record.districts.containsKey(hereDistrictOf)
            ? hereDistrictOf
            : null;
        for (var i = 0; i < rawSteps.length; i++) {
          final d = districtOfStep[i];
          final pinned = d != null && record.districts.containsKey(d)
              ? d
              : ownDistrict ?? record.districts.keys.first;
          cityDistrictOf[i] = pinned;
        }
        final key = [
          hereLocation.id,
          french,
          play.currentNodeId,
          for (final e in cityDistrictOf.entries)
            '${e.key}:${e.value}:${rawSteps[e.key].choice.nextId}',
        ].join('|');
        if (key != _cityChartKey || _cityChart == null) {
          _cityChartKey = key;
          _cityChart = CityChart.fromRecord(
            record,
            districtNames: {
              for (final d in world.childrenOf(hereLocation.id))
                if (d.level == GeoLevel.district) d.id: d.nameFor(french),
            },
            ways: [
              for (final e in cityDistrictOf.entries)
                CityWayInput(
                  id: '${e.key}',
                  districtId: e.value,
                  kind: _cityWayKindOf(rawSteps[e.key].kind),
                  name: rawSteps[e.key].label,
                  sceneId: rawSteps[e.key].choice.nextId,
                ),
            ],
            french: french,
            name: hereLocation.nameFor(french),
          );
        }
        cityChart = _cityChart;
        foundDistricts = ref.watch(foundDistrictsProvider);
      }
    }
    // Inside a building (v1.207): the room's plan, the party at its spot
    // and each way at the spot it is taken from, or at the door it leaves
    // by; the streets are one look out.
    final hereBuilding = herePlace?.isBuilding == true ? herePlace : null;
    _sceneInside = hereBuilding != null;
    RoomPlan? room;
    var hereSpot = '';
    final leavesRoom = <int>{};
    if (hereBuilding != null && !_outside) {
      room = RoomPlan.of(
          seed: _stableSeed(hereBuilding.id),
          kind: RoomKind.resolve(hereBuilding.kind, hereBuilding.name));
      hereSpot = room.has(node.spot ?? '') ? node.spot! : 'floor';
      districtOfStep.clear();
      for (var i = 0; i < choices.length; i++) {
        final next = story.nodeFor(ends[choices[i]]!);
        final inside = world.placeOfNode(next)?.id == hereBuilding.id;
        final wanted = choices[i].spot ?? (inside ? next?.spot : null);
        if (!inside) leavesRoom.add(i);
        districtOfStep[i] = wanted != null && room.has(wanted)
            ? wanted
            : inside
                ? 'floor'
                : room.exitFrom(hereSpot);
      }
    }
    // The party's district on the streets: a building's is the district
    // it stands in.
    final hereDistrictId = room != null
        ? hereSpot
        : switch (herePlace?.level) {
            GeoLevel.district => herePlace!.id,
            GeoLevel.building =>
              world.place(herePlace!.parent)?.level == GeoLevel.district
                  ? herePlace.parent
                  : '',
            _ => '',
          };
    // Which ways carry the party somewhere (v1.224): in a place, a way to
    // another place, to another district or building of this one, or out of
    // a room by its door; on the road, a way on along it. Any other keeps
    // the party where it stands (a roll, a stall, a scuffle).
    final onRoad = placeLandmark == null || chartHere == null;
    bool carries(int i) {
      final step = rawSteps[i];
      if (onRoad) {
        return switch (step.kind) {
          JourneyStepKind.road ||
          JourneyStepKind.travel ||
          JourneyStepKind.mainQuest ||
          JourneyStepKind.expedition =>
            true,
          _ => false,
        };
      }
      if (step.bearing != null) return true;
      // In a room, a way to another spot of it, or out of the building by
      // a door (even from that very door: it leads to the street).
      return room != null
          ? leavesRoom.contains(i) ||
              (districtOfStep[i] != null && districtOfStep[i] != hereSpot)
          : districtOfStep.containsKey(i);
    }

    final steps = rawSteps;
    // A choice acted out where the party stands is a card under the map, not
    // a pin on it (v1.407): in a place up close, only the plain ways on keep
    // their marks, spread over the room the marks leave. A room's ways keep
    // theirs: each is a spot in it.
    // A written detour has no map: all its ways are cards under its scene.
    _writtenDetour = play.isInExcursion &&
        ref.read(storyPlayProvider.notifier).scenePlay != null;
    final cardsOn = _writtenDetour ||
        (!play.isInExcursion &&
            placeLandmark != null &&
            chartHere != null &&
            room == null);
    final onCard = [
      for (final s in shapes) cardsOn && (_writtenDetour || s.here),
    ];
    final pinSlots = journeySlots(onCard.where((c) => !c).length);
    var pinCount = 0;
    for (var i = 0; i < steps.length; i++) {
      steps[i].shape = shapes[i];
      steps[i].tags = choiceTags(node, steps[i].choice,
          story: story, geography: world, shape: shapes[i]);
      steps[i].onCard = onCard[i];
      if (!onCard[i] && onCard.contains(true)) {
        steps[i].slot = pinSlots[pinCount++];
      }
      // A card has no road to walk: the story's next scene carries the party.
      steps[i].moves = !onCard[i] && carries(i);
      steps[i].district = districtOfStep[i];
    }
    // The chart draws only the pins: the steps that are not cards, and where
    // they stand in the list.
    _pinIdx = [
      for (var i = 0; i < steps.length; i++)
        if (!steps[i].onCard) i,
    ];
    // A scene with one way on has its step picked already: one tap on Go.
    if (_autoPickPending) {
      _autoPickPending = false;
      if (steps.length == 1 && !steps.single.locked) _selected = 0;
    }
    if (_cityPick != null) {
      final i = steps.indexWhere((s) => identical(s.choice, _cityPick));
      if (i >= 0) _selected = i;
      _cityPick = null;
    }
    final selected = _selected != null && _selected! < steps.length
        ? steps[_selected!]
        : null;
    final placeView = placeLandmark == null || chartHere == null
        ? null
        : _PlaceView(
            kind: placeKindOf(
                hereLocation?.kind ?? _kindsFor(story)[placeLandmark.id],
                atSea: placeLandmark.atSea),
            seed: _stableSeed(hereLocation?.id ?? placeLandmark.id),
            geography: geography,
            chartHere: chartHere,
            biome: world.biomeOf(herePlace?.id),
            holderColor: holderTint(
                holderOf(herePlace?.id, world,
                    ref.watch(playerSessionProvider.select((s) => s.politics))),
                ref.watch(factionsProvider),
                ref.watch(
                    playerSessionProvider.select((s) => s.politics.nemesis))),
            water: herePlace?.water ?? '',
            plan: cityPlan,
            chart: cityChart,
            explored: foundDistricts,
            room: room,
            hereDistrict: hereDistrictId,
            districtOfStep: districtOfStep,
            glyphs: {
              for (var i = 0; i < choices.length; i++)
                if (world.placeOfNode(story.nodeFor(ends[choices[i]]!))?.glyph
                    case final glyph? when glyph.isNotEmpty)
                  i: glyph,
            },
            marks: [
              for (final landmark in worldMapLandmarks)
                if ((landmark.chapter - placeLandmark.chapter).abs() <= 1)
                  (
                    at: geography.of(landmark),
                    name: landmark.name(language),
                    known: discovered.contains(landmark.id),
                  ),
            ],
          );
    // A city plan to look at whole (not from inside a room).
    _canTown = placeView?.plan != null && placeView?.room == null;
    if (!_canTown) _townView = false;
    final townView = _townView && _canTown;
    // A city with Core's stored plan is drawn as board 15's district view
    // (not in a detour, nor from inside a room).
    final hostedCity =
        cityChart != null && placeView?.room == null && !play.isInExcursion;

    // Where the party stands on the world (v1.245): a scene the story
    // carried it to without a walk (a fight lost, a roll failed, the travel
    // list) is reached by the road from where it stood, and the map says why.
    if (newScene && !play.isInExcursion) {
      final to = placeView?.chartHere;
      // The editor's jumps are tools, not travel: no road walked for them.
      final editorJump = ref.read(appModeProvider) == AppMode.edit;
      if (to != null) {
        final from = _partyChart;
        final previousId = play.history.isEmpty ? null : play.history.last;
        final cause = partyMoveCause(story, previousId, play.currentNodeId);
        // The same city's plan (or the same room) is one place, whatever
        // the world chart says of its districts: the party travels its
        // streets, not the roads between places.
        final planKey = '${placeView!.room != null ? 'room' : 'city'}'
            '${placeView.seed}';
        final samePlan = _partyPlan == planKey;
        final far = !samePlan && from != null && (from - to).distance > 0.5;
        final forced =
            cause == PartyMoveCause.lost || cause == PartyMoveCause.failed;
        _transit =
            from != null && cause != null && (far || forced) && !editorJump
                ? _Transit(
                    from: from,
                    to: to,
                    fromName: _partyName,
                    toName: hereName,
                    flight: far,
                    route: far && _partyLandmark != null && standing != null
                        ? chartRoadsBetween(
                            geography, _partyLandmark!, standing.id, language)
                        : null,
                    forced: forced,
                    caption: partyMoveNote(
                            story, previousId, play.currentNodeId,
                            french: french) ??
                        tr(ref, 'journey_move_${cause.name}')
                            .replaceAll('{place}', hereName),
                  )
                : null;
        // Inside the place (v1.246): the party travels the streets, or the
        // room, from the district or spot it stood at.
        _arriveFrom = cause != null &&
                !far &&
                !editorJump &&
                samePlan &&
                _partyDistrict != placeView.hereDistrict
            ? _partyDistrict
            : null;
        _partyPlan = planKey;
        _partyDistrict = placeView.hereDistrict;
        _partyChart = to;
        _partyLandmark = standing?.id;
        _partyName = hereName;
      }
    }

    // The world under the fog (v1.199), framed on the party's land or
    // the whole of it.
    final journeyWalked = journeyOf(play.history, play.currentNodeId);
    // Edit Mode sees the world whole (v1.209): every place, no fog.
    final editing = ref.watch(appModeProvider) == AppMode.edit;
    final worldDiscovered = editing
        ? {for (final l in worldMapLandmarks) l.id}
        : {...discovered, if (standing != null) standing.id};
    Landmark? nextPlace;
    if (standing != null) {
      final index = worldMapLandmarks.indexOf(standing);
      for (var i = index + 1; i < worldMapLandmarks.length; i++) {
        if (!worldDiscovered.contains(worldMapLandmarks[i].id)) {
          nextPlace = worldMapLandmarks[i];
          break;
        }
      }
    }
    final worldMap = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: JourneyWorldMap(
        key: const ValueKey('journey_world_map'),
        level: _level,
        palette: palette,
        here: standing,
        discovered: worldDiscovered,
        legs: roadLegs(journeyWalked, worldDiscovered),
        ahead: nextPlace,
        shopPlaces: _shopsFor(story),
        campPlaces: {
          for (final entry in _kindsFor(story).entries)
            if (entry.value == 'camp') entry.key,
        },
        chapterColor: (n) => switch (look) {
          MapLook.night => mapChapter(n).dark,
          MapLook.parchment => mapChapter(n).light,
          MapLook.shroud => const Color(0xFFA3A3AA),
        },
        onLayers: _showCalques,
        onSelect: (landmark) => setState(() => _lookedAt = landmark),
        onZoomIn: _arriveAtStreets,
        enterZoom: _enterZoom,
        onFullMap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FullMapScreen()),
        ),
        fog: editing ? ChartFog.none : ChartFog.uncharted,
      ),
    );

    final travelsFromHere = !play.isInExcursion &&
        canReturnToCampFrom(node,
            inExcursion: play.isInExcursion, flags: session.flags);
    final travelsOn = travelsFromHere &&
        ref.watch(knownPlacesProvider).any((p) => p.id != node.id);

    final levelTabs = _LevelTabs(
      selected: _level != JourneyMapLevel.place
          ? _LevelTab.world
          : townView
              ? _LevelTab.town
              : _LevelTab.district,
      townEnabled: _canTown || _level != JourneyMapLevel.place,
      busy: _busy,
      palette: palette,
      onPick: _goLevel,
    );
    final cityView = hostedCity && !ended
        ? _CityDistrictView(
            chart: cityChart,
            look: look,
            explored: ref.watch(foundDistrictsProvider),
            hereDistrict: ref.watch(partyDistrictProvider),
            focus: townView
                ? null
                // A district looked at in another city (the story moved
                // on) gives way to the party's own.
                : (cityChart.districts.any((d) => d.id == _cityFocus)
                        ? _cityFocus
                        : null) ??
                    ref.watch(partyDistrictProvider),
            focusToken: _cityFocusToken,
            steps: steps,
            districtOf: cityDistrictOf,
            palette: palette,
            text: _cityText(),
            onFocus: (d) {
              if (d == null) {
                if (!_townView) _setTown(true);
              } else if (_townView || _cityFocus != d) {
                setState(() {
                  _townView = false;
                  _cityFocus = d;
                });
              }
            },
            onOpen: (i) => _openWay(i, steps, french),
            onWalk: (d) {
              setState(() => _cityFocus = d);
              walkToDistrict(ref, d);
              _setTown(false);
            },
            overlays: [
              Positioned(
                left: 8,
                right: 56,
                bottom: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: IgnorePointer(
                    ignoring: MediaQuery.sizeOf(context).width >= 340,
                    child: WeatherChip(
                        palette: palette,
                        compact: MediaQuery.sizeOf(context).width < 340),
                  ),
                ),
              ),
              if (townView)
                Positioned(
                  right: 8,
                  bottom: 48,
                  child: _MapButton(
                    key: const Key('journey_town_zoom_in'),
                    icon: Icons.add,
                    tip: tr(ref, 'journey_tab_district'),
                    palette: palette,
                    onTap: _busy ? null : () => _goLevel(_LevelTab.district),
                  ),
                ),
              // A scene inside a building keeps its room: looking out at the
              // city chart, the way back in is a button (v1.425).
              if (_sceneInside && _outside)
                Positioned(
                  right: 8,
                  bottom: townView ? 88 : 48,
                  child: _MapButton(
                    key: const Key('journey_go_inside'),
                    icon: Icons.login,
                    tip: tr(ref, 'journey_go_inside'),
                    palette: palette,
                    onTap: _busy ? null : _goInside,
                  ),
                ),
              if (_hasBannerPins(steps)) _legendButton(palette),
              Positioned(
                right: 8,
                bottom: 8,
                child: _MapButton(
                  key: const Key('journey_place_zoom_out'),
                  icon: Icons.remove,
                  tip: tr(ref, 'journey_look_out'),
                  palette: palette,
                  onTap: _busy ? null : () => _lookOut(),
                ),
              ),
            ],
            tabs: levelTabs,
          )
        : null;

    // A written detour plays over a scene of its own, not over the map
    // (see detour_scene_band.dart).
    final detourPlay = play.isInExcursion
        ? ref.read(storyPlayProvider.notifier).scenePlay
        : null;
    final map = ended
        ? _EndedPanel(
            title: tr(ref, 'the_end'),
            message: tr(ref, 'journey_ended'),
          )
        : detourPlay != null
            ? DetourSceneBand(
                scene: detourPlay.scene,
                beat: detourPlay.nodes
                    .indexWhere((n) => n.id == play.activeExcursionNode?.id),
                french: french,
                detourLabel: tr(ref, 'detour'),
                text: node.descriptionFor(french),
                note: node.contextNoteFor(french) ?? '',
              )
            : TutorialTarget(
                id: 'journey.chart',
                // Going into a fight the map jolts and its edges run red (see
                // _take).
                child: AnimatedBuilder(
                  animation: _jolt,
                  builder: (context, child) {
                    final t = _jolt.value;
                    if (t == 0 || t == 1) return child!;
                    final shake = math.sin(t * math.pi * 7) * 6 * (1 - t);
                    return Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Transform.translate(
                          offset: Offset(shake, shake * 0.4),
                          child: child,
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: JourneyJoltPainter(
                                t: t,
                                colour: InkColors.dark.blood,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  child: cityView ??
                      Stack(
                        fit: StackFit.passthrough,
                        children: [
                          // A pinch in on the streets looks out at the land
                          // (v1.201: the levels are zoomed between).
                          GestureDetector(
                            onScaleStart: (_) => _pinch = 1,
                            onScaleUpdate: (d) {
                              if (d.pointerCount > 1 && !_busy) {
                                setState(() {
                                  _pinching = true;
                                  _pinch = d.scale.clamp(0.35,
                                      _sceneInside && _outside ? 1.6 : 1.0);
                                });
                              }
                            },
                            onScaleEnd: (_) {
                              if (_pinching && _pinch < 0.8) {
                                _lookOut(from: _pinch);
                              } else if (_pinching &&
                                  _pinch > 1.2 &&
                                  _sceneInside &&
                                  _outside) {
                                _goInside();
                              } else if (_pinching) {
                                setState(() {
                                  _pinch = 1;
                                  _pinching = false;
                                });
                              }
                            },
                            child: AnimatedBuilder(
                              animation: _arrive,
                              builder: (context, child) {
                                final scale = _pinching
                                    ? _pinch
                                    : Tween<double>(begin: 0.55, end: 1.0)
                                        .transform(Curves.easeOutCubic
                                            .transform(_arrive.value));
                                return Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: child,
                                );
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: _JourneyChart(
                                  key: _chartKey,
                                  // Looking out at the streets from inside, the
                                  // ways stay in the room.
                                  steps: _sceneInside && _outside
                                      ? const []
                                      : [for (final i in _pinIdx) steps[i]],
                                  selected: _sceneInside && _outside
                                      ? null
                                      : !_pinIdx.contains(_selected)
                                          ? null
                                          : _pinIdx.indexOf(_selected!),
                                  hereName: hereName,
                                  youAreHere: tr(ref, 'journey_you_are_here'),
                                  leadsTo: tr(ref, 'journey_leads_to'),
                                  palette: palette,
                                  ink: look == MapLook.parchment
                                      ? InkColors.light
                                      : InkColors.dark,
                                  greyed: look == MapLook.shroud,
                                  terrainShift: _terrainShift,
                                  terrainSeed: 7 +
                                      chapterOfNode(play.currentNodeId) * 13,
                                  onTap: (j, step) => _tap(_pinIdx[j], step),
                                  stamp: _stamp,
                                  burn: _burn,
                                  unroll: _unroll,
                                  weather: journeyWeatherOf(sky?.kind, chapter),
                                  stepIds: _pinIdx,
                                  rings: placeView != null && _isHub(steps)
                                      ? _rings(
                                          steps,
                                          look == MapLook.parchment
                                              ? InkColors.light
                                              : InkColors.dark)
                                      : const [],
                                  ringLit: _ringOpen,
                                  onRing: (id) =>
                                      _openList(id, steps, french, story),
                                  place: placeView?.pinned(_pinIdx),
                                  arriveFrom: _arriveFrom,
                                  townView: townView,
                                ),
                              ),
                            ),
                          ),
                          // The sky over the party (v1.204).
                          // Clear of the zoom buttons: a long line wraps, it is not
                          // cut off under them.
                          Positioned(
                            left: 8,
                            right: 56,
                            bottom: 8,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              // A narrow screen (320 px) has no room for the line
                              // beside the zoom buttons: the icon, the line on a tap.
                              child: IgnorePointer(
                                // The full line is only to read: a mark under it takes
                                // the tap (the icon alone, on a narrow screen, is a
                                // button).
                                ignoring:
                                    MediaQuery.sizeOf(context).width >= 340,
                                child: WeatherChip(
                                    palette: palette,
                                    compact:
                                        MediaQuery.sizeOf(context).width < 340),
                              ),
                            ),
                          ),
                          if (_sceneInside && _outside)
                            Positioned(
                              right: 8,
                              bottom: 56,
                              child: _MapButton(
                                key: const Key('journey_go_inside'),
                                icon: Icons.add,
                                tip: tr(ref, 'journey_go_inside'),
                                palette: palette,
                                onTap: _busy ? null : _goInside,
                              ),
                            ),
                          if (townView)
                            Positioned(
                              right: 8,
                              bottom: 48,
                              child: _MapButton(
                                key: const Key('journey_town_zoom_in'),
                                icon: Icons.add,
                                tip: tr(ref, 'journey_tab_district'),
                                palette: palette,
                                onTap: _busy
                                    ? null
                                    : () => _goLevel(_LevelTab.district),
                              ),
                            ),
                          if (_hasBannerPins(steps)) _legendButton(palette),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: _MapButton(
                              key: const Key('journey_place_zoom_out'),
                              icon: Icons.remove,
                              tip: tr(ref, 'journey_look_out'),
                              palette: palette,
                              onTap: _busy ? null : () => _lookOut(),
                            ),
                          ),
                        ],
                      ),
                ),
              );

    // The guide shows the tab around the first time it opens (see
    // TutorialTopic.journey), once there is a character to follow.
    return TutorialTrigger(
      topic: TutorialTopic.journey,
      ready: session.raceId.isNotEmpty,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerStatsBar(trailing: tools),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(builder: (context, area) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        // The map keeps room enough to find the party and
                        // its ways on a short phone: the scene gives way
                        // to it (see _mapMin), and a step's long details
                        // scroll under it.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Where the party stands, over the place's map
                            // (v1.197): each land a tap from This land; and
                            // Read, the scene full screen (v1.199: the
                            // scene no longer sits over the map).
                            if (!ended)
                              Row(
                                children: [
                                  Expanded(
                                    child: placeView != null &&
                                            herePath.isNotEmpty
                                        ? GeoBreadcrumb(
                                            key: const ValueKey(
                                                'journey_crumbs'),
                                            path: herePath,
                                            french: french,
                                            tooltip:
                                                tr(ref, 'geo_where_you_are'),
                                            onTap: (place) =>
                                                showThisLand(context, place.id),
                                          )
                                        : const SizedBox(
                                            height: GeoBreadcrumb.height),
                                  ),
                                  // The followed quest and the goal it waits
                                  // on (v1.201), a small button here since
                                  // v1.213: the map keeps the room.
                                  if (!_reading)
                                    const QuestTrackerBar(compact: true),
                                  TutorialTarget(
                                    id: 'journey.scene',
                                    child: TextButton.icon(
                                      key: const ValueKey('journey_read'),
                                      onPressed:
                                          _busy ? null : () => _read(true),
                                      icon: const Icon(
                                          Icons.chrome_reader_mode_outlined,
                                          size: 18),
                                      label: Text(tr(ref, 'journey_read')),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _level == JourneyMapLevel.place ||
                                            ended
                                        ? Stack(
                                            children: [
                                              Positioned.fill(child: map),
                                              if (_transit != null &&
                                                  placeView != null &&
                                                  !ended)
                                                Positioned.fill(
                                                  child: _PartyTransit(
                                                    key: ValueKey(
                                                        'journey_transit_$sceneKey'),
                                                    transit: _transit!,
                                                    geography:
                                                        placeView.geography,
                                                    marks: placeView.marks,
                                                    palette: palette,
                                                    passText: tr(ref,
                                                        'journey_pass_stop'),
                                                    onDone: () {
                                                      if (mounted) {
                                                        setState(() =>
                                                            _transit = null);
                                                      }
                                                    },
                                                  ),
                                                ),
                                            ],
                                          )
                                        : worldMap,
                                  ),
                                  // The level tabs under the map (v1.350), not
                                  // over it: a mark scrolled to the foot would
                                  // sit under them.
                                  if (!ended &&
                                      !_writtenDetour &&
                                      !(cityView != null &&
                                          _level == JourneyMapLevel.place))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: levelTabs,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Under the map (v1.201): once the camp
                            // stands, the way back to it from a place, and
                            // on to the other places known.
                            if (!ended && travelsFromHere) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Expanded(child: CampReturnButton()),
                                  if (travelsOn) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      key: const Key('place_travel_on'),
                                      style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact),
                                      onPressed: () => _showTravelOn(node.id),
                                      icon: const Icon(Icons.signpost_outlined,
                                          size: 18),
                                      label: Text(tr(ref, 'travel_on_button')),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!ended) ...[
                        // A timed scene's clock (see TimedChoiceBar), the
                        // one the Story tab shows too.
                        if (node.isTimed &&
                            !play.isInExcursion &&
                            ref.watch(appModeProvider) != AppMode.edit)
                          TimedChoiceBar(
                            key: ValueKey(
                                'journey_timer_${node.id}_${play.history.length}'),
                            scene: timedSceneKey(node.id, play.history.length),
                            seconds: node.timeLimit!,
                            active: !_busy &&
                                ref.watch(homeTabIndexProvider) ==
                                    journeyTabIndex,
                            label: tr(ref, 'timed_choice_hint'),
                            onTimeout: () {
                              final way = node.timeoutChoiceOrNull!;
                              final index = steps
                                  .indexWhere((s) => identical(s.choice, way));
                              if (index >= 0) _take(index, steps[index]);
                            },
                          ),
                        // The ways are rows under the map in a city drawn
                        // as board 15's chart: no panel under them.
                        if (!(cityView != null &&
                            _level == JourneyMapLevel.place)) ...[
                          const SizedBox(height: 10),
                          TutorialTarget(
                            id: 'journey.pick',
                            // A fixed height (v1.210): a way picked, or a
                            // place looked at, fills the panel without
                            // changing the map's height, so no mark moves.
                            child: SizedBox(
                              height: _panelHeight(area.maxHeight, steps),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          _panelHeight(area.maxHeight, steps)),
                                  child: _level == JourneyMapLevel.place &&
                                          steps.any((s) => s.onCard)
                                      ? _choicePanel(
                                          steps, selected, french, story)
                                      : _level == JourneyMapLevel.place
                                          ? _StepDetail(
                                              step: selected,
                                              busy: _busy,
                                              french: french,
                                              isExcursion: play.isInExcursion,
                                              onGo: selected == null
                                                  ? null
                                                  : () => _take(
                                                      _selected!, selected),
                                            )
                                          : _LookedAtPanel(
                                              landmark: _lookedAt,
                                              language: language,
                                            ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A road the party is carried along (v1.245): from where it stood to the
/// place the story set it down, with a few words on why.
class _Transit {
  const _Transit({
    required this.from,
    required this.to,
    required this.fromName,
    required this.toName,
    required this.flight,
    required this.forced,
    required this.caption,
    this.route,
  });

  /// The two places on the world chart.
  final Offset from;
  final Offset to;
  final String fromName;
  final String toName;

  /// Whether the places differ, so there is a road to draw; else only the
  /// words are told.
  final bool flight;

  /// Whether the story took the party there against its pick (a lost fight,
  /// a failed roll), not a journey the player started.
  final bool forced;
  final String caption;

  /// The roads and named stops between the two places (v1.254), when the
  /// world's roads lead there.
  final ChartRoute? route;

  /// How long the walk takes: longer for a road with more to pass.
  Duration get duration => Duration(
      milliseconds: flight
          ? math.min(5000, 2400 + 400 * (route?.stops.length ?? 0))
          : 2000);
}

/// The [_Transit] over the map: the world chart with the party walking the
/// road, and the caption under it. A tap skips it; with reduced motion only
/// the caption shows, a few seconds.
class _PartyTransit extends StatefulWidget {
  const _PartyTransit({
    super.key,
    required this.transit,
    required this.geography,
    required this.marks,
    required this.palette,
    required this.passText,
    required this.onDone,
  });

  final _Transit transit;
  final ChartGeography geography;
  final List<ChartMark> marks;
  final ChartPalette palette;

  /// "You pass {stop}.", the words said of the stop the party has reached.
  final String passText;
  final VoidCallback onDone;

  @override
  State<_PartyTransit> createState() => _PartyTransitState();
}

class _PartyTransitState extends State<_PartyTransit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.transit.duration,
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transit = widget.transit;
    final still = MediaQuery.of(context).disableAnimations;
    final scheme = Theme.of(context).colorScheme;
    void skip() {
      _c.stop();
      widget.onDone();
    }

    final road = transit.flight && !still;
    return ClipRRect(
      key: const ValueKey('journey_transit'),
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The road over the whole map takes a tap to skip; a few words
          // alone (the party moved inside its place) leave the map to be
          // played with, and the map shows the move.
          if (road)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: skip,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: RegionFlightPainter(
                    geography: widget.geography,
                    from: transit.from,
                    to: transit.to,
                    marks: widget.marks,
                    t: Curves.easeInOut.transform(_c.value),
                    palette: widget.palette,
                    fromName: transit.fromName,
                    toName: transit.toName,
                    route: transit.route,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: skip,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.94),
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          transit.forced
                              ? Icons.warning_amber_rounded
                              : Icons.directions_walk,
                          size: 18,
                          color: transit.forced
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transit.caption,
                                key: const ValueKey('journey_transit_caption'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              // The stop the party has just passed on the
                              // way there (v1.254).
                              if (road && transit.route != null)
                                AnimatedBuilder(
                                  animation: _c,
                                  builder: (context, _) {
                                    final stop = transit.route!.passed(
                                        RegionFlightPainter.walkAt(Curves
                                            .easeInOut
                                            .transform(_c.value)));
                                    if (stop == null) return const SizedBox();
                                    return Text(
                                      widget.passText
                                          .replaceAll('{stop}', stop.name),
                                      key: const ValueKey(
                                          'journey_transit_stop'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: scheme.onSurfaceVariant),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scene the story is on, as the Story tab tells it: what the last
/// fight or roll left behind, who speaks, and the scene itself. A
/// double-tap reads it full screen, as in the Story tab, and another
/// brings the map back.
class _ScenePanel extends ConsumerWidget {
  const _ScenePanel({
    super.key,
    required this.story,
    required this.node,
    required this.french,
    required this.folded,
    required this.reading,
    required this.onFold,
    required this.onReading,
    this.detour,
  });

  final StoryData story;
  final StoryNode node;
  final bool french;

  /// Folded to its first lines, to leave the map the room.
  final bool folded;
  final ValueChanged<bool> onFold;

  /// Read full screen.
  final bool reading;
  final ValueChanged<bool> onReading;

  /// On a detour: what it is met on the way to, and why.
  final String? detour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final aftermath = ref.watch(pendingAftermathProvider);
    final outcome = ref.watch(pendingCheckOutcomeProvider);
    final roadNote = ref.watch(pendingRoadNoteProvider);
    // Plain scenes read on the way here open this one (see
    // scene_flow.dart); lines an earlier choice earned close it.
    final preludes = ref.watch(pendingPreludeProvider);
    final speaker = speakerLabelFor(node.speaker, french: french);
    final parts = composeNarrationParts(node, session, story, french: french);
    final text = parts.text;
    if (!folded) {
      noteShownEchoes(ref, session, [
        for (final prelude in preludes) ...prelude.echoes,
        ...parts.echoes,
      ]);
    }
    final prose = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: InkFonts.prose,
      fontSize: reading ? 17 : 15,
      height: reading ? 1.55 : 1.45,
    );
    final aside = prose?.copyWith(
      fontStyle: FontStyle.italic,
      color: ink.ash,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (detour != null && detour!.isNotEmpty) ...[
          Text(detour!, style: aside),
          const SizedBox(height: 8),
        ],
        if (aftermath != null && aftermath.isNotEmpty) ...[
          Text(aftermath, style: aside),
          const SizedBox(height: 8),
        ],
        if (roadNote != null && roadNote.isNotEmpty) ...[
          Text(roadNote, style: aside),
          const SizedBox(height: 8),
        ],
        if (outcome != null && outcome.isNotEmpty) ...[
          Text(outcome, style: aside),
          const SizedBox(height: 8),
        ],
        for (final prelude in preludes) ...[
          if (prelude.speaker != null) ...[
            Text(
              prelude.speaker!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: InkFonts.system,
                letterSpacing: 1.2,
                color: ink.gold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(prelude.body, style: prose),
          for (final echo in prelude.echoes) ...[
            const SizedBox(height: 10),
            EchoLine(
              key: ValueKey('journey_prelude_echo_${echo.key}'),
              echo: echo,
              caption:
                  tr(ref, 'echo_because').replaceAll('{choice}', echo.cause),
              colour: ink.gold,
              style: prose ?? const TextStyle(),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('⁂', style: aside),
            ),
          ),
        ],
        if (speaker != null) ...[
          Text(
            speaker.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: InkFonts.system,
              letterSpacing: 1.2,
              color: ink.gold,
            ),
          ),
          const SizedBox(height: 4),
        ],
        // A new scene's words come out of the ink, top to bottom.
        InkReveal(
          key: ValueKey(text),
          animate: !reading && !MediaQuery.of(context).disableAnimations,
          child: Text(text, style: prose),
        ),
        for (final echo in parts.echoes) ...[
          const SizedBox(height: 10),
          EchoLine(
            key: ValueKey('journey_echo_${echo.key}'),
            echo: echo,
            caption: tr(ref, 'echo_because').replaceAll('{choice}', echo.cause),
            colour: ink.gold,
            style: prose ?? const TextStyle(),
          ),
        ],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          if (folded)
            GestureDetector(
              key: const ValueKey('journey_scene_text'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onFold(false),
              onDoubleTap: () => onReading(true),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 80, 12),
                child: Text(
                  [
                    if (detour != null && detour!.isNotEmpty) detour!,
                    for (final prelude in preludes) prelude.text,
                    text,
                  ].join(' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: prose,
                ),
              ),
            )
          else
            LayoutBuilder(
              // Captured above the scroll view, which gives its child an
              // unbounded height: short scenes are centred in the full
              // screen when read that way.
              builder: (context, viewport) => GestureDetector(
                key: const ValueKey('journey_scene_text'),
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => onReading(!reading),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: reading
                        ? const EdgeInsets.fromLTRB(22, 20, 44, 20)
                        : const EdgeInsets.fromLTRB(14, 12, 40, 36),
                    child: reading
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight:
                                    math.max(0, viewport.maxHeight - 40)),
                            child: Center(child: body),
                          )
                        : body,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reading)
                  IconButton(
                    key: const ValueKey('journey_reading_exit'),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    tooltip: tr(ref, 'journey_reading_exit'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onReading(false),
                  )
                else ...[
                  if (folded)
                    IconButton(
                      key: const ValueKey('journey_scene_unfold'),
                      icon: const Icon(Icons.expand_more, size: 20),
                      tooltip: tr(ref, 'hub_story_unfold'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onFold(false),
                    ),
                ],
              ],
            ),
          ),
          if (!folded && !reading)
            Positioned(
              bottom: 2,
              right: 2,
              child: IconButton(
                key: const ValueKey('journey_scene_fold'),
                icon: const Icon(Icons.expand_less, size: 20),
                tooltip: tr(ref, 'hub_story_fold'),
                visualDensity: VisualDensity.compact,
                onPressed: () => onFold(true),
              ),
            ),
        ],
      ),
    );
  }
}

/// No way on from here on the map: the Story tab has the ending, New
/// Game+ and the way back to the beginning.
/// A small button over a map, in the chart's colours.
class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.icon,
    required this.tip,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String tip;
  final ChartPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tip,
      child: Material(
        color: palette.land.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.coast, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 20, color: palette.place),
          ),
        ),
      ),
    );
  }
}

class _LookedAtPanel extends ConsumerWidget {
  const _LookedAtPanel({required this.landmark, required this.language});

  final Landmark? landmark;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final landmark = this.landmark;
    if (landmark == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(ref, 'journey_level_hint'),
          key: const ValueKey('journey_level_hint'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
      );
    }
    return Container(
      key: ValueKey('journey_looked_${landmark.id}'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(landmark.name(language),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 4),
            Text(
              landmark.blurb(language),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontFamily: InkFonts.prose, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndedPanel extends ConsumerWidget {
  const _EndedPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const ValueKey('journey_open_story'),
              onPressed: () => openStoryReader(context, ref),
              icon: const Icon(Icons.menu_book),
              label: Text(tr(ref, 'journey_open_story')),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// The chart: the road ahead fanning out from where the party stands, one
/// step per way on, over a gentle relief. Many ways on (a town) stack in
/// rows up the map; the chapter's earlier scenes run down it below the
/// party. It opens on the party and scrolls both ways. Taking a step
/// walks the party's mark along its road while the map follows.
class _JourneyChart extends StatefulWidget {
  const _JourneyChart({
    super.key,
    required this.steps,
    required this.selected,
    required this.hereName,
    required this.youAreHere,
    required this.leadsTo,
    required this.palette,
    required this.ink,
    required this.greyed,
    required this.terrainShift,
    required this.terrainSeed,
    required this.onTap,
    this.stamp,
    this.burn = false,
    this.unroll = 0,
    this.weather = JourneyWeather.none,
    this.place,
    this.arriveFrom,
    this.townView = false,
    this.stepIds,
    this.rings = const [],
    this.ringLit,
    this.onRing,
  });

  /// A hub's rings round the party's mark (v1.419, see choice_rings.dart),
  /// the one whose list is open ([ringLit]), and a tap on one.
  final List<ChoiceRing> rings;
  final String? ringLit;
  final ValueChanged<String>? onRing;

  /// Where each of [steps] stands in the scene's list of ways, when the map
  /// draws only some of them (the others are cards): the marks keep the
  /// keys of their own way.
  final List<int>? stepIds;

  /// The whole town in view (v1.350: the step between a district and the
  /// world) instead of the district's close-up; the frame glides between.
  final bool townView;

  /// The district (or room spot) the party comes from when the story set it
  /// down here along no walk: its mark travels the plan from there.
  final String? arriveFrom;

  /// The place up close, when the party stands at one the world chart
  /// knows: the ways ring the party and the ways out point where they
  /// go. Null (a detour) keeps the road going up.
  final _PlaceView? place;

  /// A place reached that the map hadn't shown: its name is stamped.
  final String? stamp;

  /// A new chapter: the map burns open from the party's mark.
  final bool burn;

  /// Changes each time the tab is opened from another: the map unrolls.
  final int unroll;

  /// The chapter's weather (see journeyWeatherFor).
  final JourneyWeather weather;

  final List<_Step> steps;
  final int? selected;
  final String hereName;

  /// "You are here", over [hereName].
  final String youAreHere;

  /// "To {place}", under a step that leads somewhere else.
  final String leadsTo;

  final ChartPalette palette;
  final InkColors ink;
  final bool greyed;

  /// Where this scene's land lies (see _JourneyViewState._terrainShift).
  final Offset terrainShift;
  final int terrainSeed;
  final void Function(int index, _Step step) onTap;

  @override
  State<_JourneyChart> createState() => _JourneyChartState();
}

/// How many Journey maps have their clock running (v1.209): one while
/// something on the map moves (a map on its way out may still hold one),
/// none once it has settled. For tests.
@visibleForTesting
final ValueNotifier<int> debugJourneyMapsTicking = ValueNotifier(0);

/// How long the party takes to walk a road [length] logical pixels long
/// (v1.219): in a place, at a steady stroll (about 130 px a second, from a
/// second and a half to four and a quarter), so a long street no longer
/// flashes by; on the road up the map, the short walk it always was.
Duration journeyWalkDuration(double length, {required bool place}) => place
    ? Duration(milliseconds: (length * 7.5).round().clamp(1500, 4200))
    : const Duration(milliseconds: 950);

/// The most the place's map zooms in on a walking party.
const double journeyWalkZoom = 1.5;

/// The place's map zoom [t] of the way through a walk (v1.219): in over the
/// first fifth, held while the party strolls, out over the last fifth.
double journeyWalkZoomAt(double t) {
  final edge = math.min(t / 0.2, (1 - t) / 0.2).clamp(0.0, 1.0);
  return 1 + (journeyWalkZoom - 1) * edge * edge * (3 - 2 * edge);
}

class _JourneyChartState extends State<_JourneyChart>
    with TickerProviderStateMixin {
  static const double _stepRadius = 22;
  static const double _hereRadius = 26;
  static const double _top = 40;
  static const double _rowMin = 136;
  static const double _rowMax = 190;

  /// Room under the party's mark before the map's first screen ends: the
  /// scene just left shows there, and the road runs on down to the rest.
  static const double _hereBelow = 78;

  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  /// The beat at the party's mark when a choice done here is taken (see
  /// [playBeat]).
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Color _beatColor = const Color(0xFFFFFFFF);
  IconData _beatIcon = Icons.circle;

  /// A ring spreads from the party's mark in [colour] and [icon] rises from
  /// it, for half a second; completes at once when the map is not drawn or
  /// motion is reduced.
  Future<void> playBeat(Color colour, IconData icon) async {
    if (!mounted) return;
    _beatColor = colour;
    _beatIcon = icon;
    await _beat.forward(from: 0).orCancel.catchError((_) {});
  }

  /// The party's mark travelling the plan from [_JourneyChart.arriveFrom]
  /// to where it stands (v1.246); done (1) when there is nothing to show.
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  bool _arrivalStarted = false;

  /// How much of the town is in view: 0 the district's close-up, 1 the
  /// whole plan (see [_JourneyChart.townView]).
  late final AnimationController _town = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.townView ? 1 : 0,
  );

  /// Out of a place and along the world chart to the next (v1.181).
  /// The marks' glyphs breathing (see journey_glyph.dart): its own small
  /// clock, so the map itself still rests when nothing moves.
  late final AnimationController _idleGlyphs =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  int? _flying;

  bool get _placeMode => widget.place != null;

  /// The city's plan on the map (v1.203): canvas = origin + plan * scale.
  double? _planScale;
  double _planFitted = 1;
  Offset? _planOrigin;
  CityPlan? get _plan {
    final plan = widget.place?.plan;
    return plan is CityPlan ? plan : null;
  }

  RoomPlan? get _room => widget.place?.room;

  /// The plan the ways are laid on: the room when inside, else the city.
  PlacePlan? get _anchors => widget.place?.room ?? widget.place?.plan;

  /// A way's road: through the city's streets on its plan, a street out
  /// of the square in a place, the road up the map otherwise.
  Path _road(Offset from, Offset to) {
    final plan = _anchors;
    final s = _planScale, o = _planOrigin;
    if (plan != null && s != null && o != null) {
      final pts = [
        for (final p in plan.route((from - o) / s, (to - o) / s)) o + p * s,
      ];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        if (i + 1 < pts.length) {
          final mid = (pts[i] + pts[i + 1]) / 2;
          path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      return path;
    }
    return _placeMode ? placeStreet(from, to) : _roadPath(from, to);
  }

  /// [path] less the party's mark at its start and the step's at its end.
  static Path _trimmed(Path path, double start, double end) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return path;
    final metric = metrics.first;
    if (metric.length <= start + end + 2) return path;
    return metric.extractPath(start, metric.length - end);
  }

  /// Where a way's road leaves the party and reaches its mark.
  (Offset, Offset) _roadEnds(Offset here, Offset centre, double width) {
    if (!_placeMode) {
      return (
        _roadStart(here, centre, width),
        centre.translate(0, _stepRadius)
      );
    }
    final d = centre - here;
    final unit = d.distance == 0 ? const Offset(0, -1) : d / d.distance;
    return (here + unit * _hereRadius, centre - unit * _stepRadius);
  }

  ScrollController? _scroll;
  double _openAt = 0;
  double? _viewport;
  int? _walking;

  // The last layout, for the walk.
  Offset _here = Offset.zero;
  List<Offset> _centres = const [];

  // --- Motion (see journey_fx.dart) ---------------------------------------

  /// Seconds the map has been on screen: the effects are drawn from it.
  final ValueNotifier<double> _clock = ValueNotifier(0);

  /// Ticks while something on the map is still arriving (the ways inking
  /// in, the stamp, the unroll, a burn, a rattle), for the widgets.
  final ValueNotifier<double> _phase = ValueNotifier(0);
  Ticker? _ticker;
  double _clockBase = 0;
  bool _animate = false;

  /// When the last one-off moment began, on the clock.
  double _lastEvent = 0;
  double _unrollAt = -10;
  (int, double)? _rattle;
  final List<JourneyFootprint> _footprints = [];
  (Offset, double)? _dust;
  ui.PathMetric? _walkRoad;
  double _nextPrint = 0;

  /// The share of the road between two footprints.
  double _printStep = 0.07;
  int _printSide = 1;

  @override
  void initState() {
    super.initState();
    _town.addListener(() => setState(() {}));
    _walk.addListener(_onWalk);
    _walk.addStatusListener((status) {
      if (status == AnimationStatus.completed && _walking != null) {
        final i = _walking!;
        if (i < _centres.length) _dust = (_centres[i], _clock.value);
        _wake();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only on screen, and not with the system's reduced motion.
    final animate = !MediaQuery.of(context).disableAnimations &&
        Visibility.of(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate == _animate) return;
    _animate = animate;
    if (animate) {
      _idleGlyphs.repeat();
      final from = widget.arriveFrom;
      if (!_arrivalStarted &&
          from != null &&
          _anchors != null &&
          from != widget.place?.hereDistrict) {
        _arrivalStarted = true;
        _arrival.forward(from: 0);
      }
      _ticker ??= createTicker((elapsed) {
        final now = _clockBase + elapsed.inMicroseconds / 1e6;
        _clock.value = now;
        if (now - _lastEvent < 3.8) _phase.value = now;
        // Nothing left to move: the map holds this frame (v1.209).
        if (!_movingAt(now)) _rest();
      });
      _wake();
    } else {
      _idleGlyphs.stop();
      _rest();
    }
  }

  /// Whether the map still has motion to draw at [now] (v1.209): a walk
  /// or a flight under way, the ways still inking in, a new chapter
  /// burning open, a place's name stamped, the unroll, a shut way's
  /// rattle, footprints and dust still fading, or the moments after the
  /// last event (the picked road flows a while, then holds). Idle, the
  /// ticker stops: the Journey draws no frame until something moves.
  bool _movingAt(double now) =>
      _walk.isAnimating ||
      _arrival.isAnimating ||
      _flight.isAnimating ||
      _reveal < 1 ||
      (widget.burn && now < 1.4) ||
      (widget.stamp != null && now < 4.2) ||
      now - _unrollAt < 0.55 ||
      now - _lastEvent < 3.8 ||
      (_rattle != null && now - _rattle!.$2 < 0.5) ||
      (_dust != null && now - _dust!.$2 < 0.8) ||
      _footprints.any((f) => now - f.born < 1.4);

  /// Starts the clock for the next motion, when the map animates at all.
  void _wake() {
    final ticker = _ticker;
    if (!_animate || ticker == null || ticker.isActive) return;
    ticker.start();
    debugJourneyMapsTicking.value++;
  }

  /// Stops the clock where it stands; [_wake] takes it up from there.
  void _rest() {
    final ticker = _ticker;
    if (ticker == null || !ticker.isActive) return;
    _clockBase = _clock.value;
    ticker.stop();
    debugJourneyMapsTicking.value--;
  }

  @override
  void didUpdateWidget(covariant _JourneyChart old) {
    super.didUpdateWidget(old);
    if (old.townView != widget.townView) {
      final to = widget.townView ? 1.0 : 0.0;
      if (MediaQuery.of(context).disableAnimations) {
        _town.value = to;
      } else {
        _town.animateTo(to, curve: Curves.easeInOut);
      }
    }
    if (old.unroll != widget.unroll) {
      _unrollAt = _clock.value;
      _lastEvent = _clock.value;
    }
    // A new moment to draw: the road picked flows, a chapter burns open,
    // a name is stamped, the ways of a new scene ink in.
    if (old.unroll != widget.unroll ||
        old.burn != widget.burn ||
        old.stamp != widget.stamp ||
        old.selected != widget.selected ||
        old.steps.length != widget.steps.length) {
      _lastEvent = _clock.value;
      _wake();
    }
  }

  void _onWalk() {
    final road = _walkRoad;
    if (road == null || !_animate) return;
    final t = Curves.easeInOut.transform(_walk.value);
    // A footprint every little way, left and right.
    while (_nextPrint <= t && _nextPrint < 0.97) {
      final tangent = road.getTangentForOffset(road.length * _nextPrint);
      if (tangent != null) {
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        _footprints.add(JourneyFootprint(
          tangent.position + normal * 4.0 * _printSide.toDouble(),
          _clock.value,
          math.atan2(tangent.vector.dy, tangent.vector.dx) + math.pi / 2,
        ));
        _printSide = -_printSide;
      }
      _nextPrint += _printStep;
    }
  }

  /// How far the ways have inked in (0 to 1): all of them at once with
  /// the system's reduced motion, or on a new chapter (which burns open).
  double get _reveal =>
      !_animate || widget.burn ? 1 : (_clock.value / 1.0).clamp(0.0, 1.0);

  /// Step [i]'s road drawn so far, and its mark's pop. The ways follow one
  /// another closer the more there are, so a busy town's last way is in
  /// with the rest.
  double get _stagger =>
      math.min(0.08, 0.25 / math.max(1, widget.steps.length));
  double _roadReveal(int i) =>
      ((_reveal - i * _stagger) / 0.55).clamp(0.0, 1.0).toDouble();
  double _markReveal(int i) =>
      ((_reveal - 0.4 - i * _stagger) / 0.35).clamp(0.0, 1.0).toDouble();

  /// Walks the party's mark along the road to step [index], the map
  /// following it and coming back to where it opened; returns how far the
  /// party went (the step's place less its own), or null when the map is
  /// taken down before the party gets there.
  Future<Offset?> walkTo(int index) async {
    if (index >= _centres.length || !widget.steps[index].moves) return null;
    _walkRoad = _road(_here, _centres[index]).computeMetrics().first;
    // Slow in a place, a stroll whatever the street's length, and the
    // footprints a stride apart.
    _walk.duration = _animate
        ? journeyWalkDuration(_walkRoad!.length, place: _placeMode)
        : const Duration(milliseconds: 950);
    _printStep = (26 / math.max(1.0, _walkRoad!.length)).clamp(0.02, 0.07);
    _nextPrint = _printStep;
    _footprints.clear();
    _dust = null;
    _lastEvent = _clock.value;
    _wake();
    setState(() => _walking = index);
    final scroll = _scroll;
    if (scroll != null &&
        scroll.hasClients &&
        (scroll.offset - _openAt).abs() > 1) {
      scroll.animateTo(_openAt,
          duration: _walk.duration!, curve: Curves.easeInOut);
    }
    try {
      await _walk.forward(from: 0).orCancel;
      // A way out of the place: the map zooms out to the world chart and
      // the party walks the road to where it leads.
      final place = widget.place;
      final target =
          index < widget.steps.length ? widget.steps[index].chartTarget : null;
      if (place != null && target != null && _animate && mounted) {
        // A road with more to pass takes longer to walk.
        final stops = widget.steps[index].route?.stops.length ?? 0;
        _flight.duration =
            Duration(milliseconds: math.min(4500, 1900 + 350 * stops));
        setState(() => _flying = index);
        _wake();
        await _flight.forward(from: 0).orCancel;
      }
    } on TickerCanceled {
      // The map went mid-walk (disposed with its scene): its walk never
      // ends, and the caller must not wait on it.
      return null;
    }
    return _centres[index] - _here;
  }

  /// The party walks back along the road it took, to its mark (the story
  /// stayed where it was: a fight fled, a shop shut), instead of snapping
  /// there (v1.245). With reduced motion it is there at once.
  Future<void> walkBack() async {
    if (!mounted) return;
    if (_walking != null && _animate) {
      try {
        if (_flying != null) {
          await _flight
              .animateBack(0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut)
              .orCancel;
        }
        final span = _walk.duration ?? const Duration(milliseconds: 950);
        await _walk
            .animateBack(0, duration: span * 0.6, curve: Curves.easeInOut)
            .orCancel;
      } on TickerCanceled {
        // The map went mid-walk: nothing left to bring back.
      }
    }
    resetWalk();
  }

  /// Brings the party back to its mark (the story stayed where it was).
  void resetWalk() {
    if (!mounted) return;
    _walk.value = 0;
    _flight.value = 0;
    setState(() {
      _walking = null;
      _flying = null;
    });
  }

  @override
  void dispose() {
    _rest();
    _ticker?.dispose();
    _clock.dispose();
    _phase.dispose();
    _walk.dispose();
    _beat.dispose();
    _arrival.dispose();
    _town.dispose();
    _flight.dispose();
    _idleGlyphs.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final palette = widget.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: palette.land,
        child: LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth;
          final rowSizes = journeyRowSizes(steps.length);
          final rows = rowSizes.length;
          late final double present;
          late final Offset here;
          late final List<Offset> centres;
          if (_placeMode) {
            // In a place: the party in the middle, its ways round it and
            // the ways out at the edge where they lead; the chapter
            // behind below.
            // A little short of the box, so the road behind peeks in at
            // the foot and says there is more below.
            // A crowded place (a busy hub's twenty ways) gets a taller
            // map, so the outer ring has room for every mark.
            present = math.max(
                box.maxHeight,
                steps.length > 16
                    ? 560
                    : steps.length > 7
                        ? 400
                        : steps.length > 3
                            ? 300
                            : 220);
            final plan = _anchors;
            if (plan != null) {
              // On the city's plan (v1.203): the whole city in view, the
              // party where its district is, the steps into the other
              // districts where those are, the ways out at the edge and
              // the ways within this district close round the party.
              // Close up (v1.224): the map keeps in view the party and the
              // places its ways lead to, not the whole city.
              final districtOf = widget.place!.districtOfStep;
              final focus = journeyFocusFrame(plan.frame, [
                plan.anchorOf(widget.place!.hereDistrict),
                for (var i = 0; i < steps.length; i++)
                  if (steps[i].moves && districtOf[i] != null)
                    plan.anchorOf(districtOf[i]!),
              ]);
              final frame = _town.value == 0
                  ? focus
                  : Rect.lerp(focus, plan.frame, _town.value) ?? focus;
              const side = 22.0, top = 26.0, foot = 74.0;
              final s = math.min((width - 2 * side) / frame.width,
                  (present - top - foot) / frame.height);
              final origin = Offset(width / 2 - frame.center.dx * s,
                  top + (present - top - foot) / 2 - frame.center.dy * s);
              _planScale = s;
              _planOrigin = origin;
              // The scale that fits the whole plan: the chart's detail
              // (roofs, names) reads the zoom over it.
              _planFitted = math.min((width - 2 * side) / plan.frame.width,
                  (present - top - foot) / plan.frame.height);
              Offset tf(Offset p) => origin + p * s;
              here = tf(plan.anchorOf(widget.place!.hereDistrict));
              final positions = List<Offset>.filled(steps.length, here);
              // Where the party's badge and the map's button sit: no mark
              // under them.
              final obstacles = [
                Rect.fromLTWH(0, 0, math.min(width * 0.5, 190) + 16, 84),
                Rect.fromLTWH(width - 64, present - 64, 64, 64),
              ];
              final area = Rect.fromLTWH(0, 0, width, present).deflate(28);
              final taken = <Offset>[];
              const apart = _stepRadius * 2 + 6;
              bool clear(Offset p) =>
                  area.contains(p) &&
                  (p - here).distance >= _hereRadius + _stepRadius + 4 &&
                  !obstacles.any((o) => o.overlaps(
                      Rect.fromCircle(center: p, radius: _stepRadius))) &&
                  taken.every((t) => (t - p).distance >= apart);
              // Spots round the party, ring on ring, the nearest first:
              // a way with no ground of its own takes the first spot that
              // is clear.
              final candidates = <Offset>[
                for (var k = 0; k < 7; k++)
                  for (var n = 0; n < 18; n++)
                    here +
                        Offset(math.cos(n * math.pi / 9 + k * math.pi / 18),
                                math.sin(n * math.pi / 9 + k * math.pi / 18)) *
                            (74 + k * 46),
              ];
              Offset spotNear(Offset wanted) {
                Offset? best;
                var bestD = double.infinity;
                for (final c in candidates) {
                  if (!clear(c)) continue;
                  final d = (c - wanted).distance;
                  if (d < bestD) {
                    bestD = d;
                    best = c;
                  }
                }
                return best ?? wanted;
              }

              // The districts' marks first, on their buildings; then the
              // ways out at the edge; then the rest round the party.
              final later = <int>[];
              for (var i = 0; i < steps.length; i++) {
                final district = districtOf[i];
                if (district == null) {
                  later.add(i);
                  continue;
                }
                var p = tf(plan.anchorOf(district));
                if (!clear(p)) p = spotNear(p);
                positions[i] = p;
                taken.add(p);
              }
              for (final i in later) {
                // Only a journey out of the city goes to the edge; a way
                // to another spot of this city stays by the party.
                final bearing =
                    steps[i].chartTarget != null ? steps[i].bearing : null;
                final wanted = bearing != null
                    ? journeyEdgeSpot(here, bearing, Size(width, present))
                    : here;
                final p = clear(wanted) && bearing != null
                    ? wanted
                    : spotNear(wanted);
                positions[i] = p;
                taken.add(p);
              }
              centres = positions;
            } else {
              _planScale = null;
              _planOrigin = null;
              here = Offset(width / 2, present / 2);
              centres = journeyPlaceLayout(
                area: Size(width, present),
                here: here,
                bearings: [for (final step in steps) step.bearing],
              );
            }
            _openAt = 0;
          } else {
            final needed = _top + rows * _rowMin + _hereRadius * 2 + _hereBelow;
            present = math.max(box.maxHeight, needed);
            final hereY = present - _hereBelow - _hereRadius;
            here = Offset(width / 2, hereY);
            final rowGap = rows == 0
                ? 0.0
                : ((hereY - _top - _stepRadius) / rows).clamp(_rowMin, _rowMax);
            Offset centreOf(_Step step) => Offset(
                step.slot.x * width, hereY - rowGap * (step.slot.row + 1));
            centres = [for (final step in steps) centreOf(step)];
            _openAt = math.max(0, present - box.maxHeight);
            _planScale = null;
            _planOrigin = null;
          }
          _here = here;
          _centres = centres;
          // The ways' roads on the city's plan, through its streets.
          final planRoads = _anchors == null
              ? null
              : [for (final c in centres) _road(here, c)];
          final height = present;
          _scroll ??= ScrollController(initialScrollOffset: _openAt);
          // A map made taller or shorter (the scene folded or opened, a
          // step picked and its details under the map) opens on the party
          // again, the step picked kept in view.
          if (_viewport != null && _viewport != box.maxHeight) {
            var at = _openAt;
            final picked = widget.selected;
            if (picked != null && picked < centres.length) {
              final y = centres[picked].dy;
              final low = y + _stepRadius + 24 - box.maxHeight;
              at = at.clamp(low, math.max(low, y - _stepRadius - 12));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final scroll = _scroll;
              if (mounted && scroll != null && scroll.hasClients) {
                scroll.jumpTo(at.clamp(0.0, scroll.position.maxScrollExtent));
              }
            });
          }
          _viewport = box.maxHeight;

          double labelWidth(_Step step) {
            if (_placeMode) return math.min(width * 0.34, 124);
            final n = rowSizes[step.slot.row];
            return n == 1
                ? math.min(width * 0.7, 240)
                : math.min(width / (n + 1) - 6, 180);
          }

          final placeStyle = TextStyle(
            fontFamily: InkFonts.prose,
            fontSize: 12.5,
            height: 1.25,
            color: palette.place,
          );
          final noteStyle = TextStyle(
            fontFamily: InkFonts.system,
            fontSize: 11,
            height: 1.2,
            color: palette.label,
          );

          // Where each way's name goes: under its mark on the road up; in
          // a place, wherever it leaves the other marks clear (see
          // journeyLabelSpots). A crowded place names only the way picked
          // and the ways out; the rest by their marks.
          final scaler = MediaQuery.textScalerOf(context);
          final names = <Size?>[
            for (var i = 0; i < steps.length; i++)
              if (_placeMode &&
                  steps.length > 5 &&
                  widget.selected != i &&
                  steps[i].leadsTo == null)
                null
              else if (_placeMode)
                // In a place, as much as the words take.
                _nameSize(steps[i], labelWidth(steps[i]), placeStyle, noteStyle,
                    scaler,
                    selected: widget.selected == i || _walking == i)
              else
                Size(labelWidth(steps[i]), 0),
          ];
          final nameSpots = _placeMode
              ? journeyLabelSpots(
                  area: Size(width, present),
                  centres: centres,
                  radius: _stepRadius,
                  labels: names,
                  avoid: [
                    Rect.fromCircle(center: here, radius: _hereRadius),
                    // The "You are here" badge in the corner.
                    Rect.fromLTWH(8, 8, math.min(width * 0.5, 190), 56),
                  ],
                  keep: widget.selected,
                  keepAll: _anchors != null,
                )
              : [
                  for (var i = 0; i < steps.length; i++)
                    if (names[i] case final name?)
                      Rect.fromLTWH(
                          (centres[i].dx - name.width / 2).clamp(
                              4.0, math.max(4.0, width - name.width - 4)),
                          centres[i].dy + _stepRadius + 4,
                          name.width,
                          name.height)
                    else
                      null,
                ];

          final map = SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              width: width,
              height: height,
              child: AnimatedBuilder(
                animation: Listenable.merge([_walk, _arrival, _phase]),
                builder: (context, _) {
                  // The walk: the mark goes along its road, and the map
                  // follows a little behind, so the step taken ends where
                  // the mark stood.
                  final walking = _walking;
                  final t = Curves.easeInOut.transform(_walk.value);
                  Offset? traveller;
                  var camera = Offset.zero;
                  if (walking != null && walking < centres.length) {
                    final road = _road(here, centres[walking]).computeMetrics();
                    final metric = road.first;
                    Offset at(double f) =>
                        metric.getTangentForOffset(metric.length * f)!.position;
                    traveller = at(t);
                    camera = here - at(t * t);
                  }
                  // Set down here along no walk: the mark comes by the
                  // streets from where it stood.
                  Offset? arriving;
                  final cameFrom = widget.arriveFrom;
                  final arrivalPlan = _anchors;
                  final planScale = _planScale, planOrigin = _planOrigin;
                  if (cameFrom != null &&
                      _arrival.isAnimating &&
                      traveller == null &&
                      arrivalPlan != null &&
                      planScale != null &&
                      planOrigin != null) {
                    final start =
                        planOrigin + arrivalPlan.anchorOf(cameFrom) * planScale;
                    final metric = _road(start, here).computeMetrics().first;
                    arriving = metric
                        .getTangentForOffset(metric.length *
                            Curves.easeInOut.transform(_arrival.value))!
                        .position;
                  }
                  final now = _clock.value;
                  final walkingKind = walking != null && walking < steps.length
                      ? steps[walking].kind
                      : null;
                  final selectedIndex = walking ?? widget.selected;
                  Path? selectedRoad;
                  if (widget.selected != null &&
                      walking == null &&
                      widget.selected! < centres.length &&
                      steps[widget.selected!].moves &&
                      !steps[widget.selected!].locked) {
                    if (planRoads != null) {
                      selectedRoad = _trimmed(planRoads[widget.selected!],
                          _hereRadius, _stepRadius);
                    } else {
                      final (from, to) =
                          _roadEnds(here, centres[widget.selected!], width);
                      selectedRoad = _road(from, to);
                    }
                  }
                  final burning = _animate && widget.burn && now < 1.4;
                  final burnT = (now / 1.3).clamp(0.0, 1.0);
                  final panned = Transform.translate(
                    offset: camera,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The land the place lies in (v1.197), faint,
                        // under its plan.
                        if (widget.place?.biome case final biome?)
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: const ValueKey('journey_biome'),
                                painter: BiomeBackdropPainter(
                                  biome: biome,
                                  land: palette.land,
                                  seed: widget.place!.seed,
                                  greyed: widget.greyed,
                                ),
                              ),
                            ),
                          ),
                        if (widget.place?.holderColor case final tint?)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: const ValueKey('journey_holder_tint'),
                                decoration: BoxDecoration(
                                  color: tint.withValues(alpha: 0.10),
                                  border: Border.all(
                                      color: tint.withValues(alpha: 0.45),
                                      width: 3),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: ValueKey(_room != null
                                  ? 'journey_room'
                                  : widget.place?.plan != null
                                      ? 'journey_streets'
                                      : 'journey_ground'),
                              painter: widget.place == null
                                  ? _ReliefPainter(
                                      palette: palette,
                                      here: here,
                                      shift: widget.terrainShift,
                                      seed: widget.terrainSeed,
                                    )
                                  : _room != null && _planScale != null
                                      ? RoomPlanPainter(
                                          plan: _room!,
                                          scale: _planScale!,
                                          origin: _planOrigin!,
                                          palette: palette,
                                          ember: widget.ink.ember,
                                        )
                                      : widget.place?.chart != null &&
                                              _planScale != null
                                          ? CityChartPainter(
                                              chart: widget.place!.chart!,
                                              palette: palette,
                                              scale: _planScale!,
                                              offset: _planOrigin!,
                                              fitted: _planFitted,
                                              explored: widget.place!.explored,
                                              hereDistrict: widget.place!
                                                      .hereDistrict.isEmpty
                                                  ? null
                                                  : widget.place!.hereDistrict,
                                              focusDistrict: _planScale! /
                                                          _planFitted >=
                                                      cityChartDetailZoom
                                                  ? widget.place!.hereDistrict
                                                  : null,
                                            )
                                          : _plan != null && _planScale != null
                                              ? CityPlanPainter(
                                                  plan: _plan!,
                                                  scale: _planScale!,
                                                  origin: _planOrigin!,
                                                  palette: palette,
                                                  ember: widget.ink.ember,
                                                )
                                              : PlacePlanPainter(
                                                  kind: widget.place!.kind,
                                                  seed: widget.place!.seed,
                                                  here: here,
                                                  spots: centres,
                                                  palette: palette,
                                                  ember: widget.ink.ember,
                                                  glyphs: widget.place!.glyphs,
                                                  water: widget.place!.water,
                                                ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _JourneyPainter(
                              palette: palette,
                              here: here,
                              hereRadius: _hereRadius,
                              stepRadius: _stepRadius,
                              steps: [
                                for (var i = 0; i < steps.length; i++)
                                  (
                                    centre: centres[i],
                                    row: steps[i].slot.row,
                                    locked: steps[i].locked,
                                    selected:
                                        widget.selected == i || walking == i,
                                    moves: steps[i].moves,
                                  ),
                              ],
                              radial: _placeMode,
                              walking: walking,
                              progress: t,
                              roads: planRoads,
                              reveals: [
                                for (var i = 0; i < steps.length; i++)
                                  _roadReveal(i),
                              ],
                            ),
                          ),
                        ),
                        // What each step holds, the weather, the picked
                        // road flowing, footprints (see journey_fx.dart).
                        // Its own layer (v1.209): the clock's ticks
                        // redraw it alone, not the whole map.
                        if (_animate)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: JourneyFxPainter(
                                    time: _clock,
                                    steps: [
                                      for (var i = 0; i < steps.length; i++)
                                        if (_markReveal(i) >= 1)
                                          JourneyFxStep(
                                            centre: centres[i],
                                            kind: steps[i].kind,
                                            colour: _colorFor(steps[i].kind,
                                                widget.ink, palette,
                                                greyed: widget.greyed),
                                            locked: steps[i].locked,
                                            row: steps[i].slot.row,
                                          ),
                                    ],
                                    here: traveller ?? here,
                                    hereRadius: _hereRadius,
                                    stepRadius: _stepRadius,
                                    mark: palette.mark,
                                    fog: palette.fog,
                                    weather: widget.greyed
                                        ? JourneyWeather.none
                                        : widget.weather,
                                    weatherColour: switch (widget.weather) {
                                      JourneyWeather.rain =>
                                        const Color(0xFF8FC3CF),
                                      JourneyWeather.snow =>
                                        const Color(0xFFEFF3F6),
                                      JourneyWeather.dust =>
                                        const Color(0xFFC9A46A),
                                      _ => palette.place,
                                    },
                                    selectedRoad: selectedRoad,
                                    selected: walking == null &&
                                            selectedIndex != null &&
                                            selectedIndex < steps.length &&
                                            !steps[selectedIndex].locked &&
                                            _markReveal(selectedIndex) >= 1
                                        ? selectedIndex
                                        : null,
                                    footprints: _footprints,
                                    footprintColour: palette.place,
                                    dust: _dust,
                                    dice: traveller != null &&
                                            (walkingKind ==
                                                    JourneyStepKind.check ||
                                                walkingKind ==
                                                    JourneyStepKind.challenge)
                                        ? traveller.translate(
                                            _hereRadius * 0.9,
                                            -_hereRadius -
                                                10 +
                                                math.sin(now * 14).abs() * -8)
                                        : null,
                                    diceColour: widget.ink.tide,
                                    rattle: _rattle == null ||
                                            _rattle!.$1 >= centres.length
                                        ? null
                                        : (centres[_rattle!.$1], _rattle!.$2),
                                    rattleColour: widget.ink.blood,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Where the party stood, while it walks away.
                        _hereMark(here,
                            faded: traveller != null || arriving != null),
                        // A hub's rings round it, and the beat when one of
                        // its choices is taken.
                        if (widget.rings.isNotEmpty &&
                            traveller == null &&
                            arriving == null)
                          ChoiceRingsLayer(
                            here: here,
                            innerRadius: _hereRadius,
                            rings: widget.rings,
                            lit: widget.ringLit,
                            plate: palette.land,
                            onTap: (id) => widget.onRing?.call(id),
                          ),
                        // The rings' chips, over their icons but under the marks, which the
                        // taps must reach first.
                        if (widget.rings.isNotEmpty &&
                            traveller == null &&
                            arriving == null)
                          ChoiceRingsLayer(
                            chips: true,
                            here: here,
                            innerRadius: _hereRadius,
                            rings: widget.rings,
                            lit: widget.ringLit,
                            plate: palette.land,
                            onTap: (id) => widget.onRing?.call(id),
                          ),
                        ChoiceBeat(
                          animation: _beat,
                          here: here,
                          innerRadius: _hereRadius,
                          color: _beatColor,
                          icon: _beatIcon,
                        ),
                        Positioned(
                          left: _placeMode ? 8 : here.dx + _hereRadius + 10,
                          width: _placeMode
                              ? math.min(width * 0.5, 190)
                              : math.max(0, width / 2 - _hereRadius - 16),
                          top: _placeMode ? 8 : here.dy - 18,
                          child: Opacity(
                            opacity: traveller == null ? 1 : 1 - t,
                            child: DecoratedBox(
                              // In a place, a badge in the corner: the
                              // ways ring the mark itself.
                              decoration: BoxDecoration(
                                color: _placeMode
                                    ? palette.land.withValues(alpha: 0.85)
                                    : const Color(0x00000000),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: _placeMode
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4)
                                    : EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.youAreHere.toUpperCase(),
                                      style: noteStyle.copyWith(
                                          fontSize: 10, letterSpacing: 1.2),
                                    ),
                                    Text(
                                      widget.hereName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: InkFonts.display,
                                        fontSize: 16,
                                        height: 1.1,
                                        color: palette.place,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // The ways on: their names, then every mark over
                        // them. Only the marks take taps, so a tap on one
                        // is its own step's, whatever name lies near it.
                        for (var i = 0; i < steps.length; i++)
                          if (nameSpots[i] case final spot?)
                            _stepName(i, spot, placeStyle, noteStyle,
                                fading:
                                    walking != null && walking != i ? t : 0),
                        for (var i = 0; i < steps.length; i++)
                          _stepMark(i, centres[i],
                              fading: walking != null && walking != i ? t : 0),
                        // The party, on the road.
                        if (traveller != null)
                          Positioned(
                            key: const ValueKey('journey_traveller'),
                            left: traveller.dx - _hereRadius,
                            top: traveller.dy - _hereRadius,
                            child: _partyMark(palette),
                          ),
                        if (arriving != null)
                          Positioned(
                            key: const ValueKey('journey_arriving'),
                            left: arriving.dx - _hereRadius,
                            top: arriving.dy - _hereRadius,
                            child: _partyMark(palette),
                          ),
                        // A place the map hadn't shown: its name stamped
                        // over the mark, ink spreading under it.
                        if (widget.stamp != null && _animate && now < 4.2)
                          ..._stampMark(here, now, width),
                      ],
                    ),
                  );
                  // The city's camera (v1.219): the map zooms in on the
                  // party while it walks, keeping it toward the middle,
                  // and out again as it arrives.
                  var chart = panned as Widget;
                  if (walking != null &&
                      walking < centres.length &&
                      traveller != null &&
                      _placeMode &&
                      _animate) {
                    final z = journeyWalkZoomAt(_walk.value);
                    if (z > 1.001) {
                      final focus = traveller + camera;
                      final k = (z - 1) / (journeyWalkZoom - 1);
                      final seen = (_scroll?.hasClients ?? false)
                          ? _scroll!.offset
                          : _openAt;
                      final middle =
                          Offset(width / 2, seen + box.maxHeight / 2);
                      final target = Offset.lerp(focus, middle, k)!;
                      var d = target - focus * z;
                      // Never past the map's edges.
                      d = Offset(
                        d.dx.clamp(width * (1 - z), 0.0),
                        d.dy.clamp(seen + box.maxHeight - z * height, seen),
                      );
                      chart = Transform(
                        key: const ValueKey('journey_walk_camera'),
                        transform: Matrix4.identity()
                          ..setEntry(0, 0, z)
                          ..setEntry(1, 1, z)
                          ..setEntry(0, 3, d.dx)
                          ..setEntry(1, 3, d.dy),
                        child: panned,
                      );
                    }
                  }
                  if (!burning) return chart;
                  // A new chapter: its map burns open from the mark.
                  return Stack(
                    children: [
                      ClipPath(
                        clipper: JourneyBurnClipper(t: burnT, centre: here),
                        child: chart,
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: JourneyBurnPainter(
                                t: burnT,
                                centre: here,
                                ember: widget.ink.ember),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
          // Opened from another tab, the map unrolls down from the scene
          // on a gold rod.
          final unrolled = AnimatedBuilder(
            animation: _phase,
            child: map,
            builder: (context, child) {
              final f = _animate
                  ? Curves.easeInOutCubic.transform(
                      ((_clock.value - _unrollAt) / 0.55).clamp(0.0, 1.0))
                  : 1.0;
              if (f >= 1) return child!;
              final h = box.maxHeight;
              return Stack(
                children: [
                  ClipRect(
                    clipper: _TopReveal(f),
                    child: child,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (h * f - 3).clamp(0.0, h - 6),
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [palette.mark, widget.ink.gold],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          final flying = _flying;
          final place = widget.place;
          if (flying == null ||
              place == null ||
              flying >= steps.length ||
              steps[flying].chartTarget == null) {
            return unrolled;
          }
          // On the road: the world chart, from here to where it leads.
          return Stack(
            children: [
              unrolled,
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _flight,
                  builder: (context, _) => CustomPaint(
                    key: const ValueKey('journey_flight'),
                    painter: RegionFlightPainter(
                      geography: place.geography,
                      from: place.chartHere,
                      to: steps[flying].chartTarget!,
                      marks: place.marks,
                      t: _flight.value,
                      palette: palette,
                      fromName: widget.hereName,
                      toName: steps[flying].leadsTo ?? '',
                      route: steps[flying].route,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _stampMark(Offset here, double now, double width) {
    final palette = widget.palette;
    final spread = ((now - 0.95) / 1.1).clamp(0.0, 1.0);
    // The seal that stamps it, in pixel art (v1.216): it comes down, the
    // ink flies and it dissolves, under the name that follows.
    PixelStrips.preload(const ['moment_seal']);
    return [
      if (now >= 0.9 && now < 3.2)
        Positioned(
          left: 0,
          width: width,
          top: here.dy + _hereRadius + 10 + 13 - 48,
          height: 96,
          child: IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('journey_stamp_seal'),
              painter: PixelStripPainter(
                names: const ['moment_seal'],
                progress: ((now - 0.9) / 2.3).clamp(0.0, 0.999),
                scale: 2,
              ),
            ),
          ),
        ),
      if (spread > 0 && spread < 1)
        Positioned(
          left: here.dx - 90,
          top: here.dy - 90,
          width: 180,
          height: 180,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - spread) * 0.7,
              child: Transform.scale(
                scale: 0.3 + spread * 1.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      palette.mark.withValues(alpha: 0.5),
                      palette.mark.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _partyMark(ChartPalette palette) => Container(
        width: _hereRadius * 2,
        height: _hereRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.mark,
          border: Border.all(color: palette.land, width: 3),
          boxShadow: [
            BoxShadow(
              color: palette.mark.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(Icons.person_pin, color: palette.land, size: 26),
      );

  Widget _hereMark(Offset here, {required bool faded}) {
    final palette = widget.palette;
    return Positioned(
      left: here.dx - _hereRadius,
      top: here.dy - _hereRadius,
      child: faded
          ? Container(
              width: _hereRadius * 2,
              height: _hereRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: palette.mark.withValues(alpha: 0.5), width: 2),
              ),
            )
          : _partyMark(palette),
    );
  }

  /// One of a step's ways on, a small mark above it in the fog.
  Widget _glimpse(
      int f, int count, JourneyStepKind kind, ChartPalette palette) {
    final angle = count == 1 ? 0.0 : (f / (count - 1) - 0.5) * (math.pi / 2.2);
    const size = 12.0;
    final centre = Offset(
      _stepRadius + math.sin(angle) * (_stepRadius + 10),
      _stepRadius - math.cos(angle) * (_stepRadius + 10),
    );
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      child: Icon(_iconFor(kind),
          size: size, color: palette.label.withValues(alpha: 0.75)),
    );
  }

  /// How much room step [step]'s name takes on the map, at most [w] wide:
  /// its words (three lines at most) and where it leads, on their plaque.
  Size _nameSize(_Step step, double w, TextStyle placeStyle,
      TextStyle noteStyle, TextScaler scaler,
      {required bool selected}) {
    Size measure(String text, TextStyle style, int lines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: lines,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, w - 6));
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final words = measure(
        step.label,
        placeStyle.copyWith(
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400),
        3);
    final to = step.leadsTo == null
        ? Size.zero
        : measure(
            widget.leadsTo.replaceAll('{place}', step.leadsTo!), noteStyle, 1);
    return Size(
        math.max(words.width, to.width) + 6, words.height + to.height + 2);
  }

  /// Step [i]'s name on its plaque, in [spot] (see journeyLabelSpots). It
  /// takes no taps: its mark, drawn over every name, takes them.
  Widget _stepName(int i, Rect spot, TextStyle placeStyle, TextStyle noteStyle,
      {required double fading}) {
    final step = widget.steps[i];
    final palette = widget.palette;
    final isSelected = widget.selected == i || _walking == i;
    // The words fade up once the mark has popped in.
    final pop = _markReveal(i);
    return Positioned(
      left: spot.left,
      top: spot.top,
      width: spot.width,
      child: IgnorePointer(
        // Said by the mark (see _stepMark).
        child: ExcludeSemantics(
          child: Opacity(
            opacity: (1 - fading * 0.7) * pop.clamp(0.0, 1.0),
            child: Column(
              children: [
                // A plaque under the words: the roads to the far steps
                // pass beneath it.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.land.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    child: Column(
                      children: [
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: placeStyle.copyWith(
                            color: palette.place
                                .withValues(alpha: step.locked ? 0.55 : 1),
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        if (step.leadsTo != null)
                          Text(
                            widget.leadsTo.replaceAll('{place}', step.leadsTo!),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: noteStyle,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step [i]'s mark at [centre]: the step's own tap, no wider than it.
  Widget _stepMark(int i, Offset centre, {required double fading}) {
    final step = widget.steps[i];
    final palette = widget.palette;
    final colour = step.locked
        ? palette.label
        : _colorFor(step.kind, widget.ink, palette, greyed: widget.greyed);
    final isSelected = widget.selected == i || _walking == i;
    // Most ways hang as a banner in their category's colour (see
    // journey_banner_pin.dart); fights and rolls keep their round marks.
    final cat = journeyPinCatOf(step.kind, step.questTie);
    final dark = journeyInkIsDark(widget.ink);
    final bannerColour = cat == null
        ? colour
        : step.locked
            ? palette.label
            : widget.greyed && cat != JourneyPinCat.main
                ? palette.place
                : cat.colorOn(widget.ink, dark: dark);
    // A new scene: the mark pops in once its road reaches it, and the
    // words fade up after.
    final pop = _markReveal(i);
    final popScale = pop >= 1 ? 1.0 : Curves.easeOutBack.transform(pop);
    // A shut way tapped shakes its padlock.
    final rattle = _rattle;
    final rattleAge =
        rattle != null && rattle.$1 == i ? _clock.value - rattle.$2 : 1.0;
    final shake = rattleAge < 0.45
        ? math.sin(rattleAge * 42) * 0.35 * (1 - rattleAge / 0.45)
        : 0.0;
    return Positioned(
      left: centre.dx - _stepRadius,
      top: centre.dy - _stepRadius,
      width: _stepRadius * 2,
      height: _stepRadius * 2,
      child: Opacity(
        opacity: (1 - fading * 0.7) * pop.clamp(0.0, 1.0),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: step.label,
          child: GestureDetector(
            key: ValueKey('journey_step_${widget.stepIds?[i] ?? i}'),
            behavior: HitTestBehavior.opaque,
            onTap: _walking == null
                ? () {
                    if (step.locked && _animate) {
                      _rattle = (i, _clock.value);
                      _lastEvent = _clock.value;
                      _wake();
                    }
                    widget.onTap(i, step);
                  }
                : null,
            child: AnimatedScale(
              scale: (isSelected ? 1.15 : 1) * popScale,
              duration:
                  pop >= 1 ? const Duration(milliseconds: 160) : Duration.zero,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (cat != null)
                    Center(
                      child: Transform.rotate(
                        angle: shake,
                        child: BannerPin(
                          cat: cat,
                          color: bannerColour,
                          dark: dark,
                          icon: step.locked ? Icons.lock_outline : null,
                          lit: isSelected,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: _stepRadius * 2,
                      height: _stepRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colour : palette.land,
                        border: Border.all(
                          color: colour,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Transform.rotate(
                        angle: shake,
                        child: step.locked
                            ? Icon(Icons.lock_outline,
                                size: 20,
                                color: isSelected ? palette.land : colour)
                            : AnimatedBuilder(
                                animation: _idleGlyphs,
                                builder: (context, _) => journeyIdleGlyph(
                                  glyph: step.glyph,
                                  colour: isSelected ? palette.land : colour,
                                  t: _idleGlyphs.value * 12,
                                  phase: i * 0.9,
                                ),
                              ),
                      ),
                    ),
                  // Tied to a quest: a small bookmark on the mark, gold for
                  // the main quest, the place's ink for a side job.
                  if (step.questTie != null && !step.locked && cat == null)
                    Positioned(
                      key: ValueKey(
                          'journey_quest_badge_${widget.stepIds?[i] ?? i}'),
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.questTie == JourneyQuestTie.main
                              ? widget.ink.gold
                              : palette.place,
                          border: Border.all(color: palette.land, width: 1.5),
                        ),
                        child: Icon(
                          step.questTie == JourneyQuestTie.main
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 11,
                          color: palette.land,
                        ),
                      ),
                    ),
                  // What lies past the step, glimpsed through the fog: the
                  // kinds of its own ways on.
                  if (!step.locked && pop >= 1)
                    for (var f = 0; f < step.onwardKinds.length; f++)
                      _glimpse(f, step.onwardKinds.length, step.onwardKinds[f],
                          palette),
                  // What waits on the road there.
                  if (step.event != null)
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: Container(
                        key: ValueKey(
                            'journey_event_${widget.stepIds?[i] ?? i}'),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _eventColour(step.event!, widget.ink),
                          border: Border.all(color: palette.land, width: 1.5),
                        ),
                        child: Icon(
                            _eventIcon(step.event!, hazard: step.hazard),
                            size: 11,
                            color: palette.land),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The road from [from] up to [to]: leaving straight up, arriving from
/// straight below.
/// Where step [centre]'s road leaves the party's mark: on the side it
/// heads for (as _JourneyPainter draws it).
Offset _roadStart(Offset here, Offset centre, double width) {
  final lean =
      ((centre.dx - here.dx) / width * 1.6).clamp(-math.pi / 3, math.pi / 3);
  return here +
      Offset(math.sin(lean) * _JourneyChartState._hereRadius,
          -math.cos(lean) * _JourneyChartState._hereRadius);
}

/// The top [fraction] of the map, as it unrolls.
class _TopReveal extends CustomClipper<Rect> {
  const _TopReveal(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_TopReveal old) => old.fraction != fraction;
}

Path _roadPath(Offset from, Offset to) {
  final dy = (from.dy - to.dy).abs();
  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
        from.dx, from.dy - dy * 0.45, to.dx, to.dy + dy * 0.45, to.dx, to.dy);
}

/// The land: contour lines in the look's coast colour, the index line a
/// little stronger, a soft shade on the far side of each hilltop and a
/// small peak mark on the highest. Drawn a margin past the map's edges so
/// the land is there when the map moves with the party.
class _ReliefPainter extends CustomPainter {
  _ReliefPainter({
    required this.palette,
    required this.here,
    required this.shift,
    required this.seed,
  });

  final ChartPalette palette;
  final Offset here;
  final Offset shift;
  final int seed;

  static const double _margin = 320;

  double _height(double x, double y) =>
      reliefHeight(x - here.dx + shift.dx, y - here.dy + shift.dy, seed: seed);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(-_margin, -_margin, size.width + _margin * 2,
        size.height + _margin * 2);
    // Hills first: a shade to the south-east of each top.
    final peaks = reliefPeaks(area: area, height: _height);
    for (final peak in peaks) {
      final centre = peak + const Offset(16, 18);
      final shade = Rect.fromCircle(center: centre, radius: 70);
      canvas.drawCircle(
        centre,
        70,
        Paint()
          ..shader = RadialGradient(colors: [
            palette.fog.withValues(alpha: 0.32),
            palette.fog.withValues(alpha: 0),
          ]).createShader(shade),
      );
    }
    // The contour lines, a shade stronger on the dark looks, whose coast
    // colour sits close to the land.
    final dark = palette.land.computeLuminance() < 0.2;
    final contour =
        dark ? Color.lerp(palette.coast, palette.label, 0.55)! : palette.coast;
    for (var l = 0; l < reliefLevels.length; l++) {
      final index = l == 2;
      final paint = Paint()
        ..color = contour.withValues(
            alpha: (index ? 0.6 : 0.34 + l * 0.05) * (dark ? 1.15 : 1))
        ..strokeWidth = index ? 1.3 : 0.9
        ..strokeCap = StrokeCap.round;
      for (final (a, b) in reliefContour(
          area: area, level: reliefLevels[l], height: _height, cell: 14)) {
        canvas.drawLine(a, b, paint);
      }
    }
    // A small peak on each hilltop, shaded on its eastern face.
    final line = Paint()
      ..color = palette.coast.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final face = Paint()..color = palette.coast.withValues(alpha: 0.35);
    for (final peak in peaks) {
      final top = peak + const Offset(0, -6);
      final left = peak + const Offset(-7, 5);
      final right = peak + const Offset(7, 5);
      canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..lineTo(right.dx, right.dy)
            ..lineTo(peak.dx + 1, right.dy)
            ..close(),
          face);
      canvas.drawPath(
          Path()
            ..moveTo(left.dx, left.dy)
            ..lineTo(top.dx, top.dy)
            ..lineTo(right.dx, right.dy),
          line);
    }
  }

  @override
  bool shouldRepaint(_ReliefPainter old) =>
      old.palette != palette ||
      old.here != here ||
      old.shift != shift ||
      old.seed != seed;
}

/// The roads over the land: the fog over what is not known yet and the ways
/// on.
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.palette,
    required this.here,
    required this.hereRadius,
    required this.stepRadius,
    required this.steps,
    required this.walking,
    required this.progress,
    this.reveals = const [],
    this.radial = false,
    this.roads,
  });

  /// The ways' roads through a city's streets (v1.203), from the party to
  /// each step, when the place has a plan; else each is a street or the
  /// road up the map.
  final List<Path>? roads;

  /// In a place (v1.181): the ways run out of the square every way, as
  /// streets, with no fog over the top.
  final bool radial;

  /// How much of each way's road has inked in (a new scene draws them out
  /// from the mark, one after the other); missing means all of it.
  final List<double> reveals;

  final ChartPalette palette;
  final Offset here;
  final double hereRadius;
  final double stepRadius;
  final List<
      ({
        Offset centre,
        int row,
        bool locked,
        bool selected,
        bool moves,
      })> steps;

  /// The step the party is walking to, and how far along it is.
  final int? walking;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Fog over the far side of the map.
    final fogRect = Rect.fromLTWH(-400, -400, size.width + 800, 490);
    if (!radial) {
      canvas.drawRect(
        fogRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.fog,
              palette.fog,
              palette.fog.withValues(alpha: 0)
            ],
            stops: const [0, 0.82, 1],
          ).createShader(fogRect),
      );
    }

    // The ways on: dashed, the chosen one drawn in full. Each leaves the
    // party's mark on the side it heads for, and the roads to the far
    // rows fade, so a town's many ways read as a fan rather than a knot.
    for (var s = 0; s < steps.length; s++) {
      final step = steps[s];
      // A way that keeps the party where it stands has no road to walk.
      if (!step.moves) continue;
      late final Offset start, end;
      if (radial) {
        final d = step.centre - here;
        final unit = d.distance == 0 ? const Offset(0, -1) : d / d.distance;
        start = here + unit * hereRadius;
        end = step.centre - unit * stepRadius;
      } else {
        final lean = ((step.centre.dx - here.dx) / size.width * 1.6)
            .clamp(-math.pi / 3, math.pi / 3);
        start = here +
            Offset(math.sin(lean) * hereRadius, -math.cos(lean) * hereRadius);
        end = step.centre.translate(0, stepRadius);
      }
      var path = roads != null && s < roads!.length
          ? _JourneyChartState._trimmed(roads![s], hereRadius, stepRadius)
          : radial
              ? placeStreet(start, end)
              : _roadPath(start, end);
      final reveal = s < reveals.length ? reveals[s] : 1.0;
      if (reveal <= 0) continue;
      if (reveal < 1) {
        final metric = path.computeMetrics().first;
        path = metric.extractPath(0, metric.length * reveal);
      }
      final fade = walking != null && walking != s ? 1 - progress * 0.8 : 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = step.selected ? 3 : 2
        ..color = step.selected
            ? palette.mark
            : step.locked
                ? palette.label.withValues(alpha: 0.4 * fade)
                : palette.ahead.withValues(
                    alpha:
                        (radial || step.row == 0 ? 1 : 0.75 / step.row) * fade);
      if (step.selected) {
        canvas.drawPath(path, paint);
      } else {
        _dashed(canvas, path, paint, dash: 6, gap: 6);
      }
    }
    // The road being walked, in the party's colour behind it.
    if (walking != null && walking! < steps.length && progress > 0) {
      final road = roads != null && walking! < roads!.length
          ? roads![walking!]
          : radial
              ? placeStreet(here, steps[walking!].centre)
              : _roadPath(here, steps[walking!].centre);
      for (final metric in road.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          Paint()
            ..color = palette.mark
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  static void _dashed(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.palette != palette ||
      old.here != here ||
      old.walking != walking ||
      old.progress != progress ||
      old.reveals.length != reveals.length ||
      [
        for (var i = 0; i < reveals.length; i++) old.reveals[i] != reveals[i],
      ].any((changed) => changed) ||
      old.radial != radial ||
      (old.roads == null) != (roads == null) ||
      old.steps.length != steps.length ||
      [
        for (var i = 0; i < steps.length; i++) old.steps[i] != steps[i],
      ].any((changed) => changed);
}

/// Under the map: the step picked, what it holds and costs, and Go.
/// Nothing picked yet says how to pick.
class _StepDetail extends ConsumerWidget {
  const _StepDetail({
    required this.step,
    required this.busy,
    required this.french,
    required this.isExcursion,
    required this.onGo,
  });

  final _Step? step;
  final bool busy;
  final bool french;
  final bool isExcursion;
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final step = this.step;
    if (step == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(ref, 'journey_pick_hint'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
      );
    }
    final choice = step.choice;
    String signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
    final enemies = choice.triggersCombat
        ? ref.watch(localizedDbProvider(enemiesSchema)).value
        : null;
    final ids = choice.allTriggerEnemyIds;
    final roster = isExcursion ||
            enemies == null ||
            ids.isEmpty ||
            ids.any((id) => id.startsWith('@'))
        ? null
        : enemyRoster(ids, enemies);
    final colour = step.locked
        ? ink.ash
        : _colorFor(step.kind, ink, ChartPalette.of(ref.watch(mapLookProvider)),
            greyed: false);
    final tags = [
      if (choice.hasAbilityCheck)
        InkTag(
          label: '${tr(ref, '${choice.checkAbility}_label')} '
              'DC ${choice.checkDC ?? 10}',
          color: ink.tide,
        ),
      if (choice.goldMod != 0)
        InkTag(
          label: '${signed(choice.goldMod)} ${tr(ref, 'gold_label')}',
          color: ink.gold,
        ),
      if (choice.healAmount != 0)
        InkTag(
          label: '${signed(choice.healAmount)} ${tr(ref, 'hp_label')}',
          color: choice.healAmount > 0 ? ink.heal : ink.blood,
        ),
      if (choice.alignmentMod != 0)
        InkTag(
          label: '${tr(ref, 'alignment_label')} ${signed(choice.alignmentMod)}',
          color: ink.voidColor,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              // Capped under the map on a short phone (see
              // _JourneyViewState._mapMin): the words scroll, Go stays.
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(ref, _kindKey(step.kind)).toUpperCase(),
                      style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: colour,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: InkFonts.prose,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    if (roster != null && !step.locked)
                      Text(
                        tr(ref, 'choice_fight_roster')
                            .replaceAll('{roster}', roster),
                        style: theme.textTheme.labelSmall,
                      ),
                    if (step.leadsTo != null)
                      Text(
                        tr(ref, 'journey_leads_to')
                            .replaceAll('{place}', step.leadsTo!),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                    // The road it takes, by the stops it passes (v1.256).
                    if (step.route != null && step.route!.stops.isNotEmpty)
                      Text(
                        tr(ref, 'journey_by_road').replaceAll('{stops}',
                            step.route!.stops.map((s) => s.name).join(' · ')),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                    if (step.event != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(_eventIcon(step.event!, hazard: step.hazard),
                                size: 14,
                                color: _eventColour(step.event!, ink)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tr(ref, 'journey_event_${step.event!.name}')
                                    .replaceAll('{hazard}',
                                        step.hazard?.nameFor(french) ?? ''),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: _eventColour(step.event!, ink)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: step.locked ? 0.45 : 1,
                        child: Wrap(spacing: 6, runSpacing: 4, children: tags),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              key: const ValueKey('journey_go'),
              onPressed: step.locked || busy ? null : onGo,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr(ref, 'journey_go')),
            ),
          ],
        ),
      ),
    );
  }
}

/// The story reader, for what the map has no way on to (the ending, New
/// Game+, the way back to the beginning): the Story tab in Edit Mode,
/// pushed over the game in play (v1.201: the game has no Story tab).
void openStoryReader(BuildContext context, WidgetRef ref) {
  if (ref.read(appModeProvider) == AppMode.edit) {
    ref.read(homeTabIndexProvider.notifier).state = 0;
    return;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'title_story'))),
      body: const StoryPlayerScreen(),
    ),
  ));
}

/// The Journey map's levels as tabs (v1.350).
enum _LevelTab { district, town, world }

/// Three small tab buttons on the map: the district, the whole town, the
/// world. The one looked at is lit; the town is dimmed where the place has
/// no city plan.
class _LevelTabs extends ConsumerWidget {
  const _LevelTabs({
    required this.selected,
    required this.townEnabled,
    required this.busy,
    required this.palette,
    required this.onPick,
  });

  final _LevelTab selected;
  final bool townEnabled;
  final bool busy;
  final ChartPalette palette;
  final ValueChanged<_LevelTab> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget tab(_LevelTab t, String label, {bool enabled = true}) {
      final on = t == selected;
      final colour = on
          ? palette.mark
          : enabled
              ? palette.place
              : palette.label.withValues(alpha: 0.5);
      return InkWell(
        key: Key('journey_tab_${t.name}'),
        onTap: enabled && !busy && !on ? () => onPick(t) : null,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? palette.mark.withValues(alpha: 0.18) : null,
            border: Border(
              bottom: BorderSide(
                  color: on ? palette.mark : Colors.transparent, width: 2),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 12,
                  height: 1,
                  color: colour)),
        ),
      );
    }

    return Material(
      color: palette.land.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.coast, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        key: const Key('journey_level_tabs'),
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(_LevelTab.district, tr(ref, 'journey_tab_district')),
          tab(_LevelTab.town, tr(ref, 'journey_tab_town'),
              enabled: townEnabled),
          tab(_LevelTab.world, tr(ref, 'journey_tab_world')),
        ],
      ),
    );
  }
}

CityWayKind _cityWayKindOf(JourneyStepKind kind) => switch (kind) {
      JourneyStepKind.fight => CityWayKind.fight,
      JourneyStepKind.check || JourneyStepKind.challenge => CityWayKind.check,
      JourneyStepKind.shop => CityWayKind.shop,
      JourneyStepKind.quest || JourneyStepKind.mainQuest => CityWayKind.quest,
      _ => CityWayKind.road,
    };

/// The district of a city, as board 15 draws it (v1.355): the chart framed
/// on the district with a pin on the building of each way (numbered), and
/// under it the ways as numbered rows and "Walk on" chips to the other
/// districts; zoomed out, the whole town with its districts as rows. A pin
/// or a row opens the way's sheet.
class _CityDistrictView extends ConsumerWidget {
  const _CityDistrictView({
    required this.chart,
    required this.look,
    required this.explored,
    required this.hereDistrict,
    required this.focus,
    required this.focusToken,
    required this.steps,
    required this.districtOf,
    required this.palette,
    required this.text,
    required this.onFocus,
    required this.onOpen,
    required this.onWalk,
    required this.overlays,
    required this.tabs,
  });

  final CityChart chart;
  final MapLook look;
  final Set<String>? explored;
  final String? hereDistrict;

  /// The district in view; null the whole town.
  final String? focus;
  final int focusToken;
  final List<_Step> steps;

  /// The district each step's pin stands in (a step that leaves the city
  /// stands where the party does).
  final Map<int, String> districtOf;
  final ChartPalette palette;
  final CityChartText text;
  final void Function(String? districtId) onFocus;
  final void Function(int step) onOpen;
  final void Function(String districtId) onWalk;
  final List<Widget> overlays;
  final Widget tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // The rows sit on the page, not on the chart: the page's own colours.
    final ink = InkColors.of(context);
    final pagePalette = ChartPalette.of(theme.brightness == Brightness.dark
        ? MapLook.night
        : MapLook.parchment);
    // Each way's number: its place among its district's ways.
    // A way hangs as a banner in its category's colour (see
    // journey_banner_pin.dart); only the fights and rolls keep a numbered
    // round pin, and their row its number.
    final chartInk =
        look == MapLook.parchment ? InkColors.light : InkColors.dark;
    final chartDark = journeyInkIsDark(chartInk);
    final chartPalette = ChartPalette.of(look);
    final banners = <String, PinBanner>{};
    final numbers = <String, int>{};
    final byDistrict = <String, List<int>>{};
    for (var i = 0; i < steps.length; i++) {
      final d = districtOf[i];
      if (d == null) continue;
      final list = byDistrict.putIfAbsent(d, () => []);
      list.add(i);
      final cat = journeyPinCatOf(steps[i].kind, steps[i].questTie);
      if (cat == null) {
        numbers['$i'] = list.length;
      } else {
        banners['$i'] = PinBanner(
            cat,
            steps[i].locked
                ? chartPalette.label
                : look == MapLook.shroud && cat != JourneyPinCat.main
                    ? chartPalette.place
                    : cat.colorOn(chartInk, dark: chartDark));
      }
    }
    final shown = focus == null ? const <int>[] : byDistrict[focus] ?? const [];
    final others = [
      for (final d in chart.districts)
        if (d.id != focus) d,
    ];

    Widget kindDisc(_Step s, {double size = 30}) {
      final colour = s.locked
          ? ink.ash
          : _colorFor(s.kind, ink, pagePalette, greyed: false);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colour.withValues(alpha: 0.16),
          border: Border.all(color: colour, width: 1.5),
        ),
        child: Icon(_iconFor(s.kind), size: size * 0.55, color: colour),
      );
    }

    Widget numberDot(int n) => Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: ink.gold),
          child: Text('$n',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 11,
                  height: 1,
                  color: const Color(0xFF17151B))),
        );

    final rows = <Widget>[];
    if (focus != null) {
      final n = shown.length;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          (n == 1
                  ? tr(ref, 'journey_city_ways_one')
                  : tr(ref, 'journey_city_ways_many').replaceAll('{n}', '$n'))
              .toUpperCase(),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: ink.ash, letterSpacing: 0.8),
        ),
      ));
      for (final i in shown) {
        final s = steps[i];
        final way = chart.ways.where((w) => w.id == '$i').firstOrNull;
        final building = way == null ? '' : chart.buildingOf(way)?.name ?? '';
        final target = building == s.label ? '' : building;
        rows.add(InkWell(
          key: ValueKey('journey_city_row_$i'),
          onTap: () => onOpen(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: ink.seam))),
            child: Row(children: [
              if (banners['$i'] case final banner?)
                BannerPin(
                  key: ValueKey('journey_row_banner_$i'),
                  cat: banner.cat,
                  color: s.locked
                      ? banner.color
                      : banner.cat.colorOn(ink,
                          dark: theme.brightness == Brightness.dark),
                  dark: theme.brightness == Brightness.dark,
                  icon: s.locked ? Icons.lock_outline : null,
                  scale: 0.8,
                )
              else ...[
                numberDot(numbers['$i']!),
                const SizedBox(width: 8),
                kindDisc(s),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: s.locked ? ink.ash : null, height: 1.2)),
              ),
              if (target.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  ),
                ),
              ],
            ]),
          ),
        ));
      }
      if (others.isNotEmpty) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(tr(ref, 'journey_city_walk_on').toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, letterSpacing: 0.8)),
              for (final d in others)
                ActionChip(
                  key: ValueKey('journey_city_walk_${d.id}'),
                  visualDensity: VisualDensity.compact,
                  label: Text(explored == null || explored!.contains(d.id)
                      ? d.name
                      : '? ${d.name}'),
                  side: BorderSide(color: d.colour),
                  onPressed: () => onWalk(d.id),
                ),
            ],
          ),
        ));
      }
    } else {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(tr(ref, 'journey_city_districts').toUpperCase(),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: ink.ash, letterSpacing: 0.8)),
      ));
      for (final d in chart.districts) {
        final known = explored == null || explored!.contains(d.id);
        final n = byDistrict[d.id]?.length ?? 0;
        rows.add(InkWell(
          key: ValueKey('journey_city_district_${d.id}'),
          // A district not yet found is walked into (and so found), not
          // looked at under its fog.
          onTap: () => known ? onFocus(d.id) : onWalk(d.id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: ink.seam))),
            child: Row(children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: known ? d.colour : Colors.transparent,
                      border: Border.all(color: d.colour))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(known ? d.name : '?',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: known ? null : ink.ash)),
              ),
              Text(
                  d.id == hereDistrict
                      ? text.here
                      : !known
                          ? text.unexplored
                          : (n == 0 ? '' : text.ways(n)),
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ]),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CityChartView(
                  key: const ValueKey('journey_city_chart'),
                  chart: chart,
                  look: look,
                  text: text,
                  explored: explored,
                  hereDistrict: hereDistrict,
                  focus: focus,
                  focusToken: focusToken,
                  controls: false,
                  cards: false,
                  numbers: numbers,
                  banners: banners,
                  bannersDark: chartDark,
                  onFocus: onFocus,
                  onPick: (w) {
                    final i = int.tryParse(w.id);
                    if (i != null && i < steps.length) onOpen(i);
                  },
                  onPickFog: (_) {},
                ),
                ...overlays,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(alignment: Alignment.centerLeft, child: tabs),
        ),
        Expanded(
          flex: 9,
          child: ListView(
            key: const ValueKey('journey_city_list'),
            padding: EdgeInsets.zero,
            children: rows,
          ),
        ),
      ],
    );
  }
}
