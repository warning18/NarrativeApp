part of '../fight_screen.dart';

/// Lookups over the party and the enemies, and the numbers worked out
/// from them, shared by the rounds and the view.
extension _FightQueries on _FightScreenState {
  /// A log line's actor prefix — only shown once there's more than one
  /// combatant on the player's side, so a solo player (the common case
  /// through most of the game, before any ally is both recruited and
  /// active) sees the exact same unprefixed log this screen always had.
  String _actorPrefix(_PartyMember actor) =>
      _party.length > 1 ? '${actor.displayName}: ' : '';

  /// The highest Perception among currently-conscious party members — feeds
  /// [telegraphTierFor] for every enemy's telegraph badge. A
  /// Perception-built ally can carry the party's tactical read even if the
  /// player's own Perception is low.
  int _bestPartyPerception() {
    var best = 0;
    for (final member in _party) {
      if (member.isKnockedOut) continue;
      if (member.perception > best) best = member.perception;
    }
    return best;
  }

  /// The telegraph tier the party actually reads [enemy] at this round --
  /// [telegraphTierFor] off the party's best Perception, one step worse
  /// under a Dark battlefield, and nothing at all during an Ambush's
  /// opening round.
  TelegraphTier _effectiveTierFor(_EnemyMember enemy) {
    if (_condition == BattlefieldCondition.ambush && _roundsStarted <= 1) {
      return TelegraphTier.none;
    }
    final tier = telegraphTierFor(_bestPartyPerception(), enemy.guile);
    return _condition == BattlefieldCondition.dark ? darkenedTier(tier) : tier;
  }

  /// The elements [enemy] is known to be weak to or to resist: all of them
  /// once the party reads it at the category tier or better, or has beaten
  /// its kind before; otherwise only the ones a hit has revealed this
  /// fight.
  ({List<String> weak, List<String> resist}) _knownElementsFor(
      _EnemyMember enemy) {
    final tier = _effectiveTierFor(enemy);
    final knowsAll = tier == TelegraphTier.category ||
        tier == TelegraphTier.full ||
        (ref.read(playerSessionProvider).enemyKillCounts[enemy.enemyId] ?? 0) >
            0;
    bool known(String e) => knowsAll || enemy.revealedElements.contains(e);
    return (
      weak: enemyWeaknesses(enemy.data).where(known).toList(),
      resist: enemyResistances(enemy.data).where(known).toList(),
    );
  }

