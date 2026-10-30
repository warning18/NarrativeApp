part of '../fight_screen.dart';

/// The setup screen, the battle layout and the dice tray.
extension _FightView on _FightScreenState {
  Widget _buildSetup(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final player = _party.first;
    final condition = _condition;
    // Charms carried right now, one chip per distinct charm (a second copy
    // of the same charm can't be armed twice in one fight).
    final charmCounts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      if ((items[id] as Map<String, dynamic>?)?['itemType']?.toString() ==
          'Charm') {
        charmCounts[id] = (charmCounts[id] ?? 0) + 1;
      }
    }
    final playerScalingBonus = equipmentScalingBonusFor(
      player.equippedItemIds,
      items,
      strength: player.strength,
      dexterity: player.dexterity,
      constitution: player.constitution,
      intelligence: player.intelligence,
    );
    final damageBonus =
        equipmentBonusFor(player.equippedItemIds, items, 'attackDamage') +
            playerScalingBonus.damageBonus;
    final armorBonus =
        equipmentBonusFor(player.equippedItemIds, items, 'armor') +
            playerScalingBonus.armorBonus;
    final equippedDie = _selectedDiceId != null
        ? dice[_selectedDiceId] as Map<String, dynamic>?
        : null;
    final faceCount = (equippedDie?['faces'] as List?)?.length ?? 0;
    final activeAllies = _party.skip(1).toList();
    final lang = ref.watch(appLanguageProvider);
    final knownSpellNames = <String>[
      for (final id in session.knownSpellIds)
        if (_spells[id] != null) _spells[id]!.nameFor(lang),
    ];

