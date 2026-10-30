import 'dart:math';

import '../combat/dice_faces.dart' show isOpenSkillFace;
import '../combat/gear_effects.dart' show ItemSet;
import '../models/ally_state.dart' show meetsItemStatRequirement;
import '../combat/spec_variants.dart' show SpecVariantInfo;
import '../combat/specialisations.dart' show SpecInfo;
import '../combat/spells.dart';
import '../models/story_node.dart';
import 'clan_power.dart';
import 'district_influence.dart' as influence show applyQuestInfluence;
import 'factions.dart';
import 'feature_unlocks.dart';
import 'geography.dart';
import 'nemesis.dart' show updateNemesis;
import 'offers.dart';
import 'perks.dart';
import 'patron_stats.dart';
import 'politics_events.dart';
import 'politics_events.dart' as coast show applyStoryPolitics;
import 'camp_rolls.dart' show RollBanOn;
import 'clan_crisis.dart' show buildCrisisNode, mainClanOf;
import '../combat/clan_dice.dart' show Resonance, resonanceOf, resonantFaces;
import 'district_attacks.dart'
    show buildSiegeNode, rollDistrictAttacks, settleSiegeAway;
import 'risky_gifts.dart';
import 'signs.dart';
import 'sim_combat.dart';
import 'sim_policy.dart';
import 'skill_tree.dart';
import 'throne.dart';

/// How the simulated character grows (see the playthrough simulator):
/// - [legacy]: the rules before v1.194 -- a skill point a level (and the
///   profession's starting ones) spent on the tree, a perk every even
///   level, a sign every odd level and every boss;
/// - [offers]: v1.194 -- an offer from the clans for each level, each
///   boss and each chapter reached (and the profession's starting points),
///   taken by [preferredSuitor]'s policy.
/// Both share the fight model and how a learned skill finds a face on the
/// die ([SimGrowth.assignSkills]), so their win rates compare.
enum SimProgression { legacy, offers }

/// The gamedata the growth reads.
class SimGrowthTables {
  const SimGrowthTables({
    this.skills = const {},
    this.skillTrees = const {},
    this.items = const {},
    this.spells = const {},
    this.patrons = const {},
    this.signs = const {},
    this.clans = ClanData.empty,
    this.specs = const {},
    this.specVariants = const {},
    this.events = const {},
    this.itemSets = const {},
    this.merges = const {},
    this.dice = const {},
  });

  /// item_sets.json parsed and skill_merges.json: what the competent
  /// player weighs its gear by and crafts at the Skillwright.
  final Map<String, ItemSet> itemSets;
  final Map<String, dynamic> merges;

  /// dice.json: the clans' dice (clan_dice.dart).
  final Map<String, dynamic> dice;

  /// politics_events.json parsed: the events the coast fires by itself
  /// ([SimGrowth.runEvents]) and a story choice's `event`. None, none
  /// fire.
  final Map<String, PoliticsEvent> events;

  /// specialisations.json parsed: the main clans' specialisations; and
  /// spec_variants.json, their sub-clans' variants and ranks II.
  final Map<String, SpecInfo> specs;
  final Map<String, SpecVariantInfo> specVariants;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> skillTrees;
  final Map<String, dynamic> items;
  final Map<String, SpellSpec> spells;
  final Map<String, Patron> patrons;
  final Map<String, SignDef> signs;
  final ClanData clans;
}

/// The perks the simulator takes, best first: what a fight model without a
/// party, rerolls or momentum feels most.
const List<Perk> _simPerkPreference = [
  Perk.heavyHand,
  Perk.ironHide,
  Perk.vigor,
  Perk.keenEye,
  Perk.lastStand,
  Perk.lightFeet,
  Perk.apothecary,
  Perk.deepWell,
  Perk.plunderer,
  Perk.quickStudy,
  Perk.steadyHands,
  Perk.battleRhythm,
  Perk.leader,
];

/// The odds the offers' policy takes the suitor of the faction the
/// character stands best with, rather than the best gift.
const double _simFavourBestChance = 0.25;

/// A skill's worth on a die face, for the simulator's assignment: what it
/// hits for over a plain blow, what it heals, a status it carries.
double simSkillScore(Map<String, dynamic>? skill) {
  if (skill == null) return 0;
  final mod = (skill['damageMod'] as num?)?.toDouble() ?? 0;
  final mult = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1;
  final heal = (skill['healAmount'] as num?)?.toDouble() ?? 0;
  final status = (skill['inflictsStatus']?.toString() ?? 'None') != 'None';
  // A hit of the fight's small scale (stat_scale.md: about 3).
  const base = 3.0;
  final damage = mult <= 0 ? 0.0 : (base + mod) * max(1.0, mult) - base;
  return damage + heal * 0.7 + (status ? 1 : 0);
}

/// The growth of one simulated character, in either [mode]: what waits
/// (skill points, perk and sign picks; offers), what was taken, and the
/// politics the offers move. The walk calls [levelsReached],
/// [bossBeaten] and [chapterReached], then [settle] to spend what waits.
class SimGrowth {
  SimGrowth({
    required this.mode,
    required this.tables,
    required this.character,
    int startingSkillPoints = 0,
    this.ladder = false,
    this.policy = SimPolicy.naive,
  }) {
    if (mode == SimProgression.legacy) {
      skillPoints = startingSkillPoints;
    } else if (!ladder) {
      // On the feature ladder the starting skill comes from the trainer.
      for (var i = 0; i < startingSkillPoints; i++) {
        pending.add(const OfferTicket(source: OfferSource.start));
      }
    }
  }

  final SimProgression mode;
  final SimGrowthTables tables;
  final SimCharacter character;

