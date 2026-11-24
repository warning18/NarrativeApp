import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/encounter_text.dart';
import '../data/first_journey.dart';
import '../data/clan_power.dart' show holderOf;
import '../data/city_camera.dart';
import '../data/geography.dart';
import '../data/choice_flow.dart';
import '../data/choice_shape.dart';
import '../data/scene_choice_mode.dart';
import '../data/city_districts.dart'
    show
        JourneyTownView,
        districtOfPlace,
        sceneDoorstep,
        sceneStreetOf,
        townMoveView;
import '../data/place_plan.dart';
import '../data/room_plan.dart';
import '../data/journey_map.dart';
import '../data/scene_flow.dart';
import '../data/story_plates.dart'
    show ChoiceWeight, choiceClanOf, choiceWeightOf;
import '../data/scene_lock.dart' show isHubScene, pageExitHidden;
import '../data/journey_relief.dart';
import '../data/map_charts.dart'
    show ChartGeography, ChartPalette, MapShape, chartOf;
import '../data/road_chart.dart';
import '../widgets/clan_offer_gifts.dart' show CardTier;
import '../data/world_leg_path.dart';
import '../data/world_roads.dart' show isWorldRoadLeg;
import '../data/narration_tokens.dart';
import '../data/party_trail.dart';
import '../data/quest_hints.dart' show mainQuestIdsOf;
import '../data/road_events.dart';
import '../data/story_repository.dart';
import '../data/scene_presentation.dart' show SceneView;
import '../data/way_places.dart' show wayPlaceName;
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/app_mode_provider.dart';
import 'crossing_rise_route.dart';
import '../data/camp_state.dart' show canReturnToCampFrom;
import '../providers/chapter_loop_provider.dart';
import '../providers/choice_flow_provider.dart';
import '../providers/city_provider.dart';
import '../providers/clans_provider.dart'
    show clanDataProvider, factionsProvider;
import '../providers/day_phase_provider.dart';
import '../providers/town_rulers_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../utils/slow_frames.dart' show slowFrameHint;
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/level_ladder.dart';
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
import '../widgets/town_service_sheet.dart';
import '../providers/town_services_provider.dart';
import '../widgets/geography_widgets.dart';
import '../widgets/scene_stage.dart';
import '../widgets/scene_vignette.dart';
import '../widgets/journey_fx.dart';
import '../widgets/prologue_opening.dart';
import '../widgets/story_scene_band.dart';
import '../widgets/story_text.dart';
import '../providers/story_text_provider.dart'
    show storyTextDoneProvider, storyTextSkipProvider;
import '../widgets/journey_glyph.dart';
import '../widgets/arrival_sheet.dart';
import '../widgets/district_places.dart';
import '../widgets/journey_banner_pin.dart';
import '../widgets/return_notice.dart';
import '../widgets/city_chart/city_chart.dart';
import '../widgets/city_chart/city_chart_painter.dart';
import '../widgets/city_chart/city_chart_view.dart';
import '../widgets/journey_place.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/camp_travel.dart' show CampReturnButton, TravelOnList;
import '../widgets/pixel_sprite.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/timed_choice_bar.dart';
import '../widgets/street_view/street_view.dart';
import '../widgets/district_standing.dart';
import '../widgets/town_walk.dart';
import '../widgets/way_pin_groups.dart';
import 'journal_screen.dart';
import 'city_chart_screen.dart';
import 'full_map_screen.dart';
import 'story_player_screen.dart'
    show
        EchoLine,
        StoryPlayerScreen,
        composeNarrationParts,
        isStoryChoiceLocked,
        noteShownEchoes,
        storyChoiceLockedText,
        storySceneLocked,
        takeStoryChoice;
import '../data/story_markup.dart' show stripStoryMarkup;
import '../widgets/ink_sheet.dart';
import '../widgets/ink_chip.dart';
import '../theme/palette.dart';
import '../theme/motion.dart';
import '../widgets/ink_loading.dart';
import '../theme/icon_sizes.dart';
import '../widgets/pixel_glyph.dart';

export '../providers/home_tab_provider.dart' show journeyTabIndex;

