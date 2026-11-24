// The session notifier's story flags, losing an ally, quests and contracts (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _QuestActions on _SessionNotifierBase {
  /// Edit Mode: story flag [flag] held or not ([held]); the titles it
  /// earns come with it ([data]).
  Future<void> setStoryFlag(String flag, bool held,
      {required ClanData data}) async {
    if (flag.isEmpty || state.flags.contains(flag) == held) return;
    final flags = held
        ? [...state.flags, flag]
        : [
            for (final f in state.flags)
              if (f != flag) f,
          ];
    state = _withTitles(state.copyWith(flags: flags), data);
    await _persist();
  }

  /// The story takes [companionId] for good: out of the roster and the
  /// party, and never recruited again this run; a benched companion takes
  /// their seat (see [_removeAlly], which reads the house gates off
  /// [companions]). A no-op for an unknown or already-lost id. Returns who
  /// stepped in, if anyone.
  String? loseAlly(
    String companionId, {
    bool persist = true,
    Map<String, dynamic> companions = const {},
  }) {
    if (!state.recruitedAllies.any((a) => a.companionId == companionId)) {
      return null;
    }
    // Vica (a permanent companion) is never taken (story_companions.dart).
    if (isPermanentCompanion(
        companions[companionId] as Map<String, dynamic>?)) {
      return null;
    }
    final replacement =
        _removeAlly(companionId, lost: true, companions: companions);
    if (persist) _persist();
    return replacement;
  }

  /// Takes on [questId] and sets its `<id>_accepted` flag
  /// (questAcceptedFlag). A bounty in [quest] (a `countFromAccept` Kill
  /// objective) remembers its foes' kill counts now, so only the kills
  /// made after count (see [questKillBaselines]); a quest with none stores
  /// nothing. Without [quest] the objectives can't be read, and every
  /// count is kept, as before.
  Future<void> acceptQuest(String questId,
      {Map<String, dynamic>? quest}) async {
    if (state.activeQuestIds.contains(questId) ||
        state.completedQuestIds.contains(questId)) {
      return;
    }
    final baseline = _bountyBaseline(quest);
    state = state.copyWith(
      activeQuestIds: [...state.activeQuestIds, questId],
      // Marked taken: a district lock that opens on it opens now
      // (city_districts.dart).
      flags: {...state.flags, questAcceptedFlag(questId)}.toList(),
      // A baseline already taken (see [noteQuestOfferedBeforeFight]) stands.
      questKillBaselines: baseline.isEmpty
          ? state.questKillBaselines
          : {
              ...state.questKillBaselines,
              questId: state.questKillBaselines[questId] ?? baseline,
            },
      // With no quest followed yet, the one just taken on is followed.
      trackedQuestId: state.activeQuestIds.contains(state.trackedQuestId)
          ? state.trackedQuestId
          : questId,
    );
    await _persist();
  }

  /// A choice that fights and offers [questId] at once: the offer comes
  /// after the fight, so the bounty's kill baseline is taken from
  /// [killsBefore] (the counts before the fight) and the fight's own
  /// kills count towards it. Nothing is stored for a quest already
  /// taken or turned in, or one with no `countFromAccept` bounty.
  Future<void> noteQuestOfferedBeforeFight(
    String questId,
    Map<String, int> killsBefore, {
    required Map<String, dynamic>? quest,
  }) async {
    if (quest == null ||
        state.activeQuestIds.contains(questId) ||
        state.completedQuestIds.contains(questId) ||
        state.questKillBaselines.containsKey(questId)) {
      return;
    }
    final baseline = {
      for (final objective in (quest['objectives'] as List?) ?? const [])
        if (objective is Map<String, dynamic> &&
            objective['type'] == 'Kill' &&
            objective['countFromAccept'] == true)
          for (final id in killTargetsOf(objective)) id: killsBefore[id] ?? 0,
    };
    if (baseline.isEmpty) return;
    state = state.copyWith(
      questKillBaselines: {...state.questKillBaselines, questId: baseline},
    );
    await _persist();
  }

  Map<String, int> _bountyBaseline(Map<String, dynamic>? quest) {
    if (quest == null) return Map<String, int>.of(state.enemyKillCounts);
    return {
      for (final objective in (quest['objectives'] as List?) ?? const [])
        if (objective is Map<String, dynamic> &&
            objective['type'] == 'Kill' &&
            objective['countFromAccept'] == true)
          for (final id in killTargetsOf(objective))
            id: state.enemyKillCounts[id] ?? 0,
    };
  }

  /// Puts a fresh bounty board up at the camp (see rollContracts) for
  /// [chapter], replacing whatever was there.
  Future<void> postContractBoard(List<Contract> board,
      {required int chapter}) async {
    state = state.copyWith(
      contracts: board,
      contractsChapter: chapter,
      contractBoards: state.contractBoards + 1,
    );
    await _persist();
  }

  /// Pays a met contract's gold and essence and takes it off the board.
  Future<void> claimContract(String contractId) async {
    final contract =
        state.contracts.where((c) => c.id == contractId).firstOrNull;
    if (contract == null || !contract.done) return;
    state = state.copyWith(
      gold: state.gold + contract.rewardGold,
      skillEssence: state.skillEssence + contract.rewardEssence,
      contracts: [
        for (final c in state.contracts)
          if (c.id != contractId) c,
      ],
    );
    await _persist();
  }

  /// Follows [questId]: its current goal shows above the story. Only an
  /// active quest can be followed.
  Future<void> trackQuest(String questId) async {
    if (!state.activeQuestIds.contains(questId)) return;
    state = state.copyWith(trackedQuestId: questId);
    await _persist();
  }

  /// Returns whether the quest's XP reward leveled the player up (so the
  /// caller can show the same level-up dialog a combat level-up shows).
  Future<bool> completeQuest(
    String questId, {
    int rewardGold = 0,
    int rewardXP = 0,
    String? rewardItemId,
    String? nextQuestId,
    String? rewardDiceId,
    String? grantsBannerPieceId,
    int alignmentMod = 0,
    Map<String, dynamic>? rewardItem,
    ItemOrigin? origin,
  }) async {
    final newActive =
        state.activeQuestIds.where((id) => id != questId).toList();
    final newCompleted = <String>{...state.completedQuestIds, questId}.toList();
    final newInventory = [...state.inventoryItemIds];
    var newOrigins = state.itemOrigins;
    var potionsGained = 0;
    var antidotesGained = 0;
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      final charges =
          PlayerSessionNotifier.consumableChargesFor(rewardItemId, rewardItem);
      if (charges == null) {
        newInventory.add(rewardItemId);
        newOrigins = withItemOrigins(newOrigins, [rewardItemId], origin);
      } else {
        potionsGained = charges.potions;
        antidotesGained = charges.antidotes;
      }
    }
    var newUnlockedQuests = state.unlockedQuestIds;
    if (nextQuestId != null &&
        nextQuestId.isNotEmpty &&
        !newUnlockedQuests.contains(nextQuestId)) {
      newUnlockedQuests = [...newUnlockedQuests, nextQuestId];
    }
    var newOwnedDice = state.ownedDiceIds;
    if (rewardDiceId != null &&
        rewardDiceId.isNotEmpty &&
        !newOwnedDice.contains(rewardDiceId)) {
      newOwnedDice = [...newOwnedDice, rewardDiceId];
    }
    var newBannerPieces = state.bannerPiecesCollected;
    if (grantsBannerPieceId != null &&
        grantsBannerPieceId.isNotEmpty &&
        !newBannerPieces.contains(grantsBannerPieceId)) {
      newBannerPieces = [...newBannerPieces, grantsBannerPieceId];
    }

    final leveled = _applyXp(rewardXP);
    final newAllies = leveled.leveledUp
        ? _healAndGrowAlliesOnLevelUp(leveled.levelsGained)
        : state.recruitedAllies;

    state = state.copyWith(
      level: leveled.level,
      currentXP: leveled.xp,
      maxHealth: leveled.maxHealth,
      baseDamage: leveled.baseDamage,
      currentHealth:
          leveled.leveledUp ? leveled.maxHealth : state.currentHealth,
      statPoints: leveled.statPoints,
      // Each level reached brings an offer (see offers.dart).
      pendingOffers: [
        ...state.pendingOffers,
        ...PlayerSessionNotifier._levelOffers(leveled.levelsGained),
      ],
      rerollCharges: _levelCharges(RollPower.reroll, leveled.levelsGained),
      banishCharges: _levelCharges(RollPower.banish, leveled.levelsGained),
      gold: state.gold + rewardGold,
      alignmentScore: state.alignmentScore + alignmentMod,
      activeQuestIds: newActive,
      // A finished bounty's baseline has nothing left to count.
      questKillBaselines: state.questKillBaselines.containsKey(questId)
          ? ({...state.questKillBaselines}..remove(questId))
          : state.questKillBaselines,
      // A quest turned in is no longer followed; the next active one
      // stands in until the player picks another.
      trackedQuestId:
          state.trackedQuestId == questId ? '' : state.trackedQuestId,
      completedQuestIds: newCompleted,
      inventoryItemIds: newInventory,
      itemOrigins: newOrigins,
      potionCount: state.potionCount + potionsGained,
      antidoteCount: state.antidoteCount + antidotesGained,
      unlockedQuestIds: newUnlockedQuests,
      ownedDiceIds: newOwnedDice,
      xpEarnedThisRun: state.xpEarnedThisRun + rewardXP,
      skillEssence: state.skillEssence + rewardXP,
      recruitedAllies: newAllies,
      bannerPiecesCollected: newBannerPieces,
    );
    // The patron's gifts at each level reached (patron_stats.dart).
    if (leveled.leveledUp) {
      state = _withPatronGains(state, leveled.levelsGained).withCursesEnded();
    }
    await _persist();
    return leveled.leveledUp;
  }
}
