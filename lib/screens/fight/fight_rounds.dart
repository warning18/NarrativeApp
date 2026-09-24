part of '../fight_screen.dart';

/// Rolling and confirming the party's dice, the party's round and the
/// enemies' turn.
extension _FightRounds on _FightScreenState {
  /// Milliseconds between one party member's effect and the next, so a
  /// round of dice reads as a sequence rather than one flash.
  static const int _fxStagger = 160;

  /// Rolls a die for every acting party member at once — one face per
  /// member, shown side by side — instead of each combatant taking a
  /// separate sequential turn. The first roll of a round just shows its
  /// results and waits for a keep/reroll decision (see [_confirmRoll]); the
  /// 3rd roll is forced — there's no more choice left, so it locks in and
  /// resolves automatically after a beat.
  Future<void> _rollDice(
    Map<String, dynamic> diceDb,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) async {
    if (_over || _rolling || _rollCount >= _maxRollsThisFight) return;
    final acting = _actingParty;

    final rolled = <String, DiceFaceResult>{};
    final isReroll = _rollCount > 0;
    for (final actor in acting) {
      // A die kept (locked) through a reroll shows its current face again.
      if (isReroll && _lockedActorIds.contains(actor.id)) {
        final kept = _currentFaces[actor.id];
        if (kept != null) rolled[actor.id] = kept;
        continue;
      }
      final actorDice = actor.equippedDiceId != null
          ? diceDb[actor.equippedDiceId] as Map<String, dynamic>?
          : null;
      final faces =
          (actorDice?['faces'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      if (faces.isEmpty) continue;

      final rawRoll = rollDie(faces, _random);
      rolled[actor.id] = applyFaceAssignment(
        rawRoll,
        faces[rawRoll.faceIndex],
        actor.diceSkillAssignments[rawRoll.faceIndex.toString()],
        language: ref.read(appLanguageProvider),
      );
    }
    if (rolled.isEmpty) return;

    _update(() => _rolling = true);
    await _rollController.forward(from: 0);
    if (!mounted) return;

    final rollNumber = _rollCount + 1;
    final forced = rollNumber >= _maxRollsThisFight;
    _update(() {
      _rolling = false;
      _rollCount = rollNumber;
      _currentFaces
        ..clear()
        ..addAll(rolled);
      _awaitingDecision = !forced;
      _autoAssignTargets();
    });

    if (forced) {
      // No choice left — give the player a beat to see the 3rd faces land
      // before they resolve on their own.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _confirmRoll(skills, items);
    }
  }

  /// Aims every acting member's Attack/Skill face at the first living enemy
  /// unless they already picked one still standing -- a roll is never
  /// blocked on a pick; the enemy column is where a pick is changed. Also
  /// keeps [_selectedActorId] on a member who has something to aim.
  void _autoAssignTargets() {
    if (_enemies.length <= 1) return;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null || !(face.type == 'Attack' || face.type == 'Skill')) {
        _selectedTargets.remove(actor.id);
        continue;
      }
      if (_companionsAutoAim && !actor.isPlayer) {
        final focus = _focusTargetFor();
        if (focus != null) _selectedTargets[actor.id] = focus.key;
        continue;
      }
      final current = _selectedTargets[actor.id];
      final picked = current == null ? null : _enemyByKey(current);
      if (picked != null && picked.isAlive) continue;
      final fallback = _firstLivingEnemy();
      if (fallback != null) _selectedTargets[actor.id] = fallback.key;
    }
    final selected = _selectedActorId;
    if (selected == null ||
        !_selectedTargets.containsKey(selected) ||
        (_companionsAutoAim && selected != 'player')) {
      _selectedActorId = _selectedTargets.containsKey('player')
          ? 'player'
          : _companionsAutoAim || _selectedTargets.isEmpty
              ? null
              : _selectedTargets.keys.first;
    }
  }

