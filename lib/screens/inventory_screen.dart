import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/compare_dialog.dart';
import '../widgets/detail_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, this.allyId});

  /// When set, this screen manages the named companion's gear instead of
  /// the player's own — same screen, same equip/unequip flow, just pointed
  /// at a different character's [AllyState] instead of [PlayerSession]
  /// directly. Both draw candidate items from the same shared
  /// `inventoryItemIds` pool (this game has one inventory, not one per
  /// character); only which `equippedItemIds` list gets written differs.
  final String? allyId;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _compareMode = false;
  String? _firstCompareId;

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _firstCompareId = null;
    });
  }

  void _onCompareTap(BuildContext context, Map<String, dynamic> items, String itemId) {
    if (_firstCompareId == null) {
      setState(() => _firstCompareId = itemId);
      return;
    }
    if (_firstCompareId == itemId) return;
    final firstId = _firstCompareId!;
    final itemA = items[firstId] as Map<String, dynamic>?;
    final itemB = items[itemId] as Map<String, dynamic>?;
    final lang = ref.read(appLanguageProvider);
    showCompareDialog(
      context,
      titleA: itemA?['itemName']?.toString() ?? firstId,
      titleB: itemB?['itemName']?.toString() ?? itemId,
      rows: itemCompareRows(itemA, itemB),
      closeLabel: trFor(lang, 'close_button'),
    );
    setState(() {
      _compareMode = false;
      _firstCompareId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final companions = ref.watch(gameDbProvider(companionsSchema)).value ?? const {};

    final companion = widget.allyId != null
        ? companions[widget.allyId] as Map<String, dynamic>?
        : null;
    final titleSuffix =
        widget.allyId != null ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'inventory_equipment')}$titleSuffix'),
        actions: [
          IconButton(
            icon: Icon(_compareMode ? Icons.compare_arrows : Icons.compare_arrows_outlined),
            tooltip: tr(ref, 'compare_button'),
            onPressed: _toggleCompareMode,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_compareMode)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _firstCompareId == null
                    ? tr(ref, 'compare_hint_items')
                    : tr(ref, 'compare_first_selected'),
              ),
            ),
          Expanded(
            child: itemsAsync.when(
              data: (items) => diceAsync.when(
                data: (dice) => _InventoryBody(
                  items: items,
                  dice: dice,
                  allyId: widget.allyId,
                  companion: companion,
                  compareMode: _compareMode,
                  firstCompareId: _firstCompareId,
                  onCompareTap: (itemId) => _onCompareTap(context, items, itemId),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('${tr(ref, 'failed_to_load_items')}: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat rows shared by the manual item-vs-item compare dialog and the
/// automatic item-vs-currently-equipped delta shown in item details.
List<CompareRow> itemCompareRows(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  num v(Map<String, dynamic>? item, String key) => (item?[key] as num?) ?? 0;
  return [
    CompareRow(label: 'ATK', valueA: v(a, 'attackDamage'), valueB: v(b, 'attackDamage')),
    CompareRow(label: 'ARM', valueA: v(a, 'armor'), valueB: v(b, 'armor')),
    CompareRow(label: 'Fire Dmg', valueA: v(a, 'fireDmgBonus'), valueB: v(b, 'fireDmgBonus')),
    CompareRow(label: 'Wind Dmg', valueA: v(a, 'windDmgBonus'), valueB: v(b, 'windDmgBonus')),
    CompareRow(label: 'Earth Dmg', valueA: v(a, 'earthDmgBonus'), valueB: v(b, 'earthDmgBonus')),
    CompareRow(label: 'Water Dmg', valueA: v(a, 'waterDmgBonus'), valueB: v(b, 'waterDmgBonus')),
    CompareRow(label: 'Elec Dmg', valueA: v(a, 'elecDmgBonus'), valueB: v(b, 'elecDmgBonus')),
    CompareRow(label: 'Fire Resist', valueA: v(a, 'fireResist'), valueB: v(b, 'fireResist')),
    CompareRow(label: 'Wind Resist', valueA: v(a, 'windResist'), valueB: v(b, 'windResist')),
    CompareRow(label: 'Earth Resist', valueA: v(a, 'earthResist'), valueB: v(b, 'earthResist')),
    CompareRow(label: 'Water Resist', valueA: v(a, 'waterResist'), valueB: v(b, 'waterResist')),
    CompareRow(label: 'Elec Resist', valueA: v(a, 'elecResist'), valueB: v(b, 'elecResist')),
    CompareRow(
      label: 'Cost',
      valueA: v(a, 'cost'),
      valueB: v(b, 'cost'),
      higherIsBetter: null,
    ),
  ];
}

class _InventoryBody extends ConsumerWidget {
  const _InventoryBody({
    required this.items,
    required this.dice,
    required this.allyId,
    required this.companion,
    required this.compareMode,
    required this.firstCompareId,
    required this.onCompareTap,
  });

  final Map<String, dynamic> items;
  final Map<String, dynamic> dice;
  final String? allyId;
  final Map<String, dynamic>? companion;
  final bool compareMode;
  final String? firstCompareId;
  final ValueChanged<String> onCompareTap;

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
    final ally = allyId != null
        ? session.recruitedAllies.firstWhere(
            (a) => a.companionId == allyId,
            orElse: () => AllyState(companionId: allyId!, currentHealth: 0),
          )
        : null;

    void Function(String itemId, {String? slot}) equipFn = allyId != null
        ? (itemId, {slot}) => ref
            .read(playerSessionProvider.notifier)
            .equipAllyItem(allyId!, itemId, slot: slot, items: items)
        : (itemId, {slot}) =>
            ref.read(playerSessionProvider.notifier).equipItem(itemId, slot: slot, items: items);
    void Function(String itemId) unequipFn = allyId != null
        ? (itemId) => ref.read(playerSessionProvider.notifier).unequipAllyItem(allyId!, itemId)
        : (itemId) => ref.read(playerSessionProvider.notifier).unequipItem(itemId);

    final counts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ownedIds = counts.keys.toList()..sort();
    final equippedIds = ally?.equippedItemIds ?? session.equippedItemIds;

    final equippedDiceId = allyId != null ? companion?['signatureDiceId']?.toString() : session.equippedDiceId;
    final equippedDie = equippedDiceId != null ? dice[equippedDiceId] as Map<String, dynamic>? : null;
    final ownedDiceIds = session.ownedDiceIds.where(dice.containsKey).toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr(ref, 'equipment_section'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.casino),
            title: Text(tr(ref, 'dice_label')),
            subtitle: Text(equippedDie != null ? equippedDiceId! : tr(ref, 'none_equipped')),
            // An ally's signature die is fixed at recruitment and never
            // player-swappable, so no edit affordance for that case.
            trailing: allyId != null
                ? null
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: tr(ref, 'choose_die'),
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
              subtitle: Text(equippedItem?['itemName']?.toString() ?? tr(ref, 'empty_slot_label')),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (equippedId != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: tr(ref, 'unequip'),
                      onPressed: () => unequipFn(equippedId),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: tr(ref, 'choose_item'),
                    onPressed: candidates.isEmpty
                        ? null
                        : () => _pickForSlot(context, ref, slot, candidates, equippedId, equipFn),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 32),
        Text(tr(ref, 'all_items'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (ownedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(tr(ref, 'inventory_empty')),
          )
        else
          ...ownedIds.map((id) {
            final item = items[id] as Map<String, dynamic>?;
            final isEquipped = equippedIds.contains(id);
            final isEquippable = item?['isEquippable'] as bool? ?? false;
            final equipSlot = item?['equipSlot']?.toString() ?? '';
            String? comparisonId;
            if (isEquippable && !isEquipped && equipSlot.isNotEmpty) {
              comparisonId = _equippedInSlot(equippedIds, equipSlot);
            }
            final comparisonItem =
                comparisonId != null ? items[comparisonId] as Map<String, dynamic>? : null;
            return _ItemTile(
              itemId: id,
              item: item,
              count: counts[id],
              isEquipped: isEquipped,
              language: ref.watch(appLanguageProvider),
              comparisonItemId: comparisonId,
              comparisonItem: comparisonItem,
              compareMode: compareMode,
              selectedForCompare: firstCompareId == id,
              onCompareTap: compareMode ? () => onCompareTap(id) : null,
              onEquip: (isEquippable && !isEquipped) ? () => equipFn(id, slot: equipSlot) : null,
              onUnequip: isEquipped ? () => unequipFn(id) : null,
            );
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
    final facesLabel = trFor(ref.read(appLanguageProvider), 'faces_label');
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
              subtitle: Text('$faceCount $facesLabel'),
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
    void Function(String itemId, {String? slot}) equipFn,
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
                equipFn(id, slot: slot);
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
    required this.language,
    this.comparisonItemId,
    this.comparisonItem,
    this.compareMode = false,
    this.selectedForCompare = false,
    this.onCompareTap,
    this.onEquip,
    this.onUnequip,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final int? count;
  final bool isEquipped;
  final AppLanguage language;

  /// The item currently equipped in this item's slot, if any and if
  /// different from this item — used to show a +/- stat delta.
  final String? comparisonItemId;
  final Map<String, dynamic>? comparisonItem;

  final bool compareMode;
  final bool selectedForCompare;
  final VoidCallback? onCompareTap;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;

  /// Formats [value], appending a "(+n)"/"(-n)" delta against
  /// [comparisonItem]'s value for the same stat when one is set.
  String _statValue(String key) {
    final value = (item?[key] as num?) ?? 0;
    if (comparisonItem == null) return '$value';
    final cmp = (comparisonItem?[key] as num?) ?? 0;
    final delta = value - cmp;
    if (delta == 0) return '$value';
    final sign = delta > 0 ? '+' : '';
    return '$value ($sign$delta)';
  }

  @override
  Widget build(BuildContext context) {
    final itemName = item?['itemName']?.toString() ?? itemId;
    final itemType = item?['itemType']?.toString();
    final equipSlot = item?['equipSlot']?.toString();
    final attackDamage = (item?['attackDamage'] as num?)?.toInt() ?? 0;
    final armor = (item?['armor'] as num?)?.toInt() ?? 0;
    String t(String key) => trFor(language, key);
    final colorScheme = Theme.of(context).colorScheme;

    final statsParts = <String>[
      if (itemType != null) itemType,
      if (isEquipped && equipSlot != null && equipSlot.isNotEmpty)
        '${t('equipped_prefix')}: $equipSlot',
      if (attackDamage > 0) '${t('atk_abbrev')} +$attackDamage',
      if (armor > 0) '${t('arm_abbrev')} +$armor',
      if (count != null && count! > 1) 'x$count',
      if (comparisonItem != null)
        '${t('vs_equipped_suffix')}: ${comparisonItem?['itemName'] ?? comparisonItemId}',
    ];

    return Card(
      color: selectedForCompare
          ? colorScheme.tertiaryContainer
          : (isEquipped ? colorScheme.primaryContainer : null),
      child: ListTile(
        leading: Icon(itemTypeIcon(itemType)),
        title: Text(itemName),
        subtitle: Text(statsParts.join(' · ')),
        trailing: compareMode
            ? null
            : (onEquip != null || onUnequip != null)
                ? IconButton(
                    icon: Icon(onUnequip != null ? Icons.remove_circle_outline : Icons.add_circle_outline),
                    tooltip: onUnequip != null ? t('unequip') : t('equip_button'),
                    onPressed: onUnequip ?? onEquip,
                  )
                : null,
        onTap: compareMode
            ? onCompareTap
            : () => showDetailDialog(
                  context,
                  title: itemName,
                  icon: itemTypeIcon(itemType),
                  closeLabel: t('close_button'),
                  rows: [
                    MapEntry(t('item_type_label'), itemType ?? t('unknown_label')),
                    MapEntry(t('cost_label'), '${item?['cost'] ?? 0}'),
                    if (equipSlot != null && equipSlot.isNotEmpty)
                      MapEntry(t('equip_slot_label'), equipSlot),
                    MapEntry(t('attack_damage_label'), _statValue('attackDamage')),
                    MapEntry(t('armor_label'), _statValue('armor')),
                    for (final entry in {
                      'fireDmgBonus': t('fire_dmg_label'), 'windDmgBonus': t('wind_dmg_label'),
                      'earthDmgBonus': t('earth_dmg_label'), 'waterDmgBonus': t('water_dmg_label'),
                      'elecDmgBonus': t('elec_dmg_label'),
                    }.entries)
                      if (((item?[entry.key] as num?) ?? 0) != 0 ||
                          ((comparisonItem?[entry.key] as num?) ?? 0) != 0)
                        MapEntry(entry.value, _statValue(entry.key)),
                    for (final entry in {
                      'fireResist': t('fire_resist_label'), 'windResist': t('wind_resist_label'),
                      'earthResist': t('earth_resist_label'), 'waterResist': t('water_resist_label'),
                      'elecResist': t('elec_resist_label'),
                    }.entries)
                      if (((item?[entry.key] as num?) ?? 0) != 0 ||
                          ((comparisonItem?[entry.key] as num?) ?? 0) != 0)
                        MapEntry(entry.value, _statValue(entry.key)),
                    if (count != null && count! > 1) MapEntry(t('owned_label'), '$count'),
                  ],
                ),
      ),
    );
  }
}
