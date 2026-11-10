import 'dart:math';

import 'ability_check.dart' show checkBonusFor;

import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../combat/dice_tamper.dart';
import '../combat/doctrine.dart';
import '../combat/context_rules.dart';
import '../combat/element_reaction.dart';
import '../combat/face_element.dart';
import '../combat/foe_kind.dart';
import '../combat/enemy_response.dart';
import '../combat/fight_goal.dart';
import '../combat/fight_length.dart';
import '../combat/profession_cores.dart';
import '../combat/spec_variants.dart';
import '../combat/specialisations.dart';
import '../combat/parry.dart';
import 'character_start.dart';
import '../combat/squad.dart';
import '../combat/fight_numbers.dart';
import '../combat/gear_effects.dart';
import '../combat/heal_rules.dart';
import '../combat/heal_target.dart';
import '../combat/strike_damage.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../models/ally_state.dart';
import 'perks.dart';
import 'shop_stock.dart';
import 'camp_rolls.dart' show RollBanOn;
import 'signs.dart';
import 'sim_companions.dart';
import 'sim_policy.dart';
import 'sim_rolls.dart';
import 'training.dart';

part 'sim_combat/sim_enemy.dart';
part 'sim_combat/sim_fight.dart';
part 'sim_combat/sim_fight_end.dart';
part 'sim_combat/sim_fight_enemy_turn.dart';
part 'sim_combat/sim_fight_party_turn.dart';
part 'sim_combat/sim_fight_setup.dart';
part 'sim_combat/sim_spell_cast.dart';

/// A fight model for the in-app playthrough simulator: one simulated
/// character (a random race and profession, created the way `startNewGame`
/// creates a real one) who fights every combat choice the graph walk takes
/// with the same engine a live fight uses -- `rollDie`, `resolvePlayerFace`,
/// `resolveEnemyMove`, the status effects, the chapter curve, pack
/// multipliers, the mana pool, its Mana faces and the spells the
/// profession starts with or buys, and a Mirror sending back the round's
/// best hit. Deliberate simplifications, so the numbers read as "a solo
/// player of this build" rather than a full party:
/// - companions only for the competent player ([allies], see
///   sim_companions.dart): their signature dice, approval and knock-outs,
///   but no party combos or duo techniques (nor the dexterity order, Quick
///   Resolve, momentum's surge or the hunt-the-healer retarget);
/// - of the clash rules (v1.212-v1.215) the goals (hold, rout, subdue), the
///   Writ, squad roles, the enemies' answers (counter, press), parries and
///   element reactions are played when `clash` is on; the thieves' purse,
///   the hunt-the-healer retarget and the doctrines' affixes are not;
/// - no affixes, Elites or battlefield conditions;
/// - no chapter threat on the enemies, and no sellsword;
/// - of the face keywords only the strike ones a sign may lend (Cleave,
///   Pierce, Pain, Steady), with the enemies' Hex, Silence and Curse on
///   the die as the fight screen lays them; no Luck nudges and no
///   Hammersmith work on the die;
/// - of the signs (see signs.dart), everything but momentum and the
///   party's share (there is no party); no Titan's Blood; of the clans'
///   Sworn boons (v1.194) the Writ, the Compact edge, the Crow's Price and
///   the longer poisons (no Curse and no telegraph to read here);
/// - of the perks (see perks.dart), what lays over the gear, Vigor's
///   health, the potions' and the mana's (no rerolls, momentum or party);
/// - no crit/momentum beyond what the engine rolls, and a die rerolled
///   only on an empty face;
/// - a shop visited once when the story unlocks it (best affordable gear
///   per slot, two potions, the profession's own spellbook, the sage die
///   for a caster).
///
/// A lost fight refills health and mana like the app's own loss handling;
/// a new chapter counts as a rest.
/// How each profession's simulated build shares its picks (ability ->
/// share of the points): mostly the damage stat, some Constitution, and
/// what else the profession leans on (stat_rules.dart).
const Map<String, Map<String, double>> simBuildShares = {
  'warrior': {'strength': .6, 'constitution': .3, 'perception': .1},
  'rogue': {'dexterity': .6, 'perception': .1, 'luck': .1, 'constitution': .2},
  'ranger': {'dexterity': .6, 'perception': .15, 'constitution': .25},
  'mage': {'intelligence': .6, 'wisdom': .2, 'constitution': .2},
  'cleric': {'intelligence': .5, 'wisdom': .3, 'constitution': .2},
};

class SimCharacter {
  SimCharacter._({
    required this.raceId,
    required this.professionId,
    required this.preferredStat,
    required this.maxHealth,
    required this.baseDamage,
    required this.baseArmor,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.luck,
    required this.charisma,
    required this.perception,
    required this.diceFaces,
    required this.diceSkillAssignments,
    required this.unlockedSkillIds,
    required this.knownSpells,
    required this.potions,
    required this.startingGold,
  })  : currentHealth = maxHealth,
        mana = maxManaFor(wisdom: wisdom);