    // The ground behind the setup, as it is behind the battle.
    return Stack(
      children: [
        Positioned.fill(
            child: IgnorePointer(child: _buildBackdrop(veil: 0.55))),
        Positioned.fill(child: _buildWeatherOverlay()),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // What this fight's goal, doctrine and situation mean, the
              // first time this save meets each (fight_tips.dart).
              FightTipsCard(
                shown: fightTipIdsFor(
                    goal: _goal.kind,
                    doctrineFactionId: _doctrine?.factionId,
                    condition: condition),
                holdRounds: _goal.rounds,
              ),
              if (!_goal.isSlay) ...[
                _buildGoalBanner(),
                const SizedBox(height: 12),
              ],
              if (_doctrine != null) ...[
                _buildDoctrineBanner(_doctrine!),
                const SizedBox(height: 12),
              ],
              if (condition != null) ...[
                _buildConditionBanner(condition),
                const SizedBox(height: 12),
              ],
              if (_newGamePlusCycle > 0) ...[
                Text(
                  '${tr(ref, 'new_game_plus_label')} · '
                  '${tr(ref, 'new_game_plus_cycle_label')} $_newGamePlusCycle · '
                  '+${(newGamePlusStep * _newGamePlusCycle * 100).round()}% '
                  '${tr(ref, 'new_game_plus_enemies_suffix')}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              if (_partyBonus.resolveStacks > 0) ...[
                Text(
                  '${tr(ref, 'resolve_label')} ×${_partyBonus.resolveStacks} · '
                  '+${_partyBonus.resolvePercent}% '
                  '${tr(ref, 'resolve_bonus_suffix')}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              if (_partyBonus.hasHouseBonus) ...[
                Text(
                  '${tr(ref, 'camp_works_label')} · '
                  '+${_partyBonus.houseHealthPercent}% '
                  '${tr(ref, 'party_health_bonus_label')} · '
                  '+${_partyBonus.houseDamagePercent}% '
                  '${tr(ref, 'party_damage_bonus_label')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              // One of the last battles (v1.196): the Host stands with the
              // party.
              if (widget.modifiers.hostFight && !_host.isEmpty) ...[
                Row(
                  key: const Key('fight_host_note'),
                  children: [
                    const Icon(Icons.groups_2_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tr(ref, 'host_fight_note'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (widget.modifiers.isHunt ||
                  widget.modifiers.isHunterAmbush ||
                  widget.modifiers.isZoneBoss) ...[
                Text(
                  tr(ref, _encounterNoteKey(widget.modifiers)),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
              ],
              for (final enemy in _enemies) ...[
                _buildEnemySetupCard(enemy),
                const SizedBox(height: 8),
              ],
              if (charmCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(tr(ref, 'charms_label'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(tr(ref, 'charms_hint'),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final entry in charmCounts.entries)
                      FilterChip(
                        avatar: ItemPixelIcon(entry.key, 'Charm', size: 18),
                        label: Text(
                          '${(items[entry.key] as Map<String, dynamic>?)?['itemName'] ?? entry.key}'
                          '${entry.value > 1 ? ' x${entry.value}' : ''}',
                        ),
                        tooltip: tr(ref, '${entry.key}_desc'),
                        selected: _armedCharmIds.contains(entry.key),
                        onSelected: (selected) => _update(() {
                          if (selected) {
                            _armedCharmIds.add(entry.key);
                          } else {
                            _armedCharmIds.remove(entry.key);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              if (damageBonus > 0 || armorBonus > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${tr(ref, 'your_equipment_prefix')}: +$damageBonus ${tr(ref, 'damage_word')}, '
                  '+$armorBonus ${tr(ref, 'armor_label')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              _buildPickCard(),
              if (activeAllies.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${tr(ref, 'fighting_alongside_prefix')}: '
                  '${activeAllies.map((a) => a.displayName).join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(manaIcon, size: 14, color: manaColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${tr(ref, 'mana_label')} $_mana/$_maxMana · '
                      '${tr(ref, 'spells_label')}: '
                      '${knownSpellNames.isEmpty ? '—' : knownSpellNames.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              Text(tr(ref, 'mana_faces_note'),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 24),
              Text(tr(ref, 'equipped_die_label'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (equippedDie == null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(tr(ref, 'no_die_equipped')),
                    subtitle: Text(tr(ref, 'equip_die_hint')),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.casino),
                    title: Text(dieDisplayName(_selectedDiceId!,
                        language: ref.watch(appLanguageProvider))),
                    subtitle: Text('$faceCount ${tr(ref, 'faces_label')}'),
                  ),
                ),
              if (session.ownedDiceIds.length > 1) ...[
                const SizedBox(height: 8),
                _buildLoadoutPicker(dice, skills, session),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: equippedDie == null
                    ? null
                    : () => _startFight(skills, items),
                icon: const Icon(Icons.sports_martial_arts),
                label: Text(tr(ref, 'enter_battle_button')),
              ),
              if (equippedDie != null && _quickOffered(session)) ...[
                const SizedBox(height: 8),
                Tooltip(
                  message: tr(ref, 'quick_resolve_hint'),
                  child: OutlinedButton.icon(
                    key: const Key('quick_resolve_button'),
                    onPressed: () => _quickResolve(dice, skills, items),
                    icon: const Icon(Icons.fast_forward),
                    label: Text(tr(ref, 'quick_resolve_button')),
                  ),
                ),
                Text(tr(ref, 'quick_resolve_hint'),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One enemy's card on the pre-fight setup screen — a solo fight renders
  /// exactly what this screen always showed for its one enemy; a pack
  /// renders one of these per member.
  Widget _buildEnemySetupCard(_EnemyMember enemy) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _isElite
              ? Colors.amber.shade700
              : Theme.of(context).colorScheme.errorContainer,
          child: EnemyPixelIcon(enemy.enemyId, size: 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enemy.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _isElite ? Colors.amber.shade800 : null,
                      fontWeight: _isElite ? FontWeight.bold : null,
                    ),
              ),
              // Who this is, before anything is rolled: the fight is
              // against someone, not a stat block.
              if (enemyDescriptionFor(enemy.data,
                      ref.watch(appLanguageProvider) == AppLanguage.fr)
                  case final description?) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                '${tr(ref, 'hp_label')} ${enemy.maxHealth} · ${tr(ref, 'damage_label')} ${enemy.damage} '
                '(${tr(ref, 'scaled_to_level')} $_playerLevel)',
              ),
              if (enemy.affixes.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildAffixChips(enemy, withDescriptions: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One chip per affix on [enemy] -- the one-word name, plus its rules
  /// text on the setup screen ([withDescriptions]) so the player can plan
  /// around it before the first roll.
  Widget _buildAffixChips(_EnemyMember enemy, {bool withDescriptions = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final affix in enemy.affixes)
          Tooltip(
            message: tr(ref, affixDescriptionKey(affix)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                withDescriptions
                    ? '${tr(ref, affixLabelKey(affix))}: ${tr(ref, affixDescriptionKey(affix))}'
                    : tr(ref, affixLabelKey(affix)),
                style: TextStyle(
                    fontSize: 11, color: colorScheme.onErrorContainer),
              ),
            ),
          ),
      ],
    );
  }

  /// The battlefield condition's banner on the setup screen: its name and
  /// its rules text, so the fight is read before it's rolled.
  Widget _buildConditionBanner(BattlefieldCondition condition) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.terrain, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, conditionLabelKey(condition)),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  tr(ref, conditionDescriptionKey(condition)),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onTertiaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The small status chips shown above the log during battle: the
  /// battlefield condition (if any) and the momentum meter.
  /// What the sky does to the fight (the same sentence the Journey gives
  /// its weather), when it does anything.
  String? _skyTip() => switch (_sky.kind.name) {
        'rain' ||
        'snow' ||
        'fog' ||
        'dust' ||
        'ash' =>
          tr(ref, 'weather_effect_${_sky.kind.name}'),
        _ => null,
      };

  Widget _buildBattleChips() {
    final condition = _condition;
    final ready = _momentum >= _momentumNeeded;
    return Row(
      children: [
        ..._goalChips(),
        if (condition != null)
          _telegraphChip(Icons.terrain, tr(ref, conditionLabelKey(condition)),
              tip: tr(ref, conditionDescriptionKey(condition))),
        if (_sky.effectKey != null)
          _telegraphChip(
              Icons.cloud_outlined, tr(ref, 'weather_${_sky.kind.name}'),
              color: Colors.lightBlue.shade200, tip: _skyTip()),
        if (_anomalyChip() case final chip?) chip,
        _telegraphChip(
          ready ? Icons.local_fire_department : Icons.trending_up,
          ready ? tr(ref, 'momentum_ready_label') : tr(ref, 'momentum_label'),
          badge: ready ? null : '$_momentum/$_momentumNeeded',
          color: ready ? Colors.orange : null,
          tip: tr(ref, 'momentum_tip'),
        ),
        // Luck nudges left (long-press a die to spend one).
        if (_nudgesLeft > 0)
          _telegraphChip(Icons.swap_vert, tr(ref, 'nudges_label'),
              badge: '$_nudgesLeft', tip: tr(ref, 'nudge_hint')),
        if (_hexPending)
          _telegraphChip(Icons.auto_fix_off, tr(ref, 'tamper_hex'),
              color: Colors.deepPurple.shade200,
              tip: tr(ref, 'tamper_hex_desc')),
        if (_silenced || _silencePending)
          _telegraphChip(Icons.volume_off, tr(ref, 'tamper_silence'),
              color: Colors.red.shade200, tip: tr(ref, 'tamper_silence_desc')),
        _buildTideMark(),
        _buildRuleMark(),
      ],
    );
  }

  Widget _buildBattle(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final acting = _actingParty;
    final anyDieAvailable = acting.any((m) =>
        m.equippedDiceId != null &&
        ((dice[m.equippedDiceId] as Map<String, dynamic>?)?['faces'] as List?)
                ?.isNotEmpty ==
            true);
    final plan = _roundPlan(skills, items, ref.watch(appLanguageProvider));
    final previews = plan.previews;

    final battle = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 8) * decay * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TutorialTarget(id: 'fight.top', child: _buildTopStrip()),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildSlots(items, previews),
          ),
          const SizedBox(height: 8),
          // The dice board takes what is left; the aim line is drawn over the
          // cards and the board together.
          Expanded(
            child: Stack(
              key: _battleSpaceKey,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TutorialTarget(
                      id: 'fight.dice',
                      child: _buildDiceBoard(acting, dice, skills, items, plan),
                    ),
                  ),
                ),
                Positioned.fill(child: _buildAimLine(plan)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_spoils != null)
            FightSpoilsStrip(
                spoils: _spoils!, goldLabel: tr(ref, 'gold_label')),
          if (ref.watch(appModeProvider) != AppMode.inGame) _buildLogTicker(),
          const SizedBox(height: 4),
          TutorialTarget(
            id: 'fight.actions',
            child: _buildBottomBar(
                acting, anyDieAvailable, dice, skills, items, session),
          ),
        ],
      ),
    );
    // Effects draw over the whole battle and never take a touch. The
    // fight's tour plays the first time a battle is on screen.
    return TutorialTrigger(
      topic: TutorialTopic.fight,
      // The first fight's tour waits for the lucky die to strike.
      ready: !widget.modifiers.luckyDieReveal || _luckyDieTourReady,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _buildBackdrop())),
          Positioned.fill(child: battle),
          Positioned.fill(child: _buildWeatherOverlay()),
          Positioned.fill(
            child: IgnorePointer(
              child: CombatVfxLayer(
                controller: _vfx,
                reducedMotion: MediaQuery.of(context).disableAnimations,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top strip -----------------------------------------------------------

  /// The battlefield condition, the momentum meter and the round counter --
  /// the fight-wide state, above the fighters.
  Widget _buildTopStrip() {
    final play = ref.watch(appModeProvider) == AppMode.inGame;
    return Row(
      children: [
        // One row of icon tiles; a long one scrolls rather than wraps.
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildBattleChips(),
          ),
        ),
        _telegraphChip(Icons.flag_outlined, tr(ref, 'round_label'),
            badge: '$_roundsStarted',
            tip: tr(ref, 'round_tip').replaceAll('{n}', '$tideStartRound')),
        if (play) _buildLogButton(),
      ],
    );
  }

  /// The place's rule (context_rules.dart) as a chip: its omen the round
  /// before it starts, then how far it has risen each round; in a town, the
  /// watch's whistle. Nothing for the Tide alone.
  Widget _buildRuleMark() {
    final status = placeRuleStatus(_length.rule, _roundsStarted);
    if (status == null) return const SizedBox.shrink();
    final (icon, colour) = placeRuleLook(status.stem);
    final stem = status.stem;
    String pct(double step) => '${(step * 100).round()}';
    final tip = tr(ref, 'context_${stem}_tip')
        .replaceAll(
            '{a}',
            switch (stem) {
              'mist' => pct(mistTickStep),
              'heat' => pct(heatTickStep),
              'water' => pct(waterBlowStep),
              'holy' => pct(sanctifiedHealStep),
              _ => '$risingStartRound',
            })
        .replaceAll(
            '{b}',
            switch (stem) {
              'heat' => pct(1 - heatHealFactor),
              'water' => pct(waterEnemyStep),
              'holy' => pct(sanctifiedLightStep),
              _ => '',
            });
    final label = status.omen
        ? tr(ref, 'context_${stem}_omen_mark')
        : '${tr(ref, 'context_${stem}_mark')} ×${status.level}';
    return KeyedSubtree(
      key: Key('place_rule_mark_$stem'),
      child: _telegraphChip(icon, label,
          color: colour,
          badge: status.omen ? '!' : '${status.level}',
          tip: tip),
    );
  }

  /// The Tide (fight_length.dart), the last of the battle chips, by the
  /// round count: once it rises
  /// "Tide ×N" with what it adds to each side's blows; a few rounds before,
  /// when it will.
  Widget _buildTideMark() {
    final level = tideLevel(_roundsStarted);
    final bossFight = _enemies.any((e) => isBossEnemy(e.enemyId, e.data));
    String pct(double step, int n) => '${(step * n * 100).round()}';
    final enemyStep = bossFight ? tideBossEnemyStep : tideEnemyStep;
    final Widget chip;
    if (level > 0) {
      chip = _telegraphChip(
          Icons.waves, tr(ref, 'tide_mark').replaceAll('{n}', '$level'),
          color: Colors.cyan.shade600,
          badge: '$level',
          tip: tr(ref, 'tide_mark_tip')
              .replaceAll('{party}', pct(tidePartyStep, level))
              .replaceAll('{enemies}', '${_tideEnemyPercent(_roundsStarted)}'));
    } else if (tideStartRound - _roundsStarted <= 3 && _roundsStarted > 0) {
      chip = _telegraphChip(
          Icons.waves,
          tr(ref, 'tide_soon_mark')
              .replaceAll('{n}', '${tideStartRound - _roundsStarted}'),
          color: Colors.blueGrey.shade300,
          badge: '${tideStartRound - _roundsStarted}',
          tip: tr(ref, 'tide_soon_tip')
              .replaceAll('{round}', '$tideStartRound')
              .replaceAll('{party}', pct(tidePartyStep, 1))
              .replaceAll('{enemies}', pct(enemyStep, 1)));
    } else {
      return const SizedBox.shrink();
    }
    return KeyedSubtree(key: const Key('fight_tide_mark'), child: chip);
  }

  // --- Dice tray -----------------------------------------------------------

  /// The party combos and duo techniques the dice on the table make (see
  /// party_combos.dart and duo_techniques.dart): what confirming now adds.
  Widget _buildComboChips(_RoundPlan plan) {
    final lang = ref.watch(appLanguageProvider);
    final french = lang == AppLanguage.fr;
    final colorScheme = Theme.of(context).colorScheme;
    Widget chip(IconData icon, String label, String tooltip, Color color) =>
        Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final combo in plan.combos)
            chip(Icons.groups, trFor(lang, comboLabelKey(combo)),
                trFor(lang, comboDescriptionKey(combo)), colorScheme.primary),
          for (final duo in plan.duos)
            chip(Icons.handshake, duo.nameFor(french),
                duo.descriptionFor(french), Colors.deepPurple),
        ],
      ),
    );
  }

  /// With momentum full and more than one strike on the table, the player
  /// picks which one the guaranteed critical lands on.
  Widget _buildSurgePicker(List<_PartyMember> acting) {
    final striking = _strikerIds();
    final strikers = [
      for (final actor in acting)
        if (striking.contains(actor.id)) actor,
    ];
    if (strikers.length < 2) return const SizedBox.shrink();
    final recipient = _surgeRecipient();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 4),
            Text(tr(ref, 'surge_pick_label'),
                style: Theme.of(context).textTheme.labelMedium),
            for (final actor in strikers)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(actor.displayName),
                  selected: recipient == actor.id,
                  onSelected: (_) => _update(() => _surgeActorId = actor.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDieTile(
    _PartyMember actor,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    bool canLock,
    _FacePreview? preview, {
    double cube = 46,
  }) {
    final accent = _accentFor(actor);
    final face = _currentFaces[actor.id];
    final locked = _isDieLocked(actor.id);
    final spinning = _rolling && !locked;

    // The die as a cube (v1.214, see Die3D): it tumbles to the face it
    // rolled, which stands front, and a landed face lets go a burst fitted
    // to what it does; a skill face or a heavy blow lands bigger.
    final landing = spinning ? _rollingTo[actor.id] ?? face : face;
    final Widget inner = Die3D(
      key: ValueKey('die_cube_${actor.id}'),
      faces: _cubeFacesFor(actor, landing, accent),
      accent: accent,
      size: cube,
      roll: _rollController,
      rolling: spinning,
      fx: face == null ? null : dieFxOf(_faceKindOf(face)),
      big: face != null && (face.type == 'Skill' || face.value >= 8),
      dim: face == null && !spinning,
      still: MediaQuery.of(context).disableAnimations,
      // The die's own skin, a gold ring when kept, and what the landed face
      // adds to the burst: its rule words, its element, a surge, a curse.
      skin: dieSkinOf(actor.equippedDiceId),
      shape: dieShapeOf(actor.dieFaces.length),
      artId: actor.equippedDiceId,
      held: locked,
      keywords: face?.keywords ?? const {},
      element: face == null ? 'None' : _elementFor(face, skills),
      surge: preview?.surge ?? false,
      cursed: face != null &&
          (_cursedFaces[actor.id]?.contains(face.faceIndex) ?? false),
    );
    final label = face == null || spinning
        ? ''
        : (face.faceName.isEmpty ? face.type : face.faceName);
    return GestureDetector(
      key: ValueKey('die_tile_${actor.id}'),
      // A tap selects the die, a second locks it; a double tap releases a
      // lock until the next roll (die_locks.dart).
      onTap: face == null
          ? null
          : () => _onDieTap(actor, face, canLock, dice, skills, items),
      onLongPress: face == null
          ? null
          : () => _showFaceSheet(actor, face, dice, skills, items),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // No tile under the die: the cube stands on its own, and a kept
          // die shows its gold ring.
          SizedBox(
            key: _dieKey(actor.id),
            width: cube + 12,
            height: cube + 12,
            child: Stack(
              children: [
                Center(child: inner),
                if (_dieLocks.selected == actor.id && !locked)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: Key('die_picked_${actor.id}'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFF2C14E), width: 3),
                          boxShadow: const [
                            BoxShadow(color: Color(0x88F2C14E), blurRadius: 16)
                          ],
                        ),
                      ),
                    ),
                  ),
                if (locked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                        _steadyActorIds.contains(actor.id)
                            ? Icons.anchor
                            : Icons.lock,
                        size: 12,
                        color: accent),
                  ),
                // The hero's profession core on the die: Flurry doubles an
                // attack face; the Trail shows the face coming next.
                if (actor.isPlayer &&
                    face != null &&
                    !spinning &&
                    _core.core == ProfessionCore.flurry &&
                    _faceKindOf(face) == FaceKind.attack)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: DieBadge(
                        text: '×2', tooltip: tr(ref, 'flurry_tag_tip')),
                  ),
                if (actor.isPlayer &&
                    !spinning &&
                    _core.core == ProfessionCore.trail &&
                    _core.aheadIndex != null &&
                    _core.aheadIndex! < actor.dieFaces.length)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Tooltip(
                      key: const Key('trail_next_face'),
                      message: tr(ref, 'trail_next_tip'),
                      child: Opacity(
                        opacity: 0.8,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.black54,
                            border: Border.all(
                                color: accent.withValues(alpha: 0.7)),
                          ),
                          child: Center(
                              child: _buildFaceGlyph(
                                  faceFromJson(
                                      actor.dieFaces[_core.aheadIndex!],
                                      _core.aheadIndex!),
                                  size: 14)),
                        ),
                      ),
                    ),
                  ),
                // The landed face's keywords (see face_keywords.dart).
                if (face != null && !spinning && face.keywords.isNotEmpty)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: FaceKeywordBadges(face.keywords, size: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: cube + 24,
            child: Text(
              actor.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          SizedBox(
            width: cube + 24,
            height: 12,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          SizedBox(
            width: cube + 24,
            height: 13,
            child: face == null || spinning || preview == null
                ? null
                : _buildPreviewLine(preview, actor),
          ),
        ],
      ),
    );
  }

  /// The one number a landed die is worth this round, under its name on
  /// the tile: the damage its target would take (marked when it would drop
  /// the target, starred when momentum makes it a guaranteed critical),
  /// or the healing, block or mana it gives.
  Widget _buildPreviewLine(_FacePreview preview, _PartyMember actor) {
    final result = preview.result;
    final IconData icon;
    final String text;
    final Color color;
    if (result.damageDealt > 0) {
      icon = preview.surge ? Icons.auto_awesome : Icons.bolt;
      text = preview.lethal
          ? '${preview.damage} ${tr(ref, 'preview_lethal_label')}'
          : '${preview.damage}';
      color = preview.lethal ? Colors.red.shade900 : FaceKind.attack.color;
    } else if (preview.healing > 0) {
      icon = FaceKind.heal.icon;
      color = FaceKind.heal.color;
      // Healing fatigue (fight_length.dart): each heal this member has given
      // heals less; the number shown is the tired one, dimmed. The cleric's
      // Watchfire doesn't tire.
      final before = actor.isPlayer && _core.core == ProfessionCore.watchfire
          ? 0
          : _length.healsBy(actor.id);
      if (before > 0) {
        final tired = fatiguedHeal(preview.healing, before);
        return Tooltip(
          message: tr(ref, 'heal_fatigue_tip').replaceAll(
              '{pct}', '${(healFatigueFactor(before) * 100).round()}'),
          child: Row(
            key: const Key('fatigued_heal'),
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color.withValues(alpha: 0.45)),
              const SizedBox(width: 2),
              Text('+$tired',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: color.withValues(alpha: 0.5))),
            ],
          ),
        );
      }
      text = '+${preview.healing}';
    } else if (preview.block > 0) {
      icon = FaceKind.defend.icon;
      text = '${preview.block}';
      color = FaceKind.defend.color;
      // In a party fight the biggest Defend kept draws the enemies'
      // attacks (see _confirmRoll's taunt).
      if (_party.where((m) => !m.isKnockedOut).length > 1) {
        return Tooltip(
          message: tr(ref, 'defend_draws_attacks_hint'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 2),
              Text(text,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Icon(Icons.my_location, size: 10, color: color),
            ],
          ),
        );
      }
    } else if (result.manaGained > 0) {
      icon = manaIcon;
      text = '+${result.manaGained}';
      color = manaColor;
    } else {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  /// What [face] does, for its colour: the face's own type, or for a
  /// Skill face the skill it casts (see [skillKind]).
  FaceKind _faceKindOf(DiceFaceResult face) {
    if (face.type != 'Skill') return faceKind(face.type);
    final skills =
        ref.read(localizedDbProvider(skillsSchema)).value ?? const {};
    return skillKind(skills[_effectiveSkillId(face)] as Map<String, dynamic>?);
  }

  /// The six sides of [actor]'s die as a cube, [landed] (the face on the
  /// table, or the one the die is tumbling to) in front and the die's next
  /// faces round it; a die of fewer than six faces repeats them.
  List<DieCubeFace> _cubeFacesFor(
      _PartyMember actor, DiceFaceResult? landed, Color accent) {
    final raws = actor.dieFaces;
    if (raws.isEmpty) {
      return List.filled(
          6,
          DieCubeFace(
              glyph: Icon(Icons.casino, size: 22, color: accent),
              color: accent));
    }
    final language = ref.read(appLanguageProvider);
    final start = landed?.faceIndex ?? 0;
    return [
      for (var slot = 0; slot < 6; slot++)
        () {
          final index = (start + slot) % raws.length;
          final DiceFaceResult face;
          if (slot == 0 && landed != null) {
            face = landed;
          } else {
            final assigned = applyFaceAssignment(
              faceFromJson(raws[index], index).withFaceName(''),
              raws[index],
              actor.diceSkillAssignments[index.toString()],
              language: language,
            );
            face = (_cursedFaces[actor.id]?.contains(index) ?? false)
                ? cursedFace(assigned)
                : assigned;
          }
          return DieCubeFace(
              glyph: _cubeGlyph(face), color: _faceKindOf(face).color);
        }(),
    ];
  }

  /// A side of the cube: a skill face holds the skill's own icon, large, on
  /// a pale plaque ringed in what the skill does so the pixel art reads on
  /// the dark stone (v1.214); any other face, its type icon over its value.
  Widget _cubeGlyph(DiceFaceResult face) {
    if (face.type != 'Skill') return _buildFaceGlyph(face, size: 30);
    final color = _faceKindOf(face).color;
    return Container(
      key: ValueKey('die_skill_${_effectiveSkillId(face)}'),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEFE6D2).withValues(alpha: 0.92),
        border: Border.all(color: color, width: 2),
      ),
      child: SkillPixelIcon(_effectiveSkillId(face), size: 26),
    );
  }

  /// A rolled face as a glyph: its type icon over its value (a Skill face
  /// shows the skill's own pixel icon instead).
  Widget _buildFaceGlyph(DiceFaceResult face, {double size = 28}) {
    if (face.type == 'Skill') {
      return SkillPixelIcon(_effectiveSkillId(face), size: size);
    }
    final color = _faceKindOf(face).color;
    final showValue = face.value > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_faceTypeIcon(face.type),
            size: showValue ? size * 0.62 : size, color: color),
        if (showValue)
          Text(
            '${face.value}',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
      ],
    );
  }