  /// Where an auto-aiming companion strikes (see
  /// [companionAutoTargetProvider]): the enemy the player is aiming at, so
  /// the party focuses fire, else the living enemy closest to going down.
  _EnemyMember? _focusTargetFor() {
    final playerPick = _selectedTargets['player'];
    final picked = playerPick == null ? null : _enemyByKey(playerPick);
    if (picked != null && picked.isAlive) return picked;
    _EnemyMember? weakest;
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      if (weakest == null || enemy.currentHealth < weakest.currentHealth) {
        weakest = enemy;
      }
    }
    return weakest;
  }

  /// True once every acting member currently showing an Attack/Skill face
  /// has picked a target — always true for a solo fight (nothing to pick),
  /// used to gate the Confirm button when `_enemies.length > 1` so a roll
  /// can never resolve against an unset target.
  bool get _allTargetsPicked {
    if (_enemies.length <= 1) return true;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;
      if ((face.type == 'Attack' || face.type == 'Skill') &&
          !_selectedTargets.containsKey(actor.id)) {
        return false;
      }
    }
    return true;
  }

  /// Locks in every acting member's currently-shown rolled face and applies
  /// all of their effects together, whether by tapping Confirm or the 3rd
  /// roll forcing it — then, once at least one enemy still stands, hands
  /// the turn straight to them (there's no more per-member turn order to
  /// advance through).
  Future<void> _confirmRoll(
      Map<String, dynamic> skills, Map<String, dynamic> items) async {
    if (_currentFaces.isEmpty || _over) return;
    final lang = ref.read(appLanguageProvider);

    // Safety-net backfill for the forced-3rd-roll path (no player input is
    // possible there) -- picks the first living enemy so a roll can never
    // silently miss for lack of a target.
    if (_enemies.length > 1) {
      for (final actor in _actingParty) {
        final face = _currentFaces[actor.id];
        if (face == null) continue;
        if ((face.type == 'Attack' || face.type == 'Skill') &&
            !_selectedTargets.containsKey(actor.id)) {
          final fallback = _firstLivingEnemy() ?? _enemies.first;
          _selectedTargets[actor.id] = fallback.key;
        }
      }
    }

    for (final enemy in _enemies) {
      enemy.elementsHitThisRound = {};
    }

    final newEntries = <_LogEntry>[];
    var fxIndex = 0;
    String? lastCritActorId;
    String? lastDamagedEnemyKey;
    var lastEnemyDamage = 0;
    var hitsLanded = 0;
    var manaGained = 0;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;

      final availableSkills = _availableSkillsFor(actor, skills);
      final element = _elementFor(face, availableSkills);
      final totalDamage = _totalDamageFor(actor, face, skills, items);
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      final fxDelay = fxIndex++ * _fxStagger;
      var dealt = 0;
      var drainedFx = 0;
      // Momentum: the built-up hits cash in as a guaranteed critical on
      // this strike, and the counter starts over from it.
      final surge = isStrike && _momentum >= _momentumThreshold;
      if (surge) _momentum = 0;
      final result = resolvePlayerFace(
        face,
        availableSkills,
        totalDamage,
        language: lang,
        activeEffects: actor.statusEffects,
        wisdomHealBonus: actor.wisdom ~/ 2,
        luck: actor.luck +
            (actor.isPlayer && _luckyCoinArmed ? _luckyCoinLuckBonus : 0),
        random: _random,
        forceCritical: surge,
        alignmentLabel: _alignmentLabel,
        critChanceBonus: actor.gear.critChance,
      );
      var healing = result.healingDone;
      if (_condition == BattlefieldCondition.shrine && healing > 0) {
        healing = (healing * shrineHealMultiplier).round();
      }
      final kind = result.damageDealt > 0
          ? _LogKind.playerDamage
          : healing > 0
              ? _LogKind.playerHeal
              : result.blockAmount > 0
                  ? _LogKind.playerBlock
                  : result.manaGained > 0
                      ? _LogKind.mana
                      : _LogKind.info;

      if (result.isCritical) lastCritActorId = actor.id;
      // Any member's Mana face feeds the one shared pool.
      if (result.manaGained > 0) manaGained += result.manaGained;
      actor.currentHealth = min(actor.maxHealth, actor.currentHealth + healing);
      final braced = result.blockAmount > 0 && _isTelegraphedTarget(actor);
      var block = braced
          ? result.blockAmount * _telegraphBraceMultiplier
          : result.blockAmount;
      if (_condition == BattlefieldCondition.highGround && block > 0) {
        block = (block * highGroundBlockMultiplier).round();
      }
      // A spell's block this round (Mana Ward, War Shout) stacks under the
      // face's own -- see [_spellBlock].
      actor.block = block + (_spellBlock[actor.id] ?? 0);
      newEntries
          .add(_LogEntry('${_actorPrefix(actor)}${result.message}', kind));
      if (surge) {
        newEntries.add(_LogEntry(
            trFor(lang, 'momentum_surge_message'), _LogKind.playerDamage));
      }
      if (braced) {
        newEntries.add(_LogEntry(
          '${actor.displayName} ${trFor(lang, 'braced_suffix')} (${actor.block})',
          _LogKind.playerBlock,
        ));
      }

      _EnemyMember? target;
      var redirected = false;
      if (isStrike) {
        target = _strikeTargetFor(actor);
        // The picked enemy went down to an earlier hit this same round --
        // the blow carries on to the next one standing rather than
        // vanishing into a corpse while the log claims a hit.
        final key = _selectedTargets[actor.id];
        final picked = key == null ? null : _enemyByKey(key);
        redirected = _enemies.length > 1 &&
            target != null &&
            (picked == null || !picked.isAlive);
      }

      if (redirected && target != null) {
        newEntries.add(_LogEntry(
          '${trFor(lang, 'redirected_hit_prefix')} ${target.displayName}',
          _LogKind.info,
        ));
      }

      if (target != null) {
        final armored = target.hasAffix(EnemyAffix.armored);
        final damage = strikeDamageAfterAffixes(result.damageDealt, face.type,
            armored: armored);
        if (result.damageDealt > 0 && face.type == 'Attack' && armored) {
          newEntries.add(_LogEntry(
            '${target.displayName} ${trFor(lang, 'armored_absorbs_suffix')}',
            _LogKind.info,
          ));
        }
        final wasAlive = target.isAlive;
        target.currentHealth = max(0, target.currentHealth - damage);
        dealt = damage;
        if (damage > 0) {
          lastDamagedEnemyKey = target.key;
          lastEnemyDamage = damage;
          hitsLanded++;
          // Lifesteal (a Bloodthorn Blade, the full Hollow Court set) and
          // mana on hit (a Siphon Wand) pay out per landed hit.
          final drained = actor.gear.lifestealFor(damage);
          if (drained > 0 && actor.currentHealth < actor.maxHealth) {
            drainedFx = drained;
            actor.currentHealth =
                min(actor.maxHealth, actor.currentHealth + drained);
            newEntries.add(_LogEntry(
              '${actor.displayName} ${trFor(lang, 'lifesteal_suffix')} '
              '$drained ${trFor(lang, 'hp_label')}.',
              _LogKind.playerHeal,
            ));
          }
          if (actor.gear.manaOnHit > 0) manaGained += actor.gear.manaOnHit;
        }
        if (wasAlive && !target.isAlive) {
          _lastKillWasCritical = result.isCritical;
        }
        if (element != 'None' && damage > 0) {
          target.elementsHitThisRound.add(element);
        }
        final inflicted = result.inflictedStatus;
        if (inflicted != null) {
          target.statusEffects = applyStatusEffect(
            target.statusEffects,
            inflicted,
          );
          newEntries.add(_LogEntry(
            _statusInflictedMessage(inflicted, target.displayName, lang),
            _LogKind.info,
          ));
        }
      }
      _playFaceEffects(
        actor: actor,
        face: face,
        skills: availableSkills,
        element: element,
        result: result,
        target: target,
        dealt: dealt,
        healing: healing,
        block: block,
        drained: drainedFx,
        delayMs: fxDelay,
      );
    }

    _advanceBossPhases(newEntries, lang, skills);

    if (hitsLanded > 0) {
      final before = _momentum;
      _momentum = min(_momentumThreshold, _momentum + hitsLanded);
      if (before < _momentumThreshold && _momentum >= _momentumThreshold) {
        newEntries.add(
            _LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
      }
    }

    // Each acting member's own effects count down once their turn is over
    // (see tickStatusEffects) -- ticking at the start of the round instead
    // silently ate the first (and, under Wisdom resistance, only) turn of
    // every Weaken landed on the party.
    for (final actor in _actingParty) {
      actor.statusEffects = tickStatusEffects(actor.statusEffects);
    }

    if (lastCritActorId != null) {
      final banter =
          _rollBanter(kind: _BanterKind.crit, excludeId: lastCritActorId);
      if (banter != null) newEntries.add(banter);
    }

    if (manaGained > 0) {
      _mana = min(_maxMana, _mana + manaGained);
      ref.read(playerSessionProvider.notifier).setMana(_mana);
    }

    _noteSkittishFlights(newEntries, lang);

    _update(() {
      _awaitingDecision = false;
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _lockedActorIds.clear();
      _selectedActorId = null;
      if (lastDamagedEnemyKey != null) {
        _lastDamagedEnemyKey = lastDamagedEnemyKey;
        _lastEnemyDamageTaken = lastEnemyDamage;
      }
      _log.addAll(newEntries);
    });

    // Give the round's effects time to land before the enemy answers.
    await Future.delayed(Duration(
        milliseconds:
            _effectsOn ? max(400, (fxIndex - 1) * _fxStagger + 450) : 400));
    if (!mounted) return;

    if (_enemies.every((e) => !e.isAlive)) {
      _finishFight(won: true);
      return;
    }

    _takeEnemyTurn(skills, items);
  }

  /// A Skittish enemy that's been hurt enough runs for it -- out of the
  /// fight, but taking part of its share of the spoils with it. Checked
  /// after every party action that can hurt one: a confirmed roll and a
  /// cast spell.
  void _noteSkittishFlights(List<_LogEntry> entries, AppLanguage lang) {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || !enemy.hasAffix(EnemyAffix.skittish)) continue;
      if (enemy.currentHealth < enemy.maxHealth * skittishFleeThreshold) {
        enemy.fled = true;
        enemy.currentHealth = 0;
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, 'flees_suffix')}',
          _LogKind.info,
        ));
      }
    }
  }

  /// Starts a fresh party round — called once every enemy's turn resolves
  /// without ending the fight. This is also where every still-conscious
  /// party member's own status effects take hold for the round about to
  /// start: Poison ticks its damage and Stun determines who's excluded from
  /// [_actingParty]. A stunned member's effects count down here (the stun
  /// consumed their turn); everyone else's count down once they've actually
  /// acted, in [_confirmRoll]. If nobody is able to act at all, the round is
  /// skipped straight through to the enemies' next turn rather than
  /// stalling on a roll nobody can make.
  void _startPartyRound(
      Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final newEntries = <_LogEntry>[];
    var playerDied = false;
    _roundsStarted++;

    for (final member in _party) {
      if (member.isKnockedOut) continue;
      final poison = poisonDamageFor(member.statusEffects);
      if (poison > 0) {
        _fx(VfxStyle.poison, _memberCardKey(member.id),
            text: '-$poison', textKind: VfxTextKind.hurt);
        member.currentHealth = max(0, member.currentHealth - poison);
        newEntries.add(_LogEntry(
          member.isPlayer
              ? '${trFor(lang, 'you_take_damage_prefix')} $poison '
                  '${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.'
              : '${member.displayName} ${trFor(lang, 'takes_damage_word')} '
                  '$poison ${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.',
          _LogKind.enemyDamage,
        ));
        if (member.isKnockedOut) {
          if (member.isPlayer) {
            playerDied = true;
          } else {
            _anyKnockedOut = true;
            _lastKnockedOutAllyName = member.displayName;
            newEntries.add(_LogEntry(
              '${member.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
              _LogKind.defeat,
            ));
            final banter =
                _rollBanter(kind: _BanterKind.ko, excludeId: member.id);
            if (banter != null) newEntries.add(banter);
          }
        }
      }
      if (!member.isKnockedOut && isStunned(member.statusEffects)) {
        _fx(VfxStyle.stun, _memberCardKey(member.id), delayMs: 200);
        newEntries.add(_LogEntry(
          '${member.displayName} ${trFor(lang, 'stunned_skip_turn_suffix')}',
          _LogKind.info,
        ));
      }
    }

    // Taken before ticking: a member stunned this round sits it out even
    // though the tick below may expire that very stun for the round after.
    _sittingOut = {
      for (final member in _party)
        if (!member.isKnockedOut && isStunned(member.statusEffects)) member.id,
    };
    final canAct = _actingParty.isNotEmpty;

    for (final member in _party) {
      if (member.isKnockedOut || !isStunned(member.statusEffects)) continue;
      member.statusEffects = tickStatusEffects(member.statusEffects);
    }

    // A telegraph is a promise about WHO gets hit -- if poison just took
    // that member down, re-aim the cached move now so the badge never names
    // someone who's already out (the move itself is untouched).
    final conscious = _party.where((m) => !m.isKnockedOut).toList();
    if (conscious.isNotEmpty) {
      for (final enemy in _enemies) {
        final pending = enemy.pendingMove;
        if (pending == null || !enemy.isAlive) continue;
        final cachedTarget = _memberById(pending.targetId);
        if (cachedTarget != null && !cachedTarget.isKnockedOut) continue;
        enemy.pendingMove = _PendingEnemyMove(
          move: pending.move,
          targetId: conscious[_random.nextInt(conscious.length)].id,
        );
      }
    }
    _noteTelegraphReads();

    _update(() {
      _log.addAll(newEntries);
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _lockedActorIds.clear();
      _spellBlock.clear();
      _selectedActorId = null;
      _awaitingDecision = false;
      // A fresh round with nothing hit yet on any enemy — otherwise a
      // round skipped outright below (nobody able to act) would hand
      // _takeEnemyTurn last round's stale hits, letting an
      // OnHitByElement reaction fire again for an element nobody
      // actually struck with this round.
      for (final enemy in _enemies) {
        enemy.elementsHitThisRound = {};
      }
    });

    if (playerDied) {
      _finishFight(won: false);
      return;
    }

    if (!canAct) {
      _takeEnemyTurn(skills, items);
    }
  }

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
    if (!enemy.isAlive || enemy.hasReactiveMoves) {
      enemy.pendingMove = null;
      return;
    }
    enemy.pendingMove = _rollMoveAndTargetFor(enemy, skills);
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
        final healed =
            healthAfterPhaseHeal(phase, enemy.currentHealth, enemy.maxHealth) -
                enemy.currentHealth;
        enemy.currentHealth += healed;
        if (phase.cleanse) enemy.statusEffects = [];
        enemy.damage = (enemy.damage * phase.damageMultiplier).round();
        enemy.data = enemyDataInPhase(enemy.data, phase);
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

    var enemyFx = 0;
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      final fxDelay = enemyFx++ * 220;

      final poison = poisonDamageFor(enemy.statusEffects);
      if (poison > 0) {
        _fx(VfxStyle.poison, _enemyCardKey(enemy.key),
            delayMs: fxDelay, text: '-$poison', textKind: VfxTextKind.damage);
        _update(() {
          enemy.currentHealth = max(0, enemy.currentHealth - poison);
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
      var moveDamage = applyWeaken(move.damage, enemy.statusEffects);
      if (enemy.hasAffix(EnemyAffix.frenzied) &&
          enemy.currentHealth < enemy.maxHealth * frenziedHealthThreshold) {
        moveDamage = (moveDamage * frenziedDamageMultiplier).round();
      }
      if (leaderStanding && !enemy.hasAffix(EnemyAffix.packLeader)) {
        moveDamage = (moveDamage * packLeaderAllyDamageMultiplier).round();
      }

      final _PartyMember target;
      final cachedTarget = _memberById(pending.targetId);
      if (cachedTarget != null && !cachedTarget.isKnockedOut) {
        target = cachedTarget;
      } else {
        final conscious = _party.where((m) => !m.isKnockedOut).toList();
        target = conscious[_random.nextInt(conscious.length)];
      }

      final targetScalingBonus = equipmentScalingBonusFor(
        target.equippedItemIds,
        items,
        strength: target.strength,
        dexterity: target.dexterity,
        constitution: target.constitution,
        intelligence: target.intelligence,
      );
      final targetAlignedBonus =
          alignmentGearBonusFor(target.equippedItemIds, items, _alignmentLabel);
      final totalArmor = target.armor +
          equipmentBonusFor(target.equippedItemIds, items, 'armor') +
          targetScalingBonus.armorBonus +
          targetAlignedBonus.armorBonus +
          target.gear.armor +
          (target.isPlayer && _ironSkinArmed ? _ironSkinArmorBonus : 0);
      final elementalResist =
          _elementalResist(move.element, target.equippedItemIds, items);
      // A dodge evades the hit outright -- no damage, no status effect --
      // rather than just softening it further on top of block/armor/resist.
      final wasDodged = _random.nextDouble() * 100 <
          dodgeChanceFor(target.dexterity) + target.gear.dodgeChance;
      var damageTaken = wasDodged
          ? 0
          : max(0, moveDamage - target.block - totalArmor - elementalResist);
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
      // Thorns (a Thornmail Hauberk, the Hollow Court set) cut whatever
      // actually connected.
      final thorns = damageTaken > 0 ? target.gear.thorns : 0;
      final wasKnockedOutAlready = target.isKnockedOut;
      final inflicted = move.inflictedStatus ??
          (enemy.hasAffix(EnemyAffix.venomous) ? _venomousPoison : null);

      _update(() {
        target.currentHealth = max(0, target.currentHealth - damageTaken);
        target.block = 0;
        _lastDamageTaken = damageTaken;
        _lastDamagedMemberId = target.id;
        if (damageTaken > 0) _momentum = 0;
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

    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }

    _startPartyRound(skills, items);
  }
}
