// The Journey state taking a step: the walk to it, the choice played
// out, what comes after, and the taps that lead there. Cut out of
// journey_screen.dart with no change (setState is called as _update).
part of '../journey_screen.dart';

/// Taking a step and what leads to it. Cut out of journey_screen.dart
/// with no change (setState is called as _update).
extension _JourneyTaking on _JourneyViewState {
  String _sceneKeyOf(StoryPlayState play) =>
      '${play.activeExcursionNode?.id ?? play.currentNodeId}'
      '_${play.isInExcursion}_${play.history.length}';

  Future<void> _take(int index, _Step step) async {
    // The scene the step was drawn for.
    final before = _sceneKey;
    if (_busy || step.locked || before == null) return;
    _update(() {
      _takingFrom = before;
      _pressed = index;
    });
    // The view the step is taken from: a same-place step to a scene with
    // nothing to choose keeps it (see _hasOneWay).
    final current = _reading
        ? ArrivalView.page
        : _arrival
            ? ArrivalView.sheet
            : null;
    // Where the party stands before it sets out.
    final home = _partyChart;
    final homePlan = _partyPlan, homeDistrict = _partyDistrict;
    final homeLandmark = _partyLandmark;
    // The story moved on meanwhile (the walk cut short with its map): the
    // step is no longer one to take.
    bool moved() => _sceneKeyOf(ref.read(storyPlayProvider)) != before;
    Offset? walked;
    var taken = false;
    ChoiceFlow flow = const FlowStay();
    String? fromId;
    // Kept now: the screen may be gone by the time the step ends.
    final rise = ref.read(crossingRiseProvider.notifier)..state = false;
    try {
      final chart = _chartKey.currentState;
      // On a town's District view (v1.565): the party's mark walks to the
      // way's pin first, then its scene opens; a tap skips the walk.
      if (chart == null &&
          _cityWalkable &&
          !MediaQuery.of(context).disableAnimations) {
        await _walkCity(index);
        if (!mounted || moved()) return;
      }
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
        // A long road the choice crosses (land_routes.json) is played on
        // the crossing screen: the chart flight only sets out, and the
        // crossing rises over it (crossing_rise_route.dart).
        final crossing = step.choice.crossesLand &&
            ref.read(appModeProvider) != AppMode.edit;
        walked = await chart.walkTo(_pinIdx.indexOf(index), setOut: crossing);
        if (crossing && walked != null) {
          rise.state = true;
        }
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
        await playFightJolt(context, _jolt);
        if (!mounted || moved()) return;
      }
      fromId = ref.read(storyPlayProvider).currentNodeId;
      await takeStoryChoice(context, ref, step.choice);
      taken = true;
      flow = _flowAfter(fromId, step.choice);
      _noteTakenStep(step.choice, flow, before);
    } finally {
      // The rise is for the crossing that follows this flight only.
      if (mounted) {
        rise.state = false;
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
            _roadWalk = false;
          }
        }
        if (mounted) {
          // A new game's first step out of a building (first_journey.dart):
          // the map, not the page, since the party has to move on.
          final firstOut = taken && !stayed && _firstStepOutside(fromId);
          _update(() {
            if (_takingFrom == before) _takingFrom = null;
            _pressed = null;
            _cityWalkAt.value = null;
            _placeMark = null;
            // The choice moved the story on. A main-story scene is read full
            // screen (S1); any other scene opens in a sheet over the map (S2);
            // Continue brings the map back (and plays a carry). A one-tap
            // return lands on the hub's map, with its notice (return_notice).
            // Either view also holds the scene's own choices (the ones acted
            // out here); the map keeps only the ways that carry the party.
            if (taken && !stayed) {
              _carried = flow is FlowTripThenArrive || flow is FlowReturnToHub;
              final play = ref.read(storyPlayProvider);
              final view = arrivalViewOf(
                flow,
                mainStory: ref
                        .read(storyStopsProvider)
                        ?.isMainStoryScene(play.currentNodeId) ??
                    true,
                inExcursion: play.isInExcursion,
                current: _hasOneWay(play.currentNodeId) ? current : null,
              );
              // The story begun again: its first scene, as a new game's.
              final fresh = isFreshStoryStart(play);
              _reading = fresh || view == ArrivalView.page;
              _arrival = !fresh && view == ArrivalView.sheet;
              if (firstOut && !fresh) {
                _reading = false;
                _arrival = false;
              }
              // The view is chosen here: the next build keeps it.
              _openedFresh = fresh;
              // The story brought the party here: its page holds it if a
              // way is acted out here (see the build).
              _lockedAt = ref.read(appModeProvider) == AppMode.edit
                  ? null
                  : _sceneKeyOf(play);
            }
          });
        }
      }
    }
  }

  /// Whether scene [nodeId] has nothing to choose: one way shown (the
  /// others hidden by their flags), leading on to the next scene at the
  /// same stop (FlowStay). Such a scene has its way as a card, and a
  /// same-place step to it keeps the page or the sheet it was taken from
  /// (v1.825); a scene with a choice to make opens as it did before v1.809,
  /// its choices on the map.
  bool _hasOneWay(String nodeId) {
    final node = widget.story.nodeFor(nodeId);
    final stops = ref.read(storyStopsProvider);
    if (node == null || stops == null) return false;
    final session = ref.read(playerSessionProvider);
    final gate = ref.read(coastGateWorldProvider);
    final shown = [
      for (final c in node.choices)
        if (!choiceHiddenFor(c, session, gate)) c,
    ];
    return shown.length == 1 && stops.flowOf(node, shown.single) is FlowStay;
  }

  /// A step taken inside one place (a card whose way leads to the next scene
  /// at the same stop): the scene it opens says what was taken and that the
  /// party is still here (pendingTakenProvider). A move, a carried trip, a
  /// hub's return and a step that left the scene as it was say nothing.
  void _noteTakenStep(StoryChoice choice, ChoiceFlow flow, String before) {
    final play = ref.read(storyPlayProvider);
    final place = ref
        .read(geographyProvider)
        .placeOfNode(widget.story.nodeFor(play.currentNodeId));
    ref.read(pendingTakenProvider.notifier).state = takenStepAfter(
      choice: choice,
      flow: flow,
      inExcursion: play.isInExcursion,
      sceneChanged: _sceneKeyOf(play) != before,
      placeId: place?.id,
    );
  }

  /// What the Journey does after [choice] took the story from [fromId] to
  /// where it stands now (choice_flow.dart); a one-tap return is noted for
  /// its notice.
  ChoiceFlow _flowAfter(String fromId, StoryChoice choice) {
    final stops = ref.read(storyStopsProvider);
    final play = ref.read(storyPlayProvider);
    final from = ref.read(storyDataProvider).value?.nodeFor(fromId);
    if (stops == null || from == null || play.isInExcursion) {
      return const FlowStay();
    }
    final flow = stops.flowOf(from, choice, nextId: play.currentNodeId);
    if (flow case FlowReturnToHub(:final hubNodeId, :final hubStop)) {
      ref.read(lastReturnProvider.notifier).state =
          (hubNodeId: hubNodeId, hubStop: hubStop, fromNodeId: fromId);
    }
    return flow;
  }

  /// Whether the story just took the party from [fromId] out of a building
  /// for the first time in a new game (see firstStepOutside); notes it in
  /// the session when it did, so it happens once.
  bool _firstStepOutside(String? fromId) {
    final play = ref.read(storyPlayProvider);
    if (fromId == null ||
        play.isInExcursion ||
        ref.read(appModeProvider) == AppMode.edit) {
      return false;
    }
    final world = ref.read(geographyProvider);
    final story = widget.story;
    final out = firstStepOutside(
      flags: ref.read(playerSessionProvider).flags,
      from: world.placeOfNode(story.nodeFor(fromId)),
      to: world.placeOfNode(story.nodeFor(play.currentNodeId)),
      chapter: chapterOfNode(play.currentNodeId),
    );
    if (out) {
      ref.read(playerSessionProvider.notifier).markJourneyFirstShown();
    }
    return out;
  }

  /// Walks the party's mark on the town's chart to the pin of way [index]
  /// (v1.565): from its doorstep or its district, in a straight line, for
  /// as long as cityWalkDuration says. A tap on the map skips to the end.
  Future<void> _walkCity(int index) async {
    final chart = _cityChart;
    if (chart == null) return;
    final way = chart.ways.where((w) => w.id == '$index').firstOrNull;
    if (way == null) return;
    final to = _wayPin(chart, way);
    final district = ref.read(partyDistrictProvider);
    final from = _markAtPlace ??
        chart.here ??
        (district == null ? null : chart.districtById(district)?.centre);
    if (from == null) return;
    final span = cityWalkDuration((to - from).distance);
    if (span == Duration.zero) return;
    void follow() => _cityWalkAt.value =
        Offset.lerp(from, to, Curves.easeInOut.transform(_cityWalk.value));
    _cityWalk
      ..duration = span
      ..value = 0
      ..addListener(follow);
    follow();
    try {
      await _cityWalk.forward(from: 0).orCancel;
    } on TickerCanceled {
      // The map went mid-walk: the scene is taken all the same.
    } finally {
      _cityWalk.removeListener(follow);
    }
  }

  /// Where way [way]'s pin is on the plan.
  Offset _wayPin(CityChart chart, CityChartWay way) =>
      way.at ??
      chart.buildingOf(way)?.at ??
      chart.districts[way.district].centre;

  /// Tells the top bar whether the page leaves no way to the map (after
  /// the frame: a provider can't change while the tab builds).
  void _closeMap(bool closed) {
    if (ref.read(journeyMapClosedProvider) == closed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(journeyMapClosedProvider.notifier).state = closed;
    });
  }

  /// A road card taken on a locked page (v1.553): the lock lifts, the map
  /// comes back and the party walks the way as a step on it.
  void _leaveByRoad(int index, _Step step) {
    if (_busy || step.locked) return;
    _update(() {
      _lockedAt = null;
      _reading = false;
      _arrival = false;
      _selected = index;
      _walkOn = step.choice;
    });
  }

  /// A tap on step [index]: a second tap on the way picked takes it. On
  /// the map ([fromMap]) a way the game picked is only confirmed by the
  /// first tap; a card goes at once (v1.692).
  void _tap(int index, _Step step, {bool fromMap = false}) {
    if (_busy) return;
    if (_selected == index && !step.locked && !(fromMap && _pickedForPlayer)) {
      _take(index, step);
      return;
    }
    _update(() {
      _selected = index;
      _pickedForPlayer = false;
    });
  }
}
