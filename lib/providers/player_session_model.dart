// The save itself (see player_session_provider.dart): the PlayerSession
// model, read from and written to JSON, and the constants and small rules
// around it that the rest of the game reads.
part of 'player_session_provider.dart';

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

/// How many companions may be seated (fight beside the player): two, so a
/// fight has three fighters and three dice, never more (the user's cap,
/// v1.667). No house adds a seat; the Barracks Annex gives the companions
/// health instead (`companionHealthBonus`, party_bonus.dart).
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
/// built (the cap of three fighters, v1.667). Shared by [PlayerSessionNotifier
/// .recruitAlly] (auto-activating a fresh recruit up to capacity) and
/// CampScreen's own roster display, so the two never drift apart.
int partyCapacityFor(List<String> builtHouseIds, Map<String, dynamic> houses) =>
    basePartyCapacity;

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
  /// alongside the player, bounded by party capacity (two: three fighters,
  /// v1.667).
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
  /// `requiredHouseId`), per houses.json.
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

  /// The mana pool's size -- see `maxManaFor` in spells.dart.
  int get maxMana => maxManaFor(wisdom: wisdom) + perkEffects.maxMana;

  int get xpToNextLevel => xpForLevel(level);

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
    // A save from before the cap of three fighters (v1.667) may have three
    // companions seated (the Barracks Annex's old seat): the first two stay,
    // the third goes to the bench, still recruited. Nobody is lost.
    final seated = [
      for (final id in (json['activeAllyIds'] as List?) ?? const [])
        id.toString(),
    ];
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
