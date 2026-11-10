part of '../sim_combat.dart';

// One simulated fight (simulateSimFight): what used to be the function's
// locals, kept over the fight, and the small rules several phases share.
// The phases live beside it: sim_fight_setup.dart (the fight's opening),
// sim_fight_party_turn.dart (the round's start, the hero's die, the
// companions), sim_fight_enemy_turn.dart (the enemies' answer and turn)
// and sim_fight_end.dart (the round's end and the fight's).

/// The state of one [simulateSimFight] fight, played round by round by
/// [_SimFightRun.run].
class _SimFight {
  _SimFight({
    required this.c,
    required this.enemies,
    required this.chapter,
    required this.skills,
    required this.items,
    required this.random,
    required this.itemSets,
    required this.newGamePlusCycle,
    required this.maxRounds,
    required this.s,
    required this.perks,
    required this.clash,
    required this.clashOff,
    required this.clanStanding,
    required this.context,
    required this.reinforcement,
    required this.allies,
    this.zoneMultiplier = 1.0,
  });

  // simulateSimFight's arguments ([c] the character, [s] its signs).
  final SimCharacter c;
  final List<MapEntry<String, Map<String, dynamic>>> enemies;
  final int chapter;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> items;
  final Random random;
  final Map<String, ItemSet> itemSets;
  final int newGamePlusCycle;
  final int maxRounds;
  final SignEffects s;
  final PerkEffects perks;
  final bool clash;
  final Set<String> clashOff;
  final num Function(String clanId)? clanStanding;
  final ContextRule? context;
  final Reinforcement reinforcement;
  final List<SimAlly> allies;

  /// The fight's own multiplier on the curve (a zone's tier, a Tower
  /// floor's extra): the fight screen's EncounterModifiers.difficultyMultiplier.
  final double zoneMultiplier;

  // What the fight keeps from round to round, set in _setup (where each
  // is explained), in the order it sets them.
  late final ContextRule? ctx;
  late int ctxRound;
  late final GearEffects gear;
  late int writ;
  late int edge;
  late int crowsHits;
  late bool silencePending;
  late bool silenced;
  late bool hexPending;
  late final Set<int> cursedFaces;
  late int emberCharges;
  late final bool lending;
  late bool secondWindAvailable;
  late final ThornsBank thornsBank;
  late final FractionBank strikeBank;
  late final FractionBank guardBank;
  late final FractionBank mendBank;
  late int phasesEntered;
  late int healsGiven;

  /// What the hero's heals healed this fight, by where they came from (as
  /// the heal rule worked them out, before what full health caps).
  late final Map<HealSource, int> healedBy;
  late bool packBroken;
  late final ProfessionCore core;
  late int fury;
  late int fire;
  late final TrailDeck? trail;
  late final ({List<String> ids, Set<Spec> halved}) held;
  late final Set<Spec> specs;
  late int specRound;
  late final SpecMods mods;
  late double ledgerChain;
  late bool wellRefilled;
  late bool fireLingered;
  late int specGold;
  late final Set<_SimEnemy> specFed;
  late bool broadsideUsed;
  late final int baseMaxHealth;
  late final double packMultiplier;
  late final List<bool> bossFlags;
  late FightGoal goal;
  late List<SquadRole?> roles;
  late final int? tideCap;
  late final Doctrine? doctrine;
  late final List<_SimEnemy> ens;
  late final Map<String, dynamic> availableSkills;
  late final Map<String, int> casts;
  late int manaGained;
  late int potionsUsed;
  late int rounds;
  late final Set<_SimEnemy> fed;

  // What a round keeps between its phases, set afresh each round (see
  // _openRound, _companionsTurn and _answerPartyTurn).
  var playedDefend = false;
  var acted = false;
  var guardArmed = false;
  var stunned = false;
  var block = 0;
  var bestHit = 0;
  var alliesActing = 0;
  var alliesDefending = 0;
  SimAlly? guardian;
  var heroGuards = false;

  // Which of the clash rules are in play.
  bool on(String rule) => clash && !clashOff.contains(rule);

  /// What [raw] healing from [source] heals: the heal rule the fight
  /// screen uses (heal_rules.dart), with the ground's rule of [round]
  /// (default this round) and the fatigue when its clash rule is on. The
  /// simulator has no battlefield conditions, so no shrine.
  int healed(HealSource source, int raw,
      {bool noHealFaces = false, int? round}) {
    final healing = healDealt(
      source: source,
      raw: raw,
      noHealFaces: noHealFaces,
      watchfire: core == ProfessionCore.watchfire,
      roundRule: switch (ctx) {
        final rule? => (amount) => rule.heal(amount, round ?? ctxRound),
        null => null,
      },
      fatigue:
          on('fatigue') ? (amount) => fatiguedHeal(amount, healsGiven++) : null,
    );
    if (healing > 0) healedBy[source] = (healedBy[source] ?? 0) + healing;
    return healing;
  }

  bool has(Spec spec) =>
      specs.contains(spec) &&
      (!held.halved.contains(spec) || halvedPlaysIn(specRound));

