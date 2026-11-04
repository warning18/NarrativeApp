// The session notifier's standing, marks, relations, the coast's events, sieges, the throne, betrayals and the hunter (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _PoliticsActions on _SessionNotifierBase {
  /// The chapter a clan change is logged under: [chapter] (pass the
  /// reached chapter, reachedChapterProvider), else the one the world
  /// clock counts, at least 1.
  @override
  int _politicsChapter(int? chapter) => chapter ?? max(1, state.clockChapter);

  /// Moves standing with [factionId] by [delta] for [cause] (see
  /// applyStandingChange: the ripple to its allies and rivals, the Sworn
  /// banner, the clamps), logged on [chapter] and today. Returns what
  /// moved, faction by faction.
  @override
  Future<StandingResult> changeStanding(
    String factionId,
    num delta, {
    required ClanData data,
    required String cause,
    int? chapter,
  }) async {
    final result = applyStandingChange(state.politics, factionId, delta, cause,
        data: data, chapter: _politicsChapter(chapter), day: state.day);
    if (!result.changed) return result;
    state = _withTitles(state.copyWith(politics: result.state), data);
    await _persist();
    return result;
  }

  /// [subclanId] marks the character [mark] (friend, none or foe), for
  /// [cause], logged (see setSubclanMark). False when it already did.
  Future<bool> setSubclanMark(
    String subclanId,
    SubclanMark mark, {
    required ClanData data,
    required String cause,
    int? chapter,
  }) async {
    final result = clan_rules.setSubclanMark(
        state.politics, subclanId, mark, cause,
        data: data, chapter: _politicsChapter(chapter), day: state.day);
    if (!result.changed) return false;
    state = _withTitles(state.copyWith(politics: result.state), data);
    await _persist();
    return true;
  }

  /// [a] and [b] move [steps] along the relations scale for [cause]
  /// (see shiftRelation), logged and kept as [chapter]'s snapshot. False
  /// when the pair couldn't move further.
  Future<bool> shiftRelation(
    String a,
    String b,
    int steps, {
    required ClanData data,
    required String cause,
    int? chapter,
  }) async {
    final result = clan_rules.shiftRelation(state.politics, a, b, steps, cause,
        data: data, chapter: _politicsChapter(chapter), day: state.day);
    if (!result.changed) return false;
    state = _withTitles(state.copyWith(politics: result.state), data);
    await _persist();
    return true;
  }

  /// Edit Mode: standing with [factionId] set to [value], no ripple (see
  /// setStandingValue), logged as an edit.
  Future<void> setStandingForEdit(
    String factionId,
    num value, {
    required ClanData data,
    int? chapter,
  }) async {
    final result = setStandingValue(state.politics, factionId, value, 'edit',
        data: data, chapter: _politicsChapter(chapter), day: state.day);
    if (!result.changed) return;
    state = _withTitles(state.copyWith(politics: result.state), data);
    await _persist();
  }

  /// Edit Mode: the coast as the story opens -- every standing back to its
  /// start, the Dominion the nemesis again, no marks, no faction sworn, the relations and logs cleared;
  /// the titles a mark held go with it ([data]: the clan data, for them).
  Future<void> resetPolitics({ClanData? data}) async {
    final reset = state.copyWith(politics: PoliticsState.storyStart);
    state = data == null ? reset : _withTitles(reset, data);
    await _persist();
  }

  // --- Politics in motion (v1.195, see politics_events.dart) --------------

  /// The world the politics rules read now: [data], [events], the chapter
  /// (see [_politicsChapter]) and the story's day.
  CoastWorld _coastWorld(
          ClanData data, Map<String, PoliticsEvent> events, int? chapter,
          [Geography? geography]) =>
      CoastWorld(
        data: data,
        events: events,
        chapter: _politicsChapter(chapter),
        day: state.day,
        chapterDay: max(1, state.day - state.chapterStartDay + 1),
        signPatrons: state.signPatronsThisLife,
        geography: geography,
      );

  /// Takes [change] into the session: the politics and flags after it,
  /// the offers it brought (each with its faction guaranteed a place), the
  /// companions an intrigue moved (one who `leaves` walks out for good,
  /// one who `disapproves` thinks less of the character), the titles it
  /// gave (worn when none is) and those standing and remembrance earn.
  void _takeCoastChange(CoastChange change, ClanData data,
      {Map<String, dynamic> companions = const {}}) {
    var next = state.copyWith(
      politics: change.politics,
      flags: change.flags,
      pendingOffers: [
        ...state.pendingOffers,
        for (final o in change.offers)
          OfferTicket(
              source: OfferSource.story,
              detail: o.cause,
              factionId: o.factionId),
      ],
    );
    for (final id in change.titles) {
      // The coronation's title (v1.196) is worn at once.
      final crowned = data.titles[id]?.source.startsWith('throne:') ?? false;
      if (next.heldTitleIds.contains(id)) {
        if (crowned) next = next.copyWith(activeTitleId: id);
        continue;
      }
      next = next.copyWith(
        heldTitleIds: [...next.heldTitleIds, id],
        activeTitleId: crowned ||
                (next.activeTitleId.isEmpty &&
                    !(data.titles[id]?.negative ?? false))
            ? id
            : next.activeTitleId,
      );
    }
    state = next;
    for (final turn in change.companions) {
      if (!state.recruitedAllies
          .any((a) => a.companionId == turn.companionId)) {
        continue;
      }
      switch (turn.change) {
        case 'leaves':
        case 'lost':
          _removeAlly(turn.companionId, lost: false, companions: companions);
        case 'disapproves':
        case 'approves':
          final by = turn.change == 'approves'
              ? PlayerSessionNotifier.intrigueApprovalShift
              : -PlayerSessionNotifier.intrigueApprovalShift;
          state = state.copyWith(recruitedAllies: [
            for (final a in state.recruitedAllies)
              a.companionId == turn.companionId
                  ? a.copyWith(approval: approvalAfter(a.approval, by))
                  : a,
          ]);
      }
    }
    state = _withTitles(state, data);
  }

  /// A story choice's or a scene's [politics] (see applyStoryPolitics),
  /// logged under `story:<nodeId>` on [chapter] (the chapter reached) and
  /// today. Applied once under [key] (see choicePoliticsKey,
  /// enterPoliticsKey): taken again, or the scene entered again, nothing
  /// happens. [events] for its `event`, [companions] (companions.json)
  /// for a companion an outcome takes.
  Future<CoastChange> applyStoryPolitics(
    StoryPolitics politics, {
    required String nodeId,
    required ClanData data,
    Geography? geography,
    String key = '',
    Map<String, PoliticsEvent> events = const {},
    Map<String, dynamic> companions = const {},
    int? chapter,
    String? cause,
  }) async {
    final change = coast.applyStoryPolitics(politics,
        cause: cause ?? 'story:$nodeId',
        key: key,
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter, geography));
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    _syncHeld(geography);
    await _persist();
    // A standing, an oath or an intrigue's end may be what one asks for.
    await checkAchievements();
    return change;
  }

  /// Fires every politics event whose time has come on [chapter] (the
  /// chapter reached) and today (see runDueEvents): on a chapter change
  /// and a day's tick. Returns what changed; its news are the events'
  /// "News from the coast".
  Future<CoastChange> runPoliticsEvents({
    required ClanData data,
    Geography? geography,
    required Map<String, PoliticsEvent> events,
    Map<String, dynamic> companions = const {},
    int? chapter,
  }) async {
    final change = runDueEvents(
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter, geography));
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    _syncHeld(geography);
    await _persist();
    return change;
  }

  /// Edit Mode's "Fire now": politics event [eventId] fires at once, even
  /// one that has fired before.
  Future<CoastChange> firePoliticsEvent(
    String eventId, {
    required ClanData data,
    Geography? geography,
    required Map<String, PoliticsEvent> events,
    Map<String, dynamic> companions = const {},
    int? chapter,
  }) async {
    final change = fireEvent(eventId,
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter, geography),
        force: true);
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    _syncHeld(geography);
    await _persist();
    return change;
  }

  /// The `held_<district>_<clan>` flags brought in line with who holds
  /// each district now (wave 18, see syncHeldFlags); nothing without the
  /// geography. The caller persists.
  @override
  void _syncHeld(Geography? geography) {
    if (geography == null || geography.isEmpty) return;
    final flags = syncSiegeFlags(
        influence.syncHeldFlags(state.flags, geography, state.politics),
        state.politics);
    if (!identical(flags, state.flags)) {
      state = state.copyWith(flags: flags);
    }
  }

  /// The dice of the district attacks (district_attacks.dart) on [chapter]:
  /// the run's own, so a run rolls the same.
  @override
  Random _siegeRandom(int chapter) =>
      Random(state.runSeed * 31 + chapter * 7919 + state.day * 104729);

  /// The sieges run out by today (district_attacks.dart), settled away
  /// from the party: the district taken or held, the news told. Returns
  /// how many were settled.
  @override
  int _settleExpiredSieges(ClanData data, Geography geography, int chapter) {
    final expired = expiredSieges(state.politics, state.day);
    if (expired.isEmpty) return 0;
    final random = _siegeRandom(chapter);
    var politics = state.politics;
    for (final siege in expired) {
      politics = settleSiegeAway(politics, siege,
          data: data,
          geography: geography,
          random: random,
          chapter: chapter,
          day: state.day);
    }
    state = state.copyWith(politics: politics);
    _syncHeld(geography);
    return expired.length;
  }

  /// The sieges run out by today, settled and saved (a road's check, see
  /// story_player_screen.dart's startRoadEncounter).
  Future<void> settleExpiredSieges({
    required ClanData data,
    required Geography geography,
    required int chapter,
  }) async {
    if (_settleExpiredSieges(data, geography, chapter) > 0) await _persist();
  }

  /// The `held_` flags in sync (see [_syncHeld]), saved when they moved:
  /// as a scene is entered (politics_provider.dart's applyEnterPolitics),
  /// so a new game holds them before its first scene with a condition.
  Future<void> syncHeldFlags(Geography geography) async {
    final before = state.flags;
    _syncHeld(geography);
    if (!identical(before, state.flags)) await _persist();
  }

  /// [quest] (a quests.json record) turned in (wave 18, see
  /// applyQuestInfluence in district_influence.dart): its influence for
  /// the clan [picked] (the turn-in choice's politics) favours, else its
  /// `faction`, in its district, wherever the party is; a district or a
  /// town changing hands with it. Saved when it counted.
  Future<influence.InfluenceResult> applyQuestInfluence(
    Map<String, dynamic> quest, {
    required ClanData data,
    required Geography geography,
    StoryPolitics? picked,
    String? partyDistrict,
    int chapter = 0,
  }) async {
    final result = influence.applyQuestInfluence(state.politics, quest,
        flags: state.flags,
        data: data,
        geography: geography,
        picked: picked,
        partyDistrict: partyDistrict,
        chapter: chapter,
        day: state.day);
    if (!result.counted) return result;
    state = _withTitles(
        state.copyWith(politics: result.state, flags: result.flags), data);
    await _persist();
    return result;
  }

  /// Edit Mode's Throne tab (v1.196, see throne.dart): [politics] (a
  /// claim, a pledge, the Throne, the muster) applied now, logged as an
  /// edit, every time it is pressed.
  Future<CoastChange> applyThroneEdit(
    StoryPolitics politics, {
    required ClanData data,
    Map<String, PoliticsEvent> events = const {},
    int? chapter,
  }) async {
    final change = coast.applyStoryPolitics(politics,
        cause: 'edit',
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter));
    _takeCoastChange(change, data);
    await _persist();
    return change;
  }

  /// Edit Mode: [factionId]'s clan quest at [steps] (0..3): the flags
  /// `clan_<id>_step_1` up to it held, those past it dropped.
  Future<void> setClanStepsForEdit(String factionId, int steps,
      {required ClanData data}) async {
    final keep = [
      for (var n = 1; n <= steps.clamp(0, clanQuestSteps); n++)
        clanStepFlag(factionId, n),
    ];
    final prefix = 'clan_${factionId}_step_';
    final flags = [
      for (final f in state.flags)
        if (!f.startsWith(prefix) || keep.contains(f)) f,
      for (final f in keep)
        if (!state.flags.contains(f)) f,
    ];
    state = _withTitles(state.copyWith(flags: flags), data);
    await _persist();
  }

  /// Edit Mode: the climb undone -- no claim, nobody on the Throne, no
  /// pledge, no Host -- with the flags they set for each faction
  /// (`claim_<id>`, `pledged_<id>`, `throne_winner_<id>`, `host_<id>`),
  /// `on_throne` and the Host's counts. Standing, marks, the clan quest
  /// steps and the story's own flags stay.
  Future<void> clearThroneForEdit({required ClanData data}) async {
    final ids = data.factions.keys;
    final climb = {
      for (final id in ids) ...[
        claimFlag(id),
        pledgedFlag(id),
        throneWinnerFlag(id),
      ],
      onThroneFlag,
    };
    bool climbFlag(String f) => climb.contains(f) || isMusterFlag(f, ids);
    state = _withTitles(
        state.copyWith(
          politics: state.politics.copyWith(
              claim: '', throneWinner: '', pledged: const [], host: Host.none),
          flags: [
            for (final f in state.flags)
              if (!climbFlag(f)) f,
          ],
        ),
        data);
    await _persist();
  }

  /// The camp has shown the news from the coast: none is waiting.
  Future<void> markCoastNewsRead() async {
    if (state.politics.unreadNews.isEmpty) return;
    state = state.copyWith(
      politics: state.politics.copyWith(news: [
        for (final n in state.politics.news) n.read ? n : n.markedRead(),
      ]),
    );
    await _persist();
  }

  /// Edit Mode: the Open Hand's remembrance set to [stage] (0..6): its
  /// flags up to it held, those past it dropped; the titles it earns come
  /// with it ([data]), and stay.
  Future<void> setOpenHandStage(int stage, {required ClanData data}) async {
    final keep = openHandFlagsUpTo(stage);
    final flags = [
      for (final f in state.flags)
        if (!f.startsWith('open_hand_') || keep.contains(f)) f,
      for (final f in keep)
        if (!state.flags.contains(f)) f,
    ];
    state = _withTitles(state.copyWith(flags: flags), data);
    await _persist();
  }

  /// A road at rest passes for the betrayals on their way (hunter_mercy.dart):
  /// each is a road nearer. Returns the hunter whose betrayal is due (it is
  /// a betrayer from now on), or null.
  Future<String?> tickBetrayals() async {
    final coming = pendingBetrayals(state.flags);
    if (coming.isEmpty) return null;
    String? due;
    final flags = [
      for (final f in state.flags)
        if (!f.startsWith('betrayal_')) f,
    ];
    for (final MapEntry(key: enemyId, value: roads) in coming.entries) {
      if (roads <= 1 && due == null) {
        due = enemyId;
        flags.add(betrayerFlag(enemyId));
      } else {
        flags.add(betrayalFlag(enemyId, max(1, roads - 1)));
      }
    }
    state = state.copyWith(flags: flags);
    await _persist();
    return due;
  }

  /// A rival hunter beaten (hunter_mercy.dart): [spared] or finished, with
  /// [hunterClan]'s standing moved for it ([data]), and, spared, the
  /// betrayal rolled with [random] against the hunter's [alignment].
  /// Returns whether a betrayal is on its way.
  Future<bool> settleHunter(
    String enemyId, {
    required String hunterClan,
    required int alignment,
    required bool spared,
    required ClanData data,
    required Random random,
  }) async {
    await changeStanding(hunterClan, spared ? spareStanding : finishStanding,
        data: data, cause: spared ? 'mercy' : 'no_mercy');
    if (!spared) return false;
    final betrays =
        random.nextDouble() < betrayalChance(alignment, state.alignmentScore);
    final flag = betrays
        ? betrayalFlag(enemyId, betrayalRoads(random))
        : sparedFlag(enemyId);
    state = state.copyWith(flags: [...state.flags, flag]);
    await _persist();
    return betrays;
  }
}