  /// How the player plays its choices (sim_policy.dart).
  final SimPolicy policy;
  bool get competent => policy == SimPolicy.competent;

  /// Every clan offer taken, in order: the banners offered, the one taken
  /// and why (both policies).
  final List<SimOfferPick> offerPicks = [];

  /// The skills crafted at the Skillwright (competent): result ids.
  final List<String> merged = [];

  /// The game's feature ladder (feature_unlocks.dart): no starting offer,
  /// the offers waiting for the clans, the trainer's skill.
  final bool ladder;

  /// The trainer's lesson (890_trainer): its strike or guard learned.
  void learnTrainerSkill({required bool strike}) {
    final id = trainerSkillFor(
        professionId: character.professionId,
        strike: strike,
        trees: tables.skillTrees,
        skills: tables.skills,
        known: character.unlockedSkillIds);
    if (id != null) _learn(id);
  }

  // The old rules.
  int skillPoints = 0;
  int perkPicks = 0;
  int signPicks = 0;

  // The offers.
  final List<OfferTicket> pending = [];

  /// The places that changed hands at the chapters' turns.
  final List<TerritoryChange> territoryChanges = [];

  /// Every clan that was the character's nemesis at a chapter's turn.
  final Set<String> nemeses = {};
  PoliticsState politics = PoliticsState.storyStart;
  List<String> titles = const [];
  String activeTitle = '';
  final List<String> boons = [];
  int chapterOffersThrough = 0;

  // Both.
  final Map<String, int> perkRanks = {};
  final List<String> patronsThisLife = [];
  final List<String> patronsMet = [];
  final Map<String, int> favour = {};
  final List<String> signsTaken = [];

  /// Gifts taken, by kind (offers), for the telemetry.
  final Map<GiftKind, int> giftsTaken = {};

  /// Risky gifts (risky_gifts.dart): open once the walk built the Parley
  /// Tent; the walk sets [gold] and [chapter] before [settle] and reads
  /// [gold] back (a gold penalty). [riskyOutcomes] counts the risky cards
  /// `seen` and `taken`, and each outcome (`gift`, `health`, `gold`,
  /// `curse`).
  bool riskyGifts = false;
  int gold = 0;
  int chapter = 1;
  final Map<String, int> riskyOutcomes = {};
  final List<RiskCurse> _curses = [];

  /// The risky cards' own draw, so a risky card shifts nothing else in the
  /// offers' draw: seeded from the character and the moment the tent opens
  /// (never from the walk's own stream).
  Random? _riskyRandom;
  Random _riskySeeded() => Random('${character.professionId}${character.raceId}'
          .codeUnits
          .fold<int>(0, (a, b) => a * 31 + b & 0x3fffffff) ^
      (character.level * 7919 + gold));
  int skillsLearned = 0;

  PerkEffects get perks => perkEffectsFor(perkRanks);

  /// The title worn, the bad ones, the boon while sworn.
  List<SignEffect> get clanEffects => clanEffectsFor(
        activeTitleId: activeTitle,
        heldTitleIds: titles,
        swornBoonIds: boons,
        swornFactionId: politics.swornFactionId,
        data: tables.clans,
      );

  /// What the signs, the title and the boon add up to at [alignment]; in
  /// one of the last battles ([host], v1.196) the Host's effects too;
  /// [blessing]: a temple's blessing carried (temple.dart).
  SignEffects effects(int alignment,
      {bool host = false, List<SignEffect> blessing = const []}) {
    final extra = [...clanEffects, if (host) ...hostEffectsNow, ...blessing];
    return tables.signs.isEmpty && extra.isEmpty
        ? SignEffects.none
        : signEffectsFor(character.heldSigns, tables.signs,
            alignment: alignment, extra: extra);
  }

  // --- The climb and the Host (v1.196, see throne.dart) ---------------------

  /// The Host the last battles field now (the one mustered, else the one
  /// the character would muster).
  Host get host => fieldedHost(
      politics: politics, data: tables.clans, signPatrons: patronsThisLife);

  /// What [host] adds to a fight.
  List<SignEffect> get hostEffectsNow => hostEffects(host, tables.clans);

  /// A story choice's or a scene's [story] politics, applied the story's
  /// way (once under [key], see choicePoliticsKey) with [flags] held in
  /// [chapter]: the standing, marks and relations they move, the claim,
  /// the pledges, the Throne and the muster; the titles they bring (the
  /// Throne's worn). Returns the flags after. [cause] is what the standing
  /// log says moved them: `quest:<id>` for a quest's turn-in (v1.463),
  /// which, as in the app, brings a main clan raised [questPowerStanding]
  /// or more its [questPower] and spares it this chapter's neglect.
  List<String> applyStoryPolitics(
    StoryPolitics story, {
    required Iterable<String> flags,
    required int chapter,
    String key = '',
    String cause = 'sim',
    Geography? geography,
  }) {
    return _take(coast.applyStoryPolitics(story,
        cause: cause,
        key: key,
        politics: politics,
        flags: flags.toList(),
        world: _world(chapter, geography)));
  }

  /// [quest] (a quests.json record) turned in with [flags] held in
  /// [chapter], as the app does (wave 18, applyQuestInfluence): its
  /// influence in its district, wherever the walk is, the district or
  /// the town changing hands with it. Returns the flags after.
  List<String> applyQuestInfluence(
    Map<String, dynamic> quest, {
    required Iterable<String> flags,
    required Geography geography,
    required int chapter,
    StoryPolitics? picked,
    String? partyDistrict,
  }) {
    final result = influence.applyQuestInfluence(politics, quest,
        flags: flags.toList(),
        data: tables.clans,
        geography: geography,
        picked: picked,
        partyDistrict: partyDistrict,
        chapter: max(1, chapter));
    politics = result.state;
    return result.flags;
  }

