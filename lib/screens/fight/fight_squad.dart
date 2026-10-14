part of '../fight_screen.dart';

/// Squad roles and enemies that answer the party (v1.215, see squad.dart and
/// enemy_response.dart).
extension _FightSquad on _FightScreenState {
  /// The healers among the enemies mend the most wounded of their friends
  /// before the enemies strike.
  void _squadHealersMend(AppLanguage lang) {
    for (final healer in _enemies) {
      if (!healer.isAlive ||
          healer.role != SquadRole.healer ||
          isStunned(healer.statusEffects) ||
          healer.staggered) {
        continue;
      }
      final index = squadHealTarget(
        health: [for (final e in _enemies) e.currentHealth],
        maxHealth: [for (final e in _enemies) e.maxHealth],
        self: _enemies.indexOf(healer),
      );
      if (index == null) continue;
      final friend = _enemies[index];
      final healed = min(squadHealAmount(friend.maxHealth),
          friend.maxHealth - friend.currentHealth);
      if (healed <= 0) continue;
      _fx(VfxStyle.heal, _enemyCardKey(friend.key),
          text: '+$healed', textKind: VfxTextKind.heal);
      _update(() {
        friend.currentHealth += healed;
        _log.add(_LogEntry(
            trFor(lang, 'squad_healer_mends')
                .replaceAll('{healer}', healer.displayName)
                .replaceAll('{name}', friend.displayName)
                .replaceAll('{n}', '$healed'),
            _LogKind.info));
      });
    }
  }

  /// After the party's blows: the enemies that watch the round answer it.
  void _applyEnemyResponses(
      Map<String, DiceFaceResult> played,
      Map<String, PlayerActionResult> results,
      List<_LogEntry> entries,
      AppLanguage lang) {
    final acting = played.keys.length;
    final defenders = played.values.where((f) => f.type == 'Defend').length;
    String? bestHealer;
    var bestHealing = 0;
    for (final entry in results.entries) {
      if (entry.value.healingDone > bestHealing) {
        bestHealing = entry.value.healingDone;
        bestHealer = entry.key;
      }
    }
    for (final enemy in _enemies) {
      if (!enemy.isAlive ||
          enemy.response == EnemyResponse.none ||
          isStunned(enemy.statusEffects) ||
          enemy.staggered) {
        continue;
      }
      switch (enemy.response) {
        case EnemyResponse.counter:
          if (provokesCounter(enemy.damageThisRound, enemy.maxHealth)) {
            enemy.provoked = true;
            final hitter = enemy.topHitterId;
            final pending = enemy.pendingMove;
            if (hitter != null && pending != null) {
              final member = _memberById(hitter);
              if (member != null && !member.isKnockedOut) {
                enemy.pendingMove = _PendingEnemyMove(
                    move: pending.move,
                    targetId: member.id,
                    release: pending.release);
              }
            }
            entries.add(_LogEntry(
                trFor(lang, 'response_provoked')
                    .replaceAll('{name}', enemy.displayName),
                _LogKind.enemyDamage));
          }
        case EnemyResponse.press:
          if (provokesPress(defenders: defenders, acting: acting)) {
            enemy.pressing = true;
            entries.add(_LogEntry(
                trFor(lang, 'response_pressing')
                    .replaceAll('{name}', enemy.displayName),
                _LogKind.enemyDamage));
          }
        case EnemyResponse.huntHealer:
          final healerId = bestHealer;
          final pending = enemy.pendingMove;
          if (healerId != null && pending != null) {
            final member = _memberById(healerId);
            if (member != null && !member.isKnockedOut) {
              enemy.pendingMove = _PendingEnemyMove(
                  move: pending.move,
                  targetId: member.id,
                  release: pending.release);
              entries.add(_LogEntry(
                  trFor(lang, 'response_hunts')
                      .replaceAll('{name}', enemy.displayName)
                      .replaceAll('{target}', member.displayName),
                  _LogKind.enemyDamage));
            }
          }
        case EnemyResponse.none:
          break;
      }
    }
  }

  /// The chips on an enemy's card for its role and what it is set on.
  List<Widget> _squadMarks(_EnemyMember enemy) {
    if (!enemy.isAlive) return const [];
    final role = enemy.role;
    return [
      if (role != null)
        _stateChip(
          switch (role) {
            SquadRole.healer => Icons.healing,
            SquadRole.guard => Icons.shield,
            SquadRole.striker => Icons.flash_on,
          },
          tr(ref, squadRoleLabelKey(role)),
          Colors.teal,
          tooltip: tr(ref, squadRoleDescriptionKey(role)),
        ),
      if (enemy.provoked)
        _stateChip(Icons.whatshot, tr(ref, 'response_provoked_chip'),
            Colors.red.shade700),
      if (enemy.pressing)
        _stateChip(Icons.keyboard_double_arrow_down,
            tr(ref, 'response_pressing_chip'), Colors.red.shade700),
    ];
  }
}
