import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../data/ability_check.dart' show checkPasses;

import '../combat/combat_engine.dart'
    show
        chapterRewardMultiplier,
        isBossEnemy,
        lostFightXpShare,
        scaledReward,
        zoneBossEnemyIds;
import '../combat/context_rules.dart' show ContextRule, Reinforcement;
import '../combat/gear_effects.dart';
import '../combat/spec_variants.dart' show SpecVariantInfo, specVariantsFrom;
import '../combat/specialisations.dart' show SpecInfo, specInfosFrom;
import '../combat/spells.dart';
import '../data/autoplay_engine.dart';
import '../data/autoplay_summary.dart';
import '../data/camp_errands.dart' show storyChoiceTarget;
import '../data/camp_works.dart';
import '../data/chapter_loop.dart';
import '../data/hunter_mercy.dart';
import '../data/patron_stats.dart' show statPatron;
import '../data/camp_rolls.dart' show rollPowerOf;
import '../data/risky_gifts.dart' show riskyGiftsOpen;
import '../data/sim_rolls.dart';
import '../data/rival_hunters.dart' show maybeRivalHunter;
import '../data/road_wards.dart' show wardTargets;
import '../data/alignment_events.dart'
    show hunterCooldownRolls, isHunterAmbushChain, maybeAlignmentEvent;
import '../data/camp_state.dart' show landingPortIdFor;
import '../data/chapter_spine.dart';
import '../data/detour_pacing.dart';
import '../data/detour_scenes.dart';
import '../data/journey_rules.dart' show walkWatches;
import '../data/recurring_encounters.dart'
    show markerFor, recurringBeatsOpen, recurringChance;
import '../data/feature_unlocks.dart' show trainerGuardFlag, trainerStrikeFlag;
import '../data/factions.dart';
import '../data/expedition_steps.dart';
import '../data/perks.dart';
import '../data/politics_events.dart'
    show
        PoliticsEvent,
        choicePoliticsKey,
        enterPoliticsKey,
        parsePoliticsEvents;
import '../data/materials.dart';
import '../data/settlements.dart' show campFoundedFlag;
import '../data/signs.dart';
import '../data/sim_combat.dart';
import '../data/sim_companions.dart';
import '../data/story_companions.dart';
import '../data/story_prices.dart';
import '../data/sim_growth.dart';
import '../data/sim_policy.dart';
import '../data/skill_craft.dart' show skillCraftOpen;
import '../data/sim_quests.dart';
import '../data/temple.dart';
import '../data/town_rulers.dart' show townRulers;
import '../data/story_graph_integrity.dart';
import '../data/story_repository.dart';
import '../data/sub_node_engine.dart';
import '../data/training.dart' show TrainingPath, trainingPathsFrom;
import '../data/zone_gating.dart' show meetsRequiredFlags, zoneIsMain;
import '../data/clan_power.dart' show TerritoryChange;
import '../data/city_districts.dart' show districtOfNode;
import '../data/geography.dart';
import '../data/nemesis.dart'
    show
        breakNemesis,
        championIdOf,
        championMinChapter,
        championRecordFor,
        championRoadChance,
        championWays,
        trailFlagOf;
import '../data/land_crossing.dart';
import '../data/road_events.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/place_pools_provider.dart';
import '../providers/settings_providers.dart';
import '../providers/training_provider.dart';
import '../providers/story_providers.dart';
import '../providers/clans_provider.dart' show loadClanData;
import '../providers/player_session_provider.dart' show playerSessionProvider;
import 'autoplay_summary_dialog.dart';
import '../utils/game_icons.dart';

AutoplayStrategy _toAutoplayStrategy(SimStrategy strategy) {
  switch (strategy) {
    case SimStrategy.random:
      return AutoplayStrategy.random;
    case SimStrategy.favorGood:
      return AutoplayStrategy.favorGood;
    case SimStrategy.favorEvil:
      return AutoplayStrategy.favorEvil;
    case SimStrategy.maximizeGold:
      return AutoplayStrategy.maximizeGold;
    case SimStrategy.explore:
    case SimStrategy.completionist:
      return AutoplayStrategy.random;
  }
}

/// How the simulator picks among a node's valid (non-locked) choices. Lets
/// the user compare "what if the player always chased gold" against "what
/// if they always leaned good/evil" instead of only pure-random runs.
enum SimStrategy {
  random,
  favorGood,
  favorEvil,
  maximizeGold,
  explore,

  /// A thorough human (v1.230): takes every way on of a scene it has not
  /// taken yet, offers of work first and the ways that serve a quest it
  /// holds before the rest, the way that leaves the place last.
  completionist,
}

/// The label the game gives an alignment score (see
/// PlayerSession.alignmentLabel).
String _alignmentLabelOf(int score) =>
    score >= 20 ? 'Good' : (score <= -20 ? 'Evil' : 'Neutral');

/// How often each way on has been taken over a batch of runs, shared by
/// them: the [SimStrategy.explore] walk takes the way on taken least so far,
/// so run after run the batch covers every branch it can (see
/// [simulatePlaythroughs]).
class SimCoverage {
  SimCoverage({this.alternateChecks = false});

  final Map<String, int> taken = {};

  /// Whether the explore walk settles an ability check by the outcome seen
  /// fewer times so far (a pass, or a fail) instead of by the roll, so both
  /// sides of every check are walked. Off, the dice decide.
  final bool alternateChecks;
}

/// A way on's key in [SimCoverage] and in a run's choices taken: the scene,
/// where it leads and its words.
String simChoiceKey(String nodeId, StoryChoice choice) =>
    '$nodeId|${choice.nextId}|${choice.text}';

String _strategyLabelKey(SimStrategy strategy) {
  switch (strategy) {
    case SimStrategy.random:
      return 'sim_strategy_random';
    case SimStrategy.favorGood:
      return 'sim_strategy_favor_good';
    case SimStrategy.favorEvil:
      return 'sim_strategy_favor_evil';
    case SimStrategy.maximizeGold:
      return 'sim_strategy_maximize_gold';
    case SimStrategy.explore:
      return 'sim_strategy_explore';
    case SimStrategy.completionist:
      return 'sim_strategy_completionist';
  }
}

/// One node visited during a simulated run: the node itself (with the text
/// the player would actually have seen) plus the choice taken from it, so a
/// run can be rendered or exported as a readable transcript.
class _SimStep {
  const _SimStep({
    required this.nodeId,
    required this.chapter,
    required this.mood,
    required this.uiTheme,
    required this.description,
    this.choiceText,
    this.enemyId,
    this.goldMod = 0,
    this.alignmentMod = 0,
    this.fightWon,
    this.fightAttempts = 0,
    this.spellsCast = const {},
  });

  final String nodeId;

  /// The chapter this step counts toward. For a main-beat node this is
  /// [chapterForNode]'s own answer; for a side/optional node (which has no
  /// chapter of its own) it's carried forward from the most recent main
  /// beat, so side content is grouped with the chapter it actually
  /// occurred in rather than dumped in one undifferentiated bucket. Null
  /// only for steps before the first main beat.
  final int? chapter;

  final String? mood;
  final String? uiTheme;
  final String description;

  /// The choice text taken from this node, or null for a run's final step
  /// (an ending, a dead end, or a broken link — nothing left to choose).
  final String? choiceText;
  final String? enemyId;
  final int goldMod;
  final int alignmentMod;

  /// How this step's fight went when the walk played it out (see
  /// `sim_combat.dart`): true = won, false = lost every attempt, null = no
  /// fight or no fight model.
  final bool? fightWon;
  final int fightAttempts;

  /// spell id -> casts across this step's fight attempts.
  final Map<String, int> spellsCast;
}

class _SimResult {
  const _SimResult({
    required this.steps,
    required this.finalGold,
    required this.finalAlignment,
    required this.flags,
    required this.shopsDiscovered,
    required this.questsDiscovered,
    required this.combatEncounters,
    required this.endingText,
    required this.reachedStepCap,
    required this.furthestChapter,
    this.raceId = '',
    this.professionId = '',
    this.finalLevel = 0,
    this.fightsWon = 0,
    this.fightsLost = 0,
    this.roundsFought = 0,
    this.spellsCast = const {},
    this.manaGained = 0,
    this.potionsUsed = 0,
    this.spellbooksBought = const [],
    this.signsTaken = const [],
    this.offersTaken = 0,
    this.skillsLearned = 0,
    this.choicesTaken = const [],
    this.checksRolled = 0,
    this.checksFailed = 0,
    this.questRecords = const [],
    this.questsStuck = const {},
    this.arrivals = const {},
    this.housesBuilt = const {},
    this.riskyOutcomes = const {},
    this.crises = const {},
    this.campRolls = const {},
    this.temple = (blessings: 0, gold: 0),
    this.roads = const [],
    this.transcript = const [],
    this.specs = const [],
    this.patron = '',
    this.mercy = (spared: 0, finished: 0, betrayed: 0),
    this.territory = const [],
    this.politics = PoliticsState.empty,
    this.nemeses = const {},
    this.offerPicks = const [],
    this.gear = const {},
    this.die = '',
    this.merged = const [],
    this.companionLog = const [],
    this.companions = const [],
    this.companionKnockouts = const {},
  });

  /// The competent player's companions (sim_companions.dart): every
  /// recruit, pick, swap and loss with its reason; the party at the end;
  /// and how often each was knocked out.
  final List<SimCompanionEvent> companionLog;
  final List<String> companions;
  final Map<String, int> companionKnockouts;

  /// Every clan offer taken: the banners offered, the one taken and why
  /// (SimGrowth.offerPicks).
  final List<SimOfferPick> offerPicks;

  /// The gear worn at the end (slot -> item), the die in play and the
  /// skills crafted at the Skillwright (the competent player's).
  final Map<String, String> gear;
  final String die;
  final List<String> merged;

  /// The specialisations the character held at the end, in the order
  /// taken (specialisations.dart).
  final List<String> specs;

  /// The clan whose passive stats the run ended with (patron_stats.dart);
  /// '' for none.
  final String patron;

  /// The rivals' hunters spared, finished, and come back to betray
  /// (hunter_mercy.dart).
  final ({int spared, int finished, int betrayed}) mercy;

  /// The places that changed hands at the chapters' turns
  /// (clan_power.dart).
  final List<TerritoryChange> territory;

  /// The clans as the run left them: standing, power, places.
  final PoliticsState politics;

  /// Every clan that was the character's nemesis at a chapter's turn.
  final Set<String> nemeses;

  final List<_SimStep> steps;

  /// What each road of the run held (see detour_pacing.dart), in order.
  final List<SimRoad> roads;

  /// The run told step by step, when asked for (see simulatePlaythroughs'
  /// `transcripts`).
  final List<String> transcript;

  /// The camp's works the run built: house id -> the chapter it went up in
  /// (see buildHouses).
  final Map<String, int> housesBuilt;

  /// Risky gifts (risky_gifts.dart): the cards `seen` and `taken`, and
  /// each outcome (`gift`, `health`, `gold`, `curse`).
  final Map<String, int> riskyOutcomes;

  /// The seat crises played (SimGrowth.crisisOutcomes): `held`, `lost`,
  /// `paid`, `refused`; and the districts' sieges (SimGrowth.siegeOutcomes,
  /// district_attacks.dart): `siege_defended`, `siege_defence_lost`,
  /// `siege_taken`, `siege_held`.
  final Map<String, int> crises;

  /// The camp's roll houses (sim_rolls.dart): the `rerolls`, `bans` and
  /// `raises` the walk used.
  final Map<String, int> campRolls;

  /// The temple's blessings bought and the gold they cost (temple.dart).
  final ({int blessings, int gold}) temple;

  /// The character's level and gold when the run first rested at each
  /// chapter's hub (chapter -> (level, gold)), for the balance reports.
  final Map<int, ({int level, int gold})> arrivals;

  /// The ways on taken, in order (see [simChoiceKey]).
  final List<String> choicesTaken;

  /// Ability checks rolled in the run, and how many failed.
  final int checksRolled;
  final int checksFailed;

  /// The quests taken on in the run, with when they were handed in and what
  /// they paid, and what each still undone had left to do at the end.
  final List<SimQuestRecord> questRecords;
  final Map<String, List<String>> questsStuck;
  final int finalGold;
  final int finalAlignment;
  final Set<String> flags;
  final Set<String> shopsDiscovered;
  final Set<String> questsDiscovered;
  final int combatEncounters;
  final String endingText;
  final bool reachedStepCap;
  final int? furthestChapter;

  /// The simulated character's build and combat record (see
  /// [SimCharacter]); empty/zero when the walk ran without a fight model.
  final String raceId;
  final String professionId;
  final int finalLevel;
  final int fightsWon;
  final int fightsLost;

  /// Rounds fought over the run's fights, won or lost.
  final int roundsFought;

  /// spell id -> casts over the whole run.
  final Map<String, int> spellsCast;
  final int manaGained;
  final int potionsUsed;
  final List<String> spellbooksBought;

  /// The signs the character took (see signs.dart), in order.
  final List<String> signsTaken;

  /// The clans' offers taken (v1.194, see offers.dart), and the skills
  /// learned (with points under the old rules, from offers under the new).
  final int offersTaken;
  final int skillsLearned;

  bool get hasCharacter => professionId.isNotEmpty;
  int get totalCasts => spellsCast.values.fold(0, (a, b) => a + b);

  List<String> get path => steps.map((s) => s.nodeId).toList();
  int get uniqueNodesVisited => steps.map((s) => s.nodeId).toSet().length;

  /// A short, always-non-empty label for grouping/displaying this run's
  /// outcome, since [endingText] is blank when the step cap was hit.
  String get endingSummary {
    if (reachedStepCap) return '(did not reach an ending)';
    if (endingText.trim().isEmpty) return '(unnamed ending)';
    final oneLine = endingText.replaceAll('\n', ' ').trim();
    return oneLine.length > 80 ? '${oneLine.substring(0, 80)}…' : oneLine;
  }
}

/// Everything the fight model needs (see `sim_combat.dart`) -- the walk
/// runs without one when this is null, counting encounters as it always
/// did instead of playing them out.
class _SimContext {
  const _SimContext({
    required this.dice,
    required this.skills,
    required this.items,
    required this.shops,
    required this.races,
    required this.professions,
    required this.spells,
    required this.gameConfig,
    this.itemSets = const {},
    this.zones = const {},
    this.patrons = const {},
    this.signs = const {},
    this.clans = ClanData.empty,
    this.skillTrees = const {},
    this.progression = SimProgression.offers,
    this.geography,
    this.clash = true,
    this.clashOff = const {},
    this.quests = const {},
    this.npcs = const {},
    this.landRoutes = const {},
    this.landEvents = const {},
    this.houses = const {},
    this.writtenSteps = const {},
    this.detourScenes = const {},
    this.ports = const {},
    this.startSpecs = const [],
    this.context,
    this.reinforcement = Reinforcement.none,
    this.championFights = false,
    this.featureLadder = false,
    this.specs = const {},
    this.specVariants = const {},
    this.trainingPaths = const {},
    this.politicsEvents = const {},
    this.policy = SimPolicy.naive,
    this.merges = const {},
    this.companions = const {},
  });

  /// companions.json: whom the competent player recruits and seats
  /// (sim_companions.dart). None, or the naive player: a solo run.
  final Map<String, dynamic> companions;

  /// How the simulated player plays its choices (sim_policy.dart): naive,
  /// the CI bands' measure, or competent, a real player's.
  final SimPolicy policy;

  /// skill_merges.json: what the competent player crafts at the
  /// Skillwright.
  final Map<String, dynamic> merges;

  /// politics_events.json parsed: the events the coast fires as the walk
  /// reaches a chapter and moves on (SimGrowth.runEvents). None, none fire.
  final Map<String, PoliticsEvent> politicsEvents;

  /// training_paths.json parsed: with them the levels' stat points are
  /// stat picks (SimCharacter.takeStatPicks).
  final Map<String, TrainingPath> trainingPaths;

  /// specialisations.json parsed: what the clans offer (specialisations.dart);
  /// and spec_variants.json, their sub-clans' variants and ranks II.
  final Map<String, SpecInfo> specs;
  final Map<String, SpecVariantInfo> specVariants;

  /// Specialisations the character holds from the start (to measure each
  /// one, see specialisations_test.dart); those of another profession
  /// play nothing.
  final List<String> startSpecs;

  /// A context rule every fight plays (context_rules.dart), to measure
  /// each one; null: the Tide (no fight's place is known here).
  final ContextRule? context;

  /// Reinforcements in every fight (context_rules.dart), to measure them;
  /// none: no fight's place is known here.
  final Reinforcement reinforcement;

  /// The nemeses' champions fought on the roads (nemesis.dart), to measure
  /// them; off, as the walk takes no quest a road opens.
  final bool championFights;

  /// The game's feature ladder (feature_unlocks.dart): off by default, so
  /// the measured curves stay comparable; on, to measure it.
  final bool featureLadder;

  /// detour_scenes.json: the detours' written scenes (detour_scenes.dart).
  final Map<String, DetourScene> detourScenes;

  /// ports.json: which places the camp's trips sail to (no road, no
  /// detour) rather than walk.
  final Map<String, dynamic> ports;

  /// expedition_steps.json: each zone's written road (see
  /// expedition_steps.dart), walked step by step instead of drawn events.
  final Map<String, List<WrittenStep>> writtenSteps;

  /// land_routes.json and land_events.json's events: the land crossings
  /// the walk plays (see land_crossing.dart).
  final Map<String, dynamic> landRoutes;
  final Map<String, LandEvent> landEvents;

  /// houses.json: the camp's works the walk builds (see buildHouses).
  final Map<String, dynamic> houses;

  /// quests.json and npcs.json: the quests the walk takes on and hands in.
  final Map<String, dynamic> quests;
  final Map<String, dynamic> npcs;

  /// Play the v1.212-v1.215 fight rules (goals, squads, parries, ...).
  final bool clash;

  /// Clash rules to leave out ('goal', 'squad', 'response', 'parry',
  /// 'reaction', 'writ', and the fight-length rules 'fatigue', 'execute',
  /// 'morale', 'packBreak', 'tide'), to see what each one does to the
  /// numbers.
  final Set<String> clashOff;

  final Map<String, dynamic> dice;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> items;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;
  final Map<String, SpellSpec> spells;
  final Map<String, dynamic> gameConfig;
  final Map<String, ItemSet> itemSets;

  /// zones.json, for the expeditions a choice launches.
  final Map<String, dynamic> zones;

  /// The patrons and their signs (see signs.dart): without them the
  /// character never takes one.
  final Map<String, Patron> patrons;
  final Map<String, SignDef> signs;

  /// The clans (factions, sub-clans, relations, titles) and the skill
  /// trees: what the offers draw from.
  final ClanData clans;
  final Map<String, dynamic> skillTrees;

  /// How the character grows: the clans' offers (the game's rules since
  /// v1.194), or the old skill points, perks and sign picks, to compare.
  final SimProgression progression;

  /// The world's places and biomes (v1.197): the hazards on the roads.
  /// None, no hazards.
  final Geography? geography;

  SimGrowthTables get growthTables => SimGrowthTables(
        skills: skills,
        skillTrees: skillTrees,
        items: items,
        spells: spells,
        patrons: patrons,
        signs: signs,
        clans: clans,
        specs: specs,
        specVariants: specVariants,
        events: politicsEvents,
        itemSets: itemSets,
        merges: merges,
      );
}

/// A lost fight is retried this many times, as a player would, before the
/// walk moves on (counting it lost) so the story can still be traced.
const int _maxFightAttempts = 3;

