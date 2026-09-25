part of '../fight_screen.dart';

/// Building the enemies and the party, and starting the fight.
extension _FightSetup on _FightScreenState {
  /// The story chapter this fight belongs to: the caller's (an expedition
  /// passes its zone's), else the current story node's, else 1. Drives the
  /// chapter difficulty curve and the chest's loot window.
  int get _chapter =>
      widget.modifiers.chapter ??
      chapterForNode(ref.read(storyPlayProvider).currentNodeId) ??
      1;

  /// Builds [_enemies] — a solo fight rolls Elite (see [_eliteChance]); a
  /// pack (`widget.additionalEnemyIds` non-empty) never does. A pack member
  /// sharing a base name with another gets a " #2"/" #3" suffix on its own
  /// [_EnemyMember.displayName] so the two are distinguishable in the UI;
  /// a solo fight or an all-distinct pack never shows one. Also rolls
  /// every enemy's affixes (see [rollEncounterAffixes]) and this fight's
  /// battlefield condition (see [rollBattlefieldCondition]).
  void _ensureEnemiesBuilt() {
    final entries = widget._allEnemyEntries;
    final lang = ref.read(appLanguageProvider);
    final modifiers = widget.modifiers;
    _isElite = entries.length == 1 &&
        isRandomDrawEnemy(entries.first.key) &&
        modifiers.forcedAffixes.isEmpty &&
        _random.nextDouble() < _eliteChance;
    _condition =
        rollBattlefieldCondition(enemyCount: entries.length, random: _random);

    final affixes = rollEncounterAffixes(
      enemyIds: [for (final e in entries) e.key],
      isElite: _isElite,
      random: _random,
    );
    if (modifiers.forcedAffixes.isNotEmpty) {
      affixes[0] = modifiers.forcedAffixes;
    }

    final baseNames = [
      for (final entry in entries)
        entry.value['enemyName']?.toString() ?? entry.key,
    ];
    final totalCounts = <String, int>{};
    for (final name in baseNames) {
      totalCounts[name] = (totalCounts[name] ?? 0) + 1;
    }
    final seenSoFar = <String, int>{};

    _enemies = [
      for (var i = 0; i < entries.length; i++)
        _buildEnemyMember(
          index: i,
          id: entries[i].key,
          raw: entries[i].value,
          baseName: baseNames[i],
          isDuplicateName: (totalCounts[baseNames[i]] ?? 1) > 1,
          seenSoFar: seenSoFar,
          packSize: entries.length,
          lang: lang,
          affixes: affixes[i],
          nameOverride: i == 0 ? modifiers.namedEnemyName : null,
          healthMultiplier: i == 0 ? modifiers.healthMultiplier : 1.0,
        ),
    ];
  }

