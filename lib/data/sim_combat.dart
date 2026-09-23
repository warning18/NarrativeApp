import 'dart:math';

import '../combat/combat_engine.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../models/ally_state.dart';

/// A fight model for the in-app playthrough simulator: one simulated
/// character (a random race and profession, created the way `startNewGame`
/// creates a real one) who fights every combat choice the graph walk takes
/// with the same engine a live fight uses -- `rollDie`, `resolvePlayerFace`,
/// `resolveEnemyMove`, the status effects, the chapter curve, pack
/// multipliers, the mana pool, its Mana faces and the spells the
/// profession starts with or buys. Deliberate simplifications, so the
/// numbers read as "a solo player of this build" rather than a full party:
/// no companions, no affixes or battlefield conditions, no crit/momentum
/// beyond what the engine rolls, a die rerolled only on an empty face, and
/// a shop visited once when the story unlocks it (best affordable gear per
/// slot, two potions, the profession's own spellbook, the sage die for a
/// caster). A lost fight refills health and mana like the app's own loss
/// handling; a new chapter counts as a rest.
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
      diceSkillAssignments: {
        if (professionSkillId.isNotEmpty) '4': professionSkillId,
        if (raceSkillId.isNotEmpty) '5': raceSkillId,
      },
      unlockedSkillIds: {
        if (professionSkillId.isNotEmpty) professionSkillId,
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

  // Run-wide tallies.
  int fightsWon = 0;
  int fightsLost = 0;
  int potionsUsed = 0;
  int manaGained = 0;
  final Map<String, int> spellsCast = {};
  final List<String> spellbooksBought = [];

  int get maxMana => maxManaFor(intelligence: intelligence, wisdom: wisdom);

  List<String> get equippedItemIds => equippedBySlot.values.toList();

  bool get isKnockedOut => currentHealth <= 0;

  /// The total a face or spell of [element] hits with -- the same sum the
  /// fight screen and the character screen use.
  int casterDamage(Map<String, dynamic> items, String element) {
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
        elemental;
  }

  int armor(Map<String, dynamic> items) {
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
        scaling.armorBonus;
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
      for (final raw in (shop['initialStock'] as List?) ?? const [])
        if (items[raw.toString()] is Map<String, dynamic>)
          MapEntry(
              raw.toString(), items[raw.toString()] as Map<String, dynamic>),
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
  });

  final bool won;
  final int rounds;

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
  }) : health = maxHealth;

  final String id;
  final Map<String, dynamic> data;
  final int maxHealth;
  final int damage;
  int health;
  List<StatusEffect> statusEffects = [];
  Set<String> elementsHit = {};

  bool get isAlive => health > 0;
}