/// Things the simulated party does in a place on its one tour of it (see
/// the camp loop in [_simulate]).
const int _placeActivitiesPerVisit = 3;

/// The share of an expedition's events the walk plays as a fight: an
/// event draw is a fight a quarter of the time where the zone has shops,
/// half where it has none (see SubNodeEngine.buildNode).
const double _expeditionFightShare = 0.35;

/// Auto-plays the story graph making choices (picked per [strategy]) until
/// an ending is reached, for QA / previewing a full run without clicking
/// through it by hand. This is a read-only simulation over a local
/// gold/alignment/flags model — it never touches the real player's saved
/// session. With a [sim] context it also plays every combat choice out
/// for a simulated character (random race and profession) with the real
/// engine, mana and spells, recording each fight's outcome and casts.
_SimResult _simulate(
  StoryData story,
  Random random, {
  Map<String, dynamic> enemies = const {},
  SimStrategy strategy = SimStrategy.random,
  int maxSteps = 400,
  bool french = false,
  _SimContext? sim,
  String? forceRaceId,
  String? forceProfessionId,
  SimCoverage? coverage,
  int detourSalt = 0,
  bool transcribe = false,
}) {
  final choicesTaken = <String>[];
  final takenHere = <String, int>{};
  var checksRolled = 0, checksFailed = 0;
  final questLog = sim == null || sim.quests.isEmpty
      ? null
      : SimQuestLog(sim.quests, npcs: sim.npcs);
  int combatGoldReward(StoryChoice c) {
    if (!c.triggersCombat) return 0;
    var total = 0;
    for (final id in c.allTriggerEnemyIds) {
      final enemy = enemies[id] as Map<String, dynamic>?;
      total += (enemy?['goldReward'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  SimCharacter? character;
  if (sim != null && sim.races.isNotEmpty && sim.professions.isNotEmpty) {
    final raceIds = sim.races.keys.toList()..sort();
    final professionIds = sim.professions.keys.toList()..sort();
    // The race and profession are drawn either way (the run's other draws
    // do not shift), then replaced when the caller names one.
    final drawnRace = raceIds[random.nextInt(raceIds.length)];
    final drawnProfession = professionIds[random.nextInt(professionIds.length)];
    if (forceRaceId != null && !sim.races.containsKey(forceRaceId)) {
      throw ArgumentError.value(forceRaceId, 'forceRaceId', 'unknown race');
    }
    if (forceProfessionId != null &&
        !sim.professions.containsKey(forceProfessionId)) {
      throw ArgumentError.value(
          forceProfessionId, 'forceProfessionId', 'unknown profession');
    }
    final raceId = forceRaceId ?? drawnRace;
    final professionId = forceProfessionId ?? drawnProfession;
    character = SimCharacter.create(
      raceId: raceId,
      race: sim.races[raceId] as Map<String, dynamic>,
      professionId: professionId,
      profession: sim.professions[professionId] as Map<String, dynamic>,
      gameConfig: sim.gameConfig,
      dice: sim.dice,
      spells: sim.spells,
    )
      ..specIds = [...sim.startSpecs]
      ..trainingPaths = sim.trainingPaths
      ..pickRandom = Random(detourSalt * 31 + 17)
      ..policy = sim.policy
      // The camp's roll houses draw on their own (sim_rolls.dart).
      ..rolls = SimRolls(Random(detourSalt * 31 + 29));
  }

  var currentId = StoryRepository.startNodeId;
  var gold = character?.startingGold ?? 0;
  var alignment = 0;
  final flags = <String>{};
  final shops = <String>{};
  final quests = <String>{};
  var combatCount = 0;
  int? furthestChapter = chapterForNode(currentId);
  int? lastKnownChapter = furthestChapter;
  int? restedChapter = lastKnownChapter;
  final arrivals = <int, ({int level, int gold})>{};
  // The camp's works (v1.291): the materials the walk has picked up, the
  // houses it has built (house -> the chapter it went up in) and the gold
  // they cost, kept apart from the purse it shops with (see buildHouses).
  var materials = <String>[];
  final housesBuilt = <String, int>{};
  var houseGoldSpent = 0;
  // The temple's blessing (temple.dart): bought at a chapter's hub, worn
  // for the next fights (every attempt one of them); the count and the
  // gold go in the report.
  var blessingFights = 0;
  var blessingClan = '';
  var blessingsBought = 0;
  var blessingGold = 0;
  final templeStandingChapters = <String, int>{};
  final steps = <_SimStep>[];
  // How the character grows (see sim_growth.dart): the clans' offers, or
  // the old skill points, perks and sign picks.
  final growth = character == null || sim == null
      ? null
      : (SimGrowth(
          mode: sim.progression,
          tables: sim.growthTables,
          character: character,
          startingSkillPoints: (sim.professions[character.professionId]
                  as Map<String, dynamic>?)?['startingSkillPoints'] as int? ??
              0,
          ladder: sim.featureLadder,
          policy: sim.policy,
        )..passives = !sim.clashOff.contains('passives'));
  // The companions (sim_companions.dart): the story's own (Vica) for every
  // policy; the competent and the stubborn player's recruited by their
  // quests too. Seated by the pick rule, in every fight.
  final party = character == null || sim == null || sim.companions.isEmpty
      ? null
      : SimParty(
          companions: sim.companions,
          races: sim.races,
          professions: sim.professions,
          gameConfig: sim.gameConfig,
          dice: sim.dice,
          skills: sim.skills,
          houses: sim.houses,
        );
  // The open chapters' loop: the camp the story stands at, the places
  // already toured from it, and the place being toured now (with how many
  // things are left to do there).
  final visited = <String>{currentId};
  String? campId;
  final toured = <String>{};
  // The camp expeditions the walk has played (see the camp tour).
  final campExpeditionsPlayed = <String>{};
  String? tourPlaceId;
  var tourBudget = 0;

  // The roads (v1.355, detour_pacing.dart): the pacing, the hunters'
  // cooldown, the familiar faces met (their markers, kept apart from the
  // story's flags: the walk doesn't play them), and what each road held.
  // Their dice are the road's own (detourRandomFor, salted per run), never
  // the walk's, so the rest of the run draws as it did.
  var pacing = const DetourPacing();
  var rollsSinceAmbush = hunterCooldownRolls;
  // Mercy for the rivals' hunters (hunter_mercy.dart): the flags it keeps,
  // and what came of it. The walk spares a hunter whose betrayal is under
  // [_simSpareUnder].
  final mercyFlags = <String>[];
  // The nemeses' champions beaten (nemesis.dart; [_SimContext.championFights]).
  final championsBeaten = <String>{};
  // The fight the roads call before it is declared (fightEnemies).
  late ({bool? won, int attempts, Map<String, int> casts}) Function(
      List<String> enemyIds, int chapter,
      {Map<String, Map<String, dynamic>> records}) fightOnRoad;
  // The nemeses whose trail was followed (nemesis.dart's first beat).
  final trailsFollowed = <String>{};
  var spared = 0, finished = 0, betrayed = 0;
  final metOnRoads = <String>{};
  final roads = <SimRoad>[];
  // The transcript's notes (party, standing, flags), by the step they
  // come before.
  final notes = <int, List<String>>{};
  void note(String line) {
    if (transcribe) notes.putIfAbsent(steps.length, () => []).add(line);
  }

  /// What the road from [fromId] to [toId] holds, by the game's rules
  /// (see startRoadEncounter): recorded, not played (the walk passes a
  /// detour by, as it always has; its scene and its foe are in the
  /// transcript). [travels]: a walk between places whatever the scenes
  /// say (the camp's trips); [taken]: a road event holds it.
  void roadTurn(String fromId, String toId,
      {bool travels = false, bool taken = false}) {
    final geo = sim?.geography;
    final chapter = lastKnownChapter;
    if (geo == null || chapter == null) return;
    final road = detourRoadBetween(story, geo,
        fromNodeId: fromId,
        toNodeId: toId,
        chapter: chapter,
        travels: travels,
        watches: travels
            ? geo.watchesToNode(story.nodeFor(toId), fallback: walkWatches)
            : 1);
    if (road == null) return;
    final dice = detourRandomFor(
        fromNodeId: fromId,
        toNodeId: toId,
        historyLength: steps.length,
        salt: detourSalt);
    final side = detourRandomFor(
        fromNodeId: fromId,
        toNodeId: toId,
        historyLength: steps.length,
        salt: detourSalt + 7919);
    var hunter = '';
    final landmarkDue = landmarkDueOn(
        pacing: pacing,
        road: road,
        scenes: sim?.detourScenes ?? const {},
        flags: flags);
    if (!taken &&
        !landmarkDue &&
        road.atRest &&
        chapter >= SubNodeEngine.firstDetourChapter) {
      // A betrayal due comes first.
      final coming = pendingBetrayals(mercyFlags);
      String? betrayer;
      if (coming.isNotEmpty) {
        mercyFlags.removeWhere((f) => f.startsWith('betrayal_'));
        for (final MapEntry(key: id, value: roads) in coming.entries) {
          if (roads <= 1 && betrayer == null) {
            betrayer = id;
            mercyFlags.add(betrayerFlag(id));
          } else {
            mercyFlags.add(betrayalFlag(id, max(1, roads - 1)));
          }
        }
      }
      final event = betrayer != null
          ? null
          : maybeAlignmentEvent(
              alignmentScore: alignment,
              activeQuestIds: const [],
              completedQuestIds: const [],
              enemies: enemies,
              chapter: chapter,
              random: side,
              rollsSinceAmbush: rollsSinceAmbush,
            );
      // The Warding Cairn turns the nemesis's hunters away (road_wards.dart).
      final rolls = character?.rolls;
      if (rolls != null && growth != null) {
        rolls.wardNemesis(growth.politics.nemesis,
            wardTargets(growth.politics, growth.tables.clans));
      }
      // Sworn, the rivals' hunters (v5.2 step 3b) share the road.
      final rival = event == null && betrayer == null && growth != null
          ? maybeRivalHunter(
              politics: growth.politics,
              data: growth.tables.clans,
              enemies: enemies,
              chapter: chapter,
              random: side,
              cooledDown: rollsSinceAmbush >= hunterCooldownRolls,
              flags: mercyFlags,
              warded: rolls?.warded ?? const {},
            )
          : null;
      rolls?.roadAtRest();
      final ambush = (event != null && isHunterAmbushChain(event)) ||
          rival != null ||
          betrayer != null;
      rollsSinceAmbush =
          ambush ? 0 : min(hunterCooldownRolls, rollsSinceAmbush + 1);
      if (betrayer != null) {
        hunter = 'betrayal';
        betrayed++;
      } else if (rival != null) {
        final hunterId = rival.first.choices.first.triggerEnemyId ?? '';
        final clan =
            (enemies[hunterId] as Map<String, dynamic>?)?['hunterClan'];
        hunter = clan != null && clan == growth?.politics.nemesis
            ? 'nemesis_hunter'
            : 'rival_hunter';
        // Beaten (the walk doesn't fight a road's hunter), it is spared
        // when its betrayal is unlikely.
        final id = rival.first.choices.first.triggerEnemyId ?? '';
        final chance = betrayalChance(
            hunterAlignmentOf(enemies[id] as Map<String, dynamic>?), alignment);
        if (chance < _simSpareUnder) {
          spared++;
          mercyFlags.add(side.nextDouble() < chance
              ? betrayalFlag(id, betrayalRoads(side))
              : sparedFlag(id));
        } else {
          finished++;
        }
      } else if (event != null) {
        hunter = ambush ? 'hunter' : 'temptation';
      }
      // The nemesis's champion (nemesis.dart), to measure it: its quest
      // taken as it opens, met on a road at rest; beaten, the nemesis is
      // broken.
      final nemesis = growth?.politics.nemesis ?? '';
      if (sim?.championFights == true &&
          hunter.isEmpty &&
          nemesis.isNotEmpty &&
          chapter >= championMinChapter &&
          !championsBeaten.contains(nemesis) &&
          side.nextDouble() < championRoadChance) {
        hunter = 'champion';
        final champion = championIdOf(nemesis);
        // The trail first, then the champion by a way in drawn at random,
        // with its edge.
        final way = championWays[side.nextInt(championWays.length)];
        final record = enemies[champion];
        final result = !trailsFollowed.contains(nemesis)
            ? (won: null, attempts: 0, casts: const <String, int>{})
            : fightOnRoad([champion], chapter,
                records: {
                  if (record is Map<String, dynamic>)
                    champion: championRecordFor(record, way),
                });
        if (!trailsFollowed.contains(nemesis)) {
          trailsFollowed.add(nemesis);
          steps.add(_SimStep(
            nodeId: 'road:${trailFlagOf(nemesis)}',
            chapter: chapter,
            mood: null,
            uiTheme: null,
            description: 'The nemesis\'s trail',
            choiceText: 'Follow the trail',
          ));
        } else if (result.won != null) {
          steps.add(_SimStep(
            nodeId: 'road:$champion',
            chapter: chapter,
            mood: null,
            uiTheme: null,
            description: 'The nemesis\'s champion',
            choiceText: 'The way of $way',
            enemyId: champion,
            fightWon: result.won,
            fightAttempts: result.attempts,
            spellsCast: result.casts,
          ));
          if (result.won == true) {
            championsBeaten.add(nemesis);
            growth!.politics = breakNemesis(
                growth.politics, nemesis, growth.tables.clans,
                chapter: chapter);
          }
        }
      }
    }
    var familiar = '';
    final turn = planRoad(
      pacing: pacing,
      road: road,
      scenes: sim?.detourScenes ?? const {},
      flags: flags,
      random: dice,
      taken: taken || hunter.isNotEmpty,
      familiar: () {
        final open = recurringBeatsOpen(
            flags: {...flags, ...metOnRoads}, chapter: chapter);
        if (open.isEmpty || side.nextDouble() >= recurringChance) return false;
        final pick = open[side.nextInt(open.length)];
        metOnRoads.add(markerFor(pick.who, pick.stage));
        familiar = '${pick.who} ${pick.stage}';
        return true;
      },
    );
    pacing = turn.next;
    final kind = switch (turn.kind) {
      RoadTurnKind.quiet => 'quiet',
      RoadTurnKind.owed => 'owed',
      RoadTurnKind.taken => taken ? 'road_event' : hunter,
      RoadTurnKind.familiar => 'familiar',
      RoadTurnKind.detour => turn.scene == null ? 'chain' : 'scene',
    };
    roads.add((
      chapter: chapter,
      from: fromId,
      to: toId,
      streets: road.kind == DetourRoadKind.streets,
      atRest: road.atRest,
      kind: kind,
      sceneId: turn.scene?.id,
      landmark: turn.landmark,
      paysOwed: turn.paysOwed,
    ));
    if (kind == 'quiet') return;
    final what = switch (kind) {
      'scene' =>
        '${french ? 'Détour' : 'Detour'}: ${turn.scene!.titleFor(french)}'
            '${turn.landmark ? ' (landmark)' : ''}',
      'chain' => french ? 'Détour (au hasard)' : 'Detour (drawn)',
      'familiar' => '${french ? 'Visage connu' : 'Familiar face'}: $familiar',
      'owed' => french ? 'Détour dû (crise)' : 'Detour owed (a crisis)',
      _ => kind,
    };
    steps.add(_SimStep(
      nodeId: 'road:$kind${turn.scene == null ? '' : ':${turn.scene!.id}'}',
      chapter: chapter,
      mood: null,
      uiTheme: null,
      description: '$what${turn.paysOwed ? ' (owed)' : ''}',
    ));
  }

  _SimResult finish(
      {required String endingText, required bool reachedStepCap}) {
    return _SimResult(
      steps: steps,
      finalGold: gold,
      finalAlignment: alignment,
      flags: flags,
      shopsDiscovered: shops,
      questsDiscovered: quests,
      combatEncounters: combatCount,
      endingText: endingText,
      reachedStepCap: reachedStepCap,
      furthestChapter: furthestChapter,
      raceId: character?.raceId ?? '',
      professionId: character?.professionId ?? '',
      finalLevel: character?.level ?? 0,
      fightsWon: character?.fightsWon ?? 0,
      fightsLost: character?.fightsLost ?? 0,
      roundsFought: character?.roundsFought ?? 0,
      spellsCast: Map.unmodifiable(character?.spellsCast ?? const {}),
      manaGained: character?.manaGained ?? 0,
      potionsUsed: character?.potionsUsed ?? 0,
      spellbooksBought:
          List.unmodifiable(character?.spellbooksBought ?? const []),
      signsTaken: List.unmodifiable(growth?.signsTaken ?? const <String>[]),
      offersTaken: growth?.giftsTaken.values.fold<int>(0, (a, b) => a + b) ?? 0,
      skillsLearned: growth?.skillsLearned ?? 0,
      choicesTaken: List.unmodifiable(choicesTaken),
      checksRolled: checksRolled,
      checksFailed: checksFailed,
      questRecords: List<SimQuestRecord>.unmodifiable(
          questLog?.records.values ?? const <SimQuestRecord>[]),
      questsStuck: questLog?.unmet(flags) ?? const {},
      arrivals: Map.unmodifiable(arrivals),
      housesBuilt: Map.unmodifiable(housesBuilt),
      riskyOutcomes: Map.unmodifiable(growth?.riskyOutcomes ?? const {}),
      crises: Map.unmodifiable({
        ...?growth?.crisisOutcomes,
        for (final e
            in growth?.siegeOutcomes.entries ?? const <MapEntry<String, int>>[])
          'siege_${e.key}': e.value,
      }),
      campRolls: Map.unmodifiable(character?.rolls?.used ?? const {}),
      temple: (blessings: blessingsBought, gold: blessingGold),
      roads: List.unmodifiable(roads),
      specs: List.unmodifiable(character?.specIds ?? const <String>[]),
      patron: growth == null ? '' : statPatron(growth.politics),
      mercy: (spared: spared, finished: finished, betrayed: betrayed),
      territory: List.unmodifiable(growth?.territoryChanges ?? const []),
      politics: growth?.politics ?? PoliticsState.empty,
      nemeses: Set.unmodifiable(growth?.nemeses ?? const <String>{}),
      offerPicks: List.unmodifiable(growth?.offerPicks ?? const []),
      gear: Map.unmodifiable(character?.equippedBySlot ?? const {}),
      die: character?.diceId ?? '',
      merged: List.unmodifiable(growth?.merged ?? const <String>[]),
      companionLog: List.unmodifiable(party?.log ?? const []),
      companions: List.unmodifiable(party?.active ?? const <String>[]),
      companionKnockouts: Map.unmodifiable(party?.knockouts ?? const {}),
      transcript: transcribe
          ? [
              for (final (i, step) in steps.indexed) ...[
                ...?notes[i],
                '[ch ${step.chapter ?? 0}] ${step.nodeId}'
                    '${step.choiceText == null ? '' : ' · ${step.choiceText}'}'
                    '${step.enemyId == null ? '' : ' · fight ${step.enemyId}: ${step.fightWon == true ? 'won' : step.fightWon == false ? 'lost' : '-'}'}'
                    '${step.nodeId.startsWith('road:') ? ' · ${step.description}' : ''}',
              ],
              ...?notes[steps.length],
            ]
          : const [],
    );
  }

  StoryChoice pickAmong(List<StoryChoice> pool) {
    // The competent player who keeps companions takes the way that offers
    // a companion's quest it may take (quests.json `rewardAllyId`): the
    // first such way, before its strategy speaks.
    final p = party, log = questLog;
    if (p != null && log != null && pool.length > 1) {
      for (final c in pool) {
        final id = c.unlockQuestId ?? '';
        final ally = id.isEmpty
            ? ''
            : (sim?.quests[id] as Map?)?['rewardAllyId']?.toString() ?? '';
        if (ally.isEmpty ||
            p.roster.containsKey(ally) ||
            p.lost.contains(ally) ||
            p.departed.contains(ally) ||
            !log.canTake(id,
                flags: flags,
                gold: gold,
                alignmentLabel: _alignmentLabelOf(alignment))) {
          continue;
        }
        p.log.add(SimCompanionEvent(
            chapter: lastKnownChapter ?? 1,
            kind: 'seek',
            companionId: ally,
            reason: 'took the way offering $id at $currentId'));
        return c;
      }
    }
    if (strategy == SimStrategy.random || pool.length == 1) {
      return pool[random.nextInt(pool.length)];
    }
    int score(StoryChoice c) {
      switch (strategy) {
        case SimStrategy.favorGood:
          return c.alignmentMod;
        case SimStrategy.favorEvil:
          return -c.alignmentMod;
        case SimStrategy.maximizeGold:
          return c.goldMod + combatGoldReward(c);
        case SimStrategy.explore:
          // The way taken fewest times so far, over every run of the batch.
          return -(coverage?.taken[simChoiceKey(currentId, c)] ?? 0);
        case SimStrategy.completionist:
          // Ways not taken yet first (a hub's every beat before leaving it),
          // the work on offer and what serves a quest held before the rest,
          // the way on out of the place last.
          var score = (takenHere[simChoiceKey(currentId, c)] ?? 0) == 0
              ? 10
              : -3 * takenHere[simChoiceKey(currentId, c)]!;
          final log = questLog;
          if (log != null) {
            final id = c.unlockQuestId ?? '';
            if (id.isNotEmpty &&
                log.canTake(id,
                    flags: flags,
                    gold: gold,
                    alignmentLabel: _alignmentLabelOf(alignment))) {
              score += 6;
            }
            final want = log.wanted(flags);
            if (c.flagsToAdd.any(want.flags.contains)) score += 5;
            if (c.allTriggerEnemyIds.any(want.foes.contains)) score += 5;
          }
          if (c.mainQuest || c.isEnding) score -= 4;
          return score;
        case SimStrategy.random:
          return 0;
      }
    }

    final best = pool.map(score).reduce(max);
    final tied = pool.where((c) => score(c) == best).toList();
    return tied[random.nextInt(tied.length)];
  }

  StoryChoice pickChoice(List<StoryChoice> pool) {
    final picked = pickAmong(pool);
    final key = simChoiceKey(currentId, picked);
    choicesTaken.add(key);
    takenHere[key] = (takenHere[key] ?? 0) + 1;
    if (coverage != null) {
      coverage.taken[key] = (coverage.taken[key] ?? 0) + 1;
    }
    return picked;
  }

  /// What the character fights with now; in one of the last battles
  /// ([host], v1.196) the Host fights beside them.
  SignEffects signsNow({bool host = false}) =>
      growth?.effects(alignment,
          host: host,
          blessing: growth.tables.clans.factions.isEmpty
              ? const []
              : activeBlessingEffects(
                  blessingFights: blessingFights,
                  blessingClan: blessingClan,
                  data: growth.tables.clans)) ??
      SignEffects.none;

  /// A chapter's hub [node] in [chapter]: the walk buys a blessing at its
  /// town's temple when the purse holds [simBlessingGoldFactor] times the
  /// price (docs/proposals/temple-service.md section 6); Mending isn't
  /// simulated (the walk rests at each hub already).
  void blessAtHub(StoryNode node, int chapter) {
    final g = growth;
    final geography = sim?.geography;
    if (g == null || geography == null || g.tables.clans.factions.isEmpty) {
      return;
    }
    final data = g.tables.clans;
    // The camp is a town by its city plan, which the walk doesn't load:
    // every camp counts as one here.
    final clanId = templeClanOfPlace(
        geography.placeOfNode(node)?.id,
        townRulers(geography, g.politics, data.factions, planIds: [
          for (final p in geography.places.values)
            if (p.level == GeoLevel.location && p.kind == 'camp') p.id,
        ]),
        geography);
    if (clanId == null) return;
    final offer = templeOfferFor(
        clanId: clanId,
        data: data,
        politics: g.politics,
        chapter: chapter,
        day: 0,
        gold: gold,
        alignment: alignment,
        blessingFights: blessingFights,
        standingChapters: templeStandingChapters);
    if (!offer.canBless || gold < simBlessingGoldFactor * offer.blessingPrice) {
      return;
    }
    gold -= offer.blessingPrice;
    blessingGold += offer.blessingPrice;
    blessingsBought++;
    blessingFights = templeBlessingFights;
    blessingClan = offer.clanId;
    if (offer.blessingStanding) {
      templeStandingChapters[offer.clanId] = chapter;
      g.politics = applyStandingChange(
              g.politics, offer.clanId, templeStandingGain, 'temple',
              data: data, chapter: chapter)
          .state;
    }
    if (transcribe) {
      note('   temple: blessed by ${clanId.isEmpty ? 'the town' : clanId} '
          'for ${offer.blessingPrice} gold'
          '${offer.blessingStanding ? ' (+1 standing)' : ''}');
    }
  }

  /// A story choice's or a scene's politics (v1.196: the claim, the
  /// pledges, the Throne and the muster with the rest), once under [key],
  /// in the chapter the walk is in.
  void applyPolitics(StoryPolitics? politics, String key,
      {String cause = 'sim'}) {
    final g = growth;
    if (g == null || politics == null || politics.isEmpty) return;
    final after = g.applyStoryPolitics(politics,
        flags: flags,
        chapter: lastKnownChapter ?? 1,
        key: key,
        cause: cause,
        geography: sim?.geography);
    flags
      ..clear()
      ..addAll(after);
  }

  /// The politics events due now (politics_events.dart), as the app fires
  /// them on a chapter change and a day's tick: here, at each scene the
  /// walk enters, after a new chapter's turn.
  void runEvents() {
    final g = growth;
    if (g == null) return;
    final after = g.runEvents(
        flags: flags,
        chapter: lastKnownChapter ?? 1,
        geography: sim?.geography);
    flags
      ..clear()
      ..addAll(after);
  }

  /// How [choice] stands behind its politics gate (see choicePoliticsGate):
  /// without the clans' tables every gate is open.
  bool gateOpen(StoryChoice choice) =>
      growth?.gateOpen(choice, flags: flags, chapter: lastKnownChapter ?? 1) ??
      true;

  /// Spends whatever growth waits (see SimGrowth.settle): the offers, or
  /// the points and picks; the alignment moves with what is taken.
  void settle() {
    final g = growth;
    if (g == null) return;
    // Risky gifts once the Parley Tent is up (risky_gifts.dart): a gold
    // penalty comes out of the purse.
    g
      ..riskyGifts = riskyGiftsOpen(housesBuilt.keys)
      ..gold = gold
      ..chapter = lastKnownChapter ?? 1;
    alignment = g.settle(alignment: alignment, flags: flags, random: random);
    gold = g.gold;
  }

  // The camp's works (buildHouses), which a recruit may open (Kelda's Hall).
  late final void Function() buildHousesNow;

  /// Hands in every quest whose objectives are met (the player does it at
  /// once): talks to the people they ask for, takes the pay, the XP, the
  /// item and the follow-up quest, and settles a quest that offers a choice
  /// the way the player leans.
  void settleQuests(int atStep) {
    final log = questLog;
    if (log == null) return;
    log.talkToAvailable(lastKnownChapter ?? 1);
    final bias = switch (strategy) {
      SimStrategy.favorGood => SimTurnInBias.good,
      SimStrategy.favorEvil => SimTurnInBias.evil,
      SimStrategy.maximizeGold => SimTurnInBias.gold,
      _ => SimTurnInBias.any,
    };
    for (final id in log.ready(flags)) {
      final pay = log.complete(id, step: atStep, bias: bias, random: random);
      gold = (gold + pay.gold).clamp(0, 1 << 30).toInt();
      alignment += pay.alignment;
      if (pay.flag.isNotEmpty) flags.add(pay.flag);
      // How it was settled moves the clans, as in the app (v1.463, see
      // quest_turn_in.dart): once, logged under the quest, so a main clan
      // it raises by questPowerStanding gains questPower and is spared
      // this chapter's neglect.
      applyPolitics(pay.politics, pay.politicsKey, cause: 'quest:$id');
      // Its influence in its district (wave 18 step 2: anywhere), as in the app.
      final world = sim?.geography;
      final quest = sim?.quests[id];
      if (growth != null && world != null && quest is Map<String, dynamic>) {
        final here = story.nodeFor(currentId);
        final after = growth.applyQuestInfluence(quest,
            flags: flags,
            geography: world,
            chapter: lastKnownChapter ?? 1,
            picked: pay.politics,
            partyDistrict: districtOfNode(world, here)?.id);
        flags
          ..clear()
          ..addAll(after);
      }
      final c = character;
      if (c != null) {
        final before = c.level;
        c.gainXp(pay.xp);
        growth?.levelsReached(before, c.level);
        party?.levelIs(c.level);
      }
      // A companion's quest recruits them; then the party sees how it was
      // settled, the newcomer too (quest_turn_in.dart).
      final p = party;
      if (p != null) {
        final ch = lastKnownChapter ?? 1;
        if (pay.allyId.isNotEmpty &&
            sim?.policy != SimPolicy.naive &&
            p.recruit(pay.allyId,
                chapter: ch, cause: 'quest $id', alignment: alignment)) {
          buildHousesNow();
        }
        p.react(
            chapter: ch,
            cause: 'quest $id',
            alignmentMod: pay.alignment,
            goldMod: pay.profit,
            approvalMods: pay.approvalMods,
            alignment: alignment);
      }
      steps.add(_SimStep(
        nodeId: 'quest:$id',
        chapter: lastKnownChapter,
        mood: null,
        uiTheme: null,
        description:
            (french ? 'Quête rendue\u00a0: ' : 'Quest done: ') + pay.name,
        choiceText: pay.turnIn.isEmpty
            ? (french ? 'Rendre la quête' : 'Hand in')
            : pay.turnIn,
        goldMod: pay.gold,
        alignmentMod: pay.alignment,
      ));
      settle();
      if (pay.nextQuestId.isNotEmpty) {
        log.accept(pay.nextQuestId,
            step: atStep,
            flags: flags,
            gold: gold,
            alignmentLabel: _alignmentLabelOf(alignment));
      }
    }
  }

  /// Plays out a fight against [enemyIds] (a pack when several) for the
  /// simulated character, retrying a loss up to [_maxFightAttempts] times
  /// ([once]: a fight with a defeat branch is played once, its loss is a
  /// scene); a win grants the enemies' XP through the app's own level
  /// thresholds, and the growth its levels and a boss bring. Returns the
  /// outcome, the attempts it took, every spell cast across them, what the
  /// winning attempt fought with (its signs and perks, which scale the
  /// gold) and the gold a Crow's Price stole -- or a null outcome when
  /// there is nothing to play.
  ({
    bool? won,
    int attempts,
    Map<String, int> casts,
    SignEffects signs,
    PerkEffects perks,
    int stolen,
  }) fightEnemies(List<String> enemyIds, int chapter,
      {bool once = false,
      bool host = false,
      Map<String, Map<String, dynamic>> records = const {}}) {
    const none = (
      won: null,
      attempts: 0,
      casts: <String, int>{},
      signs: SignEffects.none,
      perks: PerkEffects.none,
      stolen: 0,
    );
    final c = character;
    if (c == null || sim == null) return none;
    final entries = <MapEntry<String, Map<String, dynamic>>>[
      for (final id in enemyIds)
        if (records[id] != null)
          MapEntry(id, records[id]!)
        else if (enemies[id] is Map<String, dynamic>)
          MapEntry(id, enemies[id] as Map<String, dynamic>),
    ];
    // An enemy the data doesn't hold is a lost fight, never a free win (a
    // story naming one before it exists once made whole runs stronger).
    // `@first_ally`, the pact's turned companion, resolves only in play.
    if (entries.length < enemyIds.where((id) => !id.startsWith('@')).length) {
      return (
        won: false,
        attempts: 1,
        casts: const <String, int>{},
        signs: SignEffects.none,
        perks: PerkEffects.none,
        stolen: 0,
      );
    }
    if (entries.isEmpty) return none;
    // The competent player readies itself: its best gear (the pack's
    // loot and rewards counted), the merges worth crafting, its best die.
    growth?.prepareForFight(
        inventory: questLog?.inventory ?? const <String>{},
        skillwright: skillCraftOpen(housesBuilt.keys));
    final casts = <String, int>{};
    final maxAttempts = once ? 1 : _maxFightAttempts;
    // Vica joins at her scene (story_companions.dart), whatever the policy.
    party?.joinFromStory(visited, chapter: chapter, alignment: alignment);
    party?.levelIs(c.level);
    // Aligned gear answers to the walk's alignment, as in the game.
    c.alignmentLabel = _alignmentLabelOf(alignment);
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final signs = signsNow(host: host);
      final perks = growth?.perks ?? PerkEffects.none;
      final allies =
          party?.fightAllies(signs: signs, perks: perks) ?? const <SimAlly>[];
      // The reserve steps into [allies] itself; who fought goes home.
      final fielded = [...allies];
      final reserve = party?.fightReserve(signs: signs, perks: perks);
      final outcome = simulateSimFight(
        character: c,
        enemies: entries,
        chapter: chapter,
        skills: sim.skills,
        items: sim.items,
        itemSets: sim.itemSets,
        random: random,
        signs: signs,
        perks: perks,
        clash: sim.clash,
        clashOff: sim.clashOff,
        context: sim.context,
        reinforcement: sim.reinforcement,
        clanStanding: growth == null
            ? null
            : (id) => growth.politics.standingOf(id, growth.tables.clans),
        allies: allies,
        reserve: reserve,
      );
      party?.afterFight({...fielded, ...allies}.toList(),
          won: outcome.won, signs: signs);
      // Every pact runs one fight on, won or lost; so does a blessing.
      c.heldSigns = countDownPacts(c.heldSigns);
      if (blessingFights > 0 && --blessingFights == 0) blessingClan = '';
      for (final entry in outcome.spellsCast.entries) {
        casts[entry.key] = (casts[entry.key] ?? 0) + entry.value;
      }
      if (!outcome.won) {
        // A lost try still teaches something ([lostFightXpShare]).
        var xp = 0;
        for (final entry in entries) {
          xp += scaledReward(
              (entry.value['xpReward'] as num?)?.toInt() ?? 0, c.level);
        }
        final levelBefore = c.level;
        c.gainXp(
            (xp * chapterRewardMultiplier(chapter) * lostFightXpShare).round());
        growth?.levelsReached(levelBefore, c.level);
        party?.levelIs(c.level);
      }
      if (outcome.won) {
        questLog?.recordKills(entries.map((e) => e.key));
        // What the foes drop, by their loot tables' own odds: a quest's
        // item (the sealed letter) or a material is picked up.
        if (questLog != null) {
          for (final entry in entries) {
            for (final drop
                in (entry.value['lootTable'] as List?) ?? const []) {
              if (drop is! Map) continue;
              final rate = (drop['dropRate'] as num?)?.toInt() ?? 0;
              if (random.nextInt(100) < rate) {
                final itemId = drop['itemID'].toString();
                questLog.inventory.add(itemId);
                if (materialTierOf(itemId) != null) materials.add(itemId);
              }
            }
          }
        }
        var xp = 0;
        for (final entry in entries) {
          xp += scaledReward(
              (entry.value['xpReward'] as num?)?.toInt() ?? 0, c.level);
        }
        final levelBefore = c.level;
        c.gainXp(perks.scaleXp(
            signs.scaleXp((xp * chapterRewardMultiplier(chapter)).round())));
        growth?.levelsReached(levelBefore, c.level);
        party?.levelIs(c.level);
        if (entries.any((e) =>
            isBossEnemy(e.key, e.value) || zoneBossEnemyIds.contains(e.key))) {
          growth?.bossBeaten();
        }
        settle();
        return (
          won: true,
          attempts: attempt,
          casts: casts,
          signs: signs,
          perks: perks,
          stolen: outcome.goldStolen,
        );
      }
    }
    return (
      won: false,
      attempts: maxAttempts,
      casts: casts,
      signs: SignEffects.none,
      perks: PerkEffects.none,
      stolen: 0,
    );
  }

  fightOnRoad = (ids, chapter, {records = const {}}) {
    final r = fightEnemies(ids, chapter, records: records);
    return (won: r.won, attempts: r.attempts, casts: r.casts);
  };

  /// Your main clan's seat crisis, when the chapter's turn left one
  /// (clan_crisis.dart): played at once, the simulated player's way
  /// (SimGrowth.playCrisis), the defence fought once as the app's scene
  /// does. Its scene draws on its own dice; the fight is not counted among
  /// the encounters (the roads' hunters are not either).
  void playCrisis(int chapter) {
    final g = growth;
    final geography = sim?.geography;
    if (g == null || geography == null || g.politics.crisis.isEmpty) return;
    final crisis = g.politics.crisis;
    final r = g.playCrisis(
      geography: geography,
      enemies: enemies,
      chapter: chapter,
      gold: gold,
      flags: flags,
      random: Random(detourSalt * 31 + chapter * 7919 + steps.length),
      defend: (id) => fightEnemies([id], chapter, once: true).won == true,
    );
    if (r.how.isEmpty) return;
    gold = r.gold;
    flags
      ..clear()
      ..addAll(r.flags);
    steps.add(_SimStep(
      nodeId: 'road:clan_crisis',
      chapter: chapter,
      mood: null,
      uiTheme: null,
      description: 'Seat crisis: ${crisis['attacker']} at '
          '${crisis['place']} (${crisis['clan']}), ${r.how}',
    ));
  }

  /// The chapter's attacks on districts (district_attacks.dart), rolled
  /// and played at once the simulated player's way (SimGrowth.playSieges):
  /// the defence fought once as the app's scene does, its dice its own.
  void playSieges(int chapter) {
    final g = growth;
    final geography = sim?.geography;
    if (g == null || geography == null) return;
    final before = g.siegeOutcomes.values.fold<int>(0, (a, b) => a + b);
    final after = g.playSieges(
      geography: geography,
      enemies: enemies,
      chapter: chapter,
      flags: flags,
      random: Random(detourSalt * 37 + chapter * 104729 + steps.length),
      defend: (id) => fightEnemies([id], chapter, once: true).won == true,
    );
    flags
      ..clear()
      ..addAll(after);
    final played = g.siegeOutcomes.values.fold<int>(0, (a, b) => a + b);
    if (played == before) return;
    steps.add(_SimStep(
      nodeId: 'road:district_siege',
      chapter: chapter,
      mood: null,
      uiTheme: null,
      description: 'District sieges: ${played - before} '
          '(${g.siegeOutcomes})',
    ));
  }

  /// [choice]'s own fight (see [fightEnemies]); one of the last battles
  /// when it is marked so (v1.196).
  ({
    bool? won,
    int attempts,
    Map<String, int> casts,
    SignEffects signs,
    PerkEffects perks,
    int stolen,
  }) fight(StoryChoice choice, int chapter) => choice.triggersCombat
      ? fightEnemies(choice.allTriggerEnemyIds, chapter,
          once: choice.hasLossBranch, host: choice.hostFight)
      : fightEnemies(const [], chapter);

  /// The land route [routeId] crossed from [fromNodeId] (v1.285.0, see
  /// land_crossing.dart), played as "Play to chapter" plays it: each day's
  /// event by pickLandChoice, a lost crossing carrying the party back to
  /// set out again, up to three times, then through. Its rolls come from a
  /// stream of their own, seeded by where and when it is crossed, so the
  /// walk's own stream is left as it was.
  void crossLand(String routeId, String fromNodeId, int at) {
    final route = landRouteFor(sim?.landRoutes ?? const {}, routeId);
    final events = sim?.landEvents ?? const {};
    final c = character;
    if (route == null || events.isEmpty || c == null) return;
    var seed = at;
    for (final unit in '$routeId/$fromNodeId'.codeUnits) {
      seed = (seed * 31 + unit) & 0x3fffffff;
    }
    final crossingRandom = Random(seed);
    // Who holds the road, and how they take the party (wave 16).
    final g = growth;
    final geography = sim?.geography;
    // A clan's own road meets it more often (wave 18 step 2).
    final road = g == null || geography == null
        ? null
        : crossingRuler(route, geography, g.politics, g.tables.clans);
    final rulers = road == null
        ? const <String>[]
        : rulerPool(events, road.clanId, road.band);
    for (var i = 0; i < 3; i++) {
      final result = resolveCrossing(road?.route ?? route, events,
          health: c.currentHealth,
          maxHealth: c.maxHealth,
          gold: gold,
          modifierFor: c.abilityBonus,
          random: crossingRandom,
          chapter: lastKnownChapter,
          rulers: rulers);
      c.currentHealth = result.health;
      gold = (gold + result.gold).clamp(0, 1 << 30).toInt();
      steps.add(_SimStep(
        nodeId: 'crossing:${route.id}',
        chapter: lastKnownChapter,
        mood: null,
        uiTheme: null,
        description: route.nameFor(french),
        choiceText: result.arrived
            ? (french ? 'Traversée' : 'Crossed')
            : (french ? 'Ramené en arrière' : 'Carried back'),
        goldMod: result.gold,
      ));
      if (result.arrived) return;
    }
  }

  /// The hazard on the road from [fromNodeId] to [toNodeId] (v1.197),
  /// [at] steps into the walk, met where the game would meet it (see
  /// roadEventFor): pushed through above half health (the character
  /// wounded, never to death), waited out below. The road's other events
  /// the walk passes by (true: the road holds one, and no detour).
  bool roadHazard(String fromNodeId, String toNodeId, int at) {
    final geography = sim?.geography;
    final chapter = lastKnownChapter;
    if (geography == null || chapter == null) return false;
    final biome = geography.roadBiome(story, fromNodeId, toNodeId);
    final share = hazardShareFor(biome);
    final kind = roadEventFor(
      story: story,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      historyLength: at,
      chapter: chapter,
      hazardShare: share,
      world: geography,
    );
    if (kind != RoadEventKind.hazard) return kind != null;
    final hazard = roadHazardFor(biome,
        fromNodeId: fromNodeId, toNodeId: toNodeId, historyLength: at)!;
    final c = character;
    final pushOn = c == null ||
        hazardPushesOn(health: c.currentHealth, maxHealth: c.maxHealth);
    if (pushOn && c != null) {
      c.currentHealth =
          healthAfterHazard(c.currentHealth, hazardWoundFor(chapter));
    }
    steps.add(_SimStep(
      nodeId: 'road:${hazard.id}',
      chapter: lastKnownChapter,
      mood: null,
      uiTheme: null,
      description: french
          ? 'Danger\u00a0: ${hazard.nameFor(true)}'
          : 'Hazard: ${hazard.name}',
      choiceText: pushOn
          ? (french ? 'Forcer le passage' : 'Push on')
          : (french ? 'Attendre' : 'Wait it out'),
    ));
    return true;
  }

  /// The camp's works, built as a player keen on them would: once the camp
  /// stands, every house the building screen calls buildable (camp_works.
  /// dart: its chapter come, its flags held, the gold and materials there),
  /// cheapest first, as soon as it is; a house short only of commons a
  /// shop of the chapters reached sells (by sea once the harbour stands,
  /// which the walk builds first) has them bought first. Measured, not felt: the gold it
  /// costs comes out of a purse of its own (what the walk has, less what
  /// the works took), so the walk shops as it did, and the houses' bonuses
  /// are not played, but for the companions' seats and Kelda's Hall (built
  /// once she is recruited) when the competent player keeps companions.
  void buildHouses() {
    final houses = sim?.houses ?? const <String, dynamic>{};
    final chapter = lastKnownChapter;
    if (houses.isEmpty || chapter == null || !flags.contains(campFoundedFlag)) {
      return;
    }
    while (true) {
      final works = campWorksOf(
        houses: houses,
        zones: sim?.zones ?? const {},
        shops: sim?.shops ?? const {},
        chapter: chapter,
        flags: flags,
        gold: gold - houseGoldSpent,
        inventory: materials,
        builtHouseIds: housesBuilt.keys,
        recruitedAllyIds: party?.roster.keys.toList() ?? const <String>[],
      );
      int costOf(String id) =>
          ((houses[id] as Map?)?['buildCost'] as num?)?.toInt() ?? 0;
      final ready = [
        for (final w in works.values.expand((w) => w))
          if (w.state == WorkState.buildable) w.houseId,
      ]..sort((a, b) {
          final byCost = costOf(a).compareTo(costOf(b));
          return byCost != 0 ? byCost : a.compareTo(b);
        });
      if (ready.isEmpty) {
        // Short only of commons a shop the walk knows sells: bought, when
        // the works' purse covers them and the house.
        final items = sim?.items ?? const <String, dynamic>{};
        String? bought;
        final waiting = [
          for (final w in works.values.expand((w) => w))
            if (w.state == WorkState.shown) w,
        ]..sort((a, b) => costOf(a.houseId).compareTo(costOf(b.houseId)));
        for (final w in waiting) {
          bool open(String shopId) =>
              (((sim?.shops[shopId] as Map?)?['minChapter'] as num?)?.toInt() ??
                  1) <=
              chapter;
          if (w.needs.any(
              (n) => n.kind != WorkNeedKind.material || !n.shopIds.any(open))) {
            continue;
          }
          final price = w.needs.fold<int>(
              0,
              (sum, n) =>
                  sum +
                  (n.need - n.have) *
                      (((items[n.id] as Map?)?['cost'] as num?)?.toInt() ?? 0));
          if (gold - houseGoldSpent < costOf(w.houseId) + price) continue;
          houseGoldSpent += price;
          for (final n in w.needs) {
            for (var i = n.have; i < n.need; i++) {
              materials.add(n.id);
            }
          }
          bought = w.houseId;
          break;
        }
        if (bought == null) return;
        continue;
      }
      final id = ready.first;
      housesBuilt[id] = chapter;
      party?.housesBuilt(housesBuilt.keys,
          chapter: chapter, alignment: alignment);
      character?.rolls?.build(rollPowerOf(houses[id] as Map<String, dynamic>));
      houseGoldSpent += costOf(id);
      materials = withoutMaterials(materials,
          materialCountsOf(houses[id] as Map<String, dynamic>, 'materialCost'));
    }
  }

  buildHousesNow = buildHouses;

  /// The expedition [zoneId] launches, played out: each of its events a
  /// fight at [_expeditionFightShare] odds (a pair from the pack pool some
  /// of the time, as SubNodeEngine draws them), then the zone's boss. A
  /// fight lost every attempt ends it there; cleared, it pays its reward
  /// and sets its flag. Returns the steps it took. Launched by a
  /// `hostFight` choice ([host], v1.196), every fight of it has the Host.
  void expedition(String zoneId, StoryNode node, {bool host = false}) {
    final zone = sim?.zones[zoneId];
    final c = character;
    if (zone is! Map<String, dynamic>) return;
    final zoneChapter =
        (zone['chapter'] as num?)?.toInt() ?? lastKnownChapter ?? 1;
    final chapter = lastKnownChapter ?? zoneChapter;
    final name = french
        ? (zone['zoneName_fr'] ?? zone['zoneName'] ?? zoneId).toString()
        : (zone['zoneName'] ?? zoneId).toString();
    bool fightAt(List<String> ids) {
      final result = fightEnemies(ids, chapter, host: host);
      var reward = 0;
      for (final id in ids) {
        reward += ((enemies[id] as Map?)?['goldReward'] as num?)?.toInt() ?? 0;
      }
      final won = result.won ?? true;
      final goldMod = won
          ? result.signs.scaleGold(result.perks.scaleGold(reward)) +
              result.stolen
          : 0;
      steps.add(_SimStep(
        nodeId: 'zone:$zoneId',
        chapter: lastKnownChapter,
        mood: node.mood,
        uiTheme: node.uiTheme,
        description: french ? 'Expédition : $name' : 'Expedition: $name',
        choiceText: french ? 'Combattre' : 'Fight',
        enemyId: ids.first,
        goldMod: goldMod,
        fightWon: result.won,
        fightAttempts: result.attempts,
        spellsCast: result.casts,
      ));
      combatCount++;
      gold += goldMod;
      return won;
    }

    final written = sim?.writtenSteps[zoneId] ?? const <WrittenStep>[];
    if (c != null && written.isNotEmpty) {
      // A written road, step by step, its first way through each (as the
      // screen plays it): a roll that passes gets past the step's foes;
      // a fight gives nothing else; otherwise the choice's gold, healing
      // and materials, and a failed roll's hurt.
      final found = materialCountsOf(zone, 'rewardMaterials');
      for (final w in written) {
        final built = buildWrittenStep(w,
            zoneId: zoneId,
            chapter: zoneChapter,
            random: random,
            enemies: enemies,
            rewardMaterials: found);
        if (built.node.choices.isEmpty) continue;
        // Before a fight, a careful party (one led by its story: good or
        // evil) takes the way round it, when there is no roll or the roll
        // is an even chance or better; a party out for gold, or at random,
        // fights for the spoils.
        var pick = 0;
        final careful = strategy == SimStrategy.favorGood ||
            strategy == SimStrategy.favorEvil;
        if (careful && built.node.choices.first.triggerEnemyIds.isNotEmpty) {
          for (final (i, other) in built.node.choices.indexed) {
            final ab = other.checkAbility;
            if (i == 0 || other.triggerEnemyIds.isNotEmpty) continue;
            if (ab == null ||
                21 + c.abilityBonus(ab) - (other.checkDC ?? 10) >= 10) {
              pick = i;
              break;
            }
          }
        }
        final choice = built.node.choices[pick];
        var failed = false;
        final ability = choice.checkAbility;
        if (ability != null) {
          failed = !checkPasses(1 + random.nextInt(20), c.abilityBonus(ability),
              choice.checkDC ?? 10);
        }
        final foes = choice.avoidFightOnSuccess && !failed
            ? const <String>[]
            : choice.triggerEnemyIds;
        if (foes.isNotEmpty) {
          if (!fightAt(foes)) return;
          continue;
        }
        final hurt = built.outcomeFor(pick).hurtOnFail;
        if (failed) {
          if (hurt > 0) {
            c.currentHealth =
                max(1, c.currentHealth - (c.maxHealth * hurt / 100).round());
          }
          continue;
        }
        gold += choice.goldMod;
        if (choice.healAmount > 0) {
          c.currentHealth =
              min(c.maxHealth, c.currentHealth + choice.healAmount);
        }
        for (final MapEntry(key: id, value: n)
            in choice.grantMaterials.entries) {
          for (var i = 0; i < n; i++) {
            materials.add(id);
          }
        }
      }
      final bossId = zone['bossEnemyId']?.toString() ?? '';
      if (enemies[bossId] is Map && !fightAt([bossId])) return;
    } else if (c != null) {
      final pool = SubNodeEngine.filterEnemyPool(
          enemies: enemies, unlockedEnemyIds: const [], chapter: zoneChapter);
      final packPool =
          SubNodeEngine.filterPackPool(enemies: enemies, enemyPool: pool);
      final events = (zone['expeditionCount'] as num?)?.toInt() ?? 3;
      for (var i = 0; i < events; i++) {
        if (pool.isEmpty || random.nextDouble() >= _expeditionFightShare) {
          continue;
        }
        final pack = packPool.isNotEmpty && random.nextDouble() < 0.3;
        final size = pack
            ? SubNodeEngine.maxPackSizeFor(zoneChapter,
                partySize: 1 + (party?.active.length ?? 0))
            : 1;
        final from = pack ? packPool : pool;
        if (!fightAt([
          for (var n = 0; n < size; n++) from[random.nextInt(from.length)],
        ])) {
          return;
        }
      }
      final bossId = zone['bossEnemyId']?.toString() ?? '';
      if (enemies[bossId] is Map && !fightAt([bossId])) return;
    }
    final rewardFlag = zone['rewardFlag']?.toString() ?? '';
    if (rewardFlag.isNotEmpty) flags.add(rewardFlag);
    gold += (zone['rewardGold'] as num?)?.toInt() ?? 0;
    for (final MapEntry(key: id, value: count)
        in materialCountsOf(zone, 'rewardMaterials').entries) {
      for (var i = 0; i < count; i++) {
        materials.add(id);
      }
    }
    buildHouses();
  }

  // A new character's starting points (offers, or skill points).
  settle();
  var flagsSeen = <String>{};
  for (var step = 0; step < maxSteps; step++) {
    if (transcribe) {
      final gained = flags.difference(flagsSeen);
      if (gained.isNotEmpty) {
        note('   flags +${(gained.toList()..sort()).join(', +')}');
      }
      flagsSeen = {...flags};
    }
    final node = story.nodeFor(currentId);
    if (node == null) {
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: null,
        uiTheme: null,
        description: 'Broken link: node $currentId does not exist.',
      ));
      return finish(
        endingText: 'Broken link: node $currentId does not exist.',
        reachedStepCap: false,
      );
    }

    final mainChapter = chapterForNode(currentId);
    if (mainChapter != null) lastKnownChapter = mainChapter;
    furthestChapter = max(furthestChapter ?? 0, mainChapter ?? 0);
    if (furthestChapter == 0) furthestChapter = null;
    // The scene moves the coast as it is entered, once (v1.196: the
    // muster among it).
    applyPolitics(node.politicsOnEnter, enterPoliticsKey(currentId));
    // A new chapter's hub is where a player rests: full health and mana;
    // reaching it brings the clans' offer (see SimGrowth.chapterReached).
    if (character != null && lastKnownChapter != restedChapter) {
      character.rest();
      party
        ?..rest()
        ..arrange(chapter: lastKnownChapter ?? 1, alignment: alignment);
      restedChapter = lastKnownChapter;
      final reached = lastKnownChapter;
      if (reached != null) {
        arrivals.putIfAbsent(
            reached, () => (level: character!.level, gold: gold));
        growth?.chapterReached(reached, geography: sim?.geography);
        settle();
        buildHouses();
        playCrisis(reached);
        playSieges(reached);
        blessAtHub(node, reached);
        if (transcribe) {
          final standings = growth?.politics.standings ?? const {};
          note('== Chapter $reached: level ${character.level}, '
              '${character.currentHealth}/${character.maxHealth} HP, '
              '$gold gold, alone (the walk keeps no companions)');
          if (standings.isNotEmpty) {
            note('   standing: ${[
              for (final e
                  in standings.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                '${e.key} ${e.value.toStringAsFixed(0)}',
            ].join(', ')}');
          }
        }
      }
    }
    // The coast moves: the events a new chapter brings, and those the
    // flags set on the way call for (the app's chapter change and day's
    // tick).
    runEvents();

    if (node.choices.isEmpty) {
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: node.mood,
        uiTheme: node.uiTheme,
        description: node.descriptionFor(french),
      ));
      return finish(endingText: node.description, reachedStepCap: false);
    }

    bool meetsTarget(StoryChoice c) {
      if (c.isEnding) return true;
      final target = story.nodeFor(c.nextId);
      if (target == null || !target.hasRequirements) return true;
      if (gold < target.reqGold) return false;
      if (target.reqAlignmentScore != null &&
          alignment < target.reqAlignmentScore!) {
        return false;
      }
      if (target.reqAlignmentMax != null &&
          alignment > target.reqAlignmentMax!) {
        return false;
      }
      return target.reqFlags.every(flags.contains);
    }

    // From chapter 3 the camp is the base. Before its main quest the party
    // tours each of the chapter's places once -- a few things done in
    // each, then back to the camp -- as a player opening the chapter
    // would; with every place toured, the camp's main quest goes on.
    final here = node.settlement;
    if (here != null &&
        here.isCamp &&
        here.chapter != null &&
        tourPlaceId == null) {
      campId = currentId;
      StoryNode? next;
      for (final place in loopPlaces(story)) {
        if (place.settlement!.chapter == here.chapter &&
            !toured.contains(place.id)) {
          next = place;
          break;
        }
      }
      if (next != null) {
        final name = next.settlement!.nameFor(french);
        toured.add(next.id);
        tourPlaceId = next.id;
        tourBudget = _placeActivitiesPerVisit;
        steps.add(_SimStep(
          nodeId: currentId,
          chapter: lastKnownChapter,
          mood: node.mood,
          uiTheme: node.uiTheme,
          description: node.descriptionFor(french),
          choiceText: french ? 'Aller à : $name' : 'Go to $name',
        ));
        final arrival = arrivalNodeFor(next, visited);
        // A road (D2: the camp's trips roll as the story's do); by sea, its
        // landing does (v1.361).
        roadTurn(currentId, arrival, travels: true);
        currentId = arrival;
        visited.add(currentId);
        continue;
      }
      // Every place toured: the camp's expeditions of the chapters reached
      // (v1.291), each played once, as "Play to chapter" plays them before
      // the main quest -- one cleared may open the next (a zone's
      // requiredFlags), so the list is read again until none is left. The
      // chapter's main zone stays its main quest's.
      while (true) {
        String? zoneId;
        for (final MapEntry(:key, :value)
            in (sim?.zones ?? const <String, dynamic>{}).entries) {
          if (value is! Map<String, dynamic> ||
              zoneIsMain(value) ||
              campExpeditionsPlayed.contains(key) ||
              ((value['chapter'] as num?)?.toInt() ?? 1) > here.chapter! ||
              !meetsRequiredFlags(value, flags)) {
            continue;
          }
          zoneId = key;
          break;
        }
        if (zoneId == null) break;
        campExpeditionsPlayed.add(zoneId);
        expedition(zoneId, node);
      }
    }
    if (tourPlaceId != null && currentId == tourPlaceId) {
      final open =
          node.choices.where((c) => !c.isHiddenFor(flags) && gateOpen(c));
      if (tourBudget <= 0 || open.isEmpty) {
        steps.add(_SimStep(
          nodeId: currentId,
          chapter: lastKnownChapter,
          mood: node.mood,
          uiTheme: node.uiTheme,
          description: node.descriptionFor(french),
          choiceText: french ? 'Retour au camp' : 'Back to the camp',
        ));
        tourPlaceId = null;
        // A tour only ever starts from a camp.
        final camp = campId!;
        roadTurn(currentId, camp, travels: true);
        currentId = camp;
        visited.add(currentId);
        continue;
      }
      tourBudget--;
    }

    // A place's activity done once leaves its list (hideIfFlags), and a
    // second beat waits for the first (showIfFlags); a choice behind a
    // politics gate that fails (v1.196) is hidden, or shut with its text.
    final shown = node.choices
        .where((c) =>
            !c.isHiddenFor(flags) &&
            (gateOpen(c) || (c.lockedText ?? '').isNotEmpty))
        .toList();
    final visible = shown.isNotEmpty ? shown : node.choices;
    final available =
        visible.where((c) => meetsTarget(c) && gateOpen(c)).toList();
    final pool = available.isNotEmpty ? available : visible;
    final choice = pickChoice(pool);

    // An ability check (v1.229) is rolled as the game rolls it: a d20 plus
    // the character's score against the DC, a natural 20 passing and a
    // natural 1 failing; a skill challenge takes rounds until enough pass or
    // too many fail. A failed check with a scene of its own goes there,
    // none of the choice's effects done.
    var checkPassed = true;
    if (character != null && choice.hasAbilityCheck) {
      final bonus = character.abilityBonus(choice.checkAbility!);
      final dc = choice.checkDC ?? 10;
      bool roll() {
        final d = random.nextInt(20) + 1;
        return d == 20 || (d != 1 && d + bonus >= dc);
      }

      if (choice.hasSkillChallenge) {
        var passes = 0, fails = 0;
        while (passes < choice.challengeSuccessesNeeded! &&
            fails < choice.challengeMaxFailures!) {
          roll() ? passes++ : fails++;
        }
        checkPassed = passes >= choice.challengeSuccessesNeeded!;
      } else {
        checkPassed = roll();
      }
      // Exploring with alternating checks takes the side seen less often.
      if (strategy == SimStrategy.explore &&
          coverage != null &&
          coverage.alternateChecks) {
        final key = simChoiceKey(currentId, choice);
        checkPassed = (coverage.taken['$key#pass'] ?? 0) <=
            (coverage.taken['$key#fail'] ?? 0);
        coverage.taken['$key#${checkPassed ? 'pass' : 'fail'}'] =
            (coverage.taken['$key#${checkPassed ? 'pass' : 'fail'}'] ?? 0) + 1;
      }
      checksRolled++;
      if (!checkPassed) checksFailed++;
    }
    final failTarget = choice.failNextId ?? '';
    if (!checkPassed && failTarget.isNotEmpty) {
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: node.mood,
        uiTheme: node.uiTheme,
        description: node.descriptionFor(french),
        choiceText: choice.textFor(french),
      ));
      if (failTarget == 'EXIT' || failTarget == 'END') {
        return finish(
            endingText: choice.textFor(french), reachedStepCap: false);
      }
      currentId = failTarget;
      visited.add(currentId);
      continue;
    }

    // A won fight pays out the enemy's goldReward just like a real playthrough
    // (see FightScreen._finishFight) — folded into this step's goldMod so the
    // chapter breakdown and CSV/JSON exports stay consistent with finalGold.
    // The signs take their share of it (a pact's curse some back).
    // A sneak that works leaves the fight behind.
    final sneaked =
        choice.hasAbilityCheck && checkPassed && choice.avoidFightOnSuccess;
    final killsBefore =
        questLog == null ? null : Map<String, int>.of(questLog.kills);
    final fightResult = sneaked
        ? fightEnemies(const [], lastKnownChapter ?? 1)
        : fight(choice, lastKnownChapter ?? 1);
    final effectiveGoldMod = choice.goldMod +
        fightResult.signs.scaleGold(fightResult.perks
            .scaleGold(sneaked ? 0 : combatGoldReward(choice))) +
        fightResult.stolen;
    if (fightResult.won == false && choice.hasLossBranch) {
      // Lost, and the story goes on: the defeat branch, with none of the
      // choice's own effects (they are the winner's).
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: node.mood,
        uiTheme: node.uiTheme,
        description: node.descriptionFor(french),
        choiceText: choice.textFor(french),
        enemyId: choice.allTriggerEnemyIds.first,
        fightWon: false,
        fightAttempts: fightResult.attempts,
        spellsCast: fightResult.casts,
      ));
      combatCount++;
      currentId = choice.loseNextId!;
      visited.add(currentId);
      continue;
    }

    // A land route the choice crosses (v1.285.0), before it takes the
    // story on: lost, the party is carried back to set out again (see
    // crossLand).
    if (choice.crossesLand) crossLand(choice.landRouteId!, currentId, step);

    steps.add(_SimStep(
      nodeId: currentId,
      chapter: lastKnownChapter,
      mood: node.mood,
      uiTheme: node.uiTheme,
      description: node.descriptionFor(french),
      choiceText: choice.textFor(french),
      enemyId: choice.allTriggerEnemyIds.isEmpty
          ? null
          : choice.allTriggerEnemyIds.first,
      goldMod: effectiveGoldMod,
      alignmentMod: choice.alignmentMod,
      fightWon: fightResult.won,
      fightAttempts: fightResult.attempts,
      spellsCast: fightResult.casts,
    ));

    // A forced price the purse can't make is taken in health (#583).
    final c0 = character;
    if (choice.shortfallWounds && c0 != null) {
      c0.currentHealth = max(
          1,
          c0.currentHealth +
              shortfallWound(gold: gold, goldMod: effectiveGoldMod));
    }
    gold = (gold + effectiveGoldMod).clamp(0, 1 << 30).toInt();
    alignment += choice.alignmentMod;
    flags.addAll(choice.flagsToAdd);
    // The party sees the choice (applyChoiceEffects): who the story takes
    // is settled first, and does not stay to react.
    final p = party;
    if (p != null) {
      final ch = lastKnownChapter ?? 1;
      // Vica joins at her scene, before its choices (story_companions.dart).
      p.joinFromStory(visited, chapter: ch, alignment: alignment);
      // Never a permanent companion (Vica): `*` the first other seated.
      final lostId = storyLossOf(choice.loseAllyId,
          active: p.active, companions: p.companions);
      p.react(
          chapter: ch,
          cause: 'choice at $currentId',
          alignmentMod: choice.alignmentMod,
          goldMod: choice.goldMod,
          approvalMods: choice.approvalMods,
          exclude: lostId,
          alignment: alignment);
      if (lostId != null) {
        p.lose(lostId,
            chapter: ch, cause: 'taken at $currentId', alignment: alignment);
      }
    }
    // The trainer's lesson, on the feature ladder (feature_unlocks.dart).
    if (sim?.featureLadder == true) {
      if (choice.flagsToAdd.contains(trainerStrikeFlag)) {
        growth?.learnTrainerSkill(strike: true);
      } else if (choice.flagsToAdd.contains(trainerGuardFlag)) {
        growth?.learnTrainerSkill(strike: false);
      }
    }
    // What the choice does to the coast, once (v1.196: the claim and the
    // Host among it).
    applyPolitics(choice.politics,
        choicePoliticsKey(currentId, node.choices.indexOf(choice)));
    if ((choice.unlockShopId ?? '').isNotEmpty) {
      final shopId = choice.unlockShopId!;
      final firstVisit = shops.add(shopId);
      final shop = sim?.shops[shopId];
      if (firstVisit && character != null && sim != null && shop is Map) {
        gold = character.visitShop(
          shop.cast<String, dynamic>(),
          sim.items,
          sim.dice,
          sim.spells,
          gold,
          skills: sim.skills,
          itemSets: sim.itemSets,
        );
      }
    }
    if ((choice.unlockQuestId ?? '').isNotEmpty) {
      quests.add(choice.unlockQuestId!);
    }
    // The materials the scene hands over (the harbour's, at the camp's
    // founding) go to the camp's works.
    if (choice.grantsMaterials) {
      for (final MapEntry(key: id, value: count)
          in choice.grantMaterials.entries) {
        for (var i = 0; i < count; i++) {
          materials.add(id);
        }
      }
      buildHouses();
    }
    // The player takes the work on offer if the character qualifies, and an
    // item the scene puts in the pack goes in it.
    if (questLog != null) {
      if (choice.grantsItem) questLog.inventory.add(choice.grantItemId!);
      for (final MapEntry(key: id, value: count)
          in choice.grantMaterials.entries) {
        for (var i = 0; i < count; i++) {
          questLog.inventory.add(id);
        }
      }
      for (final id in [choice.unlockQuestId, choice.questIDToProgress]) {
        if (id != null && id.isNotEmpty) {
          questLog.accept(id,
              step: step,
              flags: flags,
              gold: gold,
              alignmentLabel: _alignmentLabelOf(alignment),
              killsBefore: killsBefore);
        }
      }
    }
    // What waits on the road there (v1.197).
    if (!choice.isEnding) {
      // A choice that sails there (its place has a landing of its own) has
      // no road and no road event, only its landing.
      final sails = choice.travels &&
          landingPortIdFor(story.nodeFor(choice.travelPlaceId!)?.settlement,
                  sim?.ports ?? const {}) !=
              null;
      final event = !sails && roadHazard(currentId, choice.nextId, step);
      if (!choice.opensCharacterCreation) {
        roadTurn(currentId, choice.nextId,
            travels: choice.travels, taken: event);
      }
    }
    if (choice.triggersCombat) combatCount++;
    // An expedition the choice launches (a zone to clear before the story
    // goes on) is played out before it does.
    if (choice.launchesZone) {
      expedition(choice.launchZoneId!, node, host: choice.hostFight);
    }

    settleQuests(step);
    if (choice.isEnding) {
      return finish(endingText: choice.text, reachedStepCap: false);
    }
    // A way back to the camp (a camp errand's end) goes to the last camp.
    currentId = storyChoiceTarget(choice, campNodeId: campId);
    visited.add(currentId);
  }

  return finish(endingText: '', reachedStepCap: true);
}