  /// Mirrors `PlayerSessionNotifier.startNewGame`: New Game Defaults plus
  /// the race's and profession's bonuses, the profession's starting die
  /// (or the starter die) with the Technique faces wired on, the two
  /// signature skills unlocked, the starting spells known, a full pool.
  factory SimCharacter.create({
    required String raceId,
    required Map<String, dynamic> race,
    required String professionId,
    required Map<String, dynamic> profession,
    required Map<String, dynamic> gameConfig,
    required Map<String, dynamic> dice,
    required Map<String, SpellSpec> spells,
  }) {
    // The game's own new-game rules (character_start.dart).
    final totals = newCharacterTotals(gameConfig, race, profession);
    final dieId = startingDiceIdFor(profession);
    final faces = ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final startingSpells = <SpellSpec>[
      for (final id in startingSpellIdsFor(profession))
        if (spells[id] != null) spells[id]!,
    ];
    final preferred = damageStatOf(professionId);
    final character = SimCharacter._(
      raceId: raceId,
      professionId: professionId,
      preferredStat: preferred.isEmpty ? 'wisdom' : preferred,
      maxHealth: max(1, totals.maxHealth),
      baseDamage: totals.baseDamage,
      baseArmor: totals.baseArmor,
      strength: totals.strength,
      dexterity: totals.dexterity,
      constitution: totals.constitution,
      intelligence: totals.intelligence,
      wisdom: totals.wisdom,
      luck: totals.luck,
      charisma: totals.charisma,
      perception: totals.perception,
      diceFaces: faces,
      // The same starting kit as PlayerSessionNotifier.startNewGame: a
      // caster's mana skill sits on the apprentice die's Channeling face.
      diceSkillAssignments: starterFaceAssignments(race, profession),
      unlockedSkillIds: starterSkillsFor(race, profession).toSet(),
      knownSpells: startingSpells,
      potions: (gameConfig['potionCount'] as num?)?.toInt() ?? 0,
      startingGold: totals.gold,
    );
    return character
      ..diceId = dieId
      ..ownedDice[dieId] = faces;
  }

  final String raceId;
  final String professionId;

  /// The ability score each level-up's assumed stat spend goes to -- the
  /// profession's damage stat (stat_rules.dart), or Wisdom for none.
  final String preferredStat;

  int level = 1;
  int xp = 0;
  int maxHealth;
  int currentHealth;
  int baseDamage;
  int baseArmor;
  int strength;
  int dexterity;
  int constitution;
  int intelligence;
  int wisdom;
  int luck;
  int charisma;
  int perception;

  /// The bonus on a d20 for an ability check (see ability_check.dart's
  /// checkBonusFor) from the score. Equipment and level-up points are not
  /// counted.
  int abilityBonus(String ability) => checkBonusFor(abilityScore(ability));

  /// The character's score in [ability].
  int abilityScore(String ability) => switch (ability) {
        'strength' => strength,
        'dexterity' => dexterity,
        'constitution' => constitution,
        'intelligence' => intelligence,
        'wisdom' => wisdom,
        'charisma' => charisma,
        'luck' => luck,
        'perception' => perception,
        _ => 0,
      };

  /// The faces of the die in play -- the starting die, or the sage die
  /// once a caster buys one.
  List<Map<String, dynamic>> diceFaces;

  /// faceIndex -> skill id, for the die's Technique faces (see
  /// `PlayerSession.diceSkillAssignments`). Emptied when the die changes.
  Map<String, String> diceSkillAssignments;
  final Set<String> unlockedSkillIds;
  final List<SpellSpec> knownSpells;

  int potions;
  int mana;

  /// The gold a real new character starts with -- the graph walk adds it
  /// to its own purse when the character is created.
  final int startingGold;

  /// equipSlot -> item id.
  final Map<String, String> equippedBySlot = {};

  /// How the player plays its choices (sim_policy.dart): the competent
  /// one keeps what it owns ([ownedItemIds], [ownedDice]) and wears and
  /// rolls the best of it.
  SimPolicy policy = SimPolicy.naive;

  /// The gear the competent player owns, worn or in the pack.
  final Set<String> ownedItemIds = {};

  /// The die in play's id, and the dice owned (id -> faces): the
  /// profession's own (its signature die) from the start, and those the
  /// competent player buys.
  String diceId = '';
  final Map<String, List<Map<String, dynamic>>> ownedDice = {};

  /// The competent player's trial of a die before switching to it (the
  /// walk's, playthrough_simulator_screen.dart): true when [faces], its
  /// skills at [assignments], fought measurably better than the die in
  /// play. Null, the worth (simDieValue) alone decides.
  bool Function(
          List<Map<String, dynamic>> faces, Map<String, String> assignments)?
      dieTrial;

