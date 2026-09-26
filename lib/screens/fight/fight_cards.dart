part of '../fight_screen.dart';

/// The party's and the enemies' cards, and the enemy sheet.
extension _FightCards on _FightScreenState {
  // --- Party column --------------------------------------------------------

  Widget _buildPartyColumn(Map<String, dynamic> items) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final member in _party) ...[
          KeyedSubtree(
            key: _memberCardKey(member.id),
            child: VfxRecoil(
              controller: _vfx,
              anchor: _memberCardKey(member.id),
              child: _buildPartyCard(member, items),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// One party member: avatar in their accent color, name, a thin health
  /// bar with numbers, block/status chips, and the die slot showing the
  /// face they're holding. In a pack fight, tapping the card selects whose
  /// die the enemy column's taps aim.
  Widget _buildPartyCard(_PartyMember member, Map<String, dynamic> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(member);
    final face = _currentFaces[member.id];
    final isStrike =
        face != null && (face.type == 'Attack' || face.type == 'Skill');
    final canSelect = _enemies.length > 1 &&
        isStrike &&
        _awaitingDecision &&
        !_rolling &&
        (member.isPlayer || !_companionsAutoAim);
    final isSelected = canSelect && _selectedActorId == member.id;
    final targeted = !member.isKnockedOut && _isTelegraphedTarget(member);
    final scalingBonus = equipmentScalingBonusFor(
      member.equippedItemIds,
      items,
      strength: member.strength,
      dexterity: member.dexterity,
      constitution: member.constitution,
      intelligence: member.intelligence,
    );
    final armor = member.armor +
        equipmentBonusFor(member.equippedItemIds, items, 'armor') +
        scalingBonus.armorBonus;
    final damage = member.baseDamage +
        equipmentBonusFor(member.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus;
    final initial =
        member.displayName.isEmpty ? '?' : member.displayName[0].toUpperCase();

    final card = GestureDetector(
      onTap:
          canSelect ? () => _update(() => _selectedActorId = member.id) : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: member.isKnockedOut
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      member.isKnockedOut ? colorScheme.outline : accent,
                  child: Text(
                    initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (targeted)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.gps_fixed,
                        size: 14, color: colorScheme.error),
                  ),
                _buildDieSlot(face, accent),
              ],
            ),
            const SizedBox(height: 5),
            _buildHpBar(member.currentHealth, member.maxHealth),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _miniStat(Icons.bolt, '$damage', Colors.deepOrange),
                _miniStat(Icons.shield_outlined, '$armor', Colors.blueGrey),
                if (member.block > 0)
                  _miniStat(Icons.shield, '+${member.block}', Colors.blue),
                for (final effect in member.statusEffects)
                  _StatusEffectChip(effect: effect),
                if (member.isKnockedOut)
                  Text(
                    tr(ref, 'knocked_out_label'),
                    style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return _withDamagePopup(
      card,
      show: _lastDamagedMemberId == member.id && _lastDamageTaken > 0,
      amount: _lastDamageTaken,
      fade: true,
    );
  }

  /// The small square next to a party member's name holding the face they
  /// rolled this round -- empty (dashed) before the roll.
  Widget _buildDieSlot(DiceFaceResult? face, Color accent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: face == null || _rolling
            ? null
            : _faceKindOf(face).color.withValues(alpha: 0.18),
        border: Border.all(
          color: face == null ? colorScheme.outlineVariant : accent,
          width: face == null ? 1 : 1.5,
        ),
      ),
      child: face == null || _rolling
          ? Icon(Icons.casino,
              size: 14, color: colorScheme.outline.withValues(alpha: 0.6))
          : Center(child: _buildFaceGlyph(face, size: 18)),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  /// A thin health bar with its numbers inside -- shared by both columns.
  /// With [pending] damage on the way (the dice aimed at an enemy, see
  /// [_previewRoll]) the slice about to go is painted [_previewColor] and
  /// the numbers read "now → after / max".
  Widget _buildHpBar(int current, int maxValue,
      {double height = 14, int pending = 0}) {
    final rawRatio = maxValue <= 0 ? 0.0 : current / maxValue;
    final ratio = rawRatio.clamp(0.0, 1.0);
    final after = max(0, current - pending);
    final afterRatio = maxValue <= 0 ? 0.0 : (after / maxValue).clamp(0.0, 1.0);
    final barColor = ratio > 0.5
        ? Colors.green
        : (ratio > 0.25 ? Colors.orange : Colors.red);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.18),
          border: Border.all(color: barColor.withValues(alpha: 0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * ratio,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [barColor.withValues(alpha: 0.75), barColor],
                        ),
                      ),
                    ),
                  ),
                  if (pending > 0 && ratio > afterRatio)
                    Positioned(
                      left: constraints.maxWidth * afterRatio,
                      width: constraints.maxWidth * (ratio - afterRatio),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _previewColor.withValues(alpha: 0.9),
                          border: Border(
                            left: BorderSide(
                                color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              pending > 0
                  ? '$current → $after / $maxValue'
                  : '$current / $maxValue',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: height * 0.68,
                height: 1,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Overlays a floating "-N" on [child] for the combatant that was just
  /// hit -- fading with the screen shake for the party, static for an enemy.
  Widget _withDamagePopup(Widget child,
      {required bool show, required int amount, bool fade = false}) {
    if (!show) return child;
    final label = Text(
      '-$amount',
      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 4,
          top: -6,
          child: fade
              ? AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, _) => Opacity(
                    opacity: (1 - _shakeController.value).clamp(0.0, 1.0),
                    child: label,
                  ),
                )
              : label,
        ),
      ],
    );
  }

  // --- Enemy column --------------------------------------------------------

  Widget _buildEnemyColumn(Map<String, _FacePreview> previews) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final enemy in _enemies) ...[
          KeyedSubtree(
            key: _enemyCardKey(enemy.key),
            child: VfxRecoil(
              controller: _vfx,
              anchor: _enemyCardKey(enemy.key),
              child: _buildEnemyCard(enemy, previews),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// One enemy: portrait, name, health bar (with the slice the dice aimed
  /// at it would take off, see [_buildHpBar]), affix/status chips, the
  /// dots of every party die currently aimed at it, and its intent box
  /// (see [_buildIntentBox]). In a pack fight a tap aims the selected
  /// member's die here; otherwise (or on a long-press) it opens the
  /// enemy's details.
  Widget _buildEnemyCard(
      _EnemyMember enemy, Map<String, _FacePreview> previews) {
    final colorScheme = Theme.of(context).colorScheme;
    var pending = 0;
    for (final preview in previews.values) {
      if (preview.target?.key == enemy.key) pending += preview.damage;
    }
    final lethal = enemy.isAlive && pending >= enemy.currentHealth;
    final selectedActor =
        _selectedActorId == null ? null : _memberById(_selectedActorId!);
    final canRetarget = selectedActor != null &&
        _enemies.length > 1 &&
        _awaitingDecision &&
        !_rolling &&
        enemy.isAlive &&
        _selectedTargets.containsKey(selectedActor.id);
    final aimingActors = <_PartyMember>[
      for (final actor in _actingParty)
        if (_currentFaces[actor.id] != null &&
            (_currentFaces[actor.id]!.type == 'Attack' ||
                _currentFaces[actor.id]!.type == 'Skill') &&
            (_enemies.length == 1
                ? enemy.isAlive
                : _selectedTargets[actor.id] == enemy.key))
          actor,
    ];
    final aimedBySelected =
        canRetarget && _selectedTargets[selectedActor.id] == enemy.key;
    final borderColor = aimedBySelected
        ? _accentFor(selectedActor)
        : _isElite && enemy.isAlive
            ? Colors.amber.shade700
            : colorScheme.outlineVariant;

    final card = GestureDetector(
      onTap: !enemy.isAlive
          ? null
          : canRetarget
              ? () => _update(() {
                    _selectedTargets[selectedActor.id] = enemy.key;
                    // Auto-aiming companions follow the player's new pick.
                    _autoAssignTargets();
                  })
              : () => _showEnemySheet(enemy),
      onLongPress: () => _showEnemySheet(enemy),
      child: Opacity(
        opacity: enemy.isAlive ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: aimedBySelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EnemyPixelIcon(enemy.enemyId, size: 30),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      enemy.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isElite ? Colors.amber.shade800 : null,
                          ),
                    ),
                  ),
                  if (aimingActors.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final actor in aimingActors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentFor(actor),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              _buildHpBar(enemy.currentHealth, enemy.maxHealth,
                  pending: enemy.isAlive ? pending : 0),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _miniStat(Icons.bolt, '${enemy.damage}', Colors.deepOrange),
                  if (enemy.isAlive && pending > 0)
                    _miniStat(
                      lethal ? Icons.dangerous_outlined : Icons.arrow_downward,
                      lethal
                          ? '-$pending ${tr(ref, 'preview_lethal_label')}'
                          : '-$pending',
                      _previewColor,
                    ),
                  if (enemy.fled)
                    Text(tr(ref, 'fled_label'),
                        style: const TextStyle(
                            fontSize: 10, fontStyle: FontStyle.italic)),
                  for (final effect in enemy.statusEffects)
                    _StatusEffectChip(effect: effect),
                ],
              ),
              if (enemy.affixes.isNotEmpty) ...[
                const SizedBox(height: 3),
                _buildAffixChips(enemy),
              ],
              if (enemy.currentPhase != null) _buildPhaseChip(enemy),
              if (enemy.isAlive) ...[
                const SizedBox(height: 5),
                _buildIntentBox(enemy),
              ],
            ],
          ),
        ),
      ),
    );
    return _withDamagePopup(
      card,
      show: _lastDamagedEnemyKey == enemy.key && _lastEnemyDamageTaken > 0,
      amount: _lastEnemyDamageTaken,
    );
  }

  /// The boss phase [enemy] is currently in, as a small purple chip under
  /// its affixes; its message on hover.
  Widget _buildPhaseChip(_EnemyMember enemy) {
    final phase = enemy.currentPhase;
    if (phase == null) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Tooltip(
        message: phase.messageFor(lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.change_circle_outlined,
                  size: 11, color: Colors.deepPurple),
              const SizedBox(width: 3),
              Text(
                '${tr(ref, 'phase_chip_prefix')} ${enemy.phaseIndex}: '
                '${phase.nameFor(lang)}',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The enemy's intent for its next turn, at whatever detail the party's
  /// Perception reads it (see [telegraphTierFor]): a "?" box when nothing
  /// can be read, the target's name from the first tier, a move-category
  /// icon from the second, and the damage number, element and the move's
  /// own words at the full tier.
  Widget _buildIntentBox(_EnemyMember enemy) {
    final colorScheme = Theme.of(context).colorScheme;
    final pending = enemy.pendingMove;
    final tier =
        pending == null ? TelegraphTier.none : _effectiveTierFor(enemy);
    final hit = tier == TelegraphTier.full
        ? _expectedHit(
            enemy,
            ref.read(localizedDbProvider(skillsSchema)).value ?? const {},
            ref.read(localizedDbProvider(itemsSchema)).value ?? const {})
        : null;
    final textStyle = TextStyle(
        fontSize: 10,
        color: colorScheme.onErrorContainer,
        fontWeight: FontWeight.w600);

    Widget content;
    if (pending == null || tier == TelegraphTier.none) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline,
              size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(tr(ref, 'intent_unknown_label'), style: textStyle),
        ],
      );
    } else {
      final targetName = _memberById(pending.targetId)?.displayName ?? '?';
      final showCategory =
          tier == TelegraphTier.category || tier == TelegraphTier.full;
      final categoryIcon = switch (categoryFor(pending.move)) {
        MoveCategory.attack => Icons.bolt,
        MoveCategory.healSelf => Icons.healing,
        MoveCategory.statusDebuff => Icons.sick,
      };
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(showCategory ? categoryIcon : Icons.visibility,
                  size: 12, color: colorScheme.onErrorContainer),
              if (tier == TelegraphTier.full && hit != null) ...[
                const SizedBox(width: 2),
                // What lands after armor, resist and block, then (dimmed)
                // what the blow carries before them.
                Text('${hit.net}', style: textStyle),
                if (hit.net != hit.raw)
                  Text('/${hit.raw}',
                      style: textStyle.copyWith(
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onErrorContainer
                              .withValues(alpha: 0.7))),
                if (hit.net == 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.shield,
                        size: 11, color: colorScheme.onErrorContainer),
                  ),
              ],
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward,
                  size: 11, color: colorScheme.onErrorContainer),
              const SizedBox(width: 3),
              Expanded(
                child: Text(targetName,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (tier == TelegraphTier.full && pending.move.element != 'None')
                Icon(elementIcon(pending.move.element),
                    size: 12, color: colorScheme.onErrorContainer),
            ],
          ),
          if (tier == TelegraphTier.full)
            Text(
              pending.move.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onErrorContainer),
            ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: content,
    );
  }

  Widget _telegraphChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: colorScheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }

  /// The sheet behind an enemy card: its numbers, every affix's rules text,
  /// its active status effects and its readable intent, in full sentences.
  Future<void> _showEnemySheet(_EnemyMember enemy) {
    final lang = ref.read(appLanguageProvider);
    final pending = enemy.pendingMove;
    final tier =
        pending == null ? TelegraphTier.none : _effectiveTierFor(enemy);
    final targetName = pending == null
        ? ''
        : _memberById(pending.targetId)?.displayName ?? '?';
    final categoryLabel = pending == null
        ? ''
        : trFor(
            lang,
            switch (categoryFor(pending.move)) {
              MoveCategory.attack => 'telegraph_category_attack',
              MoveCategory.healSelf => 'telegraph_category_heal',
              MoveCategory.statusDebuff => 'telegraph_category_debuff',
            });
    final intentText = switch (tier) {
      TelegraphTier.none => trFor(lang, 'intent_unknown_desc'),
      TelegraphTier.target =>
        '${trFor(lang, 'intent_target_prefix')} $targetName.',
      TelegraphTier.category =>
        '${trFor(lang, 'intent_target_prefix')} $targetName ($categoryLabel).',
      TelegraphTier.full => '${trFor(lang, 'intent_target_prefix')} $targetName: '
          '${pending!.move.message} '
          '(${pending.move.damage} ${trFor(lang, 'damage_word')}'
          '${pending.move.element != 'None' ? ', ${pending.move.element}' : ''}).',
    };
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
                    EnemyPixelIcon(enemy.enemyId, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(enemy.displayName,
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trFor(lang, 'hp_label')} ${enemy.currentHealth} / ${enemy.maxHealth}'
                  ' · ${trFor(lang, 'damage_label')} ${enemy.damage}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (enemy.affixes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final affix in enemy.affixes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${trFor(lang, affixLabelKey(affix))}: '
                        '${trFor(lang, affixDescriptionKey(affix))}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
                if (enemy.statusEffects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final effect in enemy.statusEffects)
                        _StatusEffectChip(effect: effect),
                    ],
                  ),
                ],
                if (enemy.phases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    enemy.currentPhase == null
                        ? '${trFor(lang, 'phases_label')}: ${enemy.phases.length} '
                            '· ${trFor(lang, 'phases_hint')}'
                        : '${trFor(lang, 'phase_chip_prefix')} '
                            '${enemy.phaseIndex}/${enemy.phases.length} — '
                            '${enemy.currentPhase!.nameFor(lang)}: '
                            '${enemy.currentPhase!.messageFor(lang)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.deepPurple),
                  ),
                ],
                const SizedBox(height: 10),
                Text(trFor(lang, 'intent_label'),
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(intentText, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Small helpers -------------------------------------------------------

  static const List<Color> _allyAccents = [
    Colors.teal,
    Colors.deepPurple,
    Colors.orange,
    Colors.pink,
    Colors.brown,
  ];

  /// The color that stands for [member] everywhere on the battle screen:
  /// their die tile, their card, their target dot on an enemy.
  Color _accentFor(_PartyMember member) {
    // The player's own colour, clear of the gold that marks an elite foe
    // and a victory.
    if (member.isPlayer) return Theme.of(context).colorScheme.secondary;
    final index = _party.indexWhere((m) => m.id == member.id) - 1;
    return _allyAccents[max(0, index) % _allyAccents.length];
  }
}
