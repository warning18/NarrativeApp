part of '../sim_combat.dart';

// The enemies' half of a simulated round (simulateSimFight): their answer
// to the party's blows (taunt, execute, the pack's break, morale, the
// watchers' responses, broken wind-ups), then their turn.

extension _SimFightEnemyTurn on _SimFight {
  /// What follows the party's blows, before the enemies move: the fight's
  /// outcome when it ends there, else null.
  SimFightOutcome? _answerPartyTurn() {
    // Taunt: whoever kept the biggest Defend face draws the blows aimed at
    // the others while their guard holds (enemy_intent.dart).
    heroGuards =
        allies.isNotEmpty && playedDefend && block > (guardian?.block ?? 0);
    if (heroGuards) guardian = null;
    // The fight-length rules after the hero's blows (fight_length.dart):
    // the execute line, the pack's leader, a hurt foe's nerve.
    if (on('execute')) {
      for (final e in ens) {
        if (e.isAlive &&
            e.damageThisRound > 0 &&
            executes(
              health: e.health,
              maxHealth: e.maxHealth,
              boss: isBossEnemy(e.id, e.data),
            )) {
          e.health = 0;
        }
      }
    }
    // A boss's escort stands by its boss: no flight in a boss's fight.
    final bossFight = bossFlags.any((b) => b);
    if (on('packBreak') &&
        !bossFight &&
        !packBroken &&
        goal.kind != FightGoalKind.rout) {
      final lead = packLeaderIndex(
        [for (final e in ens) e.maxHealth],
        [for (final e in ens) !boss(e)],
      );
      if (lead != null && !ens[lead].isAlive) {
        packBroken = true;
        for (final e in ens) {
          if (e.isAlive && !boss(e) && random.nextDouble() < packBreakChance) {
            e.health = 0;
          }
        }
      }
    }
    if (on('morale') && !bossFight) {
      for (final e in ens) {
        if (e.isAlive &&
            !boss(e) &&
            // Only people and beasts break (foe_kind.dart).
            (!on('kinds') || canWaver(e.data)) &&
            wavers(health: e.health, maxHealth: e.maxHealth) &&
            random.nextDouble() < moraleFleeChance) {
          e.health = 0;
        }
      }
    }
    advancePhases();
    noteSkittishFlights();
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
              defenders: (playedDefend ? 1 : 0) + alliesDefending,
              acting: (acted ? 1 : 0) + alliesActing,
            )) {
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
    return null;
  }

  /// The enemies' turn: the squad's heals, then each enemy's move. The
  /// fight's outcome when the hero falls, else null.
  SimFightOutcome? _enemyTurn() {
    final ctx = this.ctx;
    // A Pack Leader standing as the turn opens drives the rest harder.
    final leaderStanding =
        ens.any((e) => e.isAlive && e.has(EnemyAffix.packLeader));
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
        friend.health = min(
          friend.maxHealth,
          friend.health + squadHealAmount(friend.maxHealth),
        );
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
        // The Moss Choir: the Rot heals the rogue a share of what it takes.
        if (mods.rotHealShare > 0 && has(Spec.feverBlade)) {
          c.currentHealth = min(c.maxHealth,
              c.currentHealth + (ePoison * mods.rotHealShare).round());
        }
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
            // A claimant's one heal (fight_length.dart): spent, its turn
            // passes.
            if (e.healBlocked) break;
            final before = e.health;
            e.health = min(
              e.maxHealth,
              e.health +
                  scaledEnemyHeal(
                    move.healAmount,
                    maxHealth: e.maxHealth,
                    baseMaxHealth: baseMax,
                  ),
            );
            if (e.health > before) e.noteHeal();
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
          // A Hex, a Silence or a Curse (v1.182) on the hero's die, as the
          // fight screen lays it (fight_dice_rules `_applyTamper`).
          case EnemyIntent.tamper:
            switch (move.tamper) {
              case DiceTamper.hex:
                hexPending = true;
              case DiceTamper.silence:
                silencePending = true;
              case DiceTamper.curse:
                final index =
                    curseTargetFace(c.diceFaces.length, cursedFaces, random);
                if (index == null) break;
                if (emberCharges > 0) {
                  emberCharges--;
                } else {
                  cursedFaces.add(index);
                }
              case DiceTamper.mirror:
              case null:
                break;
            }
          case EnemyIntent.attack:
            break;
        }
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      // A party fight: the blow is aimed at a member standing, drawn at
      // random (the fight screen's _rollMoveAndTargetFor; null: the hero),
      // and taken by the guardian while their guard holds.
      SimAlly? struck;
      if (allies.isNotEmpty) {
        final standing = <SimAlly?>[
          null,
          ...allies.where((a) => !a.isKnockedOut),
        ];
        struck = standing[random.nextInt(standing.length)];
        final keeper = guardian;
        if (heroGuards) {
          if (guardianTakesBlow(
              guardianStanding: !c.isKnockedOut,
              guardianBlock: block,
              aimedAtGuardian: struck == null)) {
            struck = null;
          }
        } else if (keeper != null &&
            guardianTakesBlow(
                guardianStanding: !keeper.isKnockedOut,
                guardianBlock: keeper.block,
                aimedAtGuardian: identical(struck, keeper))) {
          struck = keeper;
        }
      }
      // The Lantern's Writ cancels the first blows aimed at the hero.
      if (struck == null && writ > 0) {
        writ--;
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      if (move.healAmount > 0 && !e.healBlocked) {
        final before = e.health;
        e.health = min(
          e.maxHealth,
          e.health +
              scaledEnemyHeal(
                move.healAmount,
                maxHealth: e.maxHealth,
                baseMaxHealth: baseMax,
              ),
        );
        if (e.health > before) e.noteHeal();
      }
      // A Mirror sends back the round's best hit, as on the fight screen;
      // a pact's curse makes every blow harder while it runs.
      var weakened = applyWeaken(
        move.tamper == DiceTamper.mirror
            ? mirrorDamage(bestPartyHit: bestHit, enemyDamage: e.damage)
            : move.damage,
        e.statusEffects,
      );
      // Frenzied below half health, and a standing Pack Leader's boost to
      // the rest (the fight screen's _incomingDamage, in its order).
      if (e.has(EnemyAffix.frenzied) &&
          e.health < e.maxHealth * frenziedHealthThreshold) {
        weakened = (weakened * frenziedDamageMultiplier).round();
      }
      if (leaderStanding && !e.has(EnemyAffix.packLeader)) {
        weakened = (weakened * packLeaderAllyDamageMultiplier).round();
      }
      var moveDamage = s.enemyDamage(weakened);
      if (on('response')) {
        final answer = responseDamageMultiplier(
          provoked: e.provoked,
          pressing: e.pressing,
        );
        if (answer != 1.0) moveDamage = (moveDamage * answer).round();
        e.provoked = false;
        e.pressing = false;
      }
      if (ctx != null) {
        moveDamage = ctx.blow(
          moveDamage,
          rounds,
          byParty: false,
          element: move.element,
          bossFight: bossFlags.any((b) => b),
          enemyTideCap: tideCap,
        );
      }
      // A beast tires (foe_kind.dart).
      if (on('kinds')) {
        moveDamage = foeBlow(moveDamage, e.data, rounds, boss: boss(e));
      }
      // A companion struck: their dodge, their guard and armor, the
      // affliction past their Wisdom; knocked out at 0, the fight goes on.
      if (struck != null) {
        final a = struck;
        final dodged = random.nextDouble() * 100 <
            dodgeChanceFor(a.dexterity,
                perception: a.perception, professionId: a.professionId);
        final taken = dodged ? 0 : max(0, moveDamage - a.block - a.armor);
        a.block = 0;
        a.currentHealth = max(0, a.currentHealth - taken);
        final inflicted = move.inflictedStatus ??
            (e.has(EnemyAffix.venomous) ? venomousPoison : null);
        if (!dodged && inflicted != null && !a.isKnockedOut) {
          a.statusEffects = applyStatusEffect(
              a.statusEffects, applyWisdomResistance(inflicted, a.wisdom));
        }
        e.statusEffects = tickStatusEffects(e.statusEffects);
        continue;
      }
      final parry = on('parry') ? e.parryBlock : 0;
      // The Briar Guard can't dodge (the draw is made all the same).
      final dodged = random.nextDouble() * 100 <
              dodgeChanceFor(c.dexterity,
                      perception: c.perception, professionId: c.professionId) +
                  gear.dodgeChance &&
          !has(Spec.briarGuard);
      var taken = dodged
          ? 0
          : max(
              0,
              moveDamage -
                  parry -
                  block -
                  c.armor(items, itemSets: itemSets) -
                  s.armor -
                  c.elementalResist(items, move.element),
            );
      // A warrior's Perception blocks half a blow now and then.
      final blockChance =
          blockChanceWith(c.professionId, c.perception, gear.blockChance);
      if (taken > 0 &&
          blockChance > 0 &&
          random.nextDouble() * 100 < blockChance) {
        taken = blockedBlow(taken);
      }
      if (taken >= c.currentHealth &&
          c.currentHealth > 0 &&
          secondWindAvailable) {
        secondWindAvailable = false;
        taken = c.currentHealth - 1;
      }
      // The Watchfire takes the blow first.
      if (fire > 0 && taken > 0) {
        final soaked = min(fire, taken);
        fire -= soaked;
        taken -= soaked;
      }
      if (core == ProfessionCore.fury && taken > 0) fury++;
      // The Briar Guard: what the guard stopped feeds Fury, and a part of
      // it goes back.
      final stopped = dodged ? 0 : min(moveDamage, moveDamage - taken);
      if (has(Spec.briarGuard) && stopped > 0 && taken < moveDamage) {
        if (fury < furyMax) fury++;
        e.health = max(0, e.health - mods.briarBack(stopped));
        // The Quarrymen: a blow sent back breaks the guard.
        if (mods.briarBreaksGuard) e.guard = 0;
        phasesEntered += e.advancePhases();
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
      final thorns = thornsBank.answer(taken, gear.thornsPercent);
      if (thorns > 0) {
        e.health = max(0, e.health - thorns);
        phasesEntered += e.advancePhases();
      }
      block = 0;
      // A Venomous foe's plain blow poisons, unless a parry stopped it
      // outright.
      final inflicted = move.inflictedStatus ??
          (e.has(EnemyAffix.venomous) &&
                  !(parry > 0 && parryStopsBlow(moveDamage, parry))
              ? venomousPoison
              : null);
      if (!dodged && inflicted != null && !c.isKnockedOut) {
        c.statusEffects = applyStatusEffect(
          c.statusEffects,
          applyWisdomResistance(inflicted, c.wisdom),
        );
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
    return null;
  }
}
