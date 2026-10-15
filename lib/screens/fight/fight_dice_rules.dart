part of '../fight_screen.dart';

/// What the whole party's dice add up to this round, worked out without
/// the dice's luck: each acting member's [_FacePreview], the party combos
/// the faces make and the duo techniques that would fire.
class _RoundPlan {
  const _RoundPlan({
    required this.previews,
    required this.combos,
    required this.duos,
  });

  static const _RoundPlan empty =
      _RoundPlan(previews: {}, combos: {}, duos: []);

  final Map<String, _FacePreview> previews;
  final Set<PartyCombo> combos;
  final List<DuoTechnique> duos;
}

/// The dice's own rules (v1.182): keywords, party combos, duo techniques,
/// the enemies' tampering and Luck nudges.
extension _FightDiceRules on _FightScreenState {
  /// A rolled face of [actor]'s die as it lands this round: the player's
  /// skill pick, the player's strike signs, then the fight's tampering
  /// (see [_tampered]).
  DiceFaceResult _landedFace(_PartyMember actor, DiceFaceResult rawRoll) {
    final lang = ref.read(appLanguageProvider);
    final faces = actor.dieFaces;
    final face = applyFaceAssignment(
      rawRoll,
      rawRoll.faceIndex < faces.length ? faces[rawRoll.faceIndex] : null,
      actor.diceSkillAssignments[rawRoll.faceIndex.toString()],
      language: lang,
    );
    return _tampered(actor, _signedFace(actor, face), lang);
  }

  /// [face] with the player's strike signs on it: an Attack face takes
  /// their keywords, and their element when it has none of its own. What
  /// the element and keywords do from there is the face's own business
  /// (the gear's elemental bonus, weaknesses, a Cleave's splash...).
  DiceFaceResult _signedFace(_PartyMember actor, DiceFaceResult face) {
    if (!actor.isPlayer || face.type != 'Attack') return face;
    var signed = face;
    if (_signs.strikeKeywords.isNotEmpty) {
      signed =
          signed.withKeywords({...face.keywords, ..._signs.strikeKeywords});
    }
    if (_signs.strikeElement.isNotEmpty && face.element == 'None') {
      signed = signed.withElement(_signs.strikeElement);
    }
    return signed;
  }

  /// [face]'s number with the player's guard, mend and spell signs on it
  /// (see SignEffects.guardValue and friends).
  DiceFaceResult _signedValue(_PartyMember actor, DiceFaceResult face) {
    if (!actor.isPlayer || _signs.isEmpty) return face;
    return switch (face.type) {
      'Defend' => face.withValue(_signs.guardValue(face.value)),
      'Heal' => face.withValue(_signs.mendValue(face.value, actor.wisdom ~/ 2)),
      'Mana' => face.withValue(_signs.manaValue(face.value)),
      _ => face,
    };
  }

  /// [face] of [actor]'s die under the enemies' tampering this round: a
  /// Curse on the face, then a Silence over the round.
  DiceFaceResult _tampered(
      _PartyMember actor, DiceFaceResult face, AppLanguage lang) {
    if (_cursedFaces[actor.id]?.contains(face.faceIndex) ?? false) {
      face =
          cursedFace(face).withFaceName(rolledFaceName(cursedFace(face), lang));
    }
    if (_silenced && face.type == 'Skill') {
      final silenced = silencedFace(face);
      face = silenced.withFaceName(silenced.type == 'Empty'
          ? trFor(lang, 'silenced_face_label')
          : rolledFaceName(silenced, lang));
    }
    return face;
  }

  /// Marks every member whose face just landed Steady: kept through the
  /// rerolls, and not to be released.
  void _noteSteadyFaces(Iterable<String> memberIds) {
    for (final id in memberIds) {
      final face = _currentFaces[id];
      if (face != null && face.hasKeyword(FaceKeyword.steady)) {
        _steadyActorIds.add(id);
        _lockedActorIds.add(id);
      } else {
        _steadyActorIds.remove(id);
      }
    }
  }

