part of '../fight_screen.dart';

/// Parries and element reactions (v1.214, see parry.dart and
/// element_reaction.dart): the two ways the party's dice answer what is in
/// front of them, beyond plain damage and plain block.
extension _FightClash on _FightScreenState {
  // --- Parry ---------------------------------------------------------------

  /// True when [enemy] has an attack waiting that a parry could meet.
  bool _canParryEnemy(_EnemyMember enemy) {
    if (!enemy.isAlive) return false;
    final pending = enemy.pendingMove;
    if (pending == null) return false;
    return pending.release || pending.move.intent == EnemyIntent.attack;
  }

  /// True when [member] plays a Defend face and some enemy's attack could
  /// be parried with it.
  bool _canParry(_PartyMember member) =>
      _awaitingDecision &&
      !_rolling &&
      !_over &&
      _playedFaces()[member.id]?.type == 'Defend' &&
      _enemies.any(_canParryEnemy);

  /// Steps [member]'s parry to the next enemy with an attack waiting, and
  /// off again after the last.
  void _cycleParry(_PartyMember member) {
    final candidates = _enemies.where(_canParryEnemy).toList();
    final current = _parryTargets[member.id];
    final index =
        current == null ? -1 : candidates.indexWhere((e) => e.key == current);
    _update(() {
      if (index + 1 >= candidates.length) {
        _parryTargets.remove(member.id);
      } else {
        _parryTargets[member.id] = candidates[index + 1].key;
      }
    });
  }

  /// The chip on a defender's card that sets the parry.
  Widget _buildParryChip(_PartyMember member) {
    final key = _parryTargets[member.id];
    final enemy = key == null ? null : _enemyByKey(key);
    return Tooltip(
      message: tr(ref, 'parry_tip'),
      child: ActionChip(
        key: Key('parry_${member.id}'),
        visualDensity: VisualDensity.compact,
        avatar: const Icon(Icons.shield_moon_outlined, size: 14),
        label: Text(
          enemy == null
              ? tr(ref, 'parry_off')
              : tr(ref, 'parry_on').replaceAll('{name}', enemy.displayName),
          style: const TextStyle(fontSize: 11),
        ),
        onPressed: () => _cycleParry(member),
      ),
    );
  }

  /// A parry [enemy]'s blow met, after the blow was worked out: said in
  /// the log, and answered when it stopped the blow outright.
  void _resolveParry(_EnemyMember enemy, int blow, int parry, bool dodged,
      AppLanguage lang, Map<String, dynamic> skills) {
    if (parry <= 0 || dodged) return;
    if (parryStopsBlow(blow, parry)) {
      final counter = parryCounter(parry);
      _fx(VfxStyle.impact, _enemyCardKey(enemy.key),
          text: '-$counter', textKind: VfxTextKind.damage);
      _update(() {
        enemy.currentHealth = max(0, enemy.currentHealth - counter);
        _lastDamagedEnemyKey = enemy.key;
        _lastEnemyDamageTaken = counter;
        _log.add(_LogEntry(
            trFor(lang, 'parry_stopped_log')
                .replaceAll('{enemy}', enemy.displayName)
                .replaceAll('{n}', '$counter'),
            _LogKind.playerBlock));
      });
      if (enemy.isAlive) _advancePhasesNow(lang, skills);
    } else {
      final soaked = min(blow, parry);
      _update(() => _log.add(_LogEntry(
          trFor(lang, 'parry_soaks_log')
              .replaceAll('{enemy}', enemy.displayName)
              .replaceAll('{n}', '$soaked'),
          _LogKind.playerBlock)));
    }
  }

  // --- Element reactions ---------------------------------------------------