  /// Whether die [id], worth more than the one in play (simDieValue), also
  /// passes its [dieTrial]: the worth leaves out the profession's core, the
  /// elements and the specialisations, and so overrates some dice. A die
  /// that failed is not tried again before the next level.
  bool _passesTrial(String id, List<Map<String, dynamic>> faces,
      Map<String, String> assignments) {
    final trial = dieTrial;
    if (trial == null) return true;
    if (_dieFailedAt[id] == level) return false;
    final passed = trial(faces, assignments);
    if (!passed) _dieFailedAt[id] = level;
    return passed;
  }

  /// The level each die last failed its trial at.
  final Map<String, int> _dieFailedAt = {};

  /// The best die owned for the competent player (simDieValue, its skills
  /// best placed by simSkillAssignments) rolled from now on, when it beats
  /// the one in play and passes its [dieTrial].
  void rollBestDie(Map<String, dynamic> skills) {
    final caster = knownSpells.isNotEmpty;
    final now = simDieValue(diceFaces, diceSkillAssignments, skills,
            damage: baseDamage, caster: caster) +
        0.01;
    final better = <({
      String id,
      List<Map<String, dynamic>> faces,
      Map<String, String> placed,
      double value
    })>[];
    for (final id in ownedDice.keys.toList()..sort()) {
      if (id == diceId) continue;
      final faces = ownedDice[id]!;
      final placed = simSkillAssignments(
          faces: faces,
          current: const {},
          unlocked: unlockedSkillIds,
          skills: skills);
      final v = simDieValue(faces, placed, skills,
          damage: baseDamage, caster: caster);
      if (v > now) better.add((id: id, faces: faces, placed: placed, value: v));
    }
    // The worthiest first; the first to pass its trial is rolled.
    better.sort((a, b) => b.value.compareTo(a.value));
    for (final d in better) {
      if (!_passesTrial(d.id, d.faces, d.placed)) continue;
      diceId = d.id;
      diceFaces = d.faces;
      diceSkillAssignments = d.placed;
      return;
    }
  }

  /// Runs [fight] (a trial) and puts back everything a fight changes on the
  /// character: its health, mana, potions, afflictions, the stats a fight
  /// lends, the die in play and the run's tallies.
  T restoringAfter<T>(T Function() fight) {
    final saved = (
      maxHealth: maxHealth,
      currentHealth: currentHealth,
      baseDamage: baseDamage,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      luck: luck,
      potions: potions,
      mana: mana,
      signMaxMana: signMaxMana,
      statusEffects: statusEffects,
      fightsWon: fightsWon,
      fightsLost: fightsLost,
      roundsFought: roundsFought,
      potionsUsed: potionsUsed,
      manaGained: manaGained,
      diceId: diceId,
      diceFaces: diceFaces,
      diceSkillAssignments: diceSkillAssignments,
    );
    try {
      return fight();
    } finally {
      maxHealth = saved.maxHealth;
      currentHealth = saved.currentHealth;
      baseDamage = saved.baseDamage;
      strength = saved.strength;
      dexterity = saved.dexterity;
      constitution = saved.constitution;
      intelligence = saved.intelligence;
      wisdom = saved.wisdom;
      luck = saved.luck;
      potions = saved.potions;
      mana = saved.mana;
      signMaxMana = saved.signMaxMana;
      statusEffects = saved.statusEffects;
      fightsWon = saved.fightsWon;
      fightsLost = saved.fightsLost;
      roundsFought = saved.roundsFought;
      potionsUsed = saved.potionsUsed;
      manaGained = saved.manaGained;
      diceId = saved.diceId;
      diceFaces = saved.diceFaces;
      diceSkillAssignments = saved.diceSkillAssignments;
    }
  }

  /// Poison/Stun/Weaken on the character -- fight-scoped, cleared when a
  /// fight ends either way.
  List<StatusEffect> statusEffects = [];

  /// The signs drawn on the character (see signs.dart): the walk takes
  /// them, a fight reads what they add up to.
  List<HeldSign> heldSigns = [];

  /// The specialisations the clans gave (specialisations.dart): those of
  /// the character's own core play.
  List<String> specIds = [];

  /// The training paths (training_paths.json): with them each level's five
  /// stat points are stat picks (drawStatPick), each taking the offer that
  /// raises [preferredStat] (statPickFor), drawn with [pickRandom]; the
  /// paths picked are counted in [trainingTaken]. Without them, the old
  /// fixed spend (see [gainXp]).
  Map<String, TrainingPath> trainingPaths = const {};
  Random pickRandom = Random(1);
  final Map<String, int> trainingTaken = {};

  /// The camp's roll houses the walk built (sim_rolls.dart): null, or none
  /// built, and the picks draw as they always did.
  SimRolls? rolls;

  /// A sign's (or a perk's) extra mana, while a fight lasts.
  int signMaxMana = 0;

