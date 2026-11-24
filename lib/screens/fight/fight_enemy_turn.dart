part of '../fight_screen.dart';

/// The enemies' side of a round: their moves rolled ahead, hits landed on
/// them, stances, boss phases and their turn (see fight_rounds.dart).
extension _FightEnemyTurn on _FightScreenState {
  /// Pre-rolls and caches [enemy]'s move+target for its NEXT turn -- called
  /// once per enemy at fight start (see [_startFight]), and again after
  /// every enemy-turn-phase resolves (see [_takeEnemyTurn]), so the
  /// upcoming party round can show a Perception/Guile-gated preview of
  /// exactly what's coming. Deliberately skipped for a
  /// [_EnemyMember.hasReactiveMoves] enemy: pre-rolling immediately after
  /// its own turn would hand it the SAME elements-hit set that already
  /// justified that turn's OnHitByElement reaction, risking a stale
  /// double-fire on a hit that already fired -- rather than resolve that
  /// ambiguity, that one enemy (iron_golem is the only current example)
  /// simply isn't pre-rolled at all: it live-rolls at execution time
  /// exactly as every enemy did before telegraphing existed, and shows no
  /// telegraph.
  void _preRollMoveFor(_EnemyMember enemy, Map<String, dynamic> skills) {
    if (!enemy.isAlive) {
      enemy.pendingMove = null;
      return;
    }
    // A wound-up blow is already decided: it's what comes next.
    if (enemy.chargedBlow != null) {
      final conscious = _party.where((m) => !m.isKnockedOut).toList();
      enemy.pendingMove = _PendingEnemyMove(
        move: _releaseOf(enemy),
        targetId: conscious.isEmpty
            ? _party.first.id
            : conscious[_random.nextInt(conscious.length)].id,
        release: true,
      );
      return;
    }
    if (enemy.hasReactiveMoves) {
      enemy.pendingMove = null;
      enemy.nextMove = null;
      return;
    }
    // Open Eyes: the move after is rolled too, and comes next.
    if (_signs.intentLookahead > 0) {
      enemy.pendingMove =
          enemy.nextMove ?? _rollMoveAndTargetFor(enemy, skills);
      enemy.nextMove = _rollMoveAndTargetFor(enemy, skills);
      return;
    }
    enemy.pendingMove = _rollMoveAndTargetFor(enemy, skills);
  }

  /// The blow [enemy]'s wind-up releases: the charged move as a plain
  /// attack, with its own landing line.
  EnemyMoveResult _releaseOf(_EnemyMember enemy) {
    final charged = enemy.chargedBlow!;
    final lang = ref.read(appLanguageProvider);
    return EnemyMoveResult(
      damage: charged.damage,
      message: charged.releaseMessage.isNotEmpty
          ? charged.releaseMessage
          : '${enemy.displayName} ${trFor(lang, 'charge_release_suffix')}',
      inflictedStatus: charged.inflictedStatus,
      element: charged.element,
      skillId: charged.skillId,
    );
  }