  // The fire's burns are Light under the Beacon, and the Road Exorcists'.
  bool burnsLight() =>
      has(Spec.beacon) || (has(Spec.ashenHand) && mods.ashenLight);
  // The Ashen Hand: a burn of the fire gives a mana and lifts an
  // affliction.
  void ashenHand(int burned) {
    c.mana = min(c.maxMana, c.mana + ashenManaPerBurn);
    c.currentHealth =
        min(c.maxHealth, c.currentHealth + (burned * mods.ashenMend).round());
    if (c.statusEffects.isNotEmpty) {
      c.statusEffects = c.statusEffects.skip(mods.ashenCleanse).toList();
    }
  }

  // The signs' lend for the fight (see _setup).
  void lendStats(int sign) {
    c.baseDamage += sign * s.stat(damageStatOf(c.professionId));
    c.strength += sign * s.stat('strength');
    c.dexterity += sign * s.stat('dexterity');
    c.constitution += sign * s.stat('constitution');
    c.intelligence += sign * s.stat('intelligence');
    c.wisdom += sign * s.stat('wisdom');
    c.luck += sign * s.stat('luck');
  }

  DifficultyCurve curveFor(MapEntry<String, Map<String, dynamic>> entry) =>
      difficultyCurveFor(
        chapter: chapter,
        zoneMultiplier: zoneMultiplier,
        newGamePlusCycle: newGamePlusCycle,
        isBoss: isBossEnemy(entry.key, entry.value),
      );

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

  bool allDead() => on('goal') ? goalMet() : ens.every((e) => !e.isAlive);
  void advancePhases() {
    for (final e in ens) {
      phasesEntered += e.advancePhases();
    }
  }

  // A kill-heal sign feeds once on each enemy's fall.
  void feedKills() {
    // The variants on a kill (spec_variants.dart): the Brig-Born's heal,
    // the Drowned Debt's reshuffle, the Barkbleeders' Rot passed on.
    for (final e in ens) {
      if (e.isAlive || !specFed.add(e) || c.isKnockedOut) continue;
      if (mods.killHealShare > 0 && has(Spec.berserker)) {
        c.currentHealth = min(c.maxHealth,
            c.currentHealth + (c.maxHealth * mods.killHealShare).round());
      }
      if (mods.killReshuffles && has(Spec.corsairsEye)) trail?.reshuffle();
      final rot = poisonDamageFor(e.statusEffects);
      if (mods.rotPasses && has(Spec.feverBlade) && rot > 0) {
        final next = ens.where((o) => o.isAlive).firstOrNull;
        if (next != null) {
          next.statusEffects = withRot(next.statusEffects, rot, share: 1);
        }
      }
    }
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
      e.statusEffects = applyStatusEffect(
        e.statusEffects,
        s.playerInflicted(chance.status),
      );
    }
  }

  _SimEnemy? firstLiving() {
    for (final e in ens) {
      if (e.isAlive) return e;
    }
    return null;
  }

  // The Stitch-Thrust: healing past full strikes the foe ([current] and
  // [max]: the health of the one mended; the hero's by default).
  void overhealed(int healing, {int? current, int? full}) {
    if (!has(Spec.stitchThrust)) return;
    final hit = stitchThrust(
        overheal(healing, current ?? c.currentHealth, full ?? c.maxHealth));
    final target = firstLiving();
    if (hit > 0 && target != null) target.health = max(0, target.health - hit);
  }

  // Who a heal mends (heal_target.dart, the game's default): the most
  // wounded member standing, the healer on a tie. 0 is the hero, then the
  // companions in order.
  int healTargetOf(int healer) => defaultHealTarget([
        (current: c.currentHealth, max: c.maxHealth),
        for (final a in allies) (current: a.currentHealth, max: a.maxHealth),
      ], healer);
  int currentOf(int i) =>
      i == 0 ? c.currentHealth : allies[i - 1].currentHealth;
  int maxOf(int i) => i == 0 ? c.maxHealth : allies[i - 1].maxHealth;
  void mend(int i, int heal) {
    if (i == 0) {
      c.currentHealth = min(c.maxHealth, c.currentHealth + heal);
    } else {
      final a = allies[i - 1];
      a.currentHealth = min(a.maxHealth, a.currentHealth + heal);
    }
  }

  bool boss(_SimEnemy e) => isBossEnemy(e.id, e.data);
}

/// The round loop: each round's phases in turn, until a side falls or the
/// rounds run out.
extension _SimFightRun on _SimFight {
  SimFightOutcome run() {
    while (rounds < maxRounds) {
      rounds++;
      final opened = _openRound();
      if (opened != null) return opened;
      if (!stunned && c.diceFaces.isNotEmpty) _heroTurn();
      _companionsTurn();
      final answered = _answerPartyTurn();
      if (answered != null) return answered;
      final struck = _enemyTurn();
      if (struck != null) return struck;
      final closed = _closeRound();
      if (closed != null) return closed;
    }
    return finish(false);
  }
}