/// The fights of [runs] random walks, chapter by chapter ('Prologue',
/// 'Chapter 1'...): the runs that reached it, the attempts played there
/// and how many were won (the rest are deaths), and the signs, offers and
/// skills the runs took in all. The balance check behind the simulator's
/// numbers, without the screen (the sign values and the offers were tuned
/// with it, see signs.json and offers.dart); [tables] holds the gamedata
/// files by name ('enemies', 'dice'...): without 'signs' the character
/// never takes a sign, without 'factions' no clan comes. [progression]:
/// the clans' offers, or the old skill points, perks and sign picks.
@visibleForTesting
({
  Map<String, ({int runs, int attempts, int won})> chapters,
  int signsTaken,
  int offersTaken,
  int skillsLearned,
}) simulateFightsByChapter(
  StoryData story, {
  required Map<String, Map<String, dynamic>> tables,
  required Map<String, dynamic> gameConfig,
  required int runs,
  required int seed,
  SimProgression progression = SimProgression.offers,
  bool clash = true,
  Set<String> clashOff = const {},
  SimPolicy policy = SimPolicy.naive,
}) {
  Map<String, dynamic> table(String name) => tables[name] ?? const {};
  final sim = _simContextOf(tables, gameConfig,
      progression: progression,
      clash: clash,
      clashOff: clashOff,
      policy: policy);
  final random = Random(seed);
  final tally = <String, ({int runs, int attempts, int won})>{};
  var signsTaken = 0;
  var offersTaken = 0;
  var skillsLearned = 0;
  for (var i = 0; i < runs; i++) {
    final result =
        _simulate(story, random, enemies: table('enemies'), sim: sim);
    signsTaken += result.signsTaken.length;
    offersTaken += result.offersTaken;
    skillsLearned += result.skillsLearned;
    final reached = <String>{};
    for (final step in result.steps) {
      final key = _chapterLabel(step.chapter);
      final before = tally[key] ?? (runs: 0, attempts: 0, won: 0);
      final fought = step.fightWon != null;
      tally[key] = (
        runs: before.runs + (reached.add(key) ? 1 : 0),
        attempts: before.attempts + (fought ? step.fightAttempts : 0),
        won: before.won + (step.fightWon == true ? 1 : 0),
      );
    }
  }
  return (
    chapters: tally,
    signsTaken: signsTaken,
    offersTaken: offersTaken,
    skillsLearned: skillsLearned,
  );
}

