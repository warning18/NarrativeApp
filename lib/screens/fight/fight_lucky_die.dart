part of '../fight_screen.dart';

/// How long after the lucky die strikes the fight's tour waits, so the
/// blow and the sign are seen before the guide explains the dice.
const Duration _luckyDieTourDelay = Duration(milliseconds: 1600);

/// The story's first fight (v1.196, see [EncounterModifiers.luckyDieReveal]).
extension _FightLuckyDie on _FightScreenState {
  /// The enemy lands the first blow; the player's old bone die jars loose,
  /// comes up six and strikes back with a sign; a moment later the fight's
  /// tour explains the dice, and the party's first round begins. Returns
  /// whether the strike ended the fight.
  bool _openWithLuckyDie(AppLanguage lang) {
    _luckyDieTourTimer?.cancel();
    _luckyDieTourTimer = Timer(_luckyDieTourDelay, () {
      if (mounted) _update(() => _luckyDieTourReady = true);
    });
    final player = _party.firstWhere((m) => m.isPlayer);
    _EnemyMember? enemy;
    for (final e in _enemies) {
      if (e.isAlive) {
        enemy = e;
        break;
      }
    }
    if (enemy == null) return false;
    final foe = enemy;
    final blow = luckyDieOpeningBlow(
      enemyDamage: foe.damage,
      playerHealth: player.currentHealth,
      playerMaxHealth: player.maxHealth,
    );
    final strike = min(foe.currentHealth, luckyDieStrike(foe.maxHealth));
    _update(() {
      player.currentHealth = max(1, player.currentHealth - blow);
      _lastDamageTaken = blow;
      _lastDamagedMemberId = player.id;
      foe.currentHealth = max(0, foe.currentHealth - strike);
      _lastDamagedEnemyKey = foe.key;
      _lastEnemyDamageTaken = strike;
      _log.add(_LogEntry(
        trFor(lang, 'lucky_die_opening_blow')
            .replaceAll('{enemy}', foe.displayName)
            .replaceAll('{n}', '$blow'),
        _LogKind.enemyDamage,
      ));
      _log.add(_LogEntry(
        trFor(lang, 'lucky_die_reveal')
            .replaceAll('{enemy}', foe.displayName)
            .replaceAll('{n}', '$strike'),
        _LogKind.phase,
      ));
      _log.add(_LogEntry(trFor(lang, 'lucky_die_roll_it'), _LogKind.info));
    });
    if (blow > 0) {
      _triggerShake();
      _fx(VfxStyle.impact, _memberCardKey(player.id),
          delayMs: 250, text: '-$blow', textKind: VfxTextKind.hurt);
    }
    _fx(VfxStyle.radiance, _enemyCardKey(foe.key),
        source: _memberCardKey(player.id),
        delayMs: 900,
        text: '-$strike',
        textKind: VfxTextKind.damage,
        big: true);
    if (_enemies.every((e) => !e.isAlive)) {
      _finishFight(won: true);
      return true;
    }
    return false;
  }
}
