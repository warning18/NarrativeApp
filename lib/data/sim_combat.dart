import 'dart:math';

import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../combat/dice_tamper.dart';
import '../combat/doctrine.dart';
import '../combat/element_reaction.dart';
import '../combat/enemy_response.dart';
import '../combat/fight_goal.dart';
import '../combat/parry.dart';
import '../combat/squad.dart';
import '../combat/gear_effects.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../models/ally_state.dart';
import 'perks.dart';
import 'shop_stock.dart';
import 'signs.dart';

/// A fight model for the in-app playthrough simulator: one simulated
/// character (a random race and profession, created the way `startNewGame`
/// creates a real one) who fights every combat choice the graph walk takes
/// with the same engine a live fight uses -- `rollDie`, `resolvePlayerFace`,
/// `resolveEnemyMove`, the status effects, the chapter curve, pack
/// multipliers, the mana pool, its Mana faces and the spells the
/// profession starts with or buys, and a Mirror sending back the round's
/// best hit. Deliberate simplifications, so the numbers read as "a solo
/// player of this build" rather than a full party:
/// - no companions, so no party combos or duo techniques (nor the
///   dexterity order, Quick Resolve or a loadout swap, which only matter
///   with one);
/// - of the clash rules (v1.212-v1.215) the goals (hold, rout, subdue), the
///   Writ, squad roles, the enemies' answers (counter, press), parries and
///   element reactions are played when `clash` is on; the thieves' purse,
///   the hunt-the-healer retarget and the doctrines' affixes are not;
/// - no affixes, Elites or battlefield conditions;
/// - no chapter threat on the enemies, and no sellsword;
/// - of the face keywords only the strike ones a sign may lend (Cleave,
///   Pierce, Pain, Steady), no Hex, Silence or Curse (the enemy spends its
///   turn and nothing else changes), no Luck nudges and no Hammersmith
///   work on the die;
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
    required this.diceFaces,
    required this.diceSkillAssignments,
    required this.unlockedSkillIds,
    required this.knownSpells,
    required this.potions,
    required this.startingGold,
  })  : currentHealth = maxHealth,
        mana = maxManaFor(intelligence: intelligence, wisdom: wisdom);

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
    int defaults(String key) => (gameConfig[key] as num?)?.toInt() ?? 0;
    int bonus(Map<String, dynamic> record, String key) =>
        (record[key] as num?)?.toInt() ?? 0;
    int stat(String key, String bonusKey) =>
        defaults(key) + bonus(race, bonusKey) + bonus(profession, bonusKey);

    final professionSkillId = profession['standardSkillID']?.toString() ?? '';
    final manaSkillId = profession['manaSkillID']?.toString() ?? '';
    final raceSkillId = race['standardSkillID']?.toString() ?? '';
    final startingDiceId = profession['startingDiceId']?.toString() ?? '';
    final dieId = startingDiceId.isEmpty ? 'starter_die' : startingDiceId;
    final faces = ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final startingSpells = <SpellSpec>[
      for (final id in (profession['startingSpellIds'] as List?) ?? const [])
        if (spells[id.toString()] != null) spells[id.toString()]!,
    ];
    final preferred = profession['preferredScalingStat']?.toString() ?? '';
    return SimCharacter._(
      raceId: raceId,
      professionId: professionId,
      preferredStat: preferred.isEmpty ? 'wisdom' : preferred,
      maxHealth: max(1, stat('maxHealth', 'bonusMaxHealth')),
      baseDamage: stat('baseDamage', 'bonusBaseDamage'),
      baseArmor: stat('baseArmor', 'bonusBaseArmor'),
      strength: stat('strength', 'bonusStrength'),
      dexterity: stat('dexterity', 'bonusDexterity'),
      constitution: stat('constitution', 'bonusConstitution'),
      intelligence: stat('intelligence', 'bonusIntelligence'),
      wisdom: stat('wisdom', 'bonusWisdom'),
      luck: stat('luck', 'bonusLuck'),
      diceFaces: faces,
      // The same starting kit as PlayerSessionNotifier.startNewGame: a
      // caster's mana skill sits on the apprentice die's Channeling face.
      diceSkillAssignments: {
        if (manaSkillId.isNotEmpty) '1': manaSkillId,
        if (professionSkillId.isNotEmpty) '4': professionSkillId,
        if (raceSkillId.isNotEmpty) '5': raceSkillId,
      },
      unlockedSkillIds: {
        if (professionSkillId.isNotEmpty) professionSkillId,
        if (manaSkillId.isNotEmpty) manaSkillId,
        if (raceSkillId.isNotEmpty) raceSkillId,
      },
      knownSpells: startingSpells,
      potions: defaults('potionCount'),
      startingGold: defaults('gold') +
          bonus(race, 'startingGoldBonus') +
          bonus(profession, 'startingGoldBonus'),
    );
  }

  final String raceId;
  final String professionId;

  /// The ability score each level-up's assumed stat spend goes to -- the
  /// profession's `preferredScalingStat`, or Wisdom for a Cleric.
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

  /// Poison/Stun/Weaken on the character -- fight-scoped, cleared when a
  /// fight ends either way.
  List<StatusEffect> statusEffects = [];

  /// The signs drawn on the character (see signs.dart): the walk takes
  /// them, a fight reads what they add up to.
  List<HeldSign> heldSigns = [];

  /// A sign's (or a perk's) extra mana, while a fight lasts.
  int signMaxMana = 0;

  // Run-wide tallies.
  int fightsWon = 0;
  int fightsLost = 0;
  int potionsUsed = 0;
  int manaGained = 0;
  final Map<String, int> spellsCast = {};
  final List<String> spellbooksBought = [];

  int get maxMana =>
      maxManaFor(intelligence: intelligence, wisdom: wisdom) + signMaxMana;

  List<String> get equippedItemIds => equippedBySlot.values.toList();

  bool get isKnockedOut => currentHealth <= 0;

  /// What the worn sets and unique items add up to (see gear_effects.dart).
  GearEffects gearEffects(
          Map<String, dynamic> items, Map<String, ItemSet> itemSets) =>
      gearEffectsFor(equippedItemIds, items, itemSets);

  /// The total a face or spell of [element] hits with -- the same sum the
  /// fight screen and the character screen use ([itemSets] adds a worn
  /// set's flat attack).
  int casterDamage(Map<String, dynamic> items, String element,
      {Map<String, ItemSet> itemSets = const {}}) {
    final scaling = equipmentScalingBonusFor(
      equippedItemIds,
      items,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
    );
    final prefix = elementFieldPrefixes[element];
    final elemental = prefix == null
        ? 0
        : equipmentBonusFor(equippedItemIds, items, '${prefix}DmgBonus');
    return baseDamage +
        equipmentBonusFor(equippedItemIds, items, 'attackDamage') +
        scaling.damageBonus +
        gearEffects(items, itemSets).attackDamage +
        elemental;
  }

  int armor(Map<String, dynamic> items,
      {Map<String, ItemSet> itemSets = const {}}) {
    final scaling = equipmentScalingBonusFor(
      equippedItemIds,
      items,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
    );
    return baseArmor +
        equipmentBonusFor(equippedItemIds, items, 'armor') +
        scaling.armorBonus +
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

  /// Runs [gain] XP through the app's own `level * 100` thresholds. Each
  /// level: +20 max health and +5 stat points, spent here as +10 health,
  /// +2 damage, +1 armor and +1 to [preferredStat] (the simulator's fixed
  /// assumption for what a player would do), then a full heal like the
  /// app's own level-up.
  bool gainXp(int gain) {
    xp += gain;
    var leveled = false;
    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
      leveled = true;
      maxHealth += 30;
      baseDamage += 2;
      baseArmor += 1;
      switch (preferredStat) {
        case 'strength':
          strength++;
        case 'dexterity':
          dexterity++;
        case 'constitution':
          constitution++;
        case 'intelligence':
          intelligence++;
        default:
          wisdom++;
      }
    }
    if (leveled) currentHealth = maxHealth;
    mana = min(mana, maxMana);
    return leveled;
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
    int gold,
  ) {
    var purse = gold;
    int scoreOf(String? itemId) {
      final item = items[itemId] as Map<String, dynamic>?;
      if (item == null) return -1;
      return ((item['attackDamage'] as num?)?.toInt() ?? 0) +
          ((item['armor'] as num?)?.toInt() ?? 0);
    }

    int costOf(Map<String, dynamic> item) =>
        (item['cost'] as num?)?.toInt() ?? 0;
    final quantities = (shop['stockQuantities'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 1),
        ) ??
        const <String, int>{};
    final stock = <MapEntry<String, Map<String, dynamic>>>[
      for (final raw in allShopStock(shop))
        if (items[raw] is Map<String, dynamic>)
          MapEntry(raw, items[raw] as Map<String, dynamic>),
    ];

    // 1. Spellbooks: the profession's own, still unknown.
    for (final entry in stock) {
      final taughtSpellId = spellbookSpellIdFor(entry.value);
      if (taughtSpellId == null) continue;
      final spell = spells[taughtSpellId];
      if (spell == null ||
          purse < costOf(entry.value) ||
          knownSpells.any((s) => s.id == spell.id) ||
          !canLearnSpell(spell,
              professionId: professionId,
              knownSpellIds: [for (final s in knownSpells) s.id])) {
        continue;
      }
      purse -= costOf(entry.value);
      knownSpells.add(spell);
      spellbooksBought.add(spell.id);
    }

    // 2. Potions: up to two charges per entry (an antidote is skipped --
    //    the model cures nothing but by spell).
    for (final entry in stock) {
      if (entry.value['itemType']?.toString() != 'Potion' ||
          entry.key == 'antidote') {
        continue;
      }
      final cost = costOf(entry.value);
      final limit = quantities[entry.key] ?? 1;
      var bought = 0;
      while (bought < min(limit, 2) && cost > 0 && purse >= cost) {
        purse -= cost;
        bought++;
        potions += entry.key == 'potion_major' ? 2 : 1;
      }
    }

    // 3. Gear: per slot, the best affordable piece that beats what is worn.
    final bySlot = <String, MapEntry<String, Map<String, dynamic>>>{};
    for (final entry in stock) {
      final item = entry.value;
      if (item['isEquippable'] != true) continue;
      final slot = item['equipSlot']?.toString() ?? '';
      if (slot.isEmpty || purse < costOf(item)) continue;
      if (scoreOf(entry.key) <= scoreOf(equippedBySlot[slot])) continue;
      if (!meetsItemStatRequirement(item,
          strength: strength,
          dexterity: dexterity,
          constitution: constitution,
          intelligence: intelligence)) {
        continue;
      }
      final best = bySlot[slot];
      if (best == null || scoreOf(entry.key) > scoreOf(best.key)) {
        bySlot[slot] = entry;
      }
    }
    for (final entry in bySlot.entries) {
      final cost = costOf(entry.value.value);
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
}

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
}

