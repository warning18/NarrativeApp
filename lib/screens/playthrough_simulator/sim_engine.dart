// The playthrough simulator's engine: the walk through the story, its
// fights, places and politics, and simulatePlaythroughs (the tests' entry
// point), cut out of
// playthrough_simulator_screen.dart with no change (wave 4a).
part of '../playthrough_simulator_screen.dart';

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
        dice: dice,
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

  // The competent player tries a die before switching to it (sim_combat.dart's
  // dieTrial): the foes of the fight at hand, a few fights with each die on
  // the same seeds; the new one must win more, or as many with more health
  // left.
  var trialFoes = <MapEntry<String, Map<String, dynamic>>>[];
  var trialChapter = 1;
  if (character != null && sim != null && sim.policy == SimPolicy.competent) {
    final c = character;
    ({int wins, int health}) tryDie(List<Map<String, dynamic>> faces,
            Map<String, String> assignments) =>
        c.restoringAfter(() {
          c.diceFaces = faces;
          c.diceSkillAssignments = assignments;
          var wins = 0, health = 0;
          for (var i = 0; i < simDieTrialFights; i++) {
            c.currentHealth = c.maxHealth;
            c.statusEffects = [];
            final o = simulateSimFight(
              character: c,
              enemies: trialFoes,
              chapter: trialChapter,
              skills: sim.skills,
              items: sim.items,
              itemSets: sim.itemSets,
              random: Random(7919 + i),
              clash: sim.clash,
              clashOff: sim.clashOff,
              context: sim.context,
              reinforcement: sim.reinforcement,
            );
            if (o.won) wins++;
            health += c.currentHealth;
          }
          return (wins: wins, health: health);
        });
    c.dieTrial = (faces, assignments) {
      // Before the first fight there is nothing to try it on.
      if (trialFoes.isEmpty) return true;
      final now = tryDie(c.diceFaces, c.diceSkillAssignments);
      final next = tryDie(faces, assignments);
      return next.wins > now.wins ||
          (next.wins == now.wins && next.health > now.health);
    };
  }

  var currentId = StoryRepository.startNodeId;
  var gold = character?.startingGold ?? 0;
  var alignment = 0;
  final flags = <String>{};
  final shops = <String>{};
  // The shops the walk can reach (v1.766): a scene's, a port's at its
  // settlement, a house's once built, the road's caravan; visited at the
  // next choice, once a chapter at most (a port's again when the walk is
  // back there a later chapter), from the chapter the shop opens.
  final pendingShops = <String>[];
  final shopVisitedInChapter = <String, int>{};
  final sceneShops = <String>{};
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
      if ((sim?.championFights ?? false) &&
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
          if (result.won ?? false) {
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
                    '${step.enemyId == null ? '' : ' · fight ${step.enemyId}: ${step.fightWon ?? false ? 'won' : step.fightWon == false ? 'lost' : '-'}'}'
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
      gold = (gold + pay.gold).clamp(0, 1 << 30);
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
    // The die trial plays this fight's foes (see dieTrial above).
    trialFoes = entries;
    trialChapter = chapter;
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
      // A clan's die with its Resonance lit rolls its low faces one more
      // (clan_dice.dart), for this fight.
      final ownFaces = c.diceFaces;
      if (growth != null &&
          resonanceOf(sim.dice[c.diceId] as Map<String, dynamic>?,
                  politics: growth.politics, data: growth.tables.clans) ==
              Resonance.lit) {
        c.diceFaces = resonantFaces(ownFaces);
      }
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
      );
      c.diceFaces = ownFaces;
      party?.afterFight(allies, won: outcome.won, signs: signs);
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
      defend: (id) => fightEnemies([id], chapter, once: true).won ?? false,
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
      defend: (id) => fightEnemies([id], chapter, once: true).won ?? false,
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
      gold = (gold + result.gold).clamp(0, 1 << 30);
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
    // The Wayfarer's Caravan on the road: its stall is looked at.
    if (kind == RoadEventKind.caravan) pendingShops.add(caravanShopId);
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
      final houseShop =
          (houses[id] as Map?)?['unlocksShopId']?.toString() ?? '';
      if (houseShop.isNotEmpty) pendingShops.add(houseShop);
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
    // A port's shops at its settlement.
    final portId = here?.portId;
    if (portId != null) {
      final port = sim?.ports[portId];
      if (port is Map<String, dynamic>) pendingShops.addAll(portShopIds(port));
    }
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
    gold = (gold + effectiveGoldMod).clamp(0, 1 << 30);
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
    if (sim?.featureLadder ?? false) {
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
      pendingShops.add(choice.unlockShopId!);
      sceneShops.add(choice.unlockShopId!);
    }
    final chapterNow = lastKnownChapter ?? 1;
    while (pendingShops.isNotEmpty) {
      final shopId = pendingShops.removeAt(0);
      final shop = sim?.shops[shopId];
      final opens =
          (shop is Map ? shop['minChapter'] as num? : null)?.toInt() ?? 1;
      // A scene's shop is found when the scene unlocks it, even before
      // its chapter; one reached any other way only once it is open.
      if (chapterNow < opens && !sceneShops.contains(shopId)) continue;
      if (shopVisitedInChapter[shopId] == chapterNow) continue;
      shopVisitedInChapter[shopId] = chapterNow;
      shops.add(shopId);
      if (character != null && sim != null && shop is Map) {
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
/// never takes a sign, without 'factions' no clan comes.
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
  bool clash = true,
  Set<String> clashOff = const {},
  SimPolicy policy = SimPolicy.naive,
}) {
  Map<String, dynamic> table(String name) => tables[name] ?? const {};
  final sim = _simContextOf(tables, gameConfig,
      clash: clash, clashOff: clashOff, policy: policy);
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
        won: before.won + (step.fightWon ?? false ? 1 : 0),
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
        won: before.won + (step.fightWon ?? false ? 1 : 0),
        fights: before.fights + 1,
        firstTry: before.firstTry +
            ((step.fightWon ?? false) && step.fightAttempts == 1 ? 1 : 0),
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