_SimContext _simContextOf(
  Map<String, Map<String, dynamic>> tables,
  Map<String, dynamic> gameConfig, {
  SimProgression progression = SimProgression.offers,
  bool clash = true,
  Set<String> clashOff = const {},
  List<String> startSpecs = const [],
  ContextRule? context,
  Reinforcement reinforcement = Reinforcement.none,
  bool championFights = false,
  bool featureLadder = false,
  SimPolicy policy = SimPolicy.naive,
}) {
  Map<String, dynamic> table(String name) => tables[name] ?? const {};
  final written = writtenStepsFrom(table('expedition_steps'));
  return _SimContext(
    dice: table('dice'),
    skills: table('skills'),
    items: table('items'),
    shops: table('shops'),
    races: table('races'),
    professions: table('professions'),
    spells: parseSpells(table('spells')),
    gameConfig: gameConfig,
    itemSets: parseItemSets(table('item_sets')),
    zones: zonesWithWrittenCounts(table('zones'), written),
    writtenSteps: written,
    patrons: parsePatrons(table('factions')),
    signs: parseSigns(table('signs')),
    clans: ClanData.fromTables(
      factions: table('factions'),
      subclans: table('subclans'),
      relations: table('relations'),
      titles: table('titles'),
    ),
    skillTrees: table('skill_trees'),
    progression: progression,
    geography:
        Geography.parse(geography: table('geography'), biomes: table('biomes')),
    clash: clash,
    clashOff: clashOff,
    quests: table('quests'),
    npcs: table('npcs'),
    landRoutes: table('land_routes'),
    landEvents: landEventsFrom(table('land_events')),
    houses: table('houses'),
    detourScenes: detourScenesFrom(table('detour_scenes')),
    ports: table('ports'),
    startSpecs: startSpecs,
    context: context,
    reinforcement: reinforcement,
    championFights: championFights,
    featureLadder: featureLadder,
    specs: specInfosFrom(table('specialisations')),
    specVariants: specVariantsFrom(table('spec_variants')),
    trainingPaths: trainingPathsFrom(table('training_paths')),
    politicsEvents: parsePoliticsEvents(table('politics_events')),
    policy: policy,
    merges: table('skill_merges'),
    companions: table('companions'),
  );
}

