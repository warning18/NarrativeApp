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

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory & Equipment')),
      body: itemsAsync.when(
        data: (items) => _InventoryBody(items: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load items: $error')),
      ),
    );
  }
}

class _InventoryBody extends ConsumerWidget {
  const _InventoryBody({required this.items});

  final Map<String, dynamic> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);

    final counts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ownedIds = counts.keys.toList()..sort();
    final equippedIds = session.equippedItemIds;

    if (ownedIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Your inventory is empty. Buy or loot some gear!'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (equippedIds.isNotEmpty) ...[
          Text('Equipped', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...equippedIds.map(
            (id) => _ItemTile(
              itemId: id,
              item: items[id] as Map<String, dynamic>?,
              isEquipped: true,
              onToggle: () => ref.read(playerSessionProvider.notifier).unequipItem(id),
            ),
          ),
          const Divider(height: 32),
        ],
        Text('All Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...ownedIds.map((id) {
          final item = items[id] as Map<String, dynamic>?;
          final isEquippable = item != null && (item['isEquippable'] as bool? ?? false);
          final isEquipped = equippedIds.contains(id);
          return _ItemTile(
            itemId: id,
            item: item,
            count: counts[id],
            isEquipped: isEquipped,
            onToggle: !isEquippable
                ? null
                : () {
                    final notifier = ref.read(playerSessionProvider.notifier);
                    if (isEquipped) {
                      notifier.unequipItem(id);
                    } else {
                      notifier.equipItem(id);
                    }
                  },
          );
        }),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.itemId,
    required this.item,
    this.count,
    required this.isEquipped,
    this.onToggle,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final int? count;
  final bool isEquipped;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final itemName = item?['itemName']?.toString() ?? itemId;
    final itemType = item?['itemType']?.toString();
    final attackDamage = (item?['attackDamage'] as num?)?.toInt() ?? 0;
    final armor = (item?['armor'] as num?)?.toInt() ?? 0;

    final statsParts = <String>[
      if (itemType != null) itemType,
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
        trailing: onToggle == null
            ? null
            : OutlinedButton(
                onPressed: onToggle,
                child: Text(isEquipped ? 'Unequip' : 'Equip'),
              ),
      ),
    );
  }
}
