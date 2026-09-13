import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../widgets/level_up_dialog.dart';
import 'death_screen.dart';

const int _potionHealAmount = 30;

/// Broad categories a combat-log line falls into, used to color and icon
/// each line so the log reads at a glance instead of as a wall of text.
enum _LogKind { info, playerDamage, playerHeal, playerBlock, enemyDamage, victory, defeat }

class _LogEntry {
  const _LogEntry(this.text, this.kind);

  final String text;
  final _LogKind kind;
}

Color _logColor(BuildContext context, _LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case _LogKind.playerDamage:
      return Colors.deepOrange;
    case _LogKind.playerHeal:
      return Colors.green;
    case _LogKind.playerBlock:
      return Colors.blueGrey;
    case _LogKind.enemyDamage:
      return Colors.red;
    case _LogKind.victory:
      return Colors.amber.shade800;
    case _LogKind.defeat:
      return Colors.red.shade900;
  }
}

IconData _logIcon(_LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Icons.info_outline;
    case _LogKind.playerDamage:
      return Icons.bolt;
    case _LogKind.playerHeal:
      return Icons.favorite;
    case _LogKind.playerBlock:
      return Icons.shield;
    case _LogKind.enemyDamage:
      return Icons.warning_amber_rounded;
    case _LogKind.victory:
      return Icons.emoji_events;
    case _LogKind.defeat:
      return Icons.heart_broken;
  }
}

/// Icon for a die face's own type — distinct from [_logIcon], which is
/// about a resolved log line's category.
IconData _faceTypeIcon(String type) {
  switch (type) {
    case 'Attack':
      return Icons.bolt;
    case 'Defend':
      return Icons.shield;
    case 'Heal':
      return Icons.favorite;
    case 'Skill':
      return Icons.auto_awesome;
    default:
      return Icons.remove_circle_outline;
  }
}

/// The skill a rolled 'Skill' face actually resolves to — mirrors
/// combat_engine.dart's own fallback so the preview always matches what
/// pressing Confirm will actually do.
String _effectiveSkillId(DiceFaceResult face) =>
    face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;

const int _maxRolls = 3;