/// What one road of a simulated run held (see detour_pacing.dart): its
/// chapter, its ends, whether it ran between a city's districts and was at
/// rest (neither a crisis nor a set piece), and
/// [kind]: 'quiet', 'owed' (a crisis), 'road_event', 'hunter',
/// 'temptation', 'familiar', 'scene' (a written detour, [sceneId]) or
/// 'chain' (today's drawn detour).
typedef SimRoad = ({
  int chapter,
  String from,
  String to,
  bool streets,
  bool atRest,
  String kind,
  String? sceneId,
  bool landmark,
  bool paysOwed,
});

/// What one simulated playthrough came to (see [simulatePlaythroughs]).
/// The walk spares a rival's hunter when its betrayal is under this
/// (hunter_mercy.dart).
const double _simSpareUnder = 0.25;

typedef SimRunSummary = ({
  SimStrategy strategy,
  String raceId,
  String professionId,
  int finalLevel,
  int finalGold,
  int finalAlignment,
  String endedHow,
  String ending,
  int? furthestChapter,
  int steps,
  int uniqueNodes,
  int fightsWon,
  int fightsLost,
  int roundsFought,
  int combatEncounters,
  int totalCasts,
  int potionsUsed,
  int shops,
  int quests,
  int flags,
  int signs,
  int offers,
  int skillsLearned,
  Map<String, ({int attempts, int won, int fights, int firstTry})> byChapter,
  Map<String, int> enemiesFought,
  Map<String, int> enemiesLost,
  Map<String, Map<String, ({int fought, int lost})>> enemiesByChapter,
  Map<int, ({int level, int gold})> arrivals,
  Map<String, int> housesBuilt,
  Map<String, int> riskyOutcomes,
  Map<String, int> crises,
  Map<String, int> campRolls,
  ({int blessings, int gold}) temple,
  Set<String> visitedNodes,
  List<String> choicesTaken,
  Set<String> questIds,
  Set<String> shopIds,
  Set<String> flagIds,
  int checksRolled,
  int checksFailed,
  List<SimQuestRecord> questRecords,
  Map<String, List<String>> questsStuck,
  List<SimRoad> roads,
  List<String> transcript,
  List<String> specs,
  String patron,
  ({int spared, int finished, int betrayed}) mercy,
  List<TerritoryChange> territory,
  PoliticsState politics,
  Set<String> nemeses,
  List<SimOfferPick> offerPicks,
  Map<String, String> gear,
  String die,
  List<String> merged,
  List<SimCompanionEvent> companionLog,
  List<String> companions,
  Map<String, int> companionKnockouts,
});

/// Full playthroughs, one per entry of [plan] (a strategy and, optionally,
/// the race and profession to play), each from the first scene with the
/// real fight model, for the balance and consistency review: how far each
/// run gets, what it earns and where its fights are lost.
@visibleForTesting
List<SimRunSummary> simulatePlaythroughs(
  StoryData story, {
  required Map<String, Map<String, dynamic>> tables,
  required Map<String, dynamic> gameConfig,
  required List<({SimStrategy strategy, String? raceId, String? professionId})>
      plan,
  required int seed,
  int maxSteps = 1500,
  SimCoverage? coverage,
  Set<String> clashOff = const {},
  bool transcripts = false,
  List<String> startSpecs = const [],
  ContextRule? context,
  Reinforcement reinforcement = Reinforcement.none,
  bool championFights = false,
  bool featureLadder = false,
  SimPolicy policy = SimPolicy.naive,
}) {
  final sim = _simContextOf(tables, gameConfig,
      clashOff: clashOff,
      startSpecs: startSpecs,
      context: context,
      reinforcement: reinforcement,
      championFights: championFights,
      featureLadder: featureLadder,
      policy: policy);
  final enemies = tables['enemies'] ?? const {};
  final out = <SimRunSummary>[];
  for (var i = 0; i < plan.length; i++) {
    final random = Random(seed * 100003 + i);
    final result = _simulate(story, random,
        enemies: enemies,
        strategy: plan[i].strategy,
        maxSteps: maxSteps,
        sim: sim,
        forceRaceId: plan[i].raceId,
        forceProfessionId: plan[i].professionId,
        coverage: coverage,
        detourSalt: seed * 100003 + i,
        transcribe: transcripts);
    final byChapter =
        <String, ({int attempts, int won, int fights, int firstTry})>{};
    final fought = <String, int>{};
    final lost = <String, int>{};
    final byChapterEnemy = <String, Map<String, ({int fought, int lost})>>{};
    for (final step in result.steps) {
      if (step.fightWon == null) continue;
      final key = _chapterLabel(step.chapter);
      final before =
          byChapter[key] ?? (attempts: 0, won: 0, fights: 0, firstTry: 0);
      byChapter[key] = (
        attempts: before.attempts + step.fightAttempts,
        won: before.won + (step.fightWon == true ? 1 : 0),
        fights: before.fights + 1,
        firstTry: before.firstTry +
            (step.fightWon == true && step.fightAttempts == 1 ? 1 : 0),
      );
      final enemy = step.enemyId ?? '?';
      fought[enemy] = (fought[enemy] ?? 0) + 1;
      if (step.fightWon == false) lost[enemy] = (lost[enemy] ?? 0) + 1;
      final tally = byChapterEnemy.putIfAbsent(key, () => {});
      final was = tally[enemy] ?? (fought: 0, lost: 0);
      tally[enemy] = (
        fought: was.fought + 1,
        lost: was.lost + (step.fightWon == false ? 1 : 0),
      );
    }
    // A real ending is a choice that ends the story; the walk also stops on
    // a scene with no way on and on a link to a scene that does not exist.
    final last = result.steps.isEmpty ? null : result.steps.last;
    final endedHow = result.reachedStepCap
        ? 'step_cap'
        : last == null
            ? 'none'
            : result.endingText.startsWith('Broken link')
                ? 'broken_link'
                : last.choiceText == null
                    ? 'dead_end'
                    : 'ending';
    out.add((
      strategy: plan[i].strategy,
      raceId: result.raceId,
      professionId: result.professionId,
      finalLevel: result.finalLevel,
      finalGold: result.finalGold,
      finalAlignment: result.finalAlignment,
      endedHow: endedHow,
      ending: result.endingSummary,
      furthestChapter: result.furthestChapter,
      steps: result.steps.length,
      uniqueNodes: result.uniqueNodesVisited,
      fightsWon: result.fightsWon,
      fightsLost: result.fightsLost,
      roundsFought: result.roundsFought,
      combatEncounters: result.combatEncounters,
      totalCasts: result.totalCasts,
      potionsUsed: result.potionsUsed,
      shops: result.shopsDiscovered.length,
      quests: result.questsDiscovered.length,
      flags: result.flags.length,
      signs: result.signsTaken.length,
      offers: result.offersTaken,
      skillsLearned: result.skillsLearned,
      byChapter: byChapter,
      enemiesFought: fought,
      enemiesLost: lost,
      enemiesByChapter: byChapterEnemy,
      arrivals: result.arrivals,
      housesBuilt: result.housesBuilt,
      riskyOutcomes: result.riskyOutcomes,
      crises: result.crises,
      campRolls: result.campRolls,
      temple: result.temple,
      visitedNodes: {
        for (final step in result.steps)
          if (!step.nodeId.contains(':')) step.nodeId,
      },
      choicesTaken: result.choicesTaken,
      questIds: result.questsDiscovered,
      shopIds: result.shopsDiscovered,
      flagIds: result.flags,
      checksRolled: result.checksRolled,
      checksFailed: result.checksFailed,
      questRecords: result.questRecords,
      questsStuck: result.questsStuck,
      roads: result.roads,
      transcript: result.transcript,
      specs: result.specs,
      patron: result.patron,
      mercy: result.mercy,
      territory: result.territory,
      politics: result.politics,
      nemeses: result.nemeses,
      offerPicks: result.offerPicks,
      gear: result.gear,
      die: result.die,
      merged: result.merged,
      companionLog: result.companionLog,
      companions: result.companions,
      companionKnockouts: result.companionKnockouts,
    ));
  }
  return out;
}

