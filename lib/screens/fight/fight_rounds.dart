part of '../fight_screen.dart';

/// Rolling and confirming the party's dice and the party's round (the
/// enemies' turn: fight_enemy_turn.dart; the signs: fight_sign_rounds.dart).
extension _FightRounds on _FightScreenState {
  /// What [raw] healing from [actor]'s [face] heals this round: the
  /// Anvil-Deaf's wall takes no Heal faces (spec_variants.dart), a shrine
  /// heals more, each heal a member gives this fight heals a little less,
  /// and the cleric's Watchfire doesn't tire, it burns
  /// (profession_cores.dart). [count] false: the round's preview, which
  /// counts no heal (fight_dice_rules.dart).
  int _healDealt(_PartyMember actor, DiceFaceResult face, int raw,
      {bool count = true}) {
    var healing = actor.isPlayer &&
            face.type == 'Heal' &&
            _core.has(Spec.briarGuard) &&
            _core.mods.noHealFaces
        ? 0
        : raw;
    if (_condition == BattlefieldCondition.shrine && healing > 0) {
      healing = (healing * shrineHealMultiplier).round();
    }
    if (actor.isPlayer && _core.core == ProfessionCore.watchfire) {
      return _length.rule.heal(healing, _roundsStarted);
    }
    return count
        ? _length.fatigued(actor.id, healing, round: _roundsStarted)
        : _length.previewed(actor.id, healing, round: _roundsStarted);
  }

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
    if (_over || _rolling || _settlingRound || _rollCount >= _rollCap) return;
    final acting = _actingParty;
    // The locks kept through this roll are frozen for the round.
    _dieLocks.rolled();

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
      // The ranger's Trail draws the die as a deck (profession_cores.dart).
      final face = actor.isPlayer && _core.core == ProfessionCore.trail
          ? _trailFace(faces)
          : rollDie(faces, _random);
      rolled[actor.id] = _landedFace(actor, face);
    }
    if (rolled.isEmpty) return;

    _update(() {
      _rolling = true;
      _rollingTo = rolled;
    });
    if (_quick) {
      _rollController.value = 1;
    } else {
      _rollController.duration = _still
          ? const Duration(milliseconds: 1)
          : diceTimeFor(diceThrowBase, ref.read(diceSpeedProvider));
      await _rollController.forward(from: 0);
    }
    if (!mounted) return;

    final rollNumber = _rollCount + 1;
    final forced = rollNumber >= _rollCap;
    _update(() {
      _rolling = false;
      _rollingTo = const {};
      _rollCount = rollNumber;
      _currentFaces
        ..clear()
        ..addAll(rolled);
      if (_core.broadsideFired) {
        _core.broadsideFired = false;
        _log.add(_LogEntry(
            trFor(ref.read(appLanguageProvider), 'spec_broadside_log'),
            _LogKind.info));
      }
      // A Steady face that just landed stays put (see face_keywords.dart).
      _noteSteadyFaces(
          rolled.keys.where((id) => !_lockedActorIds.contains(id)).toList());
      _awaitingDecision = false;
    });
    // The dice rest with their faces up for a beat before they can be
    // tapped (scaled by the dice speed; none with reduced motion or a
    // quick resolve).
    if (!_quick && !_still) {
      await Future.delayed(
          diceTimeFor(diceLandBase, ref.read(diceSpeedProvider)));
      if (!mounted) return;
    }
    _update(() {
      _awaitingDecision = !forced;
      _autoAssignTargets();
    });
    // A Hex laid last round takes the best die of this first roll.
    if (rollNumber == 1 && !forced) _springHex(skills, items);

    if (forced) {
      // No choice left — give the player a beat to see the 3rd faces land
      // before they resolve on their own.
      await Future.delayed(diceTimeFor(
          const Duration(milliseconds: 700), ref.read(diceSpeedProvider)));
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
    var bonusRollsNext = 0;
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
    _applyHeroCore(played, results, skills, items, lang, newEntries);
    final combos = partyCombosFor([for (final r in results.values) _roleOf(r)]);
    for (final actor in _actingParty) {
      final face = played[actor.id];
      final result = results[actor.id];
      if (face == null || result == null) continue;

      final availableSkills = _skillsForFace(actor, face, skills);
      // The Lantern Vanguard's heavy blow is Fire (specialisations.dart).
      final element =
          actor.isPlayer && _core.heavy && _core.has(Spec.lanternVanguard)
              ? vanguardElement
              : _elementFor(face, availableSkills);
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      final extras = result.extras;
      final pierce = face.hasKeyword(FaceKeyword.pierce) ||
          extras.pierces ||
          (actor.isPlayer && _core.piercing);
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
      final healing = _healDealt(actor, face, result.healingDone);
      // A heal mends the member it is aimed at (heal_target.dart): by
      // default the most wounded one standing. What heals past full counts
      // on them.
      final healed = healing > 0 && _roleOf(result) == FaceRole.heal
          ? _healTargetFor(actor)
          : actor;
      final watchfire =
          actor.isPlayer && _core.core == ProfessionCore.watchfire;
      if (watchfire && healing > 0) {
        _watchfireOnHeal(actor, healing, newEntries, lang, healed: healed);
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
              currentHealth: healed.currentHealth,
              maxHealth: healed.maxHealth)
          : 0;
      // The Stitch-Thrust: healing past full strikes the foe (step 3c).
      if (actor.isPlayer && healing > 0) {
        _stitchThrust(overheal(healing, healed.currentHealth, healed.maxHealth),
            newEntries, lang);
      }
      healed.currentHealth =
          min(healed.maxHealth, healed.currentHealth + healing);
      if (healed != actor) {
        _fx(VfxStyle.heal, _memberCardKey(healed.id),
            delayMs: fxDelay, text: '+$healing', textKind: VfxTextKind.heal);
        newEntries.add(_LogEntry(
            trFor(lang, 'heal_target_log')
                .replaceAll('{name}', actor.displayName)
                .replaceAll('{target}', healed.displayName)
                .replaceAll('{n}', '$healing'),
            _LogKind.playerHeal));
      }
      if (!extras.isNone) {
        bonusRollsNext +=
            _applySkillExtrasOnCaster(actor, healing, extras, newEntries, lang);
      }
      // A Shelter passes part of every Heal to the rest of the party.
      if (combos.contains(PartyCombo.shelter) &&
          _roleOf(result) == FaceRole.heal &&
          healing > 0) {
        _shelterFrom(actor, healed, healing, newEntries, lang);
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
      // A parry (v1.214): the Defend face met an enemy's coming blow
      // instead of guarding its roller.
      _EnemyMember? parryEnemy;
      if (face.type == 'Defend' && block > 0) {
        final parryKey = _parryTargets[actor.id];
        final candidate = parryKey == null ? null : _enemyByKey(parryKey);
        if (candidate != null && _canParryEnemy(candidate)) {
          parryEnemy = candidate;
        }
      }
      actor.block = (parryEnemy != null ? 0 : block) +
          (_spellBlock[actor.id] ?? 0) +
          signShield;
      // The weak links' Fury (step 3c): the Vigil's Defend face, the
      // Penitents' Mana face.
      if (actor.isPlayer &&
          _core.core == ProfessionCore.fury &&
          ((face.type == 'Defend' && _core.has(Spec.standfast)) ||
              (face.type == 'Mana' && _core.has(Spec.burningPenance)))) {
        _addFury(newEntries, lang);
      }
      // The Last Watch: a Defend face feeds the fire.
      if (actor.isPlayer &&
          face.type == 'Defend' &&
          block > 0 &&
          _core.has(Spec.longVigil) &&
          _core.mods.defendFeedsFire) {
        _core.fire = min(
            (actor.maxHealth * watchfireCapShare).round(), _core.fire + block);
      }
      // A ward (Glacial Ward, Thornwall) wounds whoever strikes it.
      actor.reflect = result.blockAmount > 0 ? extras.reflect : null;
      if (parryEnemy != null) {
        final amount = parryAmount(block);
        parryEnemy.parryBlock += amount;
        newEntries.add(_LogEntry(
            trFor(lang, 'parry_set_log')
                .replaceAll('{name}', actor.displayName)
                .replaceAll('{enemy}', parryEnemy.displayName)
                .replaceAll('{n}', '$amount'),
            _LogKind.playerBlock));
      }
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
        // A skill of several blows (Gale Cut) lands them one by one: a
        // raised guard soaks the first and the rest go through.
        final blows = max(1, extras.strikes);
        var landed = 0;
        var blowsLanded = 0;
        for (var blow = 1; blow <= blows; blow++) {
          if (blow > 1 && !target.isAlive) break;
          final share = blows > 1 ? (damage / blows).round() : damage;
          final one = _landHitOnEnemy(target, share, element, newEntries, lang,
              pierce: pierce, edge: actor.isPlayer);
          target.currentHealth = max(0, target.currentHealth - one);
          landed += one;
          if (one > 0) blowsLanded++;
          if (blows > 1 && one > 0) {
            newEntries.add(_LogEntry(
              trFor(lang, 'skill_blow_lands')
                  .replaceAll('{i}', '$blow')
                  .replaceAll('{n}', '$one'),
              _LogKind.playerDamage,
            ));
          }
        }
        dealt = landed;
        _bestHitThisRound = max(_bestHitThisRound, landed);
        if (landed > target.topHitDamage) {
          target.topHitDamage = landed;
          target.topHitterId = actor.id;
        }
        if (landed > 0) {
          lastDamagedEnemyKey = target.key;
          lastEnemyDamage = landed;
          hitsLanded += max(1, blowsLanded);
          // The Crow's Price steals on each hit the player lands.
          if (actor.isPlayer) _crowsHits++;
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
        if (actor.isPlayer) {
          _applySpecsOnHit(actor, target, landed, newEntries, lang);
        }
        if (element != 'None' && landed > 0) {
          target.elementsHitThisRound.add(element);
          _reactOnHit(target, element, landed, newEntries, lang);
        }
        // A Cleave, or any strike of a Volley, catches the rest of the pack
        // (a Cleave for more).
        final cleave = face.hasKeyword(FaceKeyword.cleave);
        if (damage > 0 && extras.splashShare > 0) {
          // A chain or a volley skill (Chain Lightning, Rain of Arrows).
          _splashFrom(actor, target, damage, extras.splashShare, element,
              pierce, newEntries, lang,
              limit: extras.splashTargets,
              logKey: extras.splashTargets > 0
                  ? 'skill_chain_hits'
                  : 'splash_hits');
        } else if (damage > 0 &&
            (cleave || combos.contains(PartyCombo.volley))) {
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
        final rawInflicted = result.inflictedStatus;
        // The Fen's Terms: a poison the player inflicts runs longer.
        final inflicted = rawInflicted != null && actor.isPlayer
            ? _signs.playerInflicted(rawInflicted)
            : rawInflicted;
        // The status lands on the one struck, or on every enemy standing
        // (Winter's Hush); a second status rides beside it.
        final laid = [
          if (inflicted != null) inflicted,
          if (extras.secondStatus != null) extras.secondStatus!,
        ];
        if (laid.isNotEmpty) {
          for (final enemy in extras.statusAll
              ? _enemies.where((e) => e.isAlive).toList()
              : [target]) {
            for (final status in laid) {
              enemy.statusEffects =
                  applyStatusEffect(enemy.statusEffects, status);
              newEntries.add(_LogEntry(
                _statusInflictedMessage(status, enemy.displayName, lang),
                _LogKind.info,
              ));
            }
          }
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
          // The Berserker's life paid feeds Fury (specialisations.dart);
          // the Tar-Hands bleed it into the foe.
          if (actor.isPlayer && _core.has(Spec.berserker)) {
            for (var i = 0; i < _core.mods.painFury; i++) {
              _addFury(newEntries, lang);
            }
            if (_core.mods.painBleeds && target != null && target.isAlive) {
              target.currentHealth = max(0, target.currentHealth - cost);
            }
          }
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
        // A heal on another member shows on their card (above).
        healing: healed == actor ? healing : 0,
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
    _bonusRollsNext += bonusRollsNext;
    manaGained += _applyAfterFaceCombos(combos, newEntries, lang);
    _applyDuos(newEntries, lang);
    _feedSignKills(newEntries, lang);

    _guardianId =
        _party.where((m) => !m.isKnockedOut).length > 1 ? guardianId : null;
    _checkChargeBreaks(newEntries, lang);
    _applyEnemyResponses(played, results, newEntries, lang);
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
      final overflow = _mana + manaGained - _maxMana;
      // Kept in the fight; the session takes it when the fight ends
      // (applyCombatResult, applyRetreat: v1.713).
      _mana = min(_maxMana, _mana + manaGained);
      _censerBurn(overflow, newEntries, lang);
    }

    _noteGoalProgress(newEntries, lang);
    _noteFightLength(newEntries, lang);
    _noteSkittishFlights(newEntries, lang);

    _update(() {
      _awaitingDecision = false;
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _parryTargets.clear();
      _dieLocks.clear();
      _healTargets.clear();
      _steadyActorIds.clear();
      _selectedActorId = null;
      if (lastDamagedEnemyKey != null) {
        _lastDamagedEnemyKey = lastDamagedEnemyKey;
        _lastEnemyDamageTaken = lastEnemyDamage;
      }
      _log.addAll(newEntries);
      _settlingRound = true;
    });

    // Give the round's effects time to land before the enemy answers.
    await Future.delayed(Duration(
        milliseconds: _quick
            ? 60
            : _effectsOn
                ? max(400, (fxIndex - 1) * _fxStagger + 450)
                : 400));
    if (!mounted) return;
    _settlingRound = false;

    if (_enemies.every((e) => !e.isAlive)) {
      unawaited(_finishFight(won: true));
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
    // The Writ (v1.212, see doctrine.dart) silences every third round.
    final writ = _writFalls(_roundsStarted);
    if (writ) _silenced = true;
    _bestHitThisRound = 0;
    _signGuardArmed = false;
    // An enemy that fell in their turn (poison, thorns, a guard sign)
    // feeds a kill-heal sign now.
    _feedSignKills(newEntries, lang);
    // The ground's anomaly: its omen, its break, its tick, its end.
    _groundRoundStart(newEntries, lang);
    // The Tide, risen this round (fight_length.dart).
    final tide = tideLevel(_roundsStarted);
    if (tide > 0) {
      newEntries.add(_LogEntry(
          trFor(lang, tide == 1 ? 'tide_turns_log' : 'tide_rises_log')
              .replaceAll('{party}', '${(tidePartyStep * tide * 100).round()}')
              .replaceAll('{enemies}', '${_tideEnemyPercent(_roundsStarted)}'),
          _LogKind.info));
    }
    // The place's rule (context_rules.dart): its omen, its rise, its toll,
    // the watch.
    final watch = _contextRoundStart(newEntries, lang);
    // The ranger sees the next face of the Trail.
    _noteTrailAhead(newEntries, lang);
    if (_silenced) {
      newEntries.add(_LogEntry(
          trFor(lang, writ ? 'writ_log' : 'silence_round_note'),
          _LogKind.enemyDamage));
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
      enemy.parryBlock = 0;
      enemy.topHitDamage = 0;
      enemy.topHitterId = null;
    }

    final sellswordWon = !playerDied && _sellswordStrikes(newEntries, lang);
    // What is left of the Watchfire burns as the round turns.
    final fireWon =
        !playerDied && !sellswordWon && _burnWatchfire(newEntries, lang);

    _update(() {
      _log.addAll(newEntries);
      _rollCount = 0;
      _bonusRolls = _bonusRollsNext;
      _bonusRollsNext = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _dieLocks.clear();
      _healTargets.clear();
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
    if (sellswordWon || fireWon || (watch ?? false)) {
      _finishFight(won: true);
      return;
    }
    if (watch == false) {
      _brokenUp();
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
}