  // Run-wide tallies.
  int fightsWon = 0;
  int fightsLost = 0;

  /// Rounds fought over every fight, won or lost (what fight length is
  /// measured by, see fight_length.dart).
  int roundsFought = 0;
  int potionsUsed = 0;
  int manaGained = 0;
  final Map<String, int> spellsCast = {};
  final List<String> spellbooksBought = [];

  int get maxMana => maxManaFor(wisdom: wisdom) + signMaxMana;

  List<String> get equippedItemIds => equippedBySlot.values.toList();

  bool get isKnockedOut => currentHealth <= 0;

  /// What the worn sets and unique items add up to (see gear_effects.dart).
  GearEffects gearEffects(
    Map<String, dynamic> items,
    Map<String, ItemSet> itemSets,
  ) =>
      gearEffectsFor(equippedItemIds, items, itemSets);

  /// The alignment the hero's gear answers to (an aligned item's bonus,
  /// see alignmentGearBonusFor): the walk sets it from its alignment score.
  String alignmentLabel = 'Neutral';

  /// The total a face or spell of [element] hits with: the fight screen's
  /// own sum (strikeDamageFor; [itemSets] adds a worn set's flat attack).
  int casterDamage(
    Map<String, dynamic> items,
    String element, {
    Map<String, ItemSet> itemSets = const {},
  }) =>
      strikeDamageFor(
        baseDamage: baseDamage,
        equippedItemIds: equippedItemIds,
        items: items,
        element: element,
        gearAttack: gearEffects(items, itemSets).attackDamage,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence,
        alignmentLabel: alignmentLabel,
      );

  int armor(
    Map<String, dynamic> items, {
    Map<String, ItemSet> itemSets = const {},
  }) {
    return baseArmor +
        equipmentBonusFor(equippedItemIds, items, 'armor') +
        gearEffects(items, itemSets).armor;
  }

  int elementalResist(Map<String, dynamic> items, String element) {
    final prefix = elementFieldPrefixes[element];
    if (prefix == null) return 0;
    return equipmentBonusFor(equippedItemIds, items, '${prefix}Resist');
  }

  /// A rest at a hub: full health and a full pool, afflictions gone.
  void rest() {
    currentHealth = maxHealth;
    mana = maxMana;
    statusEffects = [];
  }

  /// Runs [gain] XP through the app's own thresholds ([xpForLevel]). Each
  /// level: [levelHealthGain] max health and [levelStatPicks] stat pick --
  /// with [trainingPaths] drawn and taken (see [takeStatPicks]), else a
  /// point to [preferredStat] (the simulator's fixed assumption) -- then a
  /// full heal like the app's own level-up.
  bool gainXp(int gain) {
    xp += gain;
    var leveled = false;
    while (xp >= xpForLevel(level)) {
      xp -= xpForLevel(level);
      level++;
      leveled = true;
      maxHealth += levelHealthGain;
      rolls?.levels(1);
      if (trainingPaths.isNotEmpty) {
        takeStatPicks(levelStatPicks);
      } else {
        addAbilities({preferredStat: levelStatPicks});
      }
    }
    if (leveled) currentHealth = maxHealth;
    mana = min(mana, maxMana);
    return leveled;
  }

  /// [gains] (ability -> points) added, with what they bring: the damage
  /// stat's base damage, Constitution's health (stat_rules.dart), as
  /// `PlayerSession.withAbilityGains`.
  void addAbilities(Map<String, int> gains) {
    for (final MapEntry(:key, :value) in gains.entries) {
      switch (key) {
        case 'strength':
          strength += value;
        case 'dexterity':
          dexterity += value;
        case 'constitution':
          constitution += value;
        case 'intelligence':
          intelligence += value;
        case 'wisdom':
          wisdom += value;
        case 'perception':
          perception += value;
        case 'luck':
          luck += value;
        case 'charisma':
          charisma += value;
      }
    }
    final effects = abilityGainEffects(gains, professionId);
    baseDamage += effects.baseDamage;
    maxHealth = max(1, maxHealth + effects.maxHealth);
    currentHealth = max(1, currentHealth + effects.maxHealth);
  }

  /// The points this build has put into each ability through its picks.
  final Map<String, int> pickedPoints = {};