  /// An element hit of [landed] on [target]: it springs a reaction when a
  /// partner element primed the enemy in time, and otherwise primes it.
  void _reactOnHit(_EnemyMember target, String element, int landed,
      List<_LogEntry> entries, AppLanguage lang) {
    if (element == 'None' || landed <= 0 || !target.isAlive) return;
    final sprung = reactionOn(target.elementMarks, element, _roundsStarted);
    if (sprung == null) {
      target.elementMarks[element] = _roundsStarted;
      return;
    }
    target.elementMarks.remove(sprung.primer);
    final reaction = sprung.reaction;
    final name = trFor(lang, reactionLabelKey(reaction));
    final bonus = reactionBonus(reaction, landed);
    if (bonus > 0) {
      target.currentHealth = max(0, target.currentHealth - bonus);
      _bestHitThisRound = max(_bestHitThisRound, landed + bonus);
      _lastDamagedEnemyKey = target.key;
      _lastEnemyDamageTaken = bonus;
    }
    _fx(VfxStyle.impact, _enemyCardKey(target.key),
        text: bonus > 0 ? '$name -$bonus' : name, textKind: VfxTextKind.damage);
    entries.add(_LogEntry(
        bonus > 0
            ? trFor(lang, 'reaction_log_bonus')
                .replaceAll('{reaction}', name)
                .replaceAll('{name}', target.displayName)
                .replaceAll('{n}', '$bonus')
            : trFor(lang, 'reaction_log')
                .replaceAll('{reaction}', name)
                .replaceAll('{name}', target.displayName),
        _LogKind.playerDamage));
    switch (reaction) {
      case ElementReaction.shatter:
        target.guard = 0;
      case ElementReaction.freeze:
        if (isBossEnemy(target.enemyId, target.data) ||
            target.phases.isNotEmpty) {
          entries.add(_LogEntry(
              trFor(lang, 'reaction_freeze_resisted')
                  .replaceAll('{name}', target.displayName),
              _LogKind.info));
        } else {
          target.statusEffects = applyStatusEffect(
              target.statusEffects,
              const StatusEffect(
                  type: StatusEffectType.stun, remainingTurns: 1));
          entries.add(_LogEntry(
              _statusInflictedMessage(
                  const StatusEffect(
                      type: StatusEffectType.stun, remainingTurns: 1),
                  target.displayName,
                  lang),
              _LogKind.info));
        }
      case ElementReaction.sandblast:
        const weaken = StatusEffect(
            type: StatusEffectType.weaken,
            remainingTurns: weakenTurns,
            magnitude: sandblastWeakenPercent);
        target.statusEffects = applyStatusEffect(target.statusEffects, weaken);
        entries.add(_LogEntry(
            _statusInflictedMessage(weaken, target.displayName, lang),
            _LogKind.info));
      case ElementReaction.conduct:
      case ElementReaction.firestorm:
      case ElementReaction.eclipse:
        break;
    }
    final spread = reactionSpreadShare(reaction);
    if (spread > 0) {
      for (final other in _enemies) {
        if (other == target || !other.isAlive) continue;
        final share = max(1, (landed * spread).round());
        other.currentHealth = max(0, other.currentHealth - share);
        entries.add(_LogEntry(
            '${other.displayName} ${trFor(lang, 'takes_damage_word')} $share '
            '${trFor(lang, 'damage_word')}.',
            _LogKind.playerDamage));
      }
    }
  }

  /// The chips on an enemy's card for the elements that prime it now.
  List<Widget> _reactionChips(_EnemyMember enemy) {
    if (!enemy.isAlive) return const [];
    final lang = ref.watch(appLanguageProvider);
    return [
      for (final element in activeMarks(enemy.elementMarks, _roundsStarted))
        _stateChip(
          Icons.bubble_chart,
          elementLabel(element, lang),
          Colors.indigo,
          tooltip: tr(ref, 'reaction_primed_tip')
              .replaceAll('{e}', elementLabel(element, lang))
              .replaceAll(
                  '{p}',
                  reactionPartners(element)
                      .map((e) => elementLabel(e, lang))
                      .join(', ')),
        ),
    ];
  }
}
