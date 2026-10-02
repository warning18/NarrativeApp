import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../combat/combat_engine.dart' show maxSkillTier, skillTierUpgradeCost;
import '../combat/face_keywords.dart' show FaceKeyword;
import '../combat/face_smithing.dart';
import '../combat/sea_beasts.dart' show BeastState;
import '../combat/spells.dart' show maxManaFor, spellbookSpellIdFor;
import '../data/alignment_events.dart' show hunterCooldownRolls;
import '../data/approval.dart';
import '../data/contracts.dart';
import '../data/factions.dart';
import '../data/factions.dart' as clan_rules show setSubclanMark, shiftRelation;
import '../data/journey_rules.dart';
import '../data/offers.dart';
import '../data/perks.dart';
import '../data/politics_events.dart';
import '../data/politics_events.dart' as coast show applyStoryPolitics;
import '../data/quest_objectives.dart' show killTargetsOf;
import '../data/signs.dart';
import '../data/skill_tree.dart' show branchMasteryEssenceCost;
import '../data/throne.dart'
    show
        claimFlag,
        clanQuestSteps,
        clanStepFlag,
        isMusterFlag,
        onThroneFlag,
        pledgedFlag,
        throneWinnerFlag;
import '../models/ally_state.dart';
import '../models/story_politics.dart';

const String _playerSessionPrefsKey = 'player_session';

/// Where a save that could not be read is kept aside, untouched, before
/// the game falls back to a fresh session (see [PlayerSessionNotifier]).
const String unreadableSessionBackupPrefsKey = 'player_session_unreadable';

/// The save format's version, written into every save. Bump it with a
/// migration in [PlayerSession.fromJson] whenever a change to the format
/// needs one; a save without it is version 1.
const int playerSessionSaveVersion = 3;
const String _newGameDefaultsAssetPath = 'assets/gamedata/game_config.json';
const String _newGameDefaultsPrefsKey = 'gamedb_game_config';

/// The starter die's face indexes reserved for the player's profession and
/// race standard skills (see assets/gamedata/dice.json's starter_die).
const String _starterDiceId = 'starter_die';
const int _starterDieProfessionFaceIndex = 4;
const int _starterDieRaceFaceIndex = 5;

/// The apprentice die's Channeling face, where a caster's mana skill sits
/// from the start (see `manaSkillID` in professions.json).
const int _startingDieManaFaceIndex = 1;

/// The active party's size before any house bonus -- the player plus one
/// ally fits by default. Each built house's own `partyCapacityBonus`
/// (houses.json) adds to this.
const int basePartyCapacity = 2;

/// The player's current active-party capacity: [basePartyCapacity] plus
/// every built house's own bonus. Shared by [PlayerSessionNotifier
/// .recruitAlly] (auto-activating a fresh recruit up to capacity) and
/// CampScreen's own roster display, so the two never drift apart.
int partyCapacityFor(List<String> builtHouseIds, Map<String, dynamic> houses) {
  return basePartyCapacity +
      houses.values.whereType<Map<String, dynamic>>().where((h) {
        return builtHouseIds.contains(h['houseID']?.toString() ?? '');
      }).fold<int>(0,
          (sum, h) => sum + ((h['partyCapacityBonus'] as num?)?.toInt() ?? 0));
}

/// Companions the "Full House" achievement asks for: six of the eight.
/// Tobin follows only a Good leader and Malrik only an Evil one, so no
/// single run can recruit everyone.
const int fullRosterCompanionCount = 6;

/// The share of the purse a retreat costs (see [retreatCostFor]); a
/// potion, when the pack holds one, is dropped too.
const double retreatGoldShare = 0.2;

/// The least a retreat costs, when the party has that much.
const int retreatMinimumGold = 10;

