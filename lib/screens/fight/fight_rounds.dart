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
      // The die as smithed at the Hammersmith (see _ensurePartyBuilt).
      final faces = actor.dieFaces;
      if (faces.isEmpty) continue;
      rolled[actor.id] = _landedFace(actor, rollDie(faces, _random));
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
      // A Steady face that just landed stays put (see face_keywords.dart).
      _noteSteadyFaces(
          rolled.keys.where((id) => !_lockedActorIds.contains(id)).toList());
      _awaitingDecision = !forced;
      _autoAssignTargets();
    });
    // A Hex laid last round takes the best die of this first roll.
    if (rollNumber == 1 && !forced) _springHex(skills, items);

    if (forced) {
      // No choice left — give the player a beat to see the 3rd faces land
      // before they resolve on their own.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _confirmRoll(skills, items);
    }
  }

  /// Aims every acting member whose played face strikes (see
  /// [_strikerIds]) at the first living enemy unless they already picked
  /// one still standing -- a roll is never blocked on a pick; the enemy
  /// column is where a pick is changed. Also keeps [_selectedActorId] on a
  /// member who has something to aim.
  void _autoAssignTargets() {
    if (_enemies.length <= 1) return;
    final strikers = _strikerIds();
    for (final actor in _actingParty) {
      if (!strikers.contains(actor.id)) {
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

  /// True once every acting member whose played face strikes has picked a
  /// target — always true for a solo fight (nothing to pick), used to gate
  /// the Confirm button when `_enemies.length > 1` so a roll can never
  /// resolve against an unset target.
  bool get _allTargetsPicked {
    if (_enemies.length <= 1) return true;
    return _strikerIds().every(_selectedTargets.containsKey);
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
      for (final id in _strikerIds()) {
        if (_selectedTargets.containsKey(id)) continue;
        final fallback = _firstLivingEnemy() ?? _enemies.first;
        _selectedTargets[id] = fallback.key;
      }
    }

    for (final enemy in _enemies) {
      enemy.elementsHitThisRound = {};
    }
    // Only a Defend face played this round arms the guard signs.
    _signGuardArmed = false;

    final newEntries = <_LogEntry>[];
    var fxIndex = 0;
    String? lastCritActorId;
    String? lastDamagedEnemyKey;
    var lastEnemyDamage = 0;
    var hitsLanded = 0;
    var manaGained = 0;
    // Taunt (v1.162): the member who kept the biggest Defend face this round
    // draws the enemies' attacks in a party fight (see _takeEnemyTurn).
    String? guardianId;
    var guardianBlock = 0;
    // The faces as played (an Echo copies the one before it), each resolved
    // with its own critical roll in party order, then what they add up to
    // (see party_combos.dart).
    final played = _playedFaces();
    final surgeTo = _surgeRecipient(played);
    final results = <String, PlayerActionResult>{};
    for (final actor in _actingParty) {
      final face = played[actor.id];
      if (face == null) continue;
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      results[actor.id] = _resolveFor(actor, face, skills, items, lang,
          surge: isStrike && actor.id == surgeTo, rollCritical: true);
    }
    final combos = partyCombosFor([for (final r in results.values) _roleOf(r)]);
    for (final actor in _actingParty) {
      final face = played[actor.id];
      final result = results[actor.id];
      if (face == null || result == null) continue;

      final availableSkills = _skillsForFace(actor, face, skills);
      final element = _elementFor(face, availableSkills);
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      final pierce = face.hasKeyword(FaceKeyword.pierce);
      final fxDelay = fxIndex++ * _fxStagger;
      var dealt = 0;
      var drainedFx = 0;
      // Momentum: the built-up hits cash in as a guaranteed critical on
      // the strike the player picked (see _surgeRecipient), and the
      // counter starts over from it.
      final surge = isStrike && actor.id == surgeTo;
      if (surge) {
        _momentum = 0;
        _surgeActorId = null;
      }
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
      // A mend sign turns the player's healing past full into block (worked
      // out before the heal lands).
      final signShield = actor.isPlayer && face.type == 'Heal'
          ? _signs.shieldFromOverheal(
              healing: healing,
              currentHealth: actor.currentHealth,
              maxHealth: actor.maxHealth)
          : 0;
      actor.currentHealth = min(actor.maxHealth, actor.currentHealth + healing);
      // A Shelter passes part of every Heal to the rest of the party.
      if (combos.contains(PartyCombo.shelter) &&
          _roleOf(result) == FaceRole.heal &&
          healing > 0) {
        _shelterFrom(actor, healing, newEntries, lang);
      }
      final braced = result.blockAmount > 0 && _isTelegraphedTarget(actor);
      var block = braced
          ? result.blockAmount * _telegraphBraceMultiplier
          : result.blockAmount;
      if (_condition == BattlefieldCondition.highGround && block > 0) {
        block = (block * highGroundBlockMultiplier).round();
      }
      // A spell's block this round (Mana Ward, War Shout) stacks under the
      // face's own -- see [_spellBlock].
      actor.block = block + (_spellBlock[actor.id] ?? 0) + signShield;
      if (result.blockAmount > 0 && actor.block > guardianBlock) {
        guardianId = actor.id;
        guardianBlock = actor.block;
      }
      newEntries
          .add(_LogEntry('${_actorPrefix(actor)}${result.message}', kind));
      if (actor.isPlayer) {
        _applySignFaceExtras(
            actor, face, result, healing, signShield, newEntries, lang);
      }
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
            picked != null &&
            !picked.isAlive;
      }

      if (redirected && target != null) {
        newEntries.add(_LogEntry(
          '${trFor(lang, 'redirected_hit_prefix')} ${target.displayName}',
          _LogKind.info,
        ));
      }

      if (target != null) {
        final armored = target.hasAffix(EnemyAffix.armored);
        // A Flank or a Volley lands every strike harder.
        final struck = comboDamage(result.damageDealt, combos);
        final damage = pierce
            ? struck
            : strikeDamageAfterAffixes(struck, face.type, armored: armored);
        if (result.damageDealt > 0 &&
            face.type == 'Attack' &&
            armored &&
            !pierce) {
          newEntries.add(_LogEntry(
            '${target.displayName} ${trFor(lang, 'armored_absorbs_suffix')}',
            _LogKind.info,
          ));
        }
        final wasAlive = target.isAlive;
        final landed = _landHitOnEnemy(
            target, damage, element, newEntries, lang,
            pierce: pierce);
        target.currentHealth = max(0, target.currentHealth - landed);
        dealt = landed;
        _bestHitThisRound = max(_bestHitThisRound, landed);
        if (landed > 0) {
          lastDamagedEnemyKey = target.key;
          lastEnemyDamage = landed;
          hitsLanded++;
          // Lifesteal (a Bloodthorn Blade, the full Hollow Court set) and
          // mana on hit (a Siphon Wand) pay out per landed hit.
          final drained = actor.gear.lifestealFor(landed);
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
        if (element != 'None' && landed > 0) {
          target.elementsHitThisRound.add(element);
        }
        // A Cleave, or any strike of a Volley, catches the rest of the pack
        // (a Cleave for more).
        final cleave = face.hasKeyword(FaceKeyword.cleave);
        if (damage > 0 && (cleave || combos.contains(PartyCombo.volley))) {
          _splashFrom(
              actor,
              target,
              damage,
              cleave ? cleaveSplashShare : volleySplashShare,
              element,
              pierce,
              newEntries,
              lang);
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
        // A strike sign's status, on the player's Attack face that landed.
        if (actor.isPlayer && face.type == 'Attack' && landed > 0) {
          _rollSignStatuses(_signs.strikeStatuses, target, newEntries, lang);
        }
      }
      // Pain: the strike hurt its roller too.
      if (face.hasKeyword(FaceKeyword.pain) && result.damageDealt > 0) {
        final cost = painCost(
            maxHealth: actor.maxHealth, currentHealth: actor.currentHealth);
        if (cost > 0) {
          actor.currentHealth -= cost;
          _fx(VfxStyle.drain, _memberCardKey(actor.id),
              delayMs: fxDelay + 250,
              text: '-$cost',
              textKind: VfxTextKind.hurt);
          newEntries.add(_LogEntry(
            trFor(lang, 'pain_costs')
                .replaceAll('{name}', actor.displayName)
                .replaceAll('{n}', '$cost'),
            _LogKind.enemyDamage,
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

    // A Growth face grows each time it's used; an Echo repeats the face
    // played before it, so the round's faces are remembered.
    for (final entry in played.entries) {
      if (entry.value.hasKeyword(FaceKeyword.growth)) {
        final key = '${entry.key}:${entry.value.faceIndex}';
        _growthUses[key] = (_growthUses[key] ?? 0) + 1;
      }
      _lastPlayedFaces[entry.key] = entry.value;
    }
    manaGained += _applyAfterFaceCombos(combos, newEntries, lang);
    _applyDuos(newEntries, lang);
    _feedSignKills(newEntries, lang);

    _guardianId =
        _party.where((m) => !m.isKnockedOut).length > 1 ? guardianId : null;
    _checkChargeBreaks(newEntries, lang);
    _advanceBossPhases(newEntries, lang, skills);

    if (hitsLanded > 0) {
      final before = _momentum;
      _momentum = min(_momentumNeeded, _momentum + hitsLanded);
      if (before < _momentumNeeded && _momentum >= _momentumNeeded) {
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
      _steadyActorIds.clear();
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
    // A Silence laid in the enemies' turn hangs over this round's dice; the
    // round's best hit (what a Mirror sends back) starts over.
    _silenced = _silencePending;
    _silencePending = false;
    _bestHitThisRound = 0;
    _signGuardArmed = false;
    // An enemy that fell in their turn (poison, thorns, a guard sign)
    // feeds a kill-heal sign now.
    _feedSignKills(newEntries, lang);
    if (_silenced) {
      newEntries.add(
          _LogEntry(trFor(lang, 'silence_round_note'), _LogKind.enemyDamage));
    }

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
          release: pending.release,
        );
      }
    }
    _noteTelegraphReads();
    for (final enemy in _enemies) {
      enemy.damageThisRound = 0;
      enemy.hitWeaknessThisRound = false;
    }

    final sellswordWon = !playerDied && _sellswordStrikes(newEntries, lang);

    _update(() {
      _log.addAll(newEntries);
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _lockedActorIds.clear();
      _steadyActorIds.clear();
      _spellBlock.clear();
      _guardianId = null;
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
    if (sellswordWon) {
      _finishFight(won: true);
      return;
    }

    if (!canAct) {
      _takeEnemyTurn(skills, items);
    }
  }

  /// The hired sellsword strikes the weakest enemy standing, at the start
  /// of each of the party's rounds: from [_startPartyRound], and from
  /// [_startFight] for the first. Returns true when the blow ends the
  /// fight.
  bool _sellswordStrikes(List<_LogEntry> entries, AppLanguage lang) {
    if (_sellswordStrike <= 0) return false;
    final standing = _enemies.where((e) => e.isAlive).toList()
      ..sort((a, b) => a.currentHealth.compareTo(b.currentHealth));
    if (standing.isEmpty) return false;
    final target = standing.first;
    final dealt = min(_sellswordStrike, target.currentHealth);
    target.currentHealth -= dealt;
    _fx(VfxStyle.slash, _enemyCardKey(target.key),
        text: '-$dealt', textKind: VfxTextKind.hurt);
    entries.add(_LogEntry(
      trFor(lang, 'sellsword_strikes')
          .replaceAll('{name}', target.displayName)
          .replaceAll('{n}', '$dealt'),
      _LogKind.playerDamage,
    ));
    return _enemies.every((e) => !e.isAlive);
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
  int _landHitOnEnemy(_EnemyMember enemy, int damage, String element,
      List<_LogEntry> entries, AppLanguage lang,
      {bool pierce = false}) {
    if (damage <= 0) return damage;
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
      {required String targetId}) {
    final key = _enemyCardKey(enemy.key);
    switch (move.intent) {
      case EnemyIntent.tamper:
        _applyTamper(enemy, move, targetId, lang, delay);
      case EnemyIntent.heal:
        final amount = scaledEnemyHeal(move.healAmount,
            maxHealth: enemy.maxHealth, baseMaxHealth: enemy.baseMaxHealth);
        final healed = min(amount, enemy.maxHealth - enemy.currentHealth);
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
            targetId: pending.targetId);
        enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        continue;
      }
      if (pending.release) enemy.chargedBlow = null;
      final moveDamage =
          _incomingDamage(enemy, move, leaderStanding: leaderStanding);

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

      final mitigation = _mitigationFor(target, move.element, items);
      // A dodge evades the hit outright -- no damage, no status effect --
      // rather than just softening it further on top of block/armor/resist.
      final wasDodged = _random.nextDouble() * 100 <
          dodgeChanceFor(target.dexterity) + target.gear.dodgeChance;
      var damageTaken =
          wasDodged ? 0 : max(0, moveDamage - target.block - mitigation);
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
      // A guard sign bites the enemy that hits the player's raised guard
      // (the block of a Defend face played this round, before this blow
      // takes it down).
      final retaliation =
          target.isPlayer && _signGuardArmed && !wasDodged && target.block > 0
              ? _signs.guardRetaliate
              : 0;
      final wasKnockedOutAlready = target.isKnockedOut;
      final inflicted = move.inflictedStatus ??
          (enemy.hasAffix(EnemyAffix.venomous) ? _venomousPoison : null);

      _update(() {
        target.currentHealth = max(0, target.currentHealth - damageTaken);
        target.block = 0;
        _lastDamageTaken = damageTaken;
        _lastDamagedMemberId = target.id;
        if (damageTaken > 0) _momentum = momentumAfterHit(_momentum);
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
      if (move.healAmount > 0 && enemy.isAlive) {
        final healed = min(
            scaledEnemyHeal(move.healAmount,
                maxHealth: enemy.maxHealth, baseMaxHealth: enemy.baseMaxHealth),
            enemy.maxHealth - enemy.currentHealth);
        if (healed > 0) {
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

    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }

    _startPartyRound(skills, items);
  }

  // --- Signs (see signs.dart) ----------------------------------------------

  /// What the player's own guard and mend signs do once their face is
  /// played: a Defend face heals and arms the guard signs for the enemies'
  /// turn; a Heal face reaches the rest of the party, spills into block
  /// ([signShield], already added to the block) and lifts afflictions.
  void _applySignFaceExtras(
    _PartyMember actor,
    DiceFaceResult face,
    PlayerActionResult result,
    int healing,
    int signShield,
    List<_LogEntry> entries,
    AppLanguage lang,
  ) {
    if (_signs.isEmpty) return;
    if (face.type == 'Defend' && result.blockAmount > 0) {
      _signGuardArmed = true;
      final heal = min(_signs.guardHeal, actor.maxHealth - actor.currentHealth);
      if (heal > 0) {
        actor.currentHealth += heal;
        _fx(VfxStyle.heal, _memberCardKey(actor.id),
            delayMs: 300, text: '+$heal', textKind: VfxTextKind.heal);
        entries.add(_LogEntry(
            trFor(lang, 'sign_log_guard_heal').replaceAll('{n}', '$heal'),
            _LogKind.playerHeal));
      }
    }
    if (face.type != 'Heal' || healing <= 0) return;
    if (signShield > 0) {
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_mend_shield').replaceAll('{n}', '$signShield'),
          _LogKind.playerBlock));
    }
    final share = _signs.mendShare(healing);
    final others = _party.where((m) => !m.isPlayer && !m.isKnockedOut).toList();
    if (share > 0 && others.isNotEmpty) {
      for (final member in others) {
        member.currentHealth =
            min(member.maxHealth, member.currentHealth + share);
        _fx(VfxStyle.heal, _memberCardKey(member.id),
            delayMs: 300, text: '+$share', textKind: VfxTextKind.heal);
      }
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_mend_party').replaceAll('{n}', '$share'),
          _LogKind.playerHeal));
    }
    final lifted = min(_signs.mendCleanse, actor.statusEffects.length);
    if (lifted > 0) {
      actor.statusEffects = actor.statusEffects.skip(lifted).toList();
      entries
          .add(_LogEntry(trFor(lang, 'sign_log_cleanse'), _LogKind.playerHeal));
    }
  }

  /// Rolls each of [chances] (a sign's status at its odds) against
  /// [enemy], logging those that land under the sign's name.
  void _rollSignStatuses(List<SignStatusChance> chances, _EnemyMember enemy,
      List<_LogEntry> entries, AppLanguage lang) {
    for (final chance in chances) {
      if (!enemy.isAlive || !chance.rolls(_random)) continue;
      enemy.statusEffects =
          applyStatusEffect(enemy.statusEffects, chance.status);
      _fx(styleForStatus(chance.status.type), _enemyCardKey(enemy.key),
          delayMs: 350);
      entries.add(_LogEntry(
        trFor(lang, 'sign_log_status')
            .replaceAll('{sign}', _signName(chance.signId, lang))
            .replaceAll(
                '{line}',
                _statusInflictedMessage(
                    chance.status, enemy.displayName, lang)),
        _LogKind.info,
      ));
    }
  }

  /// A held sign's name for the log; the word "Signs" when it's unknown.
  String _signName(String signId, AppLanguage lang) =>
      _signDefs[signId]?.nameFor(lang) ?? trFor(lang, 'signs_section');

  /// The player's guard signs answering [enemy]'s blow: its [retaliation]
  /// back, and the guard's statuses at their odds.
  void _signGuardAnswers(
      _EnemyMember enemy, int retaliation, AppLanguage lang, int delay) {
    final entries = <_LogEntry>[];
    if (retaliation > 0) {
      final dealt = min(retaliation, enemy.currentHealth);
      enemy.currentHealth -= dealt;
      _fx(VfxStyle.impact, _enemyCardKey(enemy.key),
          source: _memberCardKey('player'),
          delayMs: delay + 350,
          text: '-$dealt',
          textKind: VfxTextKind.damage);
      final guardSign = heldInSlot(
          SignSlot.guard, ref.read(playerSessionProvider).heldSigns, _signDefs);
      entries.add(_LogEntry(
        trFor(lang, 'sign_log_retaliate')
            .replaceAll('{sign}', _signName(guardSign?.signId ?? '', lang))
            .replaceAll('{name}', enemy.displayName)
            .replaceAll('{n}', '$dealt'),
        _LogKind.playerDamage,
      ));
      _lastDamagedEnemyKey = enemy.key;
      _lastEnemyDamageTaken = dealt;
    }
    _rollSignStatuses(_signs.guardStatuses, enemy, entries, lang);
    if (entries.isNotEmpty) _update(() => _log.addAll(entries));
  }

  /// A kill-heal sign feeding on each enemy fallen since the last look
  /// (one that fled doesn't count): the player recovers its health.
  void _feedSignKills(List<_LogEntry> entries, AppLanguage lang) {
    if (_signs.killHeal <= 0) return;
    final player = _party.firstWhere((m) => m.isPlayer);
    for (final enemy in _enemies) {
      if (enemy.isAlive || enemy.fled || !_signKillsFed.add(enemy.key)) {
        continue;
      }
      final heal = player.isKnockedOut
          ? 0
          : min(_signs.killHeal, player.maxHealth - player.currentHealth);
      if (heal <= 0) continue;
      player.currentHealth += heal;
      _fx(VfxStyle.heal, _memberCardKey(player.id),
          delayMs: 300, text: '+$heal', textKind: VfxTextKind.heal);
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_kill_heal').replaceAll('{n}', '$heal'),
          _LogKind.playerHeal));
    }
  }
}