/// Pack-size stat multipliers, the fight screen's own.
const Map<int, double> _packStatMultipliers = {2: 0.8, 3: 0.7};

const int _potionHeal = 30;
const int _maxRolls = 3;

class _SimEnemy {
  _SimEnemy({
    required this.id,
    required this.data,
    required this.maxHealth,
    required this.damage,
  })  : health = maxHealth,
        phases = parseBossPhases(data);

  final String id;
  Map<String, dynamic> data;
  final int maxHealth;
  int damage;
  int health;
  List<StatusEffect> statusEffects = [];
  Set<String> elementsHit = {};

  /// Boss phases, highest threshold first (see [parseBossPhases]) and how
  /// many have been entered -- the fight screen's own bookkeeping.
  final List<BossPhase> phases;
  int phaseIndex = 0;

  bool get isAlive => health > 0;

  /// v1.215 squad role and answer, v1.212 captain mark, and the pack this
  /// enemy fights in (for a guard's cover and a reaction's spread).
  SquadRole? role;
  EnemyResponse response = EnemyResponse.none;
  bool provoked = false;
  bool pressing = false;
  bool isCaptain = false;
  List<_SimEnemy> pack = const [];

  /// v1.214 reaction marks (element -> round struck) and a parry waiting.
  final Map<String, int> marks = {};
  int parryBlock = 0;