  CoastWorld _world(int chapter, Geography? geography) => CoastWorld(
      data: tables.clans,
      events: tables.events,
      chapter: max(1, chapter),
      signPatrons: patronsThisLife,
      geography: geography);

  /// The politics events due with [flags] held in [chapter] fired, as the
  /// app fires them on a chapter change and a day's tick (runDueEvents,
  /// politics_events.dart): their standing, power and places, flags and
  /// titles. Returns the flags after; [PoliticsState.firedEvents] keeps
  /// which fired, and how.
  List<String> runEvents({
    required Iterable<String> flags,
    required int chapter,
    Geography? geography,
  }) {
    if (tables.events.isEmpty) return flags.toList();
    return _take(runDueEvents(
        politics: politics,
        flags: flags.toList(),
        world: _world(chapter, geography)));
  }

  /// [change] taken: the politics, the titles it gave and those earned
  /// (the Throne's worn); returns the flags after.
  List<String> _take(CoastChange change) {
    politics = change.politics;
    final gained = [
      for (final id in change.titles)
        if (!titles.contains(id)) id,
    ];
    final earned = titlesEarned([...titles, ...gained], politics, tables.clans,
        flags: change.flags);
    titles = earned.held;
    final crowned = [
      for (final id in change.titles)
        if (tables.clans.titles[id]?.source.startsWith('throne:') ?? false) id,
    ];
    activeTitle = crowned.isNotEmpty
        ? crowned.first
        : activeTitleAfter(
            activeTitle, titles, [...gained, ...earned.gained], tables.clans);
    return change.flags;
  }

  /// Whether [choice]'s politics gate lets it be taken with [flags] held
  /// in [chapter] (see choicePoliticsGate: one locked is not taken
  /// either).
  bool gateOpen(StoryChoice choice,
          {required Iterable<String> flags, required int chapter}) =>
      politicsIfHolds(choice.politicsIf,
          politics: politics,
          flags: flags,
          world: CoastWorld(data: tables.clans, chapter: max(1, chapter)));

  /// Levels from [before] to [after] reached.
  void levelsReached(int before, int after) {
    if (after <= before) return;
    if (mode == SimProgression.legacy) {
      skillPoints += after - before;
      perkPicks += perkPicksFor(before, after);
      signPicks += signPicksFor(before, after);
    } else {
      for (var i = before; i < after; i++) {
        pending.add(const OfferTicket(source: OfferSource.level));
        if (passives) _patronGains(i + 1);
      }
      // A clan's curse ends at its level.
      for (final c in [..._curses]) {
        if (after >= c.untilLevel) {
          character.addAbilities({c.stat: c.amount});
          _curses.remove(c);
        }
      }
    }
  }

  /// Whether the patron's passive stats are given (patron_stats.dart);
  /// off, to measure them.
  bool passives = true;

  /// One level's patron gains (patron_stats.dart) on the character.
  void _patronGains(int level) {
    final c = character;
    final gains = patronLevelGains(politics, level: level);
    c.addAbilities(gains.stats);
    c.maxHealth += gains.maxHealth;
    c.currentHealth += gains.maxHealth;
  }

  /// A boss beaten: a sign (legacy), an offer (offers).
  void bossBeaten() {
    if (mode == SimProgression.legacy) {
      signPicks++;
    } else {
      pending.add(const OfferTicket(source: OfferSource.boss));
    }
  }

  /// A new chapter reached: an offer from chapter 2 on, once (offers),
  /// the price of loyalty (applyLoyaltyDrift: the patron's rivals cool)
  /// and, with the world's [geography], the clans' power and places
  /// (territoryTurn, clan_power.dart; what changed hands is kept in
  /// [territoryChanges]).
  void chapterReached(int chapter, {Geography? geography}) {
    if (mode != SimProgression.offers ||
        chapter < 2 ||
        chapter <= chapterOffersThrough) {
      return;
    }
    chapterOffersThrough = chapter;
    politics =
        applyLoyaltyDrift(politics, data: tables.clans, chapter: chapter).state;
    if (geography != null) {
      // As in the app, a change that would take your main clan's seat or
      // last place waits as a crisis (clan_crisis.dart), which the walk
      // then plays ([playCrisis]).
      final turn = territoryTurn(politics,
          data: tables.clans,
          geography: geography,
          chapter: chapter,
          protect: mainClanOf(politics));
      politics = updateNemesis(turn.state, tables.clans, chapter: chapter);
      territoryChanges.addAll(turn.changes);
      if (politics.nemesis.isNotEmpty) nemeses.add(politics.nemesis);
    }
    pending.add(OfferTicket(source: OfferSource.chapter, detail: '$chapter'));
  }

  /// The seat crises played ([playCrisis]): `held` (defended and won),
  /// `lost` (defended and lost, then paid or refused), `paid` and
  /// `refused`.
  final Map<String, int> crisisOutcomes = {};