  /// The faces the party plays this round, by member id in acting order:
  /// the landed faces, with an Echo copying the face played before it (the
  /// first in line repeats what they played last round). The copy plays
  /// under this round's tampering like any face that lands now: a Silence
  /// blanks a copied skill, a Curse on the Echo face makes it a Pain strike.
  Map<String, DiceFaceResult> _playedFaces() {
    final lang = ref.read(appLanguageProvider);
    final echoTag = ' (${trFor(lang, 'keyword_echo')})';
    final played = <String, DiceFaceResult>{};
    DiceFaceResult? previous;
    for (final actor in _actingParty) {
      var face = _currentFaces[actor.id];
      if (face == null) continue;
      if (face.hasKeyword(FaceKeyword.echo)) {
        final source = previous ?? _lastPlayedFaces[actor.id];
        if (source != null) {
          // An echo of an echo is named once, not once a round.
          final name = source.faceName.endsWith(echoTag)
              ? source.faceName
                  .substring(0, source.faceName.length - echoTag.length)
              : source.faceName;
          final copy = _tampered(
              actor,
              DiceFaceResult(
                faceIndex: face.faceIndex,
                faceName: name,
                type: source.type,
                value: source.value,
                linkedSkillID: source.linkedSkillID,
                element: source.element,
                channeledFrom: source.channeledFrom,
                keywords: {...source.keywords}..remove(FaceKeyword.echo),
              ),
              lang);
          face = copy.withFaceName('${copy.faceName}$echoTag');
        }
      }
      played[actor.id] = face;
      previous = face;
    }
    return played;
  }

  /// What Growth and Steady add to [face] for [actor] this round.
  int _flatBonusFor(_PartyMember actor, DiceFaceResult face) {
    var bonus = 0;
    if (face.hasKeyword(FaceKeyword.growth)) {
      bonus += (_growthUses['${actor.id}:${face.faceIndex}'] ?? 0) * growthStep;
    }
    if (face.hasKeyword(FaceKeyword.steady)) bonus += steadyBonus;
    return bonus;
  }

  /// The skills [actor] can cast with [face]: their own, plus the skill an
  /// Echo copied from someone else (at its base tier).
  Map<String, dynamic> _skillsForFace(
      _PartyMember actor, DiceFaceResult face, Map<String, dynamic> skills) {
    final own = _availableSkillsFor(actor, skills);
    if (face.type != 'Skill') return own;
    final id = _effectiveSkillId(face);
    if (own.containsKey(id) || !skills.containsKey(id)) return own;
    return {...own, id: skills[id]};
  }

  /// [face] resolved for [actor]: Growth and Steady on its number (or, on a
  /// skill, on its damage), Pain doubling a strike. A critical is rolled
  /// only when [rollCritical] (the confirm); [surge] forces one.
  PlayerActionResult _resolveFor(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    AppLanguage lang, {
    required bool surge,
    bool rollCritical = false,
  }) {
    final bonus = _flatBonusFor(actor, face);
    final basic =
        face.type == 'Attack' || face.type == 'Defend' || face.type == 'Heal';
    final played = _signedValue(
        actor, bonus > 0 && basic ? face.withValue(face.value + bonus) : face);
    var damage = _totalDamageFor(actor, played, skills, items) +
        (played.type == 'Skill' ? bonus : 0);
    // The player's strike signs: an Attack face's flat damage and its
    // share, and the low-health and first-round shares on any strike.
    if (actor.isPlayer && (played.type == 'Attack' || played.type == 'Skill')) {
      final attack = played.type == 'Attack';
      damage = _signs.strikeBase(damage, played.value,
          attackFace: attack,
          percent: _signs.strikePercentFor(
            attackFace: attack,
            currentHealth: actor.currentHealth,
            maxHealth: actor.maxHealth,
            firstRound: _roundsStarted <= 1,
          ));
    }
    final result = resolvePlayerFace(
      played,
      _skillsForFace(actor, played, skills),
      damage,
      language: lang,
      activeEffects: actor.statusEffects,
      wisdomHealBonus: actor.wisdom ~/ 2,
      wisdomManaBonus: wisdomManaBonusFor(actor.wisdom),
      luck: rollCritical
          ? actor.luck +
              (actor.isPlayer && _luckyCoinArmed ? _luckyCoinLuckBonus : 0)
          : 0,
      random: rollCritical ? _random : null,
      forceCritical: surge,
      alignmentLabel: _alignmentLabel,
      critChanceBonus: rollCritical ? actor.gear.critChance : 0,
      armor: actor.armor,
    );
    if (!played.hasKeyword(FaceKeyword.pain) || result.damageDealt <= 0) {
      return result;
    }
    final doubled = result.damageDealt * painDamageMultiplier;
    return PlayerActionResult(
      damageDealt: doubled,
      healingDone: result.healingDone,
      blockAmount: result.blockAmount,
      message: '${result.message} (${trFor(lang, 'keyword_pain')}: $doubled)',
      inflictedStatus: result.inflictedStatus,
      isCritical: result.isCritical,
      manaGained: result.manaGained,
      extras: result.extras,
    );
  }

