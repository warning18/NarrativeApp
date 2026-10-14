part of '../fight_screen.dart';

/// Quick resolve and the loadout swap (v1.213, see quick_resolve.dart and
/// loadout.dart): the two things offered on the setup screen besides
/// entering the battle.
extension _FightQuick on _FightScreenState {
  // --- Quick resolve -------------------------------------------------------

  /// Whether this fight may be quick-resolved: an ordinary fight against
  /// enemies the party has beaten many times, with the player in shape.
  bool _quickOffered(PlayerSession session) {
    final modifiers = widget.modifiers;
    final eligible = !modifiers.tutorial &&
        !modifiers.isTest &&
        !modifiers.isZoneBoss &&
        !modifiers.isHunt &&
        !modifiers.isHunterAmbush &&
        !modifiers.lossContinues &&
        !modifiers.luckyDieReveal &&
        !modifiers.hostFight &&
        !_isElite &&
        !_enemies.any((e) => isBossEnemy(e.enemyId, e.data));
    final player = _party.isEmpty ? null : _party.first;
    final share = player == null || player.maxHealth <= 0
        ? 0.0
        : player.currentHealth / player.maxHealth;
    return quickResolveOffered(
      enemyIds: [for (final e in _enemies) e.enemyId],
      killCounts: session.enemyKillCounts,
      eligible: eligible,
      healthShare: share,
    );
  }

  /// Plays the fight for the player: a roll and a confirm a round, until
  /// the fight ends, the player taps Stop, or the party is hurt.
  Future<void> _quickResolve(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) async {
    if (_quick || _over) return;
    final lang = ref.read(appLanguageProvider);
    _update(() => _quick = true);
    if (!_started) _startFight(skills, items);
    var safety = 0;
    while (mounted && _quick && !_over && safety++ < 400) {
      final player = _party.first;
      final share =
          player.maxHealth <= 0 ? 0.0 : player.currentHealth / player.maxHealth;
      if (quickResolveShouldStop(
          playerHealthShare: share,
          anyAllyDown: _party.any((m) => !m.isPlayer && m.isKnockedOut))) {
        _update(() => _log.add(
            _LogEntry(trFor(lang, 'quick_resolve_paused'), _LogKind.info)));
        break;
      }
      if (_rolling) {
        await Future.delayed(const Duration(milliseconds: 40));
      } else if (_awaitingDecision) {
        await _confirmRoll(skills, items);
      } else if (_rollCount == 0) {
        await _rollDice(dice, skills, items);
      } else {
        await Future.delayed(const Duration(milliseconds: 40));
      }
    }
    if (mounted) _update(() => _quick = false);
  }

  /// The quick resolve's bar: a note and the way out.
  Widget _buildQuickBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('quick_resolve_bar'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(child: Text(tr(ref, 'quick_resolve_running'))),
          OutlinedButton.icon(
            key: const Key('quick_resolve_stop'),
            onPressed: () => _update(() => _quick = false),
            icon: const Icon(Icons.pan_tool_alt_outlined, size: 18),
            label: Text(tr(ref, 'quick_resolve_stop')),
          ),
        ],
      ),
    );
  }

  // --- Loadout -------------------------------------------------------------

  /// Swaps the die the player rolls in this fight (only): the faces, the
  /// skills set on them and the signature skills the die lends follow.
  void _swapPlayerDie(
    String dieId,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    PlayerSession session,
  ) {
    final player = _party.first;
    final faces = ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    if (faces.isEmpty) return;
    _update(() {
      _selectedDiceId = dieId;
      player.equippedDiceId = dieId;
      player.diceSkillAssignments = limitedFaceAssignments(
          faces, session.diceSkillAssignments[dieId] ?? const {}, skills);
      player.unlockedSkillIds = [
        ...session.unlockedSkillIds,
        ...dieSignatureSkillIds(dice[dieId] as Map<String, dynamic>?),
      ];
      player.dieFaces = smithedFaces(faces, session.upgradesOfDie(dieId));
    });
  }

  /// The elements the party knows its enemies are weak to, all together.
  Set<String> _knownWeaknesses() => {
        for (final enemy in _enemies) ..._knownElementsFor(enemy).weak,
      };

  /// The die chooser on the setup screen: one chip per die owned, starred
  /// when it can hit a known weakness, and a line saying what this die
  /// brings against these enemies.
  Widget _buildLoadoutPicker(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    PlayerSession session,
  ) {
    final lang = ref.watch(appLanguageProvider);
    final weak = _knownWeaknesses();
    Set<String> elementsOf(String dieId) {
      final faces = ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      return dieElements(
          faces,
          limitedFaceAssignments(
              faces, session.diceSkillAssignments[dieId] ?? const {}, skills),
          skills);
    }

    final current = elementsOf(_selectedDiceId ?? '');
    final hit = weaknessesHit(current, weak);
    String names(Iterable<String> elements) =>
        elements.map((e) => elementLabel(e, lang)).join(', ');
    return Column(
      key: const Key('loadout_picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(ref, 'loadout_title'),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final dieId in session.ownedDiceIds)
              if (dice[dieId] != null)
                ChoiceChip(
                  key: Key('loadout_die_$dieId'),
                  label: Text(
                      '${weaknessesHit(elementsOf(dieId), weak).isNotEmpty ? '★ ' : ''}'
                      '${dieDisplayName(dieId, language: lang)}'),
                  selected: _selectedDiceId == dieId,
                  onSelected: _started || _selectedDiceId == dieId
                      ? null
                      : (_) => _swapPlayerDie(dieId, dice, skills, session),
                ),
          ],
        ),
        if (weak.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${tr(ref, 'loadout_known_weak').replaceAll('{e}', names(weak))}. '
            '${hit.isEmpty ? tr(ref, 'loadout_die_misses') : tr(ref, 'loadout_die_hits').replaceAll('{e}', names(hit))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