  /// Your main clan's seat crisis waiting (clan_crisis.dart), played the
  /// simulated player's way with the app's own scene ([buildCrisisNode])
  /// and its choices' politics: defend when the character is healthy
  /// (more than half its health, as [preferredSuitor] reads it) and
  /// [defend] (the walk's fight against the attacker's hunter) is won;
  /// else, or when it is lost, pay when [gold] holds the price; else
  /// refuse. Returns the gold and flags after, and how it settled ('' for
  /// no crisis).
  ({int gold, List<String> flags, String how}) playCrisis({
    required Geography geography,
    required Map<String, dynamic> enemies,
    required int chapter,
    required int gold,
    required Iterable<String> flags,
    required Random random,
    required bool Function(String enemyId) defend,
  }) {
    final node = buildCrisisNode(politics,
        data: tables.clans,
        geography: geography,
        enemies: enemies,
        chapter: chapter,
        gold: gold,
        random: random);
    if (node == null) {
      return (gold: gold, flags: flags.toList(), how: '');
    }
    StoryChoice? settling(String how) => node.choices
        .where((c) => c.politics?.settleCrisis == how && c.goldMod <= 0)
        .where((c) => c.grantMaterials.isEmpty)
        .firstOrNull;
    final held = settling('held');
    final healthy = character.currentHealth * 2 > character.maxHealth;
    var choice = held != null && healthy && defend(held.triggerEnemyId ?? '')
        ? held
        : null;
    if (held != null && healthy && choice == null) _crisis('lost');
    choice ??= settling('paid') ?? settling('refused');
    final how = choice?.politics?.settleCrisis ?? '';
    if (choice == null) return (gold: gold, flags: flags.toList(), how: '');
    _crisis(how);
    final after = applyStoryPolitics(choice.politics!,
        flags: flags, chapter: chapter, cause: 'crisis', geography: geography);
    return (gold: gold + choice.goldMod, flags: after, how: how);
  }

  /// The districts' sieges played ([playSieges]): `defended` (held for its
  /// holder), `defence_lost` (defended, the fight lost, then settled),
  /// `taken` (the attacker took it) and `held` (the holder kept it alone).
  final Map<String, int> siegeOutcomes = {};

  /// A chapter's attacks on districts (district_attacks.dart), rolled and
  /// played at once the simulated player's way: when the holder is the
  /// character's main clan or its ally (relation step [maxRelationStep], Allies) and the
  /// character is healthy, it holds the district with the app's own scene
  /// ([buildSiegeNode]) and [defend] (the walk's fight against the
  /// attacker's hunter); otherwise, or when that fight is lost, the siege
  /// is settled away ([settleSiegeAway]). Returns the flags after.
  List<String> playSieges({
    required Geography geography,
    required Map<String, dynamic> enemies,
    required int chapter,
    required Iterable<String> flags,
    required Random random,
    required bool Function(String enemyId) defend,
  }) {
    var after = flags.toList();
    final rolled = rollDistrictAttacks(politics,
        data: tables.clans,
        geography: geography,
        day: 0,
        chapter: chapter,
        random: random);
    politics = rolled.state;
    final main = mainClanOf(politics);
    for (final siege in rolled.begun) {
      final step = main.isEmpty
          ? null
          : politics.relationStep(main, siege.holder, tables.clans);
      final ours =
          siege.holder == main || (step != null && step >= maxRelationStep);
      final healthy = character.currentHealth * 2 > character.maxHealth;
      if (ours && healthy) {
        final node = buildSiegeNode(politics, siege,
            data: tables.clans,
            geography: geography,
            enemies: enemies,
            chapter: chapter,
            random: random);
        final hold =
            node?.choices.where((c) => c.triggerEnemyId != null).firstOrNull;
        if (hold != null && defend(hold.triggerEnemyId!)) {
          after = applyStoryPolitics(hold.politics!,
              flags: after,
              chapter: chapter,
              cause: 'siege',
              geography: geography);
          _siege('defended');
          continue;
        }
        if (hold != null) _siege('defence_lost');
      }
      politics = settleSiegeAway(politics, siege,
          data: tables.clans,
          geography: geography,
          random: random,
          chapter: chapter,
          changes: territoryChanges);
      _siege(holderOf(siege.districtId, geography, politics) == siege.attacker
          ? 'taken'
          : 'held');
    }
    return after;
  }

  void _siege(String key) => siegeOutcomes[key] = (siegeOutcomes[key] ?? 0) + 1;

  /// Spends whatever waits, the simulator's way; returns the alignment
  /// after (vows, pacts and the clans' leans move it).
  int settle({
    required int alignment,
    required Iterable<String> flags,
    required Random random,
  }) {
    var next = alignment;
    if (mode == SimProgression.legacy) {
      _spendSkillPoints(next);
      while (perkPicks > 0) {
        perkPicks--;
        final offer = rollPerkOffer(perkRanks, random);
        if (offer.isEmpty) break;
        final perk = _simPerkPreference.firstWhere(offer.contains);
        _takePerk(perk);
      }
      next = _takeSigns(next, flags, random);
    } else {
      next = _takeOffers(next, flags, random);
    }
    return next;
  }

  // --- Skills and the die ---------------------------------------------------

  /// The die's open Skill faces: a Skill face with no skill of its own (or
  /// the basic strike), where a learned skill can go.
  List<int> get _openSkillFaces => [
        for (var i = 0; i < character.diceFaces.length; i++)
          if (isOpenSkillFace(character.diceFaces[i])) i,
      ];

  /// Whether [skillId], learned now, would go on an empty face of the die.
  bool fillsEmptyFace(String skillId) {
    if (character.unlockedSkillIds.contains(skillId)) return false;
    final open = _openSkillFaces;
    final used = open
        .where((i) => character.diceSkillAssignments.containsKey('$i'))
        .length;
    return used < open.length;
  }

  /// Every learned skill to the die's open Skill faces, the best on them:
  /// the mana skill keeps its face, the rest go by [simSkillScore].
  void assignSkills() {
    character.diceSkillAssignments = simSkillAssignments(
      faces: character.diceFaces,
      current: character.diceSkillAssignments,
      unlocked: character.unlockedSkillIds,
      skills: tables.skills,
    );
  }