  /// [count] stat picks (training.dart), each the offer statPickForShares
  /// takes for the profession's build (simBuildShares); its gains added,
  /// its path counted.
  void takeStatPicks(int count) {
    for (var i = 0; i < count; i++) {
      final stats = {
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'perception': perception,
        'luck': luck,
        'charisma': charisma,
      };
      final roll = rolls;
      var offer = drawStatPick(
        paths: trainingPaths,
        random: pickRandom,
        professionId: professionId,
        raceId: raceId,
        luck: luck,
        taken: trainingTaken,
        stats: stats,
        bannedPaths: roll?.banned(RollBanOn.pick) ?? const {},
      );
      if (offer.isEmpty) return;
      final shares = simBuildShares[professionId] ?? {preferredStat: 1.0};
      int choose(List<StatPickOffer> o) =>
          statPickForShares(o, shares, pickedPoints);
      if (roll != null) {
        roll.freshDraw(RollBanOn.pick);
        if (roll.built.isNotEmpty) {
          final main =
              shares.entries.reduce((a, b) => b.value > a.value ? b : a).key;
          offer = roll.workStatPick(offer,
              wanted: shares.keys.toSet(),
              mainStat: main,
              paths: trainingPaths,
              choose: choose,
              redraw: (tier) => drawStatPick(
                    paths: trainingPaths,
                    random: roll.random,
                    professionId: professionId,
                    raceId: raceId,
                    luck: luck,
                    taken: trainingTaken,
                    stats: stats,
                    tier: tier,
                    bannedPaths: roll.banned(RollBanOn.pick),
                  ));
        }
      }
      final pick = offer[choose(offer)];
      trainingTaken[pick.pathId] = (trainingTaken[pick.pathId] ?? 0) + 1;
      for (final MapEntry(:key, :value) in pick.gains.entries) {
        pickedPoints[key] = (pickedPoints[key] ?? 0) + value;
      }
      addAbilities(pick.gains);
    }
  }

  /// One visit to a shop the story just unlocked, with the walk's [gold]:
  /// the profession's own spellbook first if the spell is still unknown,
  /// then up to two potion charges per potion entry, then the single best
  /// affordable equippable per slot (by flat damage plus armor, respecting
  /// stat requirements), then the sage die for a caster. Returns the gold
  /// left.
  int visitShop(
    Map<String, dynamic> shop,
    Map<String, dynamic> items,
    Map<String, dynamic> dice,
    Map<String, SpellSpec> spells,
    int gold, {
    Map<String, dynamic> skills = const {},
    Map<String, ItemSet> itemSets = const {},
  }) {
    if (policy == SimPolicy.competent) {
      return _visitShopCompetent(shop, items, dice, spells, gold,
          skills: skills, itemSets: itemSets);
    }
    int scoreOf(String? itemId) {
      final item = items[itemId] as Map<String, dynamic>?;
      if (item == null) return -1;
      return ((item['attackDamage'] as num?)?.toInt() ?? 0) +
          ((item['armor'] as num?)?.toInt() ?? 0);
    }

    // 1. Spellbooks: the profession's own, still unknown.
    final (:stock, :quantities, purse: afterBooks) =
        _openShop(shop, items, spells, gold);
    var purse = afterBooks;

    // 2. Potions: up to two charges per entry (an antidote is skipped --
    //    the model cures nothing but by spell).
    for (final entry in stock) {
      if (entry.value['itemType']?.toString() != 'Potion' ||
          entry.key == 'antidote') {
        continue;
      }
      final cost = _itemCost(entry.value);
      final limit = quantities[entry.key] ?? 1;
      var bought = 0;
      while (bought < min(limit, 2) && cost > 0 && purse >= cost) {
        purse -= cost;
        bought++;
        potions += entry.key == 'potion_major' ? 2 : 1;
      }
    }

    // The stubborn player keeps its starting gear and die.
    if (policy == SimPolicy.stubborn) return purse;

    // 3. Gear: per slot, the best affordable piece that beats what is worn.
    final bySlot = <String, MapEntry<String, Map<String, dynamic>>>{};
    for (final entry in stock) {
      final item = entry.value;
      if (item['isEquippable'] != true) continue;
      final slot = item['equipSlot']?.toString() ?? '';
      if (slot.isEmpty || purse < _itemCost(item)) continue;
      if (scoreOf(entry.key) <= scoreOf(equippedBySlot[slot])) continue;
      if (!meetsItemStatRequirement(
        item,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence,
      )) {
        continue;
      }
      final best = bySlot[slot];
      if (best == null || scoreOf(entry.key) > scoreOf(best.key)) {
        bySlot[slot] = entry;
      }
    }
    for (final entry in bySlot.entries) {
      final cost = _itemCost(entry.value.value);
      if (purse < cost) continue;
      purse -= cost;
      equippedBySlot[entry.key] = entry.value.key;
    }

    // 4. A caster who can afford the sage die swaps to it: two Deep Focus
    //    faces keep the pool fed. Its own Skill face carries its skill, so
    //    the starter die's Technique assignments no longer apply.
    if (knownSpells.isNotEmpty) {
      for (final raw in (shop['diceStock'] as List?) ?? const []) {
        if (raw.toString() != 'sage_die') continue;
        final die = dice['sage_die'] as Map<String, dynamic>?;
        final cost = (die?['cost'] as num?)?.toInt() ?? 0;
        final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>();
        if (faces == null ||
            faces.isEmpty ||
            purse < cost ||
            diceFaces == faces) {
          continue;
        }
        purse -= cost;
        diceFaces = faces;
        diceSkillAssignments = const {};
      }
    }
    return purse;
  }