part 'journey/journey_choices.dart';
part 'journey/journey_transit.dart';
part 'journey/journey_panels.dart';
part 'journey/journey_step.dart';
part 'journey/journey_views.dart';
part 'journey/journey_taking.dart';
part 'journey/journey_maps.dart';
part 'journey/journey_maps_paint.dart';
part 'journey/journey_detail.dart';
part 'journey/journey_city.dart';

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
          loading: () => const InkLoading(),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${tr(ref, 'failed_to_load_story')}: $error'),
            ),
          ),
        );
  }
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

  /// Counts the words shown over the map, so each new one starts its own
  /// timer (see _PartyTransit's key).
  int _transitSerial = 0;

  /// Whether the map showed a building's room at the last build, and the
  /// doorway veil over the map as the party goes in or out (v1.537).
  bool? _showedRoom;
  IconData _doorIcon = Icons.login;
  late final AnimationController _door = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520), value: 1);

  /// The story carried the party to the scene it stands at now (a choice
  /// done here whose aftermath is elsewhere, or a one-tap return to a hub,
  /// see choice_flow.dart): the map plays the trip as for a lost fight. And
  /// the scene the party was last placed for on the map (a scene read full
  /// screen first is placed when the map comes back).
  bool _carried = false;
  String? _placedFor;

  /// Where the party stood inside the place it was last shown in (v1.246):
  /// the plan it stood on (the city's or a room's) and its district or spot.
  /// A scene the story carries it to along no walk, in the same place, has
  /// it travel the streets from there ([_arriveFrom], until shown once).
  String? _partyPlan;
  String _partyDistrict = '';
  String? _arriveFrom;

  /// A new scene's lone step is still to be picked for the player.
  bool _autoPickPending = false;

  /// Whether the way picked now was picked by the game (a scene's one way),
  /// not by the player: a tap on its mark on the map only confirms the pick,
  /// it never takes the step (Go does, a second tap, or a card's tap,
  /// v1.827). Before, the first tap on the map after "Back to the map" set
  /// the party on the road at once, and a way to another place rolled its
  /// detour.
  bool _pickedForPlayer = false;
  GlobalKey<_JourneyChartState> _chartKey = GlobalKey();

  /// How far out the map is looked at (v1.199): the place, its land, or
  /// the world; and the place last tapped on the chart.
  JourneyMapLevel _level = JourneyMapLevel.place;
  Landmark? _lookedAt;

  /// The whole town in view instead of the district (v1.350): the rung
  /// between the district and the world, for a place with a city plan.
  bool _townView = false;

  /// The party is walking a world road out of the place (v1.548): the map
  /// shows the World view, until the next scene.
  bool _roadWalk = false;

  /// Whether the place the map shows has a city plan to look at whole
  /// (set while building).
  bool _canTown = false;

  /// The Town rung asked for from inside a room: the party steps out first,
  /// and the whole town is shown once the build knows the town has a plan.
  bool _wantTown = false;

  /// The place (district or building) the party last stood at, for the
  /// view an in-town move shows (see townMoveView).
  String? _partyTownSpot;
  bool _moveFraming = false;

  /// The party's mark walking to a way's pin on a town's District view
  /// (v1.565): where it is on the plan while it walks (null: it stands at
  /// its own mark), the walk, and whether the District view shows the
  /// town's chart to walk on (set while building).
  final ValueNotifier<Offset?> _cityWalkAt = ValueNotifier(null);
  late final AnimationController _cityWalk = AnimationController(vsync: this);
  bool _cityWalkable = false;

  /// The district as places (v1.586, district_places.dart): the map's camera
  /// and the pin card, where the party's mark stands once it has gone to a
  /// place of the list (null: at its own mark), and the district whose arrival was last eased.
  final DistrictPlacesController _places = DistrictPlacesController();
  Offset? _placeMark;
  String? _arrivedAt;

  /// The chart of the city's stored plan, kept while its words hold.
  CityChart? _cityChart;
  String _cityChartKey = '';

  /// The district the map is framed on in a city drawn as board 15's chart
  /// (null: the party's own), and a count that asks the chart to frame it
  /// again.
  String? _cityFocus;
  int _cityFocusToken = 0;

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
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 200),
      value: 1);

  /// Whether the town's own map is what the place shows (set while
  /// building): it shrinks into its mark before the world takes over.
  bool _cityMapUp = false;

  /// A picture of the town's map as it was when the streets were left: it
  /// shrinks back into its mark over the world for 0.2 s, then is let go.
  ui.Image? _townShot;

  /// Where the plan sits in that picture, in the map box's own measure.
  Rect _townShotAt = Rect.zero;
  final GlobalKey _placeShotKey = GlobalKey();

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
    // (The town stays the view under the world: switching it to the
    // district here would have the plan re-frame unseen and report that
    // district when the streets come back.)
    _leaveForWorld(() {
      _enterZoom = (JourneyWorldMapZoom.max * from)
          .clamp(JourneyWorldMapZoom.land, JourneyWorldMapZoom.max);
      _level = JourneyMapLevel.world;
      _lookedAt = null;
      _pinch = 1;
      _pinching = false;
    });
  }

  /// A rung of the level strip: the world, the whole town, the district or
  /// the room, in one tap from any other.
  void _goLevel(LadderRung tab) {
    // A rung shows what it names: a move still playing over the map ends.
    if (_transit != null) setState(() => _transit = null);
    final inRoom = _level == JourneyMapLevel.place && _sceneInside && !_outside;
    switch (tab) {
      case LadderRung.room:
        if (!_sceneInside || inRoom) return;
        if (_level != JourneyMapLevel.place) _arriveAtStreets(town: false);
        setState(() => _townView = false);
        _goInside();
      case LadderRung.district:
        if (_level != JourneyMapLevel.place) {
          _arriveAtStreets(town: false);
        } else if (inRoom) {
          _stepOut();
        } else if (_townView) {
          _setTown(false, resetFocus: true);
        } else {
          // Already on a district: frame the party's own again.
          setState(() => _cityFocus = null);
          _setTown(false);
        }
      case LadderRung.town:
        if (_level != JourneyMapLevel.place) {
          _arriveAtStreets();
        } else if (inRoom) {
          _stepOut(town: true);
        } else if (_canTown && !_townView) {
          _setTown(true);
        }
      case LadderRung.world:
        if (_level == JourneyMapLevel.place) {
          _leaveForWorld(() {
            // The ball opens close on the place and pulls back out.
            _enterZoom = JourneyWorldMapZoom.max;
            _level = JourneyMapLevel.world;
            _lookedAt = null;
            _pinch = 1;
            _pinching = false;
          });
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
      // A scene inside a building had no town to show while its room was
      // up: the build shows it once the streets are back.
      _wantTown = town && !_canTown && _sceneInside;
      _cityFocusToken++;
      if (!town) _cityFocus = null;
      _level = JourneyMapLevel.place;
      _dropTownShot();
      _lookedAt = null;
      _outside = _sceneInside;
      // Coming down from the world is not a walk through the door: no
      // veil, no words; the streets grow out of the place.
      _showedRoom = null;
    });
    // The chart's report of the district it framed last comes a frame
    // late: it is not the player's pick, and must not undo the town.
    if (town) {
      _moveFraming = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => WidgetsBinding
          .instance
          .addPostFrameCallback((_) => _moveFraming = false));
    }
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

  /// Each landmark where a shop opens; read once per story.
  Set<String>? _shopPlaces;
  StoryData? _shopPlacesOf;

  /// The calques sheet: one calque over the chart at a time, or none.
  Future<void> _showCalques() => showCalquesSheet(context, ref);

  /// The scene read full screen (double-tap on it, again to come back).
  bool _reading = false;

  /// Whether the scene shown is a new game's first scene, opened as a page.
  bool _openedFresh = false;

  /// The first scene's text has been told as the opening animation (a new
  /// scene resets it): the way back to the map waits for it.
  bool _openingTold = false;

  /// The scene the story brought the party to (v1.553, scene_lock.dart):
  /// a way taken into it (a pin or a card), a new game's first scene, or a
  /// save picked back up on it. While it holds a way acted out here, its
  /// page holds the party: every way is a card and the map waits.
  String? _lockedAt;

  /// The play state the last new scene was shown for: a scene reached
  /// otherwise than by a step from it (a save loaded) is one the story
  /// brought the party to; a jump (a step) is not.
  StoryPlayState? _shownPlay;

  /// A road card taken on a locked page: the map comes back and walks it.
  StoryChoice? _walkOn;

  /// The scene of a place the party just arrived at, in a sheet over the map
  /// (S2, see arrival_sheet.dart); Continue closes it.
  bool _arrival = false;

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

  /// The jolt going into a fight: the map shakes and its edges run red.
  late final AnimationController _jolt =
      AnimationController(vsync: this, duration: fightJoltDuration);

  @override
  void dispose() {
    slowFrameHint = null;
    _jolt.dispose();
    _dropTownShot();
    _arrive.dispose();
    _door.dispose();
    _cityWalk.dispose();
    _cityWalkAt.dispose();
    _places.dispose();
    super.dispose();
  }

  /// Where the party's mark stands at the place it went to, while it stays
  /// there (null: at its own mark).
  Offset? get _markAtPlace =>
      ref.read(partyPlaceProvider) == null ? null : _placeMark;

  /// The party goes to a place of the district's list (v1.586): its mark
  /// walks to the place's pin (a tap skips the walk), then the place's ways
  /// show. `Here` and a way out have no pin to walk to.
  Future<void> _goPlace(PlaceInfo place) async {
    final chart = _cityChart;
    if (_busy || chart == null || place.steps.isEmpty) return;
    _places.card.value = null;
    final walks = !place.here && !place.wayOut;
    final first = chart.ways.where((w) => w.id == '${place.steps.first}');
    final pin = walks && first.isNotEmpty ? _wayPin(chart, first.first) : null;
    if (pin != null &&
        _cityWalkable &&
        !MediaQuery.of(context).disableAnimations) {
      await _walkCity(place.steps.first);
      if (!mounted) return;
    }
    _cityWalkAt.value = null;
    setState(() => _placeMark = pin);
    standAtPlace(ref, place.id);
  }

  /// The party back at the district's list of places.
  void _leavePlace() {
    setState(() => _placeMark = null);
    leavePlace(ref);
  }

  /// A tap during the walk on the town's chart: the party is there at once.
  void _skipCityWalk() {
    if (!_cityWalk.isAnimating) return;
    _cityWalk.stop(canceled: false);
    _cityWalk.value = 1;
  }

  /// Reads the scene full screen, or comes back to the map; not while the
  /// party walks, whose map would go from under it.
  void _read(bool reading) {
    if (_busy) return;
    setState(() {
      _reading = reading;
      _arrival = false;
      _lockedAt = null;
    });
  }

  /// The height of the panel under the map: a way picked fills it as it
  /// did; with choices acted out here, the cards get more of the screen.
  /// Whether the scene being played is a written detour (see
  /// detour_scene_band.dart): its ways are all cards.
  bool _writtenDetour = false;

  /// [setState] for the part files: it is @protected, so the extensions on
  /// this state (see journey/) call this instead.
  void _update(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    // For the slow-frames report: which view the Journey is showing.
    slowFrameHint = _reading ? 'reading page' : 'map';
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
      _openingTold = false;
      _selected = null;
      _pickedForPlayer = false;
      _autoPickPending = true;
      _chartKey = GlobalKey();
      _outside = false;
      // A new game opens on its first scene's page, as any main-story
      // scene arrived at does; the map comes after.
      final editing = ref.read(appModeProvider) == AppMode.edit;
      final fresh = !editing && isFreshStoryStart(play);
      // The scene the Journey first shows, or one the story was put back
      // on (a save loaded): not a step from the last scene shown.
      final shown = _shownPlay;
      final stepped = shown != null &&
          (shown.isInExcursion ||
              play.isInExcursion ||
              (play.history.length == shown.history.length + 1 &&
                  play.history.last == shown.currentNodeId));
      _shownPlay = play;
      if (fresh) {
        _reading = true;
        _arrival = false;
        _lockedAt = sceneKey;
      } else if (!editing && !stepped) {
        // A save picked back up: its page holds the party if its scene
        // locks (see below), the map otherwise.
        if (_lockedAt != null) _reading = false;
        _lockedAt = sceneKey;
      } else if (_openedFresh || (_lockedAt != null && _lockedAt != sceneKey)) {
        // Moved on from a page the story opened by other means than a way
        // taken here (a jump): the map, as before.
        _reading = false;
        _lockedAt = null;
      }
      _openedFresh = fresh;
    }

    final tools = [
      IconButton(
        icon: const Icon(Icons.menu_book_outlined, size: IconSize.s16),
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
        !ref.read(storyPlayProvider).isInExcursion) {
      tools.add(IconButton(
        key: const ValueKey('journey_city_plan'),
        icon: const Icon(Icons.map_outlined, size: IconSize.s16),
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
    final geography = chartOf(MapShape.story);
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
    final stops = ref.watch(storyStopsProvider);
    final mainQuestIds = mainQuestIdsOf(
        ref.watch(localizedDbProvider(questsSchema)).value ?? const {});
    // A way out told by a departure scene still here (`place: out`,
    // v1.851) ends where the departure's road does.
    String endOf(StoryChoice c) => play.isInExcursion || c.isEnding || !reading
        ? c.nextId
        : readThroughEnd(
            wayOutEndOf(c, story),
            nodeFor: story.nodeFor,
            flags: session.flags,
            hidden: (x, held) => choiceHiddenFor(
                x, session.copyWith(flags: held.toList()), gateWorld),
            // The read-through stops where the stop changes (choice_flow).
            travels: (from, to) =>
                stops?.changesStop(from, to) ??
                world.travelsBetween(story, from, to),
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
                  isExcursion: play.isInExcursion,
                  world: gateWorld,
                  shutWays: ref.watch(lockedStoryWaysProvider));
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
              world.travelsBetween(
                  story, play.currentNodeId, wayOutEndOf(choice, story));
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
    // A city, a town or a village of the geography is drawn from its
    // stored plan (city_plans.json, below), its districts on it; every
    // one has a record (city_plan_record_test). The procedural plan
    // (v1.203) is no longer built (N11, v1.794).
    final districtOfStep = <int, String>{};
    final isCity = hereLocation != null &&
        chartHere != null &&
        const {'city', 'town', 'village'}.contains(hereLocation.kind);
    if (isCity) {
      for (var i = 0; i < choices.length; i++) {
        final place = world.placeOfNode(story.nodeFor(ends[choices[i]]!));
        if (place == null || place.id == herePlace?.id) continue;
        if (world.locationOf(place.id)?.id != hereLocation.id) continue;
        // A way into a building stands in the building's district.
        districtOfStep[i] = districtOfPlace(world, place.id)?.id ?? '';
      }
    }
    // The city's stored plan (Core's city_plans.json, board 15): the plan
    // the ways are laid on and the chart drawn under them.
    PlacePlan? cityPlan;
    final cityDistrictOf = <int, String>{};
    // The building whose street the scene plays in (v1.589, sceneStreetOf).
    GeoPlace? sceneStreet;
    final hereDistrictOf = ref.watch(partyDistrictProvider);
    CityChart? cityChart;
    Set<String>? foundDistricts;
    // A scene inside a building (the Blind Beggar) keeps its room; looking
    // out of it shows the city's chart, with a button back in (v1.425).
    if (isCity) {
      final record = ref.watch(cityPlanRecordsProvider).value?[hereLocation.id];
      if (record != null) {
        cityPlan = record;
        // Each way is pinned in its district; one that leaves the city
        // stands where the party does.
        final ownDistrict = record.districts.containsKey(hereDistrictOf)
            ? hereDistrictOf
            : null;
        // A scene played at a building's doorstep (v1.542): the party at
        // its door, the ways that stay there in the street round it.
        sceneStreet = sceneStreetOf(world, record, node);
        final doorstep = sceneDoorstep(world, record, node, waysHere: [
          for (var i = 0; i < rawSteps.length; i++)
            if (!districtOfStep.containsKey(i)) i,
        ]);
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
                  at: doorstep?.spotOfWay[e.key],
                ),
            ],
            french: french,
            name: hereLocation.nameFor(french),
            doorstep: doorstep?.buildingId,
          );
        }
        cityChart = _cityChart;
        foundDistricts = ref.watch(foundDistrictsProvider);
      }
    }
    // Inside a building (v1.207): the room's plan, the party at its spot
    // and each way at the spot it is taken from, or at the door it leaves
    // by; the streets are one look out.
    // A scene played at its building's doorstep (v1.542) is on the streets.
    final hereBuilding = (herePlace?.isBuilding ?? false) &&
            !herePlace!.doorstep.contains(play.currentNodeId) &&
            !(story.nodeFor(play.currentNodeId)?.sceneInStreet ?? false)
        ? herePlace
        : null;
    _sceneInside = hereBuilding != null;
    // The room and the streets round it are told apart by a doorway and a
    // line of words, both ways (v1.537).
    final showsRoom = hereBuilding != null && !_outside;
    if (_showedRoom != null &&
        _showedRoom != showsRoom &&
        !play.isInExcursion &&
        _level == JourneyMapLevel.place) {
      _passDoor(
          entering: showsRoom,
          text: showsRoom
              ? tr(ref, 'journey_step_in').replaceAll(
                  '{place}', townNameInSentence(hereBuilding.nameFor(french)))
              : tr(ref, 'journey_step_out'));
    }
    _showedRoom = showsRoom;
    RoomPlan? room;
    var hereSpot = '';
    final leavesRoom = <int>{};
    if (hereBuilding != null && !_outside) {
      room = RoomPlan.ofBuilding(
          hereBuilding.id, hereBuilding.kind, hereBuilding.name);
      final spot = node.spot ?? '';
      hereSpot = spot.isNotEmpty && room.has(spot) ? spot : 'floor';
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
    final placed =
        !play.isInExcursion && placeLandmark != null && chartHere != null;
    // A scene with a choice to make keeps it on the map (v1.825, as before
    // v1.809): the city chart's banners, the room plan's spots, the place
    // view's pins and cards. Only a scene with nothing to choose, its one
    // way leading to the next scene at the same stop (choice_flow.dart's
    // FlowStay), has it as a card: the story goes on with no map.
    final single =
        choices.length == 1 && stops?.flowOf(node, choices.single) is FlowStay;
    // In a place drawn with no plan, a move that pays, checks or fights on
    // its way is still a move: a pin with its tag, not a card (v1.854, the
    // user's call: every move is on the map). A decision that weighs on the
    // conscience (choice_shape's `decide`) stays a card. On a town's chart a
    // move into a district not yet found would stand in its fog, so there
    // it stays a card (with its tag) as before.
    bool moves(int i) =>
        cityPlan == null &&
        (shapes[i].move == ChoiceMove.walk ||
            shapes[i].move == ChoiceMove.travel) &&
        shapes[i].action != ChoiceAction.decide;
    final onCard = [
      for (var i = 0; i < shapes.length; i++)
        _writtenDetour ||
            placed && ((room == null && shapes[i].here && !moves(i)) || single),
    ];
    final pinSlots = journeySlots(onCard.where((c) => !c).length);
    var pinCount = 0;
    for (var i = 0; i < steps.length; i++) {
      steps[i].shape = shapes[i];
      steps[i].tags = choiceTags(node, steps[i].choice,
          story: story, geography: world, shape: shapes[i]);
      steps[i].tag = _stepTag(ref, steps[i], InkColors.of(context));
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
      if (steps.length == 1 && !steps.single.locked) {
        _selected = 0;
        _pickedForPlayer = true;
      }
    }
    if (_cityPick != null) {
      final i = steps.indexWhere((s) => identical(s.choice, _cityPick));
      if (i >= 0) _selected = i;
      _cityPick = null;
    }
    final selected = _selected != null && _selected! < steps.length
        ? steps[_selected!]
        : null;
    // The words write themselves out when the scene is new (Edit Mode shows
    // them at once); its choices come once they have, and a tap on Continue
    // before that shows them all first.
    // A scene the writer cut into pages (narration_pages.dart, v1.750) is
    // read a page at a time: Continue turns the page, and its choices wait
    // on the last one. Each page writes itself out on its own.
    final pageCount = composeNarrationParts(
            node, ref.watch(playerSessionProvider), story,
            french: french, revisit: isRevisit(play))
        .pages
        .length;
    final pageKey = scenePageKey(play, node.id);
    final page = scenePageOf(ref.watch(scenePageProvider), pageKey, pageCount);
    final lastPage = page >= pageCount - 1;
    final revealKey = ref.watch(appModeProvider) == AppMode.edit
        ? null
        : 'journey|$sceneKey${page > 0 ? '#p$page' : ''}';
    final textReady = revealKey == null ||
        storyTextShownAtOnce(context) ||
        ref.watch(storyTextDoneProvider).contains(revealKey);
    // The choices come once the last page is written out.
    final choicesReady = textReady && lastPage;
    void continueFromScene() => !textReady
        ? ref.read(storyTextSkipProvider.notifier).state++
        : !lastPage
            ? ref.read(scenePageProvider.notifier).state =
                (key: pageKey, page: page + 1)
            : _read(false);
    // Read full screen, the scene has the tab to itself: its words, then the
    // choices acted out here (cards, or a chip for each kind in a hub), then
    // the way back to the map. The map keeps only the ways that carry the
    // party somewhere.
    // A scene the story brought the party to, with a way acted out here,
    // holds it on its page (v1.553, scene_lock.dart): every way is a card,
    // the map waits. A written detour has no map to leave already.
    // Only a scene none of whose ways the map draws locks (a pin, a way on
    // the city chart, a spot in a room). Before the places or a city's
    // plans have loaded, every way counts as drawn: nothing locks before
    // the map knows where its ways are.
    final cityLoading = world.isEmpty ||
        isCity && ref.watch(cityPlanRecordsProvider).value == null;
    final mapped = Map<StoryChoice, bool>.identity()
      ..addAll({
        for (var i = 0; i < steps.length; i++)
          steps[i].choice: !steps[i].onCard ||
              room != null ||
              cityDistrictOf.containsKey(i) ||
              cityLoading,
      });
    final locked = _lockedAt == sceneKey &&
        !_writtenDetour &&
        storySceneLocked(ref, node, story, mapped: (c) => mapped[c] ?? true);
    if (locked) {
      _reading = true;
      _arrival = false;
    }
    // A road card taken on a locked page: the map is back, the party walks.
    if (_walkOn != null && !_reading) {
      final way = _walkOn;
      _walkOn = null;
      final i = steps.indexWhere((s) => identical(s.choice, way));
      if (i >= 0) {
        final step = steps[i];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _take(i, step);
        });
      }
    }
    if (!_reading) _closeMap(false);
    if (_reading) {
      // A page the story brought the party to whose cards hold every move
      // the map would offer (scene_lock.dart's pageExitHidden, v1.565): no
      // way back to the map; its pins are road cards under the others.
      // A new game's first page keeps its way back (the map before the
      // character is made).
      final held = !locked &&
          _lockedAt == sceneKey &&
          !_openedFresh &&
          !_writtenDetour &&
          pageExitHidden(
            ways: [
              for (final s in steps)
                (card: s.onCard, takeable: !s.locked, to: s.shape.to?.id),
            ],
            hub: isHubScene(node) || _isHub(steps),
            ending: isStoryEnding(node),
            editMode: ref.watch(appModeProvider) == AppMode.edit,
          );
      final here = locked || held || steps.any((s) => s.onCard);
      // A locked page has no way back to the map: the cards take the story
      // on, and the map's tabs and buttons wait, greyed ("Choose first").
      // Nor has a new game's first page, before the hero is made: the game
      // hasn't started (the user's call, v1.692).
      final toMap = !locked &&
          !held &&
          !(isFreshStoryStart(play) &&
              ref.watch(appModeProvider) != AppMode.edit);
      _closeMap(!toMap);
      // The button names the map: the way back to it, or, locked, the way
      // that waits.
      // A new game's first scene is told as an animation, its choice
      // settling under the text (prologue_opening.dart).
      final opening = here &&
          !locked &&
          revealKey != null &&
          !play.isInExcursion &&
          isPrologueOpening(node);
      // With reduced motion the text is whole at once.
      final ready = opening
          ? _openingTold || MediaQuery.of(context).disableAnimations
          : textReady;
      final toMapLabel = lastPage && here && (toMap || ready);
      final waitLine = Text(
        tr(ref, 'journey_choose_first'),
        key: const ValueKey('journey_choose_first'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: InkColors.of(context).ash, fontStyle: FontStyle.italic),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              if (locked) ...[
                // The greyed tabs, and the followed quest: its goal stays
                // in sight while the player chooses.
                Row(
                  children: [
                    Expanded(
                      child: LevelLadder(
                        lit: null,
                        open: const {},
                        busy: true,
                        palette: palette,
                        onPick: (_) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    const QuestTrackerBar(compact: true),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (opening)
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PrologueOpening(
                          key: ValueKey('journey_reading_$sceneKey'),
                          text: composeNarrationParts(
                                  node, ref.watch(playerSessionProvider), story,
                                  french: french, revisit: isRevisit(play))
                              .text,
                          told: _openingTold,
                          onTold: () {
                            if (mounted && !_openingTold) {
                              setState(() => _openingTold = true);
                            }
                          },
                          choices: _choicePanel(
                              steps, _pickedCard(selected), french, story,
                              shrinkWrap: true),
                        ),
                      ),
                      // The map's corner button, as on any page read whole.
                      if (toMap)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            key: const ValueKey('journey_reading_exit'),
                            icon: const Icon(Icons.map_outlined,
                                size: IconSize.s16),
                            tooltip: tr(ref, 'journey_reading_exit'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _read(false),
                          ),
                        ),
                    ],
                  ),
                )
              else ...[
                Expanded(
                  child: _ScenePanel(
                    revealKey: revealKey,
                    key: ValueKey('journey_reading_$sceneKey'),
                    story: story,
                    node: node,
                    french: french,
                    folded: false,
                    reading: true,
                    toMap: toMap,
                    locked: locked,
                    onFold: (_) {},
                    onReading: (r) {
                      if (r || toMap) _read(r);
                    },
                    detour: detour,
                  ),
                ),
                if (here && choicesReady) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.42),
                    child: _choicePanel(
                        steps,
                        locked || held ? selected : _pickedCard(selected),
                        french,
                        story,
                        shrinkWrap: true,
                        all: locked || held,
                        lead: _vignetteFor(node, steps, story, world, french,
                            picked:
                                locked || held ? null : _pickedCard(selected))),
                  ),
                ],
              ],
              // On a locked page, Continue only shows the words at once;
              // then the way back to the map waits, greyed.
              if ((toMap || !ready || locked || !lastPage) &&
                  !(opening && !ready)) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('journey_continue'),
                    onPressed: !lastPage
                        ? continueFromScene
                        : locked && ready
                            ? null
                            : opening
                                ? () => _read(false)
                                : continueFromScene,
                    icon: Icon(
                        toMapLabel ? Icons.map_outlined : Icons.arrow_forward,
                        size: IconSize.s16),
                    label: Text(tr(
                        ref,
                        toMapLabel
                            ? 'journey_reading_exit'
                            : 'journey_continue')),
                  ),
                ),
                if (locked && ready && lastPage) ...[
                  const SizedBox(height: 4),
                  waitLine,
                ],
              ],
            ],
          ),
        ),
      );
    }

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
            loading: isCity && cityPlan == null,
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
    if (_wantTown && placeView?.room == null) {
      _wantTown = false;
      if (_canTown) {
        _townView = true;
        _cityFocusToken++;
      }
    }
    // A move inside one town (v1.534) is a walk on its plan, and the view
    // follows it: the whole town for another district, the district for the
    // same one.
    String? townWalkTo;
    if (_placedFor != sceneKey && !play.isInExcursion) {
      final town = townMoveView(world, _partyTownSpot, herePlace?.id);
      if (town != null && _canTown) {
        // Another district: the walk is told in words too (v1.537).
        if (town == JourneyTownView.town && herePlace != null) {
          townWalkTo = herePlace.nameFor(french);
        }
        _level = JourneyMapLevel.place;
        _townView = town == JourneyTownView.town;
        _cityFocus = null;
        _cityFocusToken++;
        // The chart's report of the district it framed before the move
        // comes a frame late: it is not the player's pick.
        _moveFraming = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => WidgetsBinding
            .instance
            .addPostFrameCallback((_) => _moveFraming = false));
      }
      _partyTownSpot = herePlace?.id;
    }
    final townView = _townView && _canTown;
    // A city with Core's stored plan is drawn as board 15's district view
    // (not in a detour, nor from inside a room).
    final hostedCity =
        cityChart != null && placeView?.room == null && !play.isInExcursion;

    // Where the party stands on the world (v1.245): a scene the story
    // carried it to without a walk (a fight lost, a roll failed, the travel
    // list) is reached by the road from where it stood, and the map says why.
    if (_placedFor != sceneKey && !play.isInExcursion) {
      _placedFor = sceneKey;
      _roadWalk = false;
      final carried = _carried;
      _carried = false;
      final to = placeView?.chartHere;
      // The editor's jumps are tools, not travel: no road walked for them.
      final editorJump = ref.read(appModeProvider) == AppMode.edit;
      if (to != null) {
        final from = _partyChart;
        final previousId = play.history.isEmpty ? null : play.history.last;
        final cause = partyMoveCause(story, previousId, play.currentNodeId) ??
            (carried ? PartyMoveCause.carried : null);
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
                    path: far &&
                            _partyLandmark != null &&
                            standing != null &&
                            _partyLandmark != standing.id
                        ? worldLegPath(
                            journeyChartOf(ref), _partyLandmark!, standing.id,
                            language: language)
                        : null,
                    forced: forced,
                    caption: partyMoveNote(
                            story, previousId, play.currentNodeId,
                            french: french) ??
                        tr(ref, 'journey_move_${cause.name}')
                            .replaceAll('{place}', hereName),
                  )
                : null;
        if (_transit == null && townWalkTo != null && !editorJump) {
          _transit = _Transit.words(tr(ref, 'journey_walk_to')
              .replaceAll('{place}', townNameInSentence(townWalkTo)));
        }
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
    Widget worldMapWith(
            {required JourneyMapLevel level,
            WorldLegPath? move,
            Animation<double>? clock}) =>
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: JourneyWorldMap(
            key: move == null ? const ValueKey('journey_world_map') : null,
            move: move,
            moveClock: clock,
            level: level,
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
              MapLook.shroud => Palette.stone65,
            },
            onLayers: _showCalques,
            onSelect: (landmark) => setState(() => _lookedAt = landmark),
            onZoomIn: _arriveAtStreets,
            enterZoom: _enterZoom,
            // The full map is the World rung enlarged: it carries the same
            // strip, and a rung picked there is gone to here.
            onFullMap: () async {
              final rung = await Navigator.of(context).push<LadderRung>(
                MaterialPageRoute(
                  builder: (_) => FullMapScreen(rungs: {
                    LadderRung.district,
                    if (_sceneInside) LadderRung.room,
                    if (cityChart != null) LadderRung.town,
                  }),
                ),
              );
              if (rung != null && rung != LadderRung.world && mounted) {
                _goLevel(rung);
              }
            },
            fog: editing ? ChartFog.none : ChartFog.uncharted,
          ),
        );
    final worldMap = worldMapWith(level: _level);

    final travelsFromHere = !play.isInExcursion &&
        canReturnToCampFrom(node,
            inExcursion: play.isInExcursion, flags: session.flags);
    final travelsOn = travelsFromHere &&
        ref.watch(knownPlacesProvider).any((p) => p.id != node.id);

    final inRoomNow =
        _level == JourneyMapLevel.place && _sceneInside && !_outside;
    final levelTabs = LevelLadder(
      lit: _level != JourneyMapLevel.place || _roadWalk
          ? LadderRung.world
          : inRoomNow
              ? LadderRung.room
              : townView
                  ? LadderRung.town
                  : LadderRung.district,
      open: {
        LadderRung.world,
        LadderRung.district,
        // From a room the party steps out first: the Town rung is open
        // wherever the town has a plan to show.
        // On the World too: no Town where the place has no plan.
        if (_canTown ||
            ((_level != JourneyMapLevel.place || inRoomNow) &&
                cityChart != null))
          LadderRung.town,
        if (_sceneInside) LadderRung.room,
      },
      busy: _busy,
      palette: palette,
      onPick: _goLevel,
    );
    // A scene at a doorstep is its street, not the sheet over it (the words
    // are behind Read; no text is laid over the map, v1.607).
    final viewOfScene = ref.watch(scenePresentationProvider)?.viewOf(node.id);
    final streetShown =
        cityChart != null && cityChart.here != null && !play.isInExcursion;
    final streetScene = hostedCity &&
        !ended &&
        !townView &&
        !_reading &&
        viewOfScene == SceneView.street &&
        streetShown;
    if (_arrival && streetScene) _arrival = false;
    // An arrival in a district: the map eases in on the party (v1.586). Read
    // from the party's district here, compared with the last one seen.
    // (Not on the Town view a move to another district frames: that view is
    // the one asked for.)
    final hereDistrictNow = ref.watch(partyDistrictProvider);
    if (!hostedCity || hereDistrictNow == null) {
      _arrivedAt = null;
    } else if (!townView && hereDistrictNow != _arrivedAt) {
      _arrivedAt = hereDistrictNow;
      final at =
          cityChart.here ?? cityChart.districtById(hereDistrictNow)?.centre;
      final jump = MediaQuery.of(context).disableAnimations;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _places.camera.show(
            CityCameraShot.arrival(hereDistrictNow, partyAt: at, jump: jump));
      });
    }
    final cityView = hostedCity && !ended
        ? _CityDistrictView(
            chart: cityChart,
            look: look,
            partyWalk: _cityWalkAt,
            places: _places,
            placeMark: _placeMark,
            onGoPlace: _goPlace,
            onLeavePlace: _leavePlace,
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
              if (_moveFraming) return;
              if (d == null) {
                if (!_townView) _setTown(true);
              } else if (_townView || _cityFocus != d) {
                setState(() {
                  _townView = false;
                  _cityFocus = d;
                });
              }
            },
            street: cityChart.here != null ? sceneStreet : null,
            onOpen: (i) => _openWay(i, steps, french),
            onOpenPin: (ways, name) => _openPin(ways, name, steps, french),
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
                    onTap: _busy ? null : () => _goLevel(LadderRung.district),
                  ),
                ),
              // A scene inside a building keeps its room: looking out at the
              // city chart, the way back in is a button (v1.425).
              if (_sceneInside && _outside && !townView)
                Positioned(
                  right: 8,
                  bottom: 48,
                  child: _MapButton(
                    key: const Key('journey_go_inside'),
                    icon: Icons.add,
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
                  onTap: _busy ? null : _lookOut,
                ),
              ),
            ],
            tabs: levelTabs,
          )
        : null;
    // The party's mark walks to a way's pin on the town's chart (v1.565):
    // on the District view, not at a doorstep (its street is drawn there).
    _cityWalkable = cityView != null &&
        _level == JourneyMapLevel.place &&
        !townView &&
        cityChart?.here == null;
    // While it walks, a tap anywhere on the map lands it there at once.
    _cityMapUp = cityView != null;
    final cityMap = cityView == null
        ? null
        : Stack(
            fit: StackFit.expand,
            children: [
              cityView,
              ValueListenableBuilder<Offset?>(
                valueListenable: _cityWalkAt,
                builder: (context, at, _) => at == null
                    ? const SizedBox.shrink()
                    : Positioned.fill(
                        child: GestureDetector(
                          key: const ValueKey('journey_city_walk_skip'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _skipCityWalk,
                        ),
                      ),
              ),
            ],
          );

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
                text: stripStoryMarkup(node.descriptionFor(french)),
                note: node.contextNoteFor(french) ?? '',
              )
            : TutorialTarget(
                id: 'journey.chart',
                // Going into a fight the map jolts and its edges run red (see
                // _take).
                child: FightJolt(
                  controller: _jolt,
                  colour: InkColors.dark.blood,
                  child: cityMap ??
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
                                duration: Motion.base,
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
                                  // Inside a building the label names it,
                                  // not its town.
                                  hereName: _sceneInside && !_outside
                                      ? hereBuilding?.nameFor(french) ??
                                          hereName
                                      : hereName,
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
                                  onTap: (j, step) =>
                                      _tap(_pinIdx[j], step, fromMap: true),
                                  stamp: _stamp,
                                  burn: _burn,
                                  unroll: _unroll,
                                  // No rain, snow or ash under a roof.
                                  weather: _sceneInside && !_outside
                                      ? JourneyWeather.none
                                      : journeyWeatherOf(sky?.kind, chapter),
                                  stepIds: _pinIdx,
                                  // The choices acted out here are in the
                                  // scene view, not on the map.
                                  rings: const [],
                                  ringLit: _ringOpen,
                                  onRing: (id) =>
                                      _openList(id, steps, french, story),
                                  place: placeView?.pinned(_pinIdx),
                                  arriveFrom: _arriveFrom,
                                  townView: townView,
                                  // A way to another place walks the world
                                  // road on the World view (v1.548).
                                  roadLeg: (step) => isWorldRoadLeg(
                                          standing?.id, step.targetLandmark)
                                      ? worldLegPath(journeyChartOf(ref),
                                          standing!.id, step.targetLandmark!,
                                          language: language)
                                      : null,
                                  roadMap: (path, clock) => worldMapWith(
                                      level: JourneyMapLevel.world,
                                      move: path,
                                      clock: clock),
                                  onRoadWalk: () =>
                                      setState(() => _roadWalk = true),
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
                                    : () => _goLevel(LadderRung.district),
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
                              onTap: _busy ? null : _lookOut,
                            ),
                          ),
                        ],
                      ),
                ),
              );

    // The guide shows the tab around the first time it opens (see
    // TutorialTopic.journey), once there is a character to follow.
    final screen = TutorialTrigger(
      topic: TutorialTopic.journey,
      // In a new game it waits for the party's first step outside, where
      // the map opens on its own (first_journey.dart).
      ready: session.raceId.isNotEmpty &&
          journeyTourDue(session.flags,
              chapter: chapterOfNode(play.currentNodeId)),
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
                                  // The choices acted out here are in the
                                  // scene view: a button opens it.
                                  if (!_writtenDetour &&
                                      steps.any((s) => s.onCard))
                                    IconButton.filledTonal(
                                      key: const ValueKey(
                                          'journey_open_choices'),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: tr(ref, 'journey_choices_here')
                                          .replaceAll('{n}',
                                              '${steps.where((s) => s.onCard).length}'),
                                      onPressed:
                                          _busy ? null : () => _read(true),
                                      icon: Badge(
                                        label: Text(
                                            '${steps.where((s) => s.onCard).length}'),
                                        child: const Icon(
                                            Icons.touch_app_outlined,
                                            size: IconSize.s16),
                                      ),
                                    ),
                                  TutorialTarget(
                                    id: 'journey.scene',
                                    child: TextButton.icon(
                                      key: const ValueKey('journey_read'),
                                      onPressed:
                                          _busy ? null : () => _read(true),
                                      icon: const Icon(
                                          Icons.chrome_reader_mode_outlined,
                                          size: IconSize.s16),
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
                                              Positioned.fill(
                                                child: RepaintBoundary(
                                                  key: _placeShotKey,
                                                  child: cityMap == null
                                                      ? map
                                                      : _GrowIn(
                                                          clock: _arrive,
                                                          child: map),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: TownDoorVeil(
                                                  clock: _door,
                                                  colour: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                  icon: _doorIcon,
                                                  still: MediaQuery.of(context)
                                                      .disableAnimations,
                                                ),
                                              ),
                                              if (_transit != null &&
                                                  placeView != null &&
                                                  !ended)
                                                Positioned.fill(
                                                  child: _PartyTransit(
                                                    key: ValueKey(
                                                        'journey_transit_$sceneKey$_transitSerial'),
                                                    transit: _transit!,
                                                    mapBuilder: (path, clock) =>
                                                        worldMapWith(
                                                            level:
                                                                JourneyMapLevel
                                                                    .world,
                                                            move: path,
                                                            clock: clock),
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
                                        // The world, and over it for a
                                        // moment the town shrinking into
                                        // its mark. (One Stack either way,
                                        // so the ball keeps its state when
                                        // the picture is let go.)
                                        : Stack(children: [
                                            Positioned.fill(child: worldMap),
                                            if (_townShot != null)
                                              Positioned.fromRect(
                                                rect: _townShotAt,
                                                child: IgnorePointer(
                                                  child: _GrowIn(
                                                    clock: _arrive,
                                                    child: CustomPaint(
                                                      key: const ValueKey(
                                                          'journey_town_leaving'),
                                                      painter: _TownShotPainter(
                                                          _townShot!,
                                                          _townShotAt,
                                                          MediaQuery
                                                              .devicePixelRatioOf(
                                                                  context)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ]),
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
                                          size: IconSize.s16),
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
                                          _writtenDetour &&
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
    // A place just arrived at: its scene in a sheet over the map (S2); a
    // one-tap return says "You came back to ..." over it.
    return ReturnNoticeHost(
      child: !_arrival
          ? screen
          : Stack(
              children: [
                screen,
                Positioned.fill(
                  child: ArrivalSheet(
                    title: hereName,
                    continueLabel: tr(ref, 'journey_continue'),
                    closeTip: tr(ref, 'journey_continue'),
                    onContinue: continueFromScene,
                    // The choices are whole, up to 70% of the room the sheet
                    // gives; the words take the rest and scroll.
                    child: LayoutBuilder(
                      builder: (context, room) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The words take what the choices leave and scroll
                          // above them; the choices are shown whole.
                          Flexible(
                            child: _ScenePanel(
                              shrinkToText: true,
                              revealKey: revealKey,
                              key: ValueKey('journey_arrival_$sceneKey'),
                              story: story,
                              node: node,
                              french: french,
                              folded: false,
                              reading: false,
                              onFold: (_) {},
                              onReading: _read,
                              detour: detour,
                            ),
                          ),
                          // The choices acted out here, under the words.
                          if (steps.any((s) => s.onCard) && choicesReady) ...[
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight: room.maxHeight * 0.7),
                              child: _choicePanel(
                                  steps, _pickedCard(selected), french, story,
                                  shrinkWrap: true,
                                  lead: _vignetteFor(
                                      node, steps, story, world, french,
                                      picked: _pickedCard(selected))),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
