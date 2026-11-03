part of '../fight_screen.dart';

/// The party's and the enemies' cards, and the enemy sheet.
extension _FightCards on _FightScreenState {
  // --- Party column --------------------------------------------------------

  /// A small labelled state chip on an enemy card: winding up, staggered,
  /// rallied.
  Widget _stateChip(IconData icon, String label, Color color,
      {String? tooltip}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }

  /// The elements [enemy] is known to be weak to (green, ×2) and to
  /// resist (grey, ×½) -- see [_knownElementsFor].
  List<Widget> _elementChips(_EnemyMember enemy) {
    if (!enemy.isAlive) return const [];
    final lang = ref.watch(appLanguageProvider);
    final known = _knownElementsFor(enemy);
    return [
      for (final element in known.weak)
        Tooltip(
          message:
              '${trFor(lang, 'weak_to_label')} ${elementLabel(element, lang)}',
          child: _miniStat(elementIcon(element),
              '×${weaknessMultiplier.round()}', Colors.green.shade700),
        ),
      for (final element in known.resist)
        Tooltip(
          message:
              '${trFor(lang, 'resists_label')} ${elementLabel(element, lang)}',
          child: _miniStat(elementIcon(element), '×½', Colors.blueGrey),
        ),
    ];
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

  /// What the blows aimed at [member] this round would take off, after
  /// armor, resist and block, from the enemies the party reads in full (see
  /// [telegraphTierFor]); each blow is figured on its own, as on its
  /// enemy's intent box. Zero when none is read or none is aimed here.
  int _incomingOn(_PartyMember member, Map<String, dynamic> items) {
    if (member.isKnockedOut) return 0;
    final skills =
        ref.read(localizedDbProvider(skillsSchema)).value ?? const {};
    var sum = 0;
    for (final enemy in _enemies) {
      final pending = enemy.pendingMove;
      if (!enemy.isAlive ||
          enemy.staggered ||
          pending == null ||
          pending.targetId != member.id ||
          _effectiveTierFor(enemy) != TelegraphTier.full) {
        continue;
      }
      sum += _expectedHit(enemy, skills, items)?.net ?? 0;
    }
    return sum;
  }

  /// A member's health bar; the blow the party can read is drawn on it as
  /// the part it would take off, with "−N" at its end and the sentence on a
  /// long press.
  Widget _buildPartyHp(_PartyMember member, Map<String, dynamic> items) {
    final incoming = _incomingOn(member, items);
    final bar =
        _buildHpBar(member.currentHealth, member.maxHealth, pending: incoming);
    if (incoming <= 0) return bar;
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tr(ref, 'incoming_tip')
          .replaceAll('{name}', member.displayName)
          .replaceAll('{n}', '$incoming'),
      child: Row(
        key: Key('incoming_${member.id}'),
        children: [
          Expanded(child: bar),
          const SizedBox(width: 4),
          Text('−$incoming',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error)),
        ],
      ),
    );
  }

  /// A thin health bar with its numbers inside -- shared by both columns.
  /// With [pending] damage on the way (the dice aimed at an enemy, see
  /// [_previewRoll]) the slice about to go is painted [_previewColor] and
  /// the numbers read "now → after / max".
  Widget _buildHpBar(int current, int maxValue,
      {double height = 14, int pending = 0, bool executeLine = false}) {
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
                  // Where a struck foe falls (fight_length.dart's execute).
                  if (executeLine)
                    Positioned(
                      key: const Key('execute_tick'),
                      left: constraints.maxWidth * executeShare - 0.75,
                      width: 1.5,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.85)),
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

  /// The enemy's intent for its next turn, at whatever detail the party's
  /// Perception reads it (see [telegraphTierFor]): a "?" box when nothing
  /// can be read, the target's name from the first tier, a move-category
  /// icon from the second, and the damage number, element and the move's
  /// own words at the full tier.
  Widget _buildIntentBox(_EnemyMember enemy, {bool compact = false}) {
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
    if (enemy.staggered) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_problem,
              size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(tr(ref, 'intent_staggered_label'),
                style: textStyle, maxLines: 2),
          ),
        ],
      );
    } else if (pending != null &&
        pending.release &&
        tier == TelegraphTier.none) {
      // A wind-up is plain to see, whatever the party can read of the rest.
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber,
              size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(tr(ref, 'intent_charged_label'),
                style: textStyle, maxLines: 2),
          ),
        ],
      );
    } else if (pending == null || tier == TelegraphTier.none) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline,
              size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(tr(ref, 'intent_unknown_label'),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
          ),
        ],
      );
    } else {
      final targetName = _memberById(pending.targetId)?.displayName ?? '?';
      final showCategory =
          tier == TelegraphTier.category || tier == TelegraphTier.full;
      final categoryIcon = pending.release
          ? Icons.warning_amber
          : switch (categoryFor(pending.move)) {
              MoveCategory.attack => Icons.bolt,
              MoveCategory.healSelf => Icons.healing,
              MoveCategory.statusDebuff => Icons.sick,
              MoveCategory.guard => Icons.shield_outlined,
              MoveCategory.charge => Icons.hourglass_top,
              MoveCategory.rally => Icons.campaign,
              MoveCategory.tamper => Icons.auto_fix_off,
              MoveCategory.mirror => Icons.flip,
            };
      // A heal, guard, wind-up or rally doesn't swing at anyone this turn;
      // a Hex or a Silence falls on the whole party's dice, a Curse on the
      // target's.
      final swings =
          pending.release || pending.move.intent == EnemyIntent.attack;
      final hitsParty = swings || pending.move.tamper == DiceTamper.curse;
      final tamper = pending.move.tamper;
      final stanceLabel = switch (categoryFor(pending.move)) {
        MoveCategory.healSelf => tr(ref, 'telegraph_category_heal'),
        MoveCategory.guard => tr(ref, 'telegraph_category_guard'),
        MoveCategory.charge => tr(ref, 'telegraph_category_charge'),
        MoveCategory.rally => tr(ref, 'telegraph_category_rally'),
        MoveCategory.tamper => tier == TelegraphTier.full && tamper != null
            ? tr(ref, tamperLabelKey(tamper))
            : tr(ref, 'telegraph_category_tamper'),
        _ => enemy.displayName,
      };
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(showCategory ? categoryIcon : Icons.visibility,
                  size: 12, color: colorScheme.onErrorContainer),
              if (swings && tier == TelegraphTier.full && hit != null) ...[
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
                child: Text(
                    hitsParty
                        ? targetName
                        : showCategory
                            ? stanceLabel
                            : enemy.displayName,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (swings &&
                  tier == TelegraphTier.full &&
                  pending.move.element != 'None')
                Icon(elementIcon(pending.move.element),
                    size: 12, color: colorScheme.onErrorContainer),
            ],
          ),
          if (tier == TelegraphTier.full && !compact)
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
    // Open Eyes: the move after, at the category the party reads.
    final then = enemy.nextMove;
    if (!compact &&
        then != null &&
        !enemy.staggered &&
        (tier == TelegraphTier.category || tier == TelegraphTier.full)) {
      final label = switch (categoryFor(then.move)) {
        MoveCategory.attack => 'telegraph_category_attack',
        MoveCategory.healSelf => 'telegraph_category_heal',
        MoveCategory.statusDebuff => 'telegraph_category_debuff',
        MoveCategory.guard => 'telegraph_category_guard',
        MoveCategory.charge => 'telegraph_category_charge',
        MoveCategory.rally => 'telegraph_category_rally',
        MoveCategory.tamper => 'telegraph_category_tamper',
        MoveCategory.mirror => 'tamper_mirror',
      };
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Row(
            key: Key('intent_then_${enemy.key}'),
            children: [
              Icon(Icons.double_arrow,
                  size: 11, color: colorScheme.onErrorContainer),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${tr(ref, 'intent_then_label')} ${tr(ref, label)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: content,
    );
  }

  Widget _telegraphChip(IconData icon, String label,
      {String? tip,
      String? badge,
      Color? color,
      String subtitle = '',
      Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    return FightStatusTile(
      key: key,
      icon: icon,
      color: color ?? scheme.tertiary,
      label: label,
      badge: badge,
      subtitle: subtitle,
      body: tip ?? label,
      closeHint: tr(ref, 'effect_popin_close'),
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
              MoveCategory.guard => 'telegraph_category_guard',
              MoveCategory.charge => 'telegraph_category_charge',
              MoveCategory.rally => 'telegraph_category_rally',
              MoveCategory.tamper => pending.move.tamper != null
                  ? tamperLabelKey(pending.move.tamper!)
                  : 'telegraph_category_tamper',
              MoveCategory.mirror => 'tamper_mirror',
            });
    final intentText = switch (tier) {
      TelegraphTier.none => trFor(lang, 'intent_unknown_desc'),
      TelegraphTier.target =>
        '${trFor(lang, 'intent_target_prefix')} $targetName.',
      TelegraphTier.category =>
        '${trFor(lang, 'intent_target_prefix')} $targetName ($categoryLabel).',
      TelegraphTier.full => pending!.move.tamper != null
          ? '$categoryLabel: ${pending.move.message} '
              '(${trFor(lang, tamperDescriptionKey(pending.move.tamper!))})'
          : pending.release || pending.move.intent == EnemyIntent.attack
              ? '${trFor(lang, 'intent_target_prefix')} $targetName: '
                  '${pending.move.message} '
                  '(${pending.move.damage} ${trFor(lang, 'damage_word')}'
                  '${pending.move.element != 'None' ? ', ${elementLabel(pending.move.element, lang)}' : ''}).'
              : '$categoryLabel: ${pending.move.message}',
    };
    final stateLines = <String>[
      if (enemy.staggered) trFor(lang, 'intent_staggered_label'),
      if (pending?.release ?? false) trFor(lang, 'winding_up_tooltip'),
      if (enemy.guard > 0)
        '${trFor(lang, 'enemy_guard_tooltip')} (${enemy.guard})',
      if (enemy.rallyStacks > 0)
        '${trFor(lang, 'rallied_label')} ×${enemy.rallyStacks}',
    ];
    final known = _knownElementsFor(enemy);
    final elementLine = [
      if (known.weak.isNotEmpty)
        '${trFor(lang, 'weak_to_label')} '
            '${known.weak.map((e) => elementLabel(e, lang)).join(', ')} '
            '(×${weaknessMultiplier.round()})',
      if (known.resist.isNotEmpty)
        '${trFor(lang, 'resists_label')} '
            '${known.resist.map((e) => elementLabel(e, lang)).join(', ')} (×½)',
    ].join(' · ');
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
                if (elementLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(elementLine, style: theme.textTheme.bodySmall),
                ],
                for (final line in stateLines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line, style: theme.textTheme.bodySmall),
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
