part of '../sim_combat.dart';

// The end of a simulated round (simulateSimFight): the Watchfire's burn,
// the ground's tick, the reinforcements, the crumbling dead, the late
// specialisations; and the end of the fight, which settles the character.

extension _SimFightEnd on _SimFight {
  /// The round's end: the fight's outcome when it ends there, else null.
  SimFightOutcome? _closeRound() {
    final ctx = this.ctx;
    // What is left of the Watchfire burns at the round's end: the first
    // enemy standing, or under the Beacon every one; the Ashen Hand draws
    // a mana and a cleansing from it.
    if (fire > 0) {
      for (final burnTarget in [
        if (has(Spec.beacon))
          ...ens.where((e) => e.isAlive)
        else if (firstLiving() case final first?)
          first,
      ]) {
        final burn =
            (watchfireBurn(fire) * (has(Spec.beacon) ? mods.beaconBurn : 1))
                .round();
        burnTarget.health = max(
            0,
            burnTarget.health -
                (burnsLight()
                    ? burnTarget.takeHit(burn, beaconElement, pierce: true)
                    : burn));
        phasesEntered += burnTarget.advancePhases();
      }
      if (has(Spec.ashenHand)) ashenHand(watchfireBurn(fire));
      // The Wickwardens keep the fire one round more, once it is fed.
      if (mods.fireLingers && has(Spec.beacon) && !fireLingered) {
        fireLingered = true;
      } else {
        fire = 0;
        fireLingered = false;
      }
    }
    // The rising ground takes from both sides (context_rules.dart).
    if (ctx != null) {
      c.currentHealth =
          afterTick(c.currentHealth, ctx.tick(c.maxHealth, rounds));
      for (final e in ens) {
        if (e.isAlive) {
          e.health = afterTick(e.health, ctx.tick(e.maxHealth, rounds));
        }
      }
    }
    // The holder's people join in (context_rules.dart's reinforcements).
    final anyBoss = bossFlags.any((b) => b);
    if (reinforcement == Reinforcement.allies) {
      for (final e in ens) {
        if (e.isAlive) {
          e.health = afterTick(
              e.health, allyStrike(e.maxHealth, rounds, bossFight: anyBoss));
        }
      }
    } else if (reinforcement == Reinforcement.foes) {
      c.currentHealth = afterTick(
          c.currentHealth, foeStrike(c.maxHealth, rounds, bossFight: anyBoss));
    }
    // The dead crumble (foe_kind.dart).
    if (on('kinds')) {
      for (final e in ens) {
        if (e.isAlive) {
          e.health = afterTick(
              e.health, crumble(e.data, e.maxHealth, rounds, boss: boss(e)));
        }
      }
    }
    // The Long Vigil mends above half health.
    if (has(Spec.longVigil) && !c.isKnockedOut) {
      c.currentHealth += mods.vigilMend(c.currentHealth, c.maxHealth);
    }
    // The Tribunal: once a fight, late, an empty Well filled by a third.
    if (has(Spec.censerMage) &&
        mods.wellRefill &&
        !wellRefilled &&
        rounds >= tribunalFromRound &&
        c.mana == 0) {
      wellRefilled = true;
      c.mana = mods.wellRefillOf(c.maxMana);
    }
    feedKills();
    for (final e in ens) {
      e.elementsHit = {};
    }
    if (allDead()) return finish(true);
    // A hold is won by living through the enemies' turns it asks for.
    if (on('goal') && holdComplete(goal, rounds)) return finish(true);
    return null;
  }

  /// Ends the fight, [won] or lost, and settles the character.
  SimFightOutcome finish(bool won) {
    // The Ash Well: what is left of it after a win heals.
    if (core == ProfessionCore.ashWell && won) {
      c.currentHealth = min(
        c.maxHealth,
        c.currentHealth + ashWellHeal(c.mana, c.maxHealth),
      );
      c.mana = 0;
    }
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
    c.roundsFought += rounds;
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
      goldStolen: s.crowsGold(crowsHits) + specGold,
      healedBy: Map.unmodifiable(healedBy),
    );
  }
}