  void _learn(String skillId) {
    if (character.unlockedSkillIds.add(skillId)) skillsLearned++;
    assignSkills();
  }

  /// The old rules: each point spent on the best next skill the points
  /// cover, one that fills an empty face first.
  void _spendSkillPoints(int alignment) {
    final branches = skillBranchesFor(tables.skillTrees,
        raceId: character.raceId, professionId: character.professionId);
    while (skillPoints > 0) {
      final known = {
        ...character.unlockedSkillIds,
        for (final e in tables.skills.entries)
          if (e.value is Map && (e.value as Map)['isUnlocked'] == true) e.key,
      };
      String? best;
      var bestScore = double.negativeInfinity;
      for (final branch in branches) {
        for (var i = 0; i < branch.skillIds.length; i++) {
          final id = branch.skillIds[i];
          if (!canLearnWithPoints(id,
              branches: branches,
              known: known,
              skills: tables.skills,
              alignmentScore: alignment)) {
            continue;
          }
          final cost = skillPointCostOf(id, branches);
          if (cost > skillPoints) continue;
          final score = (fillsEmptyFace(id) ? 1000 : 0) +
              simSkillScore(tables.skills[id] as Map<String, dynamic>?) / cost;
          if (score > bestScore) {
            best = id;
            bestScore = score;
          }
        }
      }
      if (best == null) return;
      skillPoints -= skillPointCostOf(best, branches);
      _learn(best);
    }
  }

  void _takePerk(Perk perk) {
    final rank = perkRanks[perk.name] ?? 0;
    if (rank >= perkInfo[perk]!.maxRank) return;
    perkRanks[perk.name] = rank + 1;
    if (perk == Perk.vigor) {
      character.maxHealth += vigorHealthPerRank;
      character.currentHealth += vigorHealthPerRank;
    }
  }

  // --- Signs (the old rules) ------------------------------------------------

  int _takeSigns(int alignment, Iterable<String> flags, Random random) {
    var next = alignment;
    if (tables.signs.isEmpty) {
      signPicks = 0;
      return next;
    }
    while (signPicks > 0) {
      final offer = rollSignOffer(
        patrons: tables.patrons,
        signs: tables.signs,
        held: character.heldSigns,
        flags: flags,
        alignment: next,
        random: random,
        patronsThisLife: patronsThisLife,
        patronsMet: patronsMet,
        luck: character.luck + effects(next).stat('luck'),
      );
      final card = offer == null
          ? null
          : preferredSignCard(offer, character.heldSigns, tables.signs);
      final sign = card == null ? null : tables.signs[card.signId];
      if (offer == null || card == null || sign == null) return next;
      character.heldSigns =
          takeSign(character.heldSigns, sign, card.rarity, tables.signs).held;
      next += alignmentShiftFor(sign);
      for (final id in {offer.patronId, sign.patronId}) {
        if (!patronsThisLife.contains(id)) patronsThisLife.add(id);
      }
      if (!patronsMet.contains(offer.patronId)) patronsMet.add(offer.patronId);
      signsTaken.add(sign.id);
      signPicks--;
    }
    return next;
  }

  // --- Offers ---------------------------------------------------------------

  OfferContext _context(int alignment, Iterable<String> flags) => OfferContext(
        data: tables.clans,
        politics: politics,
        signs: tables.signs,
        heldSigns: character.heldSigns,
        skills: tables.skills,
        skillTrees: tables.skillTrees,
        items: tables.items,
        spells: tables.spells,
        raceId: character.raceId,
        professionId: character.professionId,
        knownSkillIds: {
          ...character.unlockedSkillIds,
          for (final e in tables.skills.entries)
            if (e.value is Map && (e.value as Map)['isUnlocked'] == true) e.key,
        },
        ownedItemIds: competent
            ? {...character.equippedItemIds, ...character.ownedItemIds}.toList()
            : character.equippedItemIds,
        knownSpellIds: [for (final s in character.knownSpells) s.id],
        flags: flags,
        alignment: alignment,
        patronsThisLife: patronsThisLife,
        favour: favour,
        patronsMet: patronsMet,
        heldTitleIds: titles,
        swornBoonIds: boons,
        perkRanks: perkRanks,
        luck: character.luck + effects(alignment).stat('luck'),
        specs: tables.specs,
        heldSpecIds: character.specIds,
        specVariants: tables.specVariants,
        riskyGifts: riskyGifts,
        dice: tables.dice,
        ownedDiceIds: character.ownedDice.keys.toList(),
      );

  /// Whether the first banner came (see [_takeOffers]).
  bool _firstBanner = false;