  _EnemyMember _buildEnemyMember({
    required int index,
    required String id,
    required Map<String, dynamic> raw,
    required String baseName,
    required bool isDuplicateName,
    required Map<String, int> seenSoFar,
    required int packSize,
    required AppLanguage lang,
    List<EnemyAffix> affixes = const [],
    String? nameOverride,
    double healthMultiplier = 1.0,
  }) {
    final elitePrefixedName =
        _isElite ? '${trFor(lang, 'elite_prefix')} $baseName' : baseName;
    // An affix reads as a one-word title ("Venomous Harbor Rat") so the
    // player always knows what they're facing; a hunt's named quarry keeps
    // its own name and shows its affixes as chips instead.
    final affixPrefix = affixes.isEmpty || nameOverride != null
        ? ''
        : '${affixes.map((a) => trFor(lang, affixLabelKey(a))).join(' ')} ';
    final titledName = nameOverride ?? '$affixPrefix$elitePrefixedName';
    final data =
        titledName != baseName ? {...raw, 'enemyName': titledName} : raw;
    String displayName;
    if (isDuplicateName && nameOverride == null) {
      seenSoFar[baseName] = (seenSoFar[baseName] ?? 0) + 1;
      displayName = '$titledName #${seenSoFar[baseName]}';
    } else {
      displayName = titledName;
    }
    var maxHealth =
        scaledMaxHealth((raw['maxHealth'] as num?)?.toInt() ?? 1, _playerLevel);
    var damage =
        scaledDamage((raw['damage'] as num?)?.toInt() ?? 0, _playerLevel);
    // The difficulty curve (the flat floor, the chapter, a zone's tier and
    // the New Game+ cycle) scales every enemy before the Elite/pack
    // multipliers, so those keep their tuned ratios.
    final curve = difficultyCurveFor(
      chapter: _chapter,
      zoneMultiplier: widget.modifiers.difficultyMultiplier,
      newGamePlusCycle: _newGamePlusCycle,
      isBoss: isBossEnemy(id, raw),
    );
    maxHealth = max(1, (maxHealth * curve.health).round());
    damage = (damage * curve.damage).round();
    if (_isElite) {
      maxHealth = (maxHealth * _eliteStatMultiplier).round();
      damage = (damage * _eliteStatMultiplier).round();
    }
    final packMultiplier = _packStatMultipliers[packSize];
    if (packMultiplier != null) {
      maxHealth = max(1, (maxHealth * packMultiplier).round());
      damage = (damage * packMultiplier).round();
    }
    if (affixes.contains(EnemyAffix.packLeader)) {
      maxHealth = (maxHealth * packLeaderHealthMultiplier).round();
    }
    if (healthMultiplier != 1.0) {
      maxHealth = max(1, (maxHealth * healthMultiplier).round());
    }
    final moves =
        (raw['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return _EnemyMember(
      key: 'enemy_$index',
      enemyId: id,
      displayName: displayName,
      data: data,
      maxHealth: maxHealth,
      damage: damage,
      guile: (raw['guile'] as num?)?.toInt() ?? 0,
      hasReactiveMoves:
          moves.any((m) => m['condition']?.toString() == 'OnHitByElement'),
      currentHealth: maxHealth,
      affixes: affixes,
    )..phases = parseBossPhases(raw);
  }

  /// Builds [_party] (the player plus every currently-active ally) once
  /// every data source it needs has loaded. Idempotent — a rebuild
  /// triggered by an unrelated provider change is a no-op past the first
  /// successful call, since mid-fight party state (health, block) lives
  /// only here from that point on, not in the providers being watched.
  void _ensurePartyBuilt(
    PlayerSession session,
    Map<String, dynamic> companions,
    Map<String, dynamic> races,
    Map<String, dynamic> professions,
    Map<String, dynamic> gameConfig,
    Map<String, dynamic> items,
    Map<String, ItemSet> itemSets,
    Map<String, dynamic> houses,
    Map<String, dynamic> dice,
    Map<String, dynamic> skillTrees,
  ) {
    if (_partyBuilt) return;
    _partyBuilt = true;
    _companions = companions;
    _alignmentLabel = session.alignmentLabel;
    _partyBonus = partyBonusFor(
      bossDefeatCounts: session.bossDefeatCounts,
      enemyIds: [for (final e in _enemies) e.enemyId],
      builtHouseIds: session.builtHouseIds,
      houses: houses,
    );

    final playerDiceAssignments =
        session.diceSkillAssignments[_selectedDiceId] ??
            const <String, String>{};
    final playerLabel = session.characterName.isNotEmpty
        ? session.characterName
        : trFor(ref.read(appLanguageProvider), 'you_label');
    final player = _PartyMember(
      id: 'player',
      displayName: playerLabel,
      isPlayer: true,
      maxHealth: _partyBonus.scaleMaxHealth(session.maxHealth),
      baseDamage: _partyBonus.scaleDamage(session.baseDamage),
      armor: session.baseArmor,
      currentHealth: _partyBonus.scaleCurrentHealth(session.currentHealth > 0
          ? session.currentHealth
          : session.maxHealth),
      equippedItemIds: session.equippedItemIds,
      unlockedSkillIds: [
        ...session.unlockedSkillIds,
        ...dieSignatureSkillIds(
            dice[_selectedDiceId ?? ''] as Map<String, dynamic>?),
      ],
      diceSkillAssignments: playerDiceAssignments,
      equippedDiceId: _selectedDiceId,
      // A mastered branch's skills fight a tier above their own.
      skillTiers: effectiveSkillTiers(
          session.skillTiers, skillTrees, session.masteredBranchId),
      strength: session.strength,
      dexterity: session.dexterity,
      constitution: session.constitution,
      intelligence: session.intelligence,
      wisdom: session.wisdom,
      luck: session.luck,
      perception: session.perception,
      gear: gearEffectsFor(session.equippedItemIds, items, itemSets),
    );

    final activeAllies = <_PartyMember>[];
    for (final companionId in session.activeAllyIds) {
      final companion = companions[companionId] as Map<String, dynamic>?;
      if (companion == null) continue;
      final allyState = session.recruitedAllies.firstWhere(
        (a) => a.companionId == companionId,
        orElse: () => AllyState(
            companionId: companionId,
            currentHealth: AllyState.fullHealthSentinel),
      );
      final race = races[companion['raceId']?.toString() ?? '']
              as Map<String, dynamic>? ??
          const {};
      final profession =
          professions[companion['professionId']?.toString() ?? '']
                  as Map<String, dynamic>? ??
              const {};
      final base = deriveAllyBaseStats(
          gameConfig: gameConfig, race: race, profession: profession);
      final liveMaxHealth = _partyBonus
          .scaleMaxHealth(scaledMaxHealth(base.maxHealth, _playerLevel));
      activeAllies.add(_PartyMember(
        id: companionId,
        displayName: companion['companionName']?.toString() ?? companionId,
        isPlayer: false,
        maxHealth: liveMaxHealth,
        baseDamage: _partyBonus
            .scaleDamage(scaledDamage(base.baseDamage, _playerLevel)),
        armor: base.baseArmor,
        currentHealth: _partyBonus
            .scaleCurrentHealth(allyState.currentHealth)
            .clamp(0, liveMaxHealth),
        equippedItemIds: allyState.equippedItemIds,
        unlockedSkillIds: [
          ...allyState.unlockedSkillIds,
          ...dieSignatureSkillIds(
              dice[companion['signatureDiceId']?.toString() ?? '']
                  as Map<String, dynamic>?),
        ],
        diceSkillAssignments: allyState.diceSkillAssignments,
        equippedDiceId: companion['signatureDiceId']?.toString(),
        strength: base.strength,
        dexterity: base.dexterity,
        constitution: base.constitution,
        intelligence: base.intelligence,
        wisdom: base.wisdom,
        luck: base.luck,
        perception: base.perception,
        gear: gearEffectsFor(allyState.equippedItemIds, items, itemSets),
      ));
    }

    _party = [player, ...activeAllies];
  }

  void _startFight(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }
    _applyArmedCharms(items);
    final hpSuffix = _enemies.length == 1
        ? ' ${trFor(lang, 'has_label')} ${_enemies.first.maxHealth} ${trFor(lang, 'hp_label')}'
        : '';
    final condition = _condition;
    final banter = _rollBanter(
        kind: _enemies.length > 1 ? _BanterKind.pack : _BanterKind.fightStart);
    _update(() {
      _started = true;
      _roundsStarted = 1;
      _log.add(
        _LogEntry(
          '${trFor(lang, 'fight_begins_prefix')} ${_battleTitle()}$hpSuffix.',
          _LogKind.info,
        ),
      );
      if (condition != null) {
        _log.add(_LogEntry(
          '${trFor(lang, conditionLabelKey(condition))}: '
          '${trFor(lang, conditionDescriptionKey(condition))}',
          _LogKind.info,
        ));
      }
      for (final id in _armedCharmIds) {
        final name =
            (items[id] as Map<String, dynamic>?)?['itemName']?.toString() ?? id;
        _log.add(_LogEntry(
            '${trFor(lang, 'charm_used_prefix')} $name', _LogKind.playerHeal));
      }
      if (banter != null) _log.add(banter);
    });
    _noteTelegraphReads();
    if (condition == BattlefieldCondition.ambush) {
      // The enemies strike before the party's first roll; the party round
      // that follows is the opening one, so nothing reads off them yet.
      _roundsStarted = 0;
      _takeEnemyTurn(skills, items);
    }
  }

  /// Burns every charm picked on the setup screen and arms its one-fight
  /// effect (see items.json's Charm-type items).
  void _applyArmedCharms(Map<String, dynamic> items) {
    if (_armedCharmIds.isEmpty) return;
    for (final id in _armedCharmIds) {
      switch (id) {
        case 'charm_fourth_roll':
          _maxRollsThisFight = _maxRolls + 1;
        case 'charm_lucky_coin':
          _luckyCoinArmed = true;
        case 'charm_iron_skin':
          _ironSkinArmed = true;
        case 'charm_warding':
          _wardingCharges = 1;
      }
    }
    ref
        .read(playerSessionProvider.notifier)
        .consumeInventoryItems(_armedCharmIds.toList());
  }
}
