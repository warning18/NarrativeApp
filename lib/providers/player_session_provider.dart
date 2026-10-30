import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
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
import '../data/character_start.dart' show startingArmor;
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

const String _playerSessionPrefsKey = 'player_session';

/// Where a save that could not be read is kept aside, untouched, before
/// the game falls back to a fresh session (see [PlayerSessionNotifier]).
const String unreadableSessionBackupPrefsKey = 'player_session_unreadable';

/// The save format's version, written into every save. Bump it with a
/// migration in [PlayerSession.fromJson] whenever a change to the format
/// needs one; a save without it is version 1.
const int playerSessionSaveVersion = statScaleSaveVersion;
const String _newGameDefaultsAssetPath = 'assets/gamedata/game_config.json';
const String _newGameDefaultsPrefsKey = 'gamedb_game_config';

/// The flag of the rest before the Lantern Hall (7515_rest): the
/// provisions and the mana refilled (applyChoiceEffects).
const String _restBeforeHallFlag = 'rest_before_hall';

/// The starter die's face indexes reserved for the player's profession and
/// race standard skills (see assets/gamedata/dice.json's starter_die).
const String _starterDiceId = 'starter_die';
const int _starterDieProfessionFaceIndex = 4;
const int _starterDieRaceFaceIndex = 5;

/// The apprentice die's Channeling face, where a caster's mana skill sits
/// from the start (see `manaSkillID` in professions.json).
const int _startingDieManaFaceIndex = 1;

/// How many companions may be seated (fight beside the player): two, so a
/// fight has three fighters and three dice, never more (the user's cap,
/// v1.664). A house's `partyCapacityBonus` (houses.json, the Barracks
/// Annex) adds a reserve seat instead ([reserveSeatsFor]).
const int basePartyCapacity = 2;

/// The flag set when the first banner (clan offer) is due: the clans met
/// on the feature ladder (see PlayerSessionNotifier._withFirstBanner).
const String firstBannerFlag = 'first_banner';

/// Whether [session]'s level-ups, bosses and chapters bring no clan offer
/// yet (the user's rule, v1.634): on the feature ladder, until the clans
/// are met. Off the ladder they always do.
bool offersWaitForClans(PlayerSession session) =>
    session.flags.contains(featureLadderFlag) &&
    !session.featureOpen(GameFeature.clans);

/// The player's active-party capacity: [basePartyCapacity], whatever is
/// built (the cap of three fighters, v1.664; the houses' bonus is the
/// reserve seat, [reserveSeatsFor]). Shared by [PlayerSessionNotifier
/// .recruitAlly] (auto-activating a fresh recruit up to capacity) and
/// CampScreen's own roster display, so the two never drift apart.
int partyCapacityFor(List<String> builtHouseIds, Map<String, dynamic> houses) =>
    basePartyCapacity;

/// The reserve seats [builtHouseIds] give (the user's pick, v1.664): one
/// once a built house has a `partyCapacityBonus` (the Barracks Annex),
/// never more. The companion in it waits at the party's back and steps in
/// for a fielded companion knocked out, once a fight (fight_rounds.dart's
/// _reserveStepsIn).
int reserveSeatsFor(List<String> builtHouseIds, Map<String, dynamic> houses) =>
    min(
        maxReserveSeats,
        houses.values.whereType<Map<String, dynamic>>().where((h) {
          return builtHouseIds.contains(h['houseID']?.toString() ?? '');
        }).fold<int>(
            0,
            (sum, h) =>
                sum + ((h['partyCapacityBonus'] as num?)?.toInt() ?? 0)));

/// At most one companion waits in reserve.
const int maxReserveSeats = 1;