  int _takeOffers(int alignment, Iterable<String> flags, Random random) {
    var next = alignment;
    // On the ladder the offers wait for the clans (or the third chapter).
    if (ladder &&
        !featureUnlocked(GameFeature.clans, (
          flags: {...flags, featureLadderFlag},
          level: character.level,
          chapter: chapterOffersThrough,
        ))) {
      return next;
    }
    // The clans just met: the offers earned before them did not pile up,
    // one comes, the first banner (the game's rule, v1.634:
    // offersWaitForClans).
    if (ladder && !_firstBanner) {
      _firstBanner = true;
      final first = pending.isEmpty
          ? const OfferTicket(source: OfferSource.level, detail: 'first')
          : pending.first;
      pending
        ..clear()
        ..add(first);
    }
    while (pending.isNotEmpty) {
      final ticket = pending.first;
      final context = _context(next, flags);
      var offer = drawOffer(ticket, context, random,
          riskyRandom: riskyGifts ? _riskyRandom ??= _riskySeeded() : null);
      if (offer == null) return next;
      final favourBest = random.nextDouble() < _simFavourBestChance;
      // Keeping to the patron and its allies (a card of another clan only
      // for an empty die face), as a player who backs a clan would.
      final main = mainClanOf(politics);
      final keepTo = main.isEmpty
          ? null
          : {main, ...alliesOf(main, politics, tables.clans)};
      // Why the banner taken was taken, for the run's report.
      var why = '';
      Suitor? choose(ClanOffer o) {
        if (competent) {
          final pick = competentSuitor(o, ticket);
          why = pick.reason;
          return pick.suitor;
        }
        why = favourBest
            ? 'favour-best'
            : keepTo == null
                ? 'best gift'
                : 'best gift, kept to $main and allies';
        return preferredSuitor(
          o,
          fillsEmptyFace: fillsEmptyFace,
          heldSigns: character.heldSigns,
          signs: tables.signs,
          favourBest: favourBest,
          politics: politics,
          data: tables.clans,
          healthy: character.currentHealth * 2 > character.maxHealth,
          keepTo: keepTo,
        );
      }

      var chosen = choose(offer);
      // The camp's roll houses (sim_rolls.dart), on their own draw.
      final rolls = character.rolls;
      if (rolls != null) {
        rolls.freshDraw(RollBanOn.offer);
        if (rolls.built.isNotEmpty) {
          final worked = rolls.workOffer(offer,
              context: context,
              choose: choose,
              fills: fillsEmptyFace,
              redraw: () => drawOffer(ticket, context, rolls.random));
          offer = worked.offer;
          chosen = worked.suitor;
        }
      }
      final suitor = chosen;
      if (suitor == null) return next;
      pending.removeAt(0);
      offerPicks.add(SimOfferPick(
        chapter: chapter,
        source: ticket.detail.isEmpty
            ? ticket.source.name
            : '${ticket.source.name}:${ticket.detail}',
        offered: [for (final s in offer.suitors) _label(s)],
        taken: _label(suitor),
        reason: why,
      ));
      for (final s in offer.suitors) {
        if (!patronsMet.contains(s.factionId)) patronsMet.add(s.factionId);
      }
      if (offer.suitors.any((s) => s.risky)) _count('seen');
      if (suitor.risky) {
        _count('taken');
        final risk = riskyResultFor(
          roll: suitor.riskRoll,
          luck: character.luck + effects(next).stat('luck'),
          gold: gold,
          chapter: chapter,
          maxHealth: character.maxHealth,
          currentHealth: character.currentHealth,
          curseStat: riskyCurseStatFor(
              tables.clans.faction(suitor.factionId), character.professionId),
        );
        _count(risk.outcome.name);
        switch (risk.outcome) {
          case RiskyOutcome.gift:
            next = _applyGift(suitor, next);
          case RiskyOutcome.health:
            character.currentHealth =
                max(1, character.currentHealth - risk.amount);
          case RiskyOutcome.gold:
            gold = max(0, gold - risk.amount);
          case RiskyOutcome.curse:
            final old =
                _curses.where((c) => c.clan == suitor.factionId).firstOrNull;
            if (old != null) {
              character.addAbilities({old.stat: old.amount});
              _curses.remove(old);
            }
            character.addAbilities({risk.stat: -risk.amount});
            _curses.add(RiskCurse(
                clan: suitor.factionId,
                stat: risk.stat,
                amount: risk.amount,
                untilLevel: character.level + riskyCurseLevels));
        }
      } else {
        next = _applyGift(suitor, next);
      }
      final taken = acceptPolitics(suitor, ticket,
          politics: politics, data: tables.clans);
      politics = taken.politics;
      next += taken.alignment;
      final earned = titlesEarned(titles, politics, tables.clans);
      titles = earned.held;
      activeTitle =
          activeTitleAfter(activeTitle, titles, earned.gained, tables.clans);
      giftsTaken[suitor.gift.kind] = (giftsTaken[suitor.gift.kind] ?? 0) + 1;
    }
    return next;
  }

  static String _label(Suitor s) =>
      '${s.factionId}:${s.gift.kind.name}:${s.gift.id}';

  // --- The competent player (sim_policy.dart) -------------------------------

  /// The die's worth (simDieValue) with [unlocked] known, best placed.
  double _dieValueWith(Iterable<String> unlocked) {
    final c = character;
    return simDieValue(
        c.diceFaces,
        simSkillAssignments(
            faces: c.diceFaces,
            current: c.diceSkillAssignments,
            unlocked: unlocked,
            skills: tables.skills),
        tables.skills,
        damage: c.baseDamage,
        caster: c.knownSpells.isNotEmpty);
  }

  bool _canWear(Map<String, dynamic> item) => meetsItemStatRequirement(item,
      strength: character.strength,
      dexterity: character.dexterity,
      constitution: character.constitution,
      intelligence: character.intelligence);

  /// The best loadout's worth (simLoadoutValue) with [extra] owned too.
  double _bestGearValue([Iterable<String> extra = const []]) {
    final c = character;
    final best = simBestLoadout(
        worn: c.equippedBySlot,
        owned: {...c.ownedItemIds, ...extra},
        items: tables.items,
        sets: tables.itemSets,
        canWear: _canWear,
        caster: c.knownSpells.isNotEmpty);
    return simLoadoutValue(best.values, tables.items, tables.itemSets,
        caster: c.knownSpells.isNotEmpty);
  }