/// What getting away from a fight costs a party carrying [gold]: a
/// share of it, at least [retreatMinimumGold], never more than it has.
int retreatCostFor(int gold) =>
    min(gold, max(retreatMinimumGold, (gold * retreatGoldShare).round()));

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
  final raw = item?['craftMaterials'];
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (((e.value as num?)?.toInt() ?? 0) > 0)
        e.key.toString(): (e.value as num).toInt(),
  };
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
  for (final unit in text.codeUnits) {
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
    this.readSceneKeys = const [],
    this.seenEchoKeys = const [],
    this.provisions = provisionsStart,
    this.day = 1,
    this.watch = 1,
    this.clockChapter = 0,
    this.chapterStartDay = 1,
    this.sellswordFights = 0,
    this.alignmentRollsSinceAmbush = hunterCooldownRolls,
    this.runSeed = 0,
    this.diceUpgrades = const {},
    this.recruitedAllies = const [],
    this.activeAllyIds = const [],
    this.lostAllyIds = const [],
    this.departedAllyIds = const [],
    this.perkRanks = const {},
    this.heldSigns = const [],
    this.pendingOffers = const [],
    this.clanOffer,
    this.heldTitleIds = const [],
    this.activeTitleId = '',
    this.swornBoonIds = const [],
    this.chapterOffersThrough = 0,
    this.titanBlood = 0,
    this.patronFavour = const {},
    this.signPatronsThisLife = const [],
    this.patronsMet = const [],
    this.politics = PoliticsState.empty,
    this.builtHouseIds = const [],
    this.townOrder = const [],
    this.unlockedAchievementIds = const [],
    this.completedZoneIds = const [],
    this.bannerPiecesCollected = const [],
    this.shipHull = -1,
    this.shipPartIds = const ['ballista'],
    this.storedShipPartIds = const [],
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

  /// The town and camp scenes the player has read in full, as
  /// `<nodeId>#<hash of the text>` (see sceneReadKey): coming back to one
  /// whose text hasn't changed opens straight onto the place.
  final List<String> readSceneKeys;

  /// The echoes the player has read (see echoes.dart): a scene's line with
  /// the earlier choice that earned it, as `<nodeId>|<flag>`. The journal's
  /// "What changed" page lists them.
  final List<String> seenEchoKeys;

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

  /// Alignment events rolled since the last hunter's ambush: a hunter
  /// waits [hunterCooldownRolls] of them before the next (see
  /// alignment_events.dart).
  final int alignmentRollsSinceAmbush;

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

  bool get hasLegacy =>
      legacyGold > 0 || legacyDiceIds.isNotEmpty || legacySpellIds.isNotEmpty;

  /// The mana pool's size -- see `maxManaFor` in spells.dart.
  int get maxMana =>
      maxManaFor(intelligence: intelligence, wisdom: wisdom) +
      perkEffects.maxMana;

  int get xpToNextLevel => level * 100;

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
    List<String>? readSceneKeys,
    List<String>? seenEchoKeys,
    int? provisions,
    int? day,
    int? watch,
    int? clockChapter,
    int? chapterStartDay,
    int? sellswordFights,
    int? alignmentRollsSinceAmbush,
    int? runSeed,
    Map<String, DieUpgrades>? diceUpgrades,
    List<AllyState>? recruitedAllies,
    List<String>? activeAllyIds,
    List<String>? lostAllyIds,
    List<String>? departedAllyIds,
    Map<String, int>? perkRanks,
    List<HeldSign>? heldSigns,
    List<OfferTicket>? pendingOffers,
    ClanOffer? clanOffer,
    bool clearClanOffer = false,
    List<String>? heldTitleIds,
    String? activeTitleId,
    List<String>? swornBoonIds,
    int? chapterOffersThrough,
    int? titanBlood,
    Map<String, int>? patronFavour,
    List<String>? signPatronsThisLife,
    List<String>? patronsMet,
    PoliticsState? politics,
    List<String>? builtHouseIds,
    List<String>? townOrder,
    List<String>? unlockedAchievementIds,
    List<String>? completedZoneIds,
    List<String>? bannerPiecesCollected,
    int? shipHull,
    List<String>? shipPartIds,
    List<String>? storedShipPartIds,
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
      readSceneKeys: readSceneKeys ?? this.readSceneKeys,
      seenEchoKeys: seenEchoKeys ?? this.seenEchoKeys,
      provisions: provisions ?? this.provisions,
      day: day ?? this.day,
      watch: watch ?? this.watch,
      clockChapter: clockChapter ?? this.clockChapter,
      chapterStartDay: chapterStartDay ?? this.chapterStartDay,
      sellswordFights: sellswordFights ?? this.sellswordFights,
      alignmentRollsSinceAmbush:
          alignmentRollsSinceAmbush ?? this.alignmentRollsSinceAmbush,
      runSeed: runSeed ?? this.runSeed,
      diceUpgrades: diceUpgrades ?? this.diceUpgrades,
      recruitedAllies: recruitedAllies ?? this.recruitedAllies,
      activeAllyIds: activeAllyIds ?? this.activeAllyIds,
      lostAllyIds: lostAllyIds ?? this.lostAllyIds,
      departedAllyIds: departedAllyIds ?? this.departedAllyIds,
      perkRanks: perkRanks ?? this.perkRanks,
      heldSigns: heldSigns ?? this.heldSigns,
      pendingOffers: pendingOffers ?? this.pendingOffers,
      clanOffer: clearClanOffer ? null : clanOffer ?? this.clanOffer,
      heldTitleIds: heldTitleIds ?? this.heldTitleIds,
      activeTitleId: activeTitleId ?? this.activeTitleId,
      swornBoonIds: swornBoonIds ?? this.swornBoonIds,
      chapterOffersThrough: chapterOffersThrough ?? this.chapterOffersThrough,
      titanBlood: titanBlood ?? this.titanBlood,
      patronFavour: patronFavour ?? this.patronFavour,
      signPatronsThisLife: signPatronsThisLife ?? this.signPatronsThisLife,
      patronsMet: patronsMet ?? this.patronsMet,
      politics: politics ?? this.politics,
      builtHouseIds: builtHouseIds ?? this.builtHouseIds,
      townOrder: townOrder ?? this.townOrder,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      completedZoneIds: completedZoneIds ?? this.completedZoneIds,
      shipHull: shipHull ?? this.shipHull,
      shipPartIds: shipPartIds ?? this.shipPartIds,
      storedShipPartIds: storedShipPartIds ?? this.storedShipPartIds,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'saveVersion': playerSessionSaveVersion,
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
        'readSceneKeys': readSceneKeys,
        'seenEchoKeys': seenEchoKeys,
        'provisions': provisions,
        'day': day,
        'watch': watch,
        'clockChapter': clockChapter,
        'chapterStartDay': chapterStartDay,
        'sellswordFights': sellswordFights,
        'alignmentRollsSinceAmbush': alignmentRollsSinceAmbush,
        'runSeed': runSeed,
        'diceUpgrades': diceUpgradesToJson(diceUpgrades),
        'recruitedAllies': recruitedAllies.map((a) => a.toJson()).toList(),
        'activeAllyIds': activeAllyIds,
        'lostAllyIds': lostAllyIds,
        'departedAllyIds': departedAllyIds,
        'perkRanks': perkRanks,
        'heldSigns': [for (final h in heldSigns) h.toJson()],
        'pendingOffers': [for (final t in pendingOffers) t.toJson()],
        'clanOffer': clanOffer?.toJson(),
        'heldTitleIds': heldTitleIds,
        'activeTitleId': activeTitleId,
        'swornBoonIds': swornBoonIds,
        'chapterOffersThrough': chapterOffersThrough,
        'titanBlood': titanBlood,
        'patronFavour': patronFavour,
        'signPatronsThisLife': signPatronsThisLife,
        'patronsMet': patronsMet,
        'politics': politics.toJson(),
        'builtHouseIds': builtHouseIds,
        'townOrder': townOrder,
        'unlockedAchievementIds': unlockedAchievementIds,
        'completedZoneIds': completedZoneIds,
        'shipHull': shipHull,
        'shipPartIds': shipPartIds,
        'storedShipPartIds': storedShipPartIds,
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
      };

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
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
      maxHealth: (json['maxHealth'] as num?)?.toInt() ?? 100,
      currentHealth: (json['currentHealth'] as num?)?.toInt() ?? 100,
      baseDamage: (json['baseDamage'] as num?)?.toInt() ?? 10,
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
      }.toList(),
      activeQuestIds: (json['activeQuestIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedQuestIds: (json['completedQuestIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      inventoryItemIds: (json['inventoryItemIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
      readSceneKeys:
          (json['readSceneKeys'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      seenEchoKeys:
          (json['seenEchoKeys'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      provisions: (json['provisions'] as num?)?.toInt() ?? provisionsStart,
      day: max(1, (json['day'] as num?)?.toInt() ?? 1),
      watch: ((json['watch'] as num?)?.toInt() ?? 1).clamp(0, 3),
      clockChapter: (json['clockChapter'] as num?)?.toInt() ?? 0,
      chapterStartDay: (json['chapterStartDay'] as num?)?.toInt() ?? 1,
      sellswordFights: (json['sellswordFights'] as num?)?.toInt() ?? 0,
      alignmentRollsSinceAmbush:
          (json['alignmentRollsSinceAmbush'] as num?)?.toInt() ??
              hunterCooldownRolls,
      runSeed: (json['runSeed'] as num?)?.toInt() ?? 0,
      diceUpgrades: parseDiceUpgrades(json['diceUpgrades']),
      recruitedAllies: (json['recruitedAllies'] as List?)
              ?.map((e) => AllyState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeAllyIds:
          (json['activeAllyIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
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
      // Saves from before the clans stand where every faction starts.
      politics: PoliticsState.fromJson(json['politics']),
      builtHouseIds:
          (json['builtHouseIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
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
            intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
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
          maxHealth: 100,
          currentHealth: 100,
          baseDamage: 10,
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
    final maxHealth = (defaults['maxHealth'] as num?)?.toInt() ?? 100;
    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      currentXP: 0,
      gold: (defaults['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: 0,
      maxHealth: maxHealth,
      currentHealth: maxHealth,
      baseDamage: (defaults['baseDamage'] as num?)?.toInt() ?? 10,
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
      flags: const [],
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
        intelligence: (defaults['intelligence'] as num?)?.toInt() ?? 0,
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

    final maxHealth = ((defaults['maxHealth'] as num?)?.toInt() ?? 100) +
        bonus(race, 'bonusMaxHealth') +
        bonus(profession, 'bonusMaxHealth');
    final baseDamage = ((defaults['baseDamage'] as num?)?.toInt() ?? 10) +
        bonus(race, 'bonusBaseDamage') +
        bonus(profession, 'bonusBaseDamage');
    final baseArmor = ((defaults['baseArmor'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusBaseArmor') +
        bonus(profession, 'bonusBaseArmor');
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
    final startingOffers = startingOffersFor(profession);

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
      pendingOffers: startingOffers,
      maxSkillSlots: (defaults['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: const [],
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
      mana: maxManaFor(intelligence: intelligence, wisdom: wisdom),
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
  /// dislikes greed would hold against the player.
  Future<List<ApprovalChange>> applyChoiceEffects({
    int goldMod = 0,
    int alignmentMod = 0,
    int healAmount = 0,
    List<String> flagsToAdd = const [],
    String? questIDToProgress,
    String? bannerPieceId,
    String? itemId,
    String? loseAllyId,
    Map<String, int> approvalMods = const {},
    Map<String, dynamic> companions = const {},
    bool goldIsProfit = true,
  }) async {
    // Who the story takes is settled by the party as it stands in the
    // scene, before anyone reacts: a companion walking out over this very
    // choice must not leave `*` to take whoever steps into their seat.
    final lostId = loseAllyId == null || loseAllyId.isEmpty
        ? null
        : loseAllyId == '*'
            ? state.activeAllyIds.firstOrNull
            : loseAllyId;
    final reactions = _reactToDeed(
      companions: companions,
      alignmentMod: alignmentMod,
      goldMod: goldIsProfit ? goldMod : 0,
      approvalMods: approvalMods,
      // Taken by the story: they don't stay to have an opinion.
      exclude: lostId,
    );
    final newFlags = <String>{...state.flags, ...flagsToAdd}.toList();
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
    final newHealthRaw = state.currentHealth + healAmount;
    state = state.copyWith(
      gold: newGoldRaw < 0 ? 0 : newGoldRaw,
      alignmentScore: state.alignmentScore + alignmentMod,
      currentHealth: newHealthRaw > state.maxHealth
          ? state.maxHealth
          : (newHealthRaw < 1 ? 1 : newHealthRaw),
      flags: newFlags,
      activeQuestIds: newActiveQuests,
      questKillBaselines: newKillBaselines,
      trackedQuestId: newTracked,
      bannerPiecesCollected: newBannerPieces,
      inventoryItemIds: itemId == null || itemId.isEmpty
          ? state.inventoryItemIds
          : [...state.inventoryItemIds, itemId],
    );
    if (lostId != null) {
      loseAlly(lostId, persist: false, companions: companions);
    }
    await _persist();
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
      final after = approvalAfter(ally.approval, delta);
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
  OfferContext offerContextFor(OfferTables tables) {
    final s = state;
    return OfferContext(
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
      // A lucky sign (or title) helps draw the next gift.
      luck: s.luck +
          signEffectsFor(s.heldSigns, tables.signs,
              alignment: s.alignmentScore,
              extra: clanEffectsFor(
                activeTitleId: s.activeTitleId,
                heldTitleIds: s.heldTitleIds,
                swornBoonIds: s.swornBoonIds,
                swornFactionId: s.politics.swornFactionId,
                data: tables.data,
              )).stat('luck'),
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
  /// it when the alignment leans. Returns whether one was granted.
  Future<bool> grantChapterOffer(int chapter) async {
    if (chapter < 2 || chapter <= state.chapterOffersThrough) return false;
    state = state.copyWith(
      chapterOffersThrough: chapter,
      pendingOffers: [
        ...state.pendingOffers,
        OfferTicket(source: OfferSource.chapter, detail: '$chapter'),
      ],
    );
    await _persist();
    return true;
  }

  /// The offer on the table for the first offer due (see drawOffer),
  /// drawn once from [tables] and kept until a suitor is taken. Null when
  /// none is due, or nobody can come (the offer waits). The suitors'
  /// factions count as met, for their intro and the codex.
  Future<ClanOffer?> ensureOffer(OfferTables tables, {Random? random}) async {
    if (state.pendingOffers.isEmpty) return null;
    final waiting = state.clanOffer;
    if (waiting != null) return waiting;
    final offer = drawOffer(
        state.pendingOffers.first, offerContextFor(tables), random ?? Random());
    if (offer == null) return null;
    state = state.copyWith(
      clanOffer: offer,
      patronsMet: {
        ...state.patronsMet,
        for (final s in offer.suitors) s.factionId,
      }.toList(),
    );
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
      {required OfferTables tables}) async {
    final offer = state.clanOffer;
    final suitor = offer?.suitorOf(factionId);
    if (offer == null || suitor == null || state.pendingOffers.isEmpty) {
      return false;
    }
    var next = _withGift(state, suitor, tables);
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
      PlayerSession session, Suitor suitor, OfferTables tables) {
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
            session, gift.id, tables.items[gift.id] as Map<String, dynamic>?);
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
    }
  }

  /// [session] given [itemId] the way a reward is: a potion as charges, a
  /// spellbook read, a tome read on the spot (a Tome of Mastery is one more
  /// offer), anything else to the pack.
  PlayerSession _withItem(
      PlayerSession session, String itemId, Map<String, dynamic>? item) {
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
        pendingOffers: [...session.pendingOffers, ...tome.offers],
      );
    }
    return session
        .copyWith(inventoryItemIds: [...session.inventoryItemIds, itemId]);
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
  /// start, no marks, no faction sworn, the relations and logs cleared;
  /// the titles a mark held go with it ([data]: the clan data, for them).
  Future<void> resetPolitics({ClanData? data}) async {
    final reset = state.copyWith(politics: PoliticsState.empty);
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
          ClanData data, Map<String, PoliticsEvent> events, int? chapter) =>
      CoastWorld(
        data: data,
        events: events,
        chapter: _politicsChapter(chapter),
        day: state.day,
        chapterDay: max(1, state.day - state.chapterStartDay + 1),
        signPatrons: state.signPatronsThisLife,
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
    String key = '',
    Map<String, PoliticsEvent> events = const {},
    Map<String, dynamic> companions = const {},
    int? chapter,
  }) async {
    final change = coast.applyStoryPolitics(politics,
        cause: 'story:$nodeId',
        key: key,
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter));
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    await _persist();
    return change;
  }

  /// Fires every politics event whose time has come on [chapter] (the
  /// chapter reached) and today (see runDueEvents): on a chapter change
  /// and a day's tick. Returns what changed; its news are the events'
  /// "News from the coast".
  Future<CoastChange> runPoliticsEvents({
    required ClanData data,
    required Map<String, PoliticsEvent> events,
    Map<String, dynamic> companions = const {},
    int? chapter,
  }) async {
    final change = runDueEvents(
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter));
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    await _persist();
    return change;
  }

  /// Edit Mode's "Fire now": politics event [eventId] fires at once, even
  /// one that has fired before.
  Future<CoastChange> firePoliticsEvent(
    String eventId, {
    required ClanData data,
    required Map<String, PoliticsEvent> events,
    Map<String, dynamic> companions = const {},
    int? chapter,
  }) async {
    final change = fireEvent(eventId,
        politics: state.politics,
        flags: state.flags,
        world: _coastWorld(data, events, chapter),
        force: true);
    if (!change.applied) return change;
    _takeCoastChange(change, data, companions: companions);
    await _persist();
    return change;
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
    final replacement =
        _removeAlly(companionId, lost: true, companions: companions);
    if (persist) _persist();
    return replacement;
  }

  /// Takes on [questId]. A bounty in [quest] (a `countFromAccept` Kill
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
      questKillBaselines: baseline.isEmpty
          ? state.questKillBaselines
          : {...state.questKillBaselines, questId: baseline},
      // With no quest followed yet, the one just taken on is followed.
      trackedQuestId: state.activeQuestIds.contains(state.trackedQuestId)
          ? state.trackedQuestId
          : questId,
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
  }) async {
    final newActive =
        state.activeQuestIds.where((id) => id != questId).toList();
    final newCompleted = <String>{...state.completedQuestIds, questId}.toList();
    final newInventory = [...state.inventoryItemIds];
    var potionsGained = 0;
    var antidotesGained = 0;
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      final charges = consumableChargesFor(rewardItemId, rewardItem);
      if (charges == null) {
        newInventory.add(rewardItemId);
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
      currentHealth:
          leveled.leveledUp ? leveled.maxHealth : state.currentHealth,
      statPoints: leveled.statPoints,
      // Each level reached brings an offer (see offers.dart).
      pendingOffers: [
        ...state.pendingOffers,
        ..._levelOffers(leveled.levelsGained),
      ],
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
      potionCount: state.potionCount + potionsGained,
      antidoteCount: state.antidoteCount + antidotesGained,
      unlockedQuestIds: newUnlockedQuests,
      ownedDiceIds: newOwnedDice,
      xpEarnedThisRun: state.xpEarnedThisRun + rewardXP,
      skillEssence: state.skillEssence + rewardXP,
      recruitedAllies: newAllies,
      bannerPiecesCollected: newBannerPieces,
    );
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

  /// Forges [itemId] from [item]'s recipe: its gold and materials leave
  /// the pack and the piece enters it. Returns false if something is
  /// missing.
  Future<bool> craftItem(String itemId, Map<String, dynamic>? item) async {
    if (!canCraft(item)) return false;
    final remaining = [...state.inventoryItemIds];
    for (final m in craftMaterialsFor(item).entries) {
      for (var i = 0; i < m.value; i++) {
        remaining.remove(m.key);
      }
    }
    state = state.copyWith(
      gold: state.gold - ((item!['craftGold'] as num?)?.toInt() ?? 0),
      inventoryItemIds: [...remaining, itemId],
    );
    await _persist();
    return true;
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
    final starterUnlocked = <String>{
      if (professionSkillId.isNotEmpty) professionSkillId,
      if (raceSkillId.isNotEmpty) raceSkillId,
      for (final face in signatureFaces)
        if ((face['linkedSkillID']?.toString() ?? '').isNotEmpty)
          face['linkedSkillID'].toString(),
    }.toList();
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
    );
    await _persist();
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
  }) async {
    if (!state.recruitedAllies.any((a) => a.companionId == companionId)) return;
    if (!active) {
      if (!state.activeAllyIds.contains(companionId)) return;
      state = state.copyWith(
        activeAllyIds:
            state.activeAllyIds.where((id) => id != companionId).toList(),
      );
      await _persist();
      return;
    }
    if (state.activeAllyIds.contains(companionId)) return;
    if (state.activeAllyIds.length >= partyCapacity) return;
    if (requiredHouseId != null &&
        requiredHouseId.isNotEmpty &&
        !state.builtHouseIds.contains(requiredHouseId)) {
      return;
    }
    state =
        state.copyWith(activeAllyIds: [...state.activeAllyIds, companionId]);
    await _persist();
  }

  /// Spends gold to build a camp house. No-ops if already built or
  /// unaffordable. [unlocksShopId] (the house's own `unlocksShopId` field,
  /// e.g. Hammersmith opening its Forge) is passed through to
  /// [unlockContent] so building the house and gaining access to its shop
  /// are one atomic action, exactly like [recruitAlly]'s starter-skill
  /// unlock is one action rather than two.
  /// Spends [cost] and marks [houseId] built, unlocking [unlocksShopId] if
  /// any. A no-op if unaffordable, already built, or any of
  /// [requiredFlags] (houses.json) is still unset -- the camp's late
  /// workshops wait on the zones that supply them.
  Future<void> buildHouse(String houseId, int cost,
      {String? unlocksShopId, List<String> requiredFlags = const []}) async {
    if (state.gold < cost || state.builtHouseIds.contains(houseId)) return;
    if (requiredFlags.any((flag) => !state.flags.contains(flag))) return;
    // The story reads the camp's buildings back through a flag per house
    // (see houseFlag).
    final flag = houseFlag(houseId);
    state = state.copyWith(
      gold: state.gold - cost,
      builtHouseIds: [...state.builtHouseIds, houseId],
      flags: state.flags.contains(flag) ? state.flags : [...state.flags, flag],
      townOrder: [...state.townPieces, houseId],
    );
    await _persist();
    if (unlocksShopId != null && unlocksShopId.isNotEmpty) {
      await unlockContent(shopId: unlocksShopId);
    }
  }

  /// Spends [cost] on a town addition ([type], one of
  /// `cliff_town.dart`'s additions) and raises it on the cliff. Additions
  /// are the town's own: they add rooms and lights, no bonuses. A no-op
  /// if unaffordable.
  Future<void> buildTownAddition(String type, int cost) async {
    if (state.gold < cost) return;
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
  }) async {
    if (state.completedZoneIds.contains(zoneId)) return;
    final newInventory = [...state.inventoryItemIds];
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      newInventory.add(rewardItemId);
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

  /// Marks every currently-unlocked shop/quest/enemy id as seen at once —
  /// used when a Play-tab section is expanded, clearing its whole badge.
  Future<void> markAllSeenInCategory(
      {bool shops = false, bool quests = false, bool enemies = false}) async {
    state = state.copyWith(
      seenShopIds: shops ? state.unlockedShopIds : state.seenShopIds,
      seenQuestIds: quests ? state.unlockedQuestIds : state.seenQuestIds,
      seenEnemyIds: enemies ? state.unlockedEnemyIds : state.seenEnemyIds,
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
  /// strict upgrade. No-ops unless both inputs are currently unlocked and
  /// the result isn't already unlocked.
  Future<void> mergeSkills({
    required List<String> inputSkillIds,
    required String resultSkillId,
  }) async {
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

  Future<void> spendStatPoint({required String stat}) async {
    if (state.statPoints <= 0) return;
    var newBaseDamage = state.baseDamage;
    var newBaseArmor = state.baseArmor;
    var newMaxHealth = state.maxHealth;
    var newCurrentHealth = state.currentHealth;
    var newLuck = state.luck;
    var newCharisma = state.charisma;
    var newStrength = state.strength;
    var newDexterity = state.dexterity;
    var newConstitution = state.constitution;
    var newIntelligence = state.intelligence;
    var newWisdom = state.wisdom;
    var newPerception = state.perception;
    switch (stat) {
      case 'damage':
        newBaseDamage += 1;
        break;
      case 'armor':
        newBaseArmor += 1;
        break;
      case 'health':
        newMaxHealth += 10;
        newCurrentHealth += 10;
        break;
      case 'luck':
        newLuck += 1;
        break;
      case 'charisma':
        newCharisma += 1;
        break;
      case 'strength':
        newStrength += 1;
        break;
      case 'dexterity':
        newDexterity += 1;
        break;
      case 'constitution':
        newConstitution += 1;
        break;
      case 'intelligence':
        newIntelligence += 1;
        break;
      case 'wisdom':
        newWisdom += 1;
        break;
      case 'perception':
        newPerception += 1;
        break;
      default:
        break;
    }
    state = state.copyWith(
      statPoints: state.statPoints - 1,
      baseDamage: newBaseDamage,
      baseArmor: newBaseArmor,
      maxHealth: newMaxHealth,
      currentHealth: newCurrentHealth,
      luck: newLuck,
      charisma: newCharisma,
      strength: newStrength,
      dexterity: newDexterity,
      constitution: newConstitution,
      intelligence: newIntelligence,
      wisdom: newWisdom,
      perception: newPerception,
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
    int plus(String key, int value) => value + (abilities[key] ?? 0);
    state = state.copyWith(
      alignmentScore: state.alignmentScore + alignmentMod,
      strength: plus('strength', state.strength),
      dexterity: plus('dexterity', state.dexterity),
      constitution: plus('constitution', state.constitution),
      intelligence: plus('intelligence', state.intelligence),
      wisdom: plus('wisdom', state.wisdom),
      charisma: plus('charisma', state.charisma),
      luck: plus('luck', state.luck),
      perception: plus('perception', state.perception),
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
      antidoteCount: antidoteCount,
      mana: mana,
    );
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

  /// Adds [spellId] to [PlayerSession.knownSpellIds]; a no-op for a spell
  /// already known or an empty id.
  Future<void> learnSpell(String spellId) async {
    if (spellId.isEmpty || state.knownSpellIds.contains(spellId)) return;
    state = state.copyWith(knownSpellIds: [...state.knownSpellIds, spellId]);
    await _persist();
  }

  /// Runs [xpGain] through the level-up threshold (`level * 100` XP each),
  /// applying every level gained: +5 statPoints and +20 maxHealth (and an
  /// offer, which the callers add: see [_levelOffers]). Shared by
  /// [applyCombatResult] and [completeQuest] so a quest's XP reward levels
  /// the player up exactly like combat XP does.
  ({
    int level,
    int xp,
    int maxHealth,
    int statPoints,
    bool leveledUp,
    int levelsGained,
  }) _applyXp(int xpGain) {
    var newLevel = state.level;
    var newXp = state.currentXP + xpGain;
    var newMaxHealth = state.maxHealth;
    var newStatPoints = state.statPoints;
    var leveledUp = false;
    var levelsGained = 0;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel += 1;
      newStatPoints += 5;
      newMaxHealth += 20;
      leveledUp = true;
      levelsGained += 1;
    }

    return (
      level: newLevel,
      xp: newXp,
      maxHealth: newMaxHealth,
      statPoints: newStatPoints,
      leveledUp: leveledUp,
      levelsGained: levelsGained,
    );
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
  }) async {
    final leveled = _applyXp(xpGain);

    // Looted potions/antidotes become charges (see [consumableChargesFor]),
    // a looted tome is read on the spot (see [tomeGrantFor]); everything
    // else is carried in the inventory.
    var potionsGained = 0;
    var antidotesGained = 0;
    var statPointsGained = 0;
    final tomeOffers = <OfferTicket>[];
    final carried = <String>[];
    final spellsLearned = <String>[];
    for (final itemId in itemsGained) {
      final item = items[itemId] as Map<String, dynamic>?;
      final tome = tomeGrantFor(itemId, item);
      if (tome != null) {
        statPointsGained += tome.statPoints;
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
      currentHealth: newHealth,
      statPoints: leveled.statPoints + statPointsGained,
      // Each level reached and a boss beaten bring an offer (see
      // offers.dart), a Tome of Mastery one too; a hunt (or, sometimes, an
      // Elite) a drop of Titan's Blood; a dice fight won or lost runs every
      // pact one fight on.
      pendingOffers: [
        ...state.pendingOffers,
        ..._levelOffers(leveled.levelsGained),
        for (var i = 0; i < bossOffers; i++)
          const OfferTicket(source: OfferSource.boss),
        ...tomeOffers,
      ],
      titanBlood: state.titanBlood + titanBlood,
      heldSigns: pactFight ? countDownPacts(state.heldSigns) : null,
      gold: state.gold + goldGain,
      inventoryItemIds: [...state.inventoryItemIds, ...carried],
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
    await _persist();
    return leveled.leveledUp;
  }

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
      pendingOffers: startingOffersFor(profession),
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
      politics: PoliticsState.empty,
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

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});
