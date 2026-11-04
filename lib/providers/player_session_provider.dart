import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show mapEquals, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, ProviderListenableSelect;
import 'package:shared_preferences/shared_preferences.dart';

import '../combat/combat_engine.dart' show maxSkillTier, skillTierUpgradeCost;
import '../combat/face_keywords.dart' show FaceKeyword;
import '../combat/face_smithing.dart';
import '../combat/sea_beasts.dart' show BeastState;
import '../combat/spells.dart' show maxManaFor, spellbookSpellIdFor;
import '../combat/stat_rules.dart';
import '../data/cliff_town.dart' show townAdditionLimitOf;
import '../data/alignment_events.dart' show hunterCooldownRolls;
import '../data/approval.dart';
import '../data/story_companions.dart';
import '../data/story_prices.dart';
import '../data/character_start.dart';
import '../data/clan_crisis.dart' show mainClanOf, settleFallenLoyalty;
import '../data/clan_power.dart' show territoryTurn;
import '../data/city_districts.dart' show questAcceptedFlag;
import '../data/district_attacks.dart'
    show expiredSieges, rollDistrictAttacks, settleSiegeAway, syncSiegeFlags;
import '../data/nemesis.dart'
    show championMinChapter, nemesisQuestIdOf, updateNemesis;
import '../data/contracts.dart';
import '../data/district_influence.dart' as influence
    show InfluenceResult, applyQuestInfluence, syncHeldFlags;
import '../data/detour_pacing.dart' show DetourPacing;
import '../data/camp_state.dart' show harborHouseId;
import '../data/factions.dart';
import '../data/forge_roll.dart';
import '../data/feature_unlocks.dart';
import '../data/first_journey.dart' show journeyFirstShownFlag;
import '../data/hunter_mercy.dart';
import '../data/patron_stats.dart';
import '../data/factions.dart' as clan_rules show setSubclanMark, shiftRelation;
import '../data/geography.dart' show Geography;
import '../data/harbour.dart';
import '../data/heard_of.dart' show withMapGoal;
import '../data/journey_rules.dart';
import '../data/materials.dart';
import '../data/offers.dart';
import '../data/perks.dart';
import '../data/politics_events.dart';
import '../data/politics_events.dart' as coast show applyStoryPolitics;
import '../data/quest_objectives.dart' show killTargetsOf;
import '../data/camp_rolls.dart';
import '../data/road_wards.dart';
import '../data/risky_gifts.dart';
import '../data/signs.dart';
import '../data/skill_craft.dart' show skillCraftOpen;
import '../data/skill_tree.dart' show branchMasteryEssenceCost;
import '../data/stat_ledger.dart';
import '../data/dice_sizes_save.dart';
import '../data/dice_weave.dart' show canWeaveDice, tallyDieId;
import '../data/fate_coin.dart' show reforgedRoll, withFateCoinSpent;
import '../data/stat_scale_save.dart';
import '../data/temple.dart';
import '../data/training.dart';
import '../data/throne.dart'
    show
        claimFlag,
        clanQuestSteps,
        clanStepFlag,
        isMusterFlag,
        onThroneFlag,
        pledgedFlag,
        throneWinnerFlag;
import '../l10n/app_locale.dart';
import '../models/ally_state.dart';
import '../models/item_origin.dart';
import '../models/story_node.dart' show placeFoundFlag;
import '../models/story_politics.dart';
import '../data/story_markup.dart' show stripStoryMarkup;

part 'player_session_model.dart';
part 'session_offers.dart';
part 'session_politics.dart';
part 'session_quests.dart';
part 'session_shop_forge.dart';
part 'session_allies_camp.dart';
part 'session_road_time.dart';
part 'session_skills_combat.dart';

/// What the notifier's features share (4f, docs/proposals/4f-notifier-mixins.md):
/// the state, and the members one feature calls in another, declared here
/// and implemented in [PlayerSessionNotifier] or its feature mixins.
abstract class _SessionNotifierBase extends StateNotifier<PlayerSession> {
  _SessionNotifierBase(super.state);

