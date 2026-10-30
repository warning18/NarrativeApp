part of '../fight_screen.dart';

/// A slot's height, and the gap between two of them: every fighter, ally or
/// foe, has a box of this size (three a side, always), so nothing resizes
/// when the party or the pack is smaller.
const double _slotH = 72;
const double _slotGap = 6;

/// The seats of up to four dice on the board, as shares of its width and
/// height (the centre of each die tile).
const List<Offset> _seats = [
  Offset(0.2, 0.3),
  Offset(0.62, 0.24),
  Offset(0.4, 0.6),
  Offset(0.8, 0.58),
];

const double _dieCube = 60;
const double _tileW = 84;
const double _tileH = 118;

/// The fight's cards as fixed slots, the dice board and the row of kept dice
/// (combat redesign A'/A''): a head and some icons for each fighter, the dice
/// thrown onto a board that looks like the place, a tap on a die to see its
/// target and a second tap to keep it.
extension _FightBoardView on _FightScreenState {
  // --- Slots ---------------------------------------------------------------

  /// How many slots a side shows: three, or more when a side has more
  /// fighters (a fourth seat in the party).
  int get _slotCount => max(3, max(_party.length, _enemies.length));

  double get _slotsHeight => _slotCount * _slotH + (_slotCount - 1) * _slotGap;

