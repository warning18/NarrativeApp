part of '../fight_screen.dart';

/// Actions taken outside the dice: potions, antidotes and spells.
extension _FightActions on _FightScreenState {
  void _usePotion() {
    final session = ref.read(playerSessionProvider);
    if (session.potionCount <= 0 || _over) return;
    final player = _party.firstWhere((m) => m.isPlayer);
    ref.read(playerSessionProvider.notifier).consumePotion();
    final lang = ref.read(appLanguageProvider);
    final heal = _condition == BattlefieldCondition.shrine
        ? (_potionHealAmount * shrineHealMultiplier).round()
        : _potionHealAmount;
    _potionUsed = true;
    _fx(VfxStyle.heal, _memberCardKey(player.id),
        text: '+$heal', textKind: VfxTextKind.heal);
    _update(() {
      player.currentHealth = min(player.maxHealth, player.currentHealth + heal);
      _log.add(
        _LogEntry(
          '${trFor(lang, 'drink_potion_prefix')} $heal ${trFor(lang, 'hp_label')}.',
          _LogKind.playerHeal,
        ),
      );
    });
  }

  /// Cures every active status effect (Poison/Stun/Weaken) off the player —
  /// mirrors [_usePotion]'s plumbing exactly, just against
  /// [PlayerSessionNotifier.consumeAntidote] and [_PartyMember.statusEffects]
  /// instead of health. Allies aren't cured (matches how potions are
  /// player-only too).
  void _useAntidote() {
    final session = ref.read(playerSessionProvider);
    final player = _party.firstWhere((m) => m.isPlayer);
    if (session.antidoteCount <= 0 || _over || player.statusEffects.isEmpty) {
      return;
    }
    ref.read(playerSessionProvider.notifier).consumeAntidote();
    final lang = ref.read(appLanguageProvider);
    _fx(VfxStyle.splash, _memberCardKey(player.id), element: 'Water');
    _update(() {
      player.statusEffects = [];
      _log.add(
        _LogEntry(trFor(lang, 'drink_antidote_prefix'), _LogKind.playerHeal),
      );
    });
  }

  // --- Spells --------------------------------------------------------------