  /// What [gift] adds to the build's power, the competent player's
  /// measure (about ten to a point of damage on every roll): a skill by
  /// what it adds to the die, gear by what it adds to the best loadout,
  /// potions and a spellbook by what they heal or teach, a
  /// specialisation, a sign, a boon, a perk and a title by fixed worths
  /// (a sign more for an empty slot, little for a slot holding as good).
  double giftPower(OfferGift gift) {
    final c = character;
    switch (gift.kind) {
      case GiftKind.skill:
        if (tables.skills[gift.id] is! Map<String, dynamic>) return 0;
        return (_dieValueWith({...c.unlockedSkillIds, gift.id}) -
                    _dieValueWith(c.unlockedSkillIds)) *
                10 +
            1;
      case GiftKind.object:
        final item = tables.items[gift.id] as Map<String, dynamic>?;
        if (item == null) return 0;
        if (item['itemType']?.toString() == 'Potion') {
          return gift.id == 'antidote'
              ? 0
              : (gift.id == 'potion_major' ? 6 : 3);
        }
        final spellId = spellbookSpellIdFor(item);
        if (spellId != null) {
          final spell = tables.spells[spellId];
          return spell != null &&
                  canLearnSpell(spell,
                      professionId: c.professionId,
                      knownSpellIds: [for (final s in c.knownSpells) s.id])
              ? 15
              : 0;
        }
        if (item['isEquippable'] != true) return 1;
        return (_bestGearValue([gift.id]) - _bestGearValue()) * 7;
      case GiftKind.spec:
        return 25;
      case GiftKind.die:
        // What the die adds over the one rolled now, Resonance and all.
        final die = tables.dice[gift.id] as Map<String, dynamic>?;
        final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>();
        if (faces == null || faces.isEmpty) return 0;
        final rolled =
            resonanceOf(die, politics: politics, data: tables.clans) ==
                    Resonance.lit
                ? resonantFaces(faces)
                : faces;
        final caster = c.knownSpells.isNotEmpty;
        final now = simDieValue(
            c.diceFaces, c.diceSkillAssignments, tables.skills,
            damage: c.baseDamage, caster: caster);
        final worth = simDieValue(
            rolled,
            simSkillAssignments(
                faces: rolled,
                current: const {},
                unlocked: c.unlockedSkillIds,
                skills: tables.skills),
            tables.skills,
            damage: c.baseDamage,
            caster: caster);
        return max(1.0, (worth - now) * 10);
      case GiftKind.sign:
        final sign = tables.signs[gift.id];
        if (sign == null) return 0;
        final held = heldInSlot(sign.slot, c.heldSigns, tables.signs);
        var worth = 4.0 + gift.rarity.index * 6;
        if (held == null) {
          worth += 5;
        } else if (held.rarity.index >= gift.rarity.index) {
          worth -= 6;
        }
        return max(0.5, worth);
      case GiftKind.sworn:
        return 20.0 + gift.rarity.index * 4;
      case GiftKind.perk:
        final perk = perkFromName(gift.id);
        if (perk == null) return 0;
        if ((perkRanks[perk.name] ?? 0) >= perkInfo[perk]!.maxRank) return 0;
        final rank = _simPerkPreference.indexOf(perk);
        return 2.0 + (rank < 0 ? 0 : _simPerkPreference.length - rank);
      case GiftKind.title:
        return 3.0 + gift.rarity.index * 3;
    }
  }

  /// The competent banner (sim_policy.dart's rule): never one whose
  /// standing would turn a clan the character needs (its main clan or an
  /// ally) Hostile; of the rest the gift that raises its power most
  /// ([giftPower]; a risky card at 60%, none at half health or less), a
  /// tie (within a point) to the clan it stands closest to. Every offer is
  /// taken: when every banner would hurt, the best of them all.
  ({Suitor? suitor, String reason}) competentSuitor(
      ClanOffer offer, OfferTicket ticket) {
    if (offer.suitors.isEmpty) return (suitor: null, reason: '');
    final data = tables.clans;
    final main = mainClanOf(politics);
    final needed =
        main.isEmpty ? <String>{} : {main, ...alliesOf(main, politics, data)};
    String? turnsHostile(Suitor s) {
      if (needed.isEmpty || s.isWayfarer) return null;
      final after =
          acceptPolitics(s, ticket, politics: politics, data: data).politics;
      for (final id in needed.toList()..sort()) {
        if (politics.tierOf(id, data).isAtLeast(StandingTier.resented) &&
            !after.tierOf(id, data).isAtLeast(StandingTier.resented)) {
          return id;
        }
      }
      return null;
    }

    final skipped = <String>[];
    final safe = <Suitor>[];
    for (final s in offer.suitors) {
      final hurt = turnsHostile(s);
      if (hurt == null) {
        safe.add(s);
      } else {
        skipped.add('${s.factionId} would turn $hurt Hostile');
      }
    }
    var pool = safe.isEmpty ? offer.suitors : safe;
    final healthy = character.currentHealth * 2 > character.maxHealth;
    if (!healthy && pool.any((s) => !s.risky)) {
      pool = [
        for (final s in pool)
          if (!s.risky) s
      ];
    }
    double power(Suitor s) => giftPower(s.gift) * (s.risky ? 0.6 : 1);
    double standing(Suitor s) =>
        s.isWayfarer || (data.faction(s.factionId)?.isLost ?? true)
            ? double.negativeInfinity
            : politics.standingOf(s.factionId, data);
    final powers = [for (final s in pool) power(s)];
    final top = powers.reduce(max);
    final tied = [
      for (var i = 0; i < pool.length; i++)
        if (powers[i] >= top - 1) pool[i],
    ];
    final pick = tied.reduce((a, b) => standing(b) > standing(a) ? b : a);
    final parts = [
      tied.length == 1
          ? 'most power +${top.toStringAsFixed(1)}'
          : 'tie at +${top.toStringAsFixed(1)}, closest clan',
      if (skipped.isNotEmpty) 'skipped ${skipped.join(', ')}',
      if (safe.isEmpty) 'every banner hurt a needed clan',
    ];
    return (suitor: pick, reason: parts.join('; '));
  }

