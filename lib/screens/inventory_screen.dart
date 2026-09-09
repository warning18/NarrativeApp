import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final diceAsync = ref.watch(gameDbProvider(diceSchema));

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory & Equipment')),
      body: itemsAsync.when(
        data: (items) => diceAsync.when(
          data: (dice) => _InventoryBody(items: items, dice: dice),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Failed to load dice: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load items: $error')),
      ),
    );
  }
}

class _InventoryBody extends ConsumerWidget {
  const _InventoryBody({required this.items, required this.dice});

  final Map<String, dynamic> items;
  final Map<String, dynamic> dice;

  String? _equippedInSlot(List<String> equippedIds, String slot) {
    for (final id in equippedIds) {
      final item = items[id] as Map<String, dynamic>?;
      if ((item?['equipSlot']?.toString() ?? '') == slot) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);

    final counts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ownedIds = counts.keys.toList()..sort();
    final equippedIds = session.equippedItemIds;

    final equippedDiceId = session.equippedDiceId;
    final equippedDie = equippedDiceId != null ? dice[equippedDiceId] as Map<String, dynamic>? : null;
    final ownedDiceIds = session.ownedDiceIds.where(dice.containsKey).toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Equipment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('Dice'),
            subtitle: Text(equippedDie != null ? equippedDiceId! : '(none equipped)'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Choose die',
              onPressed: ownedDiceIds.isEmpty
                  ? null
                  : () => _pickDice(context, ref, ownedDiceIds, equippedDiceId),
            ),
          ),
        ),
        ...equipSlotOptions.map((slot) {
          final equippedId = _equippedInSlot(equippedIds, slot);
          final equippedItem = equippedId != null ? items[equippedId] as Map<String, dynamic>? : null;
          final candidates = ownedIds.where((id) {
            final item = items[id] as Map<String, dynamic>?;
            return (item?['isEquippable'] as bool? ?? false) &&
                (item?['equipSlot']?.toString() ?? '') == slot;
          }).toList();

          return Card(
            child: ListTile(
              leading: Icon(itemTypeIcon(equippedItem?['itemType']?.toString())),
              title: Text(slot),
              subtitle: Text(equippedItem?['itemName']?.toString() ?? '(empty)'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (equippedId != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Unequip',
                      onPressed: () =>
                          ref.read(playerSessionProvider.notifier).unequipItem(equippedId),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Choose item',
                    onPressed: candidates.isEmpty
                        ? null
                        : () => _pickForSlot(context, ref, slot, candidates, equippedId),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 32),
        Text('All Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (ownedIds.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Your inventory is empty. Buy or loot some gear!'),
          )
        else
          ...ownedIds.map((id) {
            final item = items[id] as Map<String, dynamic>?;
            final isEquipped = equippedIds.contains(id);
            return _ItemTile(itemId: id, item: item, count: counts[id], isEquipped: isEquipped);
          }),
      ],
    );
  }

  Future<void> _pickDice(
    BuildContext context,
    WidgetRef ref,
    List<String> ownedDiceIds,
    String? currentlyEquippedId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: ownedDiceIds.map((id) {
            final faceCount = (dice[id] as Map<String, dynamic>?)?['faces'] is List
                ? ((dice[id] as Map<String, dynamic>)['faces'] as List).length
                : 0;
            return ListTile(
              leading: const Icon(Icons.casino),
              title: Text(id),
              subtitle: Text('$faceCount faces'),
              trailing: id == currentlyEquippedId ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(playerSessionProvider.notifier).equipDice(id);
                Navigator.of(sheetContext).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickForSlot(
    BuildContext context,
    WidgetRef ref,
    String slot,
    List<String> candidates,
    String? currentlyEquippedId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: candidates.map((id) {
            final item = items[id] as Map<String, dynamic>?;
            final itemName = item?['itemName']?.toString() ?? id;
            return ListTile(
              leading: Icon(itemTypeIcon(item?['itemType']?.toString())),
              title: Text(itemName),
              trailing: id == currentlyEquippedId ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(playerSessionProvider.notifier).equipItem(id, slot: slot, items: items);
                Navigator.of(sheetContext).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.itemId,
    required this.item,
    this.count,
    required this.isEquipped,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final int? count;
  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    final itemName = item?['itemName']?.toString() ?? itemId;
    final itemType = item?['itemType']?.toString();
    final equipSlot = item?['equipSlot']?.toString();
    final attackDamage = (item?['attackDamage'] as num?)?.toInt() ?? 0;
    final armor = (item?['armor'] as num?)?.toInt() ?? 0;

    final statsParts = <String>[
      if (itemType != null) itemType,
      if (isEquipped && equipSlot != null && equipSlot.isNotEmpty) 'Equipped: $equipSlot',
      if (attackDamage > 0) 'ATK +$attackDamage',
      if (armor > 0) 'ARM +$armor',
      if (count != null && count! > 1) 'x$count',
    ];

    return Card(
      color: isEquipped ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(itemTypeIcon(itemType)),
        title: Text(itemName),
        subtitle: Text(statsParts.join(' · ')),
      ),
    );
  }
}
