part of '../fight_screen.dart';

/// Building the enemies and the party, and starting the fight.
extension _FightSetup on _FightScreenState {
  /// The story chapter this fight belongs to: the caller's (an expedition
  /// passes its zone's), else the current scene's (a place's own chapter,
  /// see storyChapterOf). Drives the chapter difficulty curve and the
  /// chest's loot window.
  int get _chapter =>
      widget.modifiers.chapter ??
      storyChapterOf(ref.read(storyPlayProvider).currentNodeId,
          ref.read(storyDataProvider).value);

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
    // A lesson (the story's first fight) is never Elite, rolls no affixes
    // and no battlefield condition, and ignores the threat.
    final lesson = modifiers.tutorial;
    _isElite = !lesson &&
        entries.length == 1 &&
        (modifiers.forceElite ||
            (isRandomDrawEnemy(entries.first.key) &&
                modifiers.forcedAffixes.isEmpty &&
                _random.nextDouble() < _eliteChance));
    final session = ref.read(playerSessionProvider);
    _threat = modifiers.isTest || modifiers.isZoneBoss || lesson
        ? 0
        : session.threatIn(ref.read(reachedChapterProvider));
    _condition = modifiers.forcedCondition ??
        (lesson
            ? null
            : rollBattlefieldCondition(
                enemyCount: entries.length, random: _random));
    // The day's sky over the party (v1.208): none for a lesson or a test.
    _sky = lesson || modifiers.isTest
        ? WeatherEffects.of(null)
        : WeatherEffects.of(ref.read(skyHereProvider)?.today().kind);

    // The doctrine the enemies fight under (v1.212), unless one of them is
    // a boss or a unique; its affix taste shapes the affix roll below.
    final factions = [
      for (final e in entries) e.value['faction']?.toString() ?? '',
    ];
    _doctrine = lesson || modifiers.isTest
        ? null
        : doctrineForFight(factions: factions, isBoss: [
            for (final e in entries) isBossEnemy(e.key, e.value),
          ]);
    final affixes = lesson
        ? [for (final _ in entries) <EnemyAffix>[]]
        : rollEncounterAffixes(
            enemyIds: [for (final e in entries) e.key],
            isElite: _isElite,
            random: _random,
            tastes: [
              for (final faction in factions)
                if (_doctrine != null && faction == _doctrine!.factionId)
                  _doctrine!.affixes
                else
                  const <EnemyAffix>[],
            ],
          );
    if (modifiers.forcedAffixes.isNotEmpty) {
      affixes[0] = modifiers.forcedAffixes;
    }

    // What the fight asks besides the slaughter (v1.212): set by the
    // encounter, else rolled for an ordinary fight.
    final goalEligible = !lesson &&
        !modifiers.isTest &&
        !modifiers.isZoneBoss &&
        !modifiers.isHunt &&
        !modifiers.isHunterAmbush &&
        !modifiers.lossContinues &&
        !modifiers.luckyDieReveal &&
        !modifiers.hostFight &&
        !modifiers.forceElite &&
        !_isElite &&
        !entries.any((e) => isBossEnemy(e.key, e.value));
    _goal = modifiers.forcedGoal ??
        rollFightGoal(
          eligible: goalEligible,
          enemyCount: entries.length,
          canYield: entries.length == 1 &&
              canYieldFaction(entries.first.value['faction']?.toString()),
          random: _random,
        );

