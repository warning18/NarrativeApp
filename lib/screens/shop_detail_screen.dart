import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
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
    final rawStockQuantities = shop['stockQuantities'];
    final stockQuantities = rawStockQuantities is Map
        ? rawStockQuantities.map(
            (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 1),
          )
        : const <String, int>{};

    return Scaffold(
      appBar: AppBar(title: Text(shop['shopName']?.toString() ?? shopId)),
      body: itemsAsync.when(
        data: (items) => diceAsync.when(
          data: (dice) {
            if (stock.isEmpty && diceStock.isEmpty) {
              return Center(child: Text(tr(ref, 'shop_no_stock')));
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
                  final stockLimit = stockQuantities[itemId] ?? 1;
                  final purchased = session.shopPurchaseCounts['$shopId::$itemId'] ?? 0;
                  final remaining = stockLimit - purchased;
                  final soldOut = remaining <= 0;
                  final isEquippable = item?['isEquippable'] as bool? ?? false;
                  final equipSlot = item?['equipSlot']?.toString();
                  return Card(
                    child: ListTile(
                      leading: Icon(itemTypeIcon(itemType)),
                      title: Text(itemName),
                      subtitle: Text(
                        soldOut
                            ? tr(ref, 'sold_out_label')
                            : '$cost ${tr(ref, 'gold_label')} · $remaining ${tr(ref, 'left_suffix')}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: (!canAfford || soldOut)
                            ? null
                            : () async {
                                await ref
                                    .read(playerSessionProvider.notifier)
                                    .buyItem(shopId, itemId, cost, stockLimit);
                                if (!context.mounted) return;
                                final lang = ref.read(appLanguageProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${trFor(lang, 'bought_prefix')} $itemName '
                                      '${trFor(lang, 'for_label')} $cost ${trFor(lang, 'gold_label')}',
                                    ),
                                    action: isEquippable
                                        ? SnackBarAction(
                                            label: trFor(lang, 'equip_button'),
                                            onPressed: () => ref
                                                .read(playerSessionProvider.notifier)
                                                .equipItem(itemId, slot: equipSlot, items: items),
                                          )
                                        : null,
                                  ),
                                );
                              },
                        child: Text(tr(ref, 'buy_button')),
                      ),
                    ),
                  );
                }),
                if (diceStock.isNotEmpty) ...[
                  if (stock.isNotEmpty) const Divider(height: 32),
                  Text(tr(ref, 'dice_label'), style: Theme.of(context).textTheme.titleMedium),
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
                        subtitle: Text(
                          owned ? tr(ref, 'owned_label') : '$cost ${tr(ref, 'gold_label')}',
                        ),
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
                                        final lang = ref.read(appLanguageProvider);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${trFor(lang, 'bought_prefix')} $diceId '
                                              '${trFor(lang, 'for_label')} $cost '
                                              '${trFor(lang, 'gold_label')}',
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(tr(ref, 'buy_button')),
                              ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_items')}: $error')),
      ),
    );
  }
}
