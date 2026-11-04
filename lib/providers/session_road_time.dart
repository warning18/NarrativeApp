// The session notifier's time and rest, achievements, unlocks, NPCs, what has been seen, road steps, provisions, sellswords and the temple (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _RoadTimeActions on _SessionNotifierBase {
  /// Moves the clock on by [watches] quarters of a day (an expedition is
  /// two, a day at sea four). In [chapter], the days it passes count
  /// toward the chapter's threat (see [threatIn]).
  Future<void> passTime(int watches, {int? chapter}) async {
    if (watches <= 0) return;
    final session = chapter != null && roadRulesApply(chapter)
        ? _clockedIn(state, chapter)
        : state;
    state = _later(session, watches);
    await _persist();
  }

  /// [session] with the clock [watches] on: past the night, the next day
  /// begins at dawn.
  static PlayerSession _later(PlayerSession session, int watches) {
    final total = session.watch + watches;
    return session.copyWith(
      day: session.day + total ~/ watchesPerDay,
      watch: total % watchesPerDay,
    );
  }

  /// A night's rest: the party heals and wakes at the next dawn, a day on
  /// ([chapter]'s, for its threat, see [threatIn]).
  Future<void> restUntilDawn({int? chapter}) async {
    final session = chapter != null && roadRulesApply(chapter)
        ? _clockedIn(state, chapter)
        : state;
    state = session.copyWith(day: session.day + 1, watch: 0);
    await healPartyToFull();
  }

  // --- Achievements -------------------------------------------------------

  /// Grants a single achievement outright — for milestones that are a
  /// one-off *event* rather than something derivable from persisted state
  /// (e.g. "revived a knocked-out ally," which isn't itself remembered once
  /// the fight ends). Idempotent; returns whether it was newly unlocked, so
  /// a caller can show a notice only the first time.
  Future<bool> unlockAchievement(String id) async {
    if (state.unlockedAchievementIds.contains(id)) return false;
    state = state.copyWith(
        unlockedAchievementIds: [...state.unlockedAchievementIds, id]);
    await _persist();
    return true;
  }

  /// Checks every achievement whose condition is a plain function of
  /// current, already-persisted [PlayerSession] state, and unlocks any
  /// newly met — called after whichever mutators could make one newly true
  /// (recruiting, activating an ally, building a house, completing a
  /// quest). [totalCompanionCount] is optional (the notifier has no DB
  /// access of its own) — pass it (from companions.json) when checking
  /// right after a recruit, the only time "recruited everyone" could
  /// newly become true; omitting it just skips that one check. Returns the
  /// newly-unlocked ids, if a caller wants to show a notice.
  @override
  Future<List<String>> checkAchievements({int totalCompanionCount = 0}) async {
    final newly = <String>[];
    void check(String id, bool condition) {
      if (condition &&
          !state.unlockedAchievementIds.contains(id) &&
          !newly.contains(id)) {
        newly.add(id);
      }
    }

    check('first_companion', state.recruitedAllies.isNotEmpty);
    if (totalCompanionCount > 0) {
      check(
          'full_roster',
          state.recruitedAllies.length >=
              min(totalCompanionCount, fullRosterCompanionCount));
    }
    // "Field a full 3-member active party" means the player plus 2 active
    // allies (the default party capacity) -- activeAllyIds counts allies
    // only, so the threshold here is 2, not 3.
    check('full_party', state.activeAllyIds.length >= 2);
    check('keldas_hall_built', state.builtHouseIds.contains('keldas_hall'));
    check('first_quest', state.completedQuestIds.isNotEmpty);
    check('first_shop', state.unlockedShopIds.isNotEmpty);

    // The story's milestones: plain functions of the saved flags, banner
    // pieces, politics and New Game+ cycle.
    check('on_the_throne', state.flags.contains('on_throne'));
    check('half_a_banner', state.bannerPiecesCollected.length >= 3);
    check('whole_cloth', state.flags.contains('banner_whole'));
    final settled = <String>{
      for (final flag in state.flags)
        if (_intrigueOutcomeFlag.firstMatch(flag) case final match?)
          match.group(1)!,
    };
    check('first_thread', settled.isNotEmpty);
    check('whole_web', settled.length >= intrigueCount);
    check('time_turned', state.newGamePlusCycle >= 1);
    final politics = state.politics;
    check('sworn_to_a_clan', politics.swornFactionId.isNotEmpty);
    check(
        'hunted_by_a_clan',
        coastClanIds.any((id) =>
            standingTierFor(politics.standings[id] ?? 0) ==
            StandingTier.hunted));
    check(
        'friend_of_four_clans',
        politics.swornFactionId.isEmpty &&
            coastClanIds
                    .where((id) => standingTierFor(politics.standings[id] ?? 0)
                        .isAtLeast(StandingTier.trusted))
                    .length >=
                _trustedClansForFriend);
    check('akagiri_found', state.flags.contains(placeFoundFlag('3200')));
    check('kindly_hill_found', state.flags.contains(placeFoundFlag('5200')));
    check('highhearth_found', state.flags.contains(placeFoundFlag('6200')));

    if (newly.isNotEmpty) {
      state = state.copyWith(
        unlockedAchievementIds: [...state.unlockedAchievementIds, ...newly],
      );
      await _persist();
    }
    return newly;
  }

  /// Marks a shop/quest/enemy as discovered through story progression, so it
  /// becomes accessible in the Play tab. Empty/null ids are ignored.
  ///
  /// [shopUnlockNodeId] records which story node's choice unlocked the shop
  /// (usually the node the player is leaving when the choice fires) — shops
  /// are only browsable while the player is currently on that node.
  @override
  Future<void> unlockContent({
    String? shopId,
    String? questId,
    String? enemyId,
    String? shopUnlockNodeId,
  }) async {
    var newShops = state.unlockedShopIds;
    var newQuests = state.unlockedQuestIds;
    var newEnemies = state.unlockedEnemyIds;
    var newShopUnlockNodeIds = state.shopUnlockNodeIds;
    var newSeenShopIds = state.seenShopIds;
    var newSeenQuestIds = state.seenQuestIds;
    var newSeenEnemyIds = state.seenEnemyIds;
    if (shopId != null && shopId.isNotEmpty) {
      if (!newShops.contains(shopId)) {
        newShops = [...newShops, shopId];
      }
      // Meeting a shop's stall on the road never takes it away from the
      // scene where the story placed it.
      final keepsItsPlace = shopUnlockNodeId == roadShopNodeId &&
          newShopUnlockNodeIds.containsKey(shopId);
      if (shopUnlockNodeId != null &&
          shopUnlockNodeId.isNotEmpty &&
          !keepsItsPlace) {
        newShopUnlockNodeIds = {
          ...newShopUnlockNodeIds,
          shopId: shopUnlockNodeId
        };
      }
      if (newSeenShopIds.contains(shopId)) {
        newSeenShopIds = newSeenShopIds.where((id) => id != shopId).toList();
      }
    }
    if (questId != null && questId.isNotEmpty) {
      if (!newQuests.contains(questId)) {
        newQuests = [...newQuests, questId];
      }
      if (newSeenQuestIds.contains(questId)) {
        newSeenQuestIds = newSeenQuestIds.where((id) => id != questId).toList();
      }
    }
    if (enemyId != null && enemyId.isNotEmpty) {
      if (!newEnemies.contains(enemyId)) {
        newEnemies = [...newEnemies, enemyId];
      }
      if (newSeenEnemyIds.contains(enemyId)) {
        newSeenEnemyIds = newSeenEnemyIds.where((id) => id != enemyId).toList();
      }
    }
    if (identical(newShops, state.unlockedShopIds) &&
        identical(newQuests, state.unlockedQuestIds) &&
        identical(newEnemies, state.unlockedEnemyIds) &&
        identical(newShopUnlockNodeIds, state.shopUnlockNodeIds) &&
        identical(newSeenShopIds, state.seenShopIds) &&
        identical(newSeenQuestIds, state.seenQuestIds) &&
        identical(newSeenEnemyIds, state.seenEnemyIds)) {
      return;
    }
    state = state.copyWith(
      unlockedShopIds: newShops,
      unlockedQuestIds: newQuests,
      unlockedEnemyIds: newEnemies,
      shopUnlockNodeIds: newShopUnlockNodeIds,
      seenShopIds: newSeenShopIds,
      seenQuestIds: newSeenQuestIds,
      seenEnemyIds: newSeenEnemyIds,
    );
    await _persist();
  }

  /// Records a conversation with an NPC — permanent, append-only, like
  /// [completedQuestIds]. Backs Talk-type quest objectives (see
  /// quest_objectives.dart) and is otherwise purely a flavor record of who
  /// the player has met.
  Future<void> talkToNpc(String npcId) async {
    if (npcId.isEmpty || state.talkedToNpcIds.contains(npcId)) return;
    state = state.copyWith(
      talkedToNpcIds: [...state.talkedToNpcIds, npcId],
    );
    await _persist();
  }

  /// Marks a shop/quest/enemy id as viewed in the Play tab, clearing its
  /// "newly unlocked" badge contribution.
  Future<void> markSeen(
      {String? shopId, String? questId, String? enemyId}) async {
    var newSeenShopIds = state.seenShopIds;
    var newSeenQuestIds = state.seenQuestIds;
    var newSeenEnemyIds = state.seenEnemyIds;
    if (shopId != null &&
        shopId.isNotEmpty &&
        !newSeenShopIds.contains(shopId)) {
      newSeenShopIds = [...newSeenShopIds, shopId];
    }
    if (questId != null &&
        questId.isNotEmpty &&
        !newSeenQuestIds.contains(questId)) {
      newSeenQuestIds = [...newSeenQuestIds, questId];
    }
    if (enemyId != null &&
        enemyId.isNotEmpty &&
        !newSeenEnemyIds.contains(enemyId)) {
      newSeenEnemyIds = [...newSeenEnemyIds, enemyId];
    }
    if (identical(newSeenShopIds, state.seenShopIds) &&
        identical(newSeenQuestIds, state.seenQuestIds) &&
        identical(newSeenEnemyIds, state.seenEnemyIds)) {
      return;
    }
    state = state.copyWith(
      seenShopIds: newSeenShopIds,
      seenQuestIds: newSeenQuestIds,
      seenEnemyIds: newSeenEnemyIds,
    );
    await _persist();
  }

  /// Marks the town or camp scene [key] (see sceneReadKey) as read.
  Future<void> markSceneRead(String key) async {
    if (state.readSceneKeys.contains(key)) return;
    state = state.copyWith(readSceneKeys: [...state.readSceneKeys, key]);
    await _persist();
  }

  // --- The road: echoes, rations, days and sellswords ---------------------

  /// Remembers the echoes [keys] (see echoes.dart) as read.
  Future<void> noteEchoes(Iterable<String> keys) async {
    final fresh = [
      for (final key in {...keys})
        if (!state.seenEchoKeys.contains(key)) key,
    ];
    if (fresh.isEmpty) return;
    state = state.copyWith(seenEchoKeys: [...state.seenEchoKeys, ...fresh]);
    await _persist();
  }

  /// Remembers the one-time fight tips [ids] (see fight_tips.dart) as shown
  /// on this save.
  Future<void> markFightTipsSeen(Iterable<String> ids) async {
    final fresh = [
      for (final id in {...ids})
        if (!state.seenFightTipIds.contains(id)) id,
    ];
    if (fresh.isEmpty) return;
    state =
        state.copyWith(seenFightTipIds: [...state.seenFightTipIds, ...fresh]);
    await _persist();
  }

  /// Remembers who rules each town ([rulers]: town id -> clan id) as the
  /// player has now seen it on the world chart.
  Future<void> markTownRulersSeen(Map<String, String> rulers) async {
    if (mapEquals(state.seenTownRulers, rulers)) return;
    state = state.copyWith(seenTownRulers: Map.unmodifiable(rulers));
    await _persist();
  }

  /// [session] with the clock counting [chapter]'s days, from today if it
  /// was counting another's.
  PlayerSession _clockedIn(PlayerSession session, int chapter) =>
      session.clockChapter == chapter
          ? session
          : session.copyWith(
              clockChapter: chapter, chapterStartDay: session.day);

  /// One step on the road in [chapter]: a ration eaten (or, with none
  /// left, hunger's bite, see [hungerDamage]) and [watches] of the day
  /// gone, a watch for a step (see [passTime]; a walk between places is
  /// [walkWatches]). Chapter 1 has no town to buy from, so its roads cost
  /// nothing.
  Future<RoadStep> takeRoadStep({required int chapter, int watches = 1}) async {
    if (!roadRulesApply(chapter)) return const RoadStep();
    final session = _clockedIn(state, chapter);
    final hungry = session.provisions <= 0;
    final bite = hungry
        ? hungerDamage(
            health: session.currentHealth, maxHealth: session.maxHealth)
        : 0;
    final later = _later(session, watches);
    state = later.copyWith(
      provisions: hungry ? 0 : session.provisions - 1,
      currentHealth: session.currentHealth - bite,
    );
    await _persist();
    return RoadStep(
      counted: true,
      hungry: hungry,
      hunger: bite,
      dayEnded: later.day > session.day,
      day: later.day,
      provisionsLeft: state.provisions,
    );
  }

  /// A day at sea in [chapter]: the whole day on the clock (see
  /// [passTime]) and, where the road's rules apply, the crew's ration for
  /// it, as a step on the road eats one (see [takeRoadStep]).
  Future<RoadStep> passSeaDay({required int chapter}) async {
    if (!roadRulesApply(chapter)) {
      await passTime(watchesPerDay, chapter: chapter);
      return const RoadStep();
    }
    return takeRoadStep(chapter: chapter, watches: watchesPerDay);
  }

  /// [days] pass in [chapter] (a day lost on an expedition): the same
  /// watch of the day, [days] later.
  Future<void> passDays(int days, {required int chapter}) async {
    if (days <= 0) return;
    final session =
        roadRulesApply(chapter) ? _clockedIn(state, chapter) : state;
    state = session.copyWith(day: session.day + days);
    await _persist();
  }

  /// A night's rest in a town, a port or the camp: the whole party healed
  /// (see [healPartyToFull]), and in [chapter] a day gone (see
  /// [restUntilDawn]).
  Future<void> restNight({required int chapter}) =>
      restUntilDawn(chapter: chapter);

  /// Buys [count] rations at [price] each, as many as the pack holds (see
  /// [provisionsMax]). False, and nothing bought, when the purse or the
  /// pack falls short.
  Future<bool> buyProvisions(int count, {required int price}) async {
    final room = provisionsMax - state.provisions;
    final cost = count * price;
    if (count <= 0 || count > room || state.gold < cost) return false;
    state = state.copyWith(
      gold: state.gold - cost,
      provisions: state.provisions + count,
    );
    await _persist();
    return true;
  }

  /// [delta] rations found or lost (the camp's fate die), the pack kept
  /// between empty and [provisionsMax]. Returns the change made.
  Future<int> adjustProvisions(int delta) async {
    final next = (state.provisions + delta).clamp(0, provisionsMax);
    final change = next - state.provisions;
    if (change == 0) return 0;
    state = state.copyWith(provisions: next);
    await _persist();
    return change;
  }

  /// Hires a sellsword for [sellswordContractFights] fights at [price]. False when
  /// one is already under contract or the purse falls short.
  Future<bool> hireSellsword({required int price}) async {
    if (state.sellswordFights > 0 || state.gold < price) return false;
    state = state.copyWith(
      gold: state.gold - price,
      sellswordFights: sellswordContractFights,
    );
    await _persist();
    return true;
  }

  /// One fight of the sellsword's contract spent.
  Future<void> spendSellswordFight() async {
    if (state.sellswordFights <= 0) return;
    state = state.copyWith(sellswordFights: state.sellswordFights - 1);
    await _persist();
  }

  /// Notes that a companion spoke up at sea in [chapter] (see
  /// speakUpAtSea), so the next voyage of the chapter stays quiet.
  Future<void> noteSeaRemark(int chapter) async {
    if (state.seaRemarkChapter == chapter) return;
    state = state.copyWith(seaRemarkChapter: chapter);
    await _persist();
  }

  // --- The temple (temple.dart) -------------------------------------------

  /// The offer of the temple [clanId] ('' neutral) keeps, to the party
  /// now, in [chapter] ([busy]: a fight or an expedition under way).
  TempleOffer templeOffer(String clanId,
          {required ClanData data, required int chapter, bool busy = false}) =>
      templeOfferFor(
        clanId: clanId,
        data: data,
        politics: state.politics,
        chapter: chapter,
        day: state.day,
        gold: state.gold,
        alignment: state.alignmentScore,
        templeMendDay: state.templeMendDay,
        blessingFights: state.blessingFights,
        standingChapters: state.templeStandingChapters,
        busy: busy,
      );

  /// Mending at the temple [clanId] keeps: the whole party to full health,
  /// mana unchanged, no time passing, for the offer's price. False, and
  /// nothing done, when the offer is shut (Hunted, busy, too poor, mended
  /// today, chapter 1).
  Future<bool> templeMend(String clanId,
      {required ClanData data, required int chapter, bool busy = false}) async {
    final offer = templeOffer(clanId, data: data, chapter: chapter, busy: busy);
    if (!offer.canMend) return false;
    state = state.copyWith(
      gold: state.gold - offer.mendPrice,
      templeMendDay: state.day,
      currentHealth: state.maxHealth,
      recruitedAllies: [
        for (final ally in state.recruitedAllies)
          ally.copyWith(currentHealth: AllyState.fullHealthSentinel),
      ],
    );
    await _persist();
    return true;
  }

  /// A blessing at the temple [clanId] keeps, for [templeBlessingFights]
  /// fights, replacing any carried; the first of [chapter] from a clan
  /// brings [templeStandingGain] standing with it. False, and nothing
  /// done, when the offer is shut (Hunted, busy, too poor).
  Future<bool> templeBless(String clanId,
      {required ClanData data, required int chapter, bool busy = false}) async {
    final offer = templeOffer(clanId, data: data, chapter: chapter, busy: busy);
    if (!offer.canBless) return false;
    state = state.copyWith(
      gold: state.gold - offer.blessingPrice,
      blessingFights: templeBlessingFights,
      blessingClan: offer.clanId,
      templeStandingChapters: offer.blessingStanding
          ? {...state.templeStandingChapters, offer.clanId: chapter}
          : null,
    );
    if (offer.blessingStanding) {
      await changeStanding(offer.clanId, templeStandingGain,
          data: data, cause: 'temple', chapter: chapter);
    }
    await _persist();
    return true;
  }

  /// One fight of the temple's blessing spent; the last ends it.
  Future<void> spendBlessingFight() async {
    if (state.blessingFights <= 0) return;
    final left = state.blessingFights - 1;
    state = state.copyWith(
        blessingFights: left, blessingClan: left == 0 ? '' : null);
    await _persist();
  }

  /// An alignment event was rolled (see maybeAlignmentEvent): [ambushed]
  /// when it sent a hunter, which starts the hunters' cooldown over.
  Future<void> noteAlignmentRoll({required bool ambushed}) async {
    final next = ambushed
        ? 0
        : min(hunterCooldownRolls, state.alignmentRollsSinceAmbush + 1);
    if (next == state.alignmentRollsSinceAmbush) return;
    state = state.copyWith(alignmentRollsSinceAmbush: next);
    await _persist();
  }

  /// The detours' pacing after a road (see planRoad).
  Future<void> setDetourPacing(DetourPacing pacing) async {
    state = state.copyWith(detourPacing: pacing);
    await _persist();
  }

  /// Marks every currently-unlocked shop/quest/enemy id as seen at once —
  /// used when a Play-tab section is expanded, clearing its whole badge.
  /// Marks every entry of a Play tab section as viewed, clearing its
  /// badge. The people known are not kept on the session (see
  /// npcDiscovered: they follow the scenes visited), so [npcs] takes the
  /// ids on show as [npcIds]; those join [PlayerSession.seenNpcIds].
  Future<void> markAllSeenInCategory({
    bool shops = false,
    bool quests = false,
    bool enemies = false,
    bool npcs = false,
    Iterable<String> npcIds = const [],
  }) async {
    final seenNpcs =
        npcs ? {...state.seenNpcIds, ...npcIds}.toList() : state.seenNpcIds;
    state = state.copyWith(
      seenShopIds: shops ? state.unlockedShopIds : state.seenShopIds,
      seenQuestIds: quests ? state.unlockedQuestIds : state.seenQuestIds,
      seenEnemyIds: enemies ? state.unlockedEnemyIds : state.seenEnemyIds,
      seenNpcIds: seenNpcs.length == state.seenNpcIds.length
          ? state.seenNpcIds
          : seenNpcs,
    );
    await _persist();
  }
}