  FaceRole _roleOf(PlayerActionResult result) => faceRoleOf(
        damage: result.damageDealt,
        block: result.blockAmount,
        heal: result.healingDone,
        mana: result.manaGained,
      );

  /// Whether the face [actor] rolled this round is one of their die's own
  /// signature skill faces (and still casts it).
  bool _onSignatureFace(_PartyMember actor) {
    final face = _currentFaces[actor.id];
    if (face == null || face.type != 'Skill') return false;
    if (face.faceIndex >= actor.dieFaces.length) return false;
    final raw = actor.dieFaces[face.faceIndex];
    return raw['type'] == 'Skill' && !isAssignableFace(raw);
  }

  /// The duo techniques the acting companions' faces would fire now.
  List<DuoTechnique> _duosNow() => duosFiring([
        for (final actor in _actingParty)
          if (!actor.isPlayer)
            DuoCandidate(
              companionId: actor.id,
              approval: actor.approval,
              onSignatureFace: _onSignatureFace(actor),
            ),
      ]);

  /// The round as the dice stand (see [_RoundPlan]).
  _RoundPlan _roundPlan(
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    AppLanguage lang,
  ) {
    if (_rolling || _currentFaces.isEmpty) return _RoundPlan.empty;
    final played = _playedFaces();
    final surgeTo = _surgeRecipient(played);
    final results = <String, PlayerActionResult>{};
    for (final actor in _actingParty) {
      final face = played[actor.id];
      if (face == null) continue;
      results[actor.id] = _resolveFor(actor, face, skills, items, lang,
          surge: actor.id == surgeTo);
    }
    final combos = partyCombosFor([for (final r in results.values) _roleOf(r)]);
    final previews = <String, _FacePreview>{};
    for (final actor in _actingParty) {
      final face = played[actor.id];
      final result = results[actor.id];
      if (face == null || result == null) continue;
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      final target = isStrike ? _strikeTargetFor(actor) : null;
      final dealt = comboDamage(result.damageDealt, combos);
      final damage = target == null
          ? dealt
          : face.hasKeyword(FaceKeyword.pierce)
              ? dealt
              : strikeDamageAfterAffixes(dealt, face.type,
                  armored: target.hasAffix(EnemyAffix.armored));
      var healing = result.healingDone;
      if (_condition == BattlefieldCondition.shrine && healing > 0) {
        healing = (healing * shrineHealMultiplier).round();
      }
      var block = result.blockAmount;
      if (block > 0 && _isTelegraphedTarget(actor)) {
        block *= _telegraphBraceMultiplier;
      }
      if (_condition == BattlefieldCondition.highGround && block > 0) {
        block = (block * highGroundBlockMultiplier).round();
      }
      previews[actor.id] = _FacePreview(
        result: result,
        target: target,
        damage: damage,
        healing: healing,
        block: block,
        surge: actor.id == surgeTo,
      );
    }
    return _RoundPlan(previews: previews, combos: combos, duos: _duosNow());
  }