  /// What both shop visits start with: the stock, how many of each the
  /// shop holds, and the purse once the profession's own spellbooks are
  /// bought.
  ({
    List<MapEntry<String, Map<String, dynamic>>> stock,
    Map<String, int> quantities,
    int purse,
  }) _openShop(Map<String, dynamic> shop, Map<String, dynamic> items,
      Map<String, SpellSpec> spells, int gold) {
    final quantities = (shop['stockQuantities'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 1),
        ) ??
        const <String, int>{};
    final stock = _shopItems(shop, items);
    return (
      stock: stock,
      quantities: quantities,
      purse: _buySpellbooks(stock, spells, gold),
    );
  }

  /// What [shop] sells that [items] knows, in the shop's order.
  List<MapEntry<String, Map<String, dynamic>>> _shopItems(
    Map<String, dynamic> shop,
    Map<String, dynamic> items,
  ) =>
      [
        for (final raw in allShopStock(shop))
          if (items[raw] is Map<String, dynamic>)
            MapEntry(raw, items[raw] as Map<String, dynamic>),
      ];

  /// Buys the spellbooks in [stock] that teach a spell the profession may
  /// still learn and the [purse] pays for; returns the gold left.
  int _buySpellbooks(
    List<MapEntry<String, Map<String, dynamic>>> stock,
    Map<String, SpellSpec> spells,
    int purse,
  ) {
    for (final entry in stock) {
      final taughtSpellId = spellbookSpellIdFor(entry.value);
      if (taughtSpellId == null) continue;
      final spell = spells[taughtSpellId];
      if (spell == null ||
          purse < _itemCost(entry.value) ||
          knownSpells.any((s) => s.id == spell.id) ||
          !canLearnSpell(
            spell,
            professionId: professionId,
            knownSpellIds: [for (final s in knownSpells) s.id],
          )) {
        continue;
      }
      purse -= _itemCost(entry.value);
      knownSpells.add(spell);
      spellbooksBought.add(spell.id);
    }
    return purse;
  }

  /// The competent player's visit (sim_policy.dart): the profession's own
  /// spellbook; potions up to [_potionsKept] charges; the best die the
  /// shop sells it may roll, when it beats the one in play; then gear,
  /// one piece at a time, the one that raises its best loadout most
  /// (simBestLoadout, sets weighed) while the purse lasts; the change on
  /// more potions, up to [_potionsStocked]. Returns the gold left.
  int _visitShopCompetent(
    Map<String, dynamic> shop,
    Map<String, dynamic> items,
    Map<String, dynamic> dice,
    Map<String, SpellSpec> spells,
    int gold, {
    required Map<String, dynamic> skills,
    required Map<String, ItemSet> itemSets,
  }) {
    final (:stock, :quantities, purse: afterBooks) =
        _openShop(shop, items, spells, gold);
    var purse = afterBooks;

    void buyPotions(int upTo) {
      for (final entry in stock) {
        if (entry.value['itemType']?.toString() != 'Potion' ||
            entry.key == 'antidote') {
          continue;
        }
        final cost = _itemCost(entry.value);
        final limit = quantities[entry.key] ?? 1;
        var bought = 0;
        while (potions < upTo && bought < limit && cost > 0 && purse >= cost) {
          purse -= cost;
          bought++;
          potions += entry.key == 'potion_major' ? 2 : 1;
        }
      }
    }

    buyPotions(_potionsKept);

    // The die: the best of the shop's it may roll, if it beats its own.
    final caster = knownSpells.isNotEmpty;
    final dieNow = simDieValue(diceFaces, diceSkillAssignments, skills,
        damage: baseDamage, caster: caster);
    String? dieId;
    var dieBest = dieNow + 0.1;
    for (final raw in (shop['diceStock'] as List?) ?? const []) {
      final id = raw.toString();
      final die = dice[id] as Map<String, dynamic>?;
      final faces = (die?['faces'] as List?)?.cast<Map<String, dynamic>>();
      if (die == null ||
          faces == null ||
          faces.isEmpty ||
          ownedDice.containsKey(id) ||
          purse < ((die['cost'] as num?)?.toInt() ?? 0) ||
          !simCanUseDie(die, professionId: professionId, raceId: raceId)) {
        continue;
      }
      final placed = simSkillAssignments(
          faces: faces,
          current: const {},
          unlocked: unlockedSkillIds,
          skills: skills);
      final v = simDieValue(faces, placed, skills,
          damage: baseDamage, caster: caster);
      // Bought only when it would be rolled: worth more, and its trial
      // passed.
      if (v > dieBest && _passesTrial(id, faces, placed)) {
        dieBest = v;
        dieId = id;
      }
    }
    if (dieId != null) {
      final die = dice[dieId] as Map<String, dynamic>;
      purse -= (die['cost'] as num?)?.toInt() ?? 0;
      ownedDice[dieId] = (die['faces'] as List).cast<Map<String, dynamic>>();
      rollBestDie(skills);
    }

    // Gear, the best gain first, while the purse lasts.
    bool canWear(Map<String, dynamic> item) => meetsItemStatRequirement(
          item,
          strength: strength,
          dexterity: dexterity,
          constitution: constitution,
          intelligence: intelligence,
        );
    Map<String, String> bestWith(Iterable<String> extra) => simBestLoadout(
        worn: equippedBySlot,
        owned: {...ownedItemIds, ...extra},
        items: items,
        sets: itemSets,
        canWear: canWear,
        caster: caster);
    double valueOf(Map<String, String> loadout) =>
        simLoadoutValue(loadout.values, items, itemSets, caster: caster);
    while (true) {
      final now = valueOf(bestWith(const []));
      String? pick;
      var gain = 0.05;
      for (final entry in stock) {
        final item = entry.value;
        if (item['isEquippable'] != true ||
            ownedItemIds.contains(entry.key) ||
            equippedBySlot.containsValue(entry.key) ||
            purse < _itemCost(item) ||
            !canWear(item)) {
          continue;
        }
        final g = valueOf(bestWith([entry.key])) - now;
        if (g > gain) {
          gain = g;
          pick = entry.key;
        }
      }
      if (pick == null) break;
      purse -= _itemCost(items[pick] as Map<String, dynamic>);
      ownedItemIds.add(pick);
      final best = bestWith(const []);
      equippedBySlot
        ..clear()
        ..addAll(best);
    }

    buyPotions(_potionsStocked);
    return purse;
  }