/// Total casts per spell id across [results], most cast first.
Map<String, int> _spellCastTotals(List<_SimResult> results) {
  final totals = <String, int>{};
  for (final r in results) {
    for (final entry in r.spellsCast.entries) {
      totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// How many of [results] cast each spell at least once.
Map<String, int> _runsCastingCounts(List<_SimResult> results) {
  final counts = <String, int>{};
  for (final r in results) {
    for (final id in r.spellsCast.keys) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

/// Runs, fights won, fights lost and casts per profession id.
Map<String, ({int runs, int won, int lost, int casts})> _professionTotals(
    List<_SimResult> results) {
  final map = <String, ({int runs, int won, int lost, int casts})>{};
  for (final r in results) {
    if (!r.hasCharacter) continue;
    final current = map[r.professionId] ?? (runs: 0, won: 0, lost: 0, casts: 0);
    map[r.professionId] = (
      runs: current.runs + 1,
      won: current.won + r.fightsWon,
      lost: current.lost + r.fightsLost,
      casts: current.casts + r.totalCasts,
    );
  }
  return map;
}

String _spellDisplayName(
        String id, Map<String, SpellSpec> spells, AppLanguage lang) =>
    spells[id]?.nameFor(lang) ?? id;

String _professionDisplayName(String id, Map<String, dynamic> professions) =>
    (professions[id] as Map<String, dynamic>?)?['professionName']?.toString() ??
    id;

/// "Arcane Bolt ×12, Mana Ward ×3" for one run's casts, or null.
String? _castsSummary(
    Map<String, int> casts, Map<String, SpellSpec> spells, AppLanguage lang) {
  if (casts.isEmpty) return null;
  final entries = casts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => '${_spellDisplayName(e.key, spells, lang)} ×${e.value}')
      .join(', ');
}

double _avg(Iterable<num> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

Map<String, int> _endingCounts(List<_SimResult> results) {
  final counts = <String, int>{};
  for (final r in results) {
    counts[r.endingSummary] = (counts[r.endingSummary] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// How many of [results]' runs discovered each companion's recruit quest —
/// derived purely from [_SimResult.questsDiscovered] (this graph-walk
/// simulator has no quest-completion model, so "discovered the recruit
/// quest" is the closest available proxy for "encountered this companion"),
/// cross-referenced against [quests] for which quest ids actually grant a
/// companion (a non-empty `rewardAllyId`). Most-encountered first.
Map<String, int> _companionEncounterCounts(
    List<_SimResult> results, Map<String, dynamic> quests) {
  final counts = <String, int>{};
  for (final r in results) {
    final companionsThisRun = <String>{};
    for (final questId in r.questsDiscovered) {
      final quest = quests[questId] as Map<String, dynamic>?;
      final allyId = quest?['rewardAllyId']?.toString() ?? '';
      if (allyId.isNotEmpty) companionsThisRun.add(allyId);
    }
    for (final allyId in companionsThisRun) {
      counts[allyId] = (counts[allyId] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// A stable, distinct color per companion id (cycled from a small fixed
/// palette by insertion order) — just enough to tell chips apart at a
/// glance, not meaningful per-companion branding.
const List<Color> _companionColors = [
  Colors.teal,
  Colors.deepPurple,
  Colors.orange,
  Colors.indigo,
  Colors.pink,
];

Color _companionColor(String companionId, Map<String, int> allCounts) {
  final index = allCounts.keys.toList().indexOf(companionId);
  return _companionColors[index % _companionColors.length];
}

/// One colored, icon-led stat row in a batch's recap — a lightweight,
/// scan-friendly alternative to the plain uncolored [Text] lines this
/// section used before.
class _StatLine extends StatelessWidget {
  const _StatLine(
      {required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A grouping bucket (a chapter, a location, or a mood) with the tallies
/// needed to summarize how a batch of runs spent their time in it.
class _GroupStat {
  _GroupStat(this.label);

  final String label;
  int nodeCount = 0;
  int combatCount = 0;
  int goldDelta = 0;
  int alignmentDelta = 0;
  int runsReaching = 0;
  int fightsLost = 0;
  int spellCasts = 0;
}

String _chapterLabel(int? chapter) =>
    chapter == null ? 'Prologue' : 'Chapter $chapter';

/// Buckets every step of every run by the chapter it counts toward,
/// tracking node/combat counts, gold & alignment swing, and how many runs
/// reached that chapter at all — the breakdown this screen's chapter view
/// is built from.
List<_GroupStat> _chapterBreakdown(List<_SimResult> results) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    final seenThisRun = <String>{};
    for (final s in r.steps) {
      final key = _chapterLabel(s.chapter);
      final stat = map.putIfAbsent(key, () => _GroupStat(key));
      stat.nodeCount++;
      if (s.enemyId != null) stat.combatCount++;
      if (s.fightWon == false) stat.fightsLost++;
      stat.spellCasts += s.spellsCast.values.fold(0, (a, b) => a + b);
      stat.goldDelta += s.goldMod;
      stat.alignmentDelta += s.alignmentMod;
      seenThisRun.add(key);
    }
    for (final key in seenThisRun) {
      map[key]!.runsReaching++;
    }
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == 'Prologue') return -1;
      if (b == 'Prologue') return 1;
      final na = int.tryParse(a.replaceFirst('Chapter ', '')) ?? 0;
      final nb = int.tryParse(b.replaceFirst('Chapter ', '')) ?? 0;
      return na.compareTo(nb);
    });
  return [for (final k in keys) map[k]!];
}

/// A simple node-count distribution over some per-step attribute (mood or
/// location), most-visited first — how much of the story, on average,
/// reads as "grim" vs "tense", or plays out on the "docks" vs "cathedral".
List<_GroupStat> _distributionBy(
    List<_SimResult> results, String? Function(_SimStep) keyOf) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    for (final s in r.steps) {
      final key = keyOf(s) ?? '(untagged)';
      map.putIfAbsent(key, () => _GroupStat(key)).nodeCount++;
    }
  }
  final entries = map.values.toList()
    ..sort((a, b) => b.nodeCount.compareTo(a.nodeCount));
  return entries;
}

/// One "Run" button press worth of simulations — 1 to N runs, all using the
/// same [strategy], kept together so different batches can be compared.
class _SimBatch {
  _SimBatch({required this.id, required this.strategy, required this.results});

  /// Stable identity for this batch (a monotonic counter, not a list
  /// index), used as the _BatchCard's key so each card's own analysis
  /// state stays attached to the right batch as new ones are prepended.
  final int id;
  final SimStrategy strategy;
  final List<_SimResult> results;

  int get runCount => results.length;
  int get stepCapCount => results.where((r) => r.reachedStepCap).length;
}

/// Holds every completed simulation batch for the lifetime of the app
/// (i.e. as long as the ProviderScope lives), not just this screen's own
/// widget lifetime. The screen itself is reached via Navigator.push, so
/// without this a State field would reset to empty every time the player
/// backed out and reopened it. Cleared only by the screen's own "clear
/// all" action.
class _SimulatorBatchesNotifier extends StateNotifier<List<_SimBatch>> {
  _SimulatorBatchesNotifier() : super(const []);

  int _nextId = 0;

  void addBatch(SimStrategy strategy, List<_SimResult> results) {
    state = [
      ...state,
      _SimBatch(id: _nextId++, strategy: strategy, results: results)
    ];
  }

  void clear() {
    state = const [];
    _nextId = 0;
  }
}

final _simulatorBatchesProvider =
    StateNotifierProvider<_SimulatorBatchesNotifier, List<_SimBatch>>(
  (ref) => _SimulatorBatchesNotifier(),
);

class PlaythroughSimulatorScreen extends ConsumerStatefulWidget {
  const PlaythroughSimulatorScreen({super.key});

  @override
  ConsumerState<PlaythroughSimulatorScreen> createState() =>
      _PlaythroughSimulatorScreenState();
}

class _PlaythroughSimulatorScreenState
    extends ConsumerState<PlaythroughSimulatorScreen> {
  bool _running = false;
  SimStrategy _strategy = SimStrategy.random;
  int _runCount = 1;

  /// Real-session counterpart to [_run] -- rather than an isolated
  /// statistics-only walk, [_playToChapter] plays [_strategy]-weighted
  /// choices forward against the actual player session and lands them
  /// back in live Story view once [_targetChapter] is reached. `null`
  /// means "not chosen yet" (the button stays disabled).
  int? _targetChapter;
  bool _autoplayRunning = false;

  /// The attempt [_playToChapter] is on: a run that falls short is undone
  /// and played again until it reaches the chapter.
  int _autoplayAttempt = 0;

  /// [_playToChapter]'s options: a fresh game first, with this race and
  /// profession (null: random), and a seed (null: random).
  bool _autoplayNewGame = false;
  String? _autoplayRaceId;
  String? _autoplayProfessionId;
  int? _autoplaySeed;
  Map<String, dynamic> _raceRecords = const {};
  Map<String, dynamic> _professionRecords = const {};

  /// Whether the strategy/runs/simulate controls are shown in full. They
  /// collapse to a compact bar on a tap (or a new result to look at), and
  /// come back on a tap or once the compact view's results are scrolled
  /// back to the top.
  bool _controlsExpanded = true;
  final ScrollController _resultsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
    _loadCharacterRecords();
  }

  /// The races and professions [_playToChapter]'s pickers offer.
  Future<void> _loadCharacterRecords() async {
    final races =
        await ref.read(gameDbRepositoryProvider(racesSchema)).loadRecords();
    final professions = await ref
        .read(gameDbRepositoryProvider(professionsSchema))
        .loadRecords();
    if (!mounted) return;
    setState(() {
      _raceRecords = races;
      _professionRecords = professions;
    });
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _onResultsScroll() {
    // Only the compact view's results use this controller: back at the top,
    // the full controls come back. (The full view scrolls the controls away
    // with the rest, so scrolling down must not collapse it.)
    if (_resultsScrollController.offset <= 4 && !_controlsExpanded) {
      setState(() => _controlsExpanded = true);
    }
  }

  /// Plays [_strategy]-weighted real choices forward against the actual
  /// player session until [_targetChapter] (via [autoplayToChapter]),
  /// applying true effects at every step, then lands the player back in
  /// live Story view to keep going manually -- unlike [_run], which only
  /// ever produces disposable statistics.
  Future<void> _playToChapter() async {
    final target = _targetChapter;
    if (target == null) return;
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);

    setState(() => _autoplayRunning = true);
    final story = await ref.read(storyDataProvider.future);
    final dice =
        await ref.read(gameDbRepositoryProvider(diceSchema)).loadRecords();
    final skills =
        await ref.read(gameDbRepositoryProvider(skillsSchema)).loadRecords();
    final items =
        await ref.read(gameDbRepositoryProvider(itemsSchema)).loadRecords();
    final enemies =
        await ref.read(gameDbRepositoryProvider(enemiesSchema)).loadRecords();
    final races =
        await ref.read(gameDbRepositoryProvider(racesSchema)).loadRecords();
    final professions = await ref
        .read(gameDbRepositoryProvider(professionsSchema))
        .loadRecords();
    final zones = await loadZonesWithWrittenCounts(ref);

    // A fresh game first, when asked: the pickers' race and profession are
    // a new character's.
    if (_autoplayNewGame) {
      await ref.read(playerSessionProvider.notifier).resetSession();
      ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
    }
    final before = ref.read(playerSessionProvider);
    final log = AutoplayLog();
    final result = await autoplayToChapter(
      ref,
      story: story,
      targetChapter: target,
      strategy: _toAutoplayStrategy(_strategy),
      dice: dice,
      skills: skills,
      items: items,
      enemies: enemies,
      races: races,
      professions: professions,
      zones: zones,
      raceId: _autoplayRaceId,
      professionId: _autoplayProfessionId,
      seed: _autoplaySeed,
      log: log,
      onAttempt: (attempt) {
        if (mounted) setState(() => _autoplayAttempt = attempt);
      },
    );

    if (!mounted) return;
    setState(() {
      _autoplayRunning = false;
      _autoplayAttempt = 0;
    });

    final message = switch (result.status) {
      AutoplayStatus.alreadyThere => t('autoplay_already_there'),
      AutoplayStatus.noPathFound => t('autoplay_no_path'),
      AutoplayStatus.stuckInCombat => '${t('autoplay_stuck_prefix')} '
          '${result.stuckEnemyName} (${result.stepsApplied} ${t('autoplay_steps_suffix')})',
      AutoplayStatus.reachedTarget =>
        '${t('autoplay_reached_prefix')} (${result.stepsApplied} ${t('autoplay_steps_suffix')}'
            '${result.attempts > 1 ? ', ${t('autoplay_attempt_label')} ${result.attempts}' : ''}'
            '${result.forcedWins > 0 ? ', ${result.forcedWins} ${t('autoplay_forced_suffix')}' : ''})',
      AutoplayStatus.stepCapReached => t('autoplay_step_cap_reached'),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

    // What the walk did, tab by tab, before the player takes over.
    if (result.stepsApplied > 0) {
      final clans = await loadClanData(ref);
      final companions = await ref
          .read(gameDbRepositoryProvider(companionsSchema))
          .loadRecords();
      if (!mounted) return;
      final after = ref.read(playerSessionProvider);
      final nodeId = ref.read(storyPlayProvider).currentNodeId;
      await showAutoplaySummary(
        context,
        summary: autoplaySummaryOf(
          before: before,
          after: after,
          log: log,
          data: clans,
          chapter: chapterForNode(nodeId) ?? target,
          nodeId: nodeId,
        ),
        clans: clans,
        itemName: (id) => (items[id] as Map?)?['itemName']?.toString() ?? id,
        companionName: (id) =>
            (companions[id] as Map?)?['companionName']?.toString() ?? id,
      );
      if (!mounted) return;
    }

    // Land the player on the Story tab, ready to keep going manually from
    // wherever the walk ended up -- the whole point of this feature. This
    // screen is reached via two pushed routes (Settings, then here), so
    // switching the tab alone leaves it invisible underneath both until
    // they're popped back to the root.
    if (result.stepsApplied > 0) {
      ref.read(homeTabIndexProvider.notifier).state =
          storyTabIndex(ref.read(appModeProvider));
      Navigator.of(context).popUntil(isGameRoute);
    }
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final story = await ref.read(storyDataProvider.future);
    final enemies =
        await ref.read(gameDbRepositoryProvider(enemiesSchema)).loadRecords();
    Future<Map<String, dynamic>> load(DbSchema schema) =>
        ref.read(gameDbRepositoryProvider(schema)).loadRecords();
    final sim = _SimContext(
      dice: await load(diceSchema),
      skills: await load(skillsSchema),
      items: await load(itemsSchema),
      shops: await load(shopsSchema),
      races: await load(racesSchema),
      professions: await load(professionsSchema),
      spells: parseSpells(await load(spellsSchema)),
      gameConfig: await ref.read(gameConfigProvider.future),
      itemSets: parseItemSets(await load(itemSetsSchema)),
      zones: await loadZonesWithWrittenCounts(ref),
      patrons: parsePatrons(await load(factionsSchema)),
      signs: parseSigns(await load(signsSchema)),
      clans: ClanData.fromTables(
        factions: await load(factionsSchema),
        subclans: await load(subclansSchema),
        relations: await load(relationsSchema),
        titles: await load(titlesSchema),
      ),
      skillTrees: await load(skillTreesSchema),
      geography: await loadGeography(ref),
      landRoutes: await load(landRoutesSchema),
      landEvents: landEventsFrom(await load(landEventsSchema)),
      houses: await load(housesSchema),
      writtenSteps: await loadWrittenSteps(ref),
      trainingPaths: await ref.read(trainingPathsProvider.future),
      politicsEvents: parsePoliticsEvents(await load(politicsEventsSchema)),
      // The screen plays as a real player would (sim_policy.dart); the CI
      // bands keep the naive player.
      policy: SimPolicy.competent,
      merges: await load(skillMergesSchema),
      // Its companions come with their quests (sim_companions.dart).
      companions: await load(companionsSchema),
      quests: await load(questsSchema),
      npcs: await load(npcsSchema),
    );
    final french = ref.read(appLanguageProvider) == AppLanguage.fr;
    final random = Random();
    final results = [
      for (var i = 0; i < _runCount; i++)
        _simulate(story, random,
            enemies: enemies, strategy: _strategy, french: french, sim: sim),
    ];
    if (!mounted) return;
    ref.read(_simulatorBatchesProvider.notifier).addBatch(_strategy, results);
    setState(() {
      _running = false;
      _controlsExpanded = false;
    });
  }

  /// Runs the exhaustive, gating-blind graph walk (see
  /// story_graph_integrity.dart) and shows what it finds — the same audit
  /// this project has otherwise relied on someone remembering to run by
  /// hand after a content pass.
  Future<void> _runStructuralAudit() async {
    final story = await ref.read(storyDataProvider.future);
    final report = checkStoryGraphIntegrity(story.nodes,
        startNodeId: StoryRepository.startNodeId);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          report.isClean
              ? tr(ref, 'structural_audit_clean_title')
              : tr(ref, 'structural_audit_issues_title'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '${tr(ref, 'structural_audit_endings_label')}: ${report.reachableEndingCount}'),
              if (report.unreachableNodeIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${tr(ref, 'structural_audit_unreachable_label')}: ${report.unreachableNodeIds.join(', ')}',
                ),
              ],
              if (report.deadEndNodeIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${tr(ref, 'structural_audit_dead_ends_label')}: ${report.deadEndNodeIds.join(', ')}',
                ),
              ],
              if (report.brokenReferences.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${tr(ref, 'structural_audit_broken_links_label')}:'),
                for (final link in report.brokenReferences) Text('• $link'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _fullControls(BuildContext context, List<_SimBatch> batches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr(ref, 'strategy_label'),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SimStrategy.values.map((strategy) {
            return ChoiceChip(
              label: Text(tr(ref, _strategyLabelKey(strategy))),
              selected: _strategy == strategy,
              onSelected: (_) => setState(() => _strategy = strategy),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(tr(ref, 'runs_label'),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [1, 5, 10, 20].map((count) {
            return ChoiceChip(
              label: Text('$count'),
              selected: _runCount == count,
              onSelected: (_) => setState(() => _runCount = count),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _running ? null : _run,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(_running
                    ? tr(ref, 'simulating_label')
                    : tr(ref, 'auto_playthrough_button')),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: tr(ref, 'structural_audit_button'),
              onPressed: _runStructuralAudit,
            ),
            if (batches.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.expand_less),
                tooltip: tr(ref, 'hide_options_tooltip'),
                onPressed: () => setState(() => _controlsExpanded = false),
              ),
            ],
          ],
        ),
        const Divider(height: 32),
        Text(tr(ref, 'play_to_chapter_title'),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          tr(ref, 'play_to_chapter_subtitle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var chapter = 0; chapter <= _maxChapter; chapter++)
              if (firstNodeIdForChapter(chapter,
                      prologueNodeId: StoryRepository.startNodeId) !=
                  null)
                ChoiceChip(
                  label: Text(chapter == 0
                      ? tr(ref, 'chapter_band_prologue')
                      : '$chapter'),
                  selected: _targetChapter == chapter,
                  onSelected: (_) => setState(() => _targetChapter = chapter),
                ),
          ],
        ),
        const SizedBox(height: 12),
        _playToChapterOptions(context),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (_autoplayRunning || _targetChapter == null)
              ? null
              : _playToChapter,
          icon: _autoplayRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fast_forward),
          label: Text(_autoplayRunning
              ? (_autoplayAttempt > 1
                  ? '${tr(ref, 'autoplay_running')} '
                      '${tr(ref, 'autoplay_attempt_label')} $_autoplayAttempt'
                  : tr(ref, 'autoplay_running'))
              : tr(ref, 'play_to_chapter_button')),
        ),
      ],
    );
  }

  /// [_playToChapter]'s pickers: a new game, its race and profession, the
  /// player's style (the strategy chips above) and a seed.
  Widget _playToChapterOptions(BuildContext context) {
    String nameOf(Map<String, dynamic> records, String id, String field) =>
        (records[id] as Map?)?[field]?.toString() ?? id;
    DropdownButton<String?> picker(
      Map<String, dynamic> records,
      String field,
      String? value,
      void Function(String?) onChanged,
    ) =>
        DropdownButton<String?>(
          value: records.containsKey(value) ? value : null,
          hint: Text(tr(ref, 'ptc_random')),
          items: [
            DropdownMenuItem(value: null, child: Text(tr(ref, 'ptc_random'))),
            for (final id in records.keys)
              DropdownMenuItem(
                  value: id, child: Text(nameOf(records, id, field))),
          ],
          onChanged: _autoplayNewGame ? onChanged : null,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(ref, 'ptc_new_game')),
          subtitle: Text(tr(ref, 'ptc_new_game_hint')),
          value: _autoplayNewGame,
          onChanged: (v) => setState(() => _autoplayNewGame = v),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(tr(ref, 'race_label')),
            picker(_raceRecords, 'raceName', _autoplayRaceId,
                (v) => setState(() => _autoplayRaceId = v)),
            Text(tr(ref, 'profession_label')),
            picker(_professionRecords, 'professionName', _autoplayProfessionId,
                (v) => setState(() => _autoplayProfessionId = v)),
          ],
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(ref, 'ptc_seed_label')),
          onChanged: (v) => setState(() => _autoplaySeed = int.tryParse(v)),
        ),
      ],
    );
  }

  int get _maxChapter => chapterSpines.isEmpty
      ? 0
      : chapterSpines.map((s) => s.chapter).reduce((a, b) => a > b ? a : b);

  Widget _compactControlsBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _controlsExpanded = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tr(ref, _strategyLabelKey(_strategy))} × $_runCount',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay, size: 20),
                tooltip: tr(ref, 'auto_playthrough_button'),
                onPressed: _running ? null : _run,
              ),
              Icon(Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(gameDbProvider(shopsSchema)).value ?? const {};
    final quests = ref.watch(gameDbProvider(questsSchema)).value ?? const {};
    final professions =
        ref.watch(gameDbProvider(professionsSchema)).value ?? const {};
    final spells =
        parseSpells(ref.watch(gameDbProvider(spellsSchema)).value ?? const {});
    final companions =
        ref.watch(gameDbProvider(companionsSchema)).value ?? const {};
    final batches = ref.watch(_simulatorBatchesProvider);
    final showFullControls = batches.isEmpty || _controlsExpanded;
    final reversedBatches = batches.reversed.toList();
    List<Widget> resultCards() => [
          for (var i = 0; i < reversedBatches.length; i++)
            _BatchCard(
              key: ValueKey(reversedBatches[i].id),
              batch: reversedBatches[i],
              shops: shops,
              quests: quests,
              companions: companions,
              professions: professions,
              spells: spells,
              initiallyExpanded: i == 0,
            ),
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'auto_playthrough_button')),
        actions: [
          if (batches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: tr(ref, 'clear_all_button'),
              onPressed: () {
                ref.read(_simulatorBatchesProvider.notifier).clear();
                setState(() => _controlsExpanded = true);
              },
            ),
        ],
      ),
      // The full controls are taller than a phone, so they scroll with the
      // results (a plain Column ran the last button off the screen). The app
      // already keeps clear of the system bars in main.dart; the SafeArea
      // here keeps the screen right wherever it is shown without that.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: showFullControls
              ? ListView(
                  key: const Key('sim_scroll_full'),
                  children: [
                    _fullControls(context, batches),
                    const SizedBox(height: 12),
                    if (batches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: Text(tr(ref, 'no_batches_yet_message'))),
                      )
                    else
                      ...resultCards(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _compactControlsBar(context),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        key: const Key('sim_scroll_compact'),
                        controller: _resultsScrollController,
                        children: resultCards(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Writes [content] to a temp .txt file and hands it to the OS (share
/// sheet / a text viewer), for a real "export" rather than just a
/// clipboard copy. Falls back to telling the user what went wrong — some
/// devices have nothing registered to open a bare .txt file.
Future<void> _exportToFile(BuildContext context, WidgetRef ref, String content,
    String filename) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${trFor(ref.read(appLanguageProvider), 'export_failed_prefix')}: $e')),
    );
  }
}

Future<void> _copyToClipboard(
    BuildContext context, WidgetRef ref, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(ref, 'transcript_copied_message'))),
  );
}