  /// Records whether any living enemy reads at the full tier right now --
  /// the spoils chest's Perception extra slot.
  void _noteTelegraphReads() {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.pendingMove == null) continue;
      if (_effectiveTierFor(enemy) == TelegraphTier.full) {
        _fullTelegraphRead = true;
      }
    }
  }

  /// True when some living enemy's pre-rolled next move is aimed at
  /// [member] AND the party can currently read that telegraph at all (see
  /// [_effectiveTierFor]) -- the condition under which a Defend face rolled
  /// by [member] braces for the visible blow ([_telegraphBraceMultiplier]).
  bool _isTelegraphedTarget(_PartyMember member) {
    for (final enemy in _enemies) {
      final pending = enemy.pendingMove;
      if (!enemy.isAlive || pending == null || pending.targetId != member.id) {
        continue;
      }
      if (_effectiveTierFor(enemy) != TelegraphTier.none) {
        return true;
      }
    }
    return false;
  }

  _PartyMember? _memberById(String id) {
    for (final member in _party) {
      if (member.id == id) return member;
    }
    return null;
  }

  /// A member's attack damage behind [face]: base, equipment, stat
  /// scaling, alignment gear, unique/set gear and the face's element
  /// bonus. The one formula [_confirmRoll], [_previewRoll] and the face
  /// sheet all use, so a number shown is a number dealt.
  int _totalDamageFor(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final availableSkills = _availableSkillsFor(actor, skills);
    final element = _elementFor(face, availableSkills);
    final elementalBonus =
        _elementalDamageBonus(element, actor.equippedItemIds, items);
    final scalingBonus = equipmentScalingBonusFor(
      actor.equippedItemIds,
      items,
      strength: actor.strength,
      dexterity: actor.dexterity,
      constitution: actor.constitution,
      intelligence: actor.intelligence,
    );
    final alignedBonus =
        alignmentGearBonusFor(actor.equippedItemIds, items, _alignmentLabel);
    return actor.baseDamage +
        equipmentBonusFor(actor.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus +
        alignedBonus.damageBonus +
        actor.gear.attackDamage +
        elementalBonus;
  }

  /// The enemy a strike by [actor] lands on if confirmed now: the only
  /// enemy in a solo fight, the aimed one in a pack, or the first still
  /// standing when the aimed one has gone down (the same redirect
  /// [_confirmRoll] makes). Null when nothing is left to hit.
  _EnemyMember? _strikeTargetFor(_PartyMember actor) {
    if (_enemies.length == 1) {
      return _enemies.first.isAlive ? _enemies.first : null;
    }
    final key = _selectedTargets[actor.id];
    final picked = key == null ? null : _enemyByKey(key);
    if (picked != null && picked.isAlive) return picked;
    return _firstLivingEnemy();
  }

  /// What [move] from [enemy] hits for before the target's defences:
  /// Weaken on the enemy, Frenzied when it is low, and a standing pack
  /// leader's boost to the rest of the pack.
  int _incomingDamage(_EnemyMember enemy, EnemyMoveResult move,
      {required bool leaderStanding, int? mirrorFrom}) {
    // A Mirror sends back the party's best blow of the round (see
    // dice_tamper.dart): the best landed, a spell's included, or while the
    // dice are still on the table, the best they would land.
    final base = move.tamper == DiceTamper.mirror
        ? mirrorDamage(
            bestPartyHit: mirrorFrom ?? _bestHitThisRound,
            enemyDamage: enemy.damage)
        : move.damage;
    var damage = applyWeaken(base, enemy.statusEffects);
    if (enemy.hasAffix(EnemyAffix.frenzied) &&
        enemy.currentHealth < enemy.maxHealth * frenziedHealthThreshold) {
      damage = (damage * frenziedDamageMultiplier).round();
    }
    if (leaderStanding && !enemy.hasAffix(EnemyAffix.packLeader)) {
      damage = (damage * packLeaderAllyDamageMultiplier).round();
    }
    // A pact's curse, while it runs (see signs.dart).
    return _signs.enemyDamage(damage);
  }

  /// How much of a hit of [element] [target]'s armor soaks: base armor,
  /// gear (with its stat scaling, alignment bonus and set/unique effects),
  /// an armed Iron Skin charm and the gear's resist to the element. Block
  /// comes on top of this.
  int _mitigationFor(
      _PartyMember target, String element, Map<String, dynamic> items) {
    final scaling = equipmentScalingBonusFor(
      target.equippedItemIds,
      items,
      strength: target.strength,
      dexterity: target.dexterity,
      constitution: target.constitution,
      intelligence: target.intelligence,
    );
    final aligned =
        alignmentGearBonusFor(target.equippedItemIds, items, _alignmentLabel);
    return target.armor +
        equipmentBonusFor(target.equippedItemIds, items, 'armor') +
        scaling.armorBonus +
        aligned.armorBonus +
        target.gear.armor +
        (target.isPlayer && _ironSkinArmed ? _ironSkinArmorBonus : 0) +
        _elementalResist(element, target.equippedItemIds, items);
  }

  /// The telegraphed hit as it would land: [enemy]'s pending move against
  /// its target, less the target's armor, resist and block -- the block
  /// already up, or the one the dice on the table would raise. Null when
  /// nothing is telegraphed.
  ({int raw, int net})? _expectedHit(_EnemyMember enemy,
      Map<String, dynamic> skills, Map<String, dynamic> items) {
    final pending = enemy.pendingMove;
    if (pending == null) return null;
    final target = _memberById(pending.targetId);
    if (target == null || target.isKnockedOut) return null;
    final leaderStanding =
        _enemies.any((e) => e.isAlive && e.hasAffix(EnemyAffix.packLeader));
    final previews = _awaitingDecision && !_rolling
        ? _previewRoll(skills, items, ref.read(appLanguageProvider))
        : const <String, _FacePreview>{};
    final raw = _incomingDamage(enemy, pending.move,
        leaderStanding: leaderStanding,
        mirrorFrom: previews.isEmpty
            ? null
            : previews.values.fold<int>(
                _bestHitThisRound, (best, p) => max(best, p.damage)));
    var block = target.block;
    final planned = previews[target.id];
    if (planned != null) {
      block = max(block, planned.block + (_spellBlock[target.id] ?? 0));
    }
    final net = max(
        0, raw - block - _mitigationFor(target, pending.move.element, items));
    return (raw: raw, net: net);
  }

  /// The acting members whose face as played this round (see
  /// [_playedFaces], [played] when already worked out) strikes: an Attack
  /// or a Skill face. What a pack fight aims, and what a surge lands on.
  Set<String> _strikerIds([Map<String, DiceFaceResult>? played]) => {
        for (final entry in (played ?? _playedFaces()).entries)
          if (entry.value.type == 'Attack' || entry.value.type == 'Skill')
            entry.key,
      };

  /// Who cashes in a ready momentum surge this round: the member the
  /// player picked, when their played face is a strike; otherwise the
  /// first acting member playing an Attack face, then a Skill face -- an
  /// Attack first, so the surge isn't spent on a skill face that only
  /// heals. [played] is [_playedFaces] when already worked out.
  String? _surgeRecipient([Map<String, DiceFaceResult>? played]) {
    if (_momentum < _momentumNeeded) return null;
    final faces = played ?? _playedFaces();
    final strikers = _strikerIds(faces);
    final picked = _surgeActorId;
    if (picked != null && strikers.contains(picked)) return picked;
    for (final actor in _actingParty) {
      if (faces[actor.id]?.type == 'Attack') return actor.id;
    }
    for (final actor in _actingParty) {
      if (strikers.contains(actor.id)) return actor.id;
    }
    return null;
  }

  /// Every acting member's [_FacePreview] for the faces on the table,
  /// keyed by member id: empty while the dice are still spinning. Walks
  /// the party in the confirm's own order so the momentum surge lands on
  /// the same strike it will land on.
  Map<String, _FacePreview> _previewRoll(
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    AppLanguage lang,
  ) =>
      _roundPlan(skills, items, lang).previews;

  _EnemyMember? _enemyByKey(String key) {
    for (final enemy in _enemies) {
      if (enemy.key == key) return enemy;
    }
    return null;
  }

  _EnemyMember? _firstLivingEnemy() {
    for (final enemy in _enemies) {
      if (enemy.isAlive) return enemy;
    }
    return null;
  }

  /// A single display string naming every enemy in this fight — the
  /// enemy's own name for a solo fight (unchanged from before packs
  /// existed), or every distinct name in the pack joined together, each
  /// prefixed with a "Nx " count when it appears more than once (e.g. "2x
  /// Harbor Rat, Dock Overseer").
  String _battleTitle() {
    if (_enemies.length == 1) {
      return _enemies.first.data['enemyName']?.toString() ??
          _enemies.first.enemyId;
    }
    final counts = <String, int>{};
    final order = <String>[];
    for (final enemy in _enemies) {
      final name = enemy.data['enemyName']?.toString() ?? enemy.enemyId;
      if (!counts.containsKey(name)) order.add(name);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return order
        .map(
            (name) => (counts[name] ?? 1) > 1 ? '${counts[name]}x $name' : name)
        .join(', ');
  }

  /// Rolls [_banterChance] for a random active, still-conscious ally
  /// (other than [excludeId], so nobody reacts to their own crit, dodge or
  /// knockout) to say a short line from their own companions.json banter
  /// fields for [kind] — null whenever there's simply nobody around to
  /// react (a solo player, or every ally already knocked out), the line
  /// rolled against and missed, or the chosen companion has no line
  /// authored for this language/moment.
  _LogEntry? _rollBanter({required _BanterKind kind, String? excludeId}) {
    final candidates = _party
        .where((m) => !m.isPlayer && !m.isKnockedOut && m.id != excludeId)
        .toList();
    if (candidates.isEmpty || _random.nextDouble() >= _banterChance) {
      return null;
    }
    final speaker = candidates[_random.nextInt(candidates.length)];
    final companion = _companions[speaker.id] as Map<String, dynamic>?;
    if (companion == null) return null;
    final lang = ref.read(appLanguageProvider);
    final line = companion[_banterFieldFor(kind, lang)]?.toString();
    if (line == null || line.isEmpty) return null;
    return _LogEntry('${speaker.displayName}: "$line"', _LogKind.banter);
  }

  Map<String, dynamic> _availableSkillsFor(
      _PartyMember actor, Map<String, dynamic> skills) {
    return <String, dynamic>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
                false) ||
            actor.unlockedSkillIds.contains(entry.key))
          entry.key: applySkillTier(
            entry.value as Map<String, dynamic>,
            actor.skillTiers[entry.key] ?? 0,
          ),
    };
  }

  /// Every party member able to act this round — conscious, and not
  /// currently Stunned (see status_effect.dart; a stunned member is
  /// skipped for the round entirely, announced in [_startPartyRound]).
  List<_PartyMember> get _actingParty => _party
      .where((m) =>
          !m.isKnockedOut &&
          !isStunned(m.statusEffects) &&
          !_sittingOut.contains(m.id))
      .toList();
}