/// Plays one fight of [character] against [enemies] (id -> record; a pack
/// when more than one) in [chapter], mutating the character (health, mana,
/// potions, tallies) the way the app's own fight leaves the session. On a
/// loss the character is healed and refilled like `applyCombatResult` on
/// a loss; XP and gold are the caller's to grant on a win.
SimFightOutcome simulateSimFight({
  required SimCharacter character,
  required List<MapEntry<String, Map<String, dynamic>>> enemies,
  required int chapter,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> items,
  required Random random,
  int maxRounds = 80,
}) {
  final c = character;
  final healthCurve = chapterDifficultyMultiplier(chapter);
  final damageCurve = damageShareOf(healthCurve);
  final packMultiplier = _packStatMultipliers[enemies.length] ?? 1.0;
  final ens = <_SimEnemy>[
    for (final entry in enemies)
      _SimEnemy(
        id: entry.key,
        data: entry.value,
        maxHealth: max(
            1,
            (scaledMaxHealth((entry.value['maxHealth'] as num?)?.toInt() ?? 1,
                        c.level) *
                    healthCurve *
                    packMultiplier)
                .round()),
        damage: (scaledDamage(
                    (entry.value['damage'] as num?)?.toInt() ?? 0, c.level) *
                damageCurve *
                packMultiplier)
            .round(),
      ),
  ];
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
  bool allDead() => ens.every((e) => !e.isAlive);
  _SimEnemy? firstLiving() {
    for (final e in ens) {
      if (e.isAlive) return e;
    }
    return null;
  }

  SimFightOutcome finish(bool won) {
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
    );
  }

  while (rounds < maxRounds) {
    rounds++;
    // --- party round start: poison, stun ---
    final poison = poisonDamageFor(c.statusEffects);
    if (poison > 0) c.currentHealth = max(0, c.currentHealth - poison);
    if (c.isKnockedOut) return finish(false);
    final stunned = isStunned(c.statusEffects);
    if (stunned) c.statusEffects = tickStatusEffects(c.statusEffects);

    if (c.currentHealth < 0.4 * c.maxHealth && c.potions > 0) {
      c.potions--;
      potionsUsed++;
      c.currentHealth = min(c.maxHealth, c.currentHealth + _potionHeal);
    }

    var block = _castSpellIfWorth(c, ens, items, random, casts);
    if (allDead()) return finish(true);

    if (!stunned && c.diceFaces.isNotEmpty) {
      DiceFaceResult face;
      var rolls = 0;
      do {
        rolls++;
        face = rollDie(c.diceFaces, random);
      } while (face.type == 'Empty' && rolls < _maxRolls);
      if (face.type == 'Skill') {
        final assigned = c.diceSkillAssignments[face.faceIndex.toString()];
        if (assigned != null && assigned.isNotEmpty) {
          face = face.withLinkedSkillID(assigned);
        }
      }
      final skillId =
          face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
      var element = face.element;
      if (face.type == 'Skill') {
        final skill = availableSkills[skillId] as Map<String, dynamic>?;
        element = skill?['element']?.toString() ?? 'None';
      }
      final result = resolvePlayerFace(
        face,
        availableSkills,
        c.casterDamage(items, element),
        activeEffects: c.statusEffects,
        wisdomHealBonus: c.wisdom ~/ 2,
        luck: c.luck,
        random: random,
      );
      final target = firstLiving();
      if (target != null && result.damageDealt > 0) {
        target.health = max(0, target.health - result.damageDealt);
        if (element != 'None') target.elementsHit.add(element);
      }
      final inflicted = result.inflictedStatus;
      if (target != null && inflicted != null && target.isAlive) {
        target.statusEffects =
            applyStatusEffect(target.statusEffects, inflicted);
      }
      c.currentHealth = min(c.maxHealth, c.currentHealth + result.healingDone);
      block += result.blockAmount;
      if (result.manaGained > 0) {
        final before = c.mana;
        c.mana = min(c.maxMana, c.mana + result.manaGained);
        manaGained += c.mana - before;
      }
      c.statusEffects = tickStatusEffects(c.statusEffects);
    }
    if (allDead()) return finish(true);

    // --- enemy turn ---
    for (final e in ens) {
      if (!e.isAlive) continue;
      final ePoison = poisonDamageFor(e.statusEffects);
      if (ePoison > 0) {
        e.health = max(0, e.health - ePoison);
        if (!e.isAlive) continue;
      }
      if (isStunned(e.statusEffects)) {
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      final move = resolveEnemyMove(
        enemy: {...e.data, 'damage': e.damage},
        skills: skills,
        enemyCurrentHealth: e.health,
        enemyMaxHealth: e.maxHealth,
        random: random,
        elementsHitThisRound: e.elementsHit,
      );
      final moveDamage = applyWeaken(move.damage, e.statusEffects);
      final dodged = random.nextDouble() * 100 < dodgeChanceFor(c.dexterity);
      final taken = dodged
          ? 0
          : max(
              0,
              moveDamage -
                  block -
                  c.armor(items) -
                  c.elementalResist(items, move.element));
      c.currentHealth = max(0, c.currentHealth - taken);
      block = 0;
      final inflicted = move.inflictedStatus;
      if (!dodged && inflicted != null && !c.isKnockedOut) {
        c.statusEffects = applyStatusEffect(
            c.statusEffects, applyWisdomResistance(inflicted, c.wisdom));
      }
      e.statusEffects = tickStatusEffects(e.statusEffects);
      if (c.isKnockedOut) return finish(false);
    }
    for (final e in ens) {
      e.elementsHit = {};
    }
    if (allDead()) return finish(true);
  }
  return finish(false);
}

/// The caster policy, one spell a round at most: heal below half, cleanse
/// an affliction, the strongest affordable damage spell (keeping the
/// cheapest heal's cost in reserve unless the spell finishes an enemy),
/// block against a heavy combined swing, a hex on an enemy that will live
/// long enough to feel it. Returns the block granted this round.
int _castSpellIfWorth(
  SimCharacter c,
  List<_SimEnemy> ens,
  Map<String, dynamic> items,
  Random random,
  Map<String, int> casts,
) {
  final living = ens.where((e) => e.isAlive).toList();
  if (c.knownSpells.isEmpty || living.isEmpty || c.mana <= 0) return 0;

  int amountOf(SpellSpec spell) => spellAmountFor(
        spell,
        intelligence: c.intelligence,
        wisdom: c.wisdom,
        level: c.level,
        casterDamage: c.casterDamage(items, spell.element),
      );
  void cast(SpellSpec spell) {
    c.mana -= spell.manaCost;
    casts[spell.id] = (casts[spell.id] ?? 0) + 1;
  }

  final affordable = c.knownSpells.where((s) => s.manaCost <= c.mana).toList();
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
      .map((s) => s.manaCost)
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
        c.mana - spell.manaCost < reserve) {
      continue;
    }
    final status = spellStatusFor(spell, level: c.level);
    for (final e in targets) {
      e.health = max(0, e.health - amount);
      if (spell.element != 'None') e.elementsHit.add(spell.element);
      if (status != null && e.isAlive) {
        e.statusEffects = applyStatusEffect(e.statusEffects, status);
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
            e.health > 2 * c.casterDamage(items, 'None') &&
            !e.statusEffects.any((x) => x.type == status.type))
        .toList();
    if (candidates.isEmpty) continue;
    final target = candidates.reduce((a, b) => a.health >= b.health ? a : b);
    target.statusEffects = applyStatusEffect(target.statusEffects, status);
    cast(spell);
    return 0;
  }
  return 0;
}