  /// The move rolled ahead (telegraphed), kept for the enemy's turn.
  EnemyMoveResult? planned;

  /// v1.162 intents, as the fight screen keeps them: a raised guard, a
  /// held wind-up, a broken one, and how many rallies raised the damage.
  int guard = 0;
  EnemyMoveResult? charged;
  bool staggered = false;
  int rallies = 0;
  int damageThisRound = 0;
  int topHit = 0;
  bool hitWeakness = false;

  /// A party hit of [damage] and [element]: weakness or resistance, then
  /// the guard. Returns what gets through and tallies it towards breaking
  /// a wind-up.
  int takeHit(int damage, String element, {bool pierce = false}) {
    if (damage <= 0) return damage;
    if (elementMultiplierFor(data, element) > 1.0) hitWeakness = true;
    final elemental = damageAfterElement(damage, data, element);
    // A Pierce strike goes through the raised guard.
    final through = pierce
        ? (damage: elemental, guard: guard)
        : damageThroughGuard(elemental, guard);
    guard = through.guard;
    damageThisRound += through.damage;
    topHit = max(topHit, through.damage);
    return through.damage;
  }

  /// A party blow with the v1.214/215 rules on: [takeHit], a standing
  /// guard's cover, the health it costs, the hardest hit this round and an
  /// element reaction. Returns the damage dealt, a reaction's bonus
  /// included.
  int landHit(int damage, String element, int round,
      {bool pierce = false, bool react = true}) {
    var landed = takeHit(damage, element, pierce: pierce);
    if (landed > 0 &&
        !pierce &&
        role != SquadRole.guard &&
        pack.any((o) =>
            !identical(o, this) && o.isAlive && o.role == SquadRole.guard)) {
      final cut = (landed * guardCoverShare).round();
      landed -= cut;
      damageThisRound -= cut;
    }
    health = max(0, health - landed);
    var dealt = landed;
    if (react && element != 'None' && landed > 0 && isAlive) {
      final sprung = reactionOn(marks, element, round);
      if (sprung == null) {
        marks[element] = round;
      } else {
        marks.remove(sprung.primer);
        final reaction = sprung.reaction;
        final bonus = reactionBonus(reaction, landed);
        if (bonus > 0) {
          health = max(0, health - bonus);
          dealt += bonus;
        }
        switch (reaction) {
          case ElementReaction.shatter:
            guard = 0;
          case ElementReaction.freeze:
            if (!isBossEnemy(id, data) && phases.isEmpty) {
              statusEffects = applyStatusEffect(
                  statusEffects,
                  const StatusEffect(
                      type: StatusEffectType.stun, remainingTurns: 1));
            }
          case ElementReaction.sandblast:
            statusEffects = applyStatusEffect(
                statusEffects,
                const StatusEffect(
                    type: StatusEffectType.weaken,
                    remainingTurns: weakenTurns,
                    magnitude: sandblastWeakenPercent));
          case ElementReaction.conduct:
          case ElementReaction.firestorm:
          case ElementReaction.eclipse:
            break;
        }
        final spread = reactionSpreadShare(reaction);
        if (spread > 0) {
          for (final other in pack) {
            if (identical(other, this) || !other.isAlive) continue;
            other.health =
                max(0, other.health - max(1, (landed * spread).round()));
          }
        }
      }
    }
    return dealt;
  }

  /// Plays every phase crossed since the last check; returns how many.
  int advancePhases() {
    if (phases.isEmpty || !isAlive) return 0;
    final target = bossPhaseIndexFor(phases, health, maxHealth);
    var entered = 0;
    while (phaseIndex < target) {
      final phase = phases[phaseIndex];
      phaseIndex++;
      entered++;
      health = healthAfterPhaseHeal(phase, health, maxHealth);
      if (phase.cleanse) statusEffects = [];
      damage = (damage * phase.damageMultiplier).round();
      data = enemyDataInPhase(data, phase);
    }
    return entered;
  }
}

