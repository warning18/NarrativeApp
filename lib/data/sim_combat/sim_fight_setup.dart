part of '../sim_combat.dart';

// The opening of a simulated fight (simulateSimFight): the context rule,
// the signs' and perks' lend, the hero's core and specialisations, the
// fight's goal and squad, and the enemies as the curve scales them.

extension _SimFightSetup on _SimFight {
  /// Sets the fight's state, before the first round.
  void _setup() {
    final clanStanding = this.clanStanding;
    // The fight's context rule (context_rules.dart): the place's or the
    // foe's, the Tide where none applies; none with the Tide's family off.
    ctx = on('tide') ? (context ?? ContextRule.tide) : null;
    ctxRound = 0;
    gear = s.over(perks.over(c.gearEffects(items, itemSets)));
    // The Sworn boons: blows the Writ still cancels, guards the Compact
    // edge still breaks, hits the Crow's Price has stolen on.
    writ = s.writFace;
    edge = s.compactEdge;
    crowsHits = 0;
    // The enemies' tampering (dice_tamper.dart), as on the fight screen: a
    // Silence laid in their turn hangs over the next round's dice, a Hex
    // waits for the next roll, a Curse marks a face of the die for the rest
    // of the fight (the Ember face lifts as many Curses as it has charges).
    silencePending = false;
    silenced = false;
    hexPending = false;
    cursedFaces = <int>{};
    emberCharges = s.emberFace;
    lending = !s.isEmpty || perks.maxMana > 0;
    secondWindAvailable = gear.secondWind;
    thornsBank = ThornsBank();
    // What the strike, guard and mend signs' shares owe in fractions.
    strikeBank = FractionBank();
    guardBank = FractionBank();
    mendBank = FractionBank();
    phasesEntered = 0;
    // The fight-length rules (fight_length.dart): the hero's heals so far,
    // and whether the pack has broken.
    healsGiven = 0;
    healedBy = {};
    packBroken = false;

    // The hero's core (profession_cores.dart): Fury built up, the
    // Watchfire's fire, the Trail's deck; the Ash Well starts empty.
    core = clashOff.contains('cores')
        ? ProfessionCore.none
        : coreOfProfession(c.professionId);
    fury = 0;
    fire = 0;
    trail = core == ProfessionCore.trail && c.diceFaces.isNotEmpty
        ? TrailDeck(c.diceFaces.length, random)
        : null;
    if (core == ProfessionCore.ashWell) c.mana = 0;
    // The specialisations on the core (specialisations.dart), and what they
    // keep over the fight: the Ledger Knife's chain.
    // A clan grown cold quiets them (specsByStanding): those it halves play
    // the odd rounds only.
    held = clanStanding == null
        ? (ids: c.specIds, halved: const <Spec>{})
        : specsByStanding(c.specIds, clanStanding);
    specs = clashOff.contains('specs') ? <Spec>{} : specsFor(held.ids, core);
    specRound = 0;
    // Their variants, upgrades and ranks (spec_variants.dart).
    mods = specs.isEmpty ? SpecMods.none : SpecMods(held.ids);
    ledgerChain = 0.0;
    wellRefilled = false;
    fireLingered = false;
    specGold = 0;
    specFed = <_SimEnemy>{};
    broadsideUsed = false;

    // The signs' lend for the fight: its stats, a higher max health (full
    // stays full, a running pact may take a share off the top) and mana.
    baseMaxHealth = c.maxHealth;

    if (lending) {
      lendStats(1);
      c.maxHealth = s.maxHealthFor(baseMaxHealth);
      c.currentHealth = s.afterStartCurse(
        SignEffects.healthEntering(
          current: c.currentHealth,
          base: baseMaxHealth,
          fightMax: c.maxHealth,
        ),
        c.maxHealth,
      );
      final full = c.mana >= c.maxMana;
      c.signMaxMana = s.maxMana + perks.maxMana;
      if (full) c.mana = c.maxMana;
    }
    packMultiplier = _packStatMultipliers[enemies.length] ?? 1.0;
    // An Elite is a lone foe (the fight screen's _isElite).
    isElite = elite && enemies.length == 1;
    // v1.212/v1.215: the fight's goal and the pack's squad, rolled as the
    // fight screen rolls them.
    bossFlags = [
      for (final entry in enemies) isBossEnemy(entry.key, entry.value),
    ];
    goal = FightGoal.slay;
    roles = List<SquadRole?>.filled(enemies.length, null);
    if (on('goal')) {
      // An Elite fight rolls no goal (the fight screen's goalEligible).
      goal = rollFightGoal(
        eligible: !bossFlags.any((b) => b) && !isElite,
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
    // A claimant's fight stops the enemies' Tide (fight_length.dart).
    tideCap = fightTideCap([for (final entry in enemies) entry.value]);
    doctrine = on('writ')
        ? doctrineForFight(
            factions: [
              for (final entry in enemies)
                entry.value['faction']?.toString() ?? '',
            ],
            isBoss: bossFlags,
          )
        : null;
    ens = <_SimEnemy>[
      for (var i = 0; i < enemies.length; i++)
        () {
          final entry = enemies[i];
          var health = max(
            1,
            (enemyScaledMaxHealth(
                      (entry.value['maxHealth'] as num?)?.toInt() ?? 1,
                      c.level,
                    ) *
                    curveFor(entry).health *
                    packMultiplier)
                .round(),
          );
          var damage = (scaledDamage(
                    (entry.value['damage'] as num?)?.toInt() ?? 0,
                    c.level,
                  ) *
                  curveFor(entry).damage *
                  packMultiplier)
              .round();
          // The Elite's and the pack leader's stats, as the fight screen's
          // _buildEnemyMember lays them (after the curve, before the
          // squad's roles).
          final affixed =
              i < affixes.length ? affixes[i] : const <EnemyAffix>[];
          if (isElite) {
            health = (health * eliteStatMultiplier).round();
            damage = (damage * eliteStatMultiplier).round();
          }
          if (affixed.contains(EnemyAffix.packLeader)) {
            health = (health * packLeaderHealthMultiplier).round();
          }
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
            ..skills = skills
            ..affixes = affixed
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

    availableSkills = <String, dynamic>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
                false) ||
            c.unlockedSkillIds.contains(entry.key))
          entry.key: entry.value,
    };
    casts = <String, int>{};
    manaGained = 0;
    potionsUsed = 0;
    rounds = 0;

    // A kill-heal sign feeds once on each enemy's fall.
    fed = <_SimEnemy>{};
  }
}