/// Renders one run as a plain-text transcript: its summary stats, then
/// every node visited with its narrative text and the choice taken from
/// it — the "node and text" export the QA workflow needs.
String _runTranscript(_SimResult result, String strategyLabel,
    {int? runNumber, Map<String, SpellSpec> spells = const {}}) {
  String spellName(String id) => spells[id]?.name ?? id;
  String casts(Map<String, int> m) => m.isEmpty
      ? 'none'
      : (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => '${spellName(e.key)} x${e.value}')
          .join(', ');
  final b = StringBuffer();
  b.writeln(
      '=== Playthrough Transcript${runNumber != null ? ' — Run #$runNumber' : ''} ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Ending: ${result.endingSummary}');
  b.writeln(
    'Final gold: ${result.finalGold} | Final alignment: ${result.finalAlignment} | '
    'Nodes visited: ${result.steps.length} (unique: ${result.uniqueNodesVisited})',
  );
  b.writeln(
      'Shops discovered: ${result.shopsDiscovered.isEmpty ? 'none' : result.shopsDiscovered.join(', ')}');
  b.writeln(
      'Quests discovered: ${result.questsDiscovered.isEmpty ? 'none' : result.questsDiscovered.join(', ')}');
  b.writeln(
      'Flags collected: ${result.flags.isEmpty ? 'none' : result.flags.join(', ')}');
  if (result.hasCharacter) {
    b.writeln(
        'Character: ${result.raceId} ${result.professionId}, level ${result.finalLevel} | '
        'Fights won/lost: ${result.fightsWon}/${result.fightsLost} | '
        'Potions used: ${result.potionsUsed}');
    b.writeln(
        'Spells cast: ${casts(result.spellsCast)} | Mana from dice: ${result.manaGained}'
        '${result.spellbooksBought.isEmpty ? '' : ' | Spellbooks bought: ${result.spellbooksBought.map(spellName).join(', ')}'}');
    b.writeln(
        'Offers taken: ${result.offersTaken} | Skills learned: ${result.skillsLearned} | '
        'Signs taken: ${result.signsTaken.isEmpty ? 'none' : result.signsTaken.join(', ')}');
    b.writeln(
        'Gear worn: ${result.gear.isEmpty ? 'none' : (result.gear.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key} ${e.value}').join(', ')}'
        '${result.die.isEmpty ? '' : ' | Die: ${result.die}'}'
        '${result.merged.isEmpty ? '' : ' | Crafted: ${result.merged.join(', ')}'}');
    if (result.offerPicks.isNotEmpty) {
      b.writeln();
      b.writeln('--- Clan offers (banners offered -> taken, why) ---');
      for (final pick in result.offerPicks) {
        b.writeln(pick.line);
      }
    }
    if (result.companionLog.isNotEmpty) {
      b.writeln();
      b.writeln('--- Companions (recruits, picks, swaps, losses, why) ---');
      for (final event in result.companionLog) {
        b.writeln(event.line);
      }
      b.writeln('Party at the end: '
          '${result.companions.isEmpty ? 'none' : result.companions.join(', ')}'
          '${result.companionKnockouts.isEmpty ? '' : ' | Knock-outs: ${result.companionKnockouts.entries.map((e) => '${e.key} ${e.value}').join(', ')}'}');
    }
  }
  b.writeln();
  b.writeln('--- Steps ---');
  for (final s in result.steps) {
    final tags = [
      _chapterLabel(s.chapter),
      if (s.uiTheme != null) s.uiTheme,
      if (s.mood != null) s.mood,
    ].join(' / ');
    b.writeln();
    b.writeln('[Node ${s.nodeId}] ($tags)');
    b.writeln(s.description);
    if (s.choiceText != null) {
      final fight = s.fightWon == null
          ? ''
          : ' — ${s.fightWon! ? 'won' : 'lost'}'
              '${s.fightAttempts > 1 ? ' (${s.fightAttempts} attempts)' : ''}';
      b.writeln(
          '→ Chose: "${s.choiceText}"${s.enemyId != null ? ' [combat: ${s.enemyId}$fight]' : ''}');
      if (s.spellsCast.isNotEmpty) {
        b.writeln('  Spells cast: ${casts(s.spellsCast)}');
      }
    }
  }
  return b.toString();
}

String _batchSummaryText(String strategyLabel, List<_SimResult> results,
    {Map<String, SpellSpec> spells = const {}}) {
  final b = StringBuffer();
  b.writeln('=== Batch Summary ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Runs: ${results.length}');
  b.writeln(
      'Average nodes visited: ${_avg(results.map((r) => r.steps.length)).toStringAsFixed(1)}');
  b.writeln(
      'Average final gold: ${_avg(results.map((r) => r.finalGold)).toStringAsFixed(1)}');
  b.writeln(
      'Average final alignment: ${_avg(results.map((r) => r.finalAlignment)).toStringAsFixed(1)}');
  b.writeln(
      'Average combat encounters: ${_avg(results.map((r) => r.combatEncounters)).toStringAsFixed(1)}');
  if (results.any((r) => r.hasCharacter)) {
    b.writeln(
        'Average fights won / lost: ${_avg(results.map((r) => r.fightsWon)).toStringAsFixed(1)} / '
        '${_avg(results.map((r) => r.fightsLost)).toStringAsFixed(1)}');
    b.writeln(
        'Average offers taken: ${_avg(results.map((r) => r.offersTaken)).toStringAsFixed(1)} '
        '(skills ${_avg(results.map((r) => r.skillsLearned)).toStringAsFixed(1)}, '
        'signs ${_avg(results.map((r) => r.signsTaken.length)).toStringAsFixed(1)})');
    b.writeln(
        'Average spells cast: ${_avg(results.map((r) => r.totalCasts)).toStringAsFixed(1)} '
        '(mana from dice ${_avg(results.map((r) => r.manaGained)).toStringAsFixed(1)})');
    final totals = _spellCastTotals(results);
    if (totals.isNotEmpty) {
      b.writeln(
          'Casts by spell: ${totals.entries.map((e) => '${spells[e.key]?.name ?? e.key} x${e.value}').join(', ')}');
    }
    for (final entry in _professionTotals(results).entries) {
      b.writeln(
          '- ${entry.key}: ${entry.value.runs} runs, fights won/lost ${entry.value.won}/${entry.value.lost}, ${entry.value.casts} casts');
    }
  }
  final stepCap = results.where((r) => r.reachedStepCap).length;
  if (stepCap > 0) {
    b.writeln(
        '$stepCap/${results.length} runs never reached an ending (hit the step cap).');
  }
  b.writeln();
  b.writeln('Ending distribution:');
  for (final entry in _endingCounts(results).entries) {
    b.writeln('- ${entry.value}x: ${entry.key}');
  }
  b.writeln();
  b.writeln('By chapter:');
  for (final g in _chapterBreakdown(results)) {
    b.writeln(
      '- ${g.label}: ${g.runsReaching}/${results.length} runs reached it, '
      '${(g.nodeCount / g.runsReaching).toStringAsFixed(1)} nodes avg, '
      '${g.combatCount} combats (${g.fightsLost} lost, ${g.spellCasts} spells), gold Δ${g.goldDelta}, alignment Δ${g.alignmentDelta}',
    );
  }
  b.writeln();
  b.writeln('By location:');
  for (final g in _distributionBy(results, (s) => s.uiTheme)) {
    b.writeln('- ${g.label}: ${g.nodeCount} nodes');
  }
  b.writeln();
  b.writeln('By mood:');
  for (final g in _distributionBy(results, (s) => s.mood)) {
    b.writeln('- ${g.label}: ${g.nodeCount} nodes');
  }
  return b.toString();
}

/// The batch summary followed by every run's full transcript, in one
/// document — shared by both the "Copy" and "Export as text" actions so
/// they always produce identical content.
String _fullBatchTranscript(String strategyLabel, List<_SimResult> results,
    {Map<String, SpellSpec> spells = const {}}) {
  final b = StringBuffer()
    ..writeln(_batchSummaryText(strategyLabel, results, spells: spells));
  for (var i = 0; i < results.length; i++) {
    b
      ..writeln()
      ..writeln(_runTranscript(results[i], strategyLabel,
          runNumber: i + 1, spells: spells));
  }
  return b.toString();
}

