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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                equippedDie == null ? null : () => _startFight(skills, items),
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(tr(ref, 'enter_battle_button')),
          ),
        ],
      ),
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
  Widget _buildBattleChips() {
    final condition = _condition;
    final ready = _momentum >= _momentumThreshold;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (condition != null)
          _telegraphChip(Icons.terrain, tr(ref, conditionLabelKey(condition))),
        _telegraphChip(
          ready ? Icons.local_fire_department : Icons.trending_up,
          ready
              ? tr(ref, 'momentum_ready_label')
              : '${tr(ref, 'momentum_label')} $_momentum/$_momentumThreshold',
        ),
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
    final previews =
        _previewRoll(skills, items, ref.watch(appLanguageProvider));

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
            child: _buildTopStrip(),
          ),
          const SizedBox(height: 6),
          _buildDiceTray(acting, dice, skills, items, previews),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildPartyColumn(items)),
                  const SizedBox(width: 8),
                  Expanded(flex: 6, child: _buildEnemyColumn(previews)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildLogTicker(),
          const SizedBox(height: 4),
          _buildBottomBar(
              acting, anyDieAvailable, dice, skills, items, session),
        ],
      ),
    );
    // Effects draw over the whole battle and never take a touch.
    return Stack(
      children: [
        Positioned.fill(child: battle),
        Positioned.fill(
          child: IgnorePointer(
            child: CombatVfxLayer(
              controller: _vfx,
              reducedMotion: MediaQuery.of(context).disableAnimations,
            ),
          ),
        ),
      ],
    );
  }

  // --- Top strip -----------------------------------------------------------

  /// The battlefield condition, the momentum meter and the round counter --
  /// the fight-wide state, above the dice.
  Widget _buildTopStrip() {
    return Row(
      children: [
        Expanded(child: _buildBattleChips()),
        _telegraphChip(
            Icons.flag_outlined, '${tr(ref, 'round_label')} $_roundsStarted'),
      ],
    );
  }

  // --- Dice tray -----------------------------------------------------------

  /// The party's rolled dice, one tile per acting member, in the member's
  /// own accent color, with what the landed face is worth this round under
  /// its name (see [_buildPreviewLine]). A tap on a landed die keeps it
  /// through the next reroll (tap again to release it); a long-press opens
  /// the face's details and the whole die.
  Widget _buildDiceTray(
    List<_PartyMember> acting,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    Map<String, _FacePreview> previews,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canLock =
        _awaitingDecision && !_rolling && _rollCount < _maxRollsThisFight;
    final hintKey = acting.isEmpty
        ? 'nobody_can_act_label'
        : _currentFaces.isEmpty
            ? 'roll_hint'
            : canLock
                ? 'lock_hint'
                : 'confirm_hint';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final actor in acting)
                Expanded(
                  child: Center(
                    child: _buildDieTile(actor, dice, skills, items, canLock,
                        previews[actor.id]),
                  ),
                ),
            ],
          ),
          if (_momentum >= _momentumThreshold && !_rolling)
            _buildSurgePicker(acting),
          const SizedBox(height: 4),
          Text(
            tr(ref, hintKey),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// With momentum full and more than one strike on the table, the player
  /// picks which one the guaranteed critical lands on.
  Widget _buildSurgePicker(List<_PartyMember> acting) {
    final strikers = [
      for (final actor in acting)
        if (_currentFaces[actor.id]?.type == 'Attack' ||
            _currentFaces[actor.id]?.type == 'Skill')
          actor,
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
    _FacePreview? preview,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(actor);
    final face = _currentFaces[actor.id];
    final locked = _lockedActorIds.contains(actor.id);
    final spinning = _rolling && !locked;

    Widget inner;
    if (spinning) {
      inner = AnimatedBuilder(
        animation: _rollController,
        builder: (context, _) {
          final t = _rollController.value;
          final angle = Curves.easeOutCubic.transform(t) * 6 * pi;
          final scale = 1 + (sin(t * pi) * 0.25);
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Icon(Icons.casino, size: 30, color: accent),
            ),
          );
        },
      );
    } else if (face == null) {
      inner =
          Icon(Icons.casino, size: 30, color: accent.withValues(alpha: 0.45));
    } else {
      inner = _buildFaceGlyph(face, size: 30);
    }

    final label = face == null || spinning
        ? ''
        : (face.faceName.isEmpty ? face.type : face.faceName);
    return GestureDetector(
      onTap: face == null
          ? null
          : () {
              if (canLock) {
                _update(() {
                  if (locked) {
                    _lockedActorIds.remove(actor.id);
                  } else {
                    _lockedActorIds.add(actor.id);
                  }
                });
              } else {
                _showFaceSheet(actor, face, dice, skills, items);
              }
            },
      onLongPress: face == null
          ? null
          : () => _showFaceSheet(actor, face, dice, skills, items),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  locked ? accent.withValues(alpha: 0.22) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: locked ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(child: inner),
                if (locked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.lock, size: 12, color: accent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 72,
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
            width: 72,
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
            width: 72,
            height: 13,
            child: face == null || spinning || preview == null
                ? null
                : _buildPreviewLine(preview),
          ),
        ],
      ),
    );
  }

  /// The one number a landed die is worth this round, under its name on
  /// the tile: the damage its target would take (marked when it would drop
  /// the target, starred when momentum makes it a guaranteed critical),
  /// or the healing, block or mana it gives.
  Widget _buildPreviewLine(_FacePreview preview) {
    final result = preview.result;
    final IconData icon;
    final String text;
    final Color color;
    if (result.damageDealt > 0) {
      icon = preview.surge ? Icons.auto_awesome : Icons.bolt;
      text = preview.lethal
          ? '${preview.damage} ${tr(ref, 'preview_lethal_label')}'
          : '${preview.damage}';
      color = preview.lethal ? Colors.red : Colors.deepOrange;
    } else if (preview.healing > 0) {
      icon = Icons.favorite;
      text = '+${preview.healing}';
      color = Colors.green;
    } else if (preview.block > 0) {
      icon = Icons.shield;
      text = '${preview.block}';
      color = Colors.blue;
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

  /// A rolled face as a glyph: its type icon over its value (a Skill face
  /// shows the skill's own pixel icon instead).
  Widget _buildFaceGlyph(DiceFaceResult face, {double size = 28}) {
    if (face.type == 'Skill') {
      return SkillPixelIcon(_effectiveSkillId(face), size: size);
    }
    final color = _faceTypeColor(face.type);
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
              wisdomHealBonus: actor.wisdom ~/ 2,
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
    final faces = dieId == null
        ? const <Map<String, dynamic>>[]
        : ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final accent = _accentFor(actor);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
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
    final face = applyFaceAssignment(
      DiceFaceResult(
        faceIndex: index,
        faceName: '',
        type: raw['type']?.toString() ?? 'Empty',
        value: (raw['value'] as num?)?.toInt() ?? 0,
        linkedSkillID: raw['linkedSkillID']?.toString() ?? '',
        element: raw['element']?.toString() ?? 'None',
      ),
      raw,
      actor.diceSkillAssignments[index.toString()],
      language: ref.read(appLanguageProvider),
    );
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
              color: isRolled ? accent.withValues(alpha: 0.2) : null,
              border: Border.all(
                color: isRolled ? accent : colorScheme.outlineVariant,
                width: isRolled ? 2 : 1,
              ),
            ),
            child: Center(child: _buildFaceGlyph(face, size: 22)),
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