/// Plays one fight of [character] against [enemies] (id -> record; a pack
/// when more than one) in [chapter], mutating the character (health, mana,
/// potions, tallies) the way the app's own fight leaves the session. On a
/// loss the character is healed and refilled like `applyCombatResult` on
/// a loss; XP and gold are the caller's to grant on a win. [signs] is what
/// the character's held signs add up to (see signEffectsFor): lent for
/// the fight and taken back when it ends; [perks] what the perk ranks do.
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
}) {
  final c = character;
  // Which of the clash rules are in play.
  bool on(String rule) => clash && !clashOff.contains(rule);
  final s = signs;
  final gear = s.over(perks.over(c.gearEffects(items, itemSets)));
  // The Sworn boons: blows the Writ still cancels, guards the Compact
  // edge still breaks, hits the Crow's Price has stolen on.
  var writ = s.writFace;
  var edge = s.compactEdge;
  var crowsHits = 0;
  final lending = !s.isEmpty || perks.maxMana > 0;
  var secondWindAvailable = gear.secondWind;
  var phasesEntered = 0;
  // The signs' lend for the fight: its stats, a higher max health (full
  // stays full, a running pact may take a share off the top) and mana.
  final baseMaxHealth = c.maxHealth;
  void lendStats(int sign) {
    c.strength += sign * s.stat('strength');
    c.dexterity += sign * s.stat('dexterity');
    c.constitution += sign * s.stat('constitution');
    c.intelligence += sign * s.stat('intelligence');
    c.wisdom += sign * s.stat('wisdom');
    c.luck += sign * s.stat('luck');
  }

  if (lending) {
    lendStats(1);
    c.maxHealth = s.maxHealthFor(baseMaxHealth);
    c.currentHealth = s.afterStartCurse(
        SignEffects.healthEntering(
            current: c.currentHealth,
            base: baseMaxHealth,
            fightMax: c.maxHealth),
        c.maxHealth);
    final full = c.mana >= c.maxMana;
    c.signMaxMana = s.maxMana + perks.maxMana;
    if (full) c.mana = c.maxMana;
  }
  final packMultiplier = _packStatMultipliers[enemies.length] ?? 1.0;
  DifficultyCurve curveFor(MapEntry<String, Map<String, dynamic>> entry) =>
      difficultyCurveFor(
        chapter: chapter,
        newGamePlusCycle: newGamePlusCycle,
        isBoss: isBossEnemy(entry.key, entry.value),
      );
  // v1.212/v1.215: the fight's goal and the pack's squad, rolled as the
  // fight screen rolls them.
  final bossFlags = [
    for (final entry in enemies) isBossEnemy(entry.key, entry.value),
  ];
  var goal = FightGoal.slay;
  var roles = List<SquadRole?>.filled(enemies.length, null);
  if (on('goal')) {
    goal = rollFightGoal(
      eligible: !bossFlags.any((b) => b),
      enemyCount: enemies.length,
      canYield: enemies.length == 1 &&
          canYieldFaction(enemies.first.value['faction']?.toString()),
      random: random,
    );
    if (clashOff.contains(goal.kind.name)) goal = FightGoal.slay;
  }
  if (on('squad') && chapter >= squadFirstChapter) {
    roles = rollSquadRoles(
      packSize: enemies.length,
      eligible: [for (final b in bossFlags) !b],
      random: random,
    );
  }
  final doctrine = on('writ')
      ? doctrineForFight(
          factions: [
            for (final entry in enemies)
              entry.value['faction']?.toString() ?? '',
          ],
          isBoss: bossFlags,
        )
      : null;
  final ens = <_SimEnemy>[
    for (var i = 0; i < enemies.length; i++)
      () {
        final entry = enemies[i];
        var health = max(
            1,
            (scaledMaxHealth((entry.value['maxHealth'] as num?)?.toInt() ?? 1,
                        c.level) *
                    curveFor(entry).health *
                    packMultiplier)
                .round());
        var damage = (scaledDamage(
                    (entry.value['damage'] as num?)?.toInt() ?? 0, c.level) *
                curveFor(entry).damage *
                packMultiplier)
            .round();
        switch (roles[i]) {
          case SquadRole.healer:
            damage = (damage * healerDamageMultiplier).round();
          case SquadRole.striker:
            damage = (damage * strikerDamageMultiplier).round();
            health = max(1, (health * strikerHealthMultiplier).round());
          case SquadRole.guard:
          case null:
            break;
        }
        if (goal.kind == FightGoalKind.hold) {
          damage = (damage * holdDamageMultiplier).round();
        }
        return _SimEnemy(
          id: entry.key,
          data: entry.value,
          maxHealth: health,
          damage: damage,
        )
          ..role = roles[i]
          ..response = on('response') && chapter >= squadFirstChapter
              ? enemyResponseFromName(entry.value['reaction']?.toString())
              : EnemyResponse.none;
      }(),
  ];
  for (final e in ens) {
    e.pack = ens;
  }
  if (goal.kind == FightGoalKind.rout) {
    if (ens.length >= 2) {
      ens[captainIndex([for (final e in ens) e.maxHealth])].isCaptain = true;
    } else {
      goal = FightGoal.slay;
    }
  }
  if (goal.kind == FightGoalKind.subdue && ens.length != 1) {
    goal = FightGoal.slay;
  }
  // The goal's early end: a Rout's fallen captain routs the rest, a
  // Subdue's broken fighter yields. True when the party has won by it.
  bool goalMet() {
    if (goal.kind == FightGoalKind.rout) {
      final captain = ens.where((e) => e.isCaptain).firstOrNull;
      if (captain != null && !captain.isAlive) {
        for (final e in ens) {
          e.health = 0;
        }
      }
    } else if (goal.kind == FightGoalKind.subdue) {
      for (final e in ens) {
        if (yieldsNow(e.health, e.maxHealth)) e.health = 0;
      }
    }
    return ens.every((e) => !e.isAlive);
  }

  final availableSkills = <String, dynamic>{
    for (final entry in skills.entries)
      if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
              false) ||
          c.unlockedSkillIds.contains(entry.key))
        entry.key: entry.value,
  };
  final casts = <String, int>{};
  var manaGained = 0;
  var potionsUsed = 0;
  var rounds = 0;
  bool allDead() => on('goal') ? goalMet() : ens.every((e) => !e.isAlive);
  void advancePhases() {
    for (final e in ens) {
      phasesEntered += e.advancePhases();
    }
  }

  // A kill-heal sign feeds once on each enemy's fall.
  final fed = <_SimEnemy>{};
  void feedKills() {
    if (s.killHeal <= 0 || c.isKnockedOut) return;
    for (final e in ens) {
      if (e.isAlive || !fed.add(e)) continue;
      c.currentHealth = min(c.maxHealth, c.currentHealth + s.killHeal);
    }
  }

  // A sign's status, rolled on [e] at its odds.
  void rollStatuses(List<SignStatusChance> chances, _SimEnemy e) {
    for (final chance in chances) {
      if (!e.isAlive || !chance.rolls(random)) continue;
      e.statusEffects =
          applyStatusEffect(e.statusEffects, s.playerInflicted(chance.status));
    }
  }

  _SimEnemy? firstLiving() {
    for (final e in ens) {
      if (e.isAlive) return e;
    }
    return null;
  }

  SimFightOutcome finish(bool won) {
    if (lending) {
      lendStats(-1);
      final fightMax = c.maxHealth;
      c.maxHealth = baseMaxHealth;
      c.signMaxMana = 0;
      // A sign that mends the party after a won fight.
      final healed = won ? c.currentHealth + s.afterFightHeal(fightMax) : 0;
      c.currentHealth = min(baseMaxHealth, won ? healed : c.currentHealth);
      c.mana = min(c.mana, c.maxMana);
    }
    if (won) {
      c.fightsWon++;
    } else {
      c.fightsLost++;
      c.currentHealth = c.maxHealth;
      c.mana = c.maxMana;
    }
    c.statusEffects = [];
    for (final entry in casts.entries) {
      c.spellsCast[entry.key] = (c.spellsCast[entry.key] ?? 0) + entry.value;
    }
    c.manaGained += manaGained;
    c.potionsUsed += potionsUsed;
    return SimFightOutcome(
      won: won,
      rounds: rounds,
      spellsCast: casts,
      manaGained: manaGained,
      potionsUsed: potionsUsed,
      phasesEntered: phasesEntered,
      goldStolen: s.crowsGold(crowsHits),
    );
  }

  while (rounds < maxRounds) {
    rounds++;
    for (final e in ens) {
      e.damageThisRound = 0;
      e.topHit = 0;
      e.parryBlock = 0;
      e.hitWeakness = false;
    }
    var playedDefend = false;
    var acted = false;
    // Only a Defend face played this round arms the guard signs.
    var guardArmed = false;
    // --- party round start: poison, stun ---
    final poison = poisonDamageFor(c.statusEffects);
    if (poison > 0) c.currentHealth = max(0, c.currentHealth - poison);
    if (c.isKnockedOut) return finish(false);
    final stunned = isStunned(c.statusEffects);
    if (stunned) c.statusEffects = tickStatusEffects(c.statusEffects);

    if (c.currentHealth < 0.4 * c.maxHealth && c.potions > 0) {
      c.potions--;
      potionsUsed++;
      c.currentHealth = min(c.maxHealth,
          c.currentHealth + _potionHeal + s.potionBonus + perks.potionBonus);
    }

    // The enemies' coming blows are rolled ahead (telegraphed), so a
    // parry knows what it meets; an enemy with a reactive move is read
    // live.
    if (on('parry')) {
      for (final e in ens) {
        if (!e.isAlive ||
            e.planned != null ||
            e.charged != null ||
            e.staggered ||
            isStunned(e.statusEffects) ||
            _hasReactiveMoves(e.data)) {
          continue;
        }
        e.planned = resolveEnemyMove(
          enemy: {...e.data, 'damage': e.damage},
          skills: skills,
          enemyCurrentHealth: e.health,
          enemyMaxHealth: e.maxHealth,
          random: random,
          elementsHitThisRound: <String>{},
        );
      }
    }
    var block = _castSpellIfWorth(c, ens, items, random, casts,
        itemSets: itemSets,
        signs: s,
        clash: clash,
        react: on('reaction'),
        round: rounds);
    // A sign's block for the whole party as the fight opens.
    if (rounds == 1) block += s.partyStartBlock;
    // The round's best hit, what a Mirror sends back: the spell's so far
    // (it hits each enemy once), then the die's.
    var bestHit = ens.fold<int>(0, (best, e) => max(best, e.damageThisRound));
    advancePhases();
    feedKills();
    if (allDead()) return finish(true);

    if (!stunned && c.diceFaces.isNotEmpty) {
      acted = true;
      DiceFaceResult face;
      var rolls = 0;
      do {
        rolls++;
        face = rollDie(c.diceFaces, random);
      } while (face.type == 'Empty' && rolls < _maxRolls);
      face = applyFaceAssignment(face, c.diceFaces[face.faceIndex],
          c.diceSkillAssignments[face.faceIndex.toString()]);
      // The Writ (v1.212): every third round the skill faces fall silent.
      if (doctrine?.rule == DoctrineRule.writ &&
          writSilencesRound(rounds) &&
          face.type == 'Skill') {
        face = silencedFace(face);
      }
      playedDefend = face.type == 'Defend';
      // The strike signs: an Attack face takes their keywords, and their
      // element when it has none of its own.
      if (face.type == 'Attack') {
        if (s.strikeKeywords.isNotEmpty) {
          face = face.withKeywords({...face.keywords, ...s.strikeKeywords});
        }
        if (s.strikeElement.isNotEmpty && face.element == 'None') {
          face = face.withElement(s.strikeElement);
        }
      }
      final attack = face.type == 'Attack';
      if (face.hasKeyword(FaceKeyword.steady) &&
          (attack || face.type == 'Defend' || face.type == 'Heal')) {
        face = face.withValue(face.value + steadyBonus);
      }
      // The guard, mend and spell signs on the face's number.
      face = switch (face.type) {
        'Defend' => face.withValue(s.guardValue(face.value)),
        'Heal' => face.withValue(s.mendValue(face.value, c.wisdom ~/ 2)),
        'Mana' => face.withValue(s.manaValue(face.value)),
        _ => face,
      };
      final skillId =
          face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
      var element = face.element;
      if (face.type == 'Skill') {
        final skill = availableSkills[skillId] as Map<String, dynamic>?;
        element = skill?['element']?.toString() ?? 'None';
      }
      var damageBase = c.casterDamage(items, element, itemSets: itemSets);
      if (attack || face.type == 'Skill') {
        damageBase = s.strikeBase(damageBase, face.value,
            attackFace: attack,
            percent: s.strikePercentFor(
              attackFace: attack,
              currentHealth: c.currentHealth,
              maxHealth: c.maxHealth,
              firstRound: rounds == 1,
            ));
      }
      final result = resolvePlayerFace(
        face,
        availableSkills,
        damageBase,
        activeEffects: c.statusEffects,
        wisdomHealBonus: c.wisdom ~/ 2,
        wisdomManaBonus: wisdomManaBonusFor(c.wisdom),
        luck: c.luck,
        random: random,
        critChanceBonus: gear.critChance,
      );
      // Pain: the strike hits for double and costs its roller.
      final pain = face.hasKeyword(FaceKeyword.pain) && result.damageDealt > 0;
      final dealt =
          pain ? result.damageDealt * painDamageMultiplier : result.damageDealt;
      if (pain) {
        c.currentHealth -=
            painCost(maxHealth: c.maxHealth, currentHealth: c.currentHealth);
      }
      final target = on('squad') ? _focusTarget(ens) : firstLiving();
      // The Compact edge breaks a raised guard outright, while it lasts.
      if (target != null &&
          dealt > 0 &&
          edge > 0 &&
          target.guard > 0 &&
          !face.hasKeyword(FaceKeyword.pierce)) {
        edge--;
        target.guard = 0;
      }
      if (target != null && dealt > 0) {
        final pierce = face.hasKeyword(FaceKeyword.pierce);
        final landed = clash
            ? target.landHit(dealt, element, rounds,
                pierce: pierce, react: on('reaction'))
            : target.takeHit(dealt, element, pierce: pierce);
        if (landed > 0) crowsHits++;
        if (!clash) target.health = max(0, target.health - landed);
        bestHit = max(bestHit, landed);
        if (element != 'None') target.elementsHit.add(element);
        final drained = gear.lifestealFor(landed);
        if (drained > 0) {
          c.currentHealth = min(c.maxHealth, c.currentHealth + drained);
        }
        if (gear.manaOnHit > 0) {
          final before = c.mana;
          c.mana = min(c.maxMana, c.mana + gear.manaOnHit);
          manaGained += c.mana - before;
        }
        // Cleave: every other enemy standing takes a share of the blow.
        if (face.hasKeyword(FaceKeyword.cleave)) {
          for (final other in ens) {
            if (identical(other, target) || !other.isAlive) continue;
            final splash = (dealt * cleaveSplashShare).round();
            if (clash) {
              other.landHit(splash, element, rounds, react: on('reaction'));
            } else {
              other.health =
                  max(0, other.health - other.takeHit(splash, element));
            }
          }
        }
        if (attack && landed > 0) rollStatuses(s.strikeStatuses, target);
      }
      final inflicted = result.inflictedStatus;
      if (target != null && inflicted != null && target.isAlive) {
        target.statusEffects = applyStatusEffect(
            target.statusEffects, s.playerInflicted(inflicted));
      }
      // A mend sign turns healing past full into block, and lifts
      // afflictions.
      if (face.type == 'Heal' && result.healingDone > 0) {
        block += s.shieldFromOverheal(
            healing: result.healingDone,
            currentHealth: c.currentHealth,
            maxHealth: c.maxHealth);
        if (s.mendCleanse > 0) {
          c.statusEffects = c.statusEffects.skip(s.mendCleanse).toList();
        }
      }
      c.currentHealth = min(c.maxHealth, c.currentHealth + result.healingDone);
      // A Defend face meets the strongest blow coming at it as a parry,
      // worth half again as much, instead of guarding the first to strike.
      var parried = false;
      if (on('parry') && face.type == 'Defend' && result.blockAmount > 0) {
        _SimEnemy? mark;
        var markBlow = 0;
        for (final e in ens) {
          if (!e.isAlive) continue;
          final blow = e.charged ?? e.planned;
          if (blow == null || blow.intent != EnemyIntent.attack) continue;
          if (blow.damage >= markBlow) {
            mark = e;
            markBlow = blow.damage;
          }
        }
        if (mark != null) {
          mark.parryBlock += parryAmount(result.blockAmount);
          parried = true;
        }
      }
      if (!parried) block += result.blockAmount;
      // A Defend face arms the guard signs, and may heal.
      if (face.type == 'Defend' && result.blockAmount > 0) {
        guardArmed = !s.isEmpty;
        c.currentHealth = min(c.maxHealth, c.currentHealth + s.guardHeal);
      }
      if (result.manaGained > 0) {
        final before = c.mana;
        c.mana = min(c.maxMana, c.mana + result.manaGained);
        manaGained += c.mana - before;
      }
      c.statusEffects = tickStatusEffects(c.statusEffects);
    }
    advancePhases();
    feedKills();
    if (allDead()) return finish(true);

    // The enemies that watch the round answer it (v1.215).
    if (on('response')) {
      for (final e in ens) {
        if (!e.isAlive || e.staggered || isStunned(e.statusEffects)) continue;
        switch (e.response) {
          case EnemyResponse.counter:
            if (provokesCounter(e.damageThisRound, e.maxHealth)) {
              e.provoked = true;
            }
          case EnemyResponse.press:
            if (provokesPress(
                defenders: playedDefend ? 1 : 0, acting: acted ? 1 : 0)) {
              e.pressing = true;
            }
          // Turning on the healer needs a party to turn from.
          case EnemyResponse.huntHealer:
          case EnemyResponse.none:
            break;
        }
      }
    }

    // A wind-up answered hard enough breaks (see chargeBroken).
    for (final e in ens) {
      if (e.isAlive &&
          e.charged != null &&
          chargeBroken(
            damageThisRound: e.damageThisRound,
            maxHealth: e.maxHealth,
            stunned: isStunned(e.statusEffects),
            hitWeakness: e.hitWeakness,
          )) {
        e.charged = null;
        e.staggered = true;
      }
    }

    // --- enemy turn ---
    if (on('squad')) {
      for (var i = 0; i < ens.length; i++) {
        final healer = ens[i];
        if (!healer.isAlive ||
            healer.role != SquadRole.healer ||
            healer.staggered ||
            isStunned(healer.statusEffects)) {
          continue;
        }
        final index = squadHealTarget(
          health: [for (final e in ens) e.health],
          maxHealth: [for (final e in ens) e.maxHealth],
          self: i,
        );
        if (index == null) continue;
        final friend = ens[index];
        friend.health = min(friend.maxHealth,
            friend.health + squadHealAmount(friend.maxHealth));
      }
    }
    for (final e in ens) {
      if (!e.isAlive) continue;
      final plannedMove = e.planned;
      e.planned = null;
      e.guard = 0;
      final ePoison = poisonDamageFor(e.statusEffects);
      if (ePoison > 0) {
        e.health = max(0, e.health - ePoison);
        if (!e.isAlive) continue;
        phasesEntered += e.advancePhases();
      }
      if (isStunned(e.statusEffects)) {
        e.statusEffects = tickStatusEffects(e.statusEffects);
        e.charged = null;
        e.staggered = false;
        continue;
      }
      if (e.staggered) {
        e.staggered = false;
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      final held = e.charged;
      e.charged = null;
      final move = held ??
          plannedMove ??
          resolveEnemyMove(
            enemy: {...e.data, 'damage': e.damage},
            skills: skills,
            enemyCurrentHealth: e.health,
            enemyMaxHealth: e.maxHealth,
            random: random,
            elementsHitThisRound: e.elementsHit,
          );
      final baseMax = (e.data['maxHealth'] as num?)?.toInt() ?? e.maxHealth;
      if (held == null && move.intent != EnemyIntent.attack) {
        switch (move.intent) {
          case EnemyIntent.heal:
            e.health = min(
                e.maxHealth,
                e.health +
                    scaledEnemyHeal(move.healAmount,
                        maxHealth: e.maxHealth, baseMaxHealth: baseMax));
          case EnemyIntent.guard:
            e.guard = move.guardAmount;
          case EnemyIntent.charge:
            e.charged = move;
          case EnemyIntent.rally:
            for (final other in ens) {
              if (!other.isAlive || other.rallies >= maxRallyStacks) continue;
              other.damage =
                  (other.damage * (1 + move.rallyPercent / 100)).round();
              other.rallies++;
            }
          // A Hex, a Silence or a Curse (v1.182) isn't modelled here: the
          // enemy spends its turn on it and nothing else changes.
          case EnemyIntent.tamper:
          case EnemyIntent.attack:
            break;
        }
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      // The Lantern's Writ cancels the first blows outright.
      if (writ > 0) {
        writ--;
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      if (move.healAmount > 0) {
        e.health = min(
            e.maxHealth,
            e.health +
                scaledEnemyHeal(move.healAmount,
                    maxHealth: e.maxHealth, baseMaxHealth: baseMax));
      }
      // A Mirror sends back the round's best hit, as on the fight screen;
      // a pact's curse makes every blow harder while it runs.
      var moveDamage = s.enemyDamage(applyWeaken(
          move.tamper == DiceTamper.mirror
              ? mirrorDamage(bestPartyHit: bestHit, enemyDamage: e.damage)
              : move.damage,
          e.statusEffects));
      if (on('response')) {
        final answer = responseDamageMultiplier(
            provoked: e.provoked, pressing: e.pressing);
        if (answer != 1.0) moveDamage = (moveDamage * answer).round();
        e.provoked = false;
        e.pressing = false;
      }
      final parry = on('parry') ? e.parryBlock : 0;
      final dodged = random.nextDouble() * 100 <
          dodgeChanceFor(c.dexterity) + gear.dodgeChance;
      var taken = dodged
          ? 0
          : max(
              0,
              moveDamage -
                  parry -
                  block -
                  c.armor(items, itemSets: itemSets) -
                  s.armor -
                  c.elementalResist(items, move.element));
      if (taken >= c.currentHealth &&
          c.currentHealth > 0 &&
          secondWindAvailable) {
        secondWindAvailable = false;
        taken = c.currentHealth - 1;
      }
      // A guard sign bites back while the Defend face's block holds.
      final retaliation =
          guardArmed && !dodged && block > 0 ? s.guardRetaliate : 0;
      c.currentHealth = max(0, c.currentHealth - taken);
      // A parry that stopped the blow outright answers it.
      if (parry > 0 && !dodged && parryStopsBlow(moveDamage, parry)) {
        e.health = max(0, e.health - parryCounter(parry));
        e.parryBlock = 0;
        if (e.isAlive) phasesEntered += e.advancePhases();
      }
      if (taken > 0 && gear.thorns > 0) {
        e.health = max(0, e.health - gear.thorns);
        phasesEntered += e.advancePhases();
      }
      block = 0;
      final inflicted = move.inflictedStatus;
      if (!dodged && inflicted != null && !c.isKnockedOut) {
        c.statusEffects = applyStatusEffect(
            c.statusEffects, applyWisdomResistance(inflicted, c.wisdom));
      }
      e.statusEffects = tickStatusEffects(e.statusEffects);
      if (guardArmed && e.isAlive) {
        if (retaliation > 0) {
          e.health = max(0, e.health - retaliation);
          phasesEntered += e.advancePhases();
        }
        rollStatuses(s.guardStatuses, e);
      }
      if (c.isKnockedOut) return finish(false);
    }
    feedKills();
    for (final e in ens) {
      e.elementsHit = {};
    }
    if (allDead()) return finish(true);
    // A hold is won by living through the enemies' turns it asks for.
    if (on('goal') && holdComplete(goal, rounds)) return finish(true);
  }
  return finish(false);
}

/// The caster policy, one spell a round at most: heal below half, cleanse
/// an affliction, the strongest affordable damage spell (keeping the
/// cheapest heal's cost in reserve unless the spell finishes an enemy),
/// block against a heavy combined swing, a hex on an enemy that will live
/// long enough to feel it. Returns the block granted this round. [signs]
/// lower the costs, lift what spells deal and heal, and add their status.
int _castSpellIfWorth(
  SimCharacter c,
  List<_SimEnemy> ens,
  Map<String, dynamic> items,
  Random random,
  Map<String, int> casts, {
  Map<String, ItemSet> itemSets = const {},
  SignEffects signs = SignEffects.none,
  bool clash = false,
  bool react = true,
  int round = 0,
}) {
  final living = ens.where((e) => e.isAlive).toList();
  if (c.knownSpells.isEmpty || living.isEmpty || c.mana <= 0) return 0;

  int costOf(SpellSpec spell) => signs.spellCost(spell.manaCost);
  int amountOf(SpellSpec spell) {
    final amount = spellAmountFor(
      spell,
      intelligence: c.intelligence,
      wisdom: c.wisdom,
      strength: c.strength,
      level: c.level,
      casterDamage: c.casterDamage(items, spell.element, itemSets: itemSets),
    );
    return spell.effect == SpellEffectKind.damage ||
            spell.effect == SpellEffectKind.heal
        ? signs.spellAmount(amount)
        : amount;
  }

  void cast(SpellSpec spell) {
    c.mana -= costOf(spell);
    casts[spell.id] = (casts[spell.id] ?? 0) + 1;
  }

  final affordable = c.knownSpells.where((s) => costOf(s) <= c.mana).toList();
  if (affordable.isEmpty) return 0;

  if (c.currentHealth < 0.5 * c.maxHealth) {
    final heals = affordable
        .where((s) => s.effect == SpellEffectKind.heal)
        .toList()
      ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
    if (heals.isNotEmpty) {
      c.currentHealth =
          min(c.maxHealth, c.currentHealth + amountOf(heals.first));
      cast(heals.first);
      return 0;
    }
  }

  if (c.statusEffects.isNotEmpty) {
    final cleanse = affordable
        .where((s) => s.effect == SpellEffectKind.cleanse)
        .firstOrNull;
    if (cleanse != null) {
      c.statusEffects = [];
      cast(cleanse);
      return 0;
    }
  }

  final reserve = c.knownSpells
      .where((s) => s.effect == SpellEffectKind.heal)
      .map(costOf)
      .fold<int?>(null, (m, v) => m == null ? v : min(m, v));
  final boss = living.any((e) => soloOnlyEnemyIds.contains(e.id));
  final damageSpells = affordable
      .where((s) => s.effect == SpellEffectKind.damage)
      .toList()
    ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
  for (final spell in damageSpells) {
    final amount = amountOf(spell);
    final killable = living.where((e) => e.health <= amount).toList();
    final List<_SimEnemy> targets;
    if (spell.target == SpellTarget.allEnemies) {
      if (living.length < 2 && killable.isEmpty && !boss) continue;
      targets = living;
    } else {
      targets = [
        killable.isNotEmpty
            ? killable.reduce((a, b) => a.damage >= b.damage ? a : b)
            : living.reduce((a, b) => a.damage >= b.damage ? a : b)
      ];
    }
    if (killable.isEmpty &&
        reserve != null &&
        c.mana - costOf(spell) < reserve) {
      continue;
    }
    final status = spellStatusFor(spell, level: c.level);
    for (final e in targets) {
      if (clash) {
        e.landHit(amount, spell.element, round, react: react);
      } else {
        e.health = max(0, e.health - e.takeHit(amount, spell.element));
      }
      if (spell.element != 'None') e.elementsHit.add(spell.element);
      if (status != null && e.isAlive) {
        e.statusEffects =
            applyStatusEffect(e.statusEffects, signs.playerInflicted(status));
      }
      // A spell sign's status, on every enemy the spell reaches.
      for (final chance in signs.spellStatuses) {
        if (e.isAlive && chance.rolls(random)) {
          e.statusEffects = applyStatusEffect(e.statusEffects, chance.status);
        }
      }
    }
    cast(spell);
    return 0;
  }

  final threat = living.fold(0, (sum, e) => sum + e.damage);
  if (threat >= 0.35 * c.currentHealth ||
      (living.length >= 2 && threat >= 0.25 * c.maxHealth)) {
    final blocks = affordable
        .where((s) => s.effect == SpellEffectKind.block)
        .toList()
      ..sort((a, b) => amountOf(b).compareTo(amountOf(a)));
    if (blocks.isNotEmpty) {
      cast(blocks.first);
      return amountOf(blocks.first);
    }
  }

  for (final spell
      in affordable.where((s) => s.effect == SpellEffectKind.status)) {
    final status = spellStatusFor(spell, level: c.level);
    if (status == null) continue;
    final candidates = living
        .where((e) =>
            e.health > 2 * c.casterDamage(items, 'None', itemSets: itemSets) &&
            !e.statusEffects.any((x) => x.type == status.type))
        .toList();
    if (candidates.isEmpty) continue;
    final target = candidates.reduce((a, b) => a.health >= b.health ? a : b);
    target.statusEffects = applyStatusEffect(target.statusEffects, status);
    for (final chance in signs.spellStatuses) {
      if (chance.rolls(random)) {
        target.statusEffects =
            applyStatusEffect(target.statusEffects, chance.status);
      }
    }
    cast(spell);
    return 0;
  }
  return 0;
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
