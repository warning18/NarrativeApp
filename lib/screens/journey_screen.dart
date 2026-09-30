import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/echoes.dart';
import '../data/encounter_text.dart';
import '../data/journey_map.dart';
import '../data/journey_relief.dart';
import '../data/map_charts.dart' show ChartGeography, ChartPalette, chartOf;
import '../data/narration_tokens.dart';
import '../data/road_events.dart';
import '../data/story_repository.dart';
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/journey_fx.dart';
import '../widgets/journey_place.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/timed_choice_bar.dart';
import 'journal_screen.dart';
import 'story_player_screen.dart'
    show
        EchoLine,
        composeNarrationParts,
        isStoryChoiceLocked,
        noteShownEchoes,
        takeStoryChoice;

/// The Journey tab's index among the play-mode tabs (after Story,
/// Character, Camp and Other, so theirs stay as they were).
const int journeyTabIndex = 4;

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
  const _Step({
    required this.choice,
    required this.kind,
    required this.slot,
    required this.label,
    required this.locked,
    required this.leadsTo,
    required this.onwardKinds,
    this.event,
    this.bearing,
    this.chartTarget,
  });

  final StoryChoice choice;
  final JourneyStepKind kind;
  final JourneySlot slot;

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

  /// For a way to another place: its true direction from here on the
  /// world chart (radians, 0 east, clockwise), and where it is there.
  final double? bearing;
  final Offset? chartTarget;
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
  });

  final PlaceKind kind;
  final int seed;
  final ChartGeography geography;
  final Offset chartHere;

  /// The places around on the chart, for the road between two of them.
  final List<ChartMark> marks;
}