  /// The competent player's gear: the best loadout (simBestLoadout) out of
  /// what it owns, [extra] (the pack: loot, rewards, what a scene gave)
  /// counted as owned.
  void equipBest({Iterable<String> extra = const []}) {
    final c = character;
    for (final id in extra) {
      final item = tables.items[id];
      if (item is Map<String, dynamic> && item['isEquippable'] == true) {
        c.ownedItemIds.add(id);
      }
    }
    final best = simBestLoadout(
        worn: c.equippedBySlot,
        owned: c.ownedItemIds,
        items: tables.items,
        sets: tables.itemSets,
        canWear: _canWear,
        caster: c.knownSpells.isNotEmpty);
    c.equippedBySlot
      ..clear()
      ..addAll(best);
  }

  /// The competent player before a fight: the best gear it owns (with
  /// [inventory], the pack); at the Skillwright ([skillwright]) every
  /// skill merge worth crafting (simMergeWorthIt); then the best die it
  /// owns (the dice it has bought and its own) with its skills best
  /// placed. Nothing for the naive player.
  void prepareForFight({
    Iterable<String> inventory = const [],
    bool skillwright = false,
  }) {
    if (!competent) return;
    final c = character;
    equipBest(extra: inventory);
    if (skillwright && tables.merges.isNotEmpty) {
      while (true) {
        final merge = simMergeWorthIt(
            merges: tables.merges,
            unlocked: c.unlockedSkillIds,
            faces: c.diceFaces,
            current: c.diceSkillAssignments,
            skills: tables.skills,
            damage: c.baseDamage,
            caster: c.knownSpells.isNotEmpty);
        if (merge == null) break;
        c.unlockedSkillIds
          ..removeAll(merge.inputs)
          ..add(merge.result);
        merged.add(merge.result);
        assignSkills();
      }
    }
    c.rollBestDie(tables.skills);
    assignSkills();
  }

  void _crisis(String key) =>
      crisisOutcomes[key] = (crisisOutcomes[key] ?? 0) + 1;

  void _count(String key) => riskyOutcomes[key] = (riskyOutcomes[key] ?? 0) + 1;

  int _applyGift(Suitor suitor, int alignment) {
    final gift = suitor.gift;
    switch (gift.kind) {
      case GiftKind.skill:
        _learn(gift.id);
      case GiftKind.sign:
        final sign = tables.signs[gift.id];
        if (sign == null) return alignment;
        character.heldSigns =
            takeSign(character.heldSigns, sign, gift.rarity, tables.signs).held;
        favour[suitor.factionId] = (favour[suitor.factionId] ?? 0) + 1;
        for (final id in {suitor.factionId, sign.patronId}) {
          if (!patronsThisLife.contains(id)) patronsThisLife.add(id);
        }
        signsTaken.add(sign.id);
        return alignment + alignmentShiftFor(sign);
      case GiftKind.object:
        _takeItem(gift.id);
      case GiftKind.title:
        if (!titles.contains(gift.id)) titles = [...titles, gift.id];
        if (activeTitle.isEmpty) activeTitle = gift.id;
      case GiftKind.sworn:
        if (!boons.contains(gift.id)) boons.add(gift.id);
      case GiftKind.perk:
        final perk = perkFromName(gift.id);
        if (perk != null) _takePerk(perk);
      case GiftKind.spec:
        if (!character.specIds.contains(gift.id)) {
          character.specIds = [...character.specIds, gift.id];
        }
      case GiftKind.die:
        // A clan's die to the bag; the competent player rolls it when it
        // beats the one in play.
        final faces = ((tables.dice[gift.id] as Map?)?['faces'] as List?)
            ?.cast<Map<String, dynamic>>();
        if (faces != null && !character.ownedDice.containsKey(gift.id)) {
          character.ownedDice[gift.id] = faces;
          if (competent) character.rollBestDie(tables.skills);
        }
    }
    return alignment;
  }

  /// An object given: potions as charges, a spellbook read, gear worn when
  /// it beats what is in its slot.
  void _takeItem(String itemId) {
    final item = tables.items[itemId] as Map<String, dynamic>?;
    if (item == null) return;
    final c = character;
    switch (item['itemType']?.toString()) {
      case 'Potion':
        if (itemId != 'antidote') c.potions += itemId == 'potion_major' ? 2 : 1;
        return;
      case 'Scroll':
        return;
    }
    final spellId = spellbookSpellIdFor(item);
    if (spellId != null) {
      final spell = tables.spells[spellId];
      if (spell != null &&
          canLearnSpell(spell,
              professionId: c.professionId,
              knownSpellIds: [for (final s in c.knownSpells) s.id])) {
        c.knownSpells.add(spell);
      }
      return;
    }
    if (item['isEquippable'] != true) return;
    final slot = item['equipSlot']?.toString() ?? '';
    if (slot.isEmpty) return;
    // The stubborn player keeps its starting gear.
    if (policy == SimPolicy.stubborn) return;
    if (competent) {
      c.ownedItemIds.add(itemId);
      equipBest();
      return;
    }
    int score(String? id) {
      final record = tables.items[id] as Map<String, dynamic>?;
      if (record == null) return -1;
      return ((record['attackDamage'] as num?)?.toInt() ?? 0) +
          ((record['armor'] as num?)?.toInt() ?? 0);
    }

    if (score(itemId) > score(c.equippedBySlot[slot])) {
      c.equippedBySlot[slot] = itemId;
    }
  }
}