class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({super.key, required this.enemyId, required this.enemy});

  final String enemyId;
  final Map<String, dynamic> enemy;

  @override
  ConsumerState<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends ConsumerState<FightScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  final List<_LogEntry> _log = [];

  bool _started = false;
  bool _over = false;
  bool _won = false;

  late int _playerLevel;
  late int _playerBaseDamage;
  late int _playerMaxHealth;
  late int _playerHealth;
  late int _enemyMaxHealth;
  late int _enemyHealth;
  late int _enemyDamage;
  int _block = 0;
  int _lastDamageTaken = 0;

  String? _selectedDiceId;
  bool _rolling = false;

  /// The most recently rolled face — kept on screen (never cleared) once a
  /// fight has its first roll, so the player always has the face they're
  /// looking at in view, right up until the next roll replaces it.
  DiceFaceResult? _lastFace;

  /// How many times the die has been rolled so far *this turn* (0-3).
  /// Resets to 0 once a roll is confirmed and the turn resolves.
  int _rollCount = 0;

  /// True right after a roll lands and before the player has chosen to
  /// keep it or reroll — false before the first roll of a turn, and false
  /// again once a choice is confirmed (manually, or forced at the 3rd roll).
  bool _awaitingDecision = false;

  late final AnimationController _shakeController;
  late final AnimationController _rollController;

  @override
  void initState() {
    super.initState();
    final session = ref.read(playerSessionProvider);
    _playerLevel = session.level;
    _playerBaseDamage = session.baseDamage;
    _playerMaxHealth = session.maxHealth;
    _playerHealth = session.currentHealth > 0 ? session.currentHealth : session.maxHealth;
    _enemyMaxHealth =
        scaledMaxHealth((widget.enemy['maxHealth'] as num?)?.toInt() ?? 1, _playerLevel);
    _enemyHealth = _enemyMaxHealth;
    _enemyDamage = scaledDamage((widget.enemy['damage'] as num?)?.toInt() ?? 0, _playerLevel);
    _selectedDiceId = session.equippedDiceId ??
        (session.ownedDiceIds.isNotEmpty ? session.ownedDiceIds.first : null);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Spins and bounces the die icon for a beat before a roll's result is
    // applied, so a tap reads as "rolling" rather than an instant stat swap.
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
  }

  void _startFight() {
    final lang = ref.read(appLanguageProvider);
    setState(() {
      _started = true;
      _log.add(
        _LogEntry(
          '${trFor(lang, 'fight_begins_prefix')} ${widget.enemy['enemyName']} '
          '${trFor(lang, 'has_label')} $_enemyMaxHealth ${trFor(lang, 'hp_label')}.',
          _LogKind.info,
        ),
      );
    });
  }

  int _equipmentDamageBonus(Map<String, dynamic> items) {
    final session = ref.read(playerSessionProvider);
    var bonus = 0;
    for (final id in session.equippedItemIds) {
      final item = items[id] as Map<String, dynamic>?;
      bonus += (item?['attackDamage'] as num?)?.toInt() ?? 0;
    }
    return bonus;
  }

  int _equipmentArmorBonus(Map<String, dynamic> items) {
    final session = ref.read(playerSessionProvider);
    var bonus = 0;
    for (final id in session.equippedItemIds) {
      final item = items[id] as Map<String, dynamic>?;
      bonus += (item?['armor'] as num?)?.toInt() ?? 0;
    }
    return bonus;
  }

  Map<String, dynamic> _availableSkills(Map<String, dynamic> skills) {
    final session = ref.read(playerSessionProvider);
    return <String, dynamic>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ?? false) ||
            session.unlockedSkillIds.contains(entry.key))
          entry.key: entry.value,
    };
  }

  /// Rolls the die once. The first roll of a turn just shows its result and
  /// waits for the player to confirm or reroll (see [_confirmRoll]); the
  /// 3rd roll is forced — there's no more choice left, so it locks in and
  /// resolves automatically after a beat.
  Future<void> _rollDice(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) async {
    if (_over || _rolling || _rollCount >= _maxRolls) return;
    final faces = (dice['faces'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (faces.isEmpty) return;

    var face = rollDie(faces, _random);
    if (face.type == 'Skill') {
      final session = ref.read(playerSessionProvider);
      final assigned = session.diceSkillAssignments[_selectedDiceId]?[face.faceIndex.toString()];
      if (assigned != null && assigned.isNotEmpty) {
        face = face.withLinkedSkillID(assigned);
      }
    }

    setState(() => _rolling = true);
    await _rollController.forward(from: 0);
    if (!mounted) return;

    final rollNumber = _rollCount + 1;
    final forced = rollNumber >= _maxRolls;
    setState(() {
      _rolling = false;
      _rollCount = rollNumber;
      _lastFace = face;
      _awaitingDecision = !forced;
    });

    if (forced) {
      // No choice left — give the player a beat to see the 3rd face land
      // before it resolves on its own.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _confirmRoll(skills, items);
    }
  }

  /// Locks in the currently-shown rolled face and applies its effect,
  /// whether the player tapped Confirm or the 3rd roll forced it.
  Future<void> _confirmRoll(Map<String, dynamic> skills, Map<String, dynamic> items) async {
    final face = _lastFace;
    if (face == null || _over) return;

    final totalDamage = _playerBaseDamage + _equipmentDamageBonus(items);
    final result = resolvePlayerFace(
      face,
      _availableSkills(skills),
      totalDamage,
      language: ref.read(appLanguageProvider),
    );
    final kind = result.damageDealt > 0
        ? _LogKind.playerDamage
        : result.healingDone > 0
            ? _LogKind.playerHeal
            : result.blockAmount > 0
                ? _LogKind.playerBlock
                : _LogKind.info;

    setState(() {
      _awaitingDecision = false;
      _rollCount = 0;
      _enemyHealth = max(0, _enemyHealth - result.damageDealt);
      _playerHealth = min(_playerMaxHealth, _playerHealth + result.healingDone);
      _block = result.blockAmount;
      _log.add(_LogEntry(result.message, kind));
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (_enemyHealth <= 0) {
      _finishFight(won: true);
      return;
    }

    _takeEnemyTurn(skills, items);
  }

  void _takeEnemyTurn(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final move = resolveEnemyMove(
      enemy: {...widget.enemy, 'damage': _enemyDamage},
      skills: skills,
      enemyCurrentHealth: _enemyHealth,
      enemyMaxHealth: _enemyMaxHealth,
      random: _random,
      language: ref.read(appLanguageProvider),
    );
    final session = ref.read(playerSessionProvider);
    final totalArmor = session.baseArmor + _equipmentArmorBonus(items);
    final damageTaken = max(0, move.damage - _block - totalArmor);
    final lang = ref.read(appLanguageProvider);

    setState(() {
      _playerHealth = max(0, _playerHealth - damageTaken);
      _block = 0;
      _lastDamageTaken = damageTaken;
      _log.add(
        _LogEntry(
          '${move.message} ${trFor(lang, 'you_take_damage_prefix')} $damageTaken '
          '${trFor(lang, 'damage_word')}.',
          damageTaken > 0 ? _LogKind.enemyDamage : _LogKind.playerBlock,
        ),
      );
    });
    if (damageTaken > 0) _triggerShake();

    if (_playerHealth <= 0) {
      _finishFight(won: false);
    }
  }

  void _usePotion() {
    final session = ref.read(playerSessionProvider);
    if (session.potionCount <= 0 || _over) return;
    ref.read(playerSessionProvider.notifier).consumePotion();
    final lang = ref.read(appLanguageProvider);
    setState(() {
      _playerHealth = min(_playerMaxHealth, _playerHealth + _potionHealAmount);
      _log.add(
        _LogEntry(
          '${trFor(lang, 'drink_potion_prefix')} $_potionHealAmount ${trFor(lang, 'hp_label')}.',
          _LogKind.playerHeal,
        ),
      );
    });
  }

  Future<void> _finishFight({required bool won}) async {
    setState(() {
      _over = true;
      _won = won;
    });

    final notifier = ref.read(playerSessionProvider.notifier);
    if (won) {
      final goldGain =
          scaledReward((widget.enemy['goldReward'] as num?)?.toInt() ?? 0, _playerLevel);
      final xpGain =
          scaledReward((widget.enemy['xpReward'] as num?)?.toInt() ?? 0, _playerLevel);
      final loot = <String>[];
      final lootTable =
          (widget.enemy['lootTable'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final entry in lootTable) {
        final dropRate = (entry['dropRate'] as num?)?.toDouble() ?? 0;
        if (_random.nextDouble() * 100 <= dropRate) {
          final itemId = entry['itemID']?.toString();
          if (itemId != null && itemId.isNotEmpty) loot.add(itemId);
        }
      }
      final leveledUp = await notifier.applyCombatResult(
        hpAfter: _playerHealth,
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
      );
      if (!mounted) return;
      final lang = ref.read(appLanguageProvider);
      setState(() {
        _log.add(
          _LogEntry(
            '${trFor(lang, 'victory_prefix')} +$goldGain ${trFor(lang, 'gold_label')}, '
            '+$xpGain XP'
            '${loot.isNotEmpty ? ", ${trFor(lang, 'loot_label')}: ${loot.join(", ")}" : ""}.',
            _LogKind.victory,
          ),
        );
      });
      if (leveledUp) {
        final newLevel = ref.read(playerSessionProvider).level;
        showLevelUpDialog(context, ref, newLevel: newLevel);
      }
    } else {
      await notifier.applyCombatResult(hpAfter: _playerMaxHealth);
      if (!mounted) return;
      setState(() {
        _log.add(_LogEntry(trFor(ref.read(appLanguageProvider), 'defeat_message'), _LogKind.defeat));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final session = ref.watch(playerSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'fight_prefix')}: ${widget.enemy['enemyName'] ?? widget.enemyId}'),
      ),
      body: diceAsync.when(
        data: (dice) => skillsAsync.when(
          data: (skills) => itemsAsync.when(
            data: (items) {
              if (!_started) {
                return _buildSetup(dice, items);
              }
              return _buildBattle(dice, skills, items, session);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('${tr(ref, 'failed_to_load_items')}: $error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${tr(ref, 'failed_to_load_skills')}: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
      ),
    );
  }

  Widget _buildSetup(Map<String, dynamic> dice, Map<String, dynamic> items) {
    final damageBonus = _equipmentDamageBonus(items);
    final armorBonus = _equipmentArmorBonus(items);
    final equippedDie =
        _selectedDiceId != null ? dice[_selectedDiceId] as Map<String, dynamic>? : null;
    final faceCount = (equippedDie?['faces'] as List?)?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.sports_martial_arts,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.enemy['enemyName']?.toString() ?? widget.enemyId,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tr(ref, 'hp_label')} $_enemyMaxHealth · ${tr(ref, 'damage_label')} $_enemyDamage '
            '(${tr(ref, 'scaled_to_level')} $_playerLevel)',
          ),
          if (damageBonus > 0 || armorBonus > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${tr(ref, 'your_equipment_prefix')}: +$damageBonus ${tr(ref, 'damage_word')}, '
              '+$armorBonus ${tr(ref, 'armor_label')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text(tr(ref, 'equipped_die_label'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (equippedDie == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(tr(ref, 'no_die_equipped')),
                subtitle: Text(tr(ref, 'equip_die_hint')),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.casino),
                title: Text(_selectedDiceId!),
                subtitle: Text('$faceCount ${tr(ref, 'faces_label')}'),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: equippedDie == null ? null : _startFight,
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(tr(ref, 'enter_battle_button')),
          ),
        ],
      ),
    );
  }

  Widget _buildBattle(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final selectedDice = _selectedDiceId != null
        ? dice[_selectedDiceId] as Map<String, dynamic>?
        : null;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 8) * decay * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _HealthBar(
                  label: tr(ref, 'you_label'),
                  current: _playerHealth,
                  max: _playerMaxHealth,
                  statLine: '⚔ ${_playerBaseDamage + _equipmentDamageBonus(items)}'
                      '  ·  🛡 ${session.baseArmor + _equipmentArmorBonus(items)}',
                ),
                if (_lastDamageTaken > 0)
                  Positioned(
                    right: 0,
                    top: -4,
                    child: AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, _) => Opacity(
                        opacity: (1 - _shakeController.value).clamp(0.0, 1.0),
                        child: Text(
                          '-$_lastDamageTaken',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _HealthBar(
              label: widget.enemy['enemyName']?.toString() ?? widget.enemyId,
              current: _enemyHealth,
              max: _enemyMaxHealth,
              statLine: '⚔ $_enemyDamage',
            ),
            if (_block > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${tr(ref, 'block_active_prefix')}: $_block',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  reverse: true,
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
            ),
            const SizedBox(height: 16),
            if (_lastFace != null) ...[
              _buildDieFaceCard(skills, items),
              const SizedBox(height: 12),
            ],
            if (_over)
              ElevatedButton(
                onPressed: () async {
                  if (!_won && ref.read(permadeathEnabledProvider)) {
                    final nodesVisited = ref.read(storyPlayProvider).history.length + 1;
                    final result = await ref.read(playerSessionProvider.notifier).applyPermadeath();
                    ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
                    ref.read(homeTabIndexProvider.notifier).state = 0;
                    if (!mounted) return;
                    await Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => DeathScreen(
                          lostItemIds: result.lostItemIds,
                          xpEarned: result.xpEarnedThisRun,
                          nodesVisited: nodesVisited,
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                    return;
                  }
                  Navigator.of(context).pop(_won);
                },
                child: Text(_won ? tr(ref, 'victory_return_button') : tr(ref, 'retreat_button')),
              )
            else ...[
              if (_awaitingDecision)
                Row(
                  children: [
                    if (_rollCount < _maxRolls) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _rolling ? null : () => _rollDice(selectedDice!, skills, items),
                          icon: const Icon(Icons.refresh),
                          label: Text('${tr(ref, 'reroll_button')} ($_rollCount/$_maxRolls)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _rolling ? null : () => _confirmRoll(skills, items),
                        icon: const Icon(Icons.check),
                        label: Text(tr(ref, 'confirm_roll_button')),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: (selectedDice == null || _rolling)
                      ? null
                      : () => _rollDice(selectedDice, skills, items),
                  icon: const Icon(Icons.casino),
                  label: Text(tr(ref, 'roll_dice_button')),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (session.potionCount > 0 && !_rolling) ? _usePotion : null,
                icon: const Icon(Icons.local_drink),
                label: Text('${tr(ref, 'potion_button_prefix')} (${session.potionCount})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The most recently rolled face, kept on screen so the player always
  /// knows what they're looking at — spinning while a roll is in flight,
  /// settled (face name, which skill it maps to if it's a Skill face, and
  /// a preview of what confirming it will do) once it lands.
  Widget _buildDieFaceCard(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final face = _lastFace!;
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    if (_rolling) {
      content = Text(tr(ref, 'rolling_label'), style: Theme.of(context).textTheme.bodySmall);
    } else {
      final totalDamage = _playerBaseDamage + _equipmentDamageBonus(items);
      final preview = resolvePlayerFace(
        face,
        _availableSkills(skills),
        totalDamage,
        language: ref.read(appLanguageProvider),
      );
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            face.faceName.isEmpty ? face.type : face.faceName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (face.type == 'Skill') ...[
            const SizedBox(height: 2),
            Text(
              '${tr(ref, 'skill_label')}: ${_effectiveSkillId(face)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.primary),
            ),
          ],
          const SizedBox(height: 2),
          Text(preview.message, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _awaitingDecision ? colorScheme.primaryContainer.withValues(alpha: 0.25) : null,
        border: Border.all(
          color: _awaitingDecision ? colorScheme.primary : colorScheme.outlineVariant,
          width: _awaitingDecision ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: _rolling
                  ? AnimatedBuilder(
                      animation: _rollController,
                      builder: (context, _) {
                        final t = _rollController.value;
                        final angle = Curves.easeOutCubic.transform(t) * 6 * pi;
                        final scale = 1 + (sin(t * pi) * 0.25);
                        return Transform.rotate(
                          angle: angle,
                          child: Transform.scale(
                            scale: scale,
                            child: Icon(Icons.casino, size: 30, color: colorScheme.primary),
                          ),
                        );
                      },
                    )
                  : Icon(_faceTypeIcon(face.type), size: 30, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.label,
    required this.current,
    required this.max,
    this.statLine,
  });

  final String label;
  final int current;
  final int max;

  /// An optional line of extra stats (e.g. "⚔ 12 · 🛡 4") shown under the bar.
  final String? statLine;

  @override
  Widget build(BuildContext context) {
    final rawRatio = max <= 0 ? 0.0 : current / max;
    final ratio = rawRatio < 0 ? 0.0 : (rawRatio > 1 ? 1.0 : rawRatio);
    final barColor = ratio > 0.5
        ? Colors.green
        : (ratio > 0.25 ? Colors.orange : Colors.red);
    const barHeight = 26.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.18),
              border: Border.all(color: barColor.withValues(alpha: 0.5)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerLeft,
                    width: constraints.maxWidth * ratio,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withValues(alpha: 0.75), barColor],
                      ),
                    ),
                  ),
                ),
                Text(
                  '$current / $max',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (statLine != null) ...[
          const SizedBox(height: 2),
          Text(statLine!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