  /// A copy of this character, field by field (v1.880): the Tower builds
  /// its hero once a floor and goes on from the copy (towerHeroOf), not
  /// from scratch. Its lists, sets and maps are its own; what they hold
  /// (a die's faces, a spell, a sign) is shared, as nothing changes those
  /// in place. [pickRandom] and [rolls] are shared too: a Random can't be
  /// copied (the Tower never draws from it). `test/sim_character_copy_test`
  /// fails when a field is added here and not to this copy.
  SimCharacter copy() => SimCharacter._(
        raceId: raceId,
        professionId: professionId,
        preferredStat: preferredStat,
        maxHealth: maxHealth,
        baseDamage: baseDamage,
        baseArmor: baseArmor,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence,
        wisdom: wisdom,
        luck: luck,
        charisma: charisma,
        perception: perception,
        diceFaces: List.of(diceFaces),
        diceSkillAssignments: Map.of(diceSkillAssignments),
        unlockedSkillIds: Set.of(unlockedSkillIds),
        knownSpells: List.of(knownSpells),
        potions: potions,
        startingGold: startingGold,
      )
        ..level = level
        ..xp = xp
        ..currentHealth = currentHealth
        ..mana = mana
        ..equippedBySlot.addAll(equippedBySlot)
        ..policy = policy
        ..ownedItemIds.addAll(ownedItemIds)
        ..diceId = diceId
        ..ownedDice.addAll({
          for (final MapEntry(:key, :value) in ownedDice.entries)
            key: List.of(value),
        })
        ..dieTrial = dieTrial
        .._dieFailedAt.addAll(_dieFailedAt)
        ..statusEffects = List.of(statusEffects)
        ..heldSigns = List.of(heldSigns)
        ..specIds = List.of(specIds)
        ..trainingPaths = trainingPaths
        ..pickRandom = pickRandom
        ..trainingTaken.addAll(trainingTaken)
        ..rolls = rolls
        ..signMaxMana = signMaxMana
        ..fightsWon = fightsWon
        ..fightsLost = fightsLost
        ..roundsFought = roundsFought
        ..potionsUsed = potionsUsed
        ..manaGained = manaGained
        ..spellsCast.addAll(spellsCast)
        ..spellbooksBought.addAll(spellbooksBought)
        ..alignmentLabel = alignmentLabel
        ..pickedPoints.addAll(pickedPoints);
}

/// The potion charges the competent player keeps before buying gear, and
/// tops up to with the change.
const int _potionsKept = 3;
const int _potionsStocked = 5;

/// One simulated fight's result, for the run's telemetry.
class SimFightOutcome {
  const SimFightOutcome({
    required this.won,
    required this.rounds,
    required this.spellsCast,
    required this.manaGained,
    required this.potionsUsed,
    this.phasesEntered = 0,
    this.goldStolen = 0,
    this.healedBy = const {},
  });

  final bool won;
  final int rounds;

  /// The Crow's Price's take (see SignEffects.crowsGold), won or lost.
  final int goldStolen;

  /// Boss phases the enemies crossed this fight.
  final int phasesEntered;

  /// spell id -> casts, this fight only.
  final Map<String, int> spellsCast;
  final int manaGained;
  final int potionsUsed;

