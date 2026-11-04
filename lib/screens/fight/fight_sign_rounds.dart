part of '../fight_screen.dart';

/// What the player's signs do in a round (see fight_rounds.dart).
extension _FightSignRounds on _FightScreenState {
  // --- Signs (see signs.dart) ----------------------------------------------

  /// What the player's own guard and mend signs do once their face is
  /// played: a Defend face heals and arms the guard signs for the enemies'
  /// turn; a Heal face reaches the rest of the party, spills into block
  /// ([signShield], already added to the block) and lifts afflictions.
  void _applySignFaceExtras(
    _PartyMember actor,
    DiceFaceResult face,
    PlayerActionResult result,
    int healing,
    int signShield,
    List<_LogEntry> entries,
    AppLanguage lang,
  ) {
    if (_signs.isEmpty) return;
    if (face.type == 'Defend' && result.blockAmount > 0) {
      _signGuardArmed = true;
      final heal = min(_signs.guardHeal, actor.maxHealth - actor.currentHealth);
      if (heal > 0) {
        actor.currentHealth += heal;
        _fx(VfxStyle.heal, _memberCardKey(actor.id),
            delayMs: 300, text: '+$heal', textKind: VfxTextKind.heal);
        entries.add(_LogEntry(
            trFor(lang, 'sign_log_guard_heal').replaceAll('{n}', '$heal'),
            _LogKind.playerHeal));
      }
    }
    if (face.type != 'Heal' || healing <= 0) return;
    if (signShield > 0) {
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_mend_shield').replaceAll('{n}', '$signShield'),
          _LogKind.playerBlock));
    }
    final share = _signs.mendShare(healing);
    final others = _party.where((m) => !m.isPlayer && !m.isKnockedOut).toList();
    if (share > 0 && others.isNotEmpty) {
      for (final member in others) {
        member.currentHealth =
            min(member.maxHealth, member.currentHealth + share);
        _fx(VfxStyle.heal, _memberCardKey(member.id),
            delayMs: 300, text: '+$share', textKind: VfxTextKind.heal);
      }
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_mend_party').replaceAll('{n}', '$share'),
          _LogKind.playerHeal));
    }
    final lifted = min(_signs.mendCleanse, actor.statusEffects.length);
    if (lifted > 0) {
      actor.statusEffects = actor.statusEffects.skip(lifted).toList();
      entries
          .add(_LogEntry(trFor(lang, 'sign_log_cleanse'), _LogKind.playerHeal));
    }
  }

  /// Rolls each of [chances] (a sign's status at its odds) against
  /// [enemy], logging those that land under the sign's name.
  void _rollSignStatuses(List<SignStatusChance> chances, _EnemyMember enemy,
      List<_LogEntry> entries, AppLanguage lang) {
    for (final chance in chances) {
      if (!enemy.isAlive || !chance.rolls(_random)) continue;
      enemy.statusEffects = applyStatusEffect(
          enemy.statusEffects, _signs.playerInflicted(chance.status));
      _fx(styleForStatus(chance.status.type), _enemyCardKey(enemy.key),
          delayMs: 350);
      entries.add(_LogEntry(
        trFor(lang, 'sign_log_status')
            .replaceAll('{sign}', _signName(chance.signId, lang))
            .replaceAll(
                '{line}',
                _statusInflictedMessage(
                    chance.status, enemy.displayName, lang)),
        _LogKind.info,
      ));
    }
  }

  /// A held sign's name for the log; the word "Signs" when it's unknown.
  String _signName(String signId, AppLanguage lang) =>
      _signDefs[signId]?.nameFor(lang) ?? trFor(lang, 'signs_section');

  /// The player's guard signs answering [enemy]'s blow: its [retaliation]
  /// back, and the guard's statuses at their odds.
  void _signGuardAnswers(
      _EnemyMember enemy, int retaliation, AppLanguage lang, int delay) {
    final entries = <_LogEntry>[];
    if (retaliation > 0) {
      final dealt = min(retaliation, enemy.currentHealth);
      enemy.currentHealth -= dealt;
      _fx(VfxStyle.impact, _enemyCardKey(enemy.key),
          source: _memberCardKey('player'),
          delayMs: delay + 350,
          text: '-$dealt',
          textKind: VfxTextKind.damage);
      final guardSign = heldInSlot(
          SignSlot.guard, ref.read(playerSessionProvider).heldSigns, _signDefs);
      entries.add(_LogEntry(
        trFor(lang, 'sign_log_retaliate')
            .replaceAll('{sign}', _signName(guardSign?.signId ?? '', lang))
            .replaceAll('{name}', enemy.displayName)
            .replaceAll('{n}', '$dealt'),
        _LogKind.playerDamage,
      ));
      _lastDamagedEnemyKey = enemy.key;
      _lastEnemyDamageTaken = dealt;
    }
    _rollSignStatuses(_signs.guardStatuses, enemy, entries, lang);
    if (entries.isNotEmpty) _update(() => _log.addAll(entries));
  }

  /// A kill-heal sign feeding on each enemy fallen since the last look
  /// (one that fled doesn't count): the player recovers its health.
  void _feedSignKills(List<_LogEntry> entries, AppLanguage lang) {
    _feedSpecKills(entries, lang);
    if (_signs.killHeal <= 0) return;
    final player = _party.firstWhere((m) => m.isPlayer);
    for (final enemy in _enemies) {
      if (enemy.isAlive || enemy.fled || !_signKillsFed.add(enemy.key)) {
        continue;
      }
      final heal = player.isKnockedOut
          ? 0
          : min(_signs.killHeal, player.maxHealth - player.currentHealth);
      if (heal <= 0) continue;
      player.currentHealth += heal;
      _fx(VfxStyle.heal, _memberCardKey(player.id),
          delayMs: 300, text: '+$heal', textKind: VfxTextKind.heal);
      entries.add(_LogEntry(
          trFor(lang, 'sign_log_kill_heal').replaceAll('{n}', '$heal'),
          _LogKind.playerHeal));
    }
  }
}
