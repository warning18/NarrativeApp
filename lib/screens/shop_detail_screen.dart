import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/gear_effects.dart';
import '../combat/dice_faces.dart';
import '../combat/spells.dart';
import '../data/chapter_conditions.dart';
import '../data/factions.dart';
import '../data/item_origin_here.dart';
import '../data/shop_pricing.dart';
import '../data/shop_stock.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/item_stats.dart';
import '../widgets/dice_smithing_sheet.dart';
import '../widgets/shop_trade_sheets.dart';
import 'inventory_screen.dart' show requirementSummary;
import '../widgets/player_stats_bar.dart';
import '../widgets/moments.dart';

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
    final itemsAsync = ref.watch(localizedDbProvider(itemsSchema));
    final diceAsync = ref.watch(localizedDbProvider(diceSchema));
    final professionsAsync = ref.watch(localizedDbProvider(professionsSchema));
    // Spells are only needed to describe and gate spellbooks; a table
    // that hasn't loaded yet just means those tiles say nothing extra.
    final spells = parseSpells(
        ref.watch(localizedDbProvider(spellsSchema)).value ?? const {});
    final professions = professionsAsync.value ?? const <String, dynamic>{};
    final races = ref.watch(localizedDbProvider(racesSchema)).value ??
        const <String, dynamic>{};
    final session = ref.watch(playerSessionProvider);
    final chapter = ref.watch(reachedChapterProvider);
    // The chapter's condition may raise or lower every price (see
    // chapter_conditions.dart).
    final condition = ref.watch(chapterConditionProvider);
    final priceFactor = condition?.shopPrice ?? 1.0;
    final lang = ref.watch(appLanguageProvider);
    // A faction's shop prices by the character's standing with them, and
    // won't trade with someone it hunts (v1.193).
    final clans = ref.watch(clanDataProvider);
    final faction = clans.faction(shopFactionId(widget.shop));
    final tier = faction == null
        ? null
        : ref.watch(politicsProvider).tierOf(faction.id, clans);
    final refuses = shopRefusesTrade(tier);
    final itemSets = parseItemSets(
        ref.watch(localizedDbProvider(itemSetsSchema)).value ?? {});
    // The shelf: the stock, or a wandering shop's draw for the chapter
    // (v1.197, see shop_stock.dart).
    final stock = shopStockWithAhead(widget.shop,
        chapter: chapter, items: itemsAsync.value ?? const {});
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

    final forges = recipesAt(widget.shopId,
            ref.watch(localizedDbProvider(itemsSchema)).value ?? const {})
        .isNotEmpty;
    return TutorialTrigger(
      topic: TutorialTopic.shop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.shop['shopName']?.toString() ?? widget.shopId),
          actions: [
            const GoldBadge(),
            if (forges && !refuses)
              IconButton(
                icon: const Icon(Icons.hardware_outlined),
                tooltip: tr(ref, 'forge_title'),
                onPressed: () => showForgeSheet(context, shopId: widget.shopId),
              ),
            // The Hammersmith works the party's dice too (v1.182).
            if (forges && !refuses)
              IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: tr(ref, 'smith_open_button'),
                onPressed: () => showDiceSmithingSheet(context),
              ),
            if (!refuses)
              IconButton(
                icon: const Icon(Icons.sell_outlined),
                tooltip: tr(ref, 'sell_title'),
                onPressed: () => showSellSheet(context, shopId: widget.shopId),
              ),
          ],
        ),
        body: itemsAsync.when(
          data: (items) => diceAsync.when(
            data: (dice) {
              if (stock.isEmpty && diceStock.isEmpty) {
                return Center(child: Text(tr(ref, 'shop_no_stock')));
              }

              // Potions and scrolls restock each chapter; gear doesn't.
              String stockKey(String itemId) =>
                  stockKeyFor(widget.shopId, itemId,
                      itemType:
                          (items[itemId] as Map<String, dynamic>?)?['itemType']
                              ?.toString(),
                      chapter: chapter);

              int remainingFor(String itemId) {
                final limit = stockQuantities[itemId] ?? 1;
                final purchased =
                    session.shopPurchaseCounts[stockKey(itemId)] ?? 0;
                return limit - purchased;
              }

              String nameFor(String itemId) =>
                  (items[itemId] as Map<String, dynamic>?)?['itemName']
                      ?.toString() ??
                  itemId;

              // Listed price, less the buyer's Charisma discount, at the
              // faction's rate.
              int costFor(String itemId) => conditionedPrice(
                  factionPriceFor(
                          shopPriceFor(
                              ((items[itemId] as Map<String, dynamic>?)?['cost']
                                          as num?)
                                      ?.toInt() ??
                                  0,
                              session.charisma),
                          tier) ??
                      0,
                  priceFactor);

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
                  sortedStock.sort(
                      (a, b) => remainingFor(b).compareTo(remainingFor(a)));
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
                          _KeeperStrip(
                              shopId: widget.shopId,
                              shop: widget.shop,
                              tier: tier,
                              language: lang),
                          if (faction != null && tier != null)
                            _FactionPriceLine(
                                faction: faction, tier: tier, language: lang),
                          if (condition != null && priceFactor != 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                key: const ValueKey('shop_condition_line'),
                                children: [
                                  Icon(
                                    priceFactor > 1
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 18,
                                    color: priceFactor > 1
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tr(ref, 'condition_shop_line')
                                          .replaceAll(
                                              '{name}',
                                              condition.nameFor(
                                                  lang == AppLanguage.fr))
                                          .replaceAll('{p}',
                                              percentChange(priceFactor)),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                          const SizedBox(height: 6),
                          Text(
                            tr(ref, 'shop_details_hint'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                          ),
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
                              final professionName =
                                  (professions[spell.professionId] as Map<
                                          String, dynamic>?)?['professionName']
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
                          // What the player wears in this item's slot, so the
                          // row can show at a glance whether it is an upgrade.
                          final wornId = equippedCounterpart(
                              itemId, item, session.equippedItemIds, items);
                          final worn = wornId == null
                              ? null
                              : items[wornId] as Map<String, dynamic>?;
                          final wornName =
                              worn?['itemName']?.toString() ?? wornId;
                          final meetsStats = meetsItemStatRequirement(
                            item,
                            strength: session.strength,
                            dexterity: session.dexterity,
                            constitution: session.constitution,
                            intelligence: session.intelligence,
                          );
                          final meetsAlignment =
                              meetsItemAlignment(item, session.alignmentLabel);
                          final canWear = isEquippable &&
                              (equipSlot ?? '').isNotEmpty &&
                              meetsStats &&
                              meetsAlignment;
                          final unmetRequirement = meetsStats
                              ? null
                              : requirementSummary(item, lang);
                          final wearing =
                              session.equippedItemIds.contains(itemId);
                          final set = setForItem(itemId, item, itemSets);
                          final canBuy =
                              canAfford && !soldOut && !spellLocked && !refuses;

                          Future<void> buy() async {
                            await ref
                                .read(playerSessionProvider.notifier)
                                .buyItem(
                                    widget.shopId, itemId, cost, stockLimit,
                                    item: item,
                                    stockKey: stockKey(itemId),
                                    origin: itemOriginHere(ref));
                            if (!context.mounted) return;
                            _coinsOut(context);
                            showImmersiveNotice(
                              context,
                              icon: spell != null
                                  ? Icons.auto_stories
                                  : Icons.shopping_bag_outlined,
                              message: spell != null
                                  ? '${trFor(lang, 'spell_learned_prefix')} '
                                      '${spell.nameFor(lang)}'
                                  : itemType == 'Tome'
                                      ? '${trFor(lang, 'tome_read_prefix')} $itemName. '
                                          '${consumableNote(itemId, item, lang) ?? ''}'
                                      : '${trFor(lang, 'bought_prefix')} $itemName '
                                          '${trFor(lang, 'for_label')} $cost ${trFor(lang, 'gold_label')}',
                              actionLabel:
                                  canWear ? trFor(lang, 'equip_button') : null,
                              onAction: canWear
                                  ? () => ref
                                      .read(playerSessionProvider.notifier)
                                      .equipItem(itemId,
                                          slot: equipSlot, items: items)
                                  : null,
                            );
                          }

                          final description =
                              item?['description']?.toString() ?? '';
                          final useNote = consumableNote(itemId, item, lang);
                          final extraNote = [
                            if (description.isNotEmpty) description,
                            if (useNote != null) useNote,
                            if (spellNote != null) spellNote,
                            if (!meetsAlignment)
                              trFor(lang, 'shop_alignment_locked'),
                          ];
                          void openDetails() => showItemDetailsSheet(
                                context,
                                itemId: itemId,
                                item: item,
                                language: lang,
                                equipped: worn,
                                equippedName: wornName,
                                priceLine: priceLine,
                                unmetRequirement: unmetRequirement,
                                setLine: set == null
                                    ? null
                                    : '${trFor(lang, 'set_label')}: '
                                        '${set.nameFor(lang)}',
                                extraNote: extraNote.isEmpty
                                    ? null
                                    : extraNote.join('\n'),
                                actionLabel: trFor(lang, 'buy_button'),
                                onAction: canBuy ? buy : null,
                              );

                          final theme = Theme.of(context);
                          final notes = [
                            if (useNote != null) useNote,
                            ...itemTraitNotes(item, lang,
                                unmetRequirement: unmetRequirement),
                          ];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: openDetails,
                              onLongPress: openDetails,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 8, 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: ItemPixelIcon(itemId, itemType),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(itemName,
                                                    style: theme
                                                        .textTheme.titleSmall),
                                              ),
                                              if (wearing) ...[
                                                const SizedBox(width: 6),
                                                Icon(Icons.check_circle,
                                                    size: 14,
                                                    color:
                                                        Colors.green.shade600),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            [
                                              if (itemType != null) itemType,
                                              if ((equipSlot ?? '').isNotEmpty)
                                                equipSlot,
                                              priceLine,
                                            ].join(' · '),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          ItemStatChips(
                                            item: item,
                                            equipped: worn,
                                            equippedName: wornName,
                                            language: lang,
                                          ),
                                          for (final note in notes)
                                            Text(
                                              note,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: note.startsWith(trFor(
                                                        lang,
                                                        'stat_requirement_label'))
                                                    ? theme.colorScheme.error
                                                    : theme.colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          if (!meetsAlignment)
                                            Text(
                                              trFor(lang,
                                                  'shop_alignment_locked'),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                      color: theme
                                                          .colorScheme.error),
                                            ),
                                          if (spellNote != null)
                                            Text(
                                              spellNote,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: canBuy ? buy : null,
                                      child: Text(tr(ref, 'buy_button')),
                                    ),
                                  ],
                                ),
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
                            final theme = Theme.of(context);
                            final die = dice[diceId] as Map<String, dynamic>?;
                            final cost = conditionedPrice(
                                factionPriceFor(
                                        shopPriceFor(
                                            (die?['cost'] as num?)?.toInt() ??
                                                0,
                                            session.charisma),
                                        tier) ??
                                    0,
                                priceFactor);
                            final owned = session.ownedDiceIds.contains(diceId);
                            final canAfford = session.gold >= cost;
                            // A die made for another class or race is shown
                            // but can't be bought.
                            final usable = dieUsableBy(die,
                                professionId: session.professionId,
                                raceId: session.raceId);
                            final madeFor =
                                dieMadeForLabel(die, professions, races);
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.casino),
                                title: Text(
                                    dieDisplayName(diceId, language: lang)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${owned ? tr(ref, 'owned_label') : '$cost ${tr(ref, 'gold_label')}'}\n'
                                      '${dieFacesSummary(die, lang)}',
                                    ),
                                    if (madeFor.isNotEmpty)
                                      Text(
                                        '${trFor(lang, 'die_made_for_prefix')} $madeFor',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: usable
                                                    ? theme.colorScheme
                                                        .onSurfaceVariant
                                                    : theme.colorScheme.error),
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: owned
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : ElevatedButton(
                                        onPressed: !canAfford ||
                                                !usable ||
                                                refuses
                                            ? null
                                            : () async {
                                                await ref
                                                    .read(playerSessionProvider
                                                        .notifier)
                                                    .buyDice(diceId, cost);
                                                if (!context.mounted) return;
                                                _coinsOut(context);
                                                showImmersiveNotice(
                                                  context,
                                                  icon: Icons.casino,
                                                  message:
                                                      '${trFor(lang, 'bought_prefix')} ${dieDisplayName(diceId, language: lang)} '
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
            error: (error, stack) => Center(
                child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
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
      ),
    );
  }
}

/// The shop's sign, its keeper and what they say to this character (by the
/// standing with the shop's faction, v1.197). Nothing for a shop that
/// names no keeper.
class _KeeperStrip extends StatelessWidget {
  const _KeeperStrip({
    required this.shopId,
    required this.shop,
    required this.tier,
    required this.language,
  });

  final String shopId;
  final Map<String, dynamic> shop;
  final StandingTier? tier;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final name = shopKeeperName(shop, language);
    final line = shopKeeperLine(shop, language, tier: tier);
    if (name == null && line == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('shop_keeper_strip'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShopPixelIcon(shopId, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line != null)
                  Text('“$line”',
                      key: const ValueKey('shop_keeper_line'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                if (name != null)
                  Text(name.toUpperCase(),
                      key: const ValueKey('shop_keeper_name'),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shop's faction and what the character's standing with them does to
/// its prices (v1.193), in the tier's colour: dearer, cheaper, fair, or
/// no trade at all.
class _FactionPriceLine extends StatelessWidget {
  const _FactionPriceLine({
    required this.faction,
    required this.tier,
    required this.language,
  });

  final Faction faction;
  final StandingTier tier;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factor = tierPriceFactor(tier);
    final tierWord = trFor(language, standingTierKey(tier));
    final key = factor == null
        ? 'shop_faction_refuses'
        : factor == 1
            ? 'shop_faction_fair'
            : 'shop_faction_line';
    final text = trFor(language, key)
        .replaceAll('{name}', faction.nameFor(language))
        .replaceAll('{tier}', tierWord)
        .replaceAll('{p}', factor == null ? '' : percentChange(factor));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        key: const ValueKey('shop_faction_line'),
        children: [
          Icon(
            factor == null
                ? Icons.block
                : factor > 1
                    ? Icons.trending_up
                    : factor < 1
                        ? Icons.trending_down
                        : Icons.balance,
            size: 18,
            color: Color(tierColor(tier)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: factor == null ? theme.colorScheme.error : null,
                  fontWeight: factor == null ? FontWeight.w600 : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// The price paid: coins flying from the screen's middle up to the purse
/// in the top bar.
void _coinsOut(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  showCoinFlight(context,
      from: Offset(size.width - 48, MediaQuery.paddingOf(context).top + 24),
      to: size.center(Offset.zero));
}
