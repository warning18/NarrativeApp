import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/spells.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';

enum _ShopSort { nameAsc, priceLow, priceHigh, stockLeft }

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId, required this.shop});

  final String shopId;
  final Map<String, dynamic> shop;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  String? _typeFilter;
  _ShopSort _sort = _ShopSort.nameAsc;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    // Spells are only needed to describe and gate spellbooks; a table
    // that hasn't loaded yet just means those tiles say nothing extra.
    final spells =
        parseSpells(ref.watch(gameDbProvider(spellsSchema)).value ?? const {});
    final professions = professionsAsync.value ?? const <String, dynamic>{};
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final stock = (widget.shop['initialStock'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final diceStock = (widget.shop['diceStock'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final rawStockQuantities = widget.shop['stockQuantities'];
    final stockQuantities = rawStockQuantities is Map
        ? rawStockQuantities.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 1),
          )
        : const <String, int>{};

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.shop['shopName']?.toString() ?? widget.shopId)),
      body: itemsAsync.when(
        data: (items) => diceAsync.when(
          data: (dice) {
            if (stock.isEmpty && diceStock.isEmpty) {
              return Center(child: Text(tr(ref, 'shop_no_stock')));
            }

            int remainingFor(String itemId) {
              final limit = stockQuantities[itemId] ?? 1;
              final purchased =
                  session.shopPurchaseCounts['${widget.shopId}::$itemId'] ?? 0;
              return limit - purchased;
            }

            String nameFor(String itemId) =>
                (items[itemId] as Map<String, dynamic>?)?['itemName']
                    ?.toString() ??
                itemId;

            int costFor(String itemId) =>
                ((items[itemId] as Map<String, dynamic>?)?['cost'] as num?)
                    ?.toInt() ??
                0;

            final availableTypes = stock
                .map((id) => (items[id] as Map<String, dynamic>?)?['itemType']
                    ?.toString())
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();

            final filteredStock = _typeFilter == null
                ? stock
                : stock.where((itemId) {
                    final item = items[itemId] as Map<String, dynamic>?;
                    return item?['itemType']?.toString() == _typeFilter;
                  }).toList();

            final sortedStock = [...filteredStock];
            switch (_sort) {
              case _ShopSort.nameAsc:
                sortedStock.sort((a, b) => nameFor(a).compareTo(nameFor(b)));
                break;
              case _ShopSort.priceLow:
                sortedStock.sort((a, b) => costFor(a).compareTo(costFor(b)));
                break;
              case _ShopSort.priceHigh:
                sortedStock.sort((a, b) => costFor(b).compareTo(costFor(a)));
                break;
              case _ShopSort.stockLeft:
                sortedStock
                    .sort((a, b) => remainingFor(b).compareTo(remainingFor(a)));
                break;
            }

            return Column(
              children: [
                if (stock.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sort,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<_ShopSort>(
                                  isExpanded: true,
                                  value: _sort,
                                  items: [
                                    DropdownMenuItem(
                                      value: _ShopSort.nameAsc,
                                      child: Text(tr(ref, 'sort_name')),
                                    ),
                                    DropdownMenuItem(
                                      value: _ShopSort.priceLow,
                                      child: Text(tr(ref, 'sort_price_low')),
                                    ),
                                    DropdownMenuItem(
                                      value: _ShopSort.priceHigh,
                                      child: Text(tr(ref, 'sort_price_high')),
                                    ),
                                    DropdownMenuItem(
                                      value: _ShopSort.stockLeft,
                                      child: Text(tr(ref, 'sort_stock')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _sort = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (availableTypes.length > 1) ...[
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(tr(ref, 'filter_all')),
                                    selected: _typeFilter == null,
                                    onSelected: (_) =>
                                        setState(() => _typeFilter = null),
                                  ),
                                ),
                                ...availableTypes.map(
                                  (type) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      avatar:
                                          Icon(itemTypeIcon(type), size: 16),
                                      label: Text(type),
                                      selected: _typeFilter == type,
                                      onSelected: (_) =>
                                          setState(() => _typeFilter = type),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 20),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (sortedStock.isEmpty && stock.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: Text(tr(ref, 'shop_filtered_empty'))),
                        ),
                      ...sortedStock.map((itemId) {
                        final item = items[itemId] as Map<String, dynamic>?;
                        final itemName = nameFor(itemId);
                        final itemType = item?['itemType']?.toString();
                        final cost = costFor(itemId);
                        final canAfford = session.gold >= cost;
                        final stockLimit = stockQuantities[itemId] ?? 1;
                        final remaining = remainingFor(itemId);
                        final soldOut = remaining <= 0;
                        final isEquippable =
                            item?['isEquippable'] as bool? ?? false;
                        final equipSlot = item?['equipSlot']?.toString();
                        // A spellbook: say which spell it teaches, and grey
                        // it out for a spell already known or one of
                        // another profession's.
                        final taughtSpellId = spellbookSpellIdFor(item);
                        final spell = taughtSpellId == null
                            ? null
                            : spells[taughtSpellId];
                        String? spellNote;
                        var spellLocked = false;
                        if (spell != null) {
                          if (session.knownSpellIds.contains(spell.id)) {
                            spellNote = tr(ref, 'spell_known_label');
                            spellLocked = true;
                          } else if (!canLearnSpell(spell,
                              professionId: session.professionId,
                              knownSpellIds: session.knownSpellIds)) {
                            final professionName = (professions[
                                        spell.professionId]
                                    as Map<String, dynamic>?)?['professionName']
                                ?.toString();
                            spellNote =
                                '${tr(ref, 'spell_profession_only_prefix')} '
                                '${professionName ?? spell.professionId}';
                            spellLocked = true;
                          } else {
                            spellNote =
                                '${spell.nameFor(lang)} · ${spell.manaCost} '
                                '${tr(ref, 'mana_label')} · '
                                '${spell.descriptionFor(lang)}';
                          }
                        }
                        final priceLine = soldOut
                            ? tr(ref, 'sold_out_label')
                            : '$cost ${tr(ref, 'gold_label')} · $remaining ${tr(ref, 'left_suffix')}';
                        return Card(
                          child: ListTile(
                            leading: ItemPixelIcon(itemId, itemType),
                            title: Text(itemName),
                            subtitle: Text(
                              spellNote == null
                                  ? priceLine
                                  : '$priceLine\n$spellNote',
                            ),
                            isThreeLine: spellNote != null,
                            trailing: ElevatedButton(
                              onPressed: (!canAfford || soldOut || spellLocked)
                                  ? null
                                  : () async {
                                      await ref
                                          .read(playerSessionProvider.notifier)
                                          .buyItem(widget.shopId, itemId, cost,
                                              stockLimit,
                                              item: item);
                                      if (!context.mounted) return;
                                      showImmersiveNotice(
                                        context,
                                        icon: spell != null
                                            ? Icons.auto_stories
                                            : Icons.shopping_bag_outlined,
                                        message: spell != null
                                            ? '${trFor(lang, 'spell_learned_prefix')} '
                                                '${spell.nameFor(lang)}'
                                            : '${trFor(lang, 'bought_prefix')} $itemName '
                                                '${trFor(lang, 'for_label')} $cost ${trFor(lang, 'gold_label')}',
                                        actionLabel: isEquippable
                                            ? trFor(lang, 'equip_button')
                                            : null,
                                        onAction: isEquippable
                                            ? () => ref
                                                .read(playerSessionProvider
                                                    .notifier)
                                                .equipItem(itemId,
                                                    slot: equipSlot,
                                                    items: items)
                                            : null,
                                      );
                                    },
                              child: Text(tr(ref, 'buy_button')),
                            ),
                          ),
                        );
                      }),
                      if (diceStock.isNotEmpty) ...[
                        if (sortedStock.isNotEmpty) const Divider(height: 32),
                        Text(tr(ref, 'dice_label'),
                            style: Theme.of(context).textTheme.titleMedium),
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
                                owned
                                    ? tr(ref, 'owned_label')
                                    : '$cost ${tr(ref, 'gold_label')}',
                              ),
                              trailing: owned
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : ElevatedButton(
                                      onPressed: !canAfford
                                          ? null
                                          : () async {
                                              await ref
                                                  .read(playerSessionProvider
                                                      .notifier)
                                                  .buyDice(diceId, cost);
                                              if (!context.mounted) return;
                                              showImmersiveNotice(
                                                context,
                                                icon: Icons.casino,
                                                message:
                                                    '${trFor(lang, 'bought_prefix')} $diceId '
                                                    '${trFor(lang, 'for_label')} $cost '
                                                    '${trFor(lang, 'gold_label')}',
                                              );
                                            },
                                      child: Text(tr(ref, 'buy_button')),
                                    ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(tr(ref, 'continue_button')),
        ),
      ),
    );
  }
}