  Future<void> _persist();
  String? _removeAlly(
    String companionId, {
    required bool lost,
    required Map<String, dynamic> companions,
  });
  int _levelCharges(RollPower power, int levels);
  bool _has(RollPower power, int charges);
  PlayerSession _withTitles(PlayerSession session, ClanData data);
  int _politicsChapter(int? chapter);
  Future<StandingResult> changeStanding(
    String factionId,
    num delta, {
    required ClanData data,
    required String cause,
    int? chapter,
  });
  void _syncHeld(Geography? geography);
  Random _siegeRandom(int chapter);
  int _settleExpiredSieges(ClanData data, Geography geography, int chapter);
  Future<void> healPartyToFull();
  Future<List<String>> checkAchievements({int totalCompanionCount = 0});
  Future<void> unlockContent({
    String? shopId,
    String? questId,
    String? enemyId,
    String? shopUnlockNodeId,
  });
  ({
    int level,
    int xp,
    int maxHealth,
    int baseDamage,
    int statPoints,
    bool leveledUp,
    int levelsGained,
  }) _applyXp(int xpGain);
  PlayerSession _withPatronGains(PlayerSession session, int levels);
  List<AllyState> _healAndGrowAlliesOnLevelUp(int levelsGained);
}

class PlayerSessionNotifier extends _SessionNotifierBase
    with
        _OfferActions,
        _PoliticsActions,
        _QuestActions,
        _ShopForgeActions,
        _AlliesCampActions,
        _RoadTimeActions,
        _SkillsCombatActions {
  PlayerSessionNotifier()
      : super(const PlayerSession(
          level: 1,
          currentXP: 0,
          gold: 0,
          alignmentScore: 0,
          maxHealth: 20,
          currentHealth: 20,
          baseDamage: 2,
          baseArmor: 0,
          luck: 0,
          charisma: 0,
          strength: 0,
          dexterity: 0,
          constitution: 0,
          intelligence: 0,
          wisdom: 0,
          perception: 0,
          potionCount: 0,
          statPoints: 0,
          maxSkillSlots: 3,
          flags: [],
          activeQuestIds: [],
          completedQuestIds: [],
          inventoryItemIds: [],
          equippedItemIds: [],
          unlockedSkillIds: [],
          unlockedShopIds: [],
          unlockedQuestIds: [],
          unlockedEnemyIds: [],
          diceSkillAssignments: {},
          raceId: '',
          professionId: '',
          ownedDiceIds: [],
          equippedDiceId: null,
        )) {
    _load();
  }

  /// Every state the notifier takes keeps its companion flags in step with
  /// the roster (wave 17: `ally_<id>` while recruited, `devoted_<id>` once
  /// Devoted), whichever path moved approval or the roster.
  @override
  set state(PlayerSession value) =>
      super.state = value.withCompanionFlagsSynced();

  @override
  PlayerSession get state => super.state;

  /// Completes once the saved session has been read (or found missing or
  /// unreadable). Nothing is written before then, so a change made in the
  /// first moments after launch can never write the placeholder session
  /// over the real save.
  final Completer<void> _loaded = Completer<void>();

  /// Whether the saved session has been read (see [_loaded]): until then
  /// the state is a placeholder nothing should act on.
  bool get isLoaded => _loaded.isCompleted;

  /// Whether the save on disk could not be read this launch; it was kept
  /// under [unreadableSessionBackupPrefsKey] and a fresh session started.
  bool loadFailed = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_playerSessionPrefsKey);
    if (saved != null) {
      try {
        state =
            PlayerSession.fromJson(json.decode(saved) as Map<String, dynamic>);
        _loaded.complete();
        return;
      } catch (_) {
        // Keep the unreadable save aside before anything can replace it.
        await prefs.setString(unreadableSessionBackupPrefsKey, saved);
        loadFailed = true;
      }
    }
    _loaded.complete();
    await _resetToDefaults(prefs);
  }

  /// The new-game defaults: the Data editor's game config when it has one
  /// that can be read, the shipped one otherwise (issue #693: a broken
  /// override must not stop a session or a character from being made).
  static Future<Map<String, dynamic>> _newGameDefaults(
      SharedPreferences prefs) async {
    final saved = prefs.getString(_newGameDefaultsPrefsKey);
    if (saved != null) {
      try {
        return json.decode(saved) as Map<String, dynamic>;
      } catch (_) {}
    }
    return json.decode(await rootBundle.loadString(_newGameDefaultsAssetPath))
        as Map<String, dynamic>;
  }

  /// [keepLegacy] carries the New Game+ cycle and its banked legacy (see
  /// [PlayerSession.legacyGold]) through the reset -- the reset that
  /// precedes character creation must not lose what the previous cycle
  /// handed down; an Edit-Mode "start from nothing" reset passes false.
  Future<void> _resetToDefaults(SharedPreferences prefs,
      {bool keepLegacy = true}) async {
    final previous = state;
    final defaults = await _newGameDefaults(prefs);
    final maxHealth = (defaults['maxHealth'] as num?)?.toInt() ?? 20;
    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      // The story's nemesis from the first page (nemesis.dart).
      politics: PoliticsState.storyStart,
      currentXP: 0,
      gold: (defaults['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: 0,
      maxHealth: maxHealth,
      currentHealth: maxHealth,
      baseDamage: (defaults['baseDamage'] as num?)?.toInt() ?? 2,
      baseArmor: (defaults['baseArmor'] as num?)?.toInt() ?? 0,
      luck: (defaults['luck'] as num?)?.toInt() ?? 0,
      charisma: (defaults['charisma'] as num?)?.toInt() ?? 0,
      strength: (defaults['strength'] as num?)?.toInt() ?? 0,
      dexterity: (defaults['dexterity'] as num?)?.toInt() ?? 0,
      constitution: (defaults['constitution'] as num?)?.toInt() ?? 0,
      intelligence: (defaults['intelligence'] as num?)?.toInt() ?? 0,
      wisdom: (defaults['wisdom'] as num?)?.toInt() ?? 0,
      perception: (defaults['perception'] as num?)?.toInt() ?? 0,
      potionCount: (defaults['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: 0,
      maxSkillSlots: (defaults['maxSkillSlots'] as num?)?.toInt() ?? 3,
      // A new game climbs the feature ladder (feature_unlocks.dart).
      flags: const [featureLadderFlag],
      activeQuestIds: const [],
      completedQuestIds: const [],
      inventoryItemIds: const [],
      equippedItemIds: const [],
      unlockedSkillIds: const [],
      unlockedShopIds: const [],
      unlockedQuestIds: const [],
      unlockedEnemyIds: const [],
      diceSkillAssignments: const {},
      raceId: '',
      professionId: '',
      ownedDiceIds: const [],
      equippedDiceId: null,
      antidoteCount: (defaults['antidoteCount'] as num?)?.toInt() ?? 0,
      mana: maxManaFor(
        wisdom: (defaults['wisdom'] as num?)?.toInt() ?? 0,
      ),
      newGamePlusCycle: keepLegacy ? previous.newGamePlusCycle : 0,
      legacyGold: keepLegacy ? previous.legacyGold : 0,
      legacyDiceIds: keepLegacy ? previous.legacyDiceIds : const [],
      legacySpellIds: keepLegacy ? previous.legacySpellIds : const [],
      // Favour with the patrons outlasts the character, like a legacy.
      patronFavour: keepLegacy ? previous.patronFavour : const {},
      patronsMet: keepLegacy ? previous.patronsMet : const [],
      diceUpgrades: keepLegacy
          ? {
              for (final id in previous.legacyDiceIds)
                if (previous.upgradesOfDie(id) != null)
                  id: previous.upgradesOfDie(id)!,
            }
          : const {},
    );
    await _persist();
  }

  /// Starts a fresh game as the given race/profession, combining the base
  /// New Game Defaults with each preset's stat bonuses. [race] and
  /// [profession] are the raw records from the Races/Professions db.
  Future<void> startNewGame({
    required String raceId,
    required Map<String, dynamic> race,
    required String professionId,
    required Map<String, dynamic> profession,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = await _newGameDefaults(prefs);

    // The same numbers the simulator starts from (character_start.dart).
    final totals = newCharacterTotals(defaults, race, profession);
    // A profession's starting skill points are offers since v1.194.

    // Race/profession signature skills (and a caster's mana skill) default
    // to isUnlocked: false in the skills db (most skills are locked until
    // earned) but are wired directly into the starting die's faces from
    // the moment a character exists -- so they are unlocked here too, or
    // those faces would just fizzle on the very first roll.
    final starterAssignments = starterFaceAssignments(race, profession);
    final starterUnlockedSkills = starterSkillsFor(race, profession);
    final startingDiceId = startingDiceIdFor(profession);
    final startingSpellIds = startingSpellIdsFor(profession);
    // A New Game+ character inherits the previous cycle's legacy (see
    // [beginNewGamePlus]): its gold share, every die it owned and every
    // spell it knew.
    final legacy = state;
    final legacyDice = [
      for (final id in legacy.legacyDiceIds)
        if (id != starterDiceId && id != startingDiceId) id,
    ];
    // One die to start with: the profession's own (a Mage's or Cleric's
    // apprentice die replaces the starter die), plus a New Game+ legacy.
    final legacySpells = [
      for (final id in legacy.legacySpellIds)
        if (!startingSpellIds.contains(id)) id,
    ];

    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      currentXP: 0,
      politics: PoliticsState.storyStart,
      gold: totals.gold + legacy.legacyGold,
      alignmentScore: 0,
      maxHealth: totals.maxHealth,
      currentHealth: totals.maxHealth,
      baseDamage: totals.baseDamage,
      baseArmor: totals.baseArmor,
      luck: totals.luck,
      charisma: totals.charisma,
      strength: totals.strength,
      dexterity: totals.dexterity,
      constitution: totals.constitution,
      intelligence: totals.intelligence,
      wisdom: totals.wisdom,
      perception: totals.perception,
      potionCount: (defaults['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: 0,
      // The starting skill comes from the trainer (feature_unlocks.dart),
      // the clans' offers from Saltmouth.
      pendingOffers: const [],
      maxSkillSlots: (defaults['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: const [featureLadderFlag],
      activeQuestIds: const [],
      completedQuestIds: const [],
      inventoryItemIds: const [],
      equippedItemIds: const [],
      unlockedSkillIds: starterUnlockedSkills,
      unlockedShopIds: const [],
      unlockedQuestIds: const [],
      unlockedEnemyIds: const [],
      diceSkillAssignments:
          _starterAssignmentsByDie(starterAssignments, startingDiceId),
      raceId: raceId,
      professionId: professionId,
      ownedDiceIds: [startingDiceId, ...legacyDice],
      equippedDiceId: startingDiceId,
      antidoteCount: (defaults['antidoteCount'] as num?)?.toInt() ?? 0,
      mana: maxManaFor(wisdom: totals.wisdom),
      knownSpellIds: [...startingSpellIds, ...legacySpells],
      newGamePlusCycle: legacy.newGamePlusCycle,
      // A new character starts with no signs, but the patrons remember.
      patronFavour: legacy.patronFavour,
      patronsMet: legacy.patronsMet,
      runSeed: 1 + Random().nextInt(0x7ffffffe),
      // A New Game+ legacy die keeps the Hammersmith's work on it: the
      // player's own, not a companion's on their copy of the same die.
      diceUpgrades: {
        for (final id in legacyDice)
          if (legacy.upgradesOfDie(id) != null) id: legacy.upgradesOfDie(id)!,
      },
    );
    await _persist();
  }

  /// The share of a finished run's gold the next cycle starts with.
  static const double newGamePlusGoldShare = 0.25;

  /// Banks the finished run as the legacy of the next cycle and counts the
  /// cycle up: a quarter of the gold, every owned die and every known
  /// spell wait in [PlayerSession.legacyGold] and friends for the reset at
  /// character creation (which keeps them, see [_resetToDefaults]) and the
  /// [startNewGame] that follows (which spends them). Everything else --
  /// level, gear, companions, camp, quests, flags -- starts over, and every
  /// enemy of the new cycle is `newGamePlusMultiplier` tougher.
  Future<void> beginNewGamePlus() async {
    state = state.copyWith(
      newGamePlusCycle: state.newGamePlusCycle + 1,
      legacyGold: (state.gold * newGamePlusGoldShare).round(),
      legacyDiceIds: {...state.legacyDiceIds, ...state.ownedDiceIds}.toList(),
      legacySpellIds:
          {...state.legacySpellIds, ...state.knownSpellIds}.toList(),
    );
    await _persist();
  }

  /// [starterAssignments] under the profession's starting die, the one
  /// die a new character owns.
  static Map<String, Map<String, String>> _starterAssignmentsByDie(
    Map<String, String> starterAssignments,
    String startingDiceId,
  ) =>
      {
        if (starterAssignments.isNotEmpty) startingDiceId: starterAssignments,
      };

  /// Sets the character's name — called once from the lock-in dialog right
  /// after character creation (see RaceProfessionScreen), before the
  /// origin-story prompts run.
  Future<void> setCharacterName(String name) async {
    state = state.copyWith(characterName: name.trim());
    await _persist();
  }

  /// The write the next [_persist] calls join, until it encodes.
  Future<void>? _pendingWrite;

  /// How many times the session was written (tests count them).
  @visibleForTesting
  int sessionWrites = 0;

  /// Saves the session. Calls made before the write encodes share it
  /// (v1.713): a burst of changes is written once, and every caller still
  /// awaits a write that holds its change.
  @override
  Future<void> _persist() => _pendingWrite ??= _write();

  Future<void> _write() async {
    await _loaded.future;
    _pendingWrite = null;
    final encoded = json.encode(state.toJson());
    sessionWrites++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerSessionPrefsKey, encoded);
  }

  /// See [_resetToDefaults]: a plain reset keeps a pending New Game+
  /// legacy; [keepLegacy] false wipes the save back to a first run.
  Future<void> resetSession({bool keepLegacy = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetToDefaults(prefs, keepLegacy: keepLegacy);
  }

  /// Directly replaces the live session with [session] — used to restore a
  /// manually saved checkpoint (see save_game_provider.dart). Persists
  /// immediately like every other mutator here.
  Future<void> loadSession(PlayerSession session) async {
    state = session;
    await _persist();
  }

  /// A story choice's costs and rewards. A negative [healAmount] is a wound
  /// the story deals (a storm, a burning cathedral) and never kills: health
  /// stops at 1. [bannerPieceId] adds a piece of the Shroud; [loseAllyId]
  /// (an id, or `*` for the first active ally) takes a companion for good.
  ///
  /// The companions in the party react to it (see approval.dart), by the
  /// weights in their [companions] records and the choice's own
  /// [approvalMods]; the reactions are returned, for the story to show.
  /// [goldIsProfit] false: the gold is loot picked up on the road (a
  /// detour's cache, an expedition's find), not a deed a companion who
  /// dislikes greed would hold against the player. [origin] (where the
  /// story stands, see itemOriginHere) is remembered for an [itemId] new
  /// to the pack (see [PlayerSession.itemOrigins]). [materials] (a
  /// choice's `grantMaterials`) go in the pack too, so many of each.
  Future<List<ApprovalChange>> applyChoiceEffects({
    int goldMod = 0,
    int alignmentMod = 0,
    int healAmount = 0,
    bool shortfallWounds = false,
    List<String> flagsToAdd = const [],
    String? questIDToProgress,
    String? bannerPieceId,
    String? itemId,
    Map<String, int> materials = const {},
    String? loseAllyId,
    Map<String, int> approvalMods = const {},
    Map<String, dynamic> companions = const {},
    bool goldIsProfit = true,
    ItemOrigin? origin,
  }) async {
    // Who the story takes is settled by the party as it stands in the
    // scene, before anyone reacts: a companion walking out over this very
    // choice must not leave `*` to take whoever steps into their seat.
    // Never a permanent companion (story_companions.dart): `*` takes the
    // first other one seated.
    final lostId = storyLossOf(loseAllyId,
        active: state.activeAllyIds, companions: companions);
    final reactions = _reactToDeed(
      companions: companions,
      alignmentMod: alignmentMod,
      goldMod: goldIsProfit ? goldMod : 0,
      approvalMods: approvalMods,
      // Taken by the story: they don't stay to have an opinion.
      exclude: lostId,
    );
    final newFlags = <String>{
      ...state.flags,
      ...flagsToAdd,
      // A quest taken in a scene is marked taken, as acceptQuest does.
      if (questIDToProgress != null &&
          questIDToProgress.isNotEmpty &&
          !state.completedQuestIds.contains(questIDToProgress))
        questAcceptedFlag(questIDToProgress),
    }.toList();
    // The rest before the Lantern Hall (7515_rest, docs/simulation/
    // difficulty-review.md proposal 4): the provisions and the mana
    // refilled; the scene's own heal and potion come with its choice.
    final rested = flagsToAdd.contains(_restBeforeHallFlag) &&
        !state.flags.contains(_restBeforeHallFlag);
    var newActiveQuests = state.activeQuestIds;
    var newKillBaselines = state.questKillBaselines;
    if (questIDToProgress != null &&
        questIDToProgress.isNotEmpty &&
        !state.activeQuestIds.contains(questIDToProgress) &&
        !state.completedQuestIds.contains(questIDToProgress)) {
      newActiveQuests = [...state.activeQuestIds, questIDToProgress];
      // Taken on in a scene, with no quest record at hand: every kill
      // count is kept, so a bounty's `countFromAccept` still counts from
      // now (as acceptQuest does with the record).
      newKillBaselines = {
        ...newKillBaselines,
        questIDToProgress: Map<String, int>.of(state.enemyKillCounts),
      };
    }
    final newTracked = questIDToProgress != null &&
            newActiveQuests.contains(questIDToProgress) &&
            !state.activeQuestIds.contains(state.trackedQuestId)
        ? questIDToProgress
        : state.trackedQuestId;
    var newBannerPieces = state.bannerPiecesCollected;
    if (bannerPieceId != null &&
        bannerPieceId.isNotEmpty &&
        !newBannerPieces.contains(bannerPieceId)) {
      newBannerPieces = [...newBannerPieces, bannerPieceId];
    }
    final newGoldRaw = state.gold + goldMod;
    // A forced price the purse can't make is taken in health (#583).
    final newHealthRaw = state.currentHealth +
        healAmount +
        (shortfallWounds
            ? shortfallWound(gold: state.gold, goldMod: goldMod)
            : 0);
    state = state.copyWith(
      gold: newGoldRaw < 0 ? 0 : newGoldRaw,
      alignmentScore: state.alignmentScore + alignmentMod,
      currentHealth: newHealthRaw > state.maxHealth
          ? state.maxHealth
          : (newHealthRaw < 1 ? 1 : newHealthRaw),
      flags: newFlags,
      provisions: rested ? provisionsMax : null,
      mana: rested ? state.maxMana : null,
      // The story's own boons (signs.dart): the Shroud, Lysa's blood on it.
      heldSigns: withStoryBoons(state.heldSigns, newFlags),
      activeQuestIds: newActiveQuests,
      questKillBaselines: newKillBaselines,
      trackedQuestId: newTracked,
      bannerPiecesCollected: newBannerPieces,
      inventoryItemIds: _withoutMaterials([
        ...state.inventoryItemIds,
        if (itemId != null && itemId.isNotEmpty) itemId,
        for (final MapEntry(key: id, value: count) in materials.entries)
          for (var i = 0; i < count; i++) id,
      ], materials),
      itemOrigins: itemId == null || itemId.isEmpty
          ? state.itemOrigins
          : withItemOrigins(state.itemOrigins, [itemId], origin),
    );
    if (lostId != null) {
      loseAlly(lostId, persist: false, companions: companions);
    }
    // The clans met (feat_clans): the first banner.
    state = _withFirstBanner(state);
    await _persist();
    // A flag or a piece of the Shroud may be what an achievement asks for.
    if (flagsToAdd.isNotEmpty || (bannerPieceId ?? '').isNotEmpty) {
      await checkAchievements();
    }
    return reactions;
  }

  /// The companions in the party react to a deed that moved alignment by
  /// [alignmentMod] and gold by [goldMod], plus a scene's own
  /// [approvalMods] (see approval.dart) -- a quest's outcome, say. One
  /// pushed to the end of their patience leaves the party for good.
  Future<List<ApprovalChange>> reactToDeed({
    required Map<String, dynamic> companions,
    int alignmentMod = 0,
    int goldMod = 0,
    Map<String, int> approvalMods = const {},
  }) async {
    final reactions = _reactToDeed(
      companions: companions,
      alignmentMod: alignmentMod,
      goldMod: goldMod,
      approvalMods: approvalMods,
    );
    if (reactions.isNotEmpty) await _persist();
    return reactions;
  }

  List<ApprovalChange> _reactToDeed({
    required Map<String, dynamic> companions,
    int alignmentMod = 0,
    int goldMod = 0,
    Map<String, int> approvalMods = const {},
    String? exclude,
  }) {
    final reactions = <ApprovalChange>[];
    final allies = [...state.recruitedAllies];
    for (var i = 0; i < allies.length; i++) {
      final ally = allies[i];
      // Only the party sees it; a benched companion was elsewhere.
      if (!state.activeAllyIds.contains(ally.companionId)) continue;
      if (ally.companionId == exclude) continue;
      final delta = approvalDeltaFor(
        companions[ally.companionId] as Map<String, dynamic>?,
        alignmentMod: alignmentMod,
        goldMod: goldMod,
        explicit: explicitApprovalFor(approvalMods, ally.companionId),
      );
      // Vica (a permanent companion) never falls far enough to walk out.
      final after = permanentApprovalFloor(
          companions[ally.companionId] as Map<String, dynamic>?,
          approvalAfter(ally.approval, delta));
      if (after == ally.approval) continue;
      reactions.add(ApprovalChange(
          companionId: ally.companionId, before: ally.approval, after: after));
      allies[i] = ally.copyWith(approval: after);
    }
    if (reactions.isEmpty) return reactions;
    state = state.copyWith(recruitedAllies: allies);
    for (var i = 0; i < reactions.length; i++) {
      final reaction = reactions[i];
      if (!reaction.leaves) continue;
      reactions[i] = ApprovalChange(
        companionId: reaction.companionId,
        before: reaction.before,
        after: reaction.after,
        replacedBy: _removeAlly(reaction.companionId,
            lost: false, companions: companions),
      );
    }
    return reactions;
  }

  /// Takes [companionId] off the roster and out of the party, for good:
  /// [lost] when the story took them (lostAllyIds, the story's {lost}
  /// lines), else they walked out (departedAllyIds). Their seat doesn't stay
  /// empty (a finale fought one companion short can be out of reach): the
  /// benched companion who thinks best of the player steps in, the earlier
  /// recruit on a tie, once their house is built. Returns who did.
  @override
  String? _removeAlly(
    String companionId, {
    required bool lost,
    required Map<String, dynamic> companions,
  }) {
    final roster = [
      for (final ally in state.recruitedAllies)
        if (ally.companionId != companionId) ally,
    ];
    final active = [
      for (final id in state.activeAllyIds)
        if (id != companionId) id,
    ];
    String? replacement;
    if (state.activeAllyIds.contains(companionId)) {
      final bench = [
        for (final ally in roster)
          if (!active.contains(ally.companionId) &&
              _houseBuiltFor(companions[ally.companionId]))
            ally,
      ];
      if (bench.isNotEmpty) {
        replacement = bench
            .reduce((best, ally) => ally.approval > best.approval ? ally : best)
            .companionId;
        active.add(replacement);
      }
    }
    List<String> plus(List<String> ids) =>
        ids.contains(companionId) ? ids : [...ids, companionId];
    state = state.copyWith(
      recruitedAllies: roster,
      activeAllyIds: active,
      lostAllyIds: lost ? plus(state.lostAllyIds) : state.lostAllyIds,
      departedAllyIds:
          lost ? state.departedAllyIds : plus(state.departedAllyIds),
    );
    return replacement;
  }

  /// Whether [companion]'s own house gate (companions.json
  /// `requiredHouseId`), if any, is built. Without their record (the table
  /// still loading, a caller that passed none) the gate can't be read, so
  /// they can't be seated.
  bool _houseBuiltFor(Object? companion) {
    if (companion is! Map<String, dynamic>) return false;
    final house = companion['requiredHouseId']?.toString() ?? '';
    return house.isEmpty || state.builtHouseIds.contains(house);
  }

  /// Shares a drink with [companionId] at the camp: [giftCostFor] the
  /// [chapter] in gold for [giftApproval], once a chapter per companion.
  /// Returns false when it can't be done (no gold, already this chapter).
  Future<bool> shareDrink(String companionId, {required int chapter}) async {
    final ally = state.recruitedAllies
        .where((a) => a.companionId == companionId)
        .firstOrNull;
    final cost = giftCostFor(chapter);
    if (ally == null || ally.giftChapter == chapter || state.gold < cost) {
      return false;
    }
    final allies = [
      for (final a in state.recruitedAllies)
        a.companionId == companionId
            ? a.copyWith(
                approval: approvalAfter(a.approval, giftApproval),
                giftChapter: chapter)
            : a,
    ];
    state = state.copyWith(gold: state.gold - cost, recruitedAllies: allies);
    await _persist();
    return true;
  }

  // --- Offers (v1.194, see offers.dart) -----------------------------------

  /// Offers due for a new character of [profession]: its starting skill
  /// points (professions.json `startingSkillPoints`), one offer each.
  static List<OfferTicket> startingOffersFor(Map<String, dynamic> profession) =>
      [
        for (var i = 0;
            i < ((profession['startingSkillPoints'] as num?)?.toInt() ?? 0);
            i++)
          const OfferTicket(source: OfferSource.start),
      ];

  /// [session] with its first banner (the user's rule, v1.634): on the
  /// feature ladder, once the clans are met (feat_clans, or past chapter
  /// 2), one offer is due, [firstBannerFlag] set; none when one is already
  /// waiting (a save that piled offers up before this rule keeps them, they
  /// are the player's). Off the ladder, nothing changes.
  static PlayerSession _withFirstBanner(PlayerSession session) {
    if (!session.flags.contains(featureLadderFlag) ||
        session.flags.contains(firstBannerFlag) ||
        !session.featureOpen(GameFeature.clans)) {
      return session;
    }
    return session.copyWith(
      flags: [...session.flags, firstBannerFlag],
      pendingOffers: session.pendingOffers.isEmpty
          ? const [OfferTicket(source: OfferSource.level, detail: 'first')]
          : null,
    );
  }

  /// [levels] offers for the levels just reached.
  static List<OfferTicket> _levelOffers(int levels) => [
        for (var i = 0; i < levels; i++)
          const OfferTicket(source: OfferSource.level),
      ];

  /// What a story choice's or an intrigue's outcome does to a companion:
  /// this much approval for `disapproves` (and back for `approves`).
  static const int intrigueApprovalShift = 5;

  /// How a Potion-type item converts into drinkable charges when it's
  /// bought or looted -- [PlayerSession.potionCount] / [antidoteCount] are
  /// what the fight screen's Potion/Antidote buttons actually read, so a
  /// potion that only ever landed in [PlayerSession.inventoryItemIds] could
  /// never be drunk. A Major Healing Potion is worth two charges (it costs
  /// nearly three times a Minor one). Null for any non-consumable item,
  /// which goes into the inventory as before.
  static ({int potions, int antidotes})? consumableChargesFor(
    String itemId,
    Map<String, dynamic>? item,
  ) {
    if (item?['itemType']?.toString() != 'Potion') return null;
    if (itemId == 'antidote') return (potions: 0, antidotes: 1);
    return (potions: itemId == 'potion_major' ? 2 : 1, antidotes: 0);
  }

  /// [tomePicks] with [itemId] once per pick a tome of it grants
  /// ([picks]), for the ledger (see [PlayerSession.tomePicks]).
  static List<String> _withTomePicks(
          List<String> tomePicks, String itemId, int picks) =>
      picks <= 0
          ? tomePicks
          : [...tomePicks, for (var i = 0; i < picks; i++) itemId];

  /// What reading a looted tome grants on the spot -- a Tome-type item
  /// never enters the inventory, exactly like a potion becomes a charge.
  /// `tome_of_mastery` grants an offer (it granted a skill point before
  /// v1.194); every other Tome grants a stat point. Null for anything that
  /// isn't a Tome.
  static ({int statPoints, List<OfferTicket> offers})? tomeGrantFor(
      String itemId, Map<String, dynamic>? item) {
    if (item?['itemType']?.toString() != 'Tome') return null;
    if (itemId == 'tome_of_mastery') {
      return (
        statPoints: 0,
        offers: const [OfferTicket(source: OfferSource.tome)],
      );
    }
    return (statPoints: 1, offers: const <OfferTicket>[]);
  }
}

/// Summary of a run that ended in permadeath, for the death screen.
class PermadeathResult {
  const PermadeathResult({
    required this.lostItemIds,
    required this.xpEarnedThisRun,
    required this.skillsLost,
    this.signsLost = 0,
  });

  final List<String> lostItemIds;

  /// How many skills were unlocked right before the reset wiped them back
  /// to class basics — for the death-screen recap.
  final int skillsLost;
  final int xpEarnedThisRun;

  /// How many signs the life carried, all lost with it.
  final int signsLost;
}

/// What the camp's roll houses give [s] (camp_rolls.dart): the charges of
/// each power whose house stands ([powers], else read from
/// rollPowerHouses), and the bans running.
CampRolls campRollsOf(PlayerSession s, {Set<RollPower>? powers}) {
  final built = powers ?? rollPowersOf(s.builtHouseIds);
  return CampRolls(
    reroll: built.contains(RollPower.reroll) ? s.rerollCharges : null,
    banish: built.contains(RollPower.banish) ? s.banishCharges : null,
    raise: built.contains(RollPower.raise) ? s.raiseCharges : null,
    raiseProgress: s.raiseProgress,
    bans: s.rollBans,
  );
}

/// The roll houses' charges and bans for the choice sheets (camp_rolls.dart).
final campRollsProvider = Provider<CampRolls>((ref) {
  // Only what the roll houses read (P4): other changes leave the sheets be.
  ref.watch(playerSessionProvider.select((s) => (
        built: s.builtHouseIds,
        reroll: s.rerollCharges,
        banish: s.banishCharges,
        raise: s.raiseCharges,
        progress: s.raiseProgress,
        bans: s.rollBans,
      )));
  return campRollsOf(ref.read(playerSessionProvider));
});

/// The wards on the road running now, each clan with its roads left
/// (road_wards.dart), for the Journey's mark (`ward_mark`).
final roadWardsProvider = Provider<List<RoadWard>>((ref) =>
    roadWardsOf(ref.watch(playerSessionProvider.select((s) => s.rollBans))));

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});

/// [items] with the materials [materials] counts below zero spends taken
/// out (a clan's crisis paid in timber and stone, clan_crisis.dart): as
/// many of each as the pack holds, no more.
List<String> _withoutMaterials(List<String> items, Map<String, int> materials) {
  final out = [...items];
  for (final MapEntry(key: id, value: count) in materials.entries) {
    for (var i = 0; i < -count; i++) {
      if (!out.remove(id)) break;
    }
  }
  return out;
}
