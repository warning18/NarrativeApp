import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId, required this.shop});

  final String shopId;
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final session = ref.watch(playerSessionProvider);
    final stock =
        (shop['initialStock'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(shop['shopName']?.toString() ?? shopId)),
      body: itemsAsync.when(
        data: (items) {
          if (stock.isEmpty) {
            return const Center(child: Text('This shop has no stock configured.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: stock.map((itemId) {
              final item = items[itemId] as Map<String, dynamic>?;
              final itemName = item?['itemName']?.toString() ?? itemId;
              final cost = (item?['cost'] as num?)?.toInt() ?? 0;
              final canAfford = session.gold >= cost;
              return Card(
                child: ListTile(
                  title: Text(itemName),
                  subtitle: Text('$cost gold'),
                  trailing: ElevatedButton(
                    onPressed: !canAfford
                        ? null
                        : () => ref.read(playerSessionProvider.notifier).buyItem(itemId, cost),
                    child: const Text('Buy'),
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load items: $error')),
      ),
    );
  }
}