  /// Plays the round's party combos that act after the faces: a Shield
  /// Wall's shared block and a Wellspring's mana (a Flank's and a Volley's
  /// damage, and a Shelter's heal, land with the faces in [_confirmRoll]).
  /// Returns the mana a Wellspring adds.
  int _applyAfterFaceCombos(
      Set<PartyCombo> combos, List<_LogEntry> entries, AppLanguage lang) {
    for (final combo in combos) {
      entries.add(_LogEntry(
        '${trFor(lang, comboLabelKey(combo))}! '
        '${trFor(lang, comboDescriptionKey(combo))}',
        _LogKind.playerBlock,
      ));
    }
    if (combos.contains(PartyCombo.shieldWall)) {
      var wall = 0;
      for (final member in _actingParty) {
        wall = max(wall, member.block);
      }
      for (final member in _party) {
        if (member.isKnockedOut) continue;
        member.block = max(member.block, wall);
        _fx(VfxStyle.shield, _memberCardKey(member.id), delayMs: 250);
      }
    }
    return combos.contains(PartyCombo.wellspring) ? wellspringMana : 0;
  }

  /// A Shelter: [healer]'s heal of [healing] reaches every other party
  /// member standing at [shelterShare].
  void _shelterFrom(_PartyMember healer, int healing, List<_LogEntry> entries,
      AppLanguage lang) {
    final share = (healing * shelterShare).round();
    if (share <= 0) return;
    for (final member in _party) {
      if (member.id == healer.id || member.isKnockedOut) continue;
      member.currentHealth =
          min(member.maxHealth, member.currentHealth + share);
      _fx(VfxStyle.heal, _memberCardKey(member.id),
          delayMs: 300, text: '+$share', textKind: VfxTextKind.heal);
    }
    entries.add(_LogEntry(
      trFor(lang, 'shelter_heals')
          .replaceAll('{name}', healer.displayName)
          .replaceAll('{n}', '$share'),
      _LogKind.playerHeal,
    ));
  }

