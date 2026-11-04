// The session notifier's dice-face skills, branches, merges, debug stats, potions and mana, level-ups, a fight's result and permadeath (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _SkillsCombatActions on _SessionNotifierBase {
  Future<void> assignSkillToDiceFace(
      String diceId, int faceIndex, String skillId) async {
    final updated = <String, Map<String, String>>{
      for (final entry in state.diceSkillAssignments.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    final faceMap = Map<String, String>.from(updated[diceId] ?? const {});
    faceMap[faceIndex.toString()] = skillId;
    updated[diceId] = faceMap;
    state = state.copyWith(diceSkillAssignments: updated);
    await _persist();
  }

  Future<void> clearDiceFaceSkill(String diceId, int faceIndex) async {
    final faceMap = state.diceSkillAssignments[diceId];
    if (faceMap == null || !faceMap.containsKey(faceIndex.toString())) return;
    final updated = <String, Map<String, String>>{
      for (final entry in state.diceSkillAssignments.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    updated[diceId]!.remove(faceIndex.toString());
    state = state.copyWith(diceSkillAssignments: updated);
    await _persist();
  }

  /// Masters [branchId] for [cost] skill essence (v1.194: skill points
  /// are gone, see offers.dart): the one skill-tree branch whose skills
  /// fight a tier higher (see skill_tree.dart). No-op when a branch is
  /// already mastered or the essence is short; the caller checks the
  /// branch is complete.
  Future<void> masterBranch(String branchId,
      {int cost = branchMasteryEssenceCost}) async {
    if (state.masteredBranchId.isNotEmpty || state.skillEssence < cost) return;
    state = state.copyWith(
      masteredBranchId: branchId,
      skillEssence: state.skillEssence - cost,
    );
    await _persist();
  }

  /// Spends [skillEssence] to raise an already-unlocked skill's tier by
  /// one, up to [maxSkillTier] — see combat_engine.dart's [applySkillTier]
  /// for what a tier actually does in combat. No-ops if the skill isn't
  /// unlocked, is already maxed, or essence is short.
  Future<void> upgradeSkillTier(String skillId) async {
    if (!state.unlockedSkillIds.contains(skillId)) return;
    final currentTier = state.skillTiers[skillId] ?? 0;
    if (currentTier >= maxSkillTier) return;
    final cost = skillTierUpgradeCost(currentTier);
    if (state.skillEssence < cost) return;
    state = state.copyWith(
      skillEssence: state.skillEssence - cost,
      skillTiers: {...state.skillTiers, skillId: currentTier + 1},
    );
    await _persist();
  }

  /// Fuses two unlocked skills into a new one, per a skill_merges.json
  /// recipe: both [inputSkillIds] are consumed (removed from
  /// unlockedSkillIds, along with any tier progress on them) and
  /// [resultSkillId] is unlocked in their place — a real trade-off, not a
  /// strict upgrade. No-ops unless the camp's Skillwright stands (see
  /// skill_craft.dart), both inputs are currently unlocked and the result
  /// isn't already unlocked.
  Future<void> mergeSkills({
    required List<String> inputSkillIds,
    required String resultSkillId,
  }) async {
    // Skills are crafted at the camp's Skillwright only (Wave 7).
    if (!skillCraftOpen(state.builtHouseIds)) return;
    if (state.unlockedSkillIds.contains(resultSkillId)) return;
    for (final id in inputSkillIds) {
      if (!state.unlockedSkillIds.contains(id)) return;
    }
    final newUnlocked = [
      for (final id in state.unlockedSkillIds)
        if (!inputSkillIds.contains(id)) id,
      resultSkillId,
    ];
    final newTiers = {...state.skillTiers}
      ..removeWhere((id, _) => inputSkillIds.contains(id));
    state = state.copyWith(
      unlockedSkillIds: newUnlocked,
      skillTiers: newTiers,
    );
    await _persist();
  }

  /// What the formative memories left (origin_stories.dart): their
  /// [alignmentMod], a point in each ability of [abilities] per lesson, and
  /// their [flags] for the story's echoes. Applied once, as creation ends.
  Future<void> applyOriginMemories({
    required int alignmentMod,
    required Map<String, int> abilities,
    required List<String> flags,
  }) async {
    state = state.withSourcedGains(ledgerOrigin, '', abilities).copyWith(
          alignmentScore: state.alignmentScore + alignmentMod,
          flags: <String>{...state.flags, ...flags}.toList(),
        );
    await _persist();
  }

  /// Directly overwrites any subset of the player's stats — bypassing all
  /// normal game rules (gold/level requirements, max-health clamping,
  /// etc). Only intended for the Edit-mode stat editor, so QA/authoring
  /// can jump straight to a specific game state to test a node or fight
  /// without replaying to reach it.
  Future<void> debugSetStats({
    int? level,
    int? currentXP,
    int? gold,
    int? alignmentScore,
    int? maxHealth,
    int? currentHealth,
    int? baseDamage,
    int? baseArmor,
    int? luck,
    int? charisma,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? perception,
    int? potionCount,
    int? statPoints,
    int? antidoteCount,
    int? mana,
  }) async {
    state = state.copyWith(
      level: level,
      currentXP: currentXP,
      gold: gold,
      alignmentScore: alignmentScore,
      maxHealth: maxHealth,
      currentHealth: currentHealth,
      baseDamage: baseDamage,
      baseArmor: baseArmor,
      luck: luck,
      charisma: charisma,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      perception: perception,
      potionCount: potionCount,
      statPoints: statPoints,
      statPickOffer: statPoints == null ? null : const [],
      tomePicks: statPoints == null
          ? null
          : state.tomePicks.take(max(0, statPoints)).toList(),
      antidoteCount: antidoteCount,
      mana: mana,
    );
    await _persist();
  }

  /// Marks [landmarkId] as the map's one goal (null clears it), see
  /// heard_of.dart's withMapGoal: a flag, no save field of its own.
  Future<void> setMapGoal(String? landmarkId) async {
    state = state.copyWith(flags: withMapGoal(state.flags, landmarkId));
    await _persist();
  }

  Future<void> consumePotion() async {
    if (state.potionCount <= 0) return;
    state = state.copyWith(potionCount: state.potionCount - 1);
    await _persist();
  }

  /// Uses up one carried copy of [itemId] (a scroll read in a fight).
  Future<void> consumeItem(String itemId) async {
    if (!state.inventoryItemIds.contains(itemId)) return;
    state = state.copyWith(
        inventoryItemIds: [...state.inventoryItemIds]..remove(itemId));
    await _persist();
  }

  Future<void> consumeAntidote() async {
    if (state.antidoteCount <= 0) return;
    state = state.copyWith(antidoteCount: state.antidoteCount - 1);
    await _persist();
  }

  /// Sets the party's mana, clamped to `0..maxMana` -- the fight screen
  /// writes through this after every cast and every Mana face, so a fight
  /// abandoned mid-way keeps what was spent and gained, like potions.
  Future<void> setMana(int value) async {
    final clamped = value.clamp(0, state.maxMana);
    if (clamped == state.mana) return;
    state = state.copyWith(mana: clamped);
    await _persist();
  }

  /// Runs [xpGain] through the level-up threshold ([xpForLevel] each),
  /// applying every level gained: [levelStatPicks] stat pick and
  /// [levelHealthGain] max health (stat_rules.dart; base damage grows only
  /// with the damage stat), and an offer, which the callers add: see
  /// [_levelOffers]. Shared by
  /// [applyCombatResult] and [completeQuest] so a quest's XP reward levels
  /// the player up exactly like combat XP does.
  @override
  ({
    int level,
    int xp,
    int maxHealth,
    int baseDamage,
    int statPoints,
    bool leveledUp,
    int levelsGained,
  }) _applyXp(int xpGain) {
    var newLevel = state.level;
    var newXp = state.currentXP + xpGain;
    var newMaxHealth = state.maxHealth;
    final newBaseDamage = state.baseDamage;
    var newStatPoints = state.statPoints;
    var leveledUp = false;
    var levelsGained = 0;

    while (newXp >= xpForLevel(newLevel)) {
      newXp -= xpForLevel(newLevel);
      newLevel += 1;
      newStatPoints += levelStatPicks;
      newMaxHealth += levelHealthGain;
      leveledUp = true;
      levelsGained += 1;
    }

    return (
      level: newLevel,
      xp: newXp,
      maxHealth: newMaxHealth,
      baseDamage: newBaseDamage,
      statPoints: newStatPoints,
      leveledUp: leveledUp,
      levelsGained: levelsGained,
    );
  }

  /// [session] after [levels] levels reached with the patron's gifts
  /// (patron_stats.dart): its stats, its max health, a line on the clan
  /// log each level.
  @override
  PlayerSession _withPatronGains(PlayerSession session, int levels) {
    var s = session;
    for (var i = 0; i < levels; i++) {
      final stats = {
        'strength': s.strength,
        'dexterity': s.dexterity,
        'constitution': s.constitution,
        'intelligence': s.intelligence,
        'wisdom': s.wisdom,
        'charisma': s.charisma,
        'luck': s.luck,
        'perception': s.perception,
      };
      final level = s.level - levels + i + 1;
      final gains = patronLevelGains(s.politics,
          level: level, stats: stats, openHand: bannerRaisedIn(s.flags));
      if (gains.stats.isEmpty && gains.maxHealth == 0) continue;
      // The ledger tells the patron's own gift from the open hand's point.
      final patron = statPatron(s.politics);
      final own = patronLevelGains(s.politics, level: level, stats: stats);
      final openHand = {
        for (final e in gains.stats.entries)
          e.key: e.value - (own.stats[e.key] ?? 0),
      }..removeWhere((_, v) => v == 0);
      s = s.withSourcedGains(ledgerPatron, patron, own.stats,
          maxHealth: gains.maxHealth);
      s = s.withSourcedGains(ledgerPatron, openHandSourceId, openHand);
      s = s.copyWith(
        politics: logPatronGains(s.politics, statPatron(s.politics), gains,
            chapter: _politicsChapter(null), day: s.day),
      );
    }
    return s;
  }

  /// A level-up full-heals the player and, mirroring that, every recruited
  /// ally too — "grows with you": a companion still gains their own skill
  /// point a level (see AllyState.skillPoints doc), the player an offer.
  @override
  List<AllyState> _healAndGrowAlliesOnLevelUp(int levelsGained) {
    return [
      for (final ally in state.recruitedAllies)
        ally.copyWith(
          currentHealth: AllyState.fullHealthSentinel,
          skillPoints: ally.skillPoints + levelsGained,
        ),
    ];
  }

  /// A lost boss fight: one more defeat on the books for each boss in it,
  /// read back as Resolve next time (see party_bonus.dart).
  Future<void> recordBossDefeat(List<String> enemyIds) async {
    if (enemyIds.isEmpty) return;
    final counts = Map<String, int>.from(state.bossDefeatCounts);
    for (final id in enemyIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    state = state.copyWith(bossDefeatCounts: counts);
    await _persist();
  }

  /// Applies a fight's outcome to the player's stats. Returns true if the
  /// XP gain pushed the player up one or more levels, so the caller can
  /// show a level-up celebration. [enemyId] (the enemy just beaten) is
  /// optional only for callers with no real enemy to name (there are
  /// none today, but nothing here strictly requires one) — passing it is
  /// what credits Kill-type quest objectives (see quest_objectives.dart)
  /// via [PlayerSession.enemyKillCounts].
  Future<bool> applyCombatResult({
    required int hpAfter,
    String? enemyId,
    List<String> enemyIds = const [],
    int goldGain = 0,
    int xpGain = 0,
    List<String> itemsGained = const [],
    Map<String, dynamic> items = const {},
    int? lootPityStreak,
    List<String>? recentLootIds,
    int? manaAfter,
    ContractTally? contractTally,
    int bossOffers = 0,
    int titanBlood = 0,
    bool pactFight = false,
    bool keepWounds = false,
    ItemOrigin? origin,
  }) async {
    final leveled = _applyXp(xpGain);

    // Looted potions/antidotes become charges (see [consumableChargesFor]),
    // a looted tome is read on the spot (see [tomeGrantFor]); everything
    // else is carried in the inventory.
    var potionsGained = 0;
    var antidotesGained = 0;
    var statPointsGained = 0;
    var tomePicks = state.tomePicks;
    final tomeOffers = <OfferTicket>[];
    final carried = <String>[];
    final spellsLearned = <String>[];
    for (final itemId in itemsGained) {
      final item = items[itemId] as Map<String, dynamic>?;
      final tome = PlayerSessionNotifier.tomeGrantFor(itemId, item);
      if (tome != null) {
        statPointsGained += tome.statPoints;
        tomePicks = PlayerSessionNotifier._withTomePicks(
            tomePicks, itemId, tome.statPoints);
        tomeOffers.addAll(tome.offers);
        continue;
      }
      // A spellbook handed out as a reward is read like a bought one.
      final taughtSpellId = spellbookSpellIdFor(item);
      if (taughtSpellId != null) {
        if (!state.knownSpellIds.contains(taughtSpellId) &&
            !spellsLearned.contains(taughtSpellId)) {
          spellsLearned.add(taughtSpellId);
        }
        continue;
      }
      final charges = PlayerSessionNotifier.consumableChargesFor(itemId, item);
      if (charges == null) {
        carried.add(itemId);
        continue;
      }
      potionsGained += charges.potions;
      antidotesGained += charges.antidotes;
    }

    final clampedHp = hpAfter < 0
        ? 0
        : (hpAfter > leveled.maxHealth ? leveled.maxHealth : hpAfter);
    // A level-up refills health, except in a chain with no healing
    // between its fights (see EncounterModifiers.keepWounds).
    final newHealth =
        leveled.leveledUp && !keepWounds ? leveled.maxHealth : clampedHp;

    final newAllies = leveled.leveledUp
        ? _healAndGrowAlliesOnLevelUp(leveled.levelsGained)
        : state.recruitedAllies;

    // A multi-enemy pack win credits one kill-count increment per defeated
    // enemy *instance* (so two Harbor Rats in one pack credit
    // enemyKillCounts['harbor_rat'] by 2), matching how a `Kill`-type quest
    // objective already reads that map. [enemyIds] takes precedence when
    // non-empty; [enemyId] alone still works for every existing solo-fight
    // call site.
    final idsToCredit = enemyIds.isNotEmpty
        ? enemyIds
        : (enemyId == null || enemyId.isEmpty ? const <String>[] : [enemyId]);
    var newKillCounts = state.enemyKillCounts;
    for (final id in idsToCredit) {
      newKillCounts = {
        ...newKillCounts,
        id: (newKillCounts[id] ?? 0) + 1,
      };
    }

    state = state.copyWith(
      level: leveled.level,
      currentXP: leveled.xp,
      maxHealth: leveled.maxHealth,
      baseDamage: leveled.baseDamage,
      currentHealth: newHealth,
      statPoints: leveled.statPoints + statPointsGained,
      tomePicks: tomePicks,
      // Each level reached and a boss beaten bring an offer (see
      // offers.dart), a Tome of Mastery one too; a hunt (or, sometimes, an
      // Elite) a drop of Titan's Blood; a dice fight won or lost runs every
      // pact one fight on.
      pendingOffers: [
        ...state.pendingOffers,
        // Before the clans are met, levels and bosses bring none
        // (offersWaitForClans); the first banner comes when they are.
        if (!offersWaitForClans(state)) ...[
          ...PlayerSessionNotifier._levelOffers(leveled.levelsGained),
          for (var i = 0; i < bossOffers; i++)
            const OfferTicket(source: OfferSource.boss),
        ],
        ...tomeOffers,
      ],
      rerollCharges: _levelCharges(RollPower.reroll, leveled.levelsGained),
      banishCharges: _levelCharges(RollPower.banish, leveled.levelsGained),
      titanBlood: state.titanBlood + titanBlood,
      heldSigns: pactFight ? countDownPacts(state.heldSigns) : null,
      gold: state.gold + goldGain,
      inventoryItemIds: [...state.inventoryItemIds, ...carried],
      itemOrigins: withItemOrigins(state.itemOrigins, carried, origin),
      potionCount: state.potionCount + potionsGained,
      antidoteCount: state.antidoteCount + antidotesGained,
      xpEarnedThisRun: state.xpEarnedThisRun + xpGain,
      skillEssence: state.skillEssence + xpGain,
      recruitedAllies: newAllies,
      enemyKillCounts: newKillCounts,
      contracts: contractTally == null
          ? null
          : [
              for (final c in state.contracts)
                progressContract(c, contractTally),
            ],
      lootPityStreak: lootPityStreak,
      recentLootIds: recentLootIds,
      mana: manaAfter?.clamp(0, state.maxMana),
      knownSpellIds: spellsLearned.isEmpty
          ? null
          : [...state.knownSpellIds, ...spellsLearned],
    );
    // The patron's gifts at each level reached (patron_stats.dart).
    if (leveled.leveledUp) {
      state = _withPatronGains(state, leveled.levelsGained).withCursesEnded();
    }
    state = PlayerSessionNotifier._withFirstBanner(state);
    await _persist();
    return leveled.leveledUp;
  }

  /// Removes one carried copy of each id in [itemIds] -- a charm burned
  /// at the start of a fight (see FightScreen's setup screen). Ids not in
  /// the inventory are ignored.
  Future<void> consumeInventoryItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return;
    final remaining = [...state.inventoryItemIds];
    for (final id in itemIds) {
      remaining.remove(id);
    }
    state = state.copyWith(inventoryItemIds: remaining);
    await _persist();
  }

  /// Permadeath: clears the player's inventory and equipped items, and
  /// resets the skill build back to class basics — a roguelike run starts
  /// over each life. The signs go with it (held signs, Titan's Blood, the
  /// Choir or Pit of this life), and the offers waiting (back to the
  /// profession's starting ones); favour with the patrons stays, and so do
  /// perk ranks. The world starts over too: standing, marks, relations and
  /// their logs (see [PlayerSession.politics]), the titles and the Sworn
  /// boons. Keeps level, XP, gold, stats, dice (as items) and
  /// story flags/quests intact; only the *skill build itself* (unlocked
  /// skills, tier upgrades, skill essence, and unspent skill points) is
  /// wiped, back to exactly what [startNewGame] would grant: the race and
  /// profession's own standard skill, wired onto the starter die's
  /// Heritage/Profession Technique faces. [race]/[profession] are the raw
  /// records from the Races/Professions db, same as [startNewGame] takes.
  /// Returns a summary of the run for a death-screen recap.
  Future<PermadeathResult> applyPermadeath({
    required Map<String, dynamic> race,
    required Map<String, dynamic> profession,
  }) async {
    final result = PermadeathResult(
      lostItemIds: [...state.inventoryItemIds],
      xpEarnedThisRun: state.xpEarnedThisRun,
      skillsLost: state.unlockedSkillIds.length,
      signsLost: state.heldSigns.length,
    );

    final starterUnlockedSkills = starterSkillsFor(race, profession);
    final starterAssignments = starterFaceAssignments(race, profession);

    state = state.copyWith(
      currentHealth: state.maxHealth,
      inventoryItemIds: const [],
      // The pack's provenance goes with the pack.
      itemOrigins: const {},
      equippedItemIds: const [],
      // The party shares one pack: what the companions wore goes with it.
      recruitedAllies: [
        for (final ally in state.recruitedAllies)
          ally.copyWith(equippedItemIds: const []),
      ],
      xpEarnedThisRun: 0,
      unlockedSkillIds: starterUnlockedSkills,
      skillTiers: const {},
      masteredBranchId: '',
      skillEssence: 0,
      // The offers waiting go with the life, back to the profession's
      // starting ones; the titles and the Sworn boons with the world.
      pendingOffers: state.flags.contains(featureLadderFlag)
          ? const []
          : PlayerSessionNotifier.startingOffersFor(profession),
      clearClanOffer: true,
      heldTitleIds: const [],
      activeTitleId: '',
      swornBoonIds: const [],
      diceSkillAssignments: PlayerSessionNotifier._starterAssignmentsByDie(
          starterAssignments, startingDiceIdFor(profession)),
      knownSpellIds: startingSpellIdsFor(profession),
      mana: state.maxMana,
      heldSigns: const [],
      titanBlood: 0,
      signPatronsThisLife: const [],
      politics: PoliticsState.storyStart,
    );
    await _persist();
    return result;
  }
}