  /// The sheet behind a die tile: what confirming this face would do, which
  /// skill it resolves to, and every face of the die it came from -- the
  /// same read a long-press gives on a die in Slice & Dice.
  Future<void> _showFaceSheet(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final lang = ref.read(appLanguageProvider);
    final availableSkills = _availableSkillsFor(actor, skills);
    // The tile's own preview when this is the face on the table (the usual
    // case); otherwise the face resolved on its own, with no target.
    final tablePreview = _previewRoll(skills, items, lang)[actor.id];
    final preview = tablePreview != null &&
            tablePreview.result.message.isNotEmpty &&
            _currentFaces[actor.id] == face
        ? tablePreview
        : _FacePreview(
            result: resolvePlayerFace(
              face,
              availableSkills,
              _totalDamageFor(actor, face, skills, items),
              language: lang,
              activeEffects: actor.statusEffects,
              wisdomHealBonus: wisdomHealBonusFor(actor.wisdom),
              wisdomManaBonus: wisdomManaBonusFor(actor.wisdom),
              alignmentLabel: _alignmentLabel,
            ),
            target: null,
            damage: 0,
            healing: 0,
            block: 0,
            surge: false,
          );
    final target = preview.target;
    final targetLine = target == null || preview.damage <= 0
        ? null
        : '${trFor(lang, 'preview_against_prefix')} ${target.displayName}: '
            '${preview.damage} ${trFor(lang, 'damage_word')}, '
            '${preview.lethal ? trFor(lang, 'preview_lethal_label') : '${max(0, target.currentHealth - preview.damage)} ${trFor(lang, 'hp_label')} ${trFor(lang, 'preview_left_suffix')}'}';
    final element = _elementFor(face, availableSkills);
    final dieId = actor.equippedDiceId;
    // The die as smithed at the Hammersmith.
    final faces = actor.dieFaces;
    final accent = _accentFor(actor);
    final onTable = _currentFaces[actor.id] == face;
    final growth = face.hasKeyword(FaceKeyword.growth)
        ? (_growthUses['${actor.id}:${face.faceIndex}'] ?? 0) * growthStep
        : 0;
    final cursed = _cursedFaces[actor.id]?.contains(face.faceIndex) ?? false;
    final canNudge =
        onTable && _awaitingDecision && !_rolling && _nudgesLeft > 0;
    final nudgeTo = canNudge ? _nudgePreview(actor) : null;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        // Scrolls: a face with keywords, a curse and a nudge to offer
        // runs taller than a phone's sheet.
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _faceKindOf(face).color.withValues(alpha: 0.16),
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Center(child: _buildFaceGlyph(face, size: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            face.faceName.isEmpty ? face.type : face.faceName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${actor.displayName} · ${dieDisplayName(dieId ?? '', language: lang)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(preview.result.message, style: theme.textTheme.bodyMedium),
                if (targetLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    targetLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: preview.lethal ? Colors.red : Colors.deepOrange,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                if (face.type == 'Skill') ...[
                  const SizedBox(height: 4),
                  Text(
                    face.isChanneled
                        ? trFor(lang, 'channeled_face_note').replaceAll(
                            '{face}',
                            trFor(lang, basicFaceLabelKey(face.channeledFrom)))
                        : '${trFor(lang, 'skill_label')}: '
                            '${skillDisplayName(_effectiveSkillId(face), language: lang)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (element != 'None') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(elementIcon(element), size: 14),
                      const SizedBox(width: 4),
                      Text('${trFor(lang, 'element_label')}: $element',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
                // The face's keywords, in full (see face_keywords.dart).
                for (final keyword in face.keywords) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(keyword.icon, size: 14, color: keyword.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${trFor(lang, keywordLabelKey(keyword))}: '
                          '${trFor(lang, keywordDescriptionKey(keyword))}'
                          '${keyword == FaceKeyword.growth && growth > 0 ? ' (+$growth)' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                if (cursed) ...[
                  const SizedBox(height: 4),
                  Text(trFor(lang, 'cursed_face_note'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.red.shade700)),
                ],
                if (_steadyActorIds.contains(actor.id) && onTable) ...[
                  const SizedBox(height: 4),
                  Text(trFor(lang, 'steady_kept_note'),
                      style: theme.textTheme.bodySmall),
                ],
                // A Luck nudge turns the die to its opposite face.
                if (nudgeTo != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _nudge(actor);
                    },
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: Text(trFor(lang, 'nudge_button')
                        .replaceAll('{face}', nudgeTo.faceName)
                        .replaceAll('{n}', '$_nudgesLeft')),
                  ),
                ],
                if (faces.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(trFor(lang, 'die_faces_label'),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < faces.length; i++)
                        _buildMiniFace(faces[i], i, i == face.faceIndex, accent,
                            actor, sheetContext),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                FaceColorLegend(language: lang),
                const SizedBox(height: 10),
                Text(trFor(lang, 'lock_hint'),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One face of a whole die in [_showFaceSheet]'s grid.
  Widget _buildMiniFace(
    Map<String, dynamic> raw,
    int index,
    bool isRolled,
    Color accent,
    _PartyMember actor,
    BuildContext sheetContext,
  ) {
    final assigned = applyFaceAssignment(
      faceFromJson(raw, index).withFaceName(''),
      raw,
      actor.diceSkillAssignments[index.toString()],
      language: ref.read(appLanguageProvider),
    );
    // A Curse shows on the face it fell on.
    final cursed = _cursedFaces[actor.id]?.contains(index) ?? false;
    final face = cursed ? cursedFace(assigned) : assigned;
    final colorScheme = Theme.of(sheetContext).colorScheme;
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _faceKindOf(face)
                  .color
                  .withValues(alpha: isRolled ? 0.28 : 0.14),
              border: Border.all(
                color: cursed
                    ? Colors.red.shade700
                    : isRolled
                        ? accent
                        : colorScheme.outlineVariant,
                width: isRolled || cursed ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(child: _buildFaceGlyph(face, size: 22)),
                if (face.keywords.isNotEmpty)
                  Positioned(
                    top: 1,
                    left: 1,
                    child: FaceKeywordBadges(face.keywords, size: 9),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            face.faceName.isEmpty ? face.type : face.faceName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