    // The pack's squad (v1.215, see squad.dart): none for a lesson, a test
    // or a boss.
    final roles = modifiers.forcedSquad ??
        (lesson || modifiers.isTest
            ? List<SquadRole?>.filled(entries.length, null)
            : rollSquadRoles(
                packSize: entries.length,
                eligible: [
                  for (final e in entries) !isBossEnemy(e.key, e.value),
                ],
                random: _random,
              ));

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
          role: roles[i],
        ),
    ];
    // A Rout's mark is the pack's sturdiest member; a pack of one has no
    // captain to bring down, so its Rout is the plain slaughter.
    if (_goal.kind == FightGoalKind.rout) {
      if (_enemies.length >= 2) {
        _enemies[captainIndex([for (final e in _enemies) e.maxHealth])]
            .isCaptain = true;
      } else {
        _goal = FightGoal.slay;
      }
    }
    if (_goal.kind == FightGoalKind.subdue && _enemies.length != 1) {
      _goal = FightGoal.slay;
    }
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
    SquadRole? role,
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
    if (_threat > 0 && !isBossEnemy(id, raw)) {
      maxHealth = max(1, (maxHealth * (1 + _threat)).round());
      damage = (damage * (1 + _threat)).round();
    }
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
    // A squad's roles (v1.215, see squad.dart).
    switch (role) {
      case SquadRole.healer:
        damage = (damage * healerDamageMultiplier).round();
      case SquadRole.striker:
        damage = (damage * strikerDamageMultiplier).round();
        maxHealth = max(1, (maxHealth * strikerHealthMultiplier).round());
      case SquadRole.guard:
      case null:
        break;
    }
    // A hold presses harder: the party need not kill them.
    if (_goal.kind == FightGoalKind.hold) {
      damage = (damage * holdDamageMultiplier).round();
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
      faction: raw['faction']?.toString() ?? '',
    )
      ..phases = parseBossPhases(raw)
      ..role = role
      ..response = enemyResponseFromName(raw['reaction']?.toString());
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
    Map<String, dynamic> skills,
    Map<String, dynamic> signsDb,
    List<SignEffect> clanEffects,
  ) {
    if (_partyBuilt) return;
    _partyBuilt = true;
    _companions = companions;
    // Level-up perks (see perks.dart): the rolls a round allows here, the
    // rest as the fight goes.
    _perks = session.perkEffects;
    // Signs (see signs.dart): what the held ones add up to at the
    // alignment the party walks in with, with the title worn and the
    // Sworn boon (see offers.dart's clanEffectsFor).
    _signDefs = parseSigns(signsDb);
    _signs = signEffectsFor(session.heldSigns, _signDefs,
        alignment: session.alignmentScore, extra: clanEffects);
    _writCharges = _signs.writFace;
    _edgeCharges = _signs.compactEdge;
    _emberCharges = _signs.emberFace;
    _crowsHits = 0;
    // Open Eyes: the tear's things cannot surprise the party.
    if (_signs.intentLookahead > 0 &&
        _condition == BattlefieldCondition.ambush &&
        _enemies.any((e) => enemyResistances(e.data).contains('Void'))) {
      _condition = null;
    }
    if (_signs.maxMana > 0) {
      final full = _mana >= _maxMana;
      _maxMana += _signs.maxMana;
      if (full) _mana = _maxMana;
    }
    _maxRollsThisFight = _maxRolls + _perks.extraRolls;
    _alignmentLabel = session.alignmentLabel;
    _partyBonus = partyBonusFor(
      bossDefeatCounts: session.bossDefeatCounts,
      enemyIds: [for (final e in _enemies) e.enemyId],
      builtHouseIds: session.builtHouseIds,
      houses: houses,
    );

    // A skill takes no more of a die's faces than its rarity allows; a
    // save from before the limits keeps the first of its faces.
    List<Map<String, dynamic>> facesOf(String? diceId) =>
        ((dice[diceId ?? ''] as Map<String, dynamic>?)?['faces'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    // The die as the Hammersmith left it (see face_smithing.dart): the
    // player's own, or a companion's signature die, worked apart even when
    // the player owns the same die.
    List<Map<String, dynamic>> smithed(String? diceId, {String? companionId}) =>
        smithedFaces(facesOf(diceId),
            session.upgradesOfDie(diceId, companionId: companionId));
    final playerDiceAssignments = limitedFaceAssignments(
        facesOf(_selectedDiceId),
        session.diceSkillAssignments[_selectedDiceId] ??
            const <String, String>{},
        skills);
    final playerLabel = session.characterName.isNotEmpty
        ? session.characterName
        : trFor(ref.read(appLanguageProvider), 'you_label');
    // A health sign raises the fight's max: full health stays full, a
    // wound stays as it is; a running pact may take a share off the top.
    final baseMaxHealth = _partyBonus.scaleMaxHealth(session.maxHealth);
    final playerMaxHealth = _signs.maxHealthFor(baseMaxHealth);
    final enteringHealth = SignEffects.healthEntering(
      current: _partyBonus.scaleCurrentHealth(session.currentHealth > 0
          ? session.currentHealth
          : session.maxHealth),
      base: baseMaxHealth,
      fightMax: playerMaxHealth,
    );
    final playerHealth =
        _signs.afterStartCurse(enteringHealth, playerMaxHealth);
    _signStartCurseTaken = enteringHealth - playerHealth;
    final player = _PartyMember(
      id: 'player',
      displayName: playerLabel,
      isPlayer: true,
      maxHealth: playerMaxHealth,
      baseDamage: _partyBonus.scaleDamage(session.baseDamage),
      armor: session.baseArmor,
      currentHealth: playerHealth,
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
      strength: session.strength + _signs.stat('strength'),
      dexterity: session.dexterity + _signs.stat('dexterity'),
      constitution: session.constitution + _signs.stat('constitution'),
      intelligence: session.intelligence + _signs.stat('intelligence'),
      wisdom: session.wisdom + _signs.stat('wisdom'),
      luck: session.luck + _signs.stat('luck'),
      perception: session.perception + _signs.stat('perception'),
      gear: _signs.over(_perks
          .over(gearEffectsFor(session.equippedItemIds, items, itemSets))),
      dieFaces: smithed(_selectedDiceId),
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
      // A devoted companion fights harder, a wary one holds back.
      final tier = approvalTierFor(allyState.approval);
      final baseAllyHealth = _partyBonus
              .scaleMaxHealth(scaledMaxHealth(base.maxHealth, _playerLevel)) *
          approvalHealthPercent(tier) ~/
          100;
      // A banner sign raises the whole party's health in the fight.
      final liveMaxHealth =
          _signs.maxHealthFor(baseAllyHealth, partyWide: true);
      activeAllies.add(_PartyMember(
        id: companionId,
        displayName: companion['companionName']?.toString() ?? companionId,
        isPlayer: false,
        maxHealth: liveMaxHealth,
        // A leader's allies (a perk, a sign) hit a little harder too.
        baseDamage: _signs.scaleAllyDamage(_perks.scaleAllyDamage(_partyBonus
                .scaleDamage(scaledDamage(base.baseDamage, _playerLevel)) *
            approvalDamagePercent(tier) ~/
            100)),
        armor: base.baseArmor,
        currentHealth: SignEffects.healthEntering(
          current: _partyBonus
              .scaleCurrentHealth(allyState.currentHealth)
              .clamp(0, baseAllyHealth),
          base: baseAllyHealth,
          fightMax: liveMaxHealth,
        ),
        equippedItemIds: allyState.equippedItemIds,
        unlockedSkillIds: [
          ...allyState.unlockedSkillIds,
          ...dieSignatureSkillIds(
              dice[companion['signatureDiceId']?.toString() ?? '']
                  as Map<String, dynamic>?),
        ],
        diceSkillAssignments: limitedFaceAssignments(
            facesOf(companion['signatureDiceId']?.toString()),
            allyState.diceSkillAssignments,
            skills),
        equippedDiceId: companion['signatureDiceId']?.toString(),
        strength: base.strength,
        dexterity: base.dexterity,
        constitution: base.constitution,
        intelligence: base.intelligence,
        wisdom: base.wisdom,
        luck: base.luck,
        perception: base.perception,
        gear: gearEffectsFor(allyState.equippedItemIds, items, itemSets),
        dieFaces: smithed(companion['signatureDiceId']?.toString(),
            companionId: companionId),
        approval: allyState.approval,
      ));
    }

    _party = [player, ...activeAllies];
  }

  void _startFight(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    // A hired sellsword fights this one, a fight off the contract.
    final session = ref.read(playerSessionProvider);
    if (!widget.modifiers.isTest && session.sellswordFights > 0) {
      _sellswordStrike = sellswordDamage(ref.read(reachedChapterProvider));
      ref.read(playerSessionProvider.notifier).spendSellswordFight();
    }
    final threatened =
        _threat > 0 && _enemies.any((e) => !isBossEnemy(e.enemyId, e.data));
    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }
    _applyArmedCharms(items);
    final signLines = _openSignsForFight(lang);
    // Luck nudges (v1.182): the party's luckiest member sets how many.
    _nudgesLeft = nudgesForLuck(
        _party.fold<int>(0, (best, m) => m.luck > best ? m.luck : best));
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
      if (_sky.effectKey case final key?) {
        _log.add(_LogEntry(
          '${trFor(lang, 'weather_${_sky.kind.name}')}: ${trFor(lang, key)}',
          _LogKind.info,
        ));
      }
      for (final id in _armedCharmIds) {
        final name =
            (items[id] as Map<String, dynamic>?)?['itemName']?.toString() ?? id;
        _log.add(_LogEntry(
            '${trFor(lang, 'charm_used_prefix')} $name', _LogKind.playerHeal));
      }
      if (threatened) {
        _log.add(_LogEntry(
          trFor(lang, 'threat_fight_note')
              .replaceAll('{p}', '${(_threat * 100).round()}'),
          _LogKind.info,
        ));
      }
      _log.addAll(signLines);
      if (banter != null) _log.add(banter);
    });
    _noteTelegraphReads();
    // The first fight's lucky die: the enemy's opening blow, the die
    // rolling loose and striking back, then the party's first round.
    if (widget.modifiers.luckyDieReveal && _openWithLuckyDie(lang)) return;
    if (condition == BattlefieldCondition.ambush) {
      // The enemies strike before the party's first roll; the party round
      // that follows is the opening one, so nothing reads off them yet.
      _roundsStarted = 0;
      _takeEnemyTurn(skills, items);
      return;
    }
    // The party's first round starts here, and the sellsword with it.
    final opening = <_LogEntry>[];
    final sellswordWon = _sellswordStrikes(opening, lang);
    if (opening.isNotEmpty) _update(() => _log.addAll(opening));
    if (sellswordWon) _finishFight(won: true);
  }

  /// What the signs do as the fight opens: the party's starting block (on
  /// top of the first round's faces, like a spell's), a head start on
  /// momentum; and what the log says of them -- a silent vow, a pact
  /// still running, what its curse took.
  List<_LogEntry> _openSignsForFight(AppLanguage lang) {
    final lines = <_LogEntry>[];
    // The last battles (v1.196): who of the Host fights beside the party.
    if (widget.modifiers.hostFight && !_host.isEmpty) {
      final houses = _host.houses.length;
      final names = [
        for (final id in _host.contingents)
          _hostData.faction(id)?.shortFor(lang) ?? id,
        if (houses == 1) trFor(lang, 'host_fight_house_one'),
        if (houses > 1)
          trFor(lang, 'host_fight_houses').replaceAll('{n}', '$houses'),
      ];
      lines.add(_LogEntry(
          trFor(lang, 'host_fight_log').replaceAll('{names}', names.join(', ')),
          _LogKind.info));
    }
    if (_signs.isEmpty) return lines;
    if (_signs.silentVows > 0) {
      lines.add(_LogEntry(trFor(lang, 'sign_log_vow_silent'), _LogKind.info));
    }
    final pactFights = ref
        .read(playerSessionProvider)
        .heldSigns
        .fold<int>(0, (most, h) => max(most, h.pactFightsLeft));
    if (pactFights > 0) {
      lines.add(_LogEntry(
          trFor(lang, 'sign_log_pact').replaceAll('{n}', '$pactFights'),
          _LogKind.enemyDamage));
    }
    if (_signStartCurseTaken > 0) {
      lines.add(_LogEntry(
          trFor(lang, 'sign_log_start_curse')
              .replaceAll('{n}', '$_signStartCurseTaken'),
          _LogKind.enemyDamage));
    }
    final startBlock = _signs.partyStartBlock;
    if (startBlock > 0) {
      for (final member in _party) {
        if (member.isKnockedOut) continue;
        member.block += startBlock;
        _spellBlock[member.id] = (_spellBlock[member.id] ?? 0) + startBlock;
      }
      lines.add(_LogEntry(
          trFor(lang, 'sign_log_start_block').replaceAll('{n}', '$startBlock'),
          _LogKind.playerBlock));
    }
    if (_signs.startMomentum > 0) {
      _momentum = min(_momentumNeeded, _signs.startMomentum);
      if (_momentum >= _momentumNeeded) {
        lines.add(
            _LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
      }
    }
    return lines;
  }

  /// Burns every charm picked on the setup screen and arms its one-fight
  /// effect (see items.json's Charm-type items).
  void _applyArmedCharms(Map<String, dynamic> items) {
    if (_armedCharmIds.isEmpty) return;
    for (final id in _armedCharmIds) {
      switch (id) {
        case 'charm_fourth_roll':
          _maxRollsThisFight += 1;
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