  /// The two columns of slots: the party on the left, the foes on the right,
  /// the same size.
  Widget _buildSlots(
      Map<String, dynamic> items, Map<String, _FacePreview> previews) {
    Widget column(int filled, Widget Function(int i) build, String tourId) {
      return TutorialTarget(
        id: tourId,
        child: Column(
          children: [
            for (var i = 0; i < _slotCount; i++) ...[
              SizedBox(
                height: _slotH,
                child: i < filled ? build(i) : _emptySlot(),
              ),
              if (i < _slotCount - 1) const SizedBox(height: _slotGap),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: _slotsHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: column(
              _party.length,
              (i) => KeyedSubtree(
                key: _memberCardKey(_party[i].id),
                child: VfxRecoil(
                  controller: _vfx,
                  anchor: _memberCardKey(_party[i].id),
                  child: _buildPartySlot(_party[i], items),
                ),
              ),
              'fight.party',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: column(
              _enemies.length,
              (i) => KeyedSubtree(
                key: _enemyCardKey(_enemies[i].key),
                child: VfxRecoil(
                  controller: _vfx,
                  anchor: _enemyCardKey(_enemies[i].key),
                  flash: false,
                  child: _buildEnemySlot(_enemies[i], previews),
                ),
              ),
              'fight.enemies',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySlot() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('fight_empty_slot'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    );
  }

  /// A fighter's head: a crop of its sprite (assets/visuals/heads, made by
  /// tool/gen_fight_heads.py), or its initial in [accent] when it has none.
  Widget _headTile(String? asset, String name, Color accent,
      {double size = 36, bool dim = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final fallback = Center(
      child: Container(
        width: size * 0.74,
        height: size * 0.74,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        child: Text(initial,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold)),
      ),
    );
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(3),
        child: asset == null
            ? fallback
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  String? _headAssetFor(_PartyMember member) {
    if (member.isPlayer) return 'assets/visuals/heads/hero.png';
    if (member.id == 'vica') return 'assets/visuals/heads/vica.png';
    return null;
  }

  // --- Effect icons --------------------------------------------------------

  /// One effect icon, whose tap opens its pop-in.
  Widget _effectIcon(
    FightEffect effect,
    String title, {
    String? badge,
    required String body,
    required String who,
    int? turns,
  }) {
    return Builder(
      builder: (iconContext) => FightEffectChip(
        key: Key('fight_effect_${effect.name}_$who'),
        effect: effect,
        label: title,
        badge: badge,
        onTap: () {
          final box = iconContext.findRenderObject();
          if (box is! RenderBox || !box.hasSize) return;
          final rect = box.localToGlobal(Offset.zero) & box.size;
          showFightEffectPopin(
            context,
            anchor: rect,
            effect: effect,
            title: title,
            subtitle: turns == null
                ? who
                : tr(ref, 'effect_popin_sub')
                    .replaceAll('{name}', who)
                    .replaceAll('{turns}', '$turns'),
            body: body,
            closeHint: tr(ref, 'effect_popin_close'),
          );
        },
      ),
    );
  }

  /// The icons of the status effects (poison, stun, weaken) on [effects].
  List<Widget> _statusIcons(List<StatusEffect> effects, String who) => [
        for (final effect in effects)
          switch (effect.type) {
            StatusEffectType.poison => _effectIcon(
                FightEffect.poison, tr(ref, 'status_poison_label'),
                badge: '${effect.remainingTurns}',
                who: who,
                turns: effect.remainingTurns,
                body: tr(ref, 'poison_tip')
                    .replaceAll('{n}', '${effect.magnitude}')
                    .replaceAll('{turns}', '${effect.remainingTurns}')),
            StatusEffectType.stun => _effectIcon(
                FightEffect.stun, tr(ref, 'status_stun_label'),
                badge: '${effect.remainingTurns}',
                who: who,
                turns: effect.remainingTurns,
                body: tr(ref, 'stun_tip')
                    .replaceAll('{turns}', '${effect.remainingTurns}')),
            StatusEffectType.weaken => _effectIcon(
                FightEffect.weaken, tr(ref, 'status_weaken_label'),
                badge: '${effect.remainingTurns}',
                who: who,
                turns: effect.remainingTurns,
                body: tr(ref, 'weaken_tip')
                    .replaceAll('{n}', '${effect.magnitude}')
                    .replaceAll('{turns}', '${effect.remainingTurns}')),
          },
      ];

  /// What acts on a party member, as icons: Fury or Watchfire (the hero's
  /// profession core), block, a blow aimed at them, then poison, stun and
  /// weaken.
  List<Widget> _partyEffectIcons(_PartyMember member) {
    final who = member.displayName;
    return [
      if (member.isPlayer && _core.core == ProfessionCore.fury)
        _effectIcon(FightEffect.fury, tr(ref, 'fury_label'),
            badge: '${_core.fury}', who: who, body: tr(ref, 'fury_tip')),
      if (member.isPlayer && _core.core == ProfessionCore.watchfire)
        _effectIcon(FightEffect.watchfire, tr(ref, 'watchfire_label'),
            badge: '${_core.fire}', who: who, body: tr(ref, 'watchfire_tip')),
      if (member.block > 0)
        _effectIcon(FightEffect.block, tr(ref, 'effect_block_label'),
            badge: '${member.block}',
            who: who,
            body: tr(ref, 'block_tip').replaceAll('{n}', '${member.block}')),
      if (!member.isKnockedOut && _isTelegraphedTarget(member))
        _effectIcon(FightEffect.target, tr(ref, 'effect_target_label'),
            who: who, body: tr(ref, 'effect_target_tip')),
      ..._statusIcons(member.statusEffects, who),
    ];
  }

  // --- A party slot --------------------------------------------------------

  Widget _buildPartySlot(_PartyMember member, Map<String, dynamic> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(member);
    final canSelect = _enemies.length > 1 &&
        _strikerIds().contains(member.id) &&
        _awaitingDecision &&
        !_rolling &&
        (member.isPlayer || !_companionsAutoAim);
    final picked = _dieLocks.selected == member.id && !_isDieLocked(member.id);
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
    final icons = _partyEffectIcons(member);
    final card = GestureDetector(
      key: Key('party_slot_${member.id}'),
      onTap: () => _update(() {
        if (_awaitingDecision &&
            !_rolling &&
            _currentFaces[member.id] != null) {
          _dieLocks.selected = member.id;
        }
        if (canSelect) _selectedActorId = member.id;
      }),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        decoration: BoxDecoration(
          color: member.isKnockedOut
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                picked ? const Color(0xFFF2C14E) : colorScheme.outlineVariant,
            width: picked ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _headTile(_headAssetFor(member), member.displayName, accent,
                    size: 34, dim: member.isKnockedOut),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_orderOf(member) case final order?)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                key: Key('turn_order_${member.id}'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: colorScheme.outline),
                                ),
                                child: Text('$order',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              member.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: accent),
                            ),
                          ),
                          if (member.isPlayer) ...[
                            const Icon(Icons.bolt,
                                size: 11, color: Colors.deepOrange),
                            Text('$damage',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.shield_outlined,
                                size: 11, color: Colors.blueGrey),
                            Text('$armor',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      _buildPartyHp(member, items),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...icons,
                    if (_canParry(member)) _buildParryChip(member),
                    if (member.isKnockedOut)
                      Text(tr(ref, 'knocked_out_label'),
                          style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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

  // --- An enemy slot -------------------------------------------------------

  /// The marks an enemy has that have no icon of their own (elements,
  /// goals, reactions, squad, affixes, phase): they live in its sheet; the
  /// slot shows how many there are.
  int _enemyExtraCount(_EnemyMember enemy) =>
      _elementChips(enemy).length +
      _goalMarks(enemy).length +
      _reactionChips(enemy).length +
      enemy.affixes.length +
      (enemy.currentPhase == null ? 0 : 1);

  Widget _buildEnemySlot(
      _EnemyMember enemy, Map<String, _FacePreview> previews) {
    final colorScheme = Theme.of(context).colorScheme;
    var pending = 0;
    for (final preview in previews.values) {
      if (preview.target?.key == enemy.key) pending += preview.damage;
    }
    final boss = isBossEnemy(enemy.enemyId, enemy.data);
    final pickedId = _dieLocks.selected;
    final pickedActor = pickedId == null || _isDieLocked(pickedId)
        ? null
        : _memberById(pickedId);
    final canRetarget = pickedActor != null &&
        _enemies.length > 1 &&
        _awaitingDecision &&
        !_rolling &&
        enemy.isAlive &&
        _strikerIds().contains(pickedActor.id) &&
        (pickedActor.isPlayer || !_companionsAutoAim) &&
        _selectedTargets.containsKey(pickedActor.id);
    final aimedByPicked =
        canRetarget && _selectedTargets[pickedActor.id] == enemy.key;
    final borderColor = aimedByPicked
        ? const Color(0xFFF2C14E)
        : boss || (_isElite && enemy.isAlive)
            ? Colors.amber.shade700
            : const Color(0xFFFF9A2E).withValues(alpha: 0.75);
    final who = enemy.displayName;
    final extras = _enemyExtraCount(enemy);
    final icons = <Widget>[
      // Its role in a squad (healer, guard, striker) and what it is set on
      // stay readable: they decide who to hit first.
      for (final mark in _squadMarks(enemy))
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 3),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: FittedBox(fit: BoxFit.scaleDown, child: mark),
          ),
        ),
      ..._statusIcons(enemy.statusEffects, who),
      if (enemy.isAlive && enemy.guard > 0)
        _effectIcon(FightEffect.guard, tr(ref, 'effect_guard_label'),
            badge: '${enemy.guard}',
            who: who,
            body: tr(ref, 'enemy_guard_tooltip')),
      if (enemy.isAlive && enemy.chargedBlow != null)
        _effectIcon(FightEffect.windUp, tr(ref, 'effect_windup_label'),
            who: who, body: tr(ref, 'winding_up_tooltip')),
      if (enemy.isAlive && enemy.staggered)
        _effectIcon(FightEffect.staggered, tr(ref, 'staggered_label'),
            who: who, body: tr(ref, 'intent_staggered_label')),
      if (enemy.isAlive &&
          !enemy.yielded &&
          !_enemies.any((e) => isBossEnemy(e.enemyId, e.data)) &&
          wavers(health: enemy.currentHealth, maxHealth: enemy.maxHealth))
        _effectIcon(FightEffect.flee, tr(ref, 'effect_flee_label'),
            who: who, body: tr(ref, 'wavering_tip')),
      if (enemy.isAlive && enemy.rallyStacks > 0)
        _effectIcon(FightEffect.rally, tr(ref, 'rallied_label'),
            badge: '${enemy.rallyStacks}',
            who: who,
            body: tr(ref, 'rallied_label')),
      if (extras > 0)
        Builder(
          builder: (_) => FightEffectChip(
            key: Key('fight_effect_more_${enemy.key}'),
            effect: FightEffect.info,
            label: tr(ref, 'effect_more_label'),
            badge: '$extras',
            onTap: () => _showEnemySheet(enemy),
          ),
        ),
    ];
    final card = GestureDetector(
      key: Key('enemy_slot_${enemy.key}'),
      onTap: !enemy.isAlive
          ? null
          : canRetarget
              ? () => _update(() {
                    _selectedTargets[pickedActor.id] = enemy.key;
                    _selectedActorId = pickedActor.id;
                    _autoAssignTargets();
                  })
              : () => _showEnemySheet(enemy),
      onLongPress: () => _showEnemySheet(enemy),
      child: AnimatedOpacity(
        duration: Duration.zero,
        opacity: enemy.isAlive ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: borderColor, width: aimedByPicked ? 2.5 : 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headTile('assets/visuals/heads/${enemy.enemyId}.png',
                      enemy.displayName, Colors.deepOrange,
                      size: 34, dim: !enemy.isAlive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enemy.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: boss || _isElite
                                      ? Colors.amber.shade800
                                      : const Color(0xFFFF9A2E)),
                        ),
                        const SizedBox(height: 3),
                        Tooltip(
                          message: boss ? '' : tr(ref, 'execute_tick_tip'),
                          child: _buildHpBar(
                              enemy.currentHealth, enemy.maxHealth,
                              pending: enemy.isAlive ? pending : 0,
                              executeLine: enemy.isAlive && !boss),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: icons,
                        ),
                      ),
                    ),
                    if (enemy.isAlive)
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 92),
                          child: _buildIntentBox(enemy, compact: true),
                        ),
                      ),
                  ],
                ),
              ),
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

  // --- The dice board ------------------------------------------------------

  /// Where die number [index] of [count] comes to rest this roll: its seat,
  /// shifted a little by the roll, so no two rolls land alike.
  Offset _seatFor(int index, int count, Size board) {
    final seats = count <= 1
        ? const [Offset(0.5, 0.42)]
        : count == 2
            ? const [Offset(0.28, 0.4), Offset(0.72, 0.48)]
            : _seats;
    final rng = Random(_rollCount * 131 + _roundsStarted * 17 + index * 7);
    final base = seats[index % seats.length];
    return Offset(
      (base.dx + (rng.nextDouble() - 0.5) * 0.08) * board.width,
      (base.dy + (rng.nextDouble() - 0.5) * 0.1) * board.height,
    );
  }

  Widget _buildDiceBoard(
    List<_PartyMember> acting,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    _RoundPlan plan,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canLock = _awaitingDecision && !_rolling && _rollCount < _rollCap;
    final disable = MediaQuery.of(context).disableAnimations;
    final onBoard = [
      for (final a in acting)
        if (!_lockedActorIds.contains(a.id)) a,
    ];
    final hintKey = acting.isEmpty
        ? 'nobody_can_act_label'
        : _currentFaces.isEmpty
            ? 'roll_hint'
            : _dieLocks.selected != null && canLock
                ? 'dice_picked_hint'
                : canLock
                    ? 'dice_pick_hint'
                    : 'confirm_hint';
    return Column(
      children: [
        Expanded(
          child: FightBoardSurface(
            stage: _stage,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                return AnimatedBuilder(
                  animation: _rollController,
                  builder: (context, _) {
                    final t = _rolling && !disable
                        ? Curves.easeOutCubic.transform(_rollController.value)
                        : 1.0;
                    final arc = sin(pi * t) * 46;
                    final launch = Offset(size.width / 2, size.height + 40);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // A tap on the bare board puts the pick down.
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _dieLocks.selected == null
                                ? null
                                : () =>
                                    _update(() => _dieLocks.selected = null),
                          ),
                        ),
                        for (final actor in onBoard)
                          () {
                            final i = acting.indexOf(actor);
                            final seat = _seatFor(i, acting.length, size);
                            final pos =
                                Offset.lerp(launch, seat, t)! - Offset(0, arc);
                            return Positioned(
                              left: pos.dx - _tileW / 2,
                              top: pos.dy - _tileH / 2,
                              width: _tileW,
                              height: _tileH,
                              child: _buildDieTile(actor, dice, skills, items,
                                  canLock, plan.previews[actor.id],
                                  cube: _dieCube),
                            );
                          }(),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 6,
                          child: IgnorePointer(
                            child: Text(
                              tr(ref, hintKey),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      shadows: const [
                                    Shadow(blurRadius: 4, color: Colors.black)
                                  ]),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (_momentum >= _momentumNeeded && !_rolling)
          _buildSurgePicker(acting),
        if (plan.combos.isNotEmpty || plan.duos.isNotEmpty)
          _buildComboChips(plan),
        const SizedBox(height: 6),
        _buildKeptRow(acting, canLock, colorScheme),
      ],
    );
  }

  // --- The kept row --------------------------------------------------------

  Widget _buildKeptRow(
      List<_PartyMember> acting, bool canLock, ColorScheme colorScheme) {
    final kept = [
      for (final a in acting)
        if (_lockedActorIds.contains(a.id)) a,
    ];
    return Container(
      key: const Key('fight_kept_row'),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: kept.isEmpty
            ? null
            : const Color(0xFF6FBF73).withValues(alpha: 0.1),
        border: Border.all(
          color: kept.isEmpty
              ? colorScheme.outlineVariant
              : const Color(0xFF6FBF73).withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${tr(ref, 'dice_kept_label')}\n${kept.length}/${acting.length}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.2),
          ),
          const SizedBox(width: 10),
          if (kept.isEmpty)
            Expanded(
              child: Text(tr(ref, 'dice_kept_none'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            )
          else
            for (final actor in kept) _keptDie(actor),
          if (kept.isNotEmpty) const Spacer(),
          if (kept.any((a) => _canReleaseDie(a.id)))
            Flexible(
              child: Text(tr(ref, 'dice_kept_return_hint'),
                  textAlign: TextAlign.end,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant, fontSize: 9)),
            ),
        ],
      ),
    );
  }

  /// One kept die, small: the face it holds; a double tap puts it back while
  /// it can still be (see [_canRelease]); a padlock once the keep is final.
  Widget _keptDie(_PartyMember actor) {
    final face = _currentFaces[actor.id];
    final accent = _accentFor(actor);
    final final_ = !_canReleaseDie(actor.id);
    final kind = face == null ? null : _faceKindOf(face);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        key: ValueKey('kept_die_${actor.id}'),
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _canReleaseDie(actor.id)
            ? () => _update(() => _releaseDie(actor.id))
            : null,
        onTap: final_
            ? () => showImmersiveNotice(context,
                icon: Icons.lock_outline, message: tr(ref, 'dice_sealed_tip'))
            : null,
        onLongPress: face == null
            ? null
            : () => _showFaceSheet(
                actor,
                face,
                ref.read(localizedDbProvider(diceSchema)).value ?? const {},
                ref.read(localizedDbProvider(skillsSchema)).value ?? const {},
                ref.read(localizedDbProvider(itemsSchema)).value ?? const {}),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: (kind?.color ?? accent).withValues(alpha: 0.18),
                border: Border.all(color: accent, width: 1.6),
              ),
              child: Center(
                  child: face == null
                      ? const SizedBox.shrink()
                      : _buildFaceGlyph(face, size: 22)),
            ),
            if (final_)
              const Positioned(
                right: -4,
                top: -6,
                child: Icon(Icons.lock, size: 13, color: Color(0xFFC9A070)),
              ),
          ],
        ),
      ),
    );
  }

  // --- Picking a die, and the line to its target ---------------------------

  /// The first tap on a landed die picks it (its line to the target shows);
  /// the second keeps it (the lock rules are Core's, die_locks.dart).
  void _onDieTap(
      _PartyMember actor,
      DiceFaceResult face,
      bool canLock,
      Map<String, dynamic> dice,
      Map<String, dynamic> skills,
      Map<String, dynamic> items) {
    if (!canLock || _steadyActorIds.contains(actor.id)) {
      _showFaceSheet(actor, face, dice, skills, items);
      return;
    }
    _update(() => _tapDie(actor.id));
  }

  /// The aim line of the picked die: to the enemy it strikes, or (a heal, a
  /// defence) to its own card. Nothing while the dice fly or no die is picked.
  Widget _buildAimLine(_RoundPlan plan) {
    final id = _dieLocks.selected;
    if (id == null || _rolling || !_awaitingDecision || _over) {
      return const SizedBox.shrink();
    }
    final actor = _memberById(id);
    final face = _currentFaces[id];
    if (actor == null || face == null || _lockedActorIds.contains(id)) {
      return const SizedBox.shrink();
    }
    final preview = plan.previews[id];
    final isStrike = _strikerIds().contains(id);
    final target = isStrike ? _strikeTargetFor(actor) : null;
    final GlobalKey to;
    final Color color;
    String label;
    if (target != null) {
      to = _enemyCardKey(target.key);
      color = const Color(0xFFE0752B);
      label = '−${preview?.damage ?? 0}';
    } else {
      to = _memberCardKey(id);
      final healing = preview?.healing ?? 0;
      final block = preview?.block ?? 0;
      color = healing > 0 ? const Color(0xFFD9457A) : const Color(0xFF4C8FC7);
      label = healing > 0
          ? '+$healing'
          : block > 0
              ? '⛨$block'
              : '';
    }
    return FightAimLine(
      from: _dieKey(id),
      to: to,
      space: _battleSpaceKey,
      color: color,
      label: label,
    );
  }

  GlobalKey _dieKey(String id) =>
      _cardKeys.putIfAbsent('die:$id', GlobalKey.new);
}
