import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId, required this.shop});

  final String shopId;
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final session = ref.watch(playerSessionProvider);
    final stock =
        (shop['initialStock'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final diceStock =
        (shop['diceStock'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(shop['shopName']?.toString() ?? shopId)),
      body: itemsAsync.when(
        data: (items) => diceAsync.when(
          data: (dice) {
            if (stock.isEmpty && diceStock.isEmpty) {
              return const Center(child: Text('This shop has no stock configured.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...stock.map((itemId) {
                  final item = items[itemId] as Map<String, dynamic>?;
                  final itemName = item?['itemName']?.toString() ?? itemId;
                  final itemType = item?['itemType']?.toString();
                  final cost = (item?['cost'] as num?)?.toInt() ?? 0;
                  final canAfford = session.gold >= cost;
                  return Card(
                    child: ListTile(
                      leading: Icon(itemTypeIcon(itemType)),
                      title: Text(itemName),
                      subtitle: Text('$cost gold'),
                      trailing: ElevatedButton(
                        onPressed: !canAfford
                            ? null
                            : () async {
                                await ref
                                    .read(playerSessionProvider.notifier)
                                    .buyItem(itemId, cost);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Bought $itemName for $cost gold')),
                                );
                              },
                        child: const Text('Buy'),
                      ),
                    ),
                  );
                }),
                if (diceStock.isNotEmpty) ...[
                  if (stock.isNotEmpty) const Divider(height: 32),
                  Text('Dice', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...diceStock.map((diceId) {
                    final die = dice[diceId] as Map<String, dynamic>?;
                    final cost = (die?['cost'] as num?)?.toInt() ?? 0;
                    final owned = session.ownedDiceIds.contains(diceId);
                    final canAfford = session.gold >= cost;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.casino),
                        title: Text(diceId),
                        subtitle: Text(owned ? 'Owned' : '$cost gold'),
                        trailing: owned
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: !canAfford
                                    ? null
                                    : () async {
                                        await ref
                                            .read(playerSessionProvider.notifier)
                                            .buyDice(diceId, cost);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Bought $diceId for $cost gold'),
                                          ),
                                        );
                                      },
                                child: const Text('Buy'),
                              ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Failed to load dice: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load items: $error')),
      ),
    );
  }
}
