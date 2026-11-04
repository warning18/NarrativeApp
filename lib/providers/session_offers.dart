// The session notifier's offers, risky gifts, stat picks, rerolls and bans, suitors, titles, the first banner and Titan's blood (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _OfferActions on _SessionNotifierBase {
  /// What a draw reads of the character now, with [tables].
  /// [placeHolder]: the clan that holds the place it is made in.
  OfferContext offerContextFor(OfferTables tables, {String placeHolder = ''}) {
    final s = state;
    return OfferContext(
      placeHolder: placeHolder,
      data: tables.data,
      politics: s.politics,
      signs: tables.signs,
      heldSigns: s.heldSigns,
      skills: tables.skills,
      skillTrees: tables.skillTrees,
      items: tables.items,
      spells: tables.spells,
      raceId: s.raceId,
      professionId: s.professionId,
      knownSkillIds: {
        ...s.unlockedSkillIds,
        for (final e in tables.skills.entries)
          if (e.value is Map && (e.value as Map)['isUnlocked'] == true) e.key,
      },
      ownedItemIds: s.inventoryItemIds,
      knownSpellIds: s.knownSpellIds,
      flags: s.flags,
      alignment: s.alignmentScore,
      patronsThisLife: s.signPatronsThisLife,
      favour: s.patronFavour,
      patronsMet: s.patronsMet,
      heldTitleIds: s.heldTitleIds,
      swornBoonIds: s.swornBoonIds,
      perkRanks: s.perkRanks,
      specs: tables.specs,
      heldSpecIds: s.specIds,
      specVariants: tables.specVariants,
      // A lucky sign (or title) helps draw the next gift.
      luck: _offerLuck(tables),
      riskyGifts: riskyGiftsOpen(s.builtHouseIds),
      // The gifts warded at the Warding Cairn (camp_rolls.dart).
      bannedGifts: bannedIdsOf(s.rollBans, RollBanOn.offer),
      dice: tables.dice,
      ownedDiceIds: s.ownedDiceIds,
    );
  }

  /// The character's Luck as the offers read it: their own, with what the
  /// signs, the title worn and the Sworn boon add.
  int _offerLuck(OfferTables tables) {
    final s = state;
    return s.luck +
        signEffectsFor(s.heldSigns, tables.signs,
            alignment: s.alignmentScore,
            extra: clanEffectsFor(
              activeTitleId: s.activeTitleId,
              heldTitleIds: s.heldTitleIds,
              swornBoonIds: s.swornBoonIds,
              swornFactionId: s.politics.swornFactionId,
              data: tables.data,
            )).stat('luck');
  }

  /// The Luck a risky card's roll reads now (see [_offerLuck]).
  int riskyLuck(OfferTables tables) => _offerLuck(tables);

  /// The odds a risky card shows now (risky_gifts.dart's riskyOddsFor, at
  /// the character's Luck).
  ({int gift, int price}) riskyOdds(OfferTables tables) =>
      riskyOddsFor(_offerLuck(tables));

  /// What taking [suitor]'s risky card would do now (its saved die, the
  /// Luck, the purse and the health of this moment); null for a normal
  /// card. [acceptSuitor] applies the same.
  RiskyResult? riskyResultOf(Suitor suitor, OfferTables tables) {
    if (!suitor.risky) return null;
    final s = state;
    return riskyResultFor(
      roll: suitor.riskRoll,
      luck: _offerLuck(tables),
      gold: s.gold,
      chapter: _politicsChapter(null),
      maxHealth: s.maxHealth,
      currentHealth: s.currentHealth,
      curseStat: riskyCurseStatFor(
          tables.data.faction(suitor.factionId), s.professionId),
    );
  }

  /// [count] more offers due from [source] (a boss beaten, a quest step,
  /// an intrigue, Edit Mode's "+1 offer"...): the hook for later scenes.
  /// [factionId] always takes a place in each, one rarity better for a
  /// quest or an intrigue; [detail] (the quest's id...) goes in the log's
  /// cause.
  Future<void> grantOffer(
    OfferSource source, {
    String factionId = '',
    String detail = '',
    int count = 1,
  }) async {
    if (count <= 0) return;
    state = state.copyWith(pendingOffers: [
      ...state.pendingOffers,
      for (var i = 0; i < count; i++)
        OfferTicket(source: source, detail: detail, factionId: factionId),
    ]);
    await _persist();
  }

  /// The offer a new [chapter] brings, once: from chapter 2 (the first
  /// chapter's end), and never twice for the same chapter (see
  /// [PlayerSession.chapterOffersThrough]). The Choir or the Pit come with
  /// it when the alignment leans. With the clans' [data], the chapter's
  /// price of loyalty comes with it too (applyLoyaltyDrift: the patron's
  /// rivals cool). With the world's [geography] too, the clans' power and
  /// places turn (territoryTurn, clan_power.dart). Returns whether one was
  /// granted.
  Future<bool> grantChapterOffer(int chapter,
      {ClanData? data, Geography? geography}) async {
    if (chapter < 2 || chapter <= state.chapterOffersThrough) return false;
    final drift = data == null
        ? null
        : applyLoyaltyDrift(state.politics,
            data: data, chapter: chapter, day: state.day);
    if (drift != null && drift.changed) {
      state = _withTitles(state.copyWith(politics: drift.state), data!);
    }
    if (data != null && geography != null) {
      // Your clan's seat waits for you (clan_crisis.dart); the fallen
      // clan you stayed of lets go once a banner of your own is raised.
      final turned = territoryTurn(
              settleFallenLoyalty(state.politics,
                  bannerRaised: bannerRaisedIn(state.flags)),
              data: data,
              geography: geography,
              chapter: chapter,
              day: state.day,
              protect: mainClanOf(state.politics))
          .state;
      state = state.copyWith(
          politics: updateNemesis(turned, data,
              chapter: chapter, day: state.day, flags: state.flags));
      // The rival clans' attacks on districts (district_attacks.dart):
      // the sieges run out settled, then the chapter's own rolled.
      _settleExpiredSieges(data, geography, chapter);
      state = state.copyWith(
          politics: rollDistrictAttacks(state.politics,
                  data: data,
                  geography: geography,
                  day: state.day,
                  chapter: chapter,
                  random: _siegeRandom(chapter))
              .state);
      _syncHeld(geography);
      // A new nemesis opens its quest (nemesis.dart): beat its champion;
      // the story's own once its champion can come.
      final rose = state.politics.nemesis;
      final quest = nemesisQuestIdOf(rose);
      if (rose.isNotEmpty &&
          (!state.politics.isStoryNemesis || chapter >= championMinChapter) &&
          !state.unlockedQuestIds.contains(quest) &&
          !state.completedQuestIds.contains(quest)) {
        state = state
            .copyWith(unlockedQuestIds: [...state.unlockedQuestIds, quest]);
      }
    }
    state = PlayerSessionNotifier._withFirstBanner(state.copyWith(
      chapterOffersThrough: chapter,
      // Before the clans are met, no offer piles up (offersWaitForClans).
      pendingOffers: offersWaitForClans(state)
          ? null
          : [
              ...state.pendingOffers,
              OfferTicket(source: OfferSource.chapter, detail: '$chapter'),
            ],
    ));
    await _persist();
    return true;
  }

  /// The ladder's [featureId] told of (its card seen or its screen opened).
  Future<void> acknowledgeFeature(String featureId) async {
    if (state.acknowledgedFeatures.contains(featureId)) return;
    state = state.copyWith(
        acknowledgedFeatures: [...state.acknowledgedFeatures, featureId]);
    await _persist();
  }

  /// The Journey opened on its map for the party's first step outside
  /// (first_journey.dart): once a game.
  Future<void> markJourneyFirstShown() async {
    if (state.flags.contains(journeyFirstShownFlag)) return;
    state = state.copyWith(flags: [...state.flags, journeyFirstShownFlag]);
    await _persist();
  }

  /// A fight won ([tutorial]: the lesson): the ladder's chest, then its
  /// place rules (feature_unlocks.dart).
  Future<void> noteFightWonOnLadder({required bool tutorial}) async {
    final add = ladderFlagsForWin(state.flags, tutorial: tutorial);
    if (add.isEmpty) return;
    state = state.copyWith(flags: [...state.flags, ...add]);
    await _persist();
  }

  /// The trainer's lesson (890_trainer): the skill of [trainerSkillFor]
  /// for a strike ([strike]) or a guard, learned; null when none is left.
  Future<String?> learnTrainerSkill({
    required bool strike,
    required Map<String, dynamic> trees,
    required Map<String, dynamic> skills,
  }) async {
    final id = trainerSkillFor(
        professionId: state.professionId,
        strike: strike,
        trees: trees,
        skills: skills,
        known: state.unlockedSkillIds);
    if (id == null) return null;
    state = state.copyWith(unlockedSkillIds: [...state.unlockedSkillIds, id]);
    await _persist();
    return id;
  }

  static Map<String, int> _trainingStatsOf(PlayerSession s) => {
        'strength': s.strength,
        'dexterity': s.dexterity,
        'constitution': s.constitution,
        'intelligence': s.intelligence,
        'wisdom': s.wisdom,
        'perception': s.perception,
        'luck': s.luck,
        'charisma': s.charisma,
      };

  /// The stat pick on the table (docs/proposals/stat-picks.md, see
  /// drawStatPick): the three offers of the next pending pick, drawn once
  /// from [paths] and kept until one is taken. The default [random] is
  /// seeded from the pick itself (the level, the points left, the paths
  /// taken), so a pick drawn anew never rerolls. Empty when no pick waits.
  Future<List<StatPickOffer>> ensureStatPick(Map<String, TrainingPath> paths,
      {Random? random}) async {
    final s = state;
    if (s.pendingStatPicks <= 0) {
      if (s.statPickOffer.isNotEmpty) {
        state = s.copyWith(statPickOffer: const []);
        await _persist();
      }
      return const [];
    }
    if (s.statPickOffer.isNotEmpty) return s.statPickOffer;
    final offer = drawStatPick(
      paths: paths,
      random: random ?? _statPickRandom(s),
      professionId: s.professionId,
      raceId: s.raceId,
      luck: s.luck,
      taken: s.trainingTaken,
      stats: _trainingStatsOf(s),
      bannedPaths: bannedIdsOf(s.rollBans, RollBanOn.pick),
    );
    if (offer.isEmpty) return offer;
    state = _countFreshDraw(s.copyWith(statPickOffer: offer), RollBanOn.pick);
    await _persist();
    return offer;
  }

  /// The stat pick's seed (see [ensureStatPick]): the level, the points
  /// left, the paths taken, and [PlayerSession.rollNonce], so a reroll, a
  /// ban or a raise draws anew.
  static Random _statPickRandom(PlayerSession s) {
    final takenTotal = s.trainingTaken.values.fold<int>(0, (a, b) => a + b);
    return Random(s.level * 7919 +
        s.statPoints * 131 +
        takenTotal +
        s.rollNonce * 104729);
  }

  // --- The camp's roll houses (camp_rolls.dart) ---------------------------

  /// [s] after a fresh draw of [on] (a stat pick or an offer drawn anew,
  /// never a reroll or a ban's replacement): its bans count down, and the
  /// Star Well's count moves on (see afterFreshDraw).
  static PlayerSession _countFreshDraw(PlayerSession s, RollBanOn on) {
    final raiseBuilt = rollPowersOf(s.builtHouseIds).contains(RollPower.raise);
    if (s.rollBans.isEmpty && !raiseBuilt) return s;
    final next = afterFreshDraw(
        on: on,
        bans: s.rollBans,
        raiseBuilt: raiseBuilt,
        raise: s.raiseCharges,
        raiseProgress: s.raiseProgress);
    return s.copyWith(
        rollBans: next.bans,
        raiseCharges: next.raise,
        raiseProgress: next.raiseProgress);
  }

  /// [power]'s charges after [levels] levels gained: +1 a level, never above
  /// its most, while its house stands (Reroll and Banish only).
  @override
  int _levelCharges(RollPower power, int levels) {
    final s = state;
    final now = power == RollPower.reroll ? s.rerollCharges : s.banishCharges;
    if (levels <= 0 || !rollPowersOf(s.builtHouseIds).contains(power)) {
      return now;
    }
    final most =
        power == RollPower.reroll ? rerollMaxCharges : banishMaxCharges;
    return min(most, now + levels);
  }

  /// What the roll houses give now, read from houses.json's `rollPower`
  /// ([houses]): each power's charges (null when its house isn't up) and
  /// the bans running.
  CampRolls campRolls(Map<String, dynamic> houses) =>
      campRollsOf(state, powers: rollPowersBuilt(state.builtHouseIds, houses));

  @override
  bool _has(RollPower power, int charges) =>
      charges > 0 && rollPowersOf(state.builtHouseIds).contains(power);

  /// The stat pick's tier as drawn: a raised card's is one step up.
  static SignRarity _drawnTier(List<StatPickOffer> offer) {
    final plain = offer.where((o) => !o.raised).firstOrNull;
    if (plain != null) return plain.tier;
    return SignRarity.values[max(0, offer.first.tier.index - 1)];
  }

  /// Reroll (the Bone-Caster's Hut): the stat pick on the table drawn
  /// again, at the same tier, the warded paths left out; one charge. The
  /// set unchanged when there is no charge or no pick on the table.
  Future<List<StatPickOffer>> rerollStatPick(Map<String, TrainingPath> paths,
      {Random? random}) async {
    final s = state;
    if (!_has(RollPower.reroll, s.rerollCharges) ||
        s.statPickOffer.isEmpty ||
        s.pendingStatPicks <= 0) {
      return s.statPickOffer;
    }
    final nonced = s.copyWith(rollNonce: s.rollNonce + 1);
    final offer = drawStatPick(
      paths: paths,
      random: random ?? _statPickRandom(nonced),
      professionId: s.professionId,
      raceId: s.raceId,
      luck: s.luck,
      taken: s.trainingTaken,
      stats: _trainingStatsOf(s),
      tier: _drawnTier(s.statPickOffer),
      bannedPaths: bannedIdsOf(s.rollBans, RollBanOn.pick),
    );
    if (offer.isEmpty) return s.statPickOffer;
    state = nonced.copyWith(
        statPickOffer: offer, rerollCharges: s.rerollCharges - 1);
    await _persist();
    return offer;
  }

  /// Banish (the Warding Cairn): the path of the stat pick's card at
  /// [index] warded off for [draws] fresh picks (5, 10 or 15, costing 1, 2
  /// or 3 charges), the card replaced at once by another path at the same
  /// tier. The set unchanged when the charges fall short, the length is
  /// not one of [banishLengths], or no path is left to replace it.
  Future<List<StatPickOffer>> banishStatPickOffer(
      int index, int draws, Map<String, TrainingPath> paths,
      {Random? random}) async {
    final s = state;
    final offer = s.statPickOffer;
    final cost = banishCostOf(draws);
    if (cost == 0 ||
        !_has(RollPower.banish, s.banishCharges) ||
        s.banishCharges < cost ||
        index < 0 ||
        index >= offer.length) {
      return offer;
    }
    final bans = withRollBan(s.rollBans,
        RollBan(on: RollBanOn.pick, id: offer[index].pathId, left: draws));
    final nonced = s.copyWith(rollNonce: s.rollNonce + 1);
    final card = replaceStatPickOffer(
        offer: offer,
        index: index,
        paths: paths,
        random: random ?? _statPickRandom(nonced),
        bannedPaths: bannedIdsOf(bans, RollBanOn.pick));
    if (card == null) return offer;
    final next = [...offer]..[index] = card;
    state = nonced.copyWith(
        statPickOffer: next,
        rollBans: bans,
        banishCharges: s.banishCharges - cost);
    await _persist();
    return next;
  }

  /// Banish (the Warding Cairn) on the road (road_wards.dart): [clanId], a
  /// clan hunting the character ([wardTargets] with [data]), kept off the
  /// roads at rest for [roads] of them (3, 6 or 9, costing 1, 2 or 3
  /// charges). Standing does not move. False, and nothing spent, when the
  /// cairn isn't up, the charges fall short, the length is not one of
  /// [wardLengths] or the clan isn't hunting. The line to show is
  /// [wardSetLine].
  Future<bool> wardRoad(String clanId, int roads, ClanData data) async {
    final s = state;
    final cost = wardCostOf(roads);
    if (cost == 0 ||
        !_has(RollPower.banish, s.banishCharges) ||
        s.banishCharges < cost ||
        !wardTargets(s.politics, data).contains(clanId)) {
      return false;
    }
    state = s.copyWith(
        rollBans: withWard(s.rollBans, clanId, roads),
        banishCharges: s.banishCharges - cost);
    await _persist();
    return true;
  }

  /// A road at rest gone by, where the hunters roll: the wards count down
  /// by one (road_wards.dart). A ward that runs out tells it in the coast's
  /// news (`ward_end:<clan>`, Narrative's `ward_ended`, [data] naming the
  /// clan, dated [chapter]). Returns the clans whose ward ended.
  Future<List<String>> tickRoadWards({ClanData? data, int chapter = 0}) async {
    final s = state;
    if (!s.rollBans.any((b) => b.on == RollBanOn.road)) return const [];
    final next = afterRoadAtRest(s.rollBans);
    var politics = s.politics;
    if (next.ended.isNotEmpty) {
      final news = [
        ...politics.news,
        for (final clanId in next.ended)
          CoastNews(
            eventId: 'ward_end:$clanId',
            chapter: chapter,
            day: s.day,
            text: wardLine('ward_ended', AppLanguage.en,
                clanId: clanId, data: data),
            textFr: wardLine('ward_ended', AppLanguage.fr,
                clanId: clanId, data: data),
          ),
      ];
      politics = politics.copyWith(
          news: news.length <= maxCoastNews
              ? news
              : news.sublist(news.length - maxCoastNews));
    }
    state = s.copyWith(rollBans: next.bans, politics: politics);
    await _persist();
    return next.ended;
  }

  /// Whether the stat pick's card at [index] can be raised now: a Raise
  /// charge, the card neither raised yet nor Heroic.
  bool canRaiseStatPickOffer(int index) {
    final s = state;
    if (!_has(RollPower.raise, s.raiseCharges)) return false;
    if (index < 0 || index >= s.statPickOffer.length) return false;
    final card = s.statPickOffer[index];
    return !card.raised && card.tier != SignRarity.heroic;
  }

  /// Raise (the Star Well): the stat pick's card at [index] one tier up,
  /// its gains rebuilt (see raisedStatPickOffer); one charge. The set
  /// unchanged when it can't be ([canRaiseStatPickOffer]).
  Future<List<StatPickOffer>> raiseStatPickOffer(
      int index, Map<String, TrainingPath> paths,
      {Random? random}) async {
    final s = state;
    if (!canRaiseStatPickOffer(index)) return s.statPickOffer;
    final nonced = s.copyWith(rollNonce: s.rollNonce + 1);
    final card = raisedStatPickOffer(
        s.statPickOffer[index], paths, random ?? _statPickRandom(nonced));
    if (card == null) return s.statPickOffer;
    final next = [...s.statPickOffer]..[index] = card;
    state =
        nonced.copyWith(statPickOffer: next, raiseCharges: s.raiseCharges - 1);
    await _persist();
    return next;
  }

  /// Reroll (the Bone-Caster's Hut): the offer on the table drawn again for
  /// its ticket (its faction and the home seat still come; a risky card
  /// drawn anew, with a new die), the warded gifts left out; one charge.
  /// The offer unchanged when there is no charge or none on the table.
  Future<ClanOffer?> rerollOffer(OfferTables tables,
      {Random? random, String placeHolder = ''}) async {
    final s = state;
    final offer = s.clanOffer;
    if (offer == null || !_has(RollPower.reroll, s.rerollCharges)) {
      return offer;
    }
    final next = drawOffer(offer.ticket,
        offerContextFor(tables, placeHolder: placeHolder), random ?? Random());
    if (next == null) return offer;
    state = s.copyWith(
      clanOffer: next,
      rerollCharges: s.rerollCharges - 1,
      rollNonce: s.rollNonce + 1,
      patronsMet:
          {...s.patronsMet, for (final x in next.suitors) x.factionId}.toList(),
    );
    await _persist();
    return next;
  }

  /// Banish (the Warding Cairn): [factionId]'s gift on the offer warded off
  /// for [draws] fresh offers (5, 10 or 15, costing 1, 2 or 3 charges), its
  /// card replaced at once: the same clan with something else, else
  /// another faction (see replacementSuitor). Never the Sworn boon nor the
  /// ticket's own faction's card (suitorBanishable). The offer unchanged
  /// when it can't be.
  Future<ClanOffer?> banishSuitor(
      String factionId, int draws, OfferTables tables,
      {Random? random, String placeHolder = ''}) async {
    final s = state;
    final offer = s.clanOffer;
    final suitor = offer?.suitorOf(factionId);
    final cost = banishCostOf(draws);
    if (offer == null ||
        suitor == null ||
        cost == 0 ||
        !_has(RollPower.banish, s.banishCharges) ||
        s.banishCharges < cost ||
        !suitorBanishable(suitor, offer)) {
      return offer;
    }
    final bans = withRollBan(s.rollBans,
        RollBan(on: RollBanOn.offer, id: giftBanId(suitor.gift), left: draws));
    final c = offerContextFor(tables, placeHolder: placeHolder)
        .withBans(bannedIdsOf(bans, RollBanOn.offer));
    final card = replacementSuitor(offer, factionId, c, random ?? Random());
    if (card == null) return offer;
    final next = offerWith(offer, factionId, card);
    state = s.copyWith(
      clanOffer: next,
      rollBans: bans,
      banishCharges: s.banishCharges - cost,
      rollNonce: s.rollNonce + 1,
      patronsMet: {...s.patronsMet, card.factionId}.toList(),
    );
    await _persist();
    return next;
  }

  /// The seed of [factionId]'s raise, the same until a power is used: the
  /// preview and the raise draw the same card.
  Random _raiseRandom(String factionId) => Random(
      state.rollNonce * 104729 + stableSeedOf('${state.level}:$factionId'));

  /// What raising [factionId]'s card would give (raisedSuitor), drawn now
  /// and the same when it is raised; null when there is no Raise charge or
  /// no real step up (the button hides).
  Suitor? raisePreview(String factionId, OfferTables tables) {
    final s = state;
    final suitor = s.clanOffer?.suitorOf(factionId);
    if (suitor == null || !_has(RollPower.raise, s.raiseCharges)) return null;
    return raisedSuitor(
        suitor, offerContextFor(tables), _raiseRandom(factionId));
  }

  /// Raise (the Star Well): [factionId]'s card raised to its
  /// [raisePreview]; one charge. The offer unchanged when there is none.
  Future<ClanOffer?> raiseSuitor(String factionId, OfferTables tables) async {
    final s = state;
    final offer = s.clanOffer;
    final raised = raisePreview(factionId, tables);
    if (offer == null || raised == null) return offer;
    final next = offerWith(offer, factionId, raised);
    state = s.copyWith(
        clanOffer: next,
        raiseCharges: s.raiseCharges - 1,
        rollNonce: s.rollNonce + 1);
    await _persist();
    return next;
  }

  /// Takes the offer at [index] of the stat pick on the table: its gains
  /// (max health heals as much), one pick spent (a rare offer too), its path
  /// counted. The next pick is drawn by [ensureStatPick]; false when there
  /// is none, no such offer, or no pick waits.
  Future<bool> takeStatPick(int index) async {
    final s = state;
    final offer = s.statPickOffer;
    if (index < 0 || index >= offer.length) return false;
    if (s.pendingStatPicks <= 0) return false;
    final pick = offer[index];
    // A tome's pick waiting is the one taken (see [PlayerSession.tomePicks]).
    final tomeId = s.tomePicks.firstOrNull;
    final sourced = tomeId != null
        ? s.withSourcedGains(ledgerTome, tomeId, pick.gains)
        : s.withSourcedGains(ledgerPick, pick.pathId, pick.gains);
    state = sourced.copyWith(
      statPoints: s.statPoints - 1,
      statPickOffer: const [],
      tomePicks: tomeId == null ? null : s.tomePicks.sublist(1),
      trainingTaken: {
        ...s.trainingTaken,
        pick.pathId: (s.trainingTaken[pick.pathId] ?? 0) + 1,
      },
    );
    await _persist();
    return true;
  }

  /// The offer on the table for the first offer due (see drawOffer),
  /// drawn once from [tables] and kept until a suitor is taken. Null when
  /// none is due, or nobody can come (the offer waits). The suitors'
  /// factions count as met, for their intro and the codex.
  Future<ClanOffer?> ensureOffer(OfferTables tables,
      {Random? random, String placeHolder = ''}) async {
    if (state.pendingOffers.isEmpty) return null;
    // On the feature ladder the clans come at Saltmouth: the offers wait.
    if (!state.featureOpen(GameFeature.clans)) return null;
    final waiting = state.clanOffer;
    if (waiting != null) return waiting;
    final offer = drawOffer(state.pendingOffers.first,
        offerContextFor(tables, placeHolder: placeHolder), random ?? Random());
    if (offer == null) return null;
    state = _countFreshDraw(
        state.copyWith(
          clanOffer: offer,
          patronsMet: {
            ...state.patronsMet,
            for (final s in offer.suitors) s.factionId,
          }.toList(),
        ),
        RollBanOn.offer);
    await _persist();
    return offer;
  }

  /// Takes [factionId]'s gift from the offer on the table:
  /// - **the gift:** a skill learned; a sign drawn on (see takeSign: it
  ///   replaces the one in its slot; the patron's favour, a vow's or a
  ///   pact's ±3); an object to the pack (a potion as charges, a
  ///   spellbook read, a tome read); a title held (and worn, when none
  ///   is); the Sworn boon; a perk rank (Vigor's health at once);
  /// - **the politics:** +6 standing with them (+10 for a quest, an
  ///   intrigue or a chapter's end) with the ripple, the voicing sub-clan
  ///   a friend, all logged; the alignment nudged by their lean;
  /// - the titles standing earns (see titlesEarned).
  /// The offer is spent; false when there is none or no such suitor.
  Future<bool> acceptSuitor(String factionId,
      {required OfferTables tables, ItemOrigin? origin}) async {
    final offer = state.clanOffer;
    final suitor = offer?.suitorOf(factionId);
    if (offer == null || suitor == null || state.pendingOffers.isEmpty) {
      return false;
    }
    // A risky card: the die (rolled with the draw) gives the gift or names
    // the price; standing rises either way.
    final risk = riskyResultOf(suitor, tables);
    var next = switch (risk?.outcome) {
      null ||
      RiskyOutcome.gift =>
        _withGift(state, suitor, tables, origin: origin),
      RiskyOutcome.health => state.copyWith(
          currentHealth: max(1, state.currentHealth - risk!.amount)),
      RiskyOutcome.gold =>
        state.copyWith(gold: max(0, state.gold - risk!.amount)),
      RiskyOutcome.curse =>
        state.withCurse(suitor.factionId, risk!.stat, risk.amount),
    };
    final politics = acceptPolitics(suitor, offer.ticket,
        politics: next.politics,
        data: tables.data,
        chapter: _politicsChapter(null),
        day: next.day,
        flags: next.flags);
    next = next.copyWith(
      politics: politics.politics,
      alignmentScore: next.alignmentScore + politics.alignment,
      pendingOffers: next.pendingOffers.sublist(1),
      clearClanOffer: true,
    );
    state = _withTitles(next, tables.data);
    await _persist();
    return true;
  }

  /// [session] with [suitor]'s gift applied (see [acceptSuitor]).
  PlayerSession _withGift(
      PlayerSession session, Suitor suitor, OfferTables tables,
      {ItemOrigin? origin}) {
    final gift = suitor.gift;
    switch (gift.kind) {
      case GiftKind.skill:
        if (session.unlockedSkillIds.contains(gift.id)) return session;
        return session
            .copyWith(unlockedSkillIds: [...session.unlockedSkillIds, gift.id]);
      case GiftKind.sign:
        final sign = tables.signs[gift.id];
        if (sign == null) return session;
        final taken =
            takeSign(session.heldSigns, sign, gift.rarity, tables.signs);
        return session.copyWith(
          heldSigns: taken.held,
          patronFavour: {
            ...session.patronFavour,
            suitor.factionId: (session.patronFavour[suitor.factionId] ?? 0) + 1,
          },
          signPatronsThisLife: {
            ...session.signPatronsThisLife,
            suitor.factionId,
            sign.patronId,
          }.toList(),
          alignmentScore: session.alignmentScore + alignmentShiftFor(sign),
        );
      case GiftKind.object:
        return _withItem(
            session, gift.id, tables.items[gift.id] as Map<String, dynamic>?,
            origin: origin);
      case GiftKind.title:
        if (session.heldTitleIds.contains(gift.id)) return session;
        return session.copyWith(
          heldTitleIds: [...session.heldTitleIds, gift.id],
          activeTitleId:
              session.activeTitleId.isEmpty ? gift.id : session.activeTitleId,
        );
      case GiftKind.sworn:
        if (session.swornBoonIds.contains(gift.id)) return session;
        return session
            .copyWith(swornBoonIds: [...session.swornBoonIds, gift.id]);
      case GiftKind.perk:
        final perk = perkFromName(gift.id);
        if (perk == null ||
            (session.perkRanks[gift.id] ?? 0) >= perkInfo[perk]!.maxRank) {
          return session;
        }
        final health = perk == Perk.vigor ? vigorHealthPerRank : 0;
        return session.copyWith(
          perkRanks: {
            ...session.perkRanks,
            gift.id: (session.perkRanks[gift.id] ?? 0) + 1,
          },
          maxHealth: session.maxHealth + health,
          currentHealth: session.currentHealth + health,
        );
      case GiftKind.spec:
        if (session.specIds.contains(gift.id)) return session;
        return session.copyWith(specIds: [...session.specIds, gift.id]);
      case GiftKind.die:
        // A clan's die (clan_dice.dart), to the bag: equipped like any.
        if (session.ownedDiceIds.contains(gift.id)) return session;
        return session
            .copyWith(ownedDiceIds: [...session.ownedDiceIds, gift.id]);
    }
  }

  /// [session] given [itemId] the way a reward is: a potion as charges, a
  /// spellbook read, a tome read on the spot (a Tome of Mastery is one more
  /// offer), anything else to the pack, with [origin] remembered for a
  /// piece new to it (see [PlayerSession.itemOrigins]).
  PlayerSession _withItem(
      PlayerSession session, String itemId, Map<String, dynamic>? item,
      {ItemOrigin? origin}) {
    final charges = PlayerSessionNotifier.consumableChargesFor(itemId, item);
    if (charges != null) {
      return session.copyWith(
        potionCount: session.potionCount + charges.potions,
        antidoteCount: session.antidoteCount + charges.antidotes,
      );
    }
    final spellId = spellbookSpellIdFor(item);
    if (spellId != null) {
      return session.knownSpellIds.contains(spellId)
          ? session
          : session
              .copyWith(knownSpellIds: [...session.knownSpellIds, spellId]);
    }
    final tome = PlayerSessionNotifier.tomeGrantFor(itemId, item);
    if (tome != null) {
      return session.copyWith(
        statPoints: session.statPoints + tome.statPoints,
        tomePicks: PlayerSessionNotifier._withTomePicks(
            session.tomePicks, itemId, tome.statPoints),
        pendingOffers: [...session.pendingOffers, ...tome.offers],
      );
    }
    return session.copyWith(
      inventoryItemIds: [...session.inventoryItemIds, itemId],
      itemOrigins: withItemOrigins(session.itemOrigins, [itemId], origin),
    );
  }

  /// [session] with the titles its politics earn or take away (see
  /// titlesEarned), and the one worn kept, or the first good one gained.
  @override
  PlayerSession _withTitles(PlayerSession session, ClanData data) {
    final titles = titlesEarned(session.heldTitleIds, session.politics, data,
        flags: session.flags);
    final active = activeTitleAfter(
        session.activeTitleId, titles.held, titles.gained, data);
    if (titles.gained.isEmpty &&
        titles.lost.isEmpty &&
        active == session.activeTitleId) {
      return session;
    }
    return session.copyWith(heldTitleIds: titles.held, activeTitleId: active);
  }

  /// Wears [titleId] (one held), or none with ''.
  Future<void> setActiveTitle(String titleId) async {
    if (titleId.isNotEmpty && !state.heldTitleIds.contains(titleId)) return;
    if (titleId == state.activeTitleId) return;
    state = state.copyWith(activeTitleId: titleId);
    await _persist();
  }

  /// Spends a drop of Titan's Blood raising held sign [signId] one level.
  /// False when there is no blood, no such sign, or it is at its highest.
  Future<bool> spendTitanBlood(String signId) async {
    if (state.titanBlood <= 0) return false;
    final raised = raiseSign(state.heldSigns, signId);
    if (raised == null) return false;
    state = state.copyWith(heldSigns: raised, titanBlood: state.titanBlood - 1);
    await _persist();
    return true;
  }

  /// [count] more drops of Titan's Blood (a hunt, an Elite, Edit Mode).
  Future<void> grantTitanBlood(int count) async {
    if (count <= 0) return;
    state = state.copyWith(titanBlood: state.titanBlood + count);
    await _persist();
  }

  // --- Clans: standing, marks and relations (v1.193, see factions.dart) ---
}
