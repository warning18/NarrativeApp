part of '../fight_screen.dart';

/// Finishing the fight: rewards, loot, the aftermath and leaving.
extension _FightRewards on _FightScreenState {
  /// Edit mode's shortcut: every enemy drops and the fight is won as if
  /// played out, with its rewards, chest and aftermath.
  void _autoWin(Map<String, dynamic> skills, Map<String, dynamic> items) {
    if (_over) return;
    if (!_started) _startFight(skills, items);
    _update(() {
      for (final enemy in _enemies) {
        enemy.currentHealth = 0;
      }
      _currentFaces.clear();
      _awaitingDecision = false;
      _log.add(_LogEntry(
          trFor(ref.read(appLanguageProvider), 'edit_auto_win_log'),
          _LogKind.info));
    });
    _finishFight(won: true);
  }

  Future<void> _finishFight({required bool won}) async {
    // A round still settling when the fight already ended (edit mode's
    // auto-win) must not settle it a second time.
    if (_over) return;
    _update(() {
      _over = true;
      _won = won;
    });

    // What this fight left behind, for the next scene's opening line.
    ref.read(lastFightOutcomeProvider.notifier).state = FightOutcome(
      won: won,
      enemyNames: [for (final e in _enemies) e.displayName],
      isElite: _isElite,
      isHunt: widget.modifiers.isHunt,
      isBoss: widget.modifiers.isZoneBoss ||
          _enemies.any((e) => e.phases.isNotEmpty),
      phasesCrossed: _phasesCrossed,
      knockedOutAllyName: _lastKnockedOutAllyName,
      flawless: !_potionUsed && !_anyKnockedOut,
      rounds: max(1, _roundsStarted),
      chapter: _chapter,
    );

    final notifier = ref.read(playerSessionProvider.notifier);
    final player = _party.firstWhere((m) => m.isPlayer);
    if (won) {
      // Every enemy that died (or fled) in this fight -- a pack's rewards
      // are summed across all of them, not just the one FightScreen was
      // originally constructed with.
      final defeated = _enemies.where((e) => !e.isAlive).toList();
      var goldGain = 0;
      var xpGain = 0;
      // An Elite always drops its trophy on top of the spoils chest -- the
      // guaranteed "that was worth it" payoff for the harder fight, on top
      // of the reward multiplier applied per enemy and the chest's own
      // Silver floor. Elite is solo-only, so this never double-applies.
      final loot = <String>[if (_isElite) 'elite_trophy'];
      final session = ref.read(playerSessionProvider);
      final items = ref.read(gameDbProvider(itemsSchema)).value ?? const {};
      final professions =
          ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final preferredScalingStat = (professions[session.professionId]
                  as Map<String, dynamic>?)?['preferredScalingStat']
              ?.toString() ??
          '';
      final rewardMultiplier =
          widget.modifiers.rewardMultiplier * chapterRewardMultiplier(_chapter);
      var affixCount = 0;
      var anyFled = false;
      var firstKill = false;
      var hasBoss = false;
      final signatureIds = <String>[];
      for (final enemy in defeated) {
        var enemyGold = scaledReward(
            (enemy.data['goldReward'] as num?)?.toInt() ?? 0, _playerLevel);
        var enemyXp = scaledReward(
            (enemy.data['xpReward'] as num?)?.toInt() ?? 0, _playerLevel);
        if (_isElite) {
          enemyGold = (enemyGold * _eliteRewardMultiplier).round();
          enemyXp = (enemyXp * _eliteRewardMultiplier).round();
        }
        if (enemy.fled) {
          enemyGold = (enemyGold * skittishFledRewardShare).round();
          enemyXp = (enemyXp * skittishFledRewardShare).round();
          anyFled = true;
        }
        goldGain += (enemyGold * rewardMultiplier).round();
        xpGain += (enemyXp * rewardMultiplier).round();
        affixCount += enemy.affixes.length;
        if (soloOnlyEnemyIds.contains(enemy.enemyId)) hasBoss = true;
        if ((session.enemyKillCounts[enemy.enemyId] ?? 0) == 0) {
          firstKill = true;
        }
        // An enemy's loot table now only steers WHICH gear its chest
        // favors (see LootContext.signatureItemIds); the chest itself
        // decides whether anything drops at all.
        final lootTable =
            (enemy.data['lootTable'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        for (final entry in lootTable) {
          final itemId = entry['itemID']?.toString();
          if (itemId == null || itemId.isEmpty) continue;
          // A 100% entry is a guaranteed drop (a quest item such as the
          // High Warden's sealed letter), never a mere chest weighting.
          if (((entry['dropRate'] as num?)?.toDouble() ?? 0) >= 100) {
            loot.add(itemId);
          } else {
            signatureIds.add(itemId);
          }
        }
      }

      var bestAllyLuck = 0;
      final ownedItemIds = <String>[
        ...session.inventoryItemIds,
        ...session.equippedItemIds,
      ];
      for (final member in _party) {
        if (member.isPlayer) continue;
        if (member.luck > bestAllyLuck) bestAllyLuck = member.luck;
        ownedItemIds.addAll(member.equippedItemIds);
      }
      final chapter = _chapter;
      final lootContext = LootContext(
        chapter: chapter,
        playerLuck: player.luck,
        bestAllyLuck: bestAllyLuck,
        isElite: _isElite,
        hasBossOrUnique: hasBoss,
        enemyCount: _enemies.length,
        flawless: !_potionUsed && !_anyKnockedOut,
        rounds: max(1, _roundsStarted),
        finalBlowCritical: _lastKillWasCritical,
        fullTelegraphRead: _fullTelegraphRead,
        firstKill: firstKill,
        pityStreak: session.lootPityStreak,
        affixCount: affixCount,
        conditionBonus: conditionFortuneBonus(_condition),
        tierFloor: widget.modifiers.chestTierFloor,
        tierShift: anyFled ? -1 : 0,
        preferredScalingStat: preferredScalingStat,
        alignmentLabel: session.alignmentLabel,
        ownedItemIds: ownedItemIds,
        recentLootIds: session.recentLootIds,
        signatureItemIds: signatureIds,
      );
      final chest = rollLootBox(lootContext, items, _random);
      loot.addAll(chest.itemIds);
      goldGain += chest.gold;

      final lang = ref.read(appLanguageProvider);
      final chestBanter =
          chest.isBigChest ? _rollBanter(kind: _BanterKind.chest) : null;
      if (!mounted) return;
      final spoils = await showSpoilsChestDialog(
        context,
        result: chest,
        items: items,
        autoOpen: ref.read(chestAutoOpenProvider),
        language: lang,
        equippedItemIds: session.equippedItemIds,
        canEquip: (itemId) {
          final item = items[itemId] as Map<String, dynamic>?;
          return meetsItemStatRequirement(
                item,
                strength: session.strength,
                dexterity: session.dexterity,
                constitution: session.constitution,
                intelligence: session.intelligence,
              ) &&
              meetsItemAlignment(item, session.alignmentLabel);
        },
        currentHealth: player.currentHealth,
        maxHealth: player.maxHealth,
      );
      if (!mounted) return;

      // A potion drunk from the chest heals before the health is saved;
      // its charge is spent below, once the loot has been granted.
      final drinks = spoils.drinkItemIds.length;
      final hpAfterSpoils = min(
          player.maxHealth, player.currentHealth + drinks * potionHealAmount);
      final leveledUp = await notifier.applyCombatResult(
        hpAfter: hpAfterSpoils,
        enemyIds: defeated.map((e) => e.enemyId).toList(),
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
        items: items,
        lootPityStreak: nextPityStreak(session.lootPityStreak, chest.tier),
        recentLootIds: nextRecentLootIds(session.recentLootIds, chest.itemIds),
        manaAfter: _mana,
      );
      // A knocked-out ally is revived at partial health on a win; a
      // survivor's ending health is simply persisted as-is. Level-ups
      // already full-heal every recruited ally inside applyCombatResult
      // itself, so skip writing each ally's stale pre-level-up battle-end
      // HP over that full heal (and over the new, higher level-up max).
      var anyAllyRevived = false;
      for (final member in _party) {
        if (member.isPlayer) continue;
        if (member.isKnockedOut) anyAllyRevived = true;
        if (leveledUp) continue;
        final hpAfter = member.isKnockedOut
            ? (member.maxHealth * _reviveHealthFraction).round()
            : member.currentHealth;
        await notifier.applyAllyCombatResult(member.id, hpAfter: hpAfter);
      }
      final newlyUnlockedAchievement = anyAllyRevived
          ? await notifier.unlockAchievement('ally_revival')
          : false;
      // What the player chose in the chest: put gear on straight away and
      // drink potions (a level-up already healed fully, so a potion picked
      // then is kept instead of wasted).
      final spoilsLog = <String>[];
      for (final itemId in spoils.equipItemIds) {
        final item = items[itemId] as Map<String, dynamic>?;
        await notifier.equipItem(itemId,
            slot: item?['equipSlot']?.toString(), items: items);
        spoilsLog.add('${trFor(lang, 'loot_equipped_message')} '
            '${item?['itemName']?.toString() ?? itemId}.');
      }
      if (drinks > 0) {
        if (leveledUp) {
          spoilsLog.add(trFor(lang, 'loot_potion_kept_message'));
        } else {
          for (var i = 0; i < drinks; i++) {
            await notifier.consumePotion();
          }
          spoilsLog.add(trFor(lang, 'loot_drank_message')
              .replaceAll('{hp}', '${hpAfterSpoils - player.currentHealth}'));
        }
      }
      if (!mounted) return;
      final lootNames = [
        for (final id in loot)
          (items[id] as Map<String, dynamic>?)?['itemName']?.toString() ?? id,
      ];
      _update(() {
        _log.add(
          _LogEntry(
            '${trFor(lang, 'victory_prefix')} +$goldGain ${trFor(lang, 'gold_label')}, '
            '+$xpGain XP'
            '${lootNames.isNotEmpty ? ", ${trFor(lang, 'loot_label')}: ${lootNames.join(", ")}" : ""}.',
            _LogKind.victory,
          ),
        );
        _log.add(_LogEntry(
          '${trFor(lang, chestTierLabelKey(chest.tier))} '
          '(${trFor(lang, 'fortune_roll_label')} ${chest.roll})',
          _LogKind.victory,
        ));
        if (chestBanter != null) _log.add(chestBanter);
        for (final line in spoilsLog) {
          _log.add(_LogEntry(line, _LogKind.victory));
        }
        if (newlyUnlockedAchievement) {
          _log.add(
            _LogEntry(
              '${trFor(lang, 'achievement_unlocked_prefix')}: Not Dead Yet',
              _LogKind.victory,
            ),
          );
        }
      });
      if (leveledUp) {
        final newLevel = ref.read(playerSessionProvider).level;
        showLevelUpDialog(context, ref, newLevel: newLevel);
      }
      _update(() => _settled = true);
    } else {
      // Ally HP changes from a lost fight are never persisted (mirrors the
      // player's own full-heal-on-loss below — neither side is punished
      // HP-wise by a loss).
      // A loss refills mana along with health -- neither is a lasting
      // punishment. A boss's win is remembered, though: Resolve stacks
      // against it next time (see party_bonus.dart).
      final bossIds = [
        for (final e in _enemies)
          if (isBossEnemy(e.enemyId, e.data)) e.enemyId,
      ];
      if (bossIds.isNotEmpty) await notifier.recordBossDefeat(bossIds);
      await notifier.applyCombatResult(
          hpAfter: player.maxHealth, manaAfter: _maxMana);
      if (!mounted) return;
      _update(() {
        _log.add(_LogEntry(
            trFor(ref.read(appLanguageProvider), 'defeat_message'),
            _LogKind.defeat));
        _settled = true;
      });
    }
  }

  /// The end-of-fight button: back to the story on a win, retreat (or the
  /// permadeath flow) on a loss.
  Widget _buildReturnButton() {
    return ElevatedButton(
      onPressed: _settled ? _leaveFight : null,
      child: Text(_won
          ? tr(ref, 'victory_return_button')
          : widget.modifiers.lossContinues
              ? tr(ref, 'defeat_continue_button')
              : tr(ref, 'retreat_button')),
    );
  }

  /// Leaves a finished fight: back to the story with the result, or -- a
  /// loss with permadeath on -- the death screen. The return button and
  /// the system back gesture both come here, so neither can skip a loss.
  Future<void> _leaveFight() async {
    if (!_over || !_settled || _leaving) return;
    _leaving = true;
    if (!_won && ref.read(permadeathEnabledProvider)) {
      final nodesVisited = ref.read(storyPlayProvider).history.length + 1;
      final playerSession = ref.read(playerSessionProvider);
      final races = ref.read(gameDbProvider(racesSchema)).value ?? const {};
      final professions =
          ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final result =
          await ref.read(playerSessionProvider.notifier).applyPermadeath(
                race: races[playerSession.raceId] as Map<String, dynamic>? ??
                    const {},
                profession: professions[playerSession.professionId]
                        as Map<String, dynamic>? ??
                    const {},
              );
      // The same character starts the story over: from the first scene
      // after character creation, never through it (creating a character
      // wipes the one who just died, level and all).
      final story = ref.read(storyDataProvider).value;
      ref.read(storyPlayProvider.notifier).restart(story == null
          ? StoryRepository.startNodeId
          : firstSceneAfterCreation(story));
      ref.read(homeTabIndexProvider.notifier).state = 0;
      // The dead character's last fight is the death screen's to tell,
      // not the next scene's.
      ref.read(lastFightOutcomeProvider.notifier).state = null;
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DeathScreen(
            lostItemIds: result.lostItemIds,
            xpEarned: result.xpEarnedThisRun,
            skillsLost: result.skillsLost,
            nodesVisited: nodesVisited,
            killerName: _enemies.isEmpty ? '' : _enemies.first.displayName,
            narrationSeed: _random.nextInt(1 << 20),
          ),
        ),
        (route) => route.isFirst,
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(_won);
  }
}
