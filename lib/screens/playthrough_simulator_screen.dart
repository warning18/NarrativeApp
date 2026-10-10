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

import '../combat/combat_engine.dart'
    show chapterRewardMultiplier, isBossEnemy, scaledReward, zoneBossEnemyIds;
import '../combat/gear_effects.dart';
import '../combat/spells.dart';
import '../data/autoplay_engine.dart';
import '../data/chapter_loop.dart';
import '../data/chapter_spine.dart';
import '../data/factions.dart';
import '../data/perks.dart';
import '../data/politics_events.dart' show choicePoliticsKey, enterPoliticsKey;
import '../data/signs.dart';
import '../data/sim_combat.dart';
import '../data/sim_growth.dart';
import '../data/story_graph_integrity.dart';
import '../data/story_repository.dart';
import '../data/sub_node_engine.dart';
import '../data/geography.dart';
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
import '../providers/settings_providers.dart';
import '../providers/story_providers.dart';
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
  }
}

/// How the simulator picks among a node's valid (non-locked) choices. Lets
/// the user compare "what if the player always chased gold" against "what
/// if they always leaned good/evil" instead of only pure-random runs.
enum SimStrategy { random, favorGood, favorEvil, maximizeGold }

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
    this.spellsCast = const {},
    this.manaGained = 0,
    this.potionsUsed = 0,
    this.spellbooksBought = const [],
    this.signsTaken = const [],
    this.offersTaken = 0,
    this.skillsLearned = 0,
  });

  final List<_SimStep> steps;
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
  });

  /// Play the v1.212-v1.215 fight rules (goals, squads, parries, ...).
  final bool clash;

  /// Clash rules to leave out ('goal', 'squad', 'response', 'parry',
  /// 'reaction', 'writ'), to see what each one does to the numbers.
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
}) {
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
    final raceId = raceIds[random.nextInt(raceIds.length)];
    final professionId = professionIds[random.nextInt(professionIds.length)];
    character = SimCharacter.create(
      raceId: raceId,
      race: sim.races[raceId] as Map<String, dynamic>,
      professionId: professionId,
      profession: sim.professions[professionId] as Map<String, dynamic>,
      gameConfig: sim.gameConfig,
      dice: sim.dice,
      spells: sim.spells,
    );
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
  final steps = <_SimStep>[];
  // How the character grows (see sim_growth.dart): the clans' offers, or
  // the old skill points, perks and sign picks.
  final growth = character == null || sim == null
      ? null
      : SimGrowth(
          mode: sim.progression,
          tables: sim.growthTables,
          character: character,
          startingSkillPoints: (sim.professions[character.professionId]
                  as Map<String, dynamic>?)?['startingSkillPoints'] as int? ??
              0,
        );
  // The open chapters' loop: the camp the story stands at, the places
  // already toured from it, and the place being toured now (with how many
  // things are left to do there).
  final visited = <String>{currentId};
  String? campId;
  final toured = <String>{};
  String? tourPlaceId;
  var tourBudget = 0;

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
      spellsCast: Map.unmodifiable(character?.spellsCast ?? const {}),
      manaGained: character?.manaGained ?? 0,
      potionsUsed: character?.potionsUsed ?? 0,
      spellbooksBought:
          List.unmodifiable(character?.spellbooksBought ?? const []),
      signsTaken: List.unmodifiable(growth?.signsTaken ?? const <String>[]),
      offersTaken: growth?.giftsTaken.values.fold<int>(0, (a, b) => a + b) ?? 0,
      skillsLearned: growth?.skillsLearned ?? 0,
    );
  }

  StoryChoice pickChoice(List<StoryChoice> pool) {
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
        case SimStrategy.random:
          return 0;
      }
    }

    final best = pool.map(score).reduce(max);
    final tied = pool.where((c) => score(c) == best).toList();
    return tied[random.nextInt(tied.length)];
  }

  /// What the character fights with now; in one of the last battles
  /// ([host], v1.196) the Host fights beside them.
  SignEffects signsNow({bool host = false}) =>
      growth?.effects(alignment, host: host) ?? SignEffects.none;

  /// A story choice's or a scene's politics (v1.196: the claim, the
  /// pledges, the Throne and the muster with the rest), once under [key],
  /// in the chapter the walk is in.
  void applyPolitics(StoryPolitics? politics, String key) {
    final g = growth;
    if (g == null || politics == null || politics.isEmpty) return;
    final after = g.applyStoryPolitics(politics,
        flags: flags, chapter: lastKnownChapter ?? 1, key: key);
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
    alignment = g.settle(alignment: alignment, flags: flags, random: random);
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
      {bool once = false, bool host = false}) {
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
        if (enemies[id] is Map<String, dynamic>)
          MapEntry(id, enemies[id] as Map<String, dynamic>),
    ];
    if (entries.isEmpty) return none;
    final casts = <String, int>{};
    final maxAttempts = once ? 1 : _maxFightAttempts;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final signs = signsNow(host: host);
      final perks = growth?.perks ?? PerkEffects.none;
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
      );
      // Every pact runs one fight on, won or lost.
      c.heldSigns = countDownPacts(c.heldSigns);
      for (final entry in outcome.spellsCast.entries) {
        casts[entry.key] = (casts[entry.key] ?? 0) + entry.value;
      }
      if (outcome.won) {
        var xp = 0;
        for (final entry in entries) {
          xp += scaledReward(
              (entry.value['xpReward'] as num?)?.toInt() ?? 0, c.level);
        }
        final levelBefore = c.level;
        c.gainXp(perks.scaleXp(
            signs.scaleXp((xp * chapterRewardMultiplier(chapter)).round())));
        growth?.levelsReached(levelBefore, c.level);
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

  /// The hazard on the road from [fromNodeId] to [toNodeId] (v1.197),
  /// [at] steps into the walk, met where the game would meet it (see
  /// roadEventFor): pushed through above half health (the character
  /// wounded, never to death), waited out below. The road's other events
  /// the walk passes by, as it does detours.
  void roadHazard(String fromNodeId, String toNodeId, int at) {
    final geography = sim?.geography;
    final chapter = lastKnownChapter;
    if (geography == null || chapter == null) return;
    final biome = geography.roadBiome(story, fromNodeId, toNodeId);
    final share = hazardShareFor(biome);
    if (share == 0) return;
    final kind = roadEventFor(
      story: story,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      historyLength: at,
      chapter: chapter,
      hazardShare: share,
      world: geography,
    );
    if (kind != RoadEventKind.hazard) return;
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
  }

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

    if (c != null) {
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
        final size =
            pack ? SubNodeEngine.maxPackSizeFor(zoneChapter, partySize: 1) : 1;
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
  }

  // A new character's starting points (offers, or skill points).
  settle();
  for (var step = 0; step < maxSteps; step++) {
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
      restedChapter = lastKnownChapter;
      final reached = lastKnownChapter;
      if (reached != null) {
        growth?.chapterReached(reached);
        settle();
      }
    }

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
        currentId = arrivalNodeFor(next, visited);
        visited.add(currentId);
        continue;
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
        currentId = campId!;
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

    // A won fight pays out the enemy's goldReward just like a real playthrough
    // (see FightScreen._finishFight) — folded into this step's goldMod so the
    // chapter breakdown and CSV/JSON exports stay consistent with finalGold.
    // The signs take their share of it (a pact's curse some back).
    final fightResult = fight(choice, lastKnownChapter ?? 1);
    final effectiveGoldMod = choice.goldMod +
        fightResult.signs
            .scaleGold(fightResult.perks.scaleGold(combatGoldReward(choice))) +
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

    gold = (gold + effectiveGoldMod).clamp(0, 1 << 30).toInt();
    alignment += choice.alignmentMod;
    flags.addAll(choice.flagsToAdd);
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
        );
      }
    }
    if ((choice.unlockQuestId ?? '').isNotEmpty) {
      quests.add(choice.unlockQuestId!);
    }
    // What waits on the road there (v1.197).
    if (!choice.isEnding) roadHazard(currentId, choice.nextId, step);
    if (choice.triggersCombat) combatCount++;
    // An expedition the choice launches (a zone to clear before the story
    // goes on) is played out before it does.
    if (choice.launchesZone) {
      expedition(choice.launchZoneId!, node, host: choice.hostFight);
    }

    if (choice.isEnding) {
      return finish(endingText: choice.text, reachedStepCap: false);
    }
    currentId = choice.nextId;
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
}) {
  Map<String, dynamic> table(String name) => tables[name] ?? const {};
  final sim = _SimContext(
    dice: table('dice'),
    skills: table('skills'),
    items: table('items'),
    shops: table('shops'),
    races: table('races'),
    professions: table('professions'),
    spells: parseSpells(table('spells')),
    gameConfig: gameConfig,
    itemSets: parseItemSets(table('item_sets')),
    zones: table('zones'),
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
  );
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

  /// Whether the strategy/runs/simulate controls are shown in full. They
  /// collapse to a compact bar the moment there's a result to look at, so
  /// results don't start halfway down a small screen — and re-expand
  /// automatically once the results list is scrolled back to the top, and
  /// collapse again the moment the user scrolls down into the results, or
  /// on a manual tap.
  bool _controlsExpanded = true;
  final ScrollController _resultsScrollController = ScrollController();
  double _lastResultsScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _onResultsScroll() {
    final offset = _resultsScrollController.offset;
    if (offset <= 4) {
      if (!_controlsExpanded) setState(() => _controlsExpanded = true);
    } else if (offset > _lastResultsScrollOffset && _controlsExpanded) {
      setState(() => _controlsExpanded = false);
    }
    _lastResultsScrollOffset = offset;
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
    final zones =
        await ref.read(gameDbRepositoryProvider(zonesSchema)).loadRecords();

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
      zones: await load(zonesSchema),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showFullControls
                  ? _fullControls(context, batches)
                  : _compactControlsBar(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: batches.isEmpty
                  ? Center(child: Text(tr(ref, 'no_batches_yet_message')))
                  : ListView(
                      controller: _resultsScrollController,
                      children: [
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
                      ],
                    ),
            ),
          ],
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
                          break;
                        case 'csv':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsCsv(results),
                            'playthrough_batch_${batch.id}.csv',
                          );
                          break;
                        case 'json':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsJson(strategyLabel, results),
                            'playthrough_batch_${batch.id}.json',
                          );
                          break;
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
