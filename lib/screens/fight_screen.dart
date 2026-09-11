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
import 'death_screen.dart';

const int _potionHealAmount = 30;

class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({super.key, required this.enemyId, required this.enemy});

  final String enemyId;
  final Map<String, dynamic> enemy;

  @override
  ConsumerState<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends ConsumerState<FightScreen> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<String> _log = [];

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

  late final AnimationController _shakeController;

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
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
        '${trFor(lang, 'fight_begins_prefix')} ${widget.enemy['enemyName']} '
        '${trFor(lang, 'has_label')} $_enemyMaxHealth ${trFor(lang, 'hp_label')}.',
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

  void _takePlayerTurn(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    if (_over) return;
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
    final totalDamage = _playerBaseDamage + _equipmentDamageBonus(items);
    final result = resolvePlayerFace(
      face,
      _availableSkills(skills),
      totalDamage,
      language: ref.read(appLanguageProvider),
    );

    setState(() {
      _enemyHealth = max(0, _enemyHealth - result.damageDealt);
      _playerHealth = min(_playerMaxHealth, _playerHealth + result.healingDone);
      _block = result.blockAmount;
      _log.add(result.message);
    });

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
        '${move.message} ${trFor(lang, 'you_take_damage_prefix')} $damageTaken '
        '${trFor(lang, 'damage_word')}.',
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
        '${trFor(lang, 'drink_potion_prefix')} $_potionHealAmount ${trFor(lang, 'hp_label')}.',
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
      await notifier.applyCombatResult(
        hpAfter: _playerHealth,
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
      );
      if (!mounted) return;
      final lang = ref.read(appLanguageProvider);
      setState(() {
        _log.add(
          '${trFor(lang, 'victory_prefix')} +$goldGain ${trFor(lang, 'gold_label')}, '
          '+$xpGain XP'
          '${loot.isNotEmpty ? ", ${trFor(lang, 'loot_label')}: ${loot.join(", ")}" : ""}.',
        );
      });
    } else {
      await notifier.applyCombatResult(hpAfter: _playerMaxHealth);
      if (!mounted) return;
      setState(() {
        _log.add(trFor(ref.read(appLanguageProvider), 'defeat_message'));
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
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(_log[_log.length - 1 - index]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_over)
              ElevatedButton(
                onPressed: () async {
                  if (!_won && ref.read(permadeathEnabledProvider)) {
                    final nodesVisited = ref.read(storyPlayProvider).history.length + 1;
                    final result = await ref.read(playerSessionProvider.notifier).applyPermadeath();
                    ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
                    ref.read(homeTabIndexProvider.notifier).state = 0;
                    if (!context.mounted) return;
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
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedDice == null
                          ? null
                          : () => _takePlayerTurn(selectedDice, skills, items),
                      icon: const Icon(Icons.casino),
                      label: Text(tr(ref, 'roll_dice_button')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: session.potionCount > 0 ? _usePotion : null,
                    icon: const Icon(Icons.local_drink),
                    label: Text('${tr(ref, 'potion_button_prefix')} (${session.potionCount})'),
                  ),
                ],
              ),
          ],
        ),
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
              color: barColor.withOpacity(0.18),
              border: Border.all(color: barColor.withOpacity(0.5)),
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
                        colors: [barColor.withOpacity(0.75), barColor],
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
