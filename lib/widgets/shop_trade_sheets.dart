import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'immersive_notice.dart';
import 'item_stats.dart';

/// Opens the pack at [shopId] to sell what nobody wears.
Future<void> showSellSheet(BuildContext context, {required String shopId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _SellSheet(shopId: shopId),
    ),
  );
}

/// Opens the forge's recipes at [shopId].
Future<void> showForgeSheet(BuildContext context, {required String shopId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _ForgeSheet(shopId: shopId),
    ),
  );
}

String _nameOf(Map<String, dynamic>? item, String id, AppLanguage lang) {
  final fr = item?['itemName_fr']?.toString() ?? '';
  if (lang == AppLanguage.fr && fr.isNotEmpty) return fr;
  return item?['itemName']?.toString() ?? id;
}

/// Everything in the shared pack, one row per item: a copy nobody wears
/// sells for [sellPriceFor]; one sold where it is stocked goes back on
/// the shelf. Quest items stay with the party.
class _SellSheet extends ConsumerWidget {
  const _SellSheet({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ??
        const <String, dynamic>{};
    final lang = ref.watch(appLanguageProvider);
    final counts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ids = counts.keys
        .where((id) => canSellItem(items[id] as Map<String, dynamic>?))
        .toList()
      ..sort((a, b) => _nameOf(items[a] as Map<String, dynamic>?, a, lang)
          .compareTo(_nameOf(items[b] as Map<String, dynamic>?, b, lang)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '${tr(ref, 'sell_title')} · ${session.gold} ${tr(ref, 'gold_label')}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ids.isEmpty
              ? Center(child: Text(tr(ref, 'sell_nothing')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final id in ids)
                      _sellRow(
                          context,
                          ref,
                          id,
                          items[id] as Map<String, dynamic>?,
                          counts[id]!,
                          session,
                          lang),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sellRow(
    BuildContext context,
    WidgetRef ref,
    String id,
    Map<String, dynamic>? item,
    int owned,
    PlayerSession session,
    AppLanguage lang,
  ) {
    final free = session.freeCopiesOf(id, wearerId: '');
    final price = sellPriceFor(item);
    final name = _nameOf(item, id, lang);
    return Card(
      child: ListTile(
        leading: ItemPixelIcon(id, item?['itemType']?.toString()),
        title: Text(owned > 1 ? '$name ×$owned' : name),
        subtitle: Text(free > 0
            ? '$price ${trFor(lang, 'gold_label')}'
            : trFor(lang, 'sell_worn_note')),
        trailing: FilledButton.tonal(
          onPressed: free <= 0
              ? null
              : () async {
                  final sold = await ref
                      .read(playerSessionProvider.notifier)
                      .sellItem(id, price: price, shopId: shopId);
                  if (!sold || !context.mounted) return;
                  showImmersiveNotice(
                    context,
                    icon: Icons.sell_outlined,
                    message: '${trFor(lang, 'sold_prefix')} $name '
                        '${trFor(lang, 'for_label')} $price '
                        '${trFor(lang, 'gold_label')}',
                  );
                },
          child: Text(trFor(lang, 'sell_button')),
        ),
      ),
    );
  }
}

/// The pieces forged at this shop (items.json `craftedAt`): each with its
/// stats, what it takes and whether the pack holds it.
class _ForgeSheet extends ConsumerWidget {
  const _ForgeSheet({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final notifier = ref.read(playerSessionProvider.notifier);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ??
        const <String, dynamic>{};
    final lang = ref.watch(appLanguageProvider);
    final recipes = recipesAt(shopId, items);

    int carried(String id) =>
        session.inventoryItemIds.where((i) => i == id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            '${tr(ref, 'forge_title')} · ${session.gold} ${tr(ref, 'gold_label')}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(tr(ref, 'forge_hint'),
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (final id in recipes)
                Builder(builder: (context) {
                  final item = items[id] as Map<String, dynamic>?;
                  final name = _nameOf(item, id, lang);
                  final gold = (item?['craftGold'] as num?)?.toInt() ?? 0;
                  final needs = [
                    for (final m in craftMaterialsFor(item).entries)
                      '${_nameOf(items[m.key] as Map<String, dynamic>?, m.key, lang)} '
                          '${carried(m.key)}/${m.value}',
                    '$gold ${trFor(lang, 'gold_label')}',
                  ].join(' · ');
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ItemPixelIcon(id, item?['itemType']?.toString()),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name,
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                              ),
                              FilledButton(
                                onPressed: !notifier.canCraft(item)
                                    ? null
                                    : () async {
                                        final made =
                                            await notifier.craftItem(id, item);
                                        if (!made || !context.mounted) return;
                                        showImmersiveNotice(
                                          context,
                                          icon: Icons.hardware,
                                          message:
                                              '${trFor(lang, 'forged_prefix')} $name',
                                        );
                                      },
                                child: Text(trFor(lang, 'forge_button')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ItemStatChips(
                              item: item, language: lang, compact: true),
                          const SizedBox(height: 4),
                          Text('${trFor(lang, 'forge_needs_label')}: $needs',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
