part of '../sim_combat.dart';

// The party's half of a simulated round (simulateSimFight): the round's
// start (poison, stun, a potion, the telegraphed blows, the spell), the
// hero's die and the companions' dice.

extension _SimFightPartyTurn on _SimFight {
  /// The round's start, through the spell cast: the fight's outcome when
  /// it ends there, else null.
  SimFightOutcome? _openRound() {
    final ctx = this.ctx;
    specRound = rounds;
    ctxRound = rounds;
    silenced = silencePending;
    silencePending = false;
    for (final e in ens) {
      e.damageThisRound = 0;
      e.topHit = 0;
      e.parryBlock = 0;
      e.hitWeakness = false;
    }
    playedDefend = false;
    acted = false;
    // Only a Defend face played this round arms the guard signs.
    guardArmed = false;
    // --- party round start: poison, stun ---
    final poison = poisonDamageFor(c.statusEffects);
    if (poison > 0) c.currentHealth = max(0, c.currentHealth - poison);
    if (c.isKnockedOut) return finish(false);
    stunned = isStunned(c.statusEffects);
    if (stunned) c.statusEffects = tickStatusEffects(c.statusEffects);
    // The companions' round start, as the hero's: poison, then a stun.
    for (final a in allies) {
      a.block = 0;
      a.stunned = false;
      if (a.isKnockedOut) continue;
      final aPoison = poisonDamageFor(a.statusEffects);
      if (aPoison > 0) a.currentHealth = max(0, a.currentHealth - aPoison);
      if (a.isKnockedOut) continue;
      if (isStunned(a.statusEffects)) {
        a.stunned = true;
        a.statusEffects = tickStatusEffects(a.statusEffects);
      }
    }

    if (c.currentHealth < 0.4 * c.maxHealth && c.potions > 0) {
      c.potions--;
      potionsUsed++;
      final drink = healed(
          HealSource.potion, _potionHeal + s.potionBonus + perks.potionBonus,
          round: rounds + 1);
      // The Brimming Draught: what spills past full feeds the fire.
      if (healFeedsFire(
          source: HealSource.potion,
          watchfire: core == ProfessionCore.watchfire,
          brimmingDraught: has(Spec.brimmingDraught))) {
        fire = fireAfterHeal(
          fire: fire,
          healing: drink,
          currentHealth: c.currentHealth,
          maxHealth: c.maxHealth,
          beacon: has(Spec.beacon),
        );
      }
      overhealed(drink);
      c.currentHealth = min(c.maxHealth, c.currentHealth + drink);
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
    block = _castSpellIfWorth(
      c,
      ens,
      items,
      random,
      casts,
      itemSets: itemSets,
      signs: s,
      clash: clash,
      react: on('reaction'),
      round: rounds,
      // The heal rule (heal_rules.dart), the cleric's included: before
      // v1.866 its spells skipped the ground's rule here (not on screen).
      healed: (amount) => healed(HealSource.spell, amount),
      // The Watchfire: a spell's heal past full feeds the fire too.
      onSpellHeal: healFeedsFire(
              source: HealSource.spell,
              watchfire: core == ProfessionCore.watchfire)
          ? (heal) => fire = fireAfterHeal(
                fire: fire,
                healing: heal,
                currentHealth: c.currentHealth,
                maxHealth: c.maxHealth,
                beacon: has(Spec.beacon),
              )
          : null,
      partyBlow: ctx == null
          ? null
          : (raw, element) => ctx.blow(raw, rounds,
              byParty: true,
              element: element,
              bossFight: bossFlags.any((b) => b)),
      ashWell: core == ProfessionCore.ashWell,
      fullWellMultiplier: has(Spec.burdenBearer) ? mods.burdenMultiplier : 1,
      fullWellHealShare: has(Spec.burdenBearer) ? mods.burdenHealShare : 0,
      spellLifeShare: has(Spec.tempestToll) ? mods.tempestShare : 0,
      spellDiscount: has(Spec.tempestToll) ? mods.spellDiscount : 0,
      fireReactionTimes: has(Spec.doubleKindling) ? 2 : 1,
      lingeringHex: has(Spec.lingeringHex),
      onSpellHit: has(Spec.tempestToll) && mods.spellsSteal
          ? () => specGold += ledgerStealGold
          : null,
    );
    // A sign's block for the whole party as the fight opens.
    if (rounds == 1) block += s.partyStartBlock;
    // The round's best hit, what a Mirror sends back: the spell's so far
    // (it hits each enemy once), then the die's.
    bestHit = ens.fold<int>(0, (best, e) => max(best, e.damageThisRound));
    advancePhases();
    noteSkittishFlights();
    feedKills();
    if (allDead()) return finish(true);
    return null;
  }

  /// The hero's die: rolled, shaped by the signs, cores and
  /// specialisations, and played.
  void _heroTurn() {
    final ctx = this.ctx;
    final trail = this.trail;
    acted = true;
    DiceFaceResult face;
    var verdict = false, firstOfRun = false;
    var rolls = 0;
    var redraw = false;
    // Whether [f] lands blank under the Curses and this round's Silence
    // (a cursed blank strikes; a silenced skill face of its own is blank).
    bool blank(DiceFaceResult f) =>
        _tamperedFace(f, cursedFaces, silenced).type == 'Empty';
    // With [rerollWeakFaces], a face worth less to the hero than the die's
    // mean is rolled again too (simFaceValue; the round's last roll kept).
    final caster = c.knownSpells.isNotEmpty;
    final mean = rerollWeakFaces
        ? simDieValue(c.diceFaces, c.diceSkillAssignments, skills,
            damage: c.baseDamage, caster: caster)
        : 0.0;
    bool weak(DiceFaceResult f) =>
        rerollWeakFaces &&
        simFaceValue(c.diceFaces, f.faceIndex, c.diceSkillAssignments, skills,
                damage: c.baseDamage, caster: caster) <
            mean;
    do {
      rolls++;
      if (trail != null) {
        final index = trail.draw();
        face = faceFromJson(c.diceFaces[index], index);
        verdict = trail.drewVerdict;
        firstOfRun = trail.drewFirst;
      } else {
        face = rollDie(c.diceFaces, random);
      }
      // A Hex laid last turn rolls the first die to land again at once
      // (a plain roll, the Trail's included), unless it landed Steady.
      if (rolls == 1 && hexPending) {
        hexPending = false;
        final steady = _landsSteady(c, face, s, cursedFaces, silenced);
        if (hexVictim({if (!steady) 'hero': 0}) != null) {
          face = rollDie(c.diceFaces, random);
        }
      }
      // The Second Broadside: once a fight, a face that would not strike
      // goes back, and the Trail draws again.
      redraw = trail != null &&
          has(Spec.secondBroadside) &&
          !broadsideUsed &&
          !blank(face) &&
          !faceStrikes(face.type);
      if (redraw) broadsideUsed = true;
    } while ((blank(face) || redraw || weak(face)) && rolls < _maxRolls);
    face = applyFaceAssignment(
      face,
      c.diceFaces[face.faceIndex],
      c.diceSkillAssignments[face.faceIndex.toString()],
    );
    // The Writ (v1.212): every third round the skill faces fall silent.
    if (doctrine?.rule == DoctrineRule.writ &&
        writSilencesRound(rounds) &&
        face.type == 'Skill') {
      face = silencedFace(face);
    }
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
    // The Berserker's Attack faces are Pain strikes.
    if (has(Spec.berserker) && face.type == 'Attack') {
      face = face.withKeywords({...face.keywords, FaceKeyword.pain});
    }
    // The enemies' tampering, last as on the fight screen: a Curse on the
    // face, then the round's Silence.
    face = _tamperedFace(face, cursedFaces, silenced);
    playedDefend = face.type == 'Defend';
    final attack = face.type == 'Attack';
    if (face.hasKeyword(FaceKeyword.steady) &&
        (attack || face.type == 'Defend' || face.type == 'Heal')) {
      face = face.withValue(face.value + steadyBonus);
    }
    // The guard, mend and spell signs on the face's number.
    face = switch (face.type) {
      'Defend' => face.withValue(s.guardValue(face.value, bank: guardBank)),
      'Heal' => face.withValue(s
          .mendValue(face.value, wisdomHealBonusFor(c.wisdom), bank: mendBank)),
      'Mana' => face.withValue(s.manaValue(face.value)),
      _ => face,
    };
    final skillId =
        face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
    var element =
        faceHitElement(face.type, face.element, availableSkills[skillId]);
    var damageBase = c.casterDamage(items, element, itemSets: itemSets);
    if (attack || face.type == 'Skill') {
      damageBase = s.strikeBase(
        damageBase,
        face.value,
        attackFace: attack,
        bank: strikeBank,
        percent: s.strikePercentFor(
          attackFace: attack,
          currentHealth: c.currentHealth,
          maxHealth: c.maxHealth,
          firstRound: rounds == 1,
        ),
      );
    }
    // The Relicbreaker's mana makes a sure critical of the strike.
    final sureCrit = has(Spec.relicbreaker) &&
        c.mana >= mods.relicThreshold &&
        (attack || face.type == 'Skill');
    if (sureCrit) c.mana -= mods.relicThreshold;
    PlayerActionResult rollFace({bool sure = false}) => resolvePlayerFace(
          face,
          availableSkills,
          damageBase,
          activeEffects: c.statusEffects,
          wisdomHealBonus: wisdomHealBonusFor(c.wisdom),
          wisdomManaBonus: wisdomManaBonusFor(c.wisdom),
          luck: c.luck,
          random: random,
          critChanceBonus: gear.critChance +
              perceptionCritBonus(c.professionId, c.perception) +
              ledgerChain,
          forceCritical: sure,
        );
    var result = rollFace(sure: sureCrit);
    // The cores on the face (profession_cores.dart), and their
    // specialisations (specialisations.dart).
    var crits = 0;
    var pitched = false;
    if (core == ProfessionCore.flurry && result.damageDealt > 0) {
      final second = rollFace();
      // The Pitch Hand: the second hit slows its target.
      pitched = has(Spec.pitchHand) && second.damageDealt > 0;
      int hit(PlayerActionResult r) {
        if (!r.isCritical) {
          if (has(Spec.ledgerKnife)) ledgerChain += mods.ledgerStep;
          return r.damageDealt;
        }
        crits++;
        if (!has(Spec.ledgerKnife)) return r.damageDealt;
        if (mods.critsSteal) specGold += ledgerStealGold;
        if (!mods.chainKept) ledgerChain = 0;
        return ledgerCritical(r.damageDealt);
      }

      result = coreResult(
        result,
        damage: flurryDamage(hit(result), hit(second)),
      );
    }
    var heavy = false;
    if (core == ProfessionCore.fury && result.damageDealt > 0) {
      if (fury >= furyMax) {
        result = coreResult(
          result,
          damage: (result.damageDealt *
                  (has(Spec.lanternVanguard)
                      ? vanguardHeavyMultiplier
                      : furyHeavyMultiplier))
              .round(),
        );
        fury = 0;
        heavy = true;
      } else {
        fury++;
      }
    }
    // The weak links' Fury: the Vigil's Defend face, the Penitents' Mana
    // face.
    if (core == ProfessionCore.fury &&
        fury < furyMax &&
        ((has(Spec.standfast) && face.type == 'Defend') ||
            (has(Spec.burningPenance) && face.type == 'Mana'))) {
      fury++;
    }
    // The Lantern Vanguard's heavy blow is Fire and Pierces; the
    // Corsair's Verdict counts double and Pierces.
    var piercing = face.hasKeyword(FaceKeyword.pierce);
    if (heavy && has(Spec.lanternVanguard)) {
      element = vanguardElement;
      piercing = true;
    }
    if (verdict && has(Spec.corsairsEye) && result.damageDealt > 0) {
      result = coreResult(
        result,
        damage: (result.damageDealt * mods.verdict).round(),
      );
      piercing = true;
    }
    if (crits > 0 && has(Spec.relicbreaker)) {
      final before = c.mana;
      c.mana = min(c.maxMana, c.mana + crits * mods.relicMana);
      manaGained += c.mana - before;
      c.currentHealth = min(
          c.maxHealth,
          c.currentHealth +
              (c.maxHealth * mods.relicHealShare * crits).round());
    }
    if (core == ProfessionCore.ashWell && result.manaGained > 0) {
      result = coreResult(
        result,
        mana: result.manaGained * ashWellManaMultiplier,
      );
    }
    // Pain: the strike hits for double and costs its roller.
    final pain = face.hasKeyword(FaceKeyword.pain) && result.damageDealt > 0;
    var dealt =
        pain ? result.damageDealt * painDamageMultiplier : result.damageDealt;
    if (ctx != null) {
      dealt = ctx.blow(dealt, rounds,
          byParty: true, element: element, bossFight: bossFlags.any((b) => b));
    }
    if (pain) {
      final cost = painCost(
        maxHealth: c.maxHealth,
        currentHealth: c.currentHealth,
      );
      c.currentHealth -= cost;
      // The Berserker's life paid feeds Fury (and, Tar-Hands, bleeds the
      // enemy).
      if (has(Spec.berserker) && cost > 0 && core == ProfessionCore.fury) {
        fury = min(furyMax, fury + mods.painFury);
        if (mods.painBleeds) dealt += cost;
      }
    }
    final target = on('squad') ? _focusTarget(ens) : firstLiving();
    // The Compact edge breaks a raised guard outright, while it lasts.
    if (target != null &&
        dealt > 0 &&
        edge > 0 &&
        target.guard > 0 &&
        !piercing) {
      edge--;
      target.guard = 0;
    }
    if (target != null && dealt > 0) {
      final pierce = piercing;
      // An Armored foe shrugs off a point of an Attack face (not a Pierce).
      final struck = pierce
          ? dealt
          : strikeDamageAfterAffixes(dealt, face.type,
              armored: target.has(EnemyAffix.armored));
      final landed = clash
          ? target.landHit(
              struck,
              element,
              rounds,
              pierce: pierce,
              react: on('reaction'),
            )
          : target.takeHit(struck, element, pierce: pierce);
      if (landed > 0) crowsHits++;
      if (!clash) target.health = max(0, target.health - landed);
      if (pitched && target.isAlive) {
        target.statusEffects =
            applyStatusEffect(target.statusEffects, pitchSlow);
      }
      // Against an Evil foe the Vanguard's heavy blow heals; the
      // Inquisition's weakens.
      if (heavy && has(Spec.lanternVanguard)) {
        if (isEvilFoe(target.data)) {
          c.currentHealth = min(c.maxHealth,
              c.currentHealth + (landed * mods.vanguardEvilHeal).round());
        }
        if (mods.vanguardWeakens && target.isAlive) {
          target.statusEffects =
              applyStatusEffect(target.statusEffects, specWeaken);
        }
      }
      // The Fever Blade's Rot, a stack for each critical hit.
      if (has(Spec.feverBlade) && target.isAlive) {
        for (var i = 0; i < crits; i++) {
          target.statusEffects =
              mods.withRotOf(target.statusEffects, (landed / 2).round());
        }
      }
      // The Trail's Verdict stuns (Trapwright: the Scaffolders a second
      // foe, the Quarrymen through the guard); its first face poisons
      // (Fen Guide; the Heron's Wake slows too).
      if (verdict && has(Spec.trapwright)) {
        final stunned = [
          target,
          ...ens.where((e) => !identical(e, target)),
        ].where((e) => e.isAlive).take(mods.stunTargets);
        for (final e in stunned) {
          e.statusEffects = applyStatusEffect(e.statusEffects, mods.stun);
          if (mods.trapBreaksGuard) e.guard = 0;
        }
      }
      if (target.isAlive && firstOfRun && has(Spec.fenGuide)) {
        target.statusEffects = applyStatusEffect(
            target.statusEffects, mods.fenPoisonFor((landed / 2).round()));
        if (mods.fenSlows) {
          target.statusEffects =
              applyStatusEffect(target.statusEffects, specWeaken);
        }
      }
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
            other.health = max(
              0,
              other.health - other.takeHit(splash, element),
            );
          }
        }
      }
      if (attack && landed > 0) rollStatuses(s.strikeStatuses, target);
    }
    final inflicted = result.inflictedStatus;
    if (target != null && inflicted != null && target.isAlive) {
      target.statusEffects = applyStatusEffect(
        target.statusEffects,
        s.playerInflicted(inflicted),
      );
    }
    // A heal mends the most wounded member standing (heal_target.dart),
    // and what heals past full counts on them.
    final healTo = result.healingDone > 0 &&
            result.damageDealt == 0 &&
            result.blockAmount == 0
        ? healTargetOf(0)
        : 0;
    final mended = healTo < 0 ? 0 : healTo;
    // A mend sign turns healing past full into block, and lifts
    // afflictions.
    if (face.type == 'Heal' && result.healingDone > 0) {
      block += s.shieldFromOverheal(
        healing: result.healingDone,
        currentHealth: currentOf(mended),
        maxHealth: maxOf(mended),
      );
      if (s.mendCleanse > 0) {
        c.statusEffects = c.statusEffects.skip(s.mendCleanse).toList();
      }
    }
    // The heal rule (heal_rules.dart): the Anvil-Deaf's wall takes no Heal
    // faces; the Watchfire's heals from the die don't tire, they are its
    // fire.
    final heal = healed(HealSource.face, result.healingDone,
        noHealFaces:
            mods.noHealFaces && has(Spec.briarGuard) && face.type == 'Heal',
        round: rounds);
    if (core == ProfessionCore.watchfire && heal > 0) {
      // Every heal from the die burns (under the Beacon, every enemy);
      // the part past full feeds the fire.
      for (final burnTarget in [
        if (has(Spec.beacon))
          ...ens.where((e) => e.isAlive)
        else if (firstLiving() case final first?)
          first,
      ]) {
        final burn = (heal *
                watchfireHealBurnShare *
                (has(Spec.beacon) ? mods.beaconBurn : 1))
            .round();
        burnTarget.health = max(
          0,
          burnTarget.health -
              (burnsLight()
                  ? burnTarget.takeHit(burn, beaconElement, pierce: true)
                  : burn),
        );
      }
      if (has(Spec.ashenHand)) {
        ashenHand((heal * watchfireHealBurnShare).round());
      }
      fire = fireAfterHeal(
        fire: fire,
        healing: heal,
        currentHealth: currentOf(mended),
        maxHealth: maxOf(mended),
        beacon: has(Spec.beacon),
      );
    }
    overhealed(heal, current: currentOf(mended), full: maxOf(mended));
    mend(mended, heal);
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
    // The Last Watch: a Defend face feeds the fire.
    if (face.type == 'Defend' &&
        has(Spec.longVigil) &&
        mods.defendFeedsFire &&
        result.blockAmount > 0) {
      fire = min(
          (c.maxHealth * watchfireCapShare).round(), fire + result.blockAmount);
    }
    // A Defend face arms the guard signs, and may heal.
    if (face.type == 'Defend' && result.blockAmount > 0) {
      guardArmed = !s.isEmpty;
      c.currentHealth = min(c.maxHealth, c.currentHealth + s.guardHeal);
    }
    if (result.manaGained > 0) {
      final before = c.mana;
      final overflow = c.mana + result.manaGained - c.maxMana;
      c.mana = min(c.maxMana, c.mana + result.manaGained);
      manaGained += c.mana - before;
      // The Censer Mage: mana past full burns the enemy (the
      // Inquisition's smoke weakens it).
      final burnTarget = firstLiving();
      if (has(Spec.censerMage) && overflow > 0 && burnTarget != null) {
        burnTarget.health = max(
            0, burnTarget.health - mods.censerBurnFor(overflow, damageBase));
        if (mods.censerWeakens && burnTarget.isAlive) {
          burnTarget.statusEffects =
              applyStatusEffect(burnTarget.statusEffects, specWeaken);
        }
        phasesEntered += burnTarget.advancePhases();
      }
    }
    c.statusEffects = tickStatusEffects(c.statusEffects);
  }

  // The companions' turns (sim_companions.dart), as the fight screen
  // plays an auto-aiming party: each rolls their signature die (again on
  // a blank face, as the hero), the face cast with their own skills at
  // their damage on the enemy the hero aims at; a Heal mends them, a
  // Defend guards them, a Mana face fills the shared pool.
  void _companionsTurn() {
    final ctx = this.ctx;
    alliesActing = 0;
    alliesDefending = 0;
    guardian = null;
    for (final a in allies) {
      if (a.isKnockedOut || a.stunned || a.faces.isEmpty) continue;
      alliesActing++;
      var face = rollDie(a.faces, random);
      for (var r = 1; face.type == 'Empty' && r < _maxRolls; r++) {
        face = rollDie(a.faces, random);
      }
      face = applyFaceAssignment(face, a.faces[face.faceIndex], null);
      if (doctrine?.rule == DoctrineRule.writ &&
          writSilencesRound(rounds) &&
          face.type == 'Skill') {
        face = silencedFace(face);
      }
      a.facesPlayed[face.type] = (a.facesPlayed[face.type] ?? 0) + 1;
      final skillId =
          face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
      final element =
          faceHitElement(face.type, face.element, a.skills[skillId]);
      if (face.type == 'Skill') {
        a.skillsCast[skillId] = (a.skillsCast[skillId] ?? 0) + 1;
      }
      final result = resolvePlayerFace(
        face,
        a.skills,
        a.damage,
        activeEffects: a.statusEffects,
        wisdomHealBonus: wisdomHealBonusFor(a.wisdom),
        wisdomManaBonus: wisdomManaBonusFor(a.wisdom),
        luck: a.luck,
        random: random,
        critChanceBonus: perceptionCritBonus(a.professionId, a.perception),
        armor: a.armor,
      );
      var dealt = face.hasKeyword(FaceKeyword.pain) && result.damageDealt > 0
          ? result.damageDealt * painDamageMultiplier
          : result.damageDealt;
      if (ctx != null) {
        dealt = ctx.blow(dealt, rounds,
            byParty: true,
            element: element,
            bossFight: bossFlags.any((b) => b));
      }
      final target = on('squad') ? _focusTarget(ens) : firstLiving();
      if (target != null && dealt > 0) {
        final pierce = face.hasKeyword(FaceKeyword.pierce);
        final struck = pierce
            ? dealt
            : strikeDamageAfterAffixes(dealt, face.type,
                armored: target.has(EnemyAffix.armored));
        final landed = clash
            ? target.landHit(struck, element, rounds,
                pierce: pierce, react: on('reaction'))
            : target.takeHit(struck, element, pierce: pierce);
        if (!clash) target.health = max(0, target.health - landed);
        a.damageDealt += landed;
        bestHit = max(bestHit, landed);
        if (element != 'None') target.elementsHit.add(element);
      }
      final inflicted = result.inflictedStatus;
      if (target != null && inflicted != null && target.isAlive) {
        target.statusEffects =
            applyStatusEffect(target.statusEffects, inflicted);
      }
      var heal = ctx?.heal(result.healingDone, rounds) ?? result.healingDone;
      if (on('fatigue') && heal > 0) heal = fatiguedHeal(heal, a.healsGiven++);
      // A companion's heal mends the most wounded member standing too.
      final allyIndex = allies.indexOf(a) + 1;
      final allyHealTo =
          heal > 0 && result.damageDealt == 0 && result.blockAmount == 0
              ? healTargetOf(allyIndex)
              : allyIndex;
      mend(allyHealTo < 0 ? allyIndex : allyHealTo, heal);
      a.block += result.blockAmount;
      if (face.type == 'Defend' && result.blockAmount > 0) {
        alliesDefending++;
        if (guardian == null || a.block > guardian!.block) guardian = a;
      }
      if (result.manaGained > 0) {
        final before = c.mana;
        c.mana = min(c.maxMana, c.mana + result.manaGained);
        manaGained += c.mana - before;
      }
      a.statusEffects = tickStatusEffects(a.statusEffects);
    }
  }
}