  /// What [spell] would deal / heal / block if the player cast it right
  /// now -- a Damage spell rides the same total the player's dice hit
  /// with (base, gear, stat scaling, alignment, the spell's element).
  int _spellAmountNow(SpellSpec spell, Map<String, dynamic> items) {
    final player = _party.firstWhere((m) => m.isPlayer);
    final scalingBonus = equipmentScalingBonusFor(
      player.equippedItemIds,
      items,
      strength: player.strength,
      dexterity: player.dexterity,
      constitution: player.constitution,
      intelligence: player.intelligence,
    );
    final alignedBonus =
        alignmentGearBonusFor(player.equippedItemIds, items, _alignmentLabel);
    final casterDamage = player.baseDamage +
        equipmentBonusFor(player.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus +
        alignedBonus.damageBonus +
        player.gear.attackDamage +
        _elementalDamageBonus(spell.element, player.equippedItemIds, items);
    return spellAmountFor(
      spell,
      intelligence: player.intelligence,
      wisdom: player.wisdom,
      strength: player.strength,
      level: _playerLevel,
      casterDamage: casterDamage,
    );
  }

  /// Casts [spell] right now, like drinking a potion: picks its target(s)
  /// (a sheet when there's a real choice), applies the effect, spends the
  /// mana and persists it. Spells never crit, are never Weakened and
  /// ignore the Armored affix -- the number on the button is what lands.
  Future<void> _castSpell(
    SpellSpec spell,
    Map<String, dynamic> skills,
    Map<String, dynamic> items, {
    String? scrollItemId,
  }) async {
    if (_over || _rolling || !_started || _mana < spell.manaCost) return;
    if (scrollItemId != null &&
        !ref
            .read(playerSessionProvider)
            .inventoryItemIds
            .contains(scrollItemId)) {
      return;
    }
    final lang = ref.read(appLanguageProvider);
    final player = _party.firstWhere((m) => m.isPlayer);
    final amount = _spellAmountNow(spell, items);
    final status = spellStatusFor(spell, level: _playerLevel);

    final enemyTargets = <_EnemyMember>[];
    final memberTargets = <_PartyMember>[];
    switch (spell.target) {
      case SpellTarget.enemy:
        final living = _enemies.where((e) => e.isAlive).toList();
        if (living.isEmpty) return;
        final picked =
            living.length == 1 ? living.first : await _pickEnemy(living, spell);
        if (picked == null) return;
        enemyTargets.add(picked);
      case SpellTarget.allEnemies:
        enemyTargets.addAll(_enemies.where((e) => e.isAlive));
      case SpellTarget.ally:
        final conscious = _party.where((m) => !m.isKnockedOut).toList();
        if (conscious.isEmpty) return;
        final picked = conscious.length == 1
            ? conscious.first
            : await _pickMember(conscious, spell);
        if (picked == null) return;
        memberTargets.add(picked);
      case SpellTarget.party:
        memberTargets.addAll(_party.where((m) => !m.isKnockedOut));
      case SpellTarget.self:
        memberTargets.add(player);
    }
    if (!mounted || _over || _rolling) return;

    final entries = <_LogEntry>[
      _LogEntry(
        scrollItemId != null
            ? '${trFor(lang, 'read_scroll_prefix')} ${spell.nameFor(lang)}. '
                '${spell.battleMessageFor(lang)}'
            : '${trFor(lang, 'cast_prefix')} ${spell.nameFor(lang)} '
                '(-${spell.manaCost} ${trFor(lang, 'mana_label')}). '
                '${spell.battleMessageFor(lang)}',
        _LogKind.mana,
      ),
    ];
    var hitsLanded = 0;
    final spellStyle = styleForSpell(
        vfx: spell.vfx, element: spell.element, effect: spell.effect.name);
    final casterKey = _memberCardKey(player.id);
    var spellFx = 0;
    for (final enemy in enemyTargets) {
      final fxDelay = spellFx++ * 120;
      if (spell.effect != SpellEffectKind.damage) {
        _fx(spellStyle, _enemyCardKey(enemy.key),
            source: casterKey, element: spell.element, delayMs: fxDelay);
      }
      if (spell.effect == SpellEffectKind.damage) {
        final damage = amount;
        _fx(spellStyle, _enemyCardKey(enemy.key),
            source: casterKey,
            element: spell.element,
            delayMs: fxDelay,
            text: '-$damage',
            textKind: VfxTextKind.damage);
        final wasAlive = enemy.isAlive;
        enemy.currentHealth = max(0, enemy.currentHealth - damage);
        if (damage > 0) {
          hitsLanded++;
          _lastDamagedEnemyKey = enemy.key;
          _lastEnemyDamageTaken = damage;
          if (spell.element != 'None') {
            enemy.elementsHitThisRound.add(spell.element);
          }
        }
        if (wasAlive && !enemy.isAlive) _lastKillWasCritical = false;
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, 'takes_damage_word')} $damage '
          '${trFor(lang, 'damage_word')}.',
          _LogKind.playerDamage,
        ));
      }
      if (status != null && enemy.isAlive) {
        _fx(styleForStatus(status.type), _enemyCardKey(enemy.key),
            delayMs: fxDelay + 350);
        enemy.statusEffects = applyStatusEffect(enemy.statusEffects, status);
        entries.add(_LogEntry(
          _statusInflictedMessage(status, enemy.displayName, lang),
          _LogKind.info,
        ));
      }
    }
    for (final member in memberTargets) {
      final fxDelay = spellFx++ * 120;
      final memberKey = _memberCardKey(member.id);
      switch (spell.effect) {
        case SpellEffectKind.heal:
          var healing = amount;
          if (_condition == BattlefieldCondition.shrine) {
            healing = (healing * shrineHealMultiplier).round();
          }
          _fx(spellStyle, memberKey,
              element: spell.element,
              delayMs: fxDelay,
              text: '+$healing',
              textKind: VfxTextKind.heal);
          member.currentHealth =
              min(member.maxHealth, member.currentHealth + healing);
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'recovers_word')} $healing '
            '${trFor(lang, 'hp_label')}.',
            _LogKind.playerHeal,
          ));
        case SpellEffectKind.block:
          var block = amount;
          if (_condition == BattlefieldCondition.highGround) {
            block = (block * highGroundBlockMultiplier).round();
          }
          _fx(spellStyle, memberKey,
              element: spell.element,
              delayMs: fxDelay,
              text: '+$block',
              textKind: VfxTextKind.block);
          _spellBlock[member.id] = (_spellBlock[member.id] ?? 0) + block;
          member.block += block;
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'gains_block_word')} $block '
            '${trFor(lang, 'block_word')}.',
            _LogKind.playerBlock,
          ));
        case SpellEffectKind.cleanse:
          _fx(spellStyle, memberKey, element: spell.element, delayMs: fxDelay);
          member.statusEffects = [];
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'cleansed_suffix')}',
            _LogKind.playerHeal,
          ));
        case SpellEffectKind.damage:
        case SpellEffectKind.status:
          break;
      }
    }
    _advanceBossPhases(entries, lang, skills);
    if (hitsLanded > 0) {
      final before = _momentum;
      _momentum = min(_momentumThreshold, _momentum + hitsLanded);
      if (before < _momentumThreshold && _momentum >= _momentumThreshold) {
        entries.add(
            _LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
      }
    }
    _noteSkittishFlights(entries, lang);

    if (scrollItemId != null) {
      ref.read(playerSessionProvider.notifier).consumeItem(scrollItemId);
    } else {
      _mana -= spell.manaCost;
      ref.read(playerSessionProvider.notifier).setMana(_mana);
    }
    _update(() {
      _log.addAll(entries);
      _autoAssignTargets();
    });

    if (_enemies.every((e) => !e.isAlive)) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _finishFight(won: true);
    }
  }

  Future<_EnemyMember?> _pickEnemy(
      List<_EnemyMember> candidates, SpellSpec spell) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<_EnemyMember>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${spell.nameFor(lang)} · ${trFor(lang, 'choose_target_title')}',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            for (final enemy in candidates)
              ListTile(
                leading: EnemyPixelIcon(enemy.enemyId, size: 28),
                title: Text(enemy.displayName),
                subtitle: Text(
                    '${trFor(lang, 'hp_label')} ${enemy.currentHealth} / ${enemy.maxHealth}'),
                onTap: () => Navigator.of(sheetContext).pop(enemy),
              ),
          ],
        ),
      ),
    );
  }

  Future<_PartyMember?> _pickMember(
      List<_PartyMember> candidates, SpellSpec spell) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<_PartyMember>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${spell.nameFor(lang)} · ${trFor(lang, 'choose_target_title')}',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            for (final member in candidates)
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _accentFor(member),
                  child: Text(
                    member.displayName.isEmpty
                        ? '?'
                        : member.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(
                    '${trFor(lang, 'hp_label')} ${member.currentHealth} / ${member.maxHealth}'),
                onTap: () => Navigator.of(sheetContext).pop(member),
              ),
          ],
        ),
      ),
    );
  }
}
