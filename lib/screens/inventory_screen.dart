import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import '../widgets/detail_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final diceAsync = ref.watch(gameDbProvider(diceSchema));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'inventory_equipment'))),
      body: itemsAsync.when(
        data: (items) => diceAsync.when(
          data: (dice) => _InventoryBody(items: items, dice: dice),
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
        Text(tr(ref, 'equipment_section'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.casino),
            title: Text(tr(ref, 'dice_label')),
            subtitle: Text(equippedDie != null ? equippedDiceId! : tr(ref, 'none_equipped')),
            trailing: IconButton(
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
                      onPressed: () =>
                          ref.read(playerSessionProvider.notifier).unequipItem(equippedId),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: tr(ref, 'choose_item'),
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
            return _ItemTile(
              itemId: id,
              item: item,
              count: counts[id],
              isEquipped: isEquipped,
              language: ref.watch(appLanguageProvider),
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
    required this.language,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final int? count;
  final bool isEquipped;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final itemName = item?['itemName']?.toString() ?? itemId;
    final itemType = item?['itemType']?.toString();
    final equipSlot = item?['equipSlot']?.toString();
    final attackDamage = (item?['attackDamage'] as num?)?.toInt() ?? 0;
    final armor = (item?['armor'] as num?)?.toInt() ?? 0;
    String t(String key) => trFor(language, key);

    final statsParts = <String>[
      if (itemType != null) itemType,
      if (isEquipped && equipSlot != null && equipSlot.isNotEmpty)
        '${t('equipped_prefix')}: $equipSlot',
      if (attackDamage > 0) '${t('atk_abbrev')} +$attackDamage',
      if (armor > 0) '${t('arm_abbrev')} +$armor',
      if (count != null && count! > 1) 'x$count',
    ];

    return Card(
      color: isEquipped ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(itemTypeIcon(itemType)),
        title: Text(itemName),
        subtitle: Text(statsParts.join(' · ')),
        onTap: () => showDetailDialog(
          context,
          title: itemName,
          icon: itemTypeIcon(itemType),
          closeLabel: t('close_button'),
          rows: [
            MapEntry(t('item_type_label'), itemType ?? t('unknown_label')),
            MapEntry(t('cost_label'), '${item?['cost'] ?? 0}'),
            if (equipSlot != null && equipSlot.isNotEmpty)
              MapEntry(t('equip_slot_label'), equipSlot),
            MapEntry(t('attack_damage_label'), '$attackDamage'),
            MapEntry(t('armor_label'), '$armor'),
            for (final entry in {
              'fireDmgBonus': t('fire_dmg_label'), 'windDmgBonus': t('wind_dmg_label'),
              'earthDmgBonus': t('earth_dmg_label'), 'waterDmgBonus': t('water_dmg_label'),
              'elecDmgBonus': t('elec_dmg_label'),
            }.entries)
              if (((item?[entry.key] as num?) ?? 0) != 0)
                MapEntry(entry.value, '${item?[entry.key]}'),
            for (final entry in {
              'fireResist': t('fire_resist_label'), 'windResist': t('wind_resist_label'),
              'earthResist': t('earth_resist_label'), 'waterResist': t('water_resist_label'),
              'elecResist': t('elec_resist_label'),
            }.entries)
              if (((item?[entry.key] as num?) ?? 0) != 0)
                MapEntry(entry.value, '${item?[entry.key]}'),
            if (count != null && count! > 1) MapEntry(t('owned_label'), '$count'),
          ],
        ),
      ),
    );
  }
}