  /// Lands a party hit of [damage] and [element] on [enemy] (v1.162): its
  /// weakness or resistance first, then its raised guard. Returns what gets
  /// through, notes it towards breaking a wind-up, and reveals the
  /// weakness/resistance on the enemy's card with a log line the first
  /// time.
  ///
  /// [edge]: the player's own strike, which a Compact edge (see signs.dart's
  /// compactEdge) breaks a raised guard with, outright, while it lasts.
  int _landHitOnEnemy(_EnemyMember enemy, int damage, String element,
      List<_LogEntry> entries, AppLanguage lang,
      {bool pierce = false, bool edge = false}) {
    if (damage <= 0) return damage;
    // The Tide grows the party's blows from its round on, and the place's
    // rule with it (context_rules.dart).
    damage = _length.rule.blow(damage, _roundsStarted,
        byParty: true,
        element: element,
        bossFight: _enemies.any((e) => isBossEnemy(e.enemyId, e.data)));
    final multiplier = elementMultiplierFor(enemy.data, element);
    var landed = damageAfterElement(damage, enemy.data, element);
    if (multiplier != 1.0) {
      if (multiplier > 1.0) {
        enemy.hitWeaknessThisRound = true;
        _weaknessHits++;
      }
      if (enemy.revealedElements.add(element)) {
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, multiplier > 1.0 ? 'weak_to_suffix' : 'resists_suffix')} '
          '${elementLabel(element, lang)}.',
          _LogKind.info,
        ));
      }
    }
    // The Compact edge breaks the whole guard before the blow lands.
    if (enemy.guard > 0 && !pierce && edge && _edgeCharges > 0) {
      _edgeCharges--;
      enemy.guard = 0;
      entries.add(_LogEntry(
        '${enemy.displayName} ${trFor(lang, 'sign_log_edge')}',
        _LogKind.playerDamage,
      ));
    }
    // A Pierce goes straight through a raised guard (see face_keywords).
    if (enemy.guard > 0 && !pierce) {
      final through = damageThroughGuard(landed, enemy.guard);
      final soaked = landed - through.damage;
      enemy.guard = through.guard;
      landed = through.damage;
      if (soaked > 0) {
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, 'guard_soaks_suffix')} $soaked.',
          _LogKind.info,
        ));
      }
    }
    // A standing guard covers its pack (v1.215, see squad.dart).
    if (landed > 0 &&
        !pierce &&
        enemy.role != SquadRole.guard &&
        _enemies
            .any((e) => e != enemy && e.isAlive && e.role == SquadRole.guard)) {
      final cut = (landed * guardCoverShare).round();
      if (cut > 0) {
        landed -= cut;
        entries.add(_LogEntry(
          trFor(lang, 'squad_guard_covers')
              .replaceAll('{name}', enemy.displayName)
              .replaceAll('{n}', '$cut'),
          _LogKind.info,
        ));
      }
    }
    enemy.damageThisRound += landed;
    return landed;
  }

  /// Breaks every wind-up the party answered hard enough this round (see
  /// chargeBroken): the held blow is lost and the enemy loses its next
  /// turn.
  void _checkChargeBreaks(List<_LogEntry> entries, AppLanguage lang) {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.chargedBlow == null) continue;
      if (!chargeBroken(
        damageThisRound: enemy.damageThisRound,
        maxHealth: enemy.maxHealth,
        stunned: isStunned(enemy.statusEffects),
        hitWeakness: enemy.hitWeaknessThisRound,
      )) {
        continue;
      }
      enemy.chargedBlow = null;
      enemy.staggered = true;
      enemy.pendingMove = null;
      _chargesBroken++;
      _fx(VfxStyle.stun, _enemyCardKey(enemy.key), delayMs: 250, big: true);
      entries.add(_LogEntry(
        '${enemy.displayName} ${trFor(lang, 'charge_broken_suffix')}',
        _LogKind.playerDamage,
      ));
    }
  }

  /// A turn [enemy] spends on something other than a swing: mending
  /// itself, raising its guard, winding up, or rallying its pack.
  void _resolveEnemyStance(
      _EnemyMember enemy, EnemyMoveResult move, AppLanguage lang, int delay,
      {required String targetId, required Map<String, dynamic> skills}) {
    final key = _enemyCardKey(enemy.key);
    switch (move.intent) {
      case EnemyIntent.tamper:
        _applyTamper(enemy, move, targetId, lang, delay);
      case EnemyIntent.heal:
        // A claimant's one heal spent (fight_length.dart): its turn passes.
        if (enemy.healBlocked) return;
        final amount = scaledEnemyHeal(move.healAmount,
            maxHealth: enemy.maxHealth, baseMaxHealth: enemy.baseMaxHealth);
        final healed = min(amount, enemy.maxHealth - enemy.currentHealth);
        if (healed > 0) enemy.noteHeal(skills);
        _fx(VfxStyle.heal, key,
            delayMs: delay, text: '+$healed', textKind: VfxTextKind.heal);
        _update(() {
          enemy.currentHealth += healed;
          _log.add(_LogEntry(
            '${move.message} ${enemy.displayName} '
            '${trFor(lang, 'enemy_recovers_word')} $healed '
            '${trFor(lang, 'hp_label')}.',
            _LogKind.info,
          ));
        });
      case EnemyIntent.guard:
        _fx(VfxStyle.shield, key,
            delayMs: delay,
            text: '+${move.guardAmount}',
            textKind: VfxTextKind.block);
        _update(() {
          enemy.guard = move.guardAmount;
          _log.add(_LogEntry(
            '${move.message} ${enemy.displayName} '
            '${trFor(lang, 'enemy_guards_word')} ${move.guardAmount}.',
            _LogKind.info,
          ));
        });
      case EnemyIntent.charge:
        _fx(VfxStyle.phase, key, delayMs: delay);
        _update(() {
          enemy.chargedBlow = move;
          _log.add(_LogEntry(
            '${move.message} ${enemy.displayName} '
            '${trFor(lang, 'enemy_winds_up_suffix')}',
            _LogKind.enemyDamage,
          ));
        });
      case EnemyIntent.rally:
        var rallied = 0;
        for (final other in _enemies) {
          if (!other.isAlive || other.rallyStacks >= maxRallyStacks) continue;
          other.damage = (other.damage * (1 + move.rallyPercent / 100)).round();
          other.rallyStacks++;
          rallied++;
          _fx(VfxStyle.shout, _enemyCardKey(other.key), delayMs: delay);
        }
        _update(() {
          _log.add(_LogEntry(
            rallied == 0
                ? '${move.message} ${trFor(lang, 'rally_spent_message')}'
                : '${move.message} ${trFor(lang, 'enemy_rallies_message')} '
                    '(+${move.rallyPercent}%)',
            _LogKind.enemyDamage,
          ));
        });
      case EnemyIntent.attack:
        break;
    }
  }

  /// Plays every boss phase a living enemy has crossed since the last
  /// check (see [bossPhaseIndexFor]): the transition's heal, cleanse and
  /// enrage apply at once, its new moves join the enemy's list, and the
  /// enemy's telegraphed move is re-rolled so the new stance shows on its
  /// very next turn. Appends each announcement to [entries].
  void _advanceBossPhases(
      List<_LogEntry> entries, AppLanguage lang, Map<String, dynamic> skills) {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.phases.isEmpty) continue;
      final target =
          bossPhaseIndexFor(enemy.phases, enemy.currentHealth, enemy.maxHealth);
      var entered = false;
      while (enemy.phaseIndex < target) {
        final phase = enemy.phases[enemy.phaseIndex];
        enemy.phaseIndex++;
        entered = true;
        _phasesCrossed++;
        // A claimant mends itself once a fight (fight_length.dart).
        final healed = enemy.healBlocked
            ? 0
            : healthAfterPhaseHeal(
                    phase, enemy.currentHealth, enemy.maxHealth) -
                enemy.currentHealth;
        enemy.currentHealth += healed;
        if (phase.cleanse) enemy.statusEffects = [];
        enemy.damage = (enemy.damage * phase.damageMultiplier).round();
        enemy.data = enemyDataInPhase(enemy.data, phase);
        if (healed > 0 || enemy.healBlocked) enemy.noteHeal(skills);
        final details = <String>[
          if (healed > 0)
            '${trFor(lang, 'phase_heals_prefix')} $healed ${trFor(lang, 'hp_label')}',
          if (phase.cleanse) trFor(lang, 'phase_cleansed_label'),
          if (phase.damageMultiplier > 1.0) trFor(lang, 'phase_enraged_label'),
        ];
        entries.add(_LogEntry(
          '${enemy.displayName} — ${phase.nameFor(lang)}: '
          '${phase.messageFor(lang)}'
          '${details.isEmpty ? '' : ' (${details.join(', ')})'}',
          _LogKind.phase,
        ));
      }
      if (entered) {
        enemy.nextMove = null;
        _preRollMoveFor(enemy, skills);
        _fx(VfxStyle.phase, _enemyCardKey(enemy.key), delayMs: 300, big: true);
      }
    }
  }

  /// [_advanceBossPhases] straight into the log, for the enemy-turn
  /// paths that write the log as they go.
  void _advancePhasesNow(AppLanguage lang, Map<String, dynamic> skills) {
    final entries = <_LogEntry>[];
    _advanceBossPhases(entries, lang, skills);
    if (entries.isEmpty) return;
    _update(() => _log.addAll(entries));
  }

  /// Rolls [enemy]'s move+target — shared by [_preRollMoveFor] (ahead of
  /// time) and [_takeEnemyTurn] (live, for a [_EnemyMember.hasReactiveMoves]
  /// enemy that's never pre-rolled). Reads [_EnemyMember.elementsHitThisRound]
  /// as of the moment it's called, so calling it live at execution time
  /// (rather than ahead of time) is exactly what every enemy did before
  /// pre-rolling existed.
  _PendingEnemyMove _rollMoveAndTargetFor(
      _EnemyMember enemy, Map<String, dynamic> skills) {
    final lang = ref.read(appLanguageProvider);
    // Rolled un-Weakened: a Weaken is applied at execution time in
    // [_takeEnemyTurn] against the enemy's effects as they stand THEN, so a
    // Weaken the party lands this round cuts the very next hit rather than
    // the one after (a pre-rolled move baked the debuff in a turn late).
    final move = resolveEnemyMove(
      enemy: {...enemy.data, 'damage': enemy.damage},
      skills: skills,
      enemyCurrentHealth: enemy.currentHealth,
      enemyMaxHealth: enemy.maxHealth,
      random: _random,
      language: lang,
      elementsHitThisRound: enemy.elementsHitThisRound,
    );
    final conscious = _party.where((m) => !m.isKnockedOut).toList();
    final targetId = conscious[_random.nextInt(conscious.length)].id;
    return _PendingEnemyMove(move: move, targetId: targetId);
  }

  /// Resolves every living enemy's turn once each, in [_enemies] order --
  /// each independently poison-ticks, checks its own Stun, then applies its
  /// own pre-rolled move (see [_preRollMoveFor]) against its own target,
  /// exactly mirroring how a solo enemy's single turn always worked, just
  /// looped once per pack member. An enemy with no cached
  /// [_EnemyMember.pendingMove] (a [_EnemyMember.hasReactiveMoves] enemy)
  /// rolls its move+target on the spot instead, exactly as every enemy did
  /// before telegraphing existed. A cached target that's no longer valid
  /// (knocked out since the roll, e.g. by an earlier enemy's turn this same
  /// phase) gets a fresh target pick without touching the move itself -- a
  /// pre-rolled move was already shown to the player as a promise, so only
  /// who it lands on is renegotiated. Affixes (Frenzied, Pack Leader,
  /// Venomous) and a Cramped battlefield shape the damage and who gets to
  /// swing at all.
  void _takeEnemyTurn(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final leaderStanding =
        _enemies.any((e) => e.isAlive && e.hasAffix(EnemyAffix.packLeader));

    // Cramped: only so many enemies can reach the party each round; the
    // rest hold back, rotating so the same one isn't always the one waiting.
    var heldBack = <String>{};
    final living = _enemies.where((e) => e.isAlive).toList();
    if (_condition == BattlefieldCondition.cramped &&
        living.length > crampedMaxActingEnemies) {
      final offset = _roundsStarted % living.length;
      final rotated = [...living.skip(offset), ...living.take(offset)];
      heldBack =
          rotated.skip(crampedMaxActingEnemies).map((e) => e.key).toSet();
    }

    _squadHealersMend(lang);
    var enemyFx = 0;
    var guardAnnounced = false;
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      final fxDelay = enemyFx++ * 220;
      // A raised guard lasts until the enemy's next turn comes round.
      enemy.guard = 0;

      final poison = poisonDamageFor(enemy.statusEffects);
      if (poison > 0) {
        _fx(VfxStyle.poison, _enemyCardKey(enemy.key),
            delayMs: fxDelay, text: '-$poison', textKind: VfxTextKind.damage);
        _update(() {
          enemy.currentHealth = max(0, enemy.currentHealth - poison);
          // The Moss Choir: the Rot heals the rogue a share of it.
          if (_core.has(Spec.feverBlade) && _core.mods.rotHealShare > 0) {
            final hero = _party.where((m) => m.isPlayer && !m.isKnockedOut);
            if (hero.isNotEmpty) {
              hero.first.currentHealth = min(
                  hero.first.maxHealth,
                  hero.first.currentHealth +
                      (poison * _core.mods.rotHealShare).round());
            }
          }
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'takes_damage_word')} '
            '$poison ${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.',
            _LogKind.playerDamage,
          ));
        });
        if (!enemy.isAlive) continue;
        _advancePhasesNow(lang, skills);
      }

      if (isStunned(enemy.statusEffects)) {
        _fx(VfxStyle.stun, _enemyCardKey(enemy.key), delayMs: fxDelay);
        _update(() {
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'stunned_skip_turn_suffix')}',
            _LogKind.info,
          ));
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
          enemy.chargedBlow = null;
          enemy.staggered = false;
        });
        continue;
      }

      // A broken wind-up: the enemy reels and loses this turn.
      if (enemy.staggered) {
        _update(() {
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'staggered_skip_turn_suffix')}',
            _LogKind.info,
          ));
          enemy.staggered = false;
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        });
        continue;
      }

      if (heldBack.contains(enemy.key)) {
        _update(() {
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'holds_back_suffix')}',
            _LogKind.info,
          ));
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        });
        continue;
      }

      final pending = enemy.pendingMove ?? _rollMoveAndTargetFor(enemy, skills);
      final move = pending.move;
      if (!pending.release && move.intent != EnemyIntent.attack) {
        _resolveEnemyStance(enemy, move, lang, fxDelay,
            targetId: pending.targetId, skills: skills);
        enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        continue;
      }
      if (pending.release) enemy.chargedBlow = null;
      final moveDamage =
          _incomingDamage(enemy, move, leaderStanding: leaderStanding);
      enemy.provoked = false;
      enemy.pressing = false;

      _PartyMember target;
      final cachedTarget = _memberById(pending.targetId);
      if (cachedTarget != null && !cachedTarget.isKnockedOut) {
        target = cachedTarget;
      } else {
        final conscious = _party.where((m) => !m.isKnockedOut).toList();
        target = conscious[_random.nextInt(conscious.length)];
      }
      // Taunt: whoever kept the biggest Defend face steps in front of the
      // blow meant for someone else, while their guard holds (see
      // guardianTakesBlow).
      final guardian = _guardianId == null ? null : _memberById(_guardianId!);
      if (guardian != null &&
          guardianTakesBlow(
            guardianStanding: !guardian.isKnockedOut,
            guardianBlock: guardian.block,
            aimedAtGuardian: guardian.id == target.id,
          )) {
        target = guardian;
        if (!guardAnnounced) {
          guardAnnounced = true;
          _update(() => _log.add(_LogEntry(
                '${guardian.displayName} ${trFor(lang, 'draws_attacks_suffix')}',
                _LogKind.playerBlock,
              )));
        }
      }

      // The Lantern's Writ: the first blows aimed at the player each
      // fight are cancelled before they land -- no damage, no status.
      if (target.isPlayer && _writCharges > 0) {
        _writCharges--;
        _fx(VfxStyle.radiance, _memberCardKey(target.id), delayMs: fxDelay);
        _update(() {
          _log.add(_LogEntry(
            '${move.message} ${trFor(lang, 'sign_log_writ')}',
            _LogKind.playerBlock,
          ));
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        });
        continue;
      }
      final mitigation = _mitigationFor(target, move.element, items);
      // A dodge evades the hit outright -- no damage, no status effect --
      // rather than just softening it further on top of block/armor/resist.
      // The Briar Guard can't dodge (specialisations.dart).
      final wasDodged = _random.nextDouble() * 100 <
              dodgeChanceFor(target.dexterity,
                      perception: target.perception,
                      professionId: target.professionId) +
                  target.gear.dodgeChance &&
          !(target.isPlayer && _core.has(Spec.briarGuard));
      // A parry (v1.214) takes its share of the blow first.
      final parry = enemy.parryBlock;
      enemy.parryBlock = 0;
      var damageTaken = wasDodged
          ? 0
          : damageAfterParry(
              blow: moveDamage,
              parry: parry,
              block: target.block,
              mitigation: mitigation);
      // A warrior's Perception blocks a blow now and then: half of it
      // (stat_rules.dart); signs, titles and Iron Hide lend anyone a block.
      final blockChance = blockChanceWith(
          target.professionId, target.perception, target.gear.blockChance);
      if (!wasDodged &&
          damageTaken > 0 &&
          blockChance > 0 &&
          _random.nextDouble() * 100 < blockChance) {
        damageTaken = blockedBlow(damageTaken);
      }
      // The Briar Guard: what the guard stopped feeds Fury, and a part of
      // it goes back (specialisations.dart).
      final stopped = wasDodged ? 0 : moveDamage - damageTaken;
      final briar = target.isPlayer && _core.has(Spec.briarGuard) && stopped > 0
          ? _core.mods.briarBack(stopped)
          : 0;
      // The Watchfire takes the blow first.
      if (target.isPlayer && _core.fire > 0 && damageTaken > 0) {
        final soaked = min(_core.fire, damageTaken);
        _core.fire -= soaked;
        damageTaken -= soaked;
      }
      final parriedOutright = !wasDodged && parryStopsBlow(moveDamage, parry);
      // A Warding Knot swallows the first real hit on the player outright.
      var warded = false;
      if (damageTaken > 0 && target.isPlayer && _wardingCharges > 0) {
        _wardingCharges--;
        damageTaken = 0;
        warded = true;
      }
      // A Phoenix Sigil (see UniqueEffect.secondWind) turns one lethal
      // blow per fight into a 1 HP survival.
      var secondWind = false;
      if (damageTaken >= target.currentHealth &&
          target.currentHealth > 0 &&
          target.secondWindAvailable) {
        target.secondWindAvailable = false;
        damageTaken = target.currentHealth - 1;
        secondWind = true;
      }
      // Thorns (a Thornmail Hauberk, the Hollow Court set, a sign) send
      // back their share of whatever actually connected (gear_effects.dart's
      // ThornsBank keeps the fractions for the next blow).
      final thorns =
          target.thornsBank.answer(damageTaken, target.gear.thornsPercent);
      // A guard sign bites the enemy that hits the player's raised guard
      // (the block of a Defend face played this round, before this blow
      // takes it down).
      final retaliation =
          target.isPlayer && _signGuardArmed && !wasDodged && target.block > 0
              ? _signs.guardRetaliate
              : 0;
      // A ward (Glacial Ward, Thornwall) wounds the enemy that struck it,
      // even when the shield took the whole blow.
      final wardBite = !wasDodged && !parriedOutright && target.block > 0
          ? target.reflect
          : null;
      final wasKnockedOutAlready = target.isKnockedOut;
      final inflicted = parriedOutright
          ? null
          : move.inflictedStatus ??
              (enemy.hasAffix(EnemyAffix.venomous) ? _venomousPoison : null);

      _update(() {
        target.currentHealth = max(0, target.currentHealth - damageTaken);
        target.block = 0;
        target.reflect = null;
        if (wardBite != null && enemy.isAlive) {
          enemy.statusEffects =
              applyStatusEffect(enemy.statusEffects, wardBite);
          _log.add(_LogEntry(
            trFor(lang, 'skill_ward_bites')
                .replaceAll('{name}', enemy.displayName),
            _LogKind.playerBlock,
          ));
          _fx(
              wardBite.type == StatusEffectType.poison
                  ? VfxStyle.poison
                  : VfxStyle.frost,
              _enemyCardKey(enemy.key),
              delayMs: fxDelay + 250);
        }
        _lastDamageTaken = damageTaken;
        _lastDamagedMemberId = target.id;
        // A blow that got through feeds the warrior's Fury.
        if (damageTaken > 0 &&
            target.isPlayer &&
            _core.core == ProfessionCore.fury) {
          _addFury(_log, lang);
        }
        if (briar > 0) {
          _addFury(_log, lang);
          enemy.currentHealth = max(0, enemy.currentHealth - briar);
          // The Quarrymen: a blow sent back breaks the guard.
          if (_core.mods.briarBreaksGuard) enemy.guard = 0;
          _log.add(_LogEntry(
              trFor(lang, 'spec_briar_log')
                  .replaceAll('{name}', enemy.displayName)
                  .replaceAll('{n}', '$briar'),
              _LogKind.playerDamage));
        }
        if (damageTaken > 0) _momentum = momentumAfterHit(_momentum);
        if (damageTaken > 0) _plunderFrom(enemy, lang);
        if (wasDodged) {
          _log.add(_LogEntry(
            target.isPlayer
                ? '${move.message} ${trFor(lang, 'you_dodge_suffix')}'
                : '${move.message} ${target.displayName} '
                    '${trFor(lang, 'dodges_suffix')}',
            _LogKind.playerBlock,
          ));
          final banter =
              _rollBanter(kind: _BanterKind.dodge, excludeId: target.id);
          if (banter != null) _log.add(banter);
        } else if (warded) {
          _log.add(_LogEntry(
            '${move.message} ${trFor(lang, 'warding_absorbs_message')}',
            _LogKind.playerBlock,
          ));
        } else {
          final damageLine = target.isPlayer
              ? '${move.message} ${trFor(lang, 'you_take_damage_prefix')} $damageTaken '
                  '${trFor(lang, 'damage_word')}.'
              : '${move.message} ${target.displayName} ${trFor(lang, 'takes_damage_word')} '
                  '$damageTaken ${trFor(lang, 'damage_word')}.';
          _log.add(
            _LogEntry(damageLine,
                damageTaken > 0 ? _LogKind.enemyDamage : _LogKind.playerBlock),
          );
          if (!target.isPlayer &&
              !wasKnockedOutAlready &&
              target.isKnockedOut) {
            _anyKnockedOut = true;
            _lastKnockedOutAllyName = target.displayName;
            _log.add(
              _LogEntry(
                '${target.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
                _LogKind.defeat,
              ),
            );
            final banter =
                _rollBanter(kind: _BanterKind.ko, excludeId: target.id);
            if (banter != null) _log.add(banter);
          }
          if (inflicted != null && !target.isKnockedOut) {
            target.statusEffects = applyStatusEffect(
              target.statusEffects,
              applyWisdomResistance(inflicted, target.wisdom),
            );
            _log.add(_LogEntry(
              _statusInflictedMessage(inflicted, target.displayName, lang),
              _LogKind.info,
            ));
          }
        }
        enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
      });
      _playEnemyMoveEffects(
        enemy: enemy,
        target: target,
        skillId: move.skillId,
        element: move.element,
        skills: skills,
        dodged: wasDodged,
        warded: warded,
        damage: damageTaken,
        inflicted: inflicted,
        delayMs: fxDelay,
      );
      _resolveParry(enemy, moveDamage, parry, wasDodged, lang, skills);
      if (move.healAmount > 0 && enemy.isAlive && !enemy.healBlocked) {
        final healed = min(
            scaledEnemyHeal(move.healAmount,
                maxHealth: enemy.maxHealth, baseMaxHealth: enemy.baseMaxHealth),
            enemy.maxHealth - enemy.currentHealth);
        if (healed > 0) {
          enemy.noteHeal(skills);
          _fx(VfxStyle.heal, _enemyCardKey(enemy.key),
              delayMs: fxDelay + 300,
              text: '+$healed',
              textKind: VfxTextKind.heal);
          _update(() {
            enemy.currentHealth += healed;
            _log.add(_LogEntry(
              '${enemy.displayName} ${trFor(lang, 'enemy_recovers_word')} '
              '$healed ${trFor(lang, 'hp_label')}.',
              _LogKind.info,
            ));
          });
        }
      }
      if (secondWind) {
        _fx(VfxStyle.heal, _memberCardKey(target.id),
            delayMs: fxDelay + 450, big: true);
        _update(() {
          _log.add(_LogEntry(
            '${target.displayName} ${trFor(lang, 'second_wind_message')}',
            _LogKind.playerHeal,
          ));
        });
      }
      if (target.isPlayer && _signGuardArmed && enemy.isAlive) {
        _signGuardAnswers(enemy, retaliation, lang, fxDelay);
        _advancePhasesNow(lang, skills);
      }
      if (thorns > 0 && enemy.isAlive) {
        _fx(VfxStyle.impact, _enemyCardKey(enemy.key),
            source: _memberCardKey(target.id),
            delayMs: fxDelay + 400,
            text: '-$thorns',
            textKind: VfxTextKind.damage);
        _update(() {
          enemy.currentHealth = max(0, enemy.currentHealth - thorns);
          _lastDamagedEnemyKey = enemy.key;
          _lastEnemyDamageTaken = thorns;
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'thorns_suffix')} $thorns '
            '${trFor(lang, 'damage_word')}.',
            _LogKind.playerDamage,
          ));
        });
        _advancePhasesNow(lang, skills);
      }
      if (damageTaken > 0 && target.isPlayer) _triggerShake();

      if (target.isPlayer && target.currentHealth <= 0) {
        _finishFight(won: false);
        return;
      }
    }

    if (_enemies.every((e) => !e.isAlive)) {
      _finishFight(won: true);
      return;
    }

    if (_holdHeld) {
      _update(() => _log
          .add(_LogEntry(trFor(lang, 'goal_won_hold_log'), _LogKind.victory)));
      _finishFight(won: true);
      return;
    }

    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }

    _startPartyRound(skills, items);
  }
}