/// Quotes a CSV field per RFC 4180 whenever it contains a comma, quote, or
/// newline (every field here can: run text, joined tag lists).
String _csvField(String value) {
  if (value.contains(RegExp('[,"\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// One row per run — final stats side by side, ready to drop into a
/// spreadsheet for sorting/charting across a batch.
String _batchResultsCsv(List<_SimResult> results) {
  final b = StringBuffer();
  b.writeln([
    'Run',
    'Ending',
    'Final Gold',
    'Final Alignment',
    'Nodes Visited',
    'Combat Encounters',
    'Furthest Chapter',
    'Reached Step Cap',
    'Shops Discovered',
    'Quests Discovered',
    'Flags',
    'Profession',
    'Level',
    'Fights Won',
    'Fights Lost',
    'Spells Cast',
    'Casts By Spell',
    'Mana From Dice',
  ].map(_csvField).join(','));
  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    b.writeln([
      '${i + 1}',
      r.endingSummary,
      '${r.finalGold}',
      '${r.finalAlignment}',
      '${r.uniqueNodesVisited}',
      '${r.combatEncounters}',
      '${r.furthestChapter ?? ''}',
      r.reachedStepCap ? 'yes' : 'no',
      r.shopsDiscovered.join('; '),
      r.questsDiscovered.join('; '),
      r.flags.join('; '),
      r.professionId,
      '${r.finalLevel}',
      '${r.fightsWon}',
      '${r.fightsLost}',
      '${r.totalCasts}',
      r.spellsCast.entries.map((e) => '${e.key} x${e.value}').join('; '),
      '${r.manaGained}',
    ].map(_csvField).join(','));
  }
  return b.toString();
}

/// The same per-run data as [_batchResultsCsv], structured for
/// programmatic reprocessing rather than spreadsheet import.
String _batchResultsJson(String strategyLabel, List<_SimResult> results) {
  final data = {
    'strategy': strategyLabel,
    'runCount': results.length,
    'runs': [
      for (var i = 0; i < results.length; i++)
        {
          'run': i + 1,
          'ending': results[i].endingSummary,
          'finalGold': results[i].finalGold,
          'finalAlignment': results[i].finalAlignment,
          'nodesVisited': results[i].uniqueNodesVisited,
          'combatEncounters': results[i].combatEncounters,
          'furthestChapter': results[i].furthestChapter,
          'reachedStepCap': results[i].reachedStepCap,
          'shopsDiscovered': results[i].shopsDiscovered.toList(),
          'questsDiscovered': results[i].questsDiscovered.toList(),
          'flags': results[i].flags.toList(),
          'raceId': results[i].raceId,
          'professionId': results[i].professionId,
          'finalLevel': results[i].finalLevel,
          'fightsWon': results[i].fightsWon,
          'fightsLost': results[i].fightsLost,
          'spellsCast': results[i].spellsCast,
          'manaGained': results[i].manaGained,
          'potionsUsed': results[i].potionsUsed,
          'spellbooksBought': results[i].spellbooksBought,
          'signsTaken': results[i].signsTaken,
          'path': results[i].path,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

class _BatchCard extends ConsumerStatefulWidget {
  const _BatchCard({
    super.key,
    required this.batch,
    required this.shops,
    required this.quests,
    required this.companions,
    required this.professions,
    required this.spells,
    this.initiallyExpanded = true,
  });

  final _SimBatch batch;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;
  final Map<String, dynamic> companions;
  final Map<String, dynamic> professions;
  final Map<String, SpellSpec> spells;

  /// Older batches start collapsed to their header line so a page of past
  /// runs doesn't bury the newest one — only the most recent batch (index
  /// 0 in the reversed list) opens expanded by default.
  final bool initiallyExpanded;

  @override
  ConsumerState<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends ConsumerState<_BatchCard> {
  bool _analyzing = false;
  String? _analysisText;
  String? _analysisError;
  late bool _expanded = widget.initiallyExpanded;
  bool _showAllRuns = false;

  static const int _runListPreviewCount = 5;

  // Filters applied to which runs count toward the stats/list/export below.
  String? _endingFilter;
  bool _onlyStepCapFilter = false;
  int? _minChapterFilter;

  String _oneDecimal(double v) => v.toStringAsFixed(1);

  List<_SimResult> get _filteredResults {
    return widget.batch.results.where((r) {
      if (_onlyStepCapFilter && !r.reachedStepCap) return false;
      if (_endingFilter != null && r.endingSummary != _endingFilter) {
        return false;
      }
      if (_minChapterFilter != null &&
          (r.furthestChapter ?? 0) < _minChapterFilter!) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _filterActive =>
      _endingFilter != null || _onlyStepCapFilter || _minChapterFilter != null;

  /// Compiles this batch's stats into a plain-text summary Gemini can
  /// reason over — the same numbers already shown in the card (respecting
  /// the current filter), plus the full transcript for a single run.
  String _buildPrompt(AppLanguage lang, List<_SimResult> results) {
    final strategyLabel = trFor(lang, _strategyLabelKey(widget.batch.strategy));
    final b = StringBuffer()
      ..writeln(
        'You are a narrative game designer reviewing simulated playthroughs of a dark-fantasy '
        'interactive-fiction app. Below is aggregate data from an automated simulator that plays '
        'the story graph choosing among valid choices per a fixed strategy.',
      )
      ..writeln()
      ..writeln(
          _batchSummaryText(strategyLabel, results, spells: widget.spells));
    final single = results.length == 1 ? results.single : null;
    if (single != null) {
      b
        ..writeln()
        ..writeln('Full node path for this run: ${single.path.join(' -> ')}');
    }
    b
      ..writeln()
      ..writeln(
        'Based on this data, provide: (1) a short summary of what this run reveals about the '
        'player\'s experience, (2) any issues you notice (repetitive endings, dead ends, '
        'pacing or balance problems, a strategy that trivially dominates, a chapter that\'s '
        'thin or overloaded compared to the others), and (3) concrete, specific suggestions '
        'for updates to particular story nodes to improve the story. Be concise.',
      );
    return b.toString();
  }

  Future<void> _analyze() async {
    final apiKey = ref.read(apiKeyProvider);
    final lang = ref.read(appLanguageProvider);
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _analysisError = trFor(lang, 'add_api_key_first'));
      return;
    }
    final results = _filteredResults;
    if (results.isEmpty) return;
    setState(() {
      _analyzing = true;
      _analysisError = null;
      _analysisText = null;
    });
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final response = await model
          .generateContent([Content.text(_buildPrompt(lang, results))]);
      if (!mounted) return;
      setState(() => _analysisText =
          response.text ?? trFor(lang, 'no_response_generated'));
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _analysisError = '${trFor(lang, 'generation_failed_prefix')}: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _viewRun(_SimResult result, int index) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: _SingleRunDetail(
            result: result,
            shops: widget.shops,
            quests: widget.quests,
            professions: widget.professions,
            spells: widget.spells,
            strategyLabel: tr(ref, _strategyLabelKey(widget.batch.strategy)),
            runNumber: index + 1,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final results = _filteredResults;
    final single = results.length == 1 ? results.single : null;
    final endingOptions = _endingCounts(batch.results).keys.toList();
    final hasChapterData = batch.results.any((r) => r.furthestChapter != null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tr(ref, _strategyLabelKey(batch.strategy))} × ${batch.runCount}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!_expanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${_oneDecimal(_avg(batch.results.map((r) => r.finalGold)))}g · '
                              '${tr(ref, 'final_alignment_label')} '
                              '${_oneDecimal(_avg(batch.results.map((r) => r.finalAlignment)))} · '
                              '${_endingCounts(batch.results).entries.map((e) => '${e.value}× ${e.key}').join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: tr(ref, 'copy_button'),
                    onPressed: results.isEmpty
                        ? null
                        : () => _copyToClipboard(
                              context,
                              ref,
                              _fullBatchTranscript(
                                tr(ref, _strategyLabelKey(batch.strategy)),
                                results,
                                spells: widget.spells,
                              ),
                            ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: tr(ref, 'export_all_runs_button'),
                    enabled: results.isNotEmpty,
                    onSelected: (format) {
                      final strategyLabel =
                          tr(ref, _strategyLabelKey(batch.strategy));
                      switch (format) {
                        case 'txt':
                          _exportToFile(
                            context,
                            ref,
                            _fullBatchTranscript(strategyLabel, results,
                                spells: widget.spells),
                            'playthrough_batch_${batch.id}.txt',
                          );
                        case 'csv':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsCsv(results),
                            'playthrough_batch_${batch.id}.csv',
                          );
                        case 'json':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsJson(strategyLabel, results),
                            'playthrough_batch_${batch.id}.json',
                          );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'txt', child: Text(tr(ref, 'export_as_text'))),
                      PopupMenuItem(
                          value: 'csv', child: Text(tr(ref, 'export_as_csv'))),
                      PopupMenuItem(
                          value: 'json',
                          child: Text(tr(ref, 'export_as_json'))),
                    ],
                  ),
                  IconButton(
                    icon:
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: tr(
                        ref,
                        _expanded
                            ? 'collapse_batch_label'
                            : 'expand_batch_label'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              if (batch.runCount > 1) ...[
                const SizedBox(height: 8),
                Text(tr(ref, 'filter_runs_label'),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String?>(
                      value: _endingFilter,
                      hint: Text(tr(ref, 'ending_filter_all')),
                      items: [
                        DropdownMenuItem(
                            value: null,
                            child: Text(tr(ref, 'ending_filter_all'))),
                        for (final e in endingOptions)
                          DropdownMenuItem(value: e, child: Text(e)),
                      ],
                      onChanged: (v) => setState(() => _endingFilter = v),
                    ),
                    if (hasChapterData)
                      DropdownButton<int?>(
                        value: _minChapterFilter,
                        hint: Text(tr(ref, 'min_chapter_filter_label')),
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text(tr(ref, 'any_label'))),
                          for (var c = 1; c <= 5; c++)
                            DropdownMenuItem(
                                value: c,
                                child: Text(
                                    '${tr(ref, 'min_chapter_filter_label')} $c')),
                        ],
                        onChanged: (v) => setState(() => _minChapterFilter = v),
                      ),
                    if (batch.stepCapCount > 0)
                      FilterChip(
                        label: Text(tr(ref, 'stuck_only_filter')),
                        selected: _onlyStepCapFilter,
                        onSelected: (v) =>
                            setState(() => _onlyStepCapFilter = v),
                      ),
                    if (_filterActive)
                      TextButton(
                        onPressed: () => setState(() {
                          _endingFilter = null;
                          _onlyStepCapFilter = false;
                          _minChapterFilter = null;
                        }),
                        child: Text(tr(ref, 'clear_all_button')),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (results.isEmpty)
                Text(tr(ref, 'no_runs_match_filter'))
              else ...[
                Builder(builder: (context) {
                  final avgAlignment =
                      _avg(results.map((r) => r.finalAlignment));
                  final alignmentColor = avgAlignment > 0.5
                      ? Colors.blue
                      : (avgAlignment < -0.5
                          ? Colors.deepOrange
                          : Colors.blueGrey);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLine(
                        icon: Icons.route,
                        color: Colors.blueGrey,
                        text:
                            '${tr(ref, 'nodes_visited_label')}: ${_oneDecimal(_avg(results.map((r) => r.steps.length)))}',
                      ),
                      _StatLine(
                        icon: Icons.paid,
                        color: Colors.amber.shade800,
                        text:
                            '${tr(ref, 'final_gold_label')}: ${_oneDecimal(_avg(results.map((r) => r.finalGold)))}',
                      ),
                      _StatLine(
                        icon: Icons.balance,
                        color: alignmentColor,
                        text:
                            '${tr(ref, 'final_alignment_label')}: ${_oneDecimal(avgAlignment)}',
                      ),
                      _StatLine(
                        icon: Icons.sports_martial_arts,
                        color: Colors.red.shade400,
                        text:
                            '${tr(ref, 'combat_encounters_label')}: ${_oneDecimal(_avg(results.map((r) => r.combatEncounters)))}',
                      ),
                      if (results.any((r) => r.hasCharacter)) ...[
                        _StatLine(
                          icon: Icons.emoji_events_outlined,
                          color: Colors.green.shade700,
                          text:
                              '${tr(ref, 'sim_fights_label')}: ${_oneDecimal(_avg(results.map((r) => r.fightsWon)))} / '
                              '${_oneDecimal(_avg(results.map((r) => r.fightsLost)))}',
                        ),
                        _StatLine(
                          icon: manaIcon,
                          color: manaColor,
                          text:
                              '${tr(ref, 'sim_spells_cast_label')}: ${_oneDecimal(_avg(results.map((r) => r.totalCasts)))} '
                              '(${tr(ref, 'sim_mana_from_dice_label').toLowerCase()} ${_oneDecimal(_avg(results.map((r) => r.manaGained)))})',
                        ),
                      ],
                    ],
                  );
                }),
                if (results.where((r) => r.reachedStepCap).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${results.where((r) => r.reachedStepCap).length}/${results.length} '
                      '${tr(ref, 'exceeded_step_cap_label')}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(tr(ref, 'endings_label'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                for (final entry in _endingCounts(results).entries)
                  Text('${entry.value}× ${entry.key}',
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(tr(ref, 'companions_encountered_label'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final counts =
                      _companionEncounterCounts(results, widget.quests);
                  if (counts.isEmpty) {
                    return Text(
                      tr(ref, 'none_label'),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in counts.entries)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: _companionColor(entry.key, counts),
                          ),
                          label: Text(
                            '${widget.companions[entry.key]?['companionName']?.toString() ?? entry.key} '
                            '· ${entry.value}/${results.length}',
                          ),
                        ),
                    ],
                  );
                }),
                if (results.any((r) => r.hasCharacter)) ...[
                  const SizedBox(height: 12),
                  Text(tr(ref, 'sim_spells_cast_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final totals = _spellCastTotals(results);
                    if (totals.isEmpty) {
                      return Text(
                        tr(ref, 'sim_no_spells_cast'),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    final runsCasting = _runsCastingCounts(results);
                    final lang = ref.watch(appLanguageProvider);
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final entry in totals.entries)
                          Tooltip(
                            message:
                                '${runsCasting[entry.key] ?? 0}/${results.length} ${tr(ref, 'sim_runs_casting_label')}',
                            child: Chip(
                              avatar: Icon(
                                widget.spells[entry.key] == null
                                    ? manaIcon
                                    : spellEffectIcon(
                                        widget.spells[entry.key]!.effect),
                                size: 16,
                                color: widget.spells[entry.key] == null
                                    ? manaColor
                                    : spellEffectColor(
                                        widget.spells[entry.key]!.effect),
                              ),
                              label: Text(
                                '${_spellDisplayName(entry.key, widget.spells, lang)} '
                                '· ${entry.value}',
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(tr(ref, 'sim_by_profession_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final entry in _professionTotals(results).entries)
                    Text(
                      '${_professionDisplayName(entry.key, widget.professions)}: '
                      '${entry.value.runs} ${entry.value.runs == 1 ? 'run' : 'runs'} · '
                      '${tr(ref, 'sim_fights_label').toLowerCase()} ${entry.value.won} / ${entry.value.lost} · '
                      '${tr(ref, 'sim_spells_cast_label').toLowerCase()} ${entry.value.casts}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    tr(ref, 'sim_combat_model_note'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
                const Divider(height: 24),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(tr(ref, 'chapter_breakdown_label')),
                  initiallyExpanded: hasChapterData,
                  children: [
                    for (final g in _chapterBreakdown(results))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${g.label} · ${g.runsReaching}/${results.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              [
                                '${(g.nodeCount / g.runsReaching).toStringAsFixed(1)} '
                                    '${tr(ref, 'nodes_visited_label').toLowerCase()}',
                                if (g.combatCount > 0)
                                  '${g.combatCount} ${tr(ref, 'combat_encounters_label').toLowerCase()}',
                                if (g.fightsLost > 0)
                                  '${g.fightsLost} ${tr(ref, 'sim_fight_lost_label')}',
                                if (g.spellCasts > 0)
                                  '${g.spellCasts} ${tr(ref, 'sim_spells_cast_label').toLowerCase()}',
                                if (g.goldDelta != 0) 'gold Δ${g.goldDelta}',
                                if (g.alignmentDelta != 0)
                                  'align Δ${g.alignmentDelta}',
                              ].join(' • '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(tr(ref, 'by_location_label')),
                  children: [
                    for (final g in _distributionBy(results, (s) => s.uiTheme))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(g.label,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                            Text(
                              '${g.nodeCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(tr(ref, 'by_mood_label')),
                  children: [
                    for (final g in _distributionBy(results, (s) => s.mood))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(g.label,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                            Text(
                              '${g.nodeCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : _analyze,
                        icon: _analyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _analyzing
                              ? tr(ref, 'analyzing_label')
                              : tr(ref, 'analyze_with_gemini_button'),
                        ),
                      ),
                    ),
                    if (_analysisText != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: tr(ref, 'copy_button'),
                        onPressed: () =>
                            _copyToClipboard(context, ref, _analysisText!),
                      ),
                    ],
                  ],
                ),
                if (_analysisError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _analysisError!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (_analysisText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(_analysisText!),
                    ),
                  ),
                if (single != null) ...[
                  const Divider(height: 24),
                  _SingleRunDetail(
                    result: single,
                    shops: widget.shops,
                    quests: widget.quests,
                    professions: widget.professions,
                    spells: widget.spells,
                    strategyLabel: tr(ref, _strategyLabelKey(batch.strategy)),
                  ),
                ] else ...[
                  const Divider(height: 24),
                  Text(tr(ref, 'individual_runs_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (var i = 0;
                      i <
                          (_showAllRuns
                              ? results.length
                              : results.length.clamp(0, _runListPreviewCount));
                      i++)
                    InkWell(
                      onTap: () => _viewRun(
                          results[i], batch.results.indexOf(results[i])),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${batch.results.indexOf(results[i]) + 1}: ${results[i].finalGold}g, '
                                '${tr(ref, 'final_alignment_label')} ${results[i].finalAlignment}, '
                                '${results[i].steps.length} ${tr(ref, 'nodes_visited_label')}'
                                '${results[i].hasCharacter ? ' · ${_professionDisplayName(results[i].professionId, widget.professions)} L${results[i].finalLevel} · ${results[i].totalCasts} ${tr(ref, 'sim_spells_cast_label').toLowerCase()}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  if (results.length > _runListPreviewCount)
                    TextButton(
                      onPressed: () =>
                          setState(() => _showAllRuns = !_showAllRuns),
                      child: Text(
                        _showAllRuns
                            ? tr(ref, 'show_less_label')
                            : '${tr(ref, 'show_all_runs_label')} (${results.length})',
                      ),
                    ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// " — won (2 attempts)" / " — lost" for a step's fight, or '' when the
/// walk didn't play it out.
String _fightTag(_SimStep step, WidgetRef ref) {
  final won = step.fightWon;
  if (won == null) return '';
  final outcome =
      won ? tr(ref, 'sim_fight_won_label') : tr(ref, 'sim_fight_lost_label');
  final attempts = step.fightAttempts > 1
      ? ' (${step.fightAttempts} ${tr(ref, 'sim_attempts_label')})'
      : '';
  return ' — $outcome$attempts';
}

class _SingleRunDetail extends ConsumerStatefulWidget {
  const _SingleRunDetail({
    required this.result,
    required this.shops,
    required this.quests,
    required this.professions,
    required this.spells,
    required this.strategyLabel,
    this.runNumber,
    this.scrollController,
  });

  final _SimResult result;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;
  final Map<String, dynamic> professions;
  final Map<String, SpellSpec> spells;
  final String strategyLabel;
  final int? runNumber;
  final ScrollController? scrollController;

  @override
  ConsumerState<_SingleRunDetail> createState() => _SingleRunDetailState();
}

class _SingleRunDetailState extends ConsumerState<_SingleRunDetail> {
  int?
      _chapterFilter; // null = show all chapters. Use -1 as the "Prologue" sentinel.

  String _namesFor(
      Set<String> ids, Map<String, dynamic> records, String nameField) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) =>
            (records[id] as Map<String, dynamic>?)?[nameField]?.toString() ??
            id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final chapters = result.steps.map((s) => s.chapter ?? -1).toSet().toList()
      ..sort();
    final filteredSteps = _chapterFilter == null
        ? result.steps
        : result.steps
            .where((s) => (s.chapter ?? -1) == _chapterFilter)
            .toList();

    final content = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              widget.runNumber != null
                  ? '${tr(ref, 'playthrough_recap_title')} — #${widget.runNumber}'
                  : tr(ref, 'playthrough_recap_title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: tr(ref, 'copy_button'),
            onPressed: () => _copyToClipboard(
              context,
              ref,
              _runTranscript(result, widget.strategyLabel,
                  runNumber: widget.runNumber, spells: widget.spells),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: tr(ref, 'export_button'),
            onPressed: () => _exportToFile(
              context,
              ref,
              _runTranscript(result, widget.strategyLabel,
                  runNumber: widget.runNumber, spells: widget.spells),
              'playthrough_run_${widget.runNumber ?? 1}.txt',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('${tr(ref, 'ending_reached_label')}: ${result.endingSummary}'),
      if (result.furthestChapter != null)
        Text('${tr(ref, 'furthest_chapter_label')}: ${result.furthestChapter}'),
      Text(
        '${tr(ref, 'unique_nodes_visited_label')}: ${result.uniqueNodesVisited} '
        '(${result.steps.length} ${tr(ref, 'total_steps_label')})',
      ),
      Text(
          '${tr(ref, 'shops_discovered_label')}: ${_namesFor(result.shopsDiscovered, widget.shops, 'shopName')}'),
      Text(
        '${tr(ref, 'quests_discovered_label')}: ${_namesFor(result.questsDiscovered, widget.quests, 'questName')}',
      ),
      Text(
        '${tr(ref, 'flags_collected_label')}: ${result.flags.isEmpty ? '—' : result.flags.join(', ')}',
      ),
      if (result.hasCharacter) ...[
        const SizedBox(height: 8),
        Text(
          '${tr(ref, 'sim_character_label')}: '
          '${_professionDisplayName(result.professionId, widget.professions)} '
          '(${result.raceId}) · ${tr(ref, 'level_abbrev')} ${result.finalLevel}',
        ),
        Text(
            '${tr(ref, 'sim_fights_label')}: ${result.fightsWon} / ${result.fightsLost}'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 4),
              child: Icon(manaIcon, size: 16, color: manaColor),
            ),
            Expanded(
              child: Text(
                '${tr(ref, 'sim_spells_cast_label')}: '
                '${_castsSummary(result.spellsCast, widget.spells, ref.watch(appLanguageProvider)) ?? tr(ref, 'sim_no_spells_cast')}'
                ' · ${tr(ref, 'sim_mana_from_dice_label').toLowerCase()} ${result.manaGained}',
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Text(tr(ref, 'path_summary_label'),
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: Text(tr(ref, 'chapter_filter_all_label')),
            selected: _chapterFilter == null,
            onSelected: (_) => setState(() => _chapterFilter = null),
          ),
          for (final c in chapters)
            ChoiceChip(
              label: Text(c == -1 ? tr(ref, 'prologue_label') : 'Ch. $c'),
              selected: _chapterFilter == c,
              onSelected: (_) => setState(() => _chapterFilter = c),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ];

    final stepTiles = [
      for (final entry in filteredSteps.asMap().entries)
        ExpansionTile(
          key: ValueKey('${entry.value.nodeId}_${entry.key}'),
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Node ${entry.value.nodeId} · ${_chapterLabel(entry.value.chapter)}'
            '${entry.value.uiTheme != null ? ' · ${entry.value.uiTheme}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            entry.value.description.length > 70
                ? '${entry.value.description.substring(0, 70)}…'
                : entry.value.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.description),
                  if (entry.value.choiceText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '→ "${entry.value.choiceText}"'
                      '${entry.value.enemyId != null ? '  [combat: ${entry.value.enemyId}${_fightTag(entry.value, ref)}]' : ''}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    if (entry.value.spellsCast.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${tr(ref, 'sim_spells_cast_label')}: '
                          '${_castsSummary(entry.value.spellsCast, widget.spells, ref.watch(appLanguageProvider))}',
                          style:
                              const TextStyle(color: manaColor, fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
    ];

    if (widget.scrollController != null) {
      // Rendered inside a DraggableScrollableSheet -- one scroll view for
      // the whole thing, driven by the sheet's own controller.
      return ListView(
        controller: widget.scrollController,
        children: [...content, ...stepTiles],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...content, ...stepTiles],
    );
  }
}