/// A seed from [text] that is the same on every run.
int _stableSeed(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// A scene passed earlier in the chapter, as the map draws it below the
/// party.
class _PastMark {
  const _PastMark({
    required this.nodeId,
    required this.place,
    required this.newPlace,
    required this.way,
    this.echoed = false,
  });

  final String nodeId;

  /// The scene holds a line an earlier choice earned (see echoes.dart).
  final bool echoed;

  /// Where it happened.
  final String? place;

  /// The first scene met at [place] on the way down: the place's name is
  /// written beside it.
  final bool newPlace;

  /// The choice taken out of it.
  final String? way;
}

class _JourneyView extends ConsumerStatefulWidget {
  const _JourneyView({required this.story});

  final StoryData story;

  @override
  ConsumerState<_JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends ConsumerState<_JourneyView>
    with SingleTickerProviderStateMixin {
  /// The scene the selection and the chart belong to; a new scene clears
  /// the one and draws a new other.
  String? _sceneKey;
  int? _selected;
  bool _busy = false;

  /// A new scene's lone step is still to be picked for the player.
  bool _autoPickPending = false;
  GlobalKey<_JourneyChartState> _chartKey = GlobalKey();

  /// The scene folded to its first lines (kept from scene to scene).
  bool _sceneFolded = false;

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
    final kinds = <String, String>{};
    for (final node in story.nodes.values) {
      final settlement = node.settlement;
      final landmark = settlement == null ? null : landmarkOfScene(node.id);
      if (landmark != null) kinds[landmark.id] = settlement!.kind;
    }
    _placeKindsOf = story;
    return _placeKinds = kinds;
  }

  /// The jolt going into a fight: the map shakes and its edges run red.
  late final AnimationController _jolt = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void dispose() {
    _jolt.dispose();
    super.dispose();
  }

  String _sceneKeyOf(StoryPlayState play) =>
      '${play.activeExcursionNode?.id ?? play.currentNodeId}'
      '_${play.isInExcursion}_${play.history.length}';

  Future<void> _take(int index, _Step step) async {
    if (_busy || step.locked) return;
    setState(() => _busy = true);
    final before = _sceneKeyOf(ref.read(storyPlayProvider));
    Offset? walked;
    try {
      final chart = _chartKey.currentState;
      if (chart != null && !MediaQuery.of(context).disableAnimations) {
        walked = await chart.walkTo(index);
      }
      if (!mounted) return;
      if (walked != null) _terrainShift += walked;
      if (walked != null &&
          (step.kind == JourneyStepKind.fight ||
              step.kind == JourneyStepKind.expedition)) {
        await _jolt.forward(from: 0);
        if (!mounted) return;
      }
      if (!mounted) return;
      await takeStoryChoice(context, ref, step.choice);
    } finally {
      if (mounted) {
        // A choice that keeps the story where it was (a shop, a fight
        // fled) brings the party back to its mark.
        if (_sceneKeyOf(ref.read(storyPlayProvider)) == before) {
          if (walked != null) _terrainShift -= walked;
          _chartKey.currentState?.resetWalk();
        }
        setState(() => _busy = false);
      }
    }
  }

  void _tap(int index, _Step step) {
    if (_busy) return;
    if (_selected == index && !step.locked) {
      _take(index, step);
      return;
    }
    setState(() => _selected = index);
  }

  /// A scene passed earlier: where it was, how the party left it, and the
  /// scene itself.
  void _showPast(_PastMark mark, Offset origin) {
    final story = widget.story;
    final node = story.nodeFor(mark.nodeId);
    if (node == null) return;
    final french = ref.read(appLanguageProvider) == AppLanguage.fr;
    final parts = composeNarrationParts(
        node, ref.read(playerSessionProvider), story,
        french: french);
    final text = parts.text;
    // The sheet grows out of the scene's mark on the road.
    final screen = MediaQuery.of(context).size;
    final alignment = Alignment(
      (origin.dx / screen.width * 2 - 1).clamp(-1.0, 1.0),
      (origin.dy / screen.height * 2 - 1).clamp(-1.0, 1.0),
    );
    final still = MediaQuery.of(context).disableAnimations;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: still ? 0 : 300),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
              scale: curved, alignment: alignment, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        final theme = Theme.of(context);
        final ink = InkColors.of(context);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mark.place != null)
                      Text(mark.place!,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.display)),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: InkFonts.prose,
                          fontSize: 15,
                          height: 1.45),
                    ),
                    // What earlier choices changed there.
                    for (final echo in parts.echoes) ...[
                      const SizedBox(height: 10),
                      EchoLine(
                        echo: echo,
                        caption: tr(ref, 'echo_because')
                            .replaceAll('{choice}', echo.cause),
                        colour: ink.gold,
                        style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: InkFonts.prose,
                                fontSize: 15,
                                height: 1.45) ??
                            const TextStyle(),
                      ),
                    ],
                    if (mark.way != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        tr(ref, 'journey_way_taken')
                            .replaceAll('{way}', mark.way!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: InkFonts.prose,
                            fontStyle: FontStyle.italic,
                            color: ink.ash),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          child: _ScenePanel(
            key: ValueKey('journey_reading_$sceneKey'),
            story: story,
            node: node,
            french: french,
            folded: false,
            reading: true,
            onFold: (_) {},
            onReading: (reading) => setState(() => _reading = reading),
            detour: detour,
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

    // The chapter behind it, latest first. On a detour the scene it
    // interrupts is the latest, left by the way the detour is met on.
    String? placeOf(String id) =>
        story.nodeFor(id)?.settlement?.nameFor(french) ??
        landmarkOfScene(id)?.name(language);
    // Places compared by the map's own record, so a town and its
    // landmark count as one place however each spells its name.
    String? placeKeyOf(String id) =>
        landmarkOfScene(id)?.id ?? story.nodeFor(id)?.settlement?.name;
    final past = journeyChapterPast(
      history: play.history,
      currentNodeId: play.currentNodeId,
      nodeFor: story.nodeFor,
    );
    final passed = [
      if (play.isInExcursion)
        (id: play.currentNodeId, way: play.excursionOriginFor(french)),
      for (final step in past.steps)
        (id: step.nodeId, way: step.wayTaken?.textFor(french)),
    ];
    final pastMarks = <_PastMark>[];
    for (var i = 0; i < passed.length; i++) {
      final (:id, :way) = passed[i];
      final place = placeOf(id);
      final nearer = i == 0
          ? (play.isInExcursion ? null : placeKeyOf(play.currentNodeId))
          : placeKeyOf(passed[i - 1].id);
      pastMarks.add(_PastMark(
        nodeId: id,
        place: place,
        newPlace: place != null && placeKeyOf(id) != nearer,
        way: way,
        echoed: story
                .nodeFor(id)
                ?.firedCallbacks(session.flags)
                .any((c) => echoCause(story, c.flag) != null) ??
            false,
      ));
    }

    // The place up close, when the party stands at one the world chart
    // knows (not on a detour): where it is and what the ways out point at.
    final geography = chartOf(ref.watch(mapShapeProvider));
    final placeLandmark = play.isInExcursion ? null : standing;
    final chartHere =
        placeLandmark == null ? null : geography.of(placeLandmark);
    final choices =
        node.choices.where((c) => !c.isHiddenFor(session.flags)).toList();
    final ended = choices.isEmpty || isStoryEnding(node);
    final mainQuestOpen =
        ref.watch(chapterProgressProvider)?.mainQuestOpen ?? true;
    final slots = journeySlots(choices.length);
    // What waits on each road is known before the party sets out (see
    // road_events.dart); Edit Mode's roads hold nothing.
    final reached = ref.watch(reachedChapterProvider);
    final condition = ref.watch(chapterConditionProvider);
    final eventsOn =
        !play.isInExcursion && ref.watch(appModeProvider) != AppMode.edit;
    final steps = [
      for (var i = 0; i < choices.length; i++)
        () {
          final choice = choices[i];
          final shut =
              choice.mainQuest && !play.isInExcursion && !mainQuestOpen;
          final locked = shut ||
              (!play.isInExcursion &&
                  isStoryChoiceLocked(choice, story, session));
          final lockedText = shut
              ? tr(ref, 'main_quest_shut_lock')
              : locked
                  ? choice.lockedTextFor(french)
                  : null;
          final target = play.isInExcursion || choice.isEnding
              ? null
              : landmarkOfScene(choice.nextId);
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
                    for (final next in story.nodeFor(choice.nextId)?.choices ??
                        const <StoryChoice>[])
                      if (!next.isHiddenFor(session.flags))
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
                    oddsFactor: condition?.roadEventOdds ?? 1,
                    championShare: condition?.championShare ?? 0.4,
                    shrineShare: condition?.shrineShare ?? 0.3,
                  ),
            bearing:
                chartHere != null && target != null && target.id != standing?.id
                    ? (geography.of(target) - chartHere).direction
                    : null,
            chartTarget:
                chartHere != null && target != null && target.id != standing?.id
                    ? geography.of(target)
                    : null,
          );
        }(),
    ];
    // A scene with one way on has its step picked already: one tap on Go.
    if (_autoPickPending) {
      _autoPickPending = false;
      if (steps.length == 1 && !steps.single.locked) _selected = 0;
    }
    final selected = _selected != null && _selected! < steps.length
        ? steps[_selected!]
        : null;
    final discovered =
        discoveredLandmarkIds([...play.history, play.currentNodeId]);
    final placeView = placeLandmark == null || chartHere == null
        ? null
        : _PlaceView(
            kind: placeKindOf(_kindsFor(story)[placeLandmark.id],
                atSea: placeLandmark.atSea),
            seed: _stableSeed(placeLandmark.id),
            geography: geography,
            chartHere: chartHere,
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
                      TutorialTarget(
                        id: 'journey.scene',
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: math.max(96, area.maxHeight * 0.32)),
                          child: _ScenePanel(
                            key: ValueKey('journey_scene_$sceneKey'),
                            story: story,
                            node: node,
                            french: french,
                            folded: _sceneFolded,
                            reading: false,
                            onFold: (folded) =>
                                setState(() => _sceneFolded = folded),
                            onReading: (reading) =>
                                setState(() => _reading = reading),
                            detour: detour,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ended
                            ? _EndedPanel(
                                title: tr(ref, 'the_end'),
                                message: tr(ref, 'journey_ended'),
                              )
                            : TutorialTarget(
                                id: 'journey.chart',
                                // Going into a fight the map jolts and its
                                // edges run red (see _take).
                                child: AnimatedBuilder(
                                  animation: _jolt,
                                  builder: (context, child) {
                                    final t = _jolt.value;
                                    if (t == 0 || t == 1) return child!;
                                    final shake =
                                        math.sin(t * math.pi * 7) * 6 * (1 - t);
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
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    child: _JourneyChart(
                                      key: _chartKey,
                                      steps: steps,
                                      selected: _selected,
                                      hereName: hereName,
                                      youAreHere:
                                          tr(ref, 'journey_you_are_here'),
                                      leadsTo: tr(ref, 'journey_leads_to'),
                                      past: pastMarks,
                                      pastReachesStart: past.reachesStart,
                                      chapterStart:
                                          tr(ref, 'journey_chapter_start'),
                                      palette: palette,
                                      ink: look == MapLook.parchment
                                          ? InkColors.light
                                          : InkColors.dark,
                                      greyed: look == MapLook.shroud,
                                      terrainShift: _terrainShift,
                                      terrainSeed: 7 +
                                          chapterOfNode(play.currentNodeId) *
                                              13,
                                      onTap: _tap,
                                      onPastTap: _showPast,
                                      stamp: _stamp,
                                      burn: _burn,
                                      unroll: _unroll,
                                      weather: journeyWeatherFor(chapter),
                                      place: placeView,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      if (!ended) ...[
                        // A timed scene's clock (see TimedChoiceBar).
                        if (node.isTimed &&
                            !play.isInExcursion &&
                            ref.watch(appModeProvider) != AppMode.edit)
                          TimedChoiceBar(
                            key: ValueKey(
                                'journey_timer_${node.id}_${play.history.length}'),
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
                        const SizedBox(height: 10),
                        TutorialTarget(
                          id: 'journey.pick',
                          child: _StepDetail(
                            step: selected,
                            busy: _busy,
                            french: french,
                            isExcursion: play.isInExcursion,
                            onGo: selected == null
                                ? null
                                : () => _take(_selected!, selected),
                          ),
                        ),
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
    if (!folded) noteShownEchoes(ref, session, parts.echoes);
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
          Text(prelude.text, style: prose),
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
                  // The whole scene, with its read-aloud and the
                  // companion, is a tap away in the Story tab.
                  IconButton(
                    icon:
                        const Icon(Icons.chrome_reader_mode_outlined, size: 18),
                    tooltip: tr(ref, 'journey_read_in_story'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(homeTabIndexProvider.notifier).state = 0,
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
              onPressed: () =>
                  ref.read(homeTabIndexProvider.notifier).state = 0,
              icon: const Icon(Icons.menu_book),
              label: Text(tr(ref, 'journey_open_story')),
            ),
          ],
        ),
      ),
    );
  }
}

/// A road event's badge on its step (see road_events.dart).
IconData _eventIcon(RoadEventKind kind) => switch (kind) {
      RoadEventKind.champion => Icons.military_tech,
      RoadEventKind.shrine => Icons.spa_outlined,
      RoadEventKind.caravan => Icons.storefront,
    };

Color _eventColour(RoadEventKind kind, InkColors ink) => switch (kind) {
      RoadEventKind.champion => ink.blood,
      RoadEventKind.shrine => ink.heal,
      RoadEventKind.caravan => ink.gold,
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
    required this.past,
    required this.pastReachesStart,
    required this.chapterStart,
    required this.palette,
    required this.ink,
    required this.greyed,
    required this.terrainShift,
    required this.terrainSeed,
    required this.onTap,
    required this.onPastTap,
    this.stamp,
    this.burn = false,
    this.unroll = 0,
    this.weather = JourneyWeather.none,
    this.place,
  });

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

  /// The chapter's earlier scenes, the latest first.
  final List<_PastMark> past;

  /// Whether [past] goes back to the chapter's first scene.
  final bool pastReachesStart;

  /// Written where the chapter began.
  final String chapterStart;
  final ChartPalette palette;
  final InkColors ink;
  final bool greyed;

  /// Where this scene's land lies (see _JourneyViewState._terrainShift).
  final Offset terrainShift;
  final int terrainSeed;
  final void Function(int index, _Step step) onTap;
  final void Function(_PastMark mark, Offset origin) onPastTap;

  @override
  State<_JourneyChart> createState() => _JourneyChartState();
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
  static const double _pastGap = 64;

  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  /// Out of a place and along the world chart to the next (v1.181).
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  int? _flying;

  bool get _placeMode => widget.place != null;

  /// A way's road: a street out of the square in a place, the road up
  /// the map otherwise.
  Path _road(Offset from, Offset to) =>
      _placeMode ? placeStreet(from, to) : _roadPath(from, to);

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
  int _printSide = 1;

  @override
  void initState() {
    super.initState();
    _walk.addListener(_onWalk);
    _walk.addStatusListener((status) {
      if (status == AnimationStatus.completed && _walking != null) {
        final i = _walking!;
        if (i < _centres.length) _dust = (_centres[i], _clock.value);
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
      _ticker ??= createTicker((elapsed) {
        final now = _clockBase + elapsed.inMicroseconds / 1e6;
        _clock.value = now;
        if (now - _lastEvent < 3.8) _phase.value = now;
      });
      _ticker!.start();
    } else if (_ticker?.isActive ?? false) {
      _clockBase = _clock.value;
      _ticker!.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _JourneyChart old) {
    super.didUpdateWidget(old);
    if (old.unroll != widget.unroll) {
      _unrollAt = _clock.value;
      _lastEvent = _clock.value;
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
      _nextPrint += 0.07;
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
  /// party went (the step's place less its own).
  Future<Offset?> walkTo(int index) async {
    if (index >= _centres.length) return null;
    _walkRoad = _road(_here, _centres[index]).computeMetrics().first;
    _nextPrint = 0.07;
    _footprints.clear();
    _dust = null;
    setState(() => _walking = index);
    final scroll = _scroll;
    if (scroll != null &&
        scroll.hasClients &&
        (scroll.offset - _openAt).abs() > 1) {
      scroll.animateTo(_openAt,
          duration: _walk.duration!, curve: Curves.easeInOut);
    }
    await _walk.forward(from: 0);
    // A way out of the place: the map zooms out to the world chart and
    // the party walks the road to where it leads.
    final place = widget.place;
    final target =
        index < widget.steps.length ? widget.steps[index].chartTarget : null;
    if (place != null && target != null && _animate && mounted) {
      setState(() => _flying = index);
      await _flight.forward(from: 0);
    }
    return _centres[index] - _here;
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
    _ticker?.dispose();
    _clock.dispose();
    _phase.dispose();
    _walk.dispose();
    _flight.dispose();
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
          late final List<Offset> pastPoints;
          if (_placeMode) {
            // In a place: the party in the middle, its ways round it and
            // the ways out at the edge where they lead; the chapter
            // behind below.
            // A little short of the box, so the road behind peeks in at
            // the foot and says there is more below.
            present = math.max(
                box.maxHeight - (widget.past.isEmpty ? 0 : 84),
                steps.length > 7
                    ? 400
                    : steps.length > 3
                        ? 300
                        : 220);
            here = Offset(width / 2, present / 2);
            centres = journeyPlaceLayout(
              area: Size(width, present),
              here: here,
              bearings: [for (final step in steps) step.bearing],
            );
            pastPoints = [
              for (var i = 0; i < widget.past.length; i++)
                Offset(width / 2 + math.sin((i + 1) * 1.25) * width * 0.12,
                    present + 26 + i * _pastGap),
            ];
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
            // The chapter behind, winding down the map.
            pastPoints = [
              for (var i = 0; i < widget.past.length; i++)
                Offset(width / 2 + math.sin((i + 1) * 1.25) * width * 0.12,
                    hereY + _hereRadius + 44 + i * _pastGap),
            ];
            _openAt = math.max(0, present - box.maxHeight);
          }
          _here = here;
          _centres = centres;
          final bottom = pastPoints.isEmpty
              ? present
              : math.max(present, pastPoints.last.dy + 70);
          final height = bottom;
          _scroll ??= ScrollController(initialScrollOffset: _openAt);
          // A map made taller or shorter (the scene folded or opened)
          // opens on the party again.
          if (_viewport != null && _viewport != box.maxHeight) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final scroll = _scroll;
              if (mounted && scroll != null && scroll.hasClients) {
                scroll.jumpTo(
                    _openAt.clamp(0.0, scroll.position.maxScrollExtent));
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

          final map = SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              width: width,
              height: height,
              child: AnimatedBuilder(
                animation: Listenable.merge([_walk, _phase]),
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
                  final now = _clock.value;
                  final walkingKind = walking != null && walking < steps.length
                      ? steps[walking].kind
                      : null;
                  final selectedIndex = walking ?? widget.selected;
                  Path? selectedRoad;
                  if (widget.selected != null &&
                      walking == null &&
                      widget.selected! < centres.length &&
                      !steps[widget.selected!].locked) {
                    final (from, to) =
                        _roadEnds(here, centres[widget.selected!], width);
                    selectedRoad = _road(from, to);
                  }
                  final burning = _animate && widget.burn && now < 1.4;
                  final burnT = (now / 1.3).clamp(0.0, 1.0);
                  final chart = Transform.translate(
                    offset: camera,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: widget.place == null
                                  ? _ReliefPainter(
                                      palette: palette,
                                      here: here,
                                      shift: widget.terrainShift,
                                      seed: widget.terrainSeed,
                                    )
                                  : PlacePlanPainter(
                                      kind: widget.place!.kind,
                                      seed: widget.place!.seed,
                                      here: here,
                                      spots: centres,
                                      palette: palette,
                                      ember: widget.ink.ember,
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
                                  ),
                              ],
                              past: pastPoints,
                              pastFrom: _placeMode
                                  ? Offset(here.dx, present - 6)
                                  : here,
                              radial: _placeMode,
                              pastGoesOn: !widget.pastReachesStart,
                              walking: walking,
                              progress: t,
                              reveals: [
                                for (var i = 0; i < steps.length; i++)
                                  _roadReveal(i),
                              ],
                            ),
                          ),
                        ),
                        // What each step holds, the weather, the picked
                        // road flowing, footprints (see journey_fx.dart).
                        if (_animate)
                          Positioned.fill(
                            child: IgnorePointer(
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
                        // The chapter's earlier scenes.
                        for (var i = 0; i < widget.past.length; i++)
                          _pastLabel(
                            i,
                            pastPoints[i],
                            width,
                            noteStyle,
                            placeStyle,
                          ),
                        if (widget.past.isNotEmpty && widget.pastReachesStart)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: pastPoints.last.dy + 20,
                            child: Text(
                              widget.chapterStart.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: noteStyle.copyWith(
                                  fontSize: 10, letterSpacing: 1.4),
                            ),
                          ),
                        // Where the party stood, while it walks away.
                        _hereMark(here, faded: traveller != null),
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
                        // The ways on.
                        for (var i = 0; i < steps.length; i++)
                          _stepMark(i, centres[i], labelWidth(steps[i]), width,
                              placeStyle, noteStyle,
                              fading: walking != null && walking != i ? t : 0,
                              // A crowded place names only the way picked
                              // and the ways out; the rest by their marks.
                              label: !_placeMode ||
                                  steps.length <= 5 ||
                                  widget.selected == i ||
                                  steps[i].leadsTo != null),
                        // The party, on the road.
                        if (traveller != null)
                          Positioned(
                            key: const ValueKey('journey_traveller'),
                            left: traveller.dx - _hereRadius,
                            top: traveller.dy - _hereRadius,
                            child: _partyMark(palette),
                          ),
                        // A place the map hadn't shown: its name stamped
                        // over the mark, ink spreading under it.
                        if (widget.stamp != null && _animate && now < 4.2)
                          ..._stampMark(here, now, width),
                      ],
                    ),
                  );
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
    final appear = ((now - 0.9) / 0.6).clamp(0.0, 1.0);
    final fade = ((4.2 - now) / 0.6).clamp(0.0, 1.0);
    final s = Curves.easeOutBack.transform(appear);
    final spread = ((now - 0.95) / 1.1).clamp(0.0, 1.0);
    return [
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
      if (appear > 0)
        Positioned(
          left: 0,
          width: width,
          // Under the mark, over the road behind: the ways ahead keep
          // their words.
          top: here.dy + _hereRadius + 10,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: (appear * 2).clamp(0.0, 1.0) * fade,
                child: Transform.rotate(
                  angle: -0.1 + (1 - s) * -0.14,
                  child: Transform.scale(
                    scale: 1.6 - 0.6 * s,
                    child: Container(
                      key: const ValueKey('journey_stamp'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.land.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.mark, width: 2),
                      ),
                      child: Text(
                        widget.stamp!,
                        style: TextStyle(
                          fontFamily: InkFonts.display,
                          fontSize: 16,
                          color: palette.mark,
                        ),
                      ),
                    ),
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

  Widget _pastLabel(int i, Offset point, double width, TextStyle noteStyle,
      TextStyle placeStyle) {
    final mark = widget.past[i];
    final palette = widget.palette;
    // Written on the side with more room.
    final onRight = point.dx <= width / 2;
    final labelWidth =
        math.max(0.0, onRight ? width - point.dx - 26 : point.dx - 26);
    final fade = (1 - i * 0.04).clamp(0.55, 1.0);
    return Positioned(
      left: onRight ? point.dx + 14 : point.dx - 14 - labelWidth,
      width: labelWidth,
      top: point.dy - 9,
      child: Builder(
        builder: (context) => GestureDetector(
          key: ValueKey('journey_past_$i'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // The sheet grows out of the scene's mark.
            final box = context.findRenderObject() as RenderBox?;
            final origin = box == null
                ? Offset.zero
                : box.localToGlobal(
                    Offset(onRight ? 0 : box.size.width, box.size.height / 2));
            widget.onPastTap(mark, origin);
          },
          child: Opacity(
            opacity: fade,
            child: Column(
              crossAxisAlignment:
                  onRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (mark.newPlace && mark.place != null)
                  Text(
                    mark.place!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: onRight ? TextAlign.left : TextAlign.right,
                    style: noteStyle.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: palette.place.withValues(alpha: 0.8)),
                  ),
                if (mark.echoed)
                  Icon(Icons.history,
                      key: ValueKey('journey_past_echo_$i'),
                      size: 13,
                      color: widget.ink.gold.withValues(alpha: 0.9)),
                if (mark.way != null)
                  Text(
                    mark.way!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: onRight ? TextAlign.left : TextAlign.right,
                    style: placeStyle.copyWith(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: palette.place.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepMark(int i, Offset centre, double w, double width,
      TextStyle placeStyle, TextStyle noteStyle,
      {required double fading, bool label = true}) {
    final step = widget.steps[i];
    final palette = widget.palette;
    final left =
        (centre.dx - w / 2).clamp(4.0, math.max(4.0, width - w - 4)).toDouble();
    final colour = step.locked
        ? palette.label
        : _colorFor(step.kind, widget.ink, palette, greyed: widget.greyed);
    final isSelected = widget.selected == i || _walking == i;
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
      left: left,
      top: centre.dy - _stepRadius,
      width: w,
      child: Opacity(
        opacity: (1 - fading * 0.7) * pop.clamp(0.0, 1.0),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: step.label,
          child: GestureDetector(
            key: ValueKey('journey_step_$i'),
            behavior: HitTestBehavior.opaque,
            onTap: _walking == null
                ? () {
                    if (step.locked && _animate) {
                      _rattle = (i, _clock.value);
                      _lastEvent = _clock.value;
                    }
                    widget.onTap(i, step);
                  }
                : null,
            child: Column(
              children: [
                Transform.translate(
                  offset: Offset(centre.dx - left - w / 2, 0),
                  child: AnimatedScale(
                    scale: (isSelected ? 1.15 : 1) * popScale,
                    duration: pop >= 1
                        ? const Duration(milliseconds: 160)
                        : Duration.zero,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                            child: Icon(
                              step.locked
                                  ? Icons.lock_outline
                                  : _iconFor(step.kind),
                              size: 20,
                              color: isSelected ? palette.land : colour,
                            ),
                          ),
                        ),
                        // What lies past the step, glimpsed through the
                        // fog: the kinds of its own ways on.
                        if (!step.locked && pop >= 1)
                          for (var f = 0; f < step.onwardKinds.length; f++)
                            _glimpse(f, step.onwardKinds.length,
                                step.onwardKinds[f], palette),
                        // What waits on the road there.
                        if (step.event != null)
                          Positioned(
                            right: -6,
                            bottom: -4,
                            child: Container(
                              key: ValueKey('journey_event_$i'),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _eventColour(step.event!, widget.ink),
                                border:
                                    Border.all(color: palette.land, width: 1.5),
                              ),
                              child: Icon(_eventIcon(step.event!),
                                  size: 11, color: palette.land),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (label) const SizedBox(height: 4),
                // A plaque under the words: the roads to the far steps
                // pass beneath it.
                if (label)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.land.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
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
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                          if (step.leadsTo != null)
                            Text(
                              widget.leadsTo
                                  .replaceAll('{place}', step.leadsTo!),
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

/// The roads over the land: the fog over what is not known yet, the road
/// walked coming up from the chapter's earlier scenes, and the ways on.
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.palette,
    required this.here,
    required this.hereRadius,
    required this.stepRadius,
    required this.steps,
    required this.past,
    required this.pastGoesOn,
    required this.walking,
    required this.progress,
    this.reveals = const [],
    this.radial = false,
    Offset? pastFrom,
  }) : pastFrom = pastFrom ?? here;

  /// In a place (v1.181): the ways run out of the square every way, as
  /// streets, with no fog over the top; the chapter's road comes in from
  /// [pastFrom], the map's foot.
  final bool radial;
  final Offset pastFrom;

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
      })> steps;

  /// The chapter's earlier scenes, the latest first.
  final List<Offset> past;

  /// The chapter goes back further than [past] shows.
  final bool pastGoesOn;

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

    // The road walked: up from the chapter's first scene to the party,
    // through each scene passed, fading with distance.
    final road = [pastFrom, ...past];
    for (var i = 0; i < road.length - 1; i++) {
      final a = road[i], b = road[i + 1];
      final mid = (b.dy - a.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + mid, b.dx, b.dy - mid, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.road
              .withValues(alpha: (0.85 - i * 0.03).clamp(0.35, 0.85))
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < past.length; i++) {
      canvas.drawCircle(
        past[i],
        5,
        Paint()
          ..color =
              palette.road.withValues(alpha: (0.9 - i * 0.03).clamp(0.4, 0.9)),
      );
      canvas.drawCircle(
        past[i],
        5,
        Paint()
          ..color = palette.land
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    // Where the chapter began, or the road going on beyond what is shown.
    if (past.isNotEmpty) {
      final last = past.last;
      if (pastGoesOn) {
        _dashed(
            canvas,
            Path()
              ..moveTo(last.dx, last.dy)
              ..lineTo(last.dx, last.dy + 40),
            Paint()
              ..color = palette.road.withValues(alpha: 0.35)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
            dash: 4,
            gap: 6);
      } else {
        canvas.drawCircle(
            last,
            9,
            Paint()
              ..color = palette.road.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    // The ways on: dashed, the chosen one drawn in full. Each leaves the
    // party's mark on the side it heads for, and the roads to the far
    // rows fade, so a town's many ways read as a fan rather than a knot.
    for (var s = 0; s < steps.length; s++) {
      final step = steps[s];
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
      var path = radial ? placeStreet(start, end) : _roadPath(start, end);
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
      final road = radial
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
      old.pastGoesOn != pastGoesOn ||
      old.radial != radial ||
      old.pastFrom != pastFrom ||
      old.past.length != past.length ||
      old.steps.length != steps.length ||
      [
        for (var i = 0; i < steps.length; i++) old.steps[i] != steps[i],
        for (var i = 0; i < past.length; i++) old.past[i] != past[i],
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
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash),
                    ),
                  if (step.event != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(_eventIcon(step.event!),
                              size: 14, color: _eventColour(step.event!, ink)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tr(ref, 'journey_event_${step.event!.name}'),
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