  /// What a skill's [extras] do for its caster's side once its heal has
  /// landed: cleanse [caster], mend the whole party for [healing], fill the
  /// momentum. Returns the rerolls the skill grants the next round.
  int _applySkillExtrasOnCaster(_PartyMember caster, int healing,
      SkillExtras extras, List<_LogEntry> entries, AppLanguage lang) {
    final cleansed = extras.cleanse.isEmpty
        ? const <_PartyMember>[]
        : [
            for (final member in extras.healAll && extras.cleanse == 'All'
                ? _party.where((m) => !m.isKnockedOut)
                : [caster])
              if (member.statusEffects.isNotEmpty) member,
          ];
    for (final member in cleansed) {
      final after = extras.cleansed(member.statusEffects);
      if (after.length == member.statusEffects.length) continue;
      member.statusEffects = after;
      _fx(VfxStyle.radiance, _memberCardKey(member.id), delayMs: 300);
      entries.add(_LogEntry(
        trFor(lang, 'skill_cleansed').replaceAll('{name}', member.displayName),
        _LogKind.playerHeal,
      ));
    }
    if (extras.healAll && healing > 0) {
      for (final member in _party) {
        if (member.id == caster.id || member.isKnockedOut) continue;
        final before = member.currentHealth;
        member.currentHealth = min(member.maxHealth, before + healing);
        final gained = member.currentHealth - before;
        if (gained <= 0) continue;
        _fx(VfxStyle.heal, _memberCardKey(member.id),
            delayMs: 300, text: '+$gained', textKind: VfxTextKind.heal);
        entries.add(_LogEntry(
          trFor(lang, 'skill_party_mended')
              .replaceAll('{name}', member.displayName)
              .replaceAll('{n}', '$gained'),
          _LogKind.playerHeal,
        ));
      }
    }
    if (extras.chargesMomentum && _momentum < _momentumNeeded) {
      _momentum = _momentumNeeded;
      entries
          .add(_LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
    }
    if (extras.bonusRolls > 0) {
      entries.add(_LogEntry(trFor(lang, 'skill_bonus_roll'), _LogKind.info));
    }
    return extras.bonusRolls;
  }

  /// A Cleave or a Volley: the rest of the enemies standing take [share] of
  /// [damage] (their guards and weaknesses count; a Pierce goes through the
  /// guards).
  void _splashFrom(
      _PartyMember actor,
      _EnemyMember target,
      int damage,
      double share,
      String element,
      bool pierce,
      List<_LogEntry> entries,
      AppLanguage lang,
      {int limit = 0,
      String logKey = 'splash_hits'}) {
    final splash = (damage * share).round();
    if (splash <= 0) return;
    var reached = 0;
    for (final other in _enemies) {
      if (other.key == target.key || !other.isAlive) continue;
      // A chain stops after [limit] other enemies (0 = the whole pack).
      if (limit > 0 && reached >= limit) break;
      reached++;
      final landed = _landHitOnEnemy(other, splash, element, entries, lang,
          pierce: pierce);
      if (landed <= 0) continue;
      other.currentHealth = max(0, other.currentHealth - landed);
      _bestHitThisRound = max(_bestHitThisRound, landed);
      _fx(VfxStyle.whirl, _enemyCardKey(other.key),
          delayMs: 200, text: '-$landed', textKind: VfxTextKind.damage);
      entries.add(_LogEntry(
        trFor(lang, logKey)
            .replaceAll('{name}', other.displayName)
            .replaceAll('{n}', '$landed'),
        _LogKind.playerDamage,
      ));
    }
  }

  /// Fires every duo technique the round's faces call for (see
  /// duo_techniques.dart), after the faces themselves.
  void _applyDuos(List<_LogEntry> entries, AppLanguage lang) {
    final french = lang == AppLanguage.fr;
    for (final duo in _duosNow()) {
      final first = _memberById(duo.first);
      final second = _memberById(duo.second);
      if (first == null || second == null) continue;
      final power = duoPower(first.baseDamage, second.baseDamage);
      final target = _strikeTargetFor(first) ??
          _strikeTargetFor(second) ??
          _firstLivingEnemy();
      entries.add(_LogEntry(
        '${duo.nameFor(french)}! ${duo.descriptionFor(french)}',
        _LogKind.phase,
      ));
      void strike(_EnemyMember enemy, int amount, {VfxStyle? style}) {
        if (!enemy.isAlive || amount <= 0) return;
        final landed = _landHitOnEnemy(enemy, amount, 'None', entries, lang);
        enemy.currentHealth = max(0, enemy.currentHealth - landed);
        _bestHitThisRound = max(_bestHitThisRound, landed);
        _fx(style ?? VfxStyle.heavySlash, _enemyCardKey(enemy.key),
            delayMs: 350, text: '-$landed', textKind: VfxTextKind.damage);
      }

      void mend(_PartyMember member, int amount) {
        if (member.isKnockedOut || amount <= 0) return;
        member.currentHealth =
            min(member.maxHealth, member.currentHealth + amount);
        _fx(VfxStyle.heal, _memberCardKey(member.id),
            delayMs: 350, text: '+$amount', textKind: VfxTextKind.heal);
      }

      switch (duo.effect) {
        case DuoEffect.stunBlow:
          if (target == null) break;
          strike(target, power, style: VfxStyle.quake);
          if (target.isAlive) {
            target.statusEffects = applyStatusEffect(
                target.statusEffects,
                const StatusEffect(
                    type: StatusEffectType.stun, remainingTurns: 1));
          }
        case DuoEffect.poisonCrit:
          if (target == null) break;
          final blow = criticalDamage(power);
          final before = target.currentHealth;
          strike(target, blow, style: VfxStyle.crit);
          final landed = before - target.currentHealth;
          if (target.isAlive) {
            target.statusEffects = applyStatusEffect(
                target.statusEffects,
                StatusEffect(
                    type: StatusEffectType.poison,
                    remainingTurns: duoPoisonTurns,
                    magnitude: max(3, landed ~/ 5)));
          }
        case DuoEffect.partyHeal:
          for (final member in _party) {
            if (member.isKnockedOut) continue;
            mend(member, (member.maxHealth * duoHealShare).round());
            member.statusEffects = [];
          }
        case DuoEffect.starfall:
          for (final enemy in [..._enemies]) {
            strike(enemy, (power * duoVolleyShare).round(),
                style: VfxStyle.volley);
          }
        case DuoEffect.weakenAll:
          for (final enemy in [..._enemies]) {
            strike(enemy, power ~/ 2, style: VfxStyle.shadow);
            if (enemy.isAlive) {
              enemy.statusEffects = applyStatusEffect(
                  enemy.statusEffects,
                  const StatusEffect(
                      type: StatusEffectType.weaken,
                      remainingTurns: duoWeakenTurns,
                      magnitude: duoWeakenPercent));
            }
          }
        case DuoEffect.partyWard:
          for (final member in _party) {
            if (member.isKnockedOut) continue;
            member.block += power ~/ 2;
            _fx(VfxStyle.stoneShield, _memberCardKey(member.id),
                delayMs: 350,
                text: '+${power ~/ 2}',
                textKind: VfxTextKind.block);
          }
        case DuoEffect.mercyShot:
          _PartyMember? worst;
          for (final member in _party) {
            if (member.isKnockedOut) continue;
            if (worst == null ||
                member.currentHealth / member.maxHealth <
                    worst.currentHealth / worst.maxHealth) {
              worst = member;
            }
          }
          if (worst != null) {
            mend(worst, (worst.maxHealth * duoMendShare).round());
          }
          if (target != null) strike(target, power, style: VfxStyle.arrow);
        case DuoEffect.bloodOath:
          if (target == null) break;
          final before = target.currentHealth;
          strike(target, (power * duoOathMultiplier).round(),
              style: VfxStyle.drain);
          final landed = before - target.currentHealth;
          mend(first, landed ~/ 4);
          mend(second, landed ~/ 4);
      }
    }
  }

  /// An enemy's Hex, Silence or Curse on the party's dice (see
  /// dice_tamper.dart), aimed at [targetId] for a Curse.
  void _applyTamper(_EnemyMember enemy, EnemyMoveResult move, String targetId,
      AppLanguage lang, int delay) {
    final key = _enemyCardKey(enemy.key);
    _fx(VfxStyle.voidRift, key, delayMs: delay);
    switch (move.tamper) {
      case DiceTamper.hex:
        _update(() {
          _hexPending = true;
          _log.add(_LogEntry(
              '${move.message} ${trFor(lang, 'tamper_hex_laid')}',
              _LogKind.enemyDamage));
        });
      case DiceTamper.silence:
        _update(() {
          _silencePending = true;
          _log.add(_LogEntry(
              '${move.message} ${trFor(lang, 'tamper_silence_laid')}',
              _LogKind.enemyDamage));
        });
      case DiceTamper.curse:
        var member = _memberById(targetId);
        if (member == null || member.isKnockedOut) {
          final conscious = _party.where((m) => !m.isKnockedOut).toList();
          if (conscious.isEmpty) return;
          member = conscious[_random.nextInt(conscious.length)];
        }
        final cursed = _cursedFaces.putIfAbsent(member.id, () => <int>{});
        final index = curseTargetFace(member.dieFaces.length, cursed, _random);
        final victim = member;
        // The Ember face lifts the Curse at once, while it lasts.
        if (index != null && victim.isPlayer && _emberCharges > 0) {
          _emberCharges--;
          _update(() => _log.add(_LogEntry(
                '${move.message} ${trFor(lang, 'sign_log_ember')}',
                _LogKind.playerHeal,
              )));
          _fx(VfxStyle.holyFire, _memberCardKey(victim.id),
              delayMs: delay + 200);
          return;
        }
        _update(() {
          if (index == null) {
            _log.add(_LogEntry(move.message, _LogKind.info));
            return;
          }
          cursed.add(index);
          final faceName = faceDisplayName(victim.dieFaces[index],
              assignedSkillId: victim.diceSkillAssignments[index.toString()],
              language: lang);
          _log.add(_LogEntry(
            '${move.message} ${trFor(lang, 'tamper_curse_laid').replaceAll('{name}', victim.displayName).replaceAll('{face}', faceName)}',
            _LogKind.enemyDamage,
          ));
        });
        _fx(VfxStyle.weaken, _memberCardKey(victim.id), delayMs: delay + 200);
      case DiceTamper.mirror:
      case null:
        _update(() => _log.add(_LogEntry(move.message, _LogKind.info)));
    }
  }

  /// A Hex laid last round rolls the best die of the party's first roll
  /// again (see [hexVictim]); a Steady die holds where it landed.
  void _springHex(Map<String, dynamic> skills, Map<String, dynamic> items) {
    if (!_hexPending) return;
    _hexPending = false;
    final lang = ref.read(appLanguageProvider);
    final plan = _roundPlan(skills, items, lang);
    final victimId = hexVictim({
      for (final entry in plan.previews.entries)
        if (!_steadyActorIds.contains(entry.key))
          entry.key: entry.value.damage +
              entry.value.healing +
              entry.value.block +
              entry.value.result.manaGained,
    });
    final victim = victimId == null ? null : _memberById(victimId);
    final before = victimId == null ? null : _currentFaces[victimId];
    if (victim == null || before == null || victim.dieFaces.isEmpty) return;
    final again = _landedFace(victim, rollDie(victim.dieFaces, _random));
    _fx(VfxStyle.voidRift, _memberCardKey(victim.id), delayMs: 100);
    _update(() {
      _currentFaces[victim.id] = again;
      // Rolled again, the die is kept only if it lands Steady now.
      _lockedActorIds.remove(victim.id);
      _noteSteadyFaces([victim.id]);
      _autoAssignTargets();
      _log.add(_LogEntry(
        trFor(lang, 'tamper_hex_sprung')
            .replaceAll('{name}', victim.displayName)
            .replaceAll('{from}', before.faceName)
            .replaceAll('{to}', again.faceName),
        _LogKind.enemyDamage,
      ));
    });
  }

  /// A Luck nudge: [actor]'s landed die turns to its opposite face (see
  /// nudgedFaceIndex) and is kept.
  void _nudge(_PartyMember actor) {
    if (!_awaitingDecision || _rolling || _over || _nudgesLeft <= 0) return;
    final face = _currentFaces[actor.id];
    final faces = actor.dieFaces;
    if (face == null || faces.isEmpty) return;
    final opposite = nudgedFaceIndex(face.faceIndex, faces.length);
    if (opposite == null) return;
    final flipped = _landedFace(actor, faceFromJson(faces[opposite], opposite));
    final lang = ref.read(appLanguageProvider);
    _fx(VfxStyle.crit, _memberCardKey(actor.id));
    _update(() {
      _nudgesLeft--;
      _currentFaces[actor.id] = flipped;
      _lockedActorIds.add(actor.id);
      _noteSteadyFaces([actor.id]);
      _autoAssignTargets();
      _log.add(_LogEntry(
        trFor(lang, 'nudge_log')
            .replaceAll('{name}', actor.displayName)
            .replaceAll('{from}', face.faceName)
            .replaceAll('{to}', flipped.faceName),
        _LogKind.info,
      ));
    });
  }

  /// The face opposite [actor]'s landed one, as it would land -- what a
  /// nudge would give (shown before spending it). Null when there is none
  /// to turn to (the middle face of an odd die).
  DiceFaceResult? _nudgePreview(_PartyMember actor) {
    final face = _currentFaces[actor.id];
    final faces = actor.dieFaces;
    if (face == null || faces.isEmpty) return null;
    final opposite = nudgedFaceIndex(face.faceIndex, faces.length);
    if (opposite == null) return null;
    return _landedFace(actor, faceFromJson(faces[opposite], opposite));
  }

  // --- The hero's profession core (profession_cores.dart) -----------------

  /// The ranger's Trail: the next face of the die drawn as a deck.
  DiceFaceResult _trailFace(List<Map<String, dynamic>> faces) {
    final index = _core.deckFor(faces.length, _random).draw();
    return faceFromJson(faces[index], index);
  }

  /// The ranger sees the face the Trail deals next.
  void _noteTrailAhead(List<_LogEntry> entries, AppLanguage lang) {
    if (_core.core != ProfessionCore.trail) return;
    final hero = _party.where((m) => m.isPlayer && !m.isKnockedOut);
    final faces =
        hero.isEmpty ? const <Map<String, dynamic>>[] : hero.first.dieFaces;
    if (faces.isEmpty) return;
    final index = _core.deckFor(faces.length, _random).peek();
    final assigned = hero.first.diceSkillAssignments['$index'];
    final name = assigned != null && assigned.isNotEmpty
        ? skillDisplayName(assigned, language: lang)
        : faces[index]['faceName']?.toString() ?? '';
    if (name.isEmpty) return;
    entries.add(_LogEntry(
        trFor(lang, 'trail_ahead_log').replaceAll('{face}', name),
        _LogKind.info));
  }

  /// The hero's core on the round's results: Flurry's second strike, Fury's
  /// heavy blow, the Ash Well's doubled mana.
  void _applyHeroCore(
    Map<String, DiceFaceResult> played,
    Map<String, PlayerActionResult> results,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    AppLanguage lang,
    List<_LogEntry> entries,
  ) {
    final heroes = _actingParty.where((m) => m.isPlayer);
    if (heroes.isEmpty) return;
    final hero = heroes.first;
    final face = played[hero.id];
    var result = results[hero.id];
    if (face == null || result == null) return;
    switch (_core.core) {
      case ProfessionCore.flurry:
        if (result.damageDealt <= 0) return;
        final second = _resolveFor(hero, face, skills, items, lang,
            surge: false, rollCritical: true);
        result = coreResult(result,
            damage: flurryDamage(result.damageDealt, second.damageDealt));
        entries
            .add(_LogEntry(trFor(lang, 'flurry_log'), _LogKind.playerDamage));
      case ProfessionCore.fury:
        if (result.damageDealt <= 0) return;
        if (_core.fury >= furyMax) {
          result = coreResult(result,
              damage: (result.damageDealt * furyHeavyMultiplier).round());
          _core.fury = 0;
          entries.add(
              _LogEntry(trFor(lang, 'fury_heavy_log'), _LogKind.playerDamage));
        } else {
          _addFury(entries, lang);
        }
      case ProfessionCore.ashWell:
        if (result.manaGained <= 0) return;
        result =
            coreResult(result, mana: result.manaGained * ashWellManaMultiplier);
      case ProfessionCore.watchfire:
      case ProfessionCore.trail:
      case ProfessionCore.none:
        return;
    }
    results[hero.id] = result;
  }

  /// One more Fury for the warrior, said when it is full.
  void _addFury(List<_LogEntry> entries, AppLanguage lang) {
    if (_core.fury >= furyMax) return;
    _core.fury++;
    if (_core.fury == furyMax) {
      entries.add(_LogEntry(trFor(lang, 'fury_full_log'), _LogKind.info));
    }
  }

  /// The cleric's heal of [healing] from the die: it burns the enemy the
  /// cleric faces, and what heals past full feeds the Watchfire.
  void _watchfireOnHeal(_PartyMember actor, int healing,
      List<_LogEntry> entries, AppLanguage lang) {
    _core.fire = watchfireAfterHeal(
        fire: _core.fire,
        healing: healing,
        currentHealth: actor.currentHealth,
        maxHealth: actor.maxHealth);
    final key = _selectedTargets[actor.id];
    final picked = key == null ? null : _enemyByKey(key);
    final target =
        picked != null && picked.isAlive ? picked : _firstLivingEnemy();
    if (target == null) return;
    final burn = (healing * watchfireHealBurnShare).round();
    target.currentHealth = max(0, target.currentHealth - burn);
    target.damageThisRound += burn;
    entries.add(_LogEntry(
        trFor(lang, 'watchfire_burn_log')
            .replaceAll('{name}', target.displayName)
            .replaceAll('{n}', '$burn'),
        _LogKind.playerDamage));
  }

  /// What is left of the Watchfire burns the first enemy standing. Returns
  /// true when that ends the fight.
  bool _burnWatchfire(List<_LogEntry> entries, AppLanguage lang) {
    if (_core.fire <= 0) return false;
    final target = _firstLivingEnemy();
    final burn = watchfireBurn(_core.fire);
    _core.fire = 0;
    if (target == null) return false;
    target.currentHealth = max(0, target.currentHealth - burn);
    entries.add(_LogEntry(
        trFor(lang, 'watchfire_round_log')
            .replaceAll('{name}', target.displayName)
            .replaceAll('{n}', '$burn'),
        _LogKind.playerDamage));
    return _enemies.every((e) => !e.isAlive);
  }
}
