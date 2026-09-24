part of '../fight_screen.dart';

/// The log ticker, the bottom bar, the mana meter and the spell buttons.
extension _FightControls on _FightScreenState {
  // --- Log ticker ----------------------------------------------------------

  /// The last two log lines, tappable for the whole log.
  Widget _buildLogTicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final recent = _log.length <= 2 ? _log : _log.sublist(_log.length - 2);
    return GestureDetector(
      onTap: _showFullLog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in recent)
                    Row(
                      children: [
                        Icon(_logIcon(entry.kind),
                            size: 12, color: _logColor(context, entry.kind)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: _logColor(context, entry.kind),
                              fontWeight: entry.kind == _LogKind.info
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (recent.isEmpty)
                    Text(tr(ref, 'battle_log_title'),
                        style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.unfold_more, size: 16, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullLog() {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: Column(
            children: [
              Text(trFor(lang, 'battle_log_title'),
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _log.length,
                  itemBuilder: (context, index) {
                    final entry = _log[_log.length - 1 - index];
                    final color = _logColor(context, entry.kind);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_logIcon(entry.kind), size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.text,
                              style: TextStyle(
                                color: color,
                                fontWeight: entry.kind == _LogKind.info
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Bottom bar ----------------------------------------------------------

  /// Mana and spells on the first line; potion/antidote, reroll and confirm
  /// (or roll) on the second -- everything the player can press, in one
  /// place, like the action bar under a Slice & Dice fight.
  Widget _buildBottomBar(
    List<_PartyMember> acting,
    bool anyDieAvailable,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_over) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: _buildReturnButton(),
      );
    }
    final rollsLeft = _maxRollsThisFight - _rollCount;
    final allLocked = acting.isNotEmpty &&
        acting.every((a) => _lockedActorIds.contains(a.id));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildManaRow(session, skills, items),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildConsumableButton(
                icon: Icons.local_drink,
                count: session.potionCount,
                tooltip: tr(ref, 'potion_button_prefix'),
                enabled: session.potionCount > 0 && !_rolling,
                onTap: _usePotion,
              ),
              if (_party.first.statusEffects.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildConsumableButton(
                  icon: Icons.healing,
                  count: session.antidoteCount,
                  tooltip: tr(ref, 'antidote_button_prefix'),
                  enabled: session.antidoteCount > 0 && !_rolling,
                  onTap: _useAntidote,
                ),
              ],
              const SizedBox(width: 8),
              if (_awaitingDecision) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_rolling || rollsLeft <= 0 || allLocked)
                        ? null
                        : () => _rollDice(dice, skills, items),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('${tr(ref, 'reroll_button')} ($rollsLeft)'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_rolling || !_allTargetsPicked)
                        ? null
                        : () => _confirmRoll(skills, items),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(tr(ref, 'confirm_roll_button')),
                  ),
                ),
              ] else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!anyDieAvailable || _rolling)
                        ? null
                        : () => _rollDice(dice, skills, items),
                    icon: const Icon(Icons.casino, size: 18),
                    label: Text(
                      acting.length > 1
                          ? '${tr(ref, 'roll_dice_button')} (${acting.length}×)'
                          : tr(ref, 'roll_dice_button'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// A square icon button with a count badge -- potions and antidotes.
  Widget _buildConsumableButton({
    required IconData icon,
    required int count,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$tooltip ($count)',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
              color: colorScheme.surface,
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 20, color: Colors.green)),
                Positioned(
                  right: 2,
                  bottom: 1,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The mana meter and one button per known spell, scrolling sideways.
  Widget _buildManaRow(
    PlayerSession session,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final known = <SpellSpec>[
      for (final id in session.knownSpellIds)
        if (_spells[id] != null) _spells[id]!,
    ];
    return Row(
      children: [
        _buildManaMeter(),
        const SizedBox(width: 8),
        Expanded(
          child: known.isEmpty
              ? Text(
                  tr(ref, 'no_spells_hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final spell in known)
                        _buildSpellButton(spell, skills, items),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildManaMeter() {
    final showPips = _maxMana <= 10;
    return Tooltip(
      message: '${tr(ref, 'mana_label')} $_mana / $_maxMana',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(manaIcon, size: 16, color: manaColor),
          const SizedBox(width: 2),
          Text(
            '$_mana/$_maxMana',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: manaColor),
          ),
          if (showPips) ...[
            const SizedBox(width: 4),
            for (var i = 0; i < _maxMana; i++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      i < _mana ? manaColor : manaColor.withValues(alpha: 0.2),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpellButton(
    SpellSpec spell,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final lang = ref.watch(appLanguageProvider);
    final enabled = _mana >= spell.manaCost && !_rolling && !_over;
    final color = spellEffectColor(spell.effect);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: '${spell.nameFor(lang)} · ${spell.manaCost} '
            '${tr(ref, 'mana_label')}\n${spell.descriptionFor(lang)}',
        child: InkWell(
          onTap: enabled ? () => _castSpell(spell, skills, items) : null,
          onLongPress: () => _showSpellSheet(spell, items),
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(spellEffectIcon(spell.effect), size: 15, color: color),
                  const SizedBox(width: 4),
                  Text(
                    spell.nameFor(lang),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  const SizedBox(width: 5),
                  for (var i = 0; i < spell.manaCost; i++)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 1.5),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: manaColor),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A spell's full description, numbers as they'd land right now.
  Future<void> _showSpellSheet(SpellSpec spell, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final amount = _spellAmountNow(spell, items);
    final status = spellStatusFor(spell, level: _playerLevel);
    final color = spellEffectColor(spell.effect);
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
                    Icon(spellEffectIcon(spell.effect), color: color, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(spell.nameFor(lang),
                          style: theme.textTheme.titleMedium),
                    ),
                    const Icon(manaIcon, size: 16, color: manaColor),
                    const SizedBox(width: 2),
                    Text('${spell.manaCost}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: manaColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(spell.descriptionFor(lang),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  '${trFor(lang, spellEffectLabelKey(spell.effect))}'
                  '${amount > 0 ? ' $amount' : ''}'
                  ' · ${trFor(lang, spellTargetLabelKey(spell.target))}'
                  '${spell.element != 'None' ? ' · ${spell.element}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (status != null)
                  Text(
                    '${_statusInflictedMessage(status, trFor(lang, 'the_enemy_label'), lang)}'
                    '${status.type == StatusEffectType.poison ? ' (${status.magnitude} x ${status.remainingTurns})' : ' (${status.remainingTurns})'}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