  int get totalCasts => spellsCast.values.fold(0, (a, b) => a + b);

  /// What the hero's heals healed this fight, by source (v1.874, for QA's
  /// heal-rule guards): the heal rule's amounts (heal_rules.dart), before
  /// full health caps them; a lost fight's too (its hero is then refilled).
  final Map<HealSource, int> healedBy;

  /// All of [healedBy], and the spells' share of it.
  int get healed => healedBy.values.fold(0, (a, b) => a + b);
  int get spellHealed => healedBy[HealSource.spell] ?? 0;
}

// The fight screen's own numbers (fight_numbers.dart).
const Map<int, double> _packStatMultipliers = packStatMultipliers;
const int _potionHeal = potionHealAmount;
const int _maxRolls = maxRollsPerTurn;

/// Plays one fight of [character] against [enemies] (id -> record; a pack
/// when more than one) in [chapter], mutating the character (health, mana,
/// potions, tallies) the way the app's own fight leaves the session. On a
/// loss the character is healed and refilled like `applyCombatResult` on
/// a loss; XP and gold are the caller's to grant on a win. [signs] is what
/// the character's held signs add up to (see signEffectsFor): lent for
/// the fight and taken back when it ends; [perks] what the perk ranks do.
/// [zoneMultiplier] is the fight's own multiplier on the curve, as the
/// fight screen's `EncounterModifiers.difficultyMultiplier` (a Tower floor's
/// extra).
SimFightOutcome simulateSimFight({
  required SimCharacter character,
  required List<MapEntry<String, Map<String, dynamic>>> enemies,
  required int chapter,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> items,
  required Random random,
  Map<String, ItemSet> itemSets = const {},
  int newGamePlusCycle = 0,
  int maxRounds = 80,
  SignEffects signs = SignEffects.none,
  PerkEffects perks = PerkEffects.none,
  bool clash = true,
  Set<String> clashOff = const {},
  num Function(String clanId)? clanStanding,
  ContextRule? context,
  Reinforcement reinforcement = Reinforcement.none,
  List<SimAlly> allies = const [],
  double zoneMultiplier = 1.0,
}) {
  final fight = _SimFight(
    c: character,
    enemies: enemies,
    chapter: chapter,
    skills: skills,
    items: items,
    random: random,
    itemSets: itemSets,
    newGamePlusCycle: newGamePlusCycle,
    maxRounds: maxRounds,
    s: signs,
    perks: perks,
    clash: clash,
    clashOff: clashOff,
    clanStanding: clanStanding,
    context: context,
    reinforcement: reinforcement,
    allies: allies,
    zoneMultiplier: zoneMultiplier,
  ).._setup();
  return fight.run();
}

/// True when one of the enemy's moves reads what the party just hit it
/// with (an OnHitByElement condition): such an enemy is never rolled ahead.
bool _hasReactiveMoves(Map<String, dynamic> data) =>
    ((data['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [])
        .any((m) => m['condition']?.toString() == 'OnHitByElement');

/// Who a player with the squad rules in play strikes: the healer first
/// (it undoes the work), then the guard (it covers the rest), then the
/// first left standing.
_SimEnemy? _focusTarget(List<_SimEnemy> ens) {
  for (final role in [SquadRole.healer, SquadRole.guard]) {
    for (final e in ens) {
      if (e.isAlive && e.role == role) return e;
    }
  }
  for (final e in ens) {
    if (e.isAlive) return e;
  }
  return null;
}

/// [face] under the enemies' tampering, as fight_dice_rules' `_tampered`
/// lands it: a Curse on the face ([cursed] holds the cursed face indexes),
/// then a Silence over the round.
DiceFaceResult _tamperedFace(
    DiceFaceResult face, Set<int> cursed, bool silenced) {
  var landed = cursed.contains(face.faceIndex) ? cursedFace(face) : face;
  if (silenced && landed.type == 'Skill') landed = silencedFace(landed);
  return landed;
}

/// Whether the hero's [raw] roll lands Steady -- the die a Hex leaves
/// alone: the face with its skill, the strike signs' keywords on an Attack
/// face, then the tampering.
bool _landsSteady(SimCharacter c, DiceFaceResult raw, SignEffects s,
    Set<int> cursed, bool silenced) {
  var face = applyFaceAssignment(
    raw,
    c.diceFaces[raw.faceIndex],
    c.diceSkillAssignments[raw.faceIndex.toString()],
  );
  if (face.type == 'Attack' && s.strikeKeywords.isNotEmpty) {
    face = face.withKeywords({...face.keywords, ...s.strikeKeywords});
  }
  return _tamperedFace(face, cursed, silenced).hasKeyword(FaceKeyword.steady);
}

/// A shop item's price in gold.
int _itemCost(Map<String, dynamic> item) =>
    (item['cost'] as num?)?.toInt() ?? 0;
