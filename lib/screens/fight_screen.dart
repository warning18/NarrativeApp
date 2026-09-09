import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';

const int _potionHealAmount = 30;

class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({super.key, required this.enemyId, required this.enemy});

  final String enemyId;
  final Map<String, dynamic> enemy;

  @override
  ConsumerState<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends ConsumerState<FightScreen> {
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

  String? _selectedDiceId;

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
  }

  void _startFight() {
    setState(() {
      _started = true;
      _log.add('The fight begins! ${widget.enemy['enemyName']} has $_enemyMaxHealth HP.');
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
    final result = resolvePlayerFace(face, _availableSkills(skills), totalDamage);

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
    );
    final session = ref.read(playerSessionProvider);
    final totalArmor = session.baseArmor + _equipmentArmorBonus(items);
    final damageTaken = max(0, move.damage - _block - totalArmor);

    setState(() {
      _playerHealth = max(0, _playerHealth - damageTaken);
      _block = 0;
      _log.add('${move.message} You take $damageTaken damage.');
    });

    if (_playerHealth <= 0) {
      _finishFight(won: false);
    }
  }

  void _usePotion() {
    final session = ref.read(playerSessionProvider);
    if (session.potionCount <= 0 || _over) return;
    ref.read(playerSessionProvider.notifier).consumePotion();
    setState(() {
      _playerHealth = min(_playerMaxHealth, _playerHealth + _potionHealAmount);
      _log.add('You drink a potion and recover $_potionHealAmount HP.');
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
      setState(() {
        _log.add(
          'Victory! +$goldGain gold, +$xpGain XP'
          '${loot.isNotEmpty ? ", loot: ${loot.join(", ")}" : ""}.',
        );
      });
    } else {
      await notifier.applyCombatResult(hpAfter: _playerMaxHealth);
      if (!mounted) return;
      setState(() {
        _log.add('You are overwhelmed, but crawl away to recover.');
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
      appBar: AppBar(title: Text('Fight: ${widget.enemy['enemyName'] ?? widget.enemyId}')),
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
            error: (error, stack) => Center(child: Text('Failed to load items: $error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Failed to load skills: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load dice: $error')),
      ),
    );
  }

  Widget _buildSetup(Map<String, dynamic> dice, Map<String, dynamic> items) {
    final damageBonus = _equipmentDamageBonus(items);
    final armorBonus = _equipmentArmorBonus(items);
    final equippedDie =
        _selectedDiceId != null ? dice[_selectedDiceId] as Map<String, dynamic>? : null;
    final faceCount = (equippedDie?['faces'] as List?)?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.enemy['enemyName']?.toString() ?? widget.enemyId,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('HP $_enemyMaxHealth · Damage $_enemyDamage (scaled to level $_playerLevel)'),
          if (damageBonus > 0 || armorBonus > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Your equipment: +$damageBonus damage, +$armorBonus armor',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text('Equipped Die', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (equippedDie == null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.error_outline),
                title: Text('No die equipped'),
                subtitle: Text('Equip a die from Inventory before fighting.'),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.casino),
                title: Text(_selectedDiceId!),
                subtitle: Text('$faceCount faces'),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: equippedDie == null ? null : _startFight,
            icon: const Icon(Icons.sports_martial_arts),
            label: const Text('Enter Battle'),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HealthBar(label: 'You', current: _playerHealth, max: _playerMaxHealth),
          const SizedBox(height: 8),
          _HealthBar(
            label: widget.enemy['enemyName']?.toString() ?? widget.enemyId,
            current: _enemyHealth,
            max: _enemyMaxHealth,
          ),
          if (_block > 0) ...[
            const SizedBox(height: 8),
            Text('Block active: $_block', style: Theme.of(context).textTheme.bodySmall),
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
              onPressed: () => Navigator.of(context).pop(_won),
              child: Text(_won ? 'Victory! Return' : 'Retreat'),
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
                    label: const Text('Roll Dice'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: session.potionCount > 0 ? _usePotion : null,
                  icon: const Icon(Icons.local_drink),
                  label: Text('Potion (${session.potionCount})'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.label, required this.current, required this.max});

  final String label;
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final rawRatio = max <= 0 ? 0.0 : current / max;
    final ratio = rawRatio < 0 ? 0.0 : (rawRatio > 1 ? 1.0 : rawRatio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label: $current / $max'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 8),
        ),
      ],
    );
  }
}
