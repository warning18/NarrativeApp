import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../combat/combat_engine.dart' show maxSkillTier, skillTierUpgradeCost;
import '../combat/spells.dart' show maxManaFor, spellbookSpellIdFor;
import '../models/ally_state.dart';

const String _playerSessionPrefsKey = 'player_session';

/// Where a save that could not be read is kept aside, untouched, before
/// the game falls back to a fresh session (see [PlayerSessionNotifier]).
const String unreadableSessionBackupPrefsKey = 'player_session_unreadable';

/// The save format's version, written into every save. Bump it with a
/// migration in [PlayerSession.fromJson] whenever a change to the format
/// needs one; a save without it is version 1.
const int playerSessionSaveVersion = 2;
const String _newGameDefaultsAssetPath = 'assets/gamedata/game_config.json';
const String _newGameDefaultsPrefsKey = 'gamedb_game_config';

/// The starter die's face indexes reserved for the player's profession and
/// race standard skills (see assets/gamedata/dice.json's starter_die).
const String _starterDiceId = 'starter_die';
const int _starterDieProfessionFaceIndex = 4;
const int _starterDieRaceFaceIndex = 5;

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

/// The wearer id [PlayerSession.wearersOf] uses for the player (allies go
/// by their companion id).
const String playerWearerId = 'player';

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
    required this.skillPoints,
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
    this.shopUnlockNodeIds = const {},
    this.seenShopIds = const [],
    this.seenQuestIds = const [],
    this.seenEnemyIds = const [],
    this.recruitedAllies = const [],
    this.activeAllyIds = const [],
    this.lostAllyIds = const [],
    this.builtHouseIds = const [],
    this.unlockedAchievementIds = const [],
    this.completedZoneIds = const [],
    this.bannerPiecesCollected = const [],
    this.shipHull = -1,
    this.shipPartIds = const ['ballista'],
    this.currentPortId = '',
    this.visitedPortIds = const [],
    this.enemyKillCounts = const {},
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
  /// actually wields it. Wisdom has no combat tie-in of any kind.
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
  final int skillPoints;
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

  /// shopId -> the story node whose choice unlocked it. A shop is only
  /// browsable in the Play tab while the player is currently on that node;
  /// leaving it hides the shop again (it reappears if the player returns).
  /// Unlike [unlockedShopIds], entries here are never removed, so
  /// historical stats (e.g. the playthrough simulator) still see every shop
  /// ever discovered.
  final Map<String, String> shopUnlockNodeIds;

  /// Ids the player has already viewed in the Play tab, used to compute the
  /// "newly unlocked" badge counts shown on the Quests/Shops/Bestiary
  /// section headers.
  final List<String> seenShopIds;
  final List<String> seenQuestIds;
  final List<String> seenEnemyIds;

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

  /// Houses built at camp — mirrors [unlockedShopIds]. Gates which specific
  /// companions can join the active party (a companion's own
  /// `requiredHouseId`) and/or raises party capacity
  /// (`partyCapacityBonus`), per houses.json.
  final List<String> builtHouseIds;

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
  /// lifetime rather than "since the quest was accepted" is a deliberate
  /// simplification: every current Kill objective needs exactly 1, so a
  /// player who beat the target enemy before picking up the quest gets
  /// immediate credit instead of being made to grind out a second, purely
  /// bureaucratic kill.
  final Map<String, int> enemyKillCounts;

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
  int get maxMana => maxManaFor(intelligence: intelligence, wisdom: wisdom);

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
    int? skillPoints,
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
    Map<String, String>? shopUnlockNodeIds,
    List<String>? seenShopIds,
    List<String>? seenQuestIds,
    List<String>? seenEnemyIds,
    List<AllyState>? recruitedAllies,
    List<String>? activeAllyIds,
    List<String>? lostAllyIds,
    List<String>? builtHouseIds,
    List<String>? unlockedAchievementIds,
    List<String>? completedZoneIds,
    List<String>? bannerPiecesCollected,
    int? shipHull,
    List<String>? shipPartIds,
    String? currentPortId,
    List<String>? visitedPortIds,
    Map<String, int>? enemyKillCounts,
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
      skillPoints: skillPoints ?? this.skillPoints,
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
      shopUnlockNodeIds: shopUnlockNodeIds ?? this.shopUnlockNodeIds,
      seenShopIds: seenShopIds ?? this.seenShopIds,
      seenQuestIds: seenQuestIds ?? this.seenQuestIds,
      seenEnemyIds: seenEnemyIds ?? this.seenEnemyIds,
      recruitedAllies: recruitedAllies ?? this.recruitedAllies,
      activeAllyIds: activeAllyIds ?? this.activeAllyIds,
      lostAllyIds: lostAllyIds ?? this.lostAllyIds,
      builtHouseIds: builtHouseIds ?? this.builtHouseIds,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      completedZoneIds: completedZoneIds ?? this.completedZoneIds,
      shipHull: shipHull ?? this.shipHull,
      shipPartIds: shipPartIds ?? this.shipPartIds,
      currentPortId: currentPortId ?? this.currentPortId,
      visitedPortIds: visitedPortIds ?? this.visitedPortIds,
      bannerPiecesCollected:
          bannerPiecesCollected ?? this.bannerPiecesCollected,
      enemyKillCounts: enemyKillCounts ?? this.enemyKillCounts,
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
        'skillPoints': skillPoints,
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
        'shopUnlockNodeIds': shopUnlockNodeIds,
        'seenShopIds': seenShopIds,
        'seenQuestIds': seenQuestIds,
        'seenEnemyIds': seenEnemyIds,
        'recruitedAllies': recruitedAllies.map((a) => a.toJson()).toList(),
        'activeAllyIds': activeAllyIds,
        'lostAllyIds': lostAllyIds,
        'builtHouseIds': builtHouseIds,
        'unlockedAchievementIds': unlockedAchievementIds,
        'completedZoneIds': completedZoneIds,
        'shipHull': shipHull,
        'shipPartIds': shipPartIds,
        'currentPortId': currentPortId,
        'visitedPortIds': visitedPortIds,
        'bannerPiecesCollected': bannerPiecesCollected,
        'enemyKillCounts': enemyKillCounts,
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
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      maxSkillSlots: (json['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: (json['flags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
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
      builtHouseIds:
          (json['builtHouseIds'] as List?)?.map((e) => e.toString()).toList() ??
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
          skillPoints: 0,
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
      skillPoints: 0,
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
    final skillPoints = bonus(profession, 'startingSkillPoints');

    final professionSkillId = profession['standardSkillID']?.toString() ?? '';
    final raceSkillId = race['standardSkillID']?.toString() ?? '';
    final starterAssignments = <String, String>{
      if (professionSkillId.isNotEmpty)
        _starterDieProfessionFaceIndex.toString(): professionSkillId,
      if (raceSkillId.isNotEmpty)
        _starterDieRaceFaceIndex.toString(): raceSkillId,
    };
    // Race/profession signature skills default to isUnlocked: false in the
    // skills db (most skills are locked until earned) but are wired
    // directly into the starter die's Heritage/Profession Technique faces
    // from the moment a character exists — so they need to be unlocked
    // here too, or those faces would just fizzle on the very first roll.
    final starterUnlockedSkills = <String>[
      if (professionSkillId.isNotEmpty) professionSkillId,
      if (raceSkillId.isNotEmpty) raceSkillId,
    ];
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
      skillPoints: skillPoints,
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
      ownedDiceIds: [
        _starterDiceId,
        if (startingDiceId != _starterDiceId) startingDiceId,
        ...legacyDice,
      ],
      equippedDiceId: startingDiceId,
      antidoteCount: (defaults['antidoteCount'] as num?)?.toInt() ?? 0,
      mana: maxManaFor(intelligence: intelligence, wisdom: wisdom),
      knownSpellIds: [...startingSpellIds, ...legacySpells],
      newGamePlusCycle: legacy.newGamePlusCycle,
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

  /// The die a new character of [profession] starts with equipped -- its
  /// own `startingDiceId` (a Mage's or Cleric's apprentice die, with its
  /// Mana faces) or the starter die. Every profession's starting die keeps
  /// the Profession/Heritage Technique faces at the starter die's own
  /// indexes ([_starterDieProfessionFaceIndex]/[_starterDieRaceFaceIndex]),
  /// so the same face assignments serve both dice.
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

  /// [starterAssignments] under the starter die AND the profession's own
  /// starting die (when it has one), so the Technique faces resolve on
  /// whichever of the two is equipped.
  static Map<String, Map<String, String>> _starterAssignmentsByDie(
    Map<String, String> starterAssignments,
    String startingDiceId,
  ) =>
      {
        if (starterAssignments.isNotEmpty) ...{
          _starterDiceId: starterAssignments,
          if (startingDiceId != _starterDiceId)
            startingDiceId: starterAssignments,
        },
      };

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
  Future<void> applyChoiceEffects({
    int goldMod = 0,
    int alignmentMod = 0,
    int healAmount = 0,
    List<String> flagsToAdd = const [],
    String? questIDToProgress,
    String? bannerPieceId,
    String? loseAllyId,
  }) async {
    final newFlags = <String>{...state.flags, ...flagsToAdd}.toList();
    var newActiveQuests = state.activeQuestIds;
    if (questIDToProgress != null &&
        questIDToProgress.isNotEmpty &&
        !state.activeQuestIds.contains(questIDToProgress) &&
        !state.completedQuestIds.contains(questIDToProgress)) {
      newActiveQuests = [...state.activeQuestIds, questIDToProgress];
    }
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
      bannerPiecesCollected: newBannerPieces,
    );
    if (loseAllyId != null && loseAllyId.isNotEmpty) {
      final id = loseAllyId == '*'
          ? (state.activeAllyIds.isEmpty ? null : state.activeAllyIds.first)
          : loseAllyId;
      if (id != null) loseAlly(id, persist: false);
    }
    await _persist();
  }

  /// The story takes [companionId] for good: out of the roster and the
  /// party, and never recruited again this run. A no-op for an unknown or
  /// already-lost id.
  void loseAlly(String companionId, {bool persist = true}) {
    if (!state.recruitedAllies.any((a) => a.companionId == companionId)) {
      return;
    }
    state = state.copyWith(
      recruitedAllies: state.recruitedAllies
          .where((a) => a.companionId != companionId)
          .toList(),
      activeAllyIds:
          state.activeAllyIds.where((id) => id != companionId).toList(),
      lostAllyIds: state.lostAllyIds.contains(companionId)
          ? state.lostAllyIds
          : [...state.lostAllyIds, companionId],
    );
    if (persist) _persist();
  }

  Future<void> acceptQuest(String questId) async {
    if (state.activeQuestIds.contains(questId) ||
        state.completedQuestIds.contains(questId)) {
      return;
    }
    state = state.copyWith(activeQuestIds: [...state.activeQuestIds, questId]);
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
      skillPoints: leveled.skillPoints,
      gold: state.gold + rewardGold,
      alignmentScore: state.alignmentScore + alignmentMod,
      activeQuestIds: newActive,
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
  /// via [PlayerSession.shopPurchaseCounts] and never replenishes.
  Future<void> buyItem(
    String shopId,
    String itemId,
    int cost,
    int stockLimit, {
    Map<String, dynamic>? item,
  }) async {
    final key = '$shopId::$itemId';
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
        skillPoints: state.skillPoints + tome.skillPoints,
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
      skillPoints: state.skillPoints + tome.skillPoints,
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
    state = state.copyWith(
      gold: state.gold - cost,
      builtHouseIds: [...state.builtHouseIds, houseId],
    );
    await _persist();
    if (unlocksShopId != null && unlocksShopId.isNotEmpty) {
      await unlockContent(shopId: unlocksShopId);
    }
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
  /// ship_combat.dart's canInstallPart).
  Future<bool> installShipPart(String partId, int cost,
      {List<String> replacing = const []}) async {
    if (state.shipPartIds.contains(partId) || state.gold < cost) return false;
    state = state.copyWith(
      gold: state.gold - cost,
      // Repainting the sail takes the old sigil off (see sail_powers.dart).
      shipPartIds: [
        ...state.shipPartIds.where((id) => !replacing.contains(id)),
        partId,
      ],
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
      if (shopUnlockNodeId != null && shopUnlockNodeId.isNotEmpty) {
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

  Future<void> unlockSkill(String skillId) async {
    if (state.skillPoints <= 0 || state.unlockedSkillIds.contains(skillId)) {
      return;
    }
    state = state.copyWith(
      skillPoints: state.skillPoints - 1,
      unlockedSkillIds: [...state.unlockedSkillIds, skillId],
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
    int? skillPoints,
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
      skillPoints: skillPoints,
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
  /// applying every level gained: +5 statPoints, +1 skillPoint, +20
  /// maxHealth. Shared by [applyCombatResult] and [completeQuest] so a
  /// quest's XP reward levels the player up exactly like combat XP does.
  ({
    int level,
    int xp,
    int maxHealth,
    int statPoints,
    int skillPoints,
    bool leveledUp,
    int levelsGained,
  }) _applyXp(int xpGain) {
    var newLevel = state.level;
    var newXp = state.currentXP + xpGain;
    var newMaxHealth = state.maxHealth;
    var newStatPoints = state.statPoints;
    var newSkillPoints = state.skillPoints;
    var leveledUp = false;
    var levelsGained = 0;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel += 1;
      newStatPoints += 5;
      newSkillPoints += 1;
      newMaxHealth += 20;
      leveledUp = true;
      levelsGained += 1;
    }

    return (
      level: newLevel,
      xp: newXp,
      maxHealth: newMaxHealth,
      statPoints: newStatPoints,
      skillPoints: newSkillPoints,
      leveledUp: leveledUp,
      levelsGained: levelsGained,
    );
  }

  /// A level-up full-heals the player and, mirroring that, every recruited
  /// ally too — "grows with you" plus the ally-equivalent of the player's
  /// own +1 skillPoint/level (see AllyState.skillPoints doc).
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
  }) async {
    final leveled = _applyXp(xpGain);

    // Looted potions/antidotes become charges (see [consumableChargesFor]),
    // a looted tome is read on the spot (see [tomeGrantFor]); everything
    // else is carried in the inventory.
    var potionsGained = 0;
    var antidotesGained = 0;
    var statPointsGained = 0;
    var skillPointsGained = 0;
    final carried = <String>[];
    final spellsLearned = <String>[];
    for (final itemId in itemsGained) {
      final item = items[itemId] as Map<String, dynamic>?;
      final tome = tomeGrantFor(itemId, item);
      if (tome != null) {
        statPointsGained += tome.statPoints;
        skillPointsGained += tome.skillPoints;
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
    final newHealth = leveled.leveledUp ? leveled.maxHealth : clampedHp;

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
      skillPoints: leveled.skillPoints + skillPointsGained,
      gold: state.gold + goldGain,
      inventoryItemIds: [...state.inventoryItemIds, ...carried],
      potionCount: state.potionCount + potionsGained,
      antidoteCount: state.antidoteCount + antidotesGained,
      xpEarnedThisRun: state.xpEarnedThisRun + xpGain,
      skillEssence: state.skillEssence + xpGain,
      recruitedAllies: newAllies,
      enemyKillCounts: newKillCounts,
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
  /// `tome_of_mastery` grants a skill point; every other Tome grants a
  /// stat point. Null for anything that isn't a Tome.
  static ({int statPoints, int skillPoints})? tomeGrantFor(
      String itemId, Map<String, dynamic>? item) {
    if (item?['itemType']?.toString() != 'Tome') return null;
    if (itemId == 'tome_of_mastery') return (statPoints: 0, skillPoints: 1);
    return (statPoints: 1, skillPoints: 0);
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
  /// over each life. Keeps level, XP, gold, stats, dice (as items) and
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
    );

    final professionSkillId = profession['standardSkillID']?.toString() ?? '';
    final raceSkillId = race['standardSkillID']?.toString() ?? '';
    final starterUnlockedSkills = <String>[
      if (professionSkillId.isNotEmpty) professionSkillId,
      if (raceSkillId.isNotEmpty) raceSkillId,
    ];
    final starterAssignments = <String, String>{
      if (professionSkillId.isNotEmpty)
        _starterDieProfessionFaceIndex.toString(): professionSkillId,
      if (raceSkillId.isNotEmpty)
        _starterDieRaceFaceIndex.toString(): raceSkillId,
    };
    final starterSkillPoints =
        (profession['startingSkillPoints'] as num?)?.toInt() ?? 0;

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
      skillEssence: 0,
      skillPoints: starterSkillPoints,
      diceSkillAssignments: _starterAssignmentsByDie(
          starterAssignments, _startingDiceIdFor(profession)),
      knownSpellIds: _startingSpellIdsFor(profession),
      mana: state.maxMana,
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
  });

  final List<String> lostItemIds;

  /// How many skills were unlocked right before the reset wiped them back
  /// to class basics — for the death-screen recap.
  final int skillsLost;
  final int xpEarnedThisRun;
}

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});