/// The skills a companion starts with: their profession's and race's
/// standard skill, and every skill one of their signature die's faces links
/// to, so the die works from their very first fight (see
/// [PlayerSessionNotifier.recruitAlly]).
List<String> companionStarterSkillIds({
  Map<String, dynamic>? race,
  Map<String, dynamic>? profession,
  Map<String, dynamic>? companion,
  Map<String, dynamic> dice = const {},
}) {
  final professionSkillId = profession?['standardSkillID']?.toString() ?? '';
  final raceSkillId = race?['standardSkillID']?.toString() ?? '';
  // A companion's signature die IS their kit: every skill one of its
  // faces links to has to resolve from their very first fight, not
  // fizzle until the player happens to spend ally skill points on that
  // exact id (Maren shipped with 2 of her 3 skill faces dead that way).
  final signatureDiceId = companion?['signatureDiceId']?.toString() ?? '';
  final signatureFaces =
      ((dice[signatureDiceId] as Map<String, dynamic>?)?['faces'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
  return <String>{
    if (professionSkillId.isNotEmpty) professionSkillId,
    if (raceSkillId.isNotEmpty) raceSkillId,
    for (final face in signatureFaces)
      if ((face['linkedSkillID']?.toString() ?? '').isNotEmpty)
        face['linkedSkillID'].toString(),
  }.toList();
}

/// Companions the "Full House" achievement asks for: six of the eight.
/// Tobin follows only a Good leader and Malrik only an Evil one, so no
/// single run can recruit everyone.
const int fullRosterCompanionCount = 6;

/// The intrigues of intrigues.json: "settle them all" needs this many
/// distinct ones (a test keeps the count in step with the file).
const int intrigueCount = 11;

/// How many of the six clans must trust the character at once for "A Hand
/// at Four Doors": a clan's gains cost its rivals half, so all six is out of
/// reach (QA's search never passed five).
const int _trustedClansForFriend = 4;

/// The six clans a character can swear to (the ones with a Sworn boon).
const List<String> coastClanIds = [
  'dominion',
  'vigil',
  'compact',
  'mire',
  'crows',
  'penitents',
];

/// `intrigue_<id>_outcome_<n>`: an intrigue settled (see politics_events).
final RegExp _intrigueOutcomeFlag = RegExp(r'^intrigue_(.+)_outcome_\d+$');

/// The share of the purse a retreat costs (see [retreatCostFor]); a
/// potion, when the pack holds one, is dropped too.
const double _retreatGoldShare = 0.2;

/// The least a retreat costs, when the party has that much.
const int _retreatMinimumGold = 10;

/// What getting away from a fight costs a party carrying [gold]: a
/// share of it, at least [_retreatMinimumGold], never more than it has.
int retreatCostFor(int gold) =>
    min(gold, max(_retreatMinimumGold, (gold * _retreatGoldShare).round()));

/// What a shop pays for [item]: two fifths of its price, at least 1 gold.
/// An item's own `sellValue` wins -- the Elite Mark is a trophy, worth
/// more to a dealer than a shelf price would say.
int sellPriceFor(Map<String, dynamic>? item) {
  final own = (item?['sellValue'] as num?)?.toInt();
  if (own != null) return own;
  final cost = (item?['cost'] as num?)?.toInt() ?? 0;
  return max(1, (cost * 2 / 5).round());
}

/// Whether [item] can be sold at all: quest items stay with the party.
bool canSellItem(Map<String, dynamic>? item) =>
    item != null && item['itemType']?.toString() != 'Quest';

/// The materials forging [item] takes (items.json `craftMaterials`, item
/// id to count); empty for anything not forged.
Map<String, int> craftMaterialsFor(Map<String, dynamic>? item) {
  return materialCountsOf(item, 'craftMaterials');
}

/// The items forged at [shopId] (items.json `craftedAt`), sorted by id.
List<String> recipesAt(String shopId, Map<String, dynamic> items) => [
      for (final e in items.entries)
        if ((e.value as Map<String, dynamic>)['craftedAt']?.toString() ==
            shopId)
          e.key,
    ]..sort();

/// The wearer id [PlayerSession.wearersOf] uses for the player (allies go
/// by their companion id).
const String playerWearerId = 'player';

/// The flag a built camp house leaves for the story to read back
/// ("house_hearth_hall").
String houseFlag(String houseId) => 'house_$houseId';

/// The key a scene's [text] is remembered as read under (see
/// PlayerSession.readSceneKeys): the node and a hash of the words, so a
/// changed scene reads as new.
String sceneReadKey(String nodeId, String text) {
  var hash = 0x811c9dc5;
  // The markup of the story text (`**`) is not part of the words: marking a
  // scene up does not make a place read before look unread.
  for (final unit in stripStoryMarkup(text).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return '$nodeId#${hash.toRadixString(16)}';
}

/// [PlayerSession.shopUnlockNodeIds]' mark for a shop met on the road
/// rather than found in a scene: it moved on, and is never browsable again
/// from the Shops list.
const String roadShopNodeId = '@road';

class PlayerSession {
  const PlayerSession({
    required this.level,
    required this.currentXP,
    required this.gold,
    required this.alignmentScore,
    required this.maxHealth,
    required this.currentHealth,
    required this.baseDamage,
    required this.baseArmor,
    required this.luck,
    required this.charisma,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.perception,
    required this.potionCount,
    required this.statPoints,
    required this.maxSkillSlots,
    required this.flags,
    required this.activeQuestIds,
    required this.completedQuestIds,
    required this.inventoryItemIds,
    required this.equippedItemIds,
    required this.unlockedSkillIds,
    required this.unlockedShopIds,
    required this.unlockedQuestIds,
    required this.unlockedEnemyIds,
    required this.diceSkillAssignments,
    required this.raceId,
    required this.professionId,
    required this.ownedDiceIds,
    required this.equippedDiceId,
    this.xpEarnedThisRun = 0,
    this.shopPurchaseCounts = const {},
    this.characterName = '',
    this.trackedQuestId = '',
    this.masteredBranchId = '',
    this.shopUnlockNodeIds = const {},
    this.seenShopIds = const [],
    this.seenQuestIds = const [],
    this.seenEnemyIds = const [],
    this.seenNpcIds = const [],
    this.readSceneKeys = const [],
    this.seenEchoKeys = const [],
    this.seenFightTipIds = const [],
    this.seenTownRulers = const {},
    this.provisions = provisionsStart,
    this.day = 1,
    this.watch = 1,
    this.clockChapter = 0,
    this.chapterStartDay = 1,
    this.sellswordFights = 0,
    this.blessingFights = 0,
    this.blessingClan = '',
    this.templeMendDay = 0,
    this.seaRemarkChapter = 0,
    this.templeStandingChapters = const {},
    this.alignmentRollsSinceAmbush = hunterCooldownRolls,
    this.detourPacing = const DetourPacing(),
    this.specIds = const [],
    this.runSeed = 0,
    this.diceUpgrades = const {},
    this.recruitedAllies = const [],
    this.activeAllyIds = const [],
    this.reserveAllyId = '',
    this.lostAllyIds = const [],
    this.departedAllyIds = const [],
    this.perkRanks = const {},
    this.heldSigns = const [],
    this.pendingOffers = const [],
    this.clanOffer,
    this.trainingTaken = const {},
    this.statPickOffer = const [],
    this.rerollCharges = 0,
    this.banishCharges = 0,
    this.raiseCharges = 0,
    this.raiseProgress = 0,
    this.rollBans = const [],
    this.rollNonce = 0,
    this.statSources = const {},
    this.riskCurses = const [],
    this.tomePicks = const [],
    this.heldTitleIds = const [],
    this.activeTitleId = '',
    this.swornBoonIds = const [],
    this.chapterOffersThrough = 0,
    this.titanBlood = 0,
    this.patronFavour = const {},
    this.signPatronsThisLife = const [],
    this.patronsMet = const [],
    this.acknowledgedFeatures = const [],
    this.politics = PoliticsState.empty,
    this.builtHouseIds = const [],
    this.townOrder = const [],
    this.unlockedAchievementIds = const [],
    this.completedZoneIds = const [],
    this.bannerPiecesCollected = const [],
    this.shipHull = -1,
    this.shipPartIds = const ['ballista'],
    this.storedShipPartIds = const [],
    this.shipLooks = const {},
    this.ownedShipLooks = const [],
    this.shipHullId = 'rusty_eel',
    this.ownedHullIds = const ['rusty_eel'],
    this.currentPortId = '',
    this.visitedPortIds = const [],
    this.enemyKillCounts = const {},
    this.questKillBaselines = const {},
    this.contracts = const [],
    this.contractsChapter = 0,
    this.contractBoards = 0,
    this.seaBeasts = const {},
    this.bossDefeatCounts = const {},
    this.grandfatheredQuestIds = const [],
    this.talkedToNpcIds = const [],
    this.skillEssence = 0,
    this.skillTiers = const {},
    this.antidoteCount = 0,
    this.lootPityStreak = 0,
    this.recentLootIds = const [],
    this.mana = 0,
    this.knownSpellIds = const [],
    this.newGamePlusCycle = 0,
    this.legacyGold = 0,
    this.legacyDiceIds = const [],
    this.legacySpellIds = const [],
    this.itemOrigins = const {},
  });

  final int level;
  final int currentXP;
  final int gold;
  final int alignmentScore;
  final int maxHealth;
  final int currentHealth;
  final int baseDamage;
  final int baseArmor;

  /// Boosts the drop-rate roll on combat loot (see [FightScreen]'s win
  /// handling), and feeds `criticalChanceFor` in combat_engine.dart — a
  /// lucky character both finds better gear and lands harder hits.
  final int luck;

  /// Gates persuasion-flavored story nodes via [StoryNode.reqCharisma],
  /// alongside the existing reqGold/reqAlignment/reqFlags requirements.
  final int charisma;

  /// The classic D&D-style ability scores, alongside [luck] and
  /// [charisma]. Each feeds `rollAbilityCheck` (see ability_check.dart) as
  /// a flat bonus on a d20 roll for `StoryChoice.checkAbility` — story
  /// choices phrased as an attempt ("Force the door", "Talk your way
  /// past") rather than a hard gate. [baseDamage]/[baseArmor] remain the
  /// only stats the die-roll math itself reads directly, but Strength/
  /// Dexterity/Constitution/Intelligence also matter in a fight indirectly,
  /// through gear: an equipped item's own `scalingStat` (see
  /// `equipmentScalingBonusFor` in ally_state.dart) adds `stat ~/ 2` on top
  /// of its flat attackDamage/armor, and some items gate equipping behind a
  /// minimum score (`meetsItemStatRequirement`) — a staff rewards
  /// Intelligence, a sword rewards Strength, matching whichever build
  /// actually wields it. Wisdom adds to healing, to the mana a Mana face
  /// or mana skill gives (see `wisdomManaBonusFor` in spells.dart) and
  /// shortens the statuses that land on the party.
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;

  /// Feeds `telegraphTierFor` in combat_engine.dart, offset by an enemy's
  /// own Guile — how much detail the party can read about an enemy's
  /// telegraphed next move in [FightScreen]. Uses the highest Perception
  /// among conscious party members, not just the player's own.
  final int perception;
  final int potionCount;
  final int statPoints;
  final int maxSkillSlots;
  final List<String> flags;
  final List<String> activeQuestIds;
  final List<String> completedQuestIds;
  final List<String> inventoryItemIds;
  final List<String> equippedItemIds;
  final List<String> unlockedSkillIds;
  final List<String> unlockedShopIds;
  final List<String> unlockedQuestIds;
  final List<String> unlockedEnemyIds;

  /// diceId -> {faceIndex (as string) -> skillId}
  final Map<String, Map<String, String>> diceSkillAssignments;

  final String raceId;
  final String professionId;

  /// Dice are equipment: dice the player owns (found, bought or granted),
  /// and which one is currently equipped for combat.
  final List<String> ownedDiceIds;
  final String? equippedDiceId;

  /// XP gained since the last new game / permadeath reset — a recap metric
  /// only, not a gameplay stat; doesn't affect level or anything else.
  final int xpEarnedThisRun;

  /// How many units of each item a shop has sold so far, keyed by
  /// "shopID::itemID". Shops have a fixed stock (see [DbSchema] shops'
  /// stockQuantities field) that doesn't replenish, so this persists across
  /// sessions and survives permadeath (losing an item doesn't restock it).
  final Map<String, int> shopPurchaseCounts;

  /// The player-chosen name for this character, set once during creation
  /// (see RaceProfessionScreen's lock-in dialog) and fixed for the rest of
  /// the run.
  final String characterName;

  /// The quest the player follows: its current goal shows above the story
  /// (see QuestTrackerBar). '' when none was picked; the most recent
  /// active quest stands in (see `followedQuestIdOf` in
  /// quest_tracking.dart). Set when a quest is accepted with nothing
  /// followed, cleared when it is turned in.
  final String trackedQuestId;

  /// The one skill-tree branch the character has mastered (see
  /// skill_tree.dart): its skills fight one tier above their own. Empty
  /// until a branch is mastered; only one ever is.
  final String masteredBranchId;

  /// shopId -> the story node whose choice unlocked it. A shop is only
  /// browsable in the Play tab while the player is currently on that node;
  /// leaving it hides the shop again (it reappears if the player returns).
  /// Unlike [unlockedShopIds], entries here are never removed, so
  /// historical stats (e.g. the playthrough simulator) still see every shop
  /// ever discovered. A shop met on the road (a detour's stall, the
  /// Wayfarer's Caravan) is [roadShopNodeId]: it was there only while the
  /// party stood at it.
  final Map<String, String> shopUnlockNodeIds;

  /// Ids the player has already viewed in the Play tab, used to compute the
  /// "newly unlocked" badge counts shown on the Quests/Shops/Bestiary
  /// section headers.
  final List<String> seenShopIds;
  final List<String> seenQuestIds;
  final List<String> seenEnemyIds;

  /// The people (npcs.json, v1.204) the player has looked at in the
  /// Other tab's People section: a person known (see npcDiscovered) and
  /// not here counts on the section's badge.
  final List<String> seenNpcIds;

  /// The town and camp scenes the player has read in full, as
  /// `<nodeId>#<hash of the text>` (see sceneReadKey): coming back to one
  /// whose text hasn't changed opens straight onto the place.
  final List<String> readSceneKeys;

  /// The echoes the player has read (see echoes.dart): a scene's line with
  /// the earlier choice that earned it, as `<nodeId>|<flag>`. The journal's
  /// "What changed" page lists them.
  final List<String> seenEchoKeys;

  /// The one-time fight tips this save has shown (see fight_tips.dart): a
  /// goal, a doctrine or a situation is explained the first time a fight
  /// shows it. An old save without the field has seen none.
  final List<String> seenFightTipIds;

  /// Who ruled each town (town id -> clan id, '' for none) when the player
  /// last looked at the world chart: a town whose ruler is not the one
  /// written here has changed hands since, and the chart says so. An old
  /// save without the field has seen none (the first look just writes it).
  final Map<String, String> seenTownRulers;

  /// Rations carried (see journey_rules.dart): one is eaten on each step
  /// of the road from chapter 2 on; with none left the party goes hungry.
  final int provisions;

  /// The world clock: the day of the journey, from 1, and the watch of it
  /// (0 dawn, 1 day, 2 dusk, 3 night). A step on the road is a watch (four
  /// from dawn end the day), a walk between places two, a voyage its days
  /// at sea; a rest sleeps through to the next dawn (see takeRoadStep,
  /// passTime, passDays, restUntilDawn).
  final int day;
  final int watch;

  /// The chapter the clock counts days in, and the day it began: the
  /// longer a chapter takes, the stronger its enemies grow (see
  /// [threatFor]).
  final int clockChapter;
  final int chapterStartDay;

  /// Fights left on a hired sellsword's contract (see journey_rules.dart).
  final int sellswordFights;

  /// A temple's blessing (see temple.dart): the fights it has left, and
  /// the clan whose temple gave it ('' a neutral temple), its effects read
  /// live from factions.json.
  final int blessingFights;
  final String blessingClan;

  /// The day of the last Mending at a temple (0 never): once a day.
  final int templeMendDay;

  /// The chapter a companion last spoke up at sea in (0 never, see
  /// seaRemarkDue): once a chapter, on the first voyage someone has a sea
  /// line for. An old save without the field has had none.
  final int seaRemarkChapter;

  /// The chapter each clan's blessing last brought standing (clan ->
  /// chapter): once a chapter per clan.
  final Map<String, int> templeStandingChapters;

  /// Alignment events rolled since the last hunter's ambush: a hunter
  /// waits [hunterCooldownRolls] of them before the next (see
  /// alignment_events.dart).
  final int alignmentRollsSinceAmbush;

  /// What the detours have done so far (see detour_pacing.dart): the pity
  /// timer, the cooldown, a detour owed, the scenes met.
  final DetourPacing detourPacing;

  /// The specialisations the clans gave (specialisations.dart), in the
  /// order taken: those of the character's core play in every fight.
  final List<String> specIds;

  /// Rolled once per new game: picks each chapter's condition (see
  /// chapter_conditions.dart). 0 on saves made before it existed.
  final int runSeed;

  /// The Hammersmith's work on the party's dice (v1.182, see
  /// face_smithing.dart): die key → face index → what was done to it. Kept
  /// on the die it was done on: the player's own under the die's id, a
  /// companion's signature die under their id too (see dieUpgradesKey and
  /// [upgradesOfDie]).
  final Map<String, DieUpgrades> diceUpgrades;

  /// The Hammersmith's work on die [dieId] as [companionId] has it (their
  /// signature die), or as the player has it (no [companionId]). A save
  /// from before the two were kept apart has a companion's work under the
  /// die's id alone: it stays with the player's own copy of the die, and a
  /// companion still finds it on a die the player doesn't own.
  DieUpgrades? upgradesOfDie(String? dieId, {String? companionId}) {
    if (dieId == null) return null;
    if (companionId == null) return diceUpgrades[dieId];
    return diceUpgrades[dieUpgradesKey(dieId, companionId: companionId)] ??
        (ownedDiceIds.contains(dieId) ? null : diceUpgrades[dieId]);
  }

  /// How much stronger enemies are in [chapter] for the days the party has
  /// spent in it (see [threatFor]).
  double threatIn(int chapter) =>
      roadRulesApply(chapter) && clockChapter == chapter
          ? threatFor(day - chapterStartDay, chapter: chapter)
          : 0;

  /// Companions recruited through story quests — permanent for this save
  /// once earned, regardless of active/benched status (mirrors
  /// [completedQuestIds]'s append-only pattern).
  final List<AllyState> recruitedAllies;

  /// Subset of [recruitedAllies] (by companionId) currently fighting
  /// alongside the player, bounded by party capacity (default 2, raised by
  /// built houses' partyCapacityBonus).
  final List<String> activeAllyIds;

  /// The companion in the reserve seat (the Barracks Annex, see
  /// [reserveSeatsFor]), '' for none. Read it through [reserveAlly].
  final String reserveAllyId;

  /// The companion waiting in reserve: [reserveAllyId] while recruited and
  /// not seated, else null.
  String? get reserveAlly => reserveAllyId.isNotEmpty &&
          !activeAllyIds.contains(reserveAllyId) &&
          recruitedAllies.any((a) => a.companionId == reserveAllyId)
      ? reserveAllyId
      : null;

  /// Companions the story took for good (see [StoryChoice.loseAllyId]);
  /// never re-recruited this run, cleared with a new game.
  final List<String> lostAllyIds;

  /// Companions who walked out over the player's choices (see
  /// approval.dart); never re-recruited this run. Kept apart from
  /// [lostAllyIds], which the story's `{lost}` lines name.
  final List<String> departedAllyIds;

  /// Perk ranks taken (see perks.dart): perk name -> rank. Since v1.194
  /// a rank is the Wayfarer's gift in an offer (see offers.dart); ranks
  /// taken before keep working.
  final Map<String, int> perkRanks;

  PerkEffects get perkEffects => perkEffectsFor(perkRanks);

  /// Signs (see signs.dart): the ones drawn on the character this life,
  /// with their rarity, level and any pact still running.
  final List<HeldSign> heldSigns;

  /// Offers (v1.194, see offers.dart): the ones due, oldest first (a level
  /// reached, a boss beaten, a chapter's end, a Tome of Mastery...), and
  /// the one on the table, drawn for the first of them and kept until a
  /// suitor is taken, so reopening it never redraws it.
  final List<OfferTicket> pendingOffers;
  final ClanOffer? clanOffer;

  /// The training paths (training_paths.json) the stat picks have drawn
  /// from, with how many times: they weigh the next picks' draw.
  final Map<String, int> trainingTaken;

  /// The stat pick on the table (docs/proposals/stat-picks.md): the three
  /// offers of the next of the [pendingStatPicks], drawn once and kept until
  /// one is taken; empty when none is drawn.
  final List<StatPickOffer> statPickOffer;

  /// The picks waiting: one per unspent stat point.
  int get pendingStatPicks => statPoints;

  /// The camp's roll houses (camp_rolls.dart): the Reroll, Banish and
  /// Raise charges left, the fresh draws toward the next Raise charge, the
  /// bans running, and a count of the powers used, mixed into the stat
  /// pick's seed so a redraw differs. Each written only when not its
  /// default; an old save reads them all at it.
  final int rerollCharges;
  final int banishCharges;
  final int raiseCharges;
  final int raiseProgress;
  final List<RollBan> rollBans;
  final int rollNonce;

  /// The stat ledger (stat_ledger.dart, v1.459): what raised a stat that
  /// the data can't tell afterwards -- `kind:id` (a pick's path, a tome, the
  /// patron, the formative memories) -> stat -> amount, the base damage and
  /// max health those points brought included. Written by
  /// [withSourcedGains]; read by statBreakdown. Empty in a save from before
  /// it (statBreakdown then shows what it can't explain as "earlier").
  final Map<String, Map<String, int>> statSources;

  /// The clans' curses worn (risky_gifts.dart): each lowers a stat, written
  /// in [statSources] as `curse:<clan>`, until its level is reached (see
  /// [withCursesEnded]). Left out of the save when empty.
  final List<RiskCurse> riskCurses;

  /// The tomes whose pick still waits among the [pendingStatPicks], oldest
  /// first: the next pick taken counts as the first one's (the ledger's
  /// `tome:<id>`), the others as a level's.
  final List<String> tomePicks;

  /// Titles held (titles.json): from offers, from the tiers reached with a
  /// faction, and "the Marked" while the Inquisition is a foe; the one
  /// worn ('' for none) lends its effects (see clanEffectsFor).
  final List<String> heldTitleIds;
  final String activeTitleId;

  /// The factions whose Sworn boon was taken: it works while that faction
  /// is the one sworn to.
  final List<String> swornBoonIds;

  /// The last chapter whose arrival brought its offer (see
  /// PlayerSessionNotifier.grantChapterOffer).
  final int chapterOffersThrough;

  /// Drops of Titan's Blood waiting to raise a held sign one level.
  final int titanBlood;

  /// Signs taken from each patron, ever: favour, kept through permadeath
  /// and New Game+ like a legacy (see favourLevelFor).
  final Map<String, int> patronFavour;

  /// The patrons that gave a sign this life, in order: the Choir or the
  /// Pit among them, not both (see patronOpen).
  final List<String> signPatronsThisLife;

  /// Every patron that has offered a sign, ever: the codex lists them.
  final List<String> patronsMet;

  /// The ladder's features already told of (feature_unlocks.dart), by id.
  final List<String> acknowledgedFeatures;

  /// What the feature ladder reads of this session (feature_unlocks.dart).
  LadderState get ladder =>
      (flags: flags, level: level, chapter: chapterOffersThrough);

  /// Whether [feature] is open (feature_unlocks.dart).
  bool featureOpen(GameFeature feature) => featureUnlocked(feature, ladder);

  /// Where the character stands with the coast (v1.193, see factions.dart):
  /// standing with each faction, the sub-clans' marks, the faction sworn
  /// to, how the clans stand with each other, and the logs of it all.
  /// The world starts over with a new game, a permadeath and a New Game+;
  /// favour with the patrons ([patronFavour]) is another thing, and stays.
  final PoliticsState politics;

  /// Houses built at camp — mirrors [unlockedShopIds]. Gates which specific
  /// companions can join the active party (a companion's own
  /// `requiredHouseId`) and/or raises party capacity
  /// (`partyCapacityBonus`), per houses.json.
  final List<String> builtHouseIds;

  /// Every piece of the camp's cliff town in the order it went up: house
  /// ids and town additions (`add_floor`, `add_tower`...), see
  /// data/cliff_town.dart. Saves from before the town have none; their
  /// town is their [builtHouseIds] in order (see [townPieces]).
  final List<String> townOrder;

  /// The town's pieces in build order: [townOrder], with any built house
  /// it lacks added after it and any house no longer built left out.
  List<String> get townPieces => [
        for (final id in townOrder)
          if (id.startsWith('add_') || builtHouseIds.contains(id)) id,
        for (final id in builtHouseIds)
          if (!townOrder.contains(id)) id,
      ];

  /// Achievement ids the player has earned — permanent, append-only, like
  /// [completedQuestIds].
  final List<String> unlockedAchievementIds;

  /// Expedition zones whose reward has already been banked — permanent,
  /// append-only, like [completedQuestIds]. A zone not yet in this list can
  /// still be attempted any number of times (a retreat doesn't cost
  /// anything beyond that run's own unbanked reward); once complete, it
  /// won't offer its reward again.
  final List<String> completedZoneIds;

  /// The Rusty Eel's hull as of the last voyage event; -1 means full (a
  /// fresh save, or just repaired). See ship_combat.dart's
  /// buildPlayerShip.
  final int shipHull;

  /// ship_parts.json ids installed aboard the Rusty Eel; a new game starts
  /// with the ballista.
  final List<String> shipPartIds;

  /// Parts bought (or won) and taken off the Eel to make room for another
  /// (v1.185): they wait at the Harbor and go back on for nothing.
  final List<String> storedShipPartIds;

  /// The Eel's looks (ship_looks.json): the id worn in each category
  /// (`hull`, `sail`, `figurehead`, `ensign`); a category with none wears
  /// its default. Cosmetic only.
  final Map<String, String> shipLooks;

  /// Looks bought or won, which stay the player's whichever is worn.
  final List<String> ownedShipLooks;

  /// The ships.json hull the Eel is built on (v1.228): the sloop she starts
  /// on, or one the shipwright has rebuilt her on.
  final String shipHullId;

  /// Hulls built so far: going back to one costs nothing.
  final List<String> ownedHullIds;

  /// ports.json id the boat is moored at; empty means the home port.
  final String currentPortId;

  /// Every port the boat has made landfall at, append-only.
  final List<String> visitedPortIds;

  /// Pieces of the Shroud (the "Void Banner" item, `void_banner` in
  /// items.json) actually recovered so far — the mechanical thread behind
  /// the "heirloom cut into pieces" story arc. Permanent, append-only, like
  /// [completedQuestIds]. Granted by a quest's own `grantsBannerPieceId`
  /// (see [completeQuest]) rather than any generic reward field, since
  /// which quests grant a piece is a narrative decision, not a gameplay
  /// one.
  final List<String> bannerPiecesCollected;

  /// Lifetime count of each enemy defeated (enemyId -> times beaten),
  /// incremented in [PlayerSessionNotifier.applyCombatResult]'s win path.
  /// Backs Kill-type quest objectives (see quest_objectives.dart) —
  /// lifetime rather than "since the quest was accepted" by default: a
  /// single-kill objective on a foe the player already beat gives
  /// immediate credit instead of a purely bureaucratic second kill. A
  /// bounty with `countFromAccept` counts from [questKillBaselines].
  final Map<String, int> enemyKillCounts;

  /// [enemyKillCounts] as they stood when each quest was accepted (quest id
  /// -> enemy id -> kills): a `countFromAccept` Kill objective (a bounty
  /// for several of a common foe) counts only kills made since. Quests
  /// accepted before v1.162 have none and count lifetime kills.
  final Map<String, Map<String, int>> questKillBaselines;

  /// The camp's bounty board (see contracts.dart): the contracts posted
  /// and not yet claimed, the chapter they went up in, and how many boards
  /// have been posted this run (for fresh ids).
  final List<Contract> contracts;
  final int contractsChapter;
  final int contractBoards;

  /// What the crew knows of each sea beast (enemy_ships.json id -> state):
  /// seen, signs of it, the wounds it carries, slain (see sea_beasts.dart).
  final Map<String, BeastState> seaBeasts;

  /// Defeats each boss has dealt the party this run (enemy id -> losses):
  /// Resolve reads it back as a stacking bonus against that boss (see
  /// party_bonus.dart). Reset with everything else on a new game.
  final Map<String, int> bossDefeatCounts;

  /// Quest ids grandfathered past objective-completion gating entirely —
  /// populated once, automatically, the first time a save from before this
  /// field existed loads (see [fromJson]), from whatever was in
  /// [activeQuestIds] at that moment. Without this, a save already holding
  /// an active quest whose objective was satisfied before this feature
  /// shipped (so never got logged) would suddenly find that quest
  /// permanently uncompletable.
  final List<String> grandfatheredQuestIds;

  /// NPC ids the player has talked to at least once (see npcs.json /
  /// NpcDetailScreen) — permanent, append-only, like [completedQuestIds].
  /// Backs Talk-type quest objectives whose `targetNPCID` names one of
  /// these (see quest_objectives.dart).
  final List<String> talkedToNpcIds;

  /// Roguelike skill-upgrade currency — earned 1:1 alongside XP (see
  /// [PlayerSessionNotifier._applyXp]), spent via [PlayerSessionNotifier.
  /// upgradeSkillTier] to raise an already-unlocked skill's tier. Unlike
  /// [skillPoints] (which unlocks new skills), this only powers up skills
  /// you already have. Reset to 0 on permadeath, alongside [unlockedSkillIds]
  /// and [skillTiers] — the whole build starts over each life.
  final int skillEssence;

  /// skillId -> tier (0 = just unlocked, up to [maxSkillTier] in
  /// combat_engine.dart). Only skills present here have been upgraded past
  /// their base numbers; an unlocked skill with no entry is tier 0. Reset to
  /// {} on permadeath along with [unlockedSkillIds].
  final Map<String, int> skillTiers;

  /// Cures every active status effect (Poison/Stun/Weaken) off the player
  /// on use — see [FightScreen]'s antidote button. A separate counter from
  /// [potionCount], mirroring its own plumbing exactly (a starting count
  /// from game_config.json, no other way to gain more yet).
  final int antidoteCount;

  /// Consecutive Wooden spoils chests (see loot_box.dart) -- each one
  /// raises the next chest's fortune roll a little, so a cold streak
  /// can't run forever. Reset by any Silver-or-better chest.
  final int lootPityStreak;

  /// The last few spoils-chest drops, weighted down in the next chest so
  /// the same piece of gear doesn't come up fight after fight.
  final List<String> recentLootIds;

  /// The party's current mana, spent on spells in a fight (see
  /// [knownSpellIds]) and restored by a die's `Mana` faces, a rest, or a
  /// new game. Carries over between fights exactly like [currentHealth];
  /// never above [maxMana].
  final int mana;

  /// Spells the player can cast (spells.json ids) -- the profession's
  /// starting spells plus every spellbook bought since. Reset to the
  /// starting spells on permadeath, like [unlockedSkillIds].
  final List<String> knownSpellIds;

  /// How many times this save has finished the story and gone round again
  /// -- 0 on a first run. Every enemy is scaled by `newGamePlusMultiplier`
  /// of it (see combat_engine.dart), and the ending screen offers the
  /// next cycle.
  final int newGamePlusCycle;

  /// What the previous cycle hands the next character: a share of its
  /// gold, every die it owned and every spell it knew. Banked by
  /// `PlayerSessionNotifier.beginNewGamePlus`, kept through the reset at
  /// character creation, and spent (added onto the new character, then
  /// cleared) by `startNewGame`.
  final int legacyGold;
  final List<String> legacyDiceIds;
  final List<String> legacySpellIds;

  /// Where each item first came into the pack (item id -> place and
  /// chapter, v1.204, see item_origin.dart): recorded by every way an item
  /// enters the inventory, on the first acquisition only, and read by the
  /// inventory's detail dialog ("Yours since the Lower Town, chapter 1").
  /// Cleared with the pack on permadeath.
  final Map<String, ItemOrigin> itemOrigins;

  bool get hasLegacy =>
      legacyGold > 0 || legacyDiceIds.isNotEmpty || legacySpellIds.isNotEmpty;

  /// The mana pool's size -- see `maxManaFor` in spells.dart.
  int get maxMana => maxManaFor(wisdom: wisdom) + perkEffects.maxMana;

  int get xpToNextLevel => level * 100;

  /// This session with its companion flags (`ally_<id>`, `devoted_<id>`,
  /// see approval.dart's withCompanionFlags) in step with the roster; this
  /// very session when they already are. The notifier applies it to every
  /// state it takes, a loaded save included, so an old save with a Devoted
  /// companion gets its `devoted_` flag on load.
  PlayerSession withCompanionFlagsSynced() {
    final synced = withCompanionFlags(flags, {
      for (final ally in recruitedAllies) ally.companionId: ally.approval,
    });
    return identical(synced, flags) ? this : copyWith(flags: synced);
  }

  /// Who wears [itemId]: [playerWearerId] for the player and each recruited
  /// ally's companion id.
  List<String> wearersOf(String itemId) => [
        if (equippedItemIds.contains(itemId)) playerWearerId,
        for (final ally in recruitedAllies)
          if (ally.equippedItemIds.contains(itemId)) ally.companionId,
      ];

  /// Copies of [itemId] in the shared pack that [wearerId] could put on:
  /// the pack's copies less those worn by anyone else. One copy is worn by
  /// one character at a time.
  int freeCopiesOf(String itemId, {required String wearerId}) {
    final copies = inventoryItemIds.where((id) => id == itemId).length;
    final wornElsewhere =
        wearersOf(itemId).where((wearer) => wearer != wearerId).length;
    return copies - wornElsewhere;
  }

  String get alignmentLabel {
    if (alignmentScore >= 20) return 'Good';
    if (alignmentScore <= -20) return 'Evil';
    return 'Neutral';
  }

  bool meetsRequirements({
    int reqGold = 0,
    int? reqAlignmentScore,
    int? reqAlignmentMax,
    List<String> reqFlags = const [],
    int reqCharisma = 0,
  }) {
    if (gold < reqGold) return false;
    if (reqAlignmentScore != null && alignmentScore < reqAlignmentScore) {
      return false;
    }
    if (reqAlignmentMax != null && alignmentScore > reqAlignmentMax) {
      return false;
    }
    // Only a node that actually asks for Charisma gates on it -- with the
    // default of 0 this would otherwise lock every flag/gold/alignment-gated
    // node for a negative-Charisma race (Orc -2, Voidkin -1).
    if (reqCharisma > 0 && charisma < reqCharisma) return false;
    for (final flag in reqFlags) {
      if (!flags.contains(flag)) return false;
    }
    return true;
  }

  PlayerSession copyWith({
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
    int? maxSkillSlots,
    List<String>? flags,
    List<String>? activeQuestIds,
    List<String>? completedQuestIds,
    List<String>? inventoryItemIds,
    List<String>? equippedItemIds,
    List<String>? unlockedSkillIds,
    List<String>? unlockedShopIds,
    List<String>? unlockedQuestIds,
    List<String>? unlockedEnemyIds,
    Map<String, Map<String, String>>? diceSkillAssignments,
    String? raceId,
    String? professionId,
    List<String>? ownedDiceIds,
    String? equippedDiceId,
    int? xpEarnedThisRun,
    Map<String, int>? shopPurchaseCounts,
    String? characterName,
    String? trackedQuestId,
    String? masteredBranchId,
    Map<String, String>? shopUnlockNodeIds,
    List<String>? seenShopIds,
    List<String>? seenQuestIds,
    List<String>? seenEnemyIds,
    List<String>? seenNpcIds,
    List<String>? readSceneKeys,
    List<String>? seenEchoKeys,
    List<String>? seenFightTipIds,
    Map<String, String>? seenTownRulers,
    int? provisions,
    int? day,
    int? watch,
    int? clockChapter,
    int? chapterStartDay,
    int? sellswordFights,
    int? blessingFights,
    String? blessingClan,
    int? templeMendDay,
    int? seaRemarkChapter,
    Map<String, int>? templeStandingChapters,
    int? alignmentRollsSinceAmbush,
    DetourPacing? detourPacing,
    List<String>? specIds,
    int? runSeed,
    Map<String, DieUpgrades>? diceUpgrades,
    List<AllyState>? recruitedAllies,
    List<String>? activeAllyIds,
    String? reserveAllyId,
    List<String>? lostAllyIds,
    List<String>? departedAllyIds,
    Map<String, int>? perkRanks,
    List<HeldSign>? heldSigns,
    List<OfferTicket>? pendingOffers,
    ClanOffer? clanOffer,
    bool clearClanOffer = false,
    Map<String, int>? trainingTaken,
    List<StatPickOffer>? statPickOffer,
    int? rerollCharges,
    int? banishCharges,
    int? raiseCharges,
    int? raiseProgress,
    List<RollBan>? rollBans,
    int? rollNonce,
    Map<String, Map<String, int>>? statSources,
    List<RiskCurse>? riskCurses,
    List<String>? tomePicks,
    List<String>? heldTitleIds,
    String? activeTitleId,
    List<String>? swornBoonIds,
    int? chapterOffersThrough,
    int? titanBlood,
    Map<String, int>? patronFavour,
    List<String>? signPatronsThisLife,
    List<String>? patronsMet,
    List<String>? acknowledgedFeatures,
    PoliticsState? politics,
    List<String>? builtHouseIds,
    List<String>? townOrder,
    List<String>? unlockedAchievementIds,
    List<String>? completedZoneIds,
    List<String>? bannerPiecesCollected,
    int? shipHull,
    List<String>? shipPartIds,
    List<String>? storedShipPartIds,
    Map<String, String>? shipLooks,
    List<String>? ownedShipLooks,
    String? shipHullId,
    List<String>? ownedHullIds,
    String? currentPortId,
    List<String>? visitedPortIds,
    Map<String, int>? enemyKillCounts,
    Map<String, Map<String, int>>? questKillBaselines,
    List<Contract>? contracts,
    int? contractsChapter,
    int? contractBoards,
    Map<String, BeastState>? seaBeasts,
    Map<String, int>? bossDefeatCounts,
    List<String>? grandfatheredQuestIds,
    List<String>? talkedToNpcIds,
    int? skillEssence,
    Map<String, int>? skillTiers,
    int? antidoteCount,
    int? lootPityStreak,
    List<String>? recentLootIds,
    int? mana,
    List<String>? knownSpellIds,
    int? newGamePlusCycle,
    int? legacyGold,
    List<String>? legacyDiceIds,
    List<String>? legacySpellIds,
    Map<String, ItemOrigin>? itemOrigins,
  }) {
    return PlayerSession(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      gold: gold ?? this.gold,
      alignmentScore: alignmentScore ?? this.alignmentScore,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      baseDamage: baseDamage ?? this.baseDamage,
      baseArmor: baseArmor ?? this.baseArmor,
      luck: luck ?? this.luck,
      charisma: charisma ?? this.charisma,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      perception: perception ?? this.perception,
      potionCount: potionCount ?? this.potionCount,
      statPoints: statPoints ?? this.statPoints,
      maxSkillSlots: maxSkillSlots ?? this.maxSkillSlots,
      flags: flags ?? this.flags,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      equippedItemIds: equippedItemIds ?? this.equippedItemIds,
      unlockedSkillIds: unlockedSkillIds ?? this.unlockedSkillIds,
      unlockedShopIds: unlockedShopIds ?? this.unlockedShopIds,
      unlockedQuestIds: unlockedQuestIds ?? this.unlockedQuestIds,
      unlockedEnemyIds: unlockedEnemyIds ?? this.unlockedEnemyIds,
      diceSkillAssignments: diceSkillAssignments ?? this.diceSkillAssignments,
      raceId: raceId ?? this.raceId,
      professionId: professionId ?? this.professionId,
      ownedDiceIds: ownedDiceIds ?? this.ownedDiceIds,
      equippedDiceId: equippedDiceId ?? this.equippedDiceId,
      xpEarnedThisRun: xpEarnedThisRun ?? this.xpEarnedThisRun,
      shopPurchaseCounts: shopPurchaseCounts ?? this.shopPurchaseCounts,
      characterName: characterName ?? this.characterName,
      trackedQuestId: trackedQuestId ?? this.trackedQuestId,
      masteredBranchId: masteredBranchId ?? this.masteredBranchId,
      shopUnlockNodeIds: shopUnlockNodeIds ?? this.shopUnlockNodeIds,
      seenShopIds: seenShopIds ?? this.seenShopIds,
      seenQuestIds: seenQuestIds ?? this.seenQuestIds,
      seenEnemyIds: seenEnemyIds ?? this.seenEnemyIds,
      seenNpcIds: seenNpcIds ?? this.seenNpcIds,
      readSceneKeys: readSceneKeys ?? this.readSceneKeys,
      seenEchoKeys: seenEchoKeys ?? this.seenEchoKeys,
      seenFightTipIds: seenFightTipIds ?? this.seenFightTipIds,
      seenTownRulers: seenTownRulers ?? this.seenTownRulers,
      provisions: provisions ?? this.provisions,
      day: day ?? this.day,
      watch: watch ?? this.watch,
      clockChapter: clockChapter ?? this.clockChapter,
      chapterStartDay: chapterStartDay ?? this.chapterStartDay,
      sellswordFights: sellswordFights ?? this.sellswordFights,
      blessingFights: blessingFights ?? this.blessingFights,
      blessingClan: blessingClan ?? this.blessingClan,
      templeMendDay: templeMendDay ?? this.templeMendDay,
      seaRemarkChapter: seaRemarkChapter ?? this.seaRemarkChapter,
      templeStandingChapters:
          templeStandingChapters ?? this.templeStandingChapters,
      alignmentRollsSinceAmbush:
          alignmentRollsSinceAmbush ?? this.alignmentRollsSinceAmbush,
      detourPacing: detourPacing ?? this.detourPacing,
      specIds: specIds ?? this.specIds,
      runSeed: runSeed ?? this.runSeed,
      diceUpgrades: diceUpgrades ?? this.diceUpgrades,
      recruitedAllies: recruitedAllies ?? this.recruitedAllies,
      activeAllyIds: activeAllyIds ?? this.activeAllyIds,
      reserveAllyId: reserveAllyId ?? this.reserveAllyId,
      lostAllyIds: lostAllyIds ?? this.lostAllyIds,
      departedAllyIds: departedAllyIds ?? this.departedAllyIds,
      perkRanks: perkRanks ?? this.perkRanks,
      heldSigns: heldSigns ?? this.heldSigns,
      pendingOffers: pendingOffers ?? this.pendingOffers,
      clanOffer: clearClanOffer ? null : clanOffer ?? this.clanOffer,
      trainingTaken: trainingTaken ?? this.trainingTaken,
      statPickOffer: statPickOffer ?? this.statPickOffer,
      rerollCharges: rerollCharges ?? this.rerollCharges,
      banishCharges: banishCharges ?? this.banishCharges,
      raiseCharges: raiseCharges ?? this.raiseCharges,
      raiseProgress: raiseProgress ?? this.raiseProgress,
      rollBans: rollBans ?? this.rollBans,
      rollNonce: rollNonce ?? this.rollNonce,
      statSources: statSources ?? this.statSources,
      riskCurses: riskCurses ?? this.riskCurses,
      tomePicks: tomePicks ?? this.tomePicks,
      heldTitleIds: heldTitleIds ?? this.heldTitleIds,
      activeTitleId: activeTitleId ?? this.activeTitleId,
      swornBoonIds: swornBoonIds ?? this.swornBoonIds,
      chapterOffersThrough: chapterOffersThrough ?? this.chapterOffersThrough,
      titanBlood: titanBlood ?? this.titanBlood,
      patronFavour: patronFavour ?? this.patronFavour,
      signPatronsThisLife: signPatronsThisLife ?? this.signPatronsThisLife,
      patronsMet: patronsMet ?? this.patronsMet,
      acknowledgedFeatures: acknowledgedFeatures ?? this.acknowledgedFeatures,
      politics: politics ?? this.politics,
      builtHouseIds: builtHouseIds ?? this.builtHouseIds,
      townOrder: townOrder ?? this.townOrder,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      completedZoneIds: completedZoneIds ?? this.completedZoneIds,
      shipHull: shipHull ?? this.shipHull,
      shipPartIds: shipPartIds ?? this.shipPartIds,
      storedShipPartIds: storedShipPartIds ?? this.storedShipPartIds,
      shipLooks: shipLooks ?? this.shipLooks,
      ownedShipLooks: ownedShipLooks ?? this.ownedShipLooks,
      shipHullId: shipHullId ?? this.shipHullId,
      ownedHullIds: ownedHullIds ?? this.ownedHullIds,
      currentPortId: currentPortId ?? this.currentPortId,
      visitedPortIds: visitedPortIds ?? this.visitedPortIds,
      bannerPiecesCollected:
          bannerPiecesCollected ?? this.bannerPiecesCollected,
      enemyKillCounts: enemyKillCounts ?? this.enemyKillCounts,
      questKillBaselines: questKillBaselines ?? this.questKillBaselines,
      contracts: contracts ?? this.contracts,
      contractsChapter: contractsChapter ?? this.contractsChapter,
      contractBoards: contractBoards ?? this.contractBoards,
      seaBeasts: seaBeasts ?? this.seaBeasts,
      bossDefeatCounts: bossDefeatCounts ?? this.bossDefeatCounts,
      grandfatheredQuestIds:
          grandfatheredQuestIds ?? this.grandfatheredQuestIds,
      talkedToNpcIds: talkedToNpcIds ?? this.talkedToNpcIds,
      skillEssence: skillEssence ?? this.skillEssence,
      skillTiers: skillTiers ?? this.skillTiers,
      antidoteCount: antidoteCount ?? this.antidoteCount,
      lootPityStreak: lootPityStreak ?? this.lootPityStreak,
      recentLootIds: recentLootIds ?? this.recentLootIds,
      mana: mana ?? this.mana,
      knownSpellIds: knownSpellIds ?? this.knownSpellIds,
      newGamePlusCycle: newGamePlusCycle ?? this.newGamePlusCycle,
      legacyGold: legacyGold ?? this.legacyGold,
      legacyDiceIds: legacyDiceIds ?? this.legacyDiceIds,
      legacySpellIds: legacySpellIds ?? this.legacySpellIds,
      itemOrigins: itemOrigins ?? this.itemOrigins,
    );
  }

  /// This session with [gains] (ability -> points) added: the abilities,
  /// and what they bring (stat_rules.dart) -- +1 base damage a point of the
  /// profession's damage stat, +5 max health (healed as much) a point of
  /// Constitution. Every way an ability is gained goes through here: a
  /// pick, the patron's gifts, the formative memories.
  PlayerSession withAbilityGains(Map<String, int> gains) {
    if (gains.isEmpty) return this;
    int gain(String stat) => gains[stat] ?? 0;
    final effects = abilityGainEffects(gains, professionId);
    return copyWith(
      strength: strength + gain('strength'),
      dexterity: dexterity + gain('dexterity'),
      constitution: constitution + gain('constitution'),
      intelligence: intelligence + gain('intelligence'),
      wisdom: wisdom + gain('wisdom'),
      perception: perception + gain('perception'),
      luck: luck + gain('luck'),
      charisma: charisma + gain('charisma'),
      baseDamage: baseDamage + effects.baseDamage,
      maxHealth: max(1, maxHealth + effects.maxHealth),
      currentHealth: max(1, currentHealth + effects.maxHealth),
    );
  }

  /// [withAbilityGains] of [gains] and [maxHealth] more max health (healed
  /// as much), written in the stat ledger ([statSources]) under [kind]
  /// (stat_ledger.dart's ledgerKinds) and [id] -- with the base damage and
  /// max health the points bring, so statBreakdown can tell them apart.
  PlayerSession withSourcedGains(
    String kind,
    String id,
    Map<String, int> gains, {
    int maxHealth = 0,
  }) {
    final effects = abilityGainEffects(gains, professionId);
    var s = withAbilityGains(gains);
    if (maxHealth != 0) {
      s = s.copyWith(
        maxHealth: s.maxHealth + maxHealth,
        currentHealth: s.currentHealth + maxHealth,
      );
    }
    return s.copyWith(
      statSources: ledgerWith(statSources, kind, id, {
        ...gains,
        'baseDamage': effects.baseDamage,
        'maxHealth': effects.maxHealth + maxHealth,
      }),
    );
  }

  /// This session with [faction]'s curse (risky_gifts.dart): [amount]
  /// points off [stat] for [riskyCurseLevels] levels, in the ledger as
  /// `curse:<faction>`. A second curse from the same clan restarts the
  /// count instead of stacking.
  PlayerSession withCurse(String faction, String stat, int amount) {
    final old = riskCurses.where((c) => c.clan == faction).firstOrNull;
    var s = this;
    if (old != null) {
      s = s.withSourcedGains(ledgerCurse, faction, {old.stat: old.amount});
    }
    s = s.withSourcedGains(ledgerCurse, faction, {stat: -amount});
    return s.copyWith(riskCurses: [
      for (final c in s.riskCurses)
        if (c.clan != faction) c,
      RiskCurse(
          clan: faction,
          stat: stat,
          amount: amount,
          untilLevel: level + riskyCurseLevels),
    ]);
  }

  /// This session with the curses whose level is reached lifted: their
  /// points given back, the ledger's row cancelled.
  PlayerSession withCursesEnded() {
    final ended = [
      for (final c in riskCurses)
        if (level >= c.untilLevel) c,
    ];
    if (ended.isEmpty) return this;
    var s = this;
    for (final c in ended) {
      s = s.withSourcedGains(ledgerCurse, c.clan, {c.stat: c.amount});
    }
    return s.copyWith(riskCurses: [
      for (final c in riskCurses)
        if (level < c.untilLevel) c,
    ]);
  }

  Map<String, dynamic> toJson() => {
        'saveVersion': playerSessionSaveVersion,
        diceDataVersionKey: diceDataVersion,
        'level': level,
        'currentXP': currentXP,
        'gold': gold,
        'alignmentScore': alignmentScore,
        'maxHealth': maxHealth,
        'currentHealth': currentHealth,
        'baseDamage': baseDamage,
        'baseArmor': baseArmor,
        'luck': luck,
        'charisma': charisma,
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'perception': perception,
        'potionCount': potionCount,
        'statPoints': statPoints,
        'maxSkillSlots': maxSkillSlots,
        'flags': flags,
        'activeQuestIds': activeQuestIds,
        'completedQuestIds': completedQuestIds,
        'inventoryItemIds': inventoryItemIds,
        'equippedItemIds': equippedItemIds,
        'unlockedSkillIds': unlockedSkillIds,
        'unlockedShopIds': unlockedShopIds,
        'unlockedQuestIds': unlockedQuestIds,
        'unlockedEnemyIds': unlockedEnemyIds,
        'diceSkillAssignments': diceSkillAssignments,
        'raceId': raceId,
        'professionId': professionId,
        'ownedDiceIds': ownedDiceIds,
        'equippedDiceId': equippedDiceId,
        'xpEarnedThisRun': xpEarnedThisRun,
        'shopPurchaseCounts': shopPurchaseCounts,
        'characterName': characterName,
        'trackedQuestId': trackedQuestId,
        'masteredBranchId': masteredBranchId,
        'shopUnlockNodeIds': shopUnlockNodeIds,
        'seenShopIds': seenShopIds,
        'seenQuestIds': seenQuestIds,
        'seenEnemyIds': seenEnemyIds,
        'seenNpcIds': seenNpcIds,
        'readSceneKeys': readSceneKeys,
        'seenEchoKeys': seenEchoKeys,
        'seenFightTipIds': seenFightTipIds,
        'seenTownRulers': seenTownRulers,
        'provisions': provisions,
        'day': day,
        'watch': watch,
        'clockChapter': clockChapter,
        'chapterStartDay': chapterStartDay,
        'sellswordFights': sellswordFights,
        if (blessingFights != 0) 'blessingFights': blessingFights,
        if (blessingClan.isNotEmpty) 'blessingClan': blessingClan,
        if (templeMendDay != 0) 'templeMendDay': templeMendDay,
        if (seaRemarkChapter != 0) 'seaRemarkChapter': seaRemarkChapter,
        if (templeStandingChapters.isNotEmpty)
          'templeStandingChapters': templeStandingChapters,
        'alignmentRollsSinceAmbush': alignmentRollsSinceAmbush,
        'detourPacing': detourPacing.toJson(),
        'specIds': specIds,
        'runSeed': runSeed,
        'diceUpgrades': diceUpgradesToJson(diceUpgrades),
        'recruitedAllies': recruitedAllies.map((a) => a.toJson()).toList(),
        'activeAllyIds': activeAllyIds,
        'reserveAllyId': reserveAllyId,
        'lostAllyIds': lostAllyIds,
        'departedAllyIds': departedAllyIds,
        'perkRanks': perkRanks,
        'heldSigns': [for (final h in heldSigns) h.toJson()],
        'pendingOffers': [for (final t in pendingOffers) t.toJson()],
        'clanOffer': clanOffer?.toJson(),
        'trainingTaken': trainingTaken,
        if (statPickOffer.isNotEmpty)
          'statPickOffer': [for (final o in statPickOffer) o.toJson()],
        if (rerollCharges != 0) 'rerollCharges': rerollCharges,
        if (banishCharges != 0) 'banishCharges': banishCharges,
        if (raiseCharges != 0) 'raiseCharges': raiseCharges,
        if (raiseProgress != 0) 'raiseProgress': raiseProgress,
        if (rollBans.isNotEmpty)
          'rollBans': [for (final b in rollBans) b.toJson()],
        if (rollNonce != 0) 'rollNonce': rollNonce,
        if (statSources.isNotEmpty) 'statSources': statSources,
        if (riskCurses.isNotEmpty)
          'riskCurses': [for (final c in riskCurses) c.toJson()],
        if (tomePicks.isNotEmpty) 'tomePicks': tomePicks,
        'heldTitleIds': heldTitleIds,
        'activeTitleId': activeTitleId,
        'swornBoonIds': swornBoonIds,
        'chapterOffersThrough': chapterOffersThrough,
        'titanBlood': titanBlood,
        'patronFavour': patronFavour,
        'signPatronsThisLife': signPatronsThisLife,
        'patronsMet': patronsMet,
        if (acknowledgedFeatures.isNotEmpty)
          'acknowledgedFeatures': acknowledgedFeatures,
        'politics': politics.toJson(),
        'builtHouseIds': builtHouseIds,
        'townOrder': townOrder,
        'unlockedAchievementIds': unlockedAchievementIds,
        'completedZoneIds': completedZoneIds,
        'shipHull': shipHull,
        'shipPartIds': shipPartIds,
        'storedShipPartIds': storedShipPartIds,
        'shipLooks': shipLooks,
        'ownedShipLooks': ownedShipLooks,
        'shipHullId': shipHullId,
        'ownedHullIds': ownedHullIds,
        'currentPortId': currentPortId,
        'visitedPortIds': visitedPortIds,
        'bannerPiecesCollected': bannerPiecesCollected,
        'enemyKillCounts': enemyKillCounts,
        'questKillBaselines': questKillBaselines,
        'contracts': [for (final c in contracts) c.toJson()],
        'contractsChapter': contractsChapter,
        'contractBoards': contractBoards,
        'seaBeasts': {
          for (final e in seaBeasts.entries) e.key: e.value.toJson(),
        },
        'bossDefeatCounts': bossDefeatCounts,
        'grandfatheredQuestIds': grandfatheredQuestIds,
        'talkedToNpcIds': talkedToNpcIds,
        'skillEssence': skillEssence,
        'skillTiers': skillTiers,
        'antidoteCount': antidoteCount,
        'lootPityStreak': lootPityStreak,
        'recentLootIds': recentLootIds,
        'mana': mana,
        'knownSpellIds': knownSpellIds,
        'newGamePlusCycle': newGamePlusCycle,
        'legacyGold': legacyGold,
        'legacyDiceIds': legacyDiceIds,
        'legacySpellIds': legacySpellIds,
        'itemOrigins': {
          for (final e in itemOrigins.entries) e.key: e.value.toJson(),
        },
      };

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    // A save from before the stat scale, once on the small scale
    // (stat_scale_save.dart).
    json = rescaledSave(json, allyFullHealth: AllyState.fullHealthSentinel);
    // A save from before the dice sizes: picks and Hammersmith work on a
    // die that shrank move with their faces, or come back
    // (dice_sizes_save.dart).
    json = resizedDiceSave(json);
    // A save from before the cap of three fighters (v1.664) may have three
    // companions seated (the Barracks Annex's old seat): the first two stay,
    // the third waits in the reserve seat the Annex now gives, or on the
    // bench when it is taken. Nobody is lost.
    final seated = [
      for (final id in (json['activeAllyIds'] as List?) ?? const [])
        id.toString(),
    ];
    final savedReserve = json['reserveAllyId']?.toString() ?? '';
    final reserve = savedReserve.isEmpty && seated.length > basePartyCapacity
        ? seated[basePartyCapacity]
        : savedReserve;
    // A save with no 'enemyKillCounts' key at all predates objective
    // tracking entirely -- every quest already active in it was accepted
    // (and may well have already been earned) under the old, ungated
    // rules, so grandfather all of them past the new gate rather than
    // strand the save on quests it can no longer prove completion for.
    // A save that already has the key (even an empty {}) went through
    // this exact branch once before and must never repeat it, or a
    // Complete-quest'd-and-moved-on run would re-grandfather every quest
    // accepted since.
    final isPreObjectiveTrackingSave = !json.containsKey('enemyKillCounts');
    return PlayerSession(
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXP: (json['currentXP'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: (json['alignmentScore'] as num?)?.toInt() ?? 0,
      maxHealth: (json['maxHealth'] as num?)?.toInt() ?? 20,
      currentHealth: (json['currentHealth'] as num?)?.toInt() ?? 20,
      baseDamage: (json['baseDamage'] as num?)?.toInt() ?? 2,
      baseArmor: (json['baseArmor'] as num?)?.toInt() ?? 0,
      luck: (json['luck'] as num?)?.toInt() ?? 0,
      charisma: (json['charisma'] as num?)?.toInt() ?? 0,
      strength: (json['strength'] as num?)?.toInt() ?? 0,
      dexterity: (json['dexterity'] as num?)?.toInt() ?? 0,
      constitution: (json['constitution'] as num?)?.toInt() ?? 0,
      intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
      wisdom: (json['wisdom'] as num?)?.toInt() ?? 0,
      perception: (json['perception'] as num?)?.toInt() ?? 0,
      potionCount: (json['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: (json['statPoints'] as num?)?.toInt() ?? 0,
      maxSkillSlots: (json['maxSkillSlots'] as num?)?.toInt() ?? 3,
      // Houses built before the story read them back get their flag here.
      flags: {
        ...?(json['flags'] as List?)?.map((e) => e.toString()),
        ...?(json['builtHouseIds'] as List?)
            ?.map((e) => houseFlag(e.toString())),
        if (legacyHarbourDue(json)) houseFlag(harborHouseId),
        // Quests taken before the accepted flag was set (v1.639).
        ...?(json['activeQuestIds'] as List?)
            ?.map((e) => questAcceptedFlag(e.toString())),
      }.toList(),
      activeQuestIds: (json['activeQuestIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedQuestIds: (json['completedQuestIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      inventoryItemIds: [
        ...?(json['inventoryItemIds'] as List?)?.map((e) => e.toString()),
        // A save from before materials gets, once, a rare material of each
        // tier its story has passed (see legacyMaterialGrant); it is saved
        // with the new version, so it never gets them again.
        if (((json['saveVersion'] as num?)?.toInt() ?? 1) <
            materialsSaveVersion)
          ...legacyMaterialGrant((json['clockChapter'] as num?)?.toInt() ?? 0),
      ],
      equippedItemIds: (json['equippedItemIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockedSkillIds: (json['unlockedSkillIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockedShopIds: (json['unlockedShopIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockedQuestIds: (json['unlockedQuestIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockedEnemyIds: (json['unlockedEnemyIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      diceSkillAssignments: (json['diceSkillAssignments'] as Map?)?.map(
            (diceId, faces) => MapEntry(
              diceId.toString(),
              (faces as Map).map(
                (faceIndex, skillId) =>
                    MapEntry(faceIndex.toString(), skillId.toString()),
              ),
            ),
          ) ??
          const {},
      raceId: json['raceId'] as String? ?? '',
      professionId: json['professionId'] as String? ?? '',
      ownedDiceIds:
          (json['ownedDiceIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      equippedDiceId: json['equippedDiceId'] as String?,
      xpEarnedThisRun: (json['xpEarnedThisRun'] as num?)?.toInt() ?? 0,
      shopPurchaseCounts: (json['shopPurchaseCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      characterName: json['characterName'] as String? ?? '',
      trackedQuestId: json['trackedQuestId'] as String? ?? '',
      masteredBranchId: json['masteredBranchId'] as String? ?? '',
      shopUnlockNodeIds: (json['shopUnlockNodeIds'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
      seenShopIds:
          (json['seenShopIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenQuestIds:
          (json['seenQuestIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenEnemyIds:
          (json['seenEnemyIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenNpcIds:
          (json['seenNpcIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      readSceneKeys:
          (json['readSceneKeys'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenEchoKeys:
          (json['seenEchoKeys'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenFightTipIds: (json['seenFightTipIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      seenTownRulers: {
        for (final e in ((json['seenTownRulers'] as Map?) ?? const {}).entries)
          e.key.toString(): e.value.toString(),
      },
      provisions: (json['provisions'] as num?)?.toInt() ?? provisionsStart,
      day: max(1, (json['day'] as num?)?.toInt() ?? 1),
      watch: ((json['watch'] as num?)?.toInt() ?? 1).clamp(0, 3),
      clockChapter: (json['clockChapter'] as num?)?.toInt() ?? 0,
      chapterStartDay: (json['chapterStartDay'] as num?)?.toInt() ?? 1,
      sellswordFights: (json['sellswordFights'] as num?)?.toInt() ?? 0,
      blessingFights: (json['blessingFights'] as num?)?.toInt() ?? 0,
      blessingClan: json['blessingClan']?.toString() ?? '',
      templeMendDay: (json['templeMendDay'] as num?)?.toInt() ?? 0,
      seaRemarkChapter: (json['seaRemarkChapter'] as num?)?.toInt() ?? 0,
      templeStandingChapters: {
        for (final e
            in ((json['templeStandingChapters'] as Map?) ?? const {}).entries)
          if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      },
      alignmentRollsSinceAmbush:
          (json['alignmentRollsSinceAmbush'] as num?)?.toInt() ??
              hunterCooldownRolls,
      detourPacing: DetourPacing.fromJson(json['detourPacing']),
      specIds: [
        for (final id in (json['specIds'] as List? ?? const [])) id.toString(),
      ],
      runSeed: (json['runSeed'] as num?)?.toInt() ?? 0,
      diceUpgrades: parseDiceUpgrades(json['diceUpgrades']),
      recruitedAllies: (json['recruitedAllies'] as List?)
              ?.map((e) => AllyState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeAllyIds: seated.take(basePartyCapacity).toList(),
      reserveAllyId: reserve,
      lostAllyIds:
          (json['lostAllyIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      departedAllyIds: (json['departedAllyIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      perkRanks: (json['perkRanks'] as Map?)?.map(
            (id, rank) => MapEntry(id.toString(), (rank as num?)?.toInt() ?? 0),
          ) ??
          const {},
      // Saves from before signs hold none.
      heldSigns: [
        for (final raw in (json['heldSigns'] as List?) ?? const [])
          if (raw is Map) HeldSign.fromJson(Map<String, dynamic>.from(raw)),
      ],
      // A save from before the offers (v1.194) is owed one for each skill
      // point it had not spent, each perk and each sign it had not picked;
      // its learned skills, perk ranks and held signs stay as they are.
      pendingOffers: json['pendingOffers'] is List
          ? [
              for (final raw in json['pendingOffers'] as List)
                if (raw is Map)
                  OfferTicket.fromJson(Map<String, dynamic>.from(raw)),
            ]
          : migratedOffers(
              skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
              perkPicks: (json['pendingPerkPicks'] as num?)?.toInt() ?? 0,
              signPicks: (json['pendingSignPicks'] as num?)?.toInt() ?? 0,
            ),
      clanOffer: ClanOffer.tryParse(json['clanOffer']),
      // An old save's `trainingOffer` (the training offers before the stat
      // picks) is ignored: its unspent points are stat picks now.
      statPickOffer: [
        for (final o in (json['statPickOffer'] as List? ?? const []))
          if (o is Map) StatPickOffer.fromJson(o),
      ],
      rerollCharges: (json['rerollCharges'] as num?)?.toInt() ?? 0,
      banishCharges: (json['banishCharges'] as num?)?.toInt() ?? 0,
      raiseCharges: (json['raiseCharges'] as num?)?.toInt() ?? 0,
      raiseProgress: (json['raiseProgress'] as num?)?.toInt() ?? 0,
      rollBans: rollBansFromJson(json['rollBans']),
      rollNonce: (json['rollNonce'] as num?)?.toInt() ?? 0,
      trainingTaken: {
        for (final MapEntry(:key, :value)
            in ((json['trainingTaken'] as Map?) ?? const {}).entries)
          if (value is num) key.toString(): value.toInt(),
      },
      statSources: ledgerFromJson(json['statSources']),
      riskCurses: riskCursesFromJson(json['riskCurses']),
      tomePicks:
          (json['tomePicks'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      heldTitleIds:
          (json['heldTitleIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      activeTitleId: json['activeTitleId']?.toString() ?? '',
      swornBoonIds:
          (json['swornBoonIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      // An old save's chapter so far brought no offer: from the chapter
      // its clock counts, the next ones will.
      chapterOffersThrough: (json['chapterOffersThrough'] as num?)?.toInt() ??
          (json['clockChapter'] as num?)?.toInt() ??
          0,
      titanBlood: (json['titanBlood'] as num?)?.toInt() ?? 0,
      patronFavour: (json['patronFavour'] as Map?)?.map(
            (id, favour) =>
                MapEntry(id.toString(), (favour as num?)?.toInt() ?? 0),
          ) ??
          const {},
      signPatronsThisLife: (json['signPatronsThisLife'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      patronsMet:
          (json['patronsMet'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      acknowledgedFeatures: (json['acknowledgedFeatures'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      // Saves from before the clans stand where every faction starts.
      politics: PoliticsState.fromJson(json['politics']),
      builtHouseIds: [
        ...?(json['builtHouseIds'] as List?)?.map((e) => e.toString()),
        // A save from before the harbour was the player's to build, past
        // the camp's founding, has it built (see legacyHarbourDue).
        if (legacyHarbourDue(json)) harborHouseId,
      ],
      townOrder:
          (json['townOrder'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      unlockedAchievementIds: (json['unlockedAchievementIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedZoneIds: (json['completedZoneIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shipHull: (json['shipHull'] as num?)?.toInt() ?? -1,
      shipPartIds:
          (json['shipPartIds'] as List?)?.map((e) => e.toString()).toList() ??
              const ['ballista'],
      storedShipPartIds: (json['storedShipPartIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shipLooks: {
        for (final entry in ((json['shipLooks'] as Map?) ?? const {}).entries)
          entry.key.toString(): entry.value.toString(),
      },
      ownedShipLooks: (json['ownedShipLooks'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shipHullId: json['shipHullId']?.toString() ?? 'rusty_eel',
      ownedHullIds:
          (json['ownedHullIds'] as List?)?.map((e) => e.toString()).toList() ??
              const ['rusty_eel'],
      currentPortId: json['currentPortId']?.toString() ?? '',
      visitedPortIds: (json['visitedPortIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bannerPiecesCollected: (json['bannerPiecesCollected'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      enemyKillCounts: (json['enemyKillCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      contracts: (json['contracts'] as List?)
              ?.whereType<Map>()
              .map((c) => Contract.fromJson(Map<String, dynamic>.from(c)))
              .toList() ??
          const [],
      contractsChapter: (json['contractsChapter'] as num?)?.toInt() ?? 0,
      contractBoards: (json['contractBoards'] as num?)?.toInt() ?? 0,
      seaBeasts: {
        for (final e in ((json['seaBeasts'] as Map?) ?? const {}).entries)
          if (e.value is Map)
            e.key.toString():
                BeastState.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      questKillBaselines: (json['questKillBaselines'] as Map?)?.map(
            (quest, kills) => MapEntry(
              quest.toString(),
              (kills as Map).map((enemy, count) =>
                  MapEntry(enemy.toString(), (count as num).toInt())),
            ),
          ) ??
          const {},
      bossDefeatCounts: (json['bossDefeatCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      grandfatheredQuestIds: isPreObjectiveTrackingSave
          ? ((json['activeQuestIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [])
          : ((json['grandfatheredQuestIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const []),
      talkedToNpcIds: (json['talkedToNpcIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skillEssence: (json['skillEssence'] as num?)?.toInt() ?? 0,
      skillTiers: (json['skillTiers'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      antidoteCount: (json['antidoteCount'] as num?)?.toInt() ?? 0,
      lootPityStreak: (json['lootPityStreak'] as num?)?.toInt() ?? 0,
      recentLootIds:
          (json['recentLootIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      // A save from before mana existed wakes up with a full pool, the
      // same as a fresh character.
      mana: (json['mana'] as num?)?.toInt() ??
          maxManaFor(
            wisdom: (json['wisdom'] as num?)?.toInt() ?? 0,
          ),
      knownSpellIds:
          (json['knownSpellIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      newGamePlusCycle: (json['newGamePlusCycle'] as num?)?.toInt() ?? 0,
      legacyGold: (json['legacyGold'] as num?)?.toInt() ?? 0,
      legacyDiceIds:
          (json['legacyDiceIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      legacySpellIds: (json['legacySpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      // A save from before v1.204 knows no origins: its items are simply
      // owned, with no "since" line.
      itemOrigins: {
        for (final e in ((json['itemOrigins'] as Map?) ?? const {}).entries)
          if (ItemOrigin.tryParse(e.value) case final origin?)
            e.key.toString(): origin,
      },
    );
  }
}

class PlayerSessionNotifier extends StateNotifier<PlayerSession> {
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

  /// [keepLegacy] carries the New Game+ cycle and its banked legacy (see
  /// [PlayerSession.legacyGold]) through the reset -- the reset that
  /// precedes character creation must not lose what the previous cycle
  /// handed down; an Edit-Mode "start from nothing" reset passes false.
  Future<void> _resetToDefaults(SharedPreferences prefs,
      {bool keepLegacy = true}) async {
    final previous = state;
    Map<String, dynamic> defaults;
    final savedConfig = prefs.getString(_newGameDefaultsPrefsKey);
    if (savedConfig != null) {
      defaults = json.decode(savedConfig) as Map<String, dynamic>;
    } else {
      final raw = await rootBundle.loadString(_newGameDefaultsAssetPath);
      defaults = json.decode(raw) as Map<String, dynamic>;
    }
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
    Map<String, dynamic> defaults;
    final savedConfig = prefs.getString(_newGameDefaultsPrefsKey);
    if (savedConfig != null) {
      defaults = json.decode(savedConfig) as Map<String, dynamic>;
    } else {
      final raw = await rootBundle.loadString(_newGameDefaultsAssetPath);
      defaults = json.decode(raw) as Map<String, dynamic>;
    }

    int bonus(Map<String, dynamic> preset, String key) =>
        (preset[key] as num?)?.toInt() ?? 0;

    final maxHealth = ((defaults['maxHealth'] as num?)?.toInt() ?? 20) +
        bonus(race, 'bonusMaxHealth') +
        bonus(profession, 'bonusMaxHealth');
    final baseDamage = ((defaults['baseDamage'] as num?)?.toInt() ?? 2) +
        bonus(race, 'bonusBaseDamage') +
        bonus(profession, 'bonusBaseDamage');
    final baseArmor = startingArmor(
        ((defaults['baseArmor'] as num?)?.toInt() ?? 0) +
            bonus(race, 'bonusBaseArmor') +
            bonus(profession, 'bonusBaseArmor'));
    final luck = ((defaults['luck'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusLuck') +
        bonus(profession, 'bonusLuck');
    final charisma = ((defaults['charisma'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusCharisma') +
        bonus(profession, 'bonusCharisma');
    final strength = ((defaults['strength'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusStrength') +
        bonus(profession, 'bonusStrength');
    final dexterity = ((defaults['dexterity'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusDexterity') +
        bonus(profession, 'bonusDexterity');
    final constitution = ((defaults['constitution'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusConstitution') +
        bonus(profession, 'bonusConstitution');
    final intelligence = ((defaults['intelligence'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusIntelligence') +
        bonus(profession, 'bonusIntelligence');
    final wisdom = ((defaults['wisdom'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusWisdom') +
        bonus(profession, 'bonusWisdom');
    final perception = ((defaults['perception'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusPerception') +
        bonus(profession, 'bonusPerception');
    final gold = ((defaults['gold'] as num?)?.toInt() ?? 0) +
        bonus(race, 'startingGoldBonus') +
        bonus(profession, 'startingGoldBonus');
    // A profession's starting skill points are offers since v1.194.

    // Race/profession signature skills (and a caster's mana skill) default
    // to isUnlocked: false in the skills db (most skills are locked until
    // earned) but are wired directly into the starting die's faces from
    // the moment a character exists -- so they are unlocked here too, or
    // those faces would just fizzle on the very first roll.
    final starterAssignments = _starterFaceAssignments(race, profession);
    final starterUnlockedSkills = _starterSkillsFor(race, profession);
    final startingDiceId = _startingDiceIdFor(profession);
    final startingSpellIds = _startingSpellIdsFor(profession);
    // A New Game+ character inherits the previous cycle's legacy (see
    // [beginNewGamePlus]): its gold share, every die it owned and every
    // spell it knew.
    final legacy = state;
    final legacyDice = [
      for (final id in legacy.legacyDiceIds)
        if (id != _starterDiceId && id != startingDiceId) id,
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
      gold: gold + legacy.legacyGold,
      alignmentScore: 0,
      maxHealth: maxHealth,
      currentHealth: maxHealth,
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
      mana: maxManaFor(wisdom: wisdom),
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

  /// The one die a new character of [profession] starts with -- its own
  /// `startingDiceId` (a Mage's or Cleric's apprentice die, with its Focus
  /// and Channeling faces) or the starter die. Every profession's starting
  /// die keeps the Profession/Heritage Technique faces at the same indexes
  /// ([_starterDieProfessionFaceIndex]/[_starterDieRaceFaceIndex]).
  static String _startingDiceIdFor(Map<String, dynamic> profession) {
    final id = profession['startingDiceId']?.toString() ?? '';
    return id.isEmpty ? _starterDiceId : id;
  }

  static List<String> _startingSpellIdsFor(Map<String, dynamic> profession) =>
      (profession['startingSpellIds'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const [];

  /// [starterAssignments] under the profession's starting die, the one
  /// die a new character owns.
  static Map<String, Map<String, String>> _starterAssignmentsByDie(
    Map<String, String> starterAssignments,
    String startingDiceId,
  ) =>
      {
        if (starterAssignments.isNotEmpty) startingDiceId: starterAssignments,
      };

  /// The skills a new character of [race] and [profession] knows: the
  /// profession's standard skill, a caster's mana skill (`manaSkillID`:
  /// Channel for a Mage, Prayer for a Cleric) and the race's standard
  /// skill. Nothing from another class: the generic Heavy Blow every open
  /// Skill face falls back to is the only skill everyone shares.
  static List<String> _starterSkillsFor(
      Map<String, dynamic> race, Map<String, dynamic> profession) {
    final ids = [
      profession['standardSkillID']?.toString() ?? '',
      profession['manaSkillID']?.toString() ?? '',
      race['standardSkillID']?.toString() ?? '',
    ];
    return [
      for (final id in ids.toSet())
        if (id.isNotEmpty) id,
    ];
  }

  /// Where the starter skills sit on the starting die: the profession's
  /// technique on the Profession Technique face, the race's on the
  /// Heritage Technique face, and a caster's mana skill on the apprentice
  /// die's Channeling face.
  static Map<String, String> _starterFaceAssignments(
      Map<String, dynamic> race, Map<String, dynamic> profession) {
    final professionSkillId = profession['standardSkillID']?.toString() ?? '';
    final manaSkillId = profession['manaSkillID']?.toString() ?? '';
    final raceSkillId = race['standardSkillID']?.toString() ?? '';
    return {
      if (manaSkillId.isNotEmpty)
        _startingDieManaFaceIndex.toString(): manaSkillId,
      if (professionSkillId.isNotEmpty)
        _starterDieProfessionFaceIndex.toString(): professionSkillId,
      if (raceSkillId.isNotEmpty)
        _starterDieRaceFaceIndex.toString(): raceSkillId,
    };
  }

  /// Sets the character's name — called once from the lock-in dialog right
  /// after character creation (see RaceProfessionScreen), before the
  /// origin-story prompts run.
  Future<void> setCharacterName(String name) async {
    state = state.copyWith(characterName: name.trim());
    await _persist();
  }

  Future<void> _persist() async {
    await _loaded.future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerSessionPrefsKey, json.encode(state.toJson()));
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
    state = _withFirstBanner(state.copyWith(
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
    }
  }

  /// [session] given [itemId] the way a reward is: a potion as charges, a
  /// spellbook read, a tome read on the spot (a Tome of Mastery is one more
  /// offer), anything else to the pack, with [origin] remembered for a
  /// piece new to it (see [PlayerSession.itemOrigins]).
  PlayerSession _withItem(
      PlayerSession session, String itemId, Map<String, dynamic>? item,
      {ItemOrigin? origin}) {
    final charges = consumableChargesFor(itemId, item);
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
    final tome = tomeGrantFor(itemId, item);
    if (tome != null) {
      return session.copyWith(
        statPoints: session.statPoints + tome.statPoints,
        tomePicks: _withTomePicks(session.tomePicks, itemId, tome.statPoints),
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

  /// The chapter a clan change is logged under: [chapter] (pass the
  /// reached chapter, reachedChapterProvider), else the one the world
  /// clock counts, at least 1.
  int _politicsChapter(int? chapter) => chapter ?? max(1, state.clockChapter);

  /// Moves standing with [factionId] by [delta] for [cause] (see
  /// applyStandingChange: the ripple to its allies and rivals, the Sworn
  /// banner, the clamps), logged on [chapter] and today. Returns what
  /// moved, faction by faction.
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

  /// What a story choice's or an intrigue's outcome does to a companion:
  /// this much approval for `disapproves` (and back for `approves`).
  static const int intrigueApprovalShift = 5;

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
              ? intrigueApprovalShift
              : -intrigueApprovalShift;
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
  Random _siegeRandom(int chapter) =>
      Random(state.runSeed * 31 + chapter * 7919 + state.day * 104729);

  /// The sieges run out by today (district_attacks.dart), settled away
  /// from the party: the district taken or held, the news told. Returns
  /// how many were settled.
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
      final charges = consumableChargesFor(rewardItemId, rewardItem);
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
        ..._levelOffers(leveled.levelsGained),
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

  Future<void> buyDice(String diceId, int cost) async {
    if (state.gold < cost || state.ownedDiceIds.contains(diceId)) return;
    state = state.copyWith(
      gold: state.gold - cost,
      ownedDiceIds: [...state.ownedDiceIds, diceId],
    );
    await _persist();
  }

  Future<void> equipDice(String diceId) async {
    if (!state.ownedDiceIds.contains(diceId) ||
        state.equippedDiceId == diceId) {
      return;
    }
    state = state.copyWith(equippedDiceId: diceId);
    await _persist();
  }

  /// Recuts [first] and [second], two d8s the player owns, into the tally
  /// die at the Skillwright (dice_weave.dart): both are spent, their face
  /// picks with them, and the Hammersmith's work on them is paid back
  /// (smithingRefundFor). The tally die is equipped when one of the two
  /// was. False, and nothing done, when [canWeaveDice] says no.
  Future<bool> weaveDice(String first, String second,
      {required Map<String, dynamic> dice}) async {
    if (!canWeaveDice(first, second,
        owned: state.ownedDiceIds,
        builtHouseIds: state.builtHouseIds,
        dice: dice)) {
      return false;
    }
    final spent = {first, second};
    var gold = state.gold;
    final inventory = [...state.inventoryItemIds];
    for (final id in spent) {
      for (final work in (state.diceUpgrades[id] ?? const {}).values) {
        final refund = smithingRefundFor(work);
        gold += refund.gold;
        for (var i = 0; i < refund.iron; i++) {
          inventory.add(ironOreId);
        }
        for (var i = 0; i < refund.trophies; i++) {
          inventory.add(eliteTrophyId);
        }
      }
    }
    state = state.copyWith(
      gold: gold,
      inventoryItemIds: inventory,
      ownedDiceIds: [
        for (final id in state.ownedDiceIds)
          if (!spent.contains(id)) id,
        tallyDieId,
      ],
      equippedDiceId: spent.contains(state.equippedDiceId) ? tallyDieId : null,
      diceSkillAssignments: {
        for (final entry in state.diceSkillAssignments.entries)
          if (!spent.contains(entry.key)) entry.key: entry.value,
      },
      diceUpgrades: {
        for (final entry in state.diceUpgrades.entries)
          if (!spent.contains(entry.key)) entry.key: entry.value,
      },
    );
    await _persist();
    return true;
  }

  /// Spends one fate coin from the pack (fate_coin.dart), for a check
  /// rolled again. False when the pack holds none.
  Future<bool> spendFateCoin() async {
    final left = withFateCoinSpent(state.inventoryItemIds);
    if (left == null) return false;
    state = state.copyWith(inventoryItemIds: left);
    await _persist();
    return true;
  }

  /// Buys [itemId] from [shopId]. Shops have a fixed stock per item
  /// ([stockLimit], from the shop's stockQuantities data) that this tracks
  /// via [PlayerSession.shopPurchaseCounts]: gear never replenishes, and
  /// potions and scrolls restock each chapter (their [stockKey] carries the
  /// chapter, see stockKeyFor).
  Future<void> buyItem(
    String shopId,
    String itemId,
    int cost,
    int stockLimit, {
    Map<String, dynamic>? item,
    String? stockKey,
    ItemOrigin? origin,
  }) async {
    // A restocking consumable is counted per chapter (see stockKeyFor).
    final key = stockKey ?? '$shopId::$itemId';
    final purchased = state.shopPurchaseCounts[key] ?? 0;
    if (state.gold < cost || purchased >= stockLimit) return;
    // A spellbook is read on the spot: the spell joins [knownSpellIds] and
    // the book never enters the inventory. One the player already knows
    // is refused outright (the shop screen also greys it out).
    final taughtSpellId = spellbookSpellIdFor(item);
    if (taughtSpellId != null) {
      if (state.knownSpellIds.contains(taughtSpellId)) return;
      state = state.copyWith(
        gold: state.gold - cost,
        knownSpellIds: [...state.knownSpellIds, taughtSpellId],
        shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
      );
      await _persist();
      return;
    }
    // A tome is read on the spot, as a looted one is: its points are the
    // purchase, and nothing enters the pack.
    final tome = tomeGrantFor(itemId, item);
    if (tome != null) {
      state = state.copyWith(
        gold: state.gold - cost,
        statPoints: state.statPoints + tome.statPoints,
        tomePicks: _withTomePicks(state.tomePicks, itemId, tome.statPoints),
        pendingOffers: [...state.pendingOffers, ...tome.offers],
        shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
      );
      await _persist();
      return;
    }
    final charges = consumableChargesFor(itemId, item);
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: charges == null
          ? [...state.inventoryItemIds, itemId]
          : state.inventoryItemIds,
      itemOrigins: charges == null
          ? withItemOrigins(state.itemOrigins, [itemId], origin)
          : state.itemOrigins,
      potionCount: state.potionCount + (charges?.potions ?? 0),
      antidoteCount: state.antidoteCount + (charges?.antidotes ?? 0),
      shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
    );
    await _persist();
  }

  /// Sells one copy of [itemId] for [price]. Only a copy nobody wears can
  /// go; one sold where it is stocked goes back on that shop's shelf
  /// ([shopId]). Returns false when there is no free copy to sell.
  Future<bool> sellItem(String itemId,
      {required int price, String? shopId}) async {
    if (state.freeCopiesOf(itemId, wearerId: '') <= 0) return false;
    final remaining = [...state.inventoryItemIds]..remove(itemId);
    final counts = {...state.shopPurchaseCounts};
    if (shopId != null) {
      final key = '$shopId::$itemId';
      final bought = counts[key] ?? 0;
      if (bought > 0) counts[key] = bought - 1;
    }
    state = state.copyWith(
      inventoryItemIds: remaining,
      gold: state.gold + max(0, price),
      shopPurchaseCounts: counts,
    );
    await _persist();
    return true;
  }

  /// Getting away from a fight: [goldLost] spills and the wounds stay --
  /// the player's health is saved as it stands (at least 1), with the
  /// mana left. No loss is recorded and nothing is won.
  Future<void> applyRetreat({
    required int hpAfter,
    required int goldLost,
    int? manaAfter,
    bool dropPotion = false,
  }) async {
    state = state.copyWith(
      gold: max(0, state.gold - goldLost),
      potionCount: dropPotion ? max(0, state.potionCount - 1) : null,
      currentHealth: max(1, min(state.maxHealth, hpAfter)),
      mana: manaAfter ?? state.mana,
    );
    await _persist();
  }

  /// Whether the pack holds what forging [item] takes: its `craftGold` and
  /// every `craftMaterials` count (see [craftMaterialsFor]).
  bool canCraft(Map<String, dynamic>? item) {
    if (item == null) return false;
    final gold = (item['craftGold'] as num?)?.toInt() ?? 0;
    if (state.gold < gold) return false;
    return craftMaterialsFor(item).entries.every((m) =>
        state.inventoryItemIds.where((id) => id == m.key).length >= m.value);
  }

  /// Forges [itemId] from [item]'s recipe (docs/proposals/forge-roll.md):
  /// its gold and materials leave the pack, the forge rolls its d20 on
  /// [random] with [modifiers] (forgeModifiersProvider's; a dwarf's +2
  /// alone when null), and the piece enters the pack under the tier's id
  /// (forgedVariantId: `<itemId>@fine`, the plain id for Sound). A flawed
  /// roll costs nothing more. Returns the roll, or null if something is
  /// missing.
  Future<ForgeRoll?> craftItem(String itemId, Map<String, dynamic>? item,
      {ItemOrigin? origin,
      Random? random,
      List<ForgeModifier>? modifiers}) async {
    if (!canCraft(item)) return null;
    final roll = rollForge(
      random: random ?? Random(),
      modifiers: modifiers ?? forgeModifiersFor(raceId: state.raceId),
    );
    final pieceId = forgedVariantId(baseItemIdOf(itemId), roll.tier);
    final remaining = [...state.inventoryItemIds];
    for (final m in craftMaterialsFor(item).entries) {
      for (var i = 0; i < m.value; i++) {
        remaining.remove(m.key);
      }
    }
    state = state.copyWith(
      gold: state.gold - ((item!['craftGold'] as num?)?.toInt() ?? 0),
      inventoryItemIds: [...remaining, pieceId],
      itemOrigins: withItemOrigins(state.itemOrigins, [pieceId], origin),
    );
    await _persist();
    return roll;
  }

  /// Flips a fate coin on the forge [roll] that made [pieceId] (a Flawed
  /// one, fate_coin.dart): the coin is spent, the forge's d20 rolls once
  /// more on [random] with the same modifiers, and the piece in the pack
  /// takes the new tier's id. Returns the new roll, or null when the pack
  /// holds no coin or no such piece.
  Future<ForgeRoll?> reforgeWithFateCoin(String pieceId, ForgeRoll roll,
      {Random? random}) async {
    final left = withFateCoinSpent(state.inventoryItemIds);
    if (left == null || !left.contains(pieceId)) return null;
    final again = reforgedRoll(roll, random ?? Random());
    state = _withPieceReforged(
        state.copyWith(inventoryItemIds: left), pieceId, again.tier);
    await _persist();
    return again;
  }

  /// Whether a camp house can roll the forge again now: the Bone-Caster's
  /// Hut stands and has a Reroll charge (camp_rolls.dart).
  bool get canRerollForge => _has(RollPower.reroll, state.rerollCharges);

  /// The Bone-Caster's Hut's Reroll on the forge [roll] that made [pieceId]
  /// (docs/proposals/forge-roll.md, "the camp's roll houses"): one charge
  /// spent, the forge's d20 rolled once more on [random] with the same
  /// modifiers, and the piece in the pack takes the new tier's id. Returns
  /// the new roll, or null with no charge or no such piece.
  Future<ForgeRoll?> rerollForge(String pieceId, ForgeRoll roll,
      {Random? random}) async {
    if (!canRerollForge || !state.inventoryItemIds.contains(pieceId)) {
      return null;
    }
    final again = rerolledForge(roll, random ?? Random());
    state = _withPieceReforged(
        state.copyWith(rerollCharges: state.rerollCharges - 1),
        pieceId,
        again.tier);
    await _persist();
    return again;
  }

  /// [s] with the piece [pieceId] in its pack swapped for the same base
  /// forged at [tier] (its origin kept).
  PlayerSession _withPieceReforged(
      PlayerSession s, String pieceId, ForgeTier tier) {
    final pack = [...s.inventoryItemIds];
    final newId = forgedVariantId(baseItemIdOf(pieceId), tier);
    pack[pack.indexOf(pieceId)] = newId;
    return s.copyWith(
      inventoryItemIds: pack,
      itemOrigins:
          withItemOrigins(s.itemOrigins, [newId], s.itemOrigins[pieceId]),
    );
  }

  /// Whether the pack and purse cover [cost] (see face_smithing.dart).
  bool canPaySmithing(SmithingCost cost) {
    int carried(String id) =>
        state.inventoryItemIds.where((i) => i == id).length;
    final trophies = trophyItemIds.fold<int>(0, (n, id) => n + carried(id));
    return state.gold >= cost.gold &&
        carried(ironOreId) >= cost.iron &&
        trophies >= cost.trophies;
  }

  /// The Hammersmith works face [faceIndex] of die [dieId] (whose dice.json
  /// faces are [faces]), the player's own or [companionId]'s signature die:
  /// [work] is paid for (gold, iron ore, a trophy -- an Elite Mark first)
  /// and kept on that die (see [PlayerSession.upgradesOfDie]). A Temper
  /// takes [element], an inscription [keyword], a Recast [recastType].
  /// Returns false when the work doesn't fit the face or can't be paid for.
  Future<bool> smithFace({
    required String dieId,
    required int faceIndex,
    required List<Map<String, dynamic>> faces,
    required SmithingWork work,
    String? companionId,
    String? element,
    FaceKeyword? keyword,
    String? recastType,
  }) async {
    if (faceIndex < 0 || faceIndex >= faces.length) return false;
    final dieUpgrades = state.upgradesOfDie(dieId, companionId: companionId) ??
        const <String, FaceUpgrade>{};
    final current = dieUpgrades[faceIndex.toString()] ?? FaceUpgrade.none;
    final face = faces[faceIndex];
    if (!canSmith(work, face, current)) return false;
    final FaceUpgrade next;
    switch (work) {
      case SmithingWork.hone:
        next = current.copyWith(hones: current.hones + 1);
      case SmithingWork.temper:
        if (element == null ||
            !temperableElements(face, current).contains(element)) {
          return false;
        }
        next = current.copyWith(element: element);
      case SmithingWork.inscribe:
        if (keyword == null ||
            !inscribableKeywords(face, current).contains(keyword)) {
          return false;
        }
        next = current.copyWith(keyword: keyword);
      case SmithingWork.recast:
        final baseType = face['type']?.toString() ?? '';
        final from = current.recastType ?? baseType;
        if (recastType == null ||
            !smithableBasicTypes.contains(recastType) ||
            recastType == from) {
          return false;
        }
        // Back to what the die made it clears the Recast; a Temper only
        // stays on an Attack face.
        next = FaceUpgrade(
          hones: current.hones,
          element: recastType == 'Attack' ? current.element : null,
          keyword: current.keyword,
          recastType: recastType == baseType ? null : recastType,
        );
    }
    final cost = smithingCostFor(work, current);
    if (!canPaySmithing(cost)) return false;
    final remaining = [...state.inventoryItemIds];
    for (var i = 0; i < cost.iron; i++) {
      remaining.remove(ironOreId);
    }
    var trophiesLeft = cost.trophies;
    for (final id in trophyItemIds) {
      while (trophiesLeft > 0 && remaining.remove(id)) {
        trophiesLeft--;
      }
    }
    // A companion's work an older save kept under the die's id alone (on a
    // die the player doesn't own) moves under their own key with this.
    final movesOver =
        companionId != null && !state.ownedDiceIds.contains(dieId);
    state = state.copyWith(
      gold: state.gold - cost.gold,
      inventoryItemIds: remaining,
      diceUpgrades: {
        for (final entry in state.diceUpgrades.entries)
          if (!movesOver || entry.key != dieId) entry.key: entry.value,
        dieUpgradesKey(dieId, companionId: companionId): {
          ...dieUpgrades,
          faceIndex.toString(): next,
        },
      },
    );
    await _persist();
    return true;
  }

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

  /// Reads one carried copy of the tome [itemId] -- for a tome that reached
  /// the pack before tomes were read on the spot. No-op for anything that
  /// isn't a carried tome.
  Future<void> readTome(String itemId, Map<String, dynamic>? item) async {
    final tome = tomeGrantFor(itemId, item);
    if (tome == null || !state.inventoryItemIds.contains(itemId)) return;
    final remaining = [...state.inventoryItemIds]..remove(itemId);
    state = state.copyWith(
      inventoryItemIds: remaining,
      statPoints: state.statPoints + tome.statPoints,
      tomePicks: _withTomePicks(state.tomePicks, itemId, tome.statPoints),
      pendingOffers: [...state.pendingOffers, ...tome.offers],
    );
    await _persist();
  }

  /// Equips [itemId]. When [slot] is given, any other equipped item sharing
  /// that slot (per [items], a map of itemId -> item record) is unequipped
  /// first, so only one item per slot is ever equipped at once.
  Future<void> equipItem(
    String itemId, {
    String? slot,
    Map<String, dynamic>? items,
  }) async {
    if (state.equippedItemIds.contains(itemId)) return;
    // No copy left that someone else isn't already wearing.
    if (state.freeCopiesOf(itemId, wearerId: playerWearerId) <= 0) return;
    var newEquipped = state.equippedItemIds;
    if (slot != null && slot.isNotEmpty && items != null) {
      newEquipped = state.equippedItemIds.where((id) {
        final other = items[id] as Map<String, dynamic>?;
        return (other?['equipSlot']?.toString() ?? '') != slot;
      }).toList();
    }
    state = state.copyWith(equippedItemIds: [...newEquipped, itemId]);
    await _persist();
  }

  Future<void> unequipItem(String itemId) async {
    if (!state.equippedItemIds.contains(itemId)) return;
    state = state.copyWith(
      equippedItemIds:
          state.equippedItemIds.where((id) => id != itemId).toList(),
    );
    await _persist();
  }

  // --- Companions (allies) & houses -------------------------------------

  /// Grants a companion permanently once their recruit quest completes — see
  /// the `rewardAllyId` handling at the Quests tab's completion call site.
  /// No-ops if already recruited (recruiting is a one-time story reward).
  /// [race]/[profession] are the companion's own race/profession records
  /// (looked up via their companions.json entry), used only to seed their
  /// starting unlocked skills exactly like [startNewGame] does for the
  /// player — an ally's actual combat stats are always derived live, never
  /// stored (see [AllyState]'s class doc).
  Future<void> recruitAlly(
    String companionId, {
    Map<String, dynamic>? race,
    Map<String, dynamic>? profession,
    Map<String, dynamic>? companion,
    Map<String, dynamic> dice = const {},
    Map<String, dynamic> houses = const {},
    String? requiredHouseId,
  }) async {
    if (state.recruitedAllies.any((a) => a.companionId == companionId)) return;
    if (state.lostAllyIds.contains(companionId)) return;
    if (state.departedAllyIds.contains(companionId)) return;
    final starterUnlocked = companionStarterSkillIds(
      race: race,
      profession: profession,
      companion: companion,
      dice: dice,
    );
    // A freshly recruited companion joins the fight immediately, up to
    // capacity -- Camp is where the roster is *managed*, not a
    // precondition for a new ally actually helping in combat (and Camp
    // itself may not even be unlocked yet when an early companion is
    // recruited).
    final houseBuilt = requiredHouseId == null ||
        requiredHouseId.isEmpty ||
        state.builtHouseIds.contains(requiredHouseId);
    final autoActivate = houseBuilt &&
        state.activeAllyIds.length <
            partyCapacityFor(state.builtHouseIds, houses);
    // The seats full, a free reserve seat (the Barracks Annex) takes them.
    final toReserve = houseBuilt &&
        !autoActivate &&
        state.reserveAlly == null &&
        reserveSeatsFor(state.builtHouseIds, houses) > 0;
    state = state.copyWith(
      recruitedAllies: [
        ...state.recruitedAllies,
        AllyState(
          companionId: companionId,
          currentHealth: AllyState.fullHealthSentinel,
          unlockedSkillIds: starterUnlocked,
        ),
      ],
      activeAllyIds: autoActivate
          ? [...state.activeAllyIds, companionId]
          : state.activeAllyIds,
      reserveAllyId: toReserve ? companionId : null,
    );
    await _persist();
  }

  /// Whether the camp may bench [companionId] ([companions]: the
  /// companions.json table): not Vica when she is the last one seated.
  bool canBench(String companionId, Map<String, dynamic> companions) =>
      canBenchCompanion(companionId,
          active: state.activeAllyIds, companions: companions);

  /// Recruits the story's companions (story_companions.dart) the story has
  /// reached: one of their join scenes is in [visited]. A save already past
  /// Vica's scene gets her this way too, on load. [races], [professions],
  /// [dice] and [houses] as for [recruitAlly]. Returns who joined.
  Future<List<String>> recruitStoryCompanions(
    Iterable<String> visited, {
    required Map<String, dynamic> companions,
    Map<String, dynamic> races = const {},
    Map<String, dynamic> professions = const {},
    Map<String, dynamic> dice = const {},
    Map<String, dynamic> houses = const {},
  }) async {
    final due = storyRecruitsDue(companions,
        visited: visited,
        recruited: [for (final a in state.recruitedAllies) a.companionId],
        gone: [...state.lostAllyIds, ...state.departedAllyIds]);
    for (final id in due) {
      final companion = companions[id] as Map<String, dynamic>?;
      await recruitAlly(
        id,
        race: races[companion?['raceId']?.toString() ?? '']
            as Map<String, dynamic>?,
        profession: professions[companion?['professionId']?.toString() ?? '']
            as Map<String, dynamic>?,
        companion: companion,
        dice: dice,
        houses: houses,
        requiredHouseId: companion?['requiredHouseId']?.toString(),
      );
    }
    return due;
  }

  /// Adds or removes [companionId] from the active fight party.
  /// [partyCapacity] and [requiredHouseId] (that companion's own gate, if
  /// any, from companions.json) are enforced here as well as in the Camp
  /// UI, matching how e.g. [buyItem] re-checks affordability itself.
  Future<void> setAllyActive(
    String companionId,
    bool active, {
    required int partyCapacity,
    String? requiredHouseId,
    Map<String, dynamic> companions = const {},
  }) async {
    if (!state.recruitedAllies.any((a) => a.companionId == companionId)) return;
    if (!active) {
      if (!state.activeAllyIds.contains(companionId)) return;
      // Vica is benched only by seating someone else; anyone else benched
      // to an empty party leaves her seat to her (story_companions.dart).
      if (!canBench(companionId, companions)) return;
      state = state.copyWith(
        activeAllyIds: withPermanentSeated(
          state.activeAllyIds.where((id) => id != companionId).toList(),
          recruited: [
            for (final a in state.recruitedAllies)
              if (a.companionId != companionId) a.companionId,
          ],
          companions: companions,
        ),
      );
      await _persist();
      return;
    }
    if (state.activeAllyIds.contains(companionId)) return;
    // Never more than three fighters (v1.664), whatever the caller passed.
    if (state.activeAllyIds.length >= min(partyCapacity, basePartyCapacity)) {
      return;
    }
    if (requiredHouseId != null &&
        requiredHouseId.isNotEmpty &&
        !state.builtHouseIds.contains(requiredHouseId)) {
      return;
    }
    state = state.copyWith(
      activeAllyIds: [...state.activeAllyIds, companionId],
      // Seated, they leave the reserve seat.
      reserveAllyId: state.reserveAllyId == companionId ? '' : null,
    );
    await _persist();
  }

  /// Puts [companionId] in the reserve seat (the user's pick, v1.664), or
  /// empties it with ''. Refused without a reserve seat ([reserveSeats],
  /// [reserveSeatsFor]), for a companion not recruited or seated already,
  /// or whose own house ([requiredHouseId]) isn't built.
  Future<void> setReserveAlly(
    String companionId, {
    required int reserveSeats,
    String? requiredHouseId,
  }) async {
    if (companionId.isNotEmpty) {
      if (reserveSeats <= 0) return;
      if (!state.recruitedAllies.any((a) => a.companionId == companionId)) {
        return;
      }
      if (state.activeAllyIds.contains(companionId)) return;
      if (requiredHouseId != null &&
          requiredHouseId.isNotEmpty &&
          !state.builtHouseIds.contains(requiredHouseId)) {
        return;
      }
    }
    if (state.reserveAllyId == companionId) return;
    state = state.copyWith(reserveAllyId: companionId);
    await _persist();
  }

  /// Spends gold to build a camp house. No-ops if already built or
  /// unaffordable. [unlocksShopId] (the house's own `unlocksShopId` field,
  /// e.g. Hammersmith opening its Forge) is passed through to
  /// [unlockContent] so building the house and gaining access to its shop
  /// are one atomic action, exactly like [recruitAlly]'s starter-skill
  /// unlock is one action rather than two.
  /// Spends [cost] and marks [houseId] built, unlocking [unlocksShopId] if
  /// any. A no-op if unaffordable (gold, or the [materialCost] in the pack,
  /// see materials.dart), already built, or any of [requiredFlags]
  /// (houses.json) is still unset -- the camp's late workshops wait on the
  /// zones that supply them -- unless one of [unlockedByFlags] is set.
  ///
  /// A house still locked (see camp_works.dart) is refused too: one whose
  /// tier comes in a chapter after [chapter] ([fromChapter], the tier's
  /// first), or whose companion ([requiredAllyId]) is not recruited.
  Future<void> buildHouse(String houseId, int cost,
      {String? unlocksShopId,
      List<String> requiredFlags = const [],
      List<String> unlockedByFlags = const [],
      Map<String, int> materialCost = const {},
      int fromChapter = 1,
      int? chapter,
      String? requiredAllyId,
      String? rollPower}) async {
    if (state.gold < cost || state.builtHouseIds.contains(houseId)) return;
    if (chapter != null && chapter < fromChapter) return;
    if ((requiredAllyId ?? '').isNotEmpty &&
        !state.recruitedAllies.any((a) => a.companionId == requiredAllyId)) {
      return;
    }
    if (!unlockedByFlags.any(state.flags.contains) &&
        requiredFlags.any((flag) => !state.flags.contains(flag))) {
      return;
    }
    if (missingMaterials(state.inventoryItemIds, materialCost).isNotEmpty) {
      return;
    }
    // The story reads the camp's buildings back through a flag per house
    // (see houseFlag).
    final flag = houseFlag(houseId);
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: withoutMaterials(state.inventoryItemIds, materialCost),
      builtHouseIds: [...state.builtHouseIds, houseId],
      flags: state.flags.contains(flag) ? state.flags : [...state.flags, flag],
      townOrder: [...state.townPieces, houseId],
    );
    // A roll house (camp_rolls.dart) comes with its charges.
    switch (rollPowerNamed(rollPower) ?? rollPowerHouses[houseId]) {
      case RollPower.reroll:
        state =
            state.copyWith(rerollCharges: chargesWhenBuilt(RollPower.reroll));
      case RollPower.banish:
        state =
            state.copyWith(banishCharges: chargesWhenBuilt(RollPower.banish));
      case RollPower.raise:
        state = state.copyWith(raiseCharges: chargesWhenBuilt(RollPower.raise));
      case null:
        break;
    }
    await _persist();
    if (unlocksShopId != null && unlocksShopId.isNotEmpty) {
      await unlockContent(shopId: unlocksShopId);
    }
  }

  /// Spends [cost] on a town addition ([type], one of
  /// `cliff_town.dart`'s additions) and raises it on the cliff. Additions
  /// are the town's own: they add rooms and lights, no bonuses. A no-op
  /// if unaffordable, or when the town already holds as many as it may
  /// (see townAdditionLimit).
  Future<void> buildTownAddition(String type, int cost) async {
    if (state.gold < cost) return;
    final limit = townAdditionLimitOf(type,
        pieces: state.townPieces, houseCount: state.builtHouseIds.length);
    if (limit.atLimit) return;
    state = state.copyWith(
      gold: state.gold - cost,
      townOrder: [...state.townPieces, type],
    );
    await _persist();
  }

  // --- Expedition zones ----------------------------------------------------

  /// Banks a zone's completion reward — the payoff for clearing every
  /// expedition in [zoneId] in one run without retreating (see
  /// [ExpeditionScreen]). No-ops if already banked (a zone pays out once).
  /// Ally rewards aren't handled here, mirroring [completeQuest]'s own
  /// `rewardAllyId` convention: the caller looks up the companion's
  /// race/profession and calls [recruitAlly] itself.
  Future<void> completeZone(
    String zoneId, {
    int rewardGold = 0,
    String? rewardItemId,
    String? rewardDiceId,
    String? rewardFlag,
    Map<String, int> rewardMaterials = const {},
    ItemOrigin? origin,
  }) async {
    if (state.completedZoneIds.contains(zoneId)) return;
    final newInventory = [
      ...state.inventoryItemIds,
      // The zone's materials (zones.json rewardMaterials).
      for (final e in rewardMaterials.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];
    var newOrigins = state.itemOrigins;
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      newInventory.add(rewardItemId);
      newOrigins = withItemOrigins(newOrigins, [rewardItemId], origin);
    }
    var newOwnedDice = state.ownedDiceIds;
    if (rewardDiceId != null &&
        rewardDiceId.isNotEmpty &&
        !newOwnedDice.contains(rewardDiceId)) {
      newOwnedDice = [...newOwnedDice, rewardDiceId];
    }
    var newFlags = state.flags;
    if (rewardFlag != null &&
        rewardFlag.isNotEmpty &&
        !newFlags.contains(rewardFlag)) {
      newFlags = [...newFlags, rewardFlag];
    }
    state = state.copyWith(
      gold: state.gold + rewardGold,
      inventoryItemIds: newInventory,
      itemOrigins: newOrigins,
      ownedDiceIds: newOwnedDice,
      flags: newFlags,
      completedZoneIds: [...state.completedZoneIds, zoneId],
    );
    await _persist();
  }

  /// Stores the Rusty Eel's hull after a voyage event or ship battle
  /// (-1 = full).
  Future<void> setShipHull(int hull) async {
    state = state.copyWith(shipHull: hull);
    await _persist();
  }

  /// Buys and fits a ship part; false (and nothing spent) if it is already
  /// aboard or unaffordable. Slot room is the caller's check (see
  /// ship_combat.dart's canInstallPart); [replacing] come off to make it,
  /// and wait at the Harbor (see [storedShipPartIds]). A stored part goes
  /// back on for nothing, whatever [cost] says.
  Future<bool> installShipPart(String partId, int cost,
      {List<String> replacing = const []}) async {
    final stored = state.storedShipPartIds.contains(partId);
    final price = stored ? 0 : cost;
    if (state.shipPartIds.contains(partId) || state.gold < price) return false;
    final removed = [
      for (final id in state.shipPartIds)
        if (replacing.contains(id)) id,
    ];
    state = state.copyWith(
      gold: state.gold - price,
      // Repainting the sail takes the old sigil off (see sail_powers.dart).
      shipPartIds: [
        ...state.shipPartIds.where((id) => !replacing.contains(id)),
        partId,
      ],
      storedShipPartIds: [
        for (final id in state.storedShipPartIds)
          if (id != partId) id,
        ...removed,
      ],
    );
    await _persist();
    return true;
  }

  /// Writes what the crew knows of the sea beast [beastId] (see
  /// sea_beasts.dart), from [update] of what they knew.
  Future<void> updateSeaBeast(
      String beastId, BeastState Function(BeastState beast) update) async {
    state = state.copyWith(seaBeasts: {
      ...state.seaBeasts,
      beastId: update(state.seaBeasts[beastId] ?? const BeastState()),
    });
    await _persist();
  }

  /// Puts a part won at sea in the Harbor's store (no room aboard for it
  /// now): it goes on later for nothing (see [installShipPart]).
  Future<void> storeShipPart(String partId) async {
    if (state.shipPartIds.contains(partId) ||
        state.storedShipPartIds.contains(partId)) {
      return;
    }
    state =
        state.copyWith(storedShipPartIds: [...state.storedShipPartIds, partId]);
    await _persist();
  }

  /// Rebuilds the Eel on the hull [hullId] (see ship_forms.dart), paying
  /// [cost] unless she has been built on it before; false (and nothing
  /// changed) if it is her hull already or unaffordable. [toStore] are the
  /// parts the new hull has no slot for: they wait at the Harbor (see
  /// [storedShipPartIds]). [hull] is the hull she is rebuilt with, -1 for
  /// full.
  Future<bool> rebuildHull(String hullId, int cost,
      {List<String> toStore = const [], int hull = -1}) async {
    if (state.shipHullId == hullId) return false;
    final owned = state.ownedHullIds.contains(hullId);
    final price = owned ? 0 : cost;
    if (state.gold < price) return false;
    state = state.copyWith(
      gold: state.gold - price,
      shipHullId: hullId,
      ownedHullIds:
          owned ? state.ownedHullIds : [...state.ownedHullIds, hullId],
      shipPartIds: [
        for (final id in state.shipPartIds)
          if (!toStore.contains(id)) id,
      ],
      storedShipPartIds: [
        ...state.storedShipPartIds,
        for (final id in toStore)
          if (!state.storedShipPartIds.contains(id)) id,
      ],
      shipHull: hull,
    );
    await _persist();
    return true;
  }

  /// Wears the look [lookId] in its [category], buying it first for [cost]
  /// when it is not yet owned; false (and nothing changed) if it cannot be
  /// afforded. A default look is always owned, so [cost] 0 is the caller's
  /// way to wear one.
  Future<bool> wearShipLook(String category, String lookId, int cost) async {
    final owned = state.ownedShipLooks.contains(lookId);
    final price = owned ? 0 : cost;
    if (state.gold < price) return false;
    state = state.copyWith(
      gold: state.gold - price,
      shipLooks: {...state.shipLooks, category: lookId},
      ownedShipLooks:
          owned ? state.ownedShipLooks : [...state.ownedShipLooks, lookId],
    );
    await _persist();
    return true;
  }

  /// Pays [cost] to restore the hull to full; false if unaffordable.
  Future<bool> repairShip(int cost) async {
    if (state.gold < cost) return false;
    state = state.copyWith(gold: state.gold - cost, shipHull: -1);
    await _persist();
    return true;
  }

  /// Landfall: the boat is now moored at [portId].
  Future<void> arriveAtPort(String portId) async {
    state = state.copyWith(
      currentPortId: portId,
      visitedPortIds: state.visitedPortIds.contains(portId)
          ? state.visitedPortIds
          : [...state.visitedPortIds, portId],
    );
    await _persist();
  }

  /// Runs [update] against the named ally's current [AllyState] and writes
  /// the result back into [recruitedAllies] — the shared plumbing every
  /// per-ally mutator below uses, since an ally lives inside a list rather
  /// than getting its own top-level provider.
  Future<void> _updateAlly(
    String companionId,
    AllyState Function(AllyState ally) update,
  ) async {
    final index =
        state.recruitedAllies.indexWhere((a) => a.companionId == companionId);
    if (index == -1) return;
    final newAllies = [...state.recruitedAllies];
    newAllies[index] = update(newAllies[index]);
    state = state.copyWith(recruitedAllies: newAllies);
    await _persist();
  }

  /// Equips [itemId] onto ally [companionId] — the ally equivalent of
  /// [equipItem]. Items are drawn from the same shared [inventoryItemIds]
  /// pool the player equips from (this game has one inventory, not one per
  /// character); equipping doesn't remove the item from that pool, matching
  /// [equipItem]'s own existing behavior.
  Future<void> equipAllyItem(
    String companionId,
    String itemId, {
    String? slot,
    Map<String, dynamic>? items,
  }) async {
    if (state.freeCopiesOf(itemId, wearerId: companionId) <= 0) return;
    await _updateAlly(companionId, (ally) {
      if (ally.equippedItemIds.contains(itemId)) return ally;
      var newEquipped = ally.equippedItemIds;
      if (slot != null && slot.isNotEmpty && items != null) {
        newEquipped = ally.equippedItemIds.where((id) {
          final other = items[id] as Map<String, dynamic>?;
          return (other?['equipSlot']?.toString() ?? '') != slot;
        }).toList();
      }
      return ally.copyWith(equippedItemIds: [...newEquipped, itemId]);
    });
  }

  Future<void> unequipAllyItem(String companionId, String itemId) async {
    await _updateAlly(
      companionId,
      (ally) => ally.copyWith(
        equippedItemIds:
            ally.equippedItemIds.where((id) => id != itemId).toList(),
      ),
    );
  }

  /// The ally equivalent of [unlockSkill] — spends one of the ally's own
  /// [AllyState.skillPoints].
  Future<void> unlockAllySkill(String companionId, String skillId) async {
    await _updateAlly(companionId, (ally) {
      if (ally.skillPoints <= 0 || ally.unlockedSkillIds.contains(skillId)) {
        return ally;
      }
      return ally.copyWith(
        skillPoints: ally.skillPoints - 1,
        unlockedSkillIds: [...ally.unlockedSkillIds, skillId],
      );
    });
  }

  /// The ally equivalent of [assignSkillToDiceFace]/[clearDiceFaceSkill] —
  /// flat by faceIndex rather than dice-keyed, since an ally only ever has
  /// their one fixed signature die (see [AllyState.diceSkillAssignments]).
  Future<void> assignSkillToAllyDiceFace(
      String companionId, int faceIndex, String skillId) async {
    await _updateAlly(companionId, (ally) {
      final updated = Map<String, String>.from(ally.diceSkillAssignments);
      updated[faceIndex.toString()] = skillId;
      return ally.copyWith(diceSkillAssignments: updated);
    });
  }

  Future<void> clearAllyDiceFaceSkill(String companionId, int faceIndex) async {
    await _updateAlly(companionId, (ally) {
      if (!ally.diceSkillAssignments.containsKey(faceIndex.toString())) {
        return ally;
      }
      final updated = Map<String, String>.from(ally.diceSkillAssignments)
        ..remove(faceIndex.toString());
      return ally.copyWith(diceSkillAssignments: updated);
    });
  }

  /// Persists an ally's health at the end of a fight (see [FightScreen]) —
  /// unlike the player, a lost fight simply doesn't call this, so an ally's
  /// mid-fight damage is never persisted on a loss (mirrors the player not
  /// being HP-punished on a loss either, via the existing full-heal-on-loss
  /// behavior in [applyCombatResult]).
  Future<void> applyAllyCombatResult(String companionId,
      {required int hpAfter}) async {
    await _updateAlly(
      companionId,
      (ally) => ally.copyWith(currentHealth: hpAfter < 0 ? 0 : hpAfter),
    );
  }

  /// Heals the player and every recruited ally (active or benched) to full
  /// — the Camp screen's Rest action.
  Future<void> healPartyToFull() async {
    state = state.copyWith(
      currentHealth: state.maxHealth,
      mana: state.maxMana,
      recruitedAllies: [
        for (final ally in state.recruitedAllies)
          ally.copyWith(currentHealth: AllyState.fullHealthSentinel),
      ],
    );
    await _persist();
  }

  // --- The world clock ---------------------------------------------------

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

  /// Runs [xpGain] through the level-up threshold (`level * 100` XP each),
  /// applying every level gained: [levelStatPicks] stat pick and
  /// [levelHealthGain] max health (stat_rules.dart; base damage grows only
  /// with the damage stat), and an offer, which the callers add: see
  /// [_levelOffers]. Shared by
  /// [applyCombatResult] and [completeQuest] so a quest's XP reward levels
  /// the player up exactly like combat XP does.
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

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
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
      final tome = tomeGrantFor(itemId, item);
      if (tome != null) {
        statPointsGained += tome.statPoints;
        tomePicks = _withTomePicks(tomePicks, itemId, tome.statPoints);
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
      final charges = consumableChargesFor(itemId, item);
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
          ..._levelOffers(leveled.levelsGained),
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
    state = _withFirstBanner(state);
    await _persist();
    return leveled.leveledUp;
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

    final starterUnlockedSkills = _starterSkillsFor(race, profession);
    final starterAssignments = _starterFaceAssignments(race, profession);

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
          : startingOffersFor(profession),
      clearClanOffer: true,
      heldTitleIds: const [],
      activeTitleId: '',
      swornBoonIds: const [],
      diceSkillAssignments: _starterAssignmentsByDie(
          starterAssignments, _startingDiceIdFor(profession)),
      knownSpellIds: _startingSpellIdsFor(profession),
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
final campRollsProvider =
    Provider<CampRolls>((ref) => campRollsOf(ref.watch(playerSessionProvider)));

/// The wards on the road running now, each clan with its roads left
/// (road_wards.dart), for the Journey's mark (`ward_mark`).
final roadWardsProvider = Provider<List<RoadWard>>(
    (ref) => roadWardsOf(ref.watch(playerSessionProvider).rollBans));

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
