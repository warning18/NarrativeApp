import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../combat/dice_faces.dart';
import '../combat/gear_effects.dart';
import '../models/ally_state.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
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

  void _onCompareTap(
      BuildContext context, Map<String, dynamic> items, String itemId) {
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
    final itemsAsync = ref.watch(localizedDbProvider(itemsSchema));
    final diceAsync = ref.watch(localizedDbProvider(diceSchema));
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};

    final companion = widget.allyId != null
        ? companions[widget.allyId] as Map<String, dynamic>?
        : null;
    final titleSuffix = widget.allyId != null
        ? ' — ${companion?['companionName']?.toString() ?? widget.allyId}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'inventory_equipment')}$titleSuffix'),
        actions: [
          IconButton(
            icon: Icon(_compareMode
                ? Icons.compare_arrows
                : Icons.compare_arrows_outlined),
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
                  itemSets: parseItemSets(
                      ref.watch(localizedDbProvider(itemSetsSchema)).value ??
                          const {}),
                  dice: dice,
                  allyId: widget.allyId,
                  companion: companion,
                  compareMode: _compareMode,
                  firstCompareId: _firstCompareId,
                  onCompareTap: (itemId) =>
                      _onCompareTap(context, items, itemId),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                    child: Text('${tr(ref, 'failed_to_load_dice')}: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                  child: Text('${tr(ref, 'failed_to_load_items')}: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat rows shared by the manual item-vs-item compare dialog and the
/// automatic item-vs-currently-equipped delta shown in item details.
List<CompareRow> itemCompareRows(
    Map<String, dynamic>? a, Map<String, dynamic>? b) {
  num v(Map<String, dynamic>? item, String key) => (item?[key] as num?) ?? 0;
  return [
    CompareRow(
        label: 'ATK',
        valueA: v(a, 'attackDamage'),
        valueB: v(b, 'attackDamage')),
    CompareRow(label: 'ARM', valueA: v(a, 'armor'), valueB: v(b, 'armor')),
    CompareRow(
        label: 'Fire Dmg',
        valueA: v(a, 'fireDmgBonus'),
        valueB: v(b, 'fireDmgBonus')),
    CompareRow(
        label: 'Wind Dmg',
        valueA: v(a, 'windDmgBonus'),
        valueB: v(b, 'windDmgBonus')),
    CompareRow(
        label: 'Earth Dmg',
        valueA: v(a, 'earthDmgBonus'),
        valueB: v(b, 'earthDmgBonus')),
    CompareRow(
        label: 'Water Dmg',
        valueA: v(a, 'waterDmgBonus'),
        valueB: v(b, 'waterDmgBonus')),
    CompareRow(
        label: 'Elec Dmg',
        valueA: v(a, 'elecDmgBonus'),
        valueB: v(b, 'elecDmgBonus')),
    CompareRow(
        label: 'Ice Dmg',
        valueA: v(a, 'iceDmgBonus'),
        valueB: v(b, 'iceDmgBonus')),
    CompareRow(
        label: 'Light Dmg',
        valueA: v(a, 'lightDmgBonus'),
        valueB: v(b, 'lightDmgBonus')),
    CompareRow(
        label: 'Void Dmg',
        valueA: v(a, 'voidDmgBonus'),
        valueB: v(b, 'voidDmgBonus')),
    CompareRow(
        label: 'Fire Resist',
        valueA: v(a, 'fireResist'),
        valueB: v(b, 'fireResist')),
    CompareRow(
        label: 'Wind Resist',
        valueA: v(a, 'windResist'),
        valueB: v(b, 'windResist')),
    CompareRow(
        label: 'Earth Resist',
        valueA: v(a, 'earthResist'),
        valueB: v(b, 'earthResist')),
    CompareRow(
        label: 'Water Resist',
        valueA: v(a, 'waterResist'),
        valueB: v(b, 'waterResist')),
    CompareRow(
        label: 'Elec Resist',
        valueA: v(a, 'elecResist'),
        valueB: v(b, 'elecResist')),
    CompareRow(
        label: 'Ice Resist',
        valueA: v(a, 'iceResist'),
        valueB: v(b, 'iceResist')),
    CompareRow(
        label: 'Light Resist',
        valueA: v(a, 'lightResist'),
        valueB: v(b, 'lightResist')),
    CompareRow(
        label: 'Void Resist',
        valueA: v(a, 'voidResist'),
        valueB: v(b, 'voidResist')),
    CompareRow(
      label: 'Cost',
      valueA: v(a, 'cost'),
      valueB: v(b, 'cost'),
      higherIsBetter: null,
    ),
  ];
}

/// "10 STR, 4 CON" style summary of an item's reqStrength/reqDexterity/
/// reqConstitution/reqIntelligence fields (only the nonzero ones) — shown
/// wherever an unmet requirement needs explaining.
String requirementSummary(Map<String, dynamic>? item, AppLanguage lang) {
  int req(String key) => (item?[key] as num?)?.toInt() ?? 0;
  final parts = <String>[
    if (req('reqStrength') > 0)
      '${req('reqStrength')} ${trFor(lang, 'str_abbrev')}',
    if (req('reqDexterity') > 0)
      '${req('reqDexterity')} ${trFor(lang, 'dex_abbrev')}',
    if (req('reqConstitution') > 0)
      '${req('reqConstitution')} ${trFor(lang, 'con_abbrev')}',
    if (req('reqIntelligence') > 0)
      '${req('reqIntelligence')} ${trFor(lang, 'int_abbrev')}',
  ];
  return parts.join(', ');
}

/// The scaling stat's display abbreviation (e.g. "strength" -> "STR"), or
/// null if [item] doesn't scale with anything.
String? scalingStatAbbrev(Map<String, dynamic>? item, AppLanguage lang) {
  final key = switch (item?['scalingStat']?.toString() ?? '') {
    'strength' => 'str_abbrev',
    'dexterity' => 'dex_abbrev',
    'constitution' => 'con_abbrev',
    'intelligence' => 'int_abbrev',
    _ => null,
  };
  return key == null ? null : trFor(lang, key);
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
    this.itemSets = const {},
  });

  final Map<String, dynamic> items;
  final Map<String, dynamic> dice;

  /// item_sets.json, parsed -- for the "Set: Name (n/3)" line on a set
  /// piece and the worn-pieces count.
  final Map<String, ItemSet> itemSets;
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

    // Whichever character is actually being equipped -- the player, or (when
    // allyId is set) the ally's own race/profession-derived ability scores
    // (see deriveAllyBaseStats) -- gates and scales gear identically either
    // way, via the same pure helpers combat already uses.
    int equipperStrength = session.strength;
    int equipperDexterity = session.dexterity;
    int equipperConstitution = session.constitution;
    int equipperIntelligence = session.intelligence;
    if (allyId != null) {
      final races =
          ref.watch(localizedDbProvider(racesSchema)).value ?? const {};
      final professions =
          ref.watch(localizedDbProvider(professionsSchema)).value ?? const {};
      final gameConfig = ref.watch(gameConfigProvider).value ?? const {};
      final race = races[companion?['raceId']?.toString() ?? '']
              as Map<String, dynamic>? ??
          const {};
      final profession =
          professions[companion?['professionId']?.toString() ?? '']
                  as Map<String, dynamic>? ??
              const {};
      final allyBase = deriveAllyBaseStats(
          gameConfig: gameConfig, race: race, profession: profession);
      equipperStrength = allyBase.strength;
      equipperDexterity = allyBase.dexterity;
      equipperConstitution = allyBase.constitution;
      equipperIntelligence = allyBase.intelligence;
    }

    // Aligned gear answers to the player's alignment for the whole party
    // (an ally doesn't track one), exactly as aligned skills do.
    bool canEquip(String itemId) =>
        meetsItemStatRequirement(
          items[itemId] as Map<String, dynamic>?,
          strength: equipperStrength,
          dexterity: equipperDexterity,
          constitution: equipperConstitution,
          intelligence: equipperIntelligence,
        ) &&
        meetsItemAlignment(
            items[itemId] as Map<String, dynamic>?, session.alignmentLabel);

    void Function(String itemId, {String? slot}) equipFn = allyId != null
        ? (itemId, {slot}) => ref
            .read(playerSessionProvider.notifier)
            .equipAllyItem(allyId!, itemId, slot: slot, items: items)
        : (itemId, {slot}) => ref
            .read(playerSessionProvider.notifier)
            .equipItem(itemId, slot: slot, items: items);
    void Function(String itemId) unequipFn = allyId != null
        ? (itemId) => ref
            .read(playerSessionProvider.notifier)
            .unequipAllyItem(allyId!, itemId)
        : (itemId) =>
            ref.read(playerSessionProvider.notifier).unequipItem(itemId);

    final counts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final ownedIds = counts.keys.toList()..sort();
    final equippedIds = ally?.equippedItemIds ?? session.equippedItemIds;
    // One copy is worn by one character: an item everyone's copies of are
    // already worn by others isn't offered, and says who wears it.
    final wearerId = allyId ?? playerWearerId;
    bool hasFreeCopy(String id) =>
        equippedIds.contains(id) ||
        session.freeCopiesOf(id, wearerId: wearerId) > 0;
    final companionsDb =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    String? wornByOthers(String id) {
      if (hasFreeCopy(id)) return null;
      final names = [
        for (final wearer in session.wearersOf(id))
          if (wearer != wearerId)
            wearer == playerWearerId
                ? (session.characterName.isNotEmpty
                    ? session.characterName
                    : tr(ref, 'you_label'))
                : ((companionsDb[wearer]
                            as Map<String, dynamic>?)?['companionName']
                        ?.toString() ??
                    wearer),
      ];
      return names.isEmpty ? null : names.join(', ');
    }

    final allySignatureDiceId = companion?['signatureDiceId']?.toString();
    final equippedDiceId =
        allyId != null ? allySignatureDiceId : session.equippedDiceId;
    final equippedDie = equippedDiceId != null
        ? dice[equippedDiceId] as Map<String, dynamic>?
        : null;
    final ownedDiceIds = session.ownedDiceIds.where(dice.containsKey).toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr(ref, 'equipment_section'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.casino),
            title: Text(tr(ref, 'dice_label')),
            subtitle: Text(equippedDie != null
                ? equippedDiceId!
                : tr(ref, 'none_equipped')),
            // An ally's signature die is fixed at recruitment and never
            // player-swappable, so no edit affordance for that case.
            trailing: allyId != null
                ? null
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: tr(ref, 'choose_die'),
                    onPressed: ownedDiceIds.isEmpty
                        ? null
                        : () => _pickDice(
                            context, ref, ownedDiceIds, equippedDiceId),
                  ),
          ),
        ),
        ...equipSlotOptions.map((slot) {
          final equippedId = _equippedInSlot(equippedIds, slot);
          final equippedItem = equippedId != null
              ? items[equippedId] as Map<String, dynamic>?
              : null;
          final candidates = ownedIds.where((id) {
            final item = items[id] as Map<String, dynamic>?;
            return (item?['isEquippable'] as bool? ?? false) &&
                (item?['equipSlot']?.toString() ?? '') == slot &&
                hasFreeCopy(id);
          }).toList();

          return Card(
            child: ListTile(
              leading: ItemPixelIcon(
                  equippedId, equippedItem?['itemType']?.toString()),
              title: Text(slot),
              subtitle: Text(equippedItem?['itemName']?.toString() ??
                  tr(ref, 'empty_slot_label')),
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
                        : () => _pickForSlot(context, ref, slot, candidates,
                            equippedId, equipFn, canEquip),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 32),
        Text(tr(ref, 'all_items'),
            style: Theme.of(context).textTheme.titleMedium),
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
            final comparisonItem = comparisonId != null
                ? items[comparisonId] as Map<String, dynamic>?
                : null;
            final set = setForItem(id, item, itemSets);
            return _ItemTile(
              itemId: id,
              item: item,
              count: counts[id],
              itemSet: set,
              setPiecesWorn: set?.piecesWornIn(equippedIds) ?? 0,
              isEquipped: isEquipped,
              language: ref.watch(appLanguageProvider),
              comparisonItemId: comparisonId,
              comparisonItem: comparisonItem,
              compareMode: compareMode,
              selectedForCompare: firstCompareId == id,
              onCompareTap: compareMode ? () => onCompareTap(id) : null,
              onEquip: (isEquippable &&
                      !isEquipped &&
                      canEquip(id) &&
                      hasFreeCopy(id))
                  ? () => equipFn(id, slot: equipSlot)
                  : null,
              onUnequip: isEquipped ? () => unequipFn(id) : null,
              requirementUnmet: isEquippable && !isEquipped && !canEquip(id),
              wornBy: isEquippable && !isEquipped ? wornByOthers(id) : null,
              onRead: item?['itemType']?.toString() == 'Tome'
                  ? () => ref
                      .read(playerSessionProvider.notifier)
                      .readTome(id, item)
                  : null,
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
            final faceCount = (dice[id] as Map<String, dynamic>?)?['faces']
                    is List
                ? ((dice[id] as Map<String, dynamic>)['faces'] as List).length
                : 0;
            return ListTile(
              leading: const Icon(Icons.casino),
              title: Text(
                  dieDisplayName(id, language: ref.watch(appLanguageProvider))),
              subtitle: Text(
                  '$faceCount $facesLabel · ${dieFacesSummary(dice[id] as Map<String, dynamic>?, ref.read(appLanguageProvider))}'),
              trailing:
                  id == currentlyEquippedId ? const Icon(Icons.check) : null,
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
    bool Function(String itemId) canEquip,
  ) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: candidates.map((id) {
            final item = items[id] as Map<String, dynamic>?;
            final itemName = item?['itemName']?.toString() ?? id;
            final equippable = canEquip(id);
            return ListTile(
              leading: ItemPixelIcon(id, item?['itemType']?.toString()),
              title: Text(itemName),
              subtitle: equippable
                  ? null
                  : Text(
                      '${trFor(lang, 'stat_requirement_label')}: '
                      '${requirementSummary(item, lang)}',
                    ),
              enabled: equippable,
              trailing:
                  id == currentlyEquippedId ? const Icon(Icons.check) : null,
              onTap: !equippable
                  ? null
                  : () {
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
    this.onRead,
    this.requirementUnmet = false,
    this.itemSet,
    this.setPiecesWorn = 0,
    this.wornBy,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final int? count;

  /// Who else wears every copy of this item, when no copy is free for the
  /// character this inventory belongs to.
  final String? wornBy;
  final bool isEquipped;
  final AppLanguage language;

  /// The set this item belongs to, if any, and how many of its pieces the
  /// equipping character currently wears -- shown as "Set: Name (2/3)".
  final ItemSet? itemSet;
  final int setPiecesWorn;

  /// The item currently equipped in this item's slot, if any and if
  /// different from this item — used to show a +/- stat delta.
  final String? comparisonItemId;
  final Map<String, dynamic>? comparisonItem;

  final bool compareMode;
  final bool selectedForCompare;
  final VoidCallback? onCompareTap;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;

  /// Reads a carried tome (see PlayerSessionNotifier.readTome).
  final VoidCallback? onRead;

  /// True when this item is equippable, not already equipped, but the
  /// equipping character's ability scores don't meet its
  /// reqStrength/reqDexterity/reqConstitution/reqIntelligence gate — shows
  /// why the equip action is unavailable instead of just hiding it.
  final bool requirementUnmet;

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
    final scalingAbbrev = scalingStatAbbrev(item, language);
    final requirementText =
        requirementUnmet ? requirementSummary(item, language) : null;
    final itemAlignment = item?['alignment']?.toString() ?? '';
    final alignedAttack = (item?['alignedAttackBonus'] as num?)?.toInt() ?? 0;
    final alignedArmor = (item?['alignedArmorBonus'] as num?)?.toInt() ?? 0;
    final alignedParts = <String>[
      if (alignedAttack > 0) '${t('atk_abbrev')} +$alignedAttack',
      if (alignedArmor > 0) '${t('arm_abbrev')} +$alignedArmor',
    ];
    final unique = uniqueEffectOf(item);
    final uniqueText = unique == null
        ? null
        : t(uniqueEffectDescriptionKey(unique))
            .replaceAll('{v}', '${uniqueValueOf(item)}');
    final set = itemSet;
    final setText = set == null
        ? null
        : '${t('set_label')}: ${set.nameFor(language)} '
            '($setPiecesWorn/${set.itemIds.length})';

    final statsParts = <String>[
      if (itemType != null) itemType,
      if (isEquipped && equipSlot != null && equipSlot.isNotEmpty)
        '${t('equipped_prefix')}: $equipSlot',
      if (attackDamage > 0) '${t('atk_abbrev')} +$attackDamage',
      if (armor > 0) '${t('arm_abbrev')} +$armor',
      if (scalingAbbrev != null) '${t('scales_with_label')}: $scalingAbbrev',
      if (requirementText != null && requirementText.isNotEmpty)
        '${t('stat_requirement_label')}: $requirementText',
      if (itemAlignment.isNotEmpty)
        '${t('aligned_gear_label')}: ${itemAlignment == 'Good' ? t('alignment_good') : t('alignment_evil')}'
            '${alignedParts.isNotEmpty ? ' (${alignedParts.join(', ')} ${t('aligned_bonus_suffix')})' : ''}',
      if (itemAlignment.isNotEmpty &&
          requirementUnmet &&
          requirementText != null &&
          requirementText.isEmpty)
        t('alignment_rejects_label'),
      if (uniqueText != null) '${t('unique_label')}: $uniqueText',
      if (wornBy != null) '${t('worn_by_prefix')}: $wornBy',
      if (setText != null) setText,
      if (count != null && count! > 1) 'x$count',
      if (comparisonItem != null)
        '${t('vs_equipped_suffix')}: ${comparisonItem?['itemName'] ?? comparisonItemId}',
    ];

    return Card(
      color: selectedForCompare
          ? colorScheme.tertiaryContainer
          : (isEquipped ? colorScheme.primaryContainer : null),
      child: ListTile(
        leading: ItemPixelIcon(itemId, itemType),
        title: Text(itemName),
        subtitle: Text(statsParts.join(' · ')),
        trailing: compareMode
            ? null
            : onRead != null
                ? TextButton(onPressed: onRead, child: Text(t('read_button')))
                : (onEquip != null || onUnequip != null)
                    ? IconButton(
                        icon: Icon(onUnequip != null
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline),
                        tooltip: onUnequip != null
                            ? t('unequip')
                            : t('equip_button'),
                        onPressed: onUnequip ?? onEquip,
                      )
                    : requirementUnmet
                        ? Icon(Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant)
                        : null,
        onTap: compareMode
            ? onCompareTap
            : () => showDetailDialog(
                  context,
                  title: itemName,
                  leading: ItemPixelIcon(itemId, itemType, size: 24),
                  closeLabel: t('close_button'),
                  rows: [
                    MapEntry(
                        t('item_type_label'), itemType ?? t('unknown_label')),
                    MapEntry(t('cost_label'), '${item?['cost'] ?? 0}'),
                    if (equipSlot != null && equipSlot.isNotEmpty)
                      MapEntry(t('equip_slot_label'), equipSlot),
                    MapEntry(
                        t('attack_damage_label'), _statValue('attackDamage')),
                    MapEntry(t('armor_label'), _statValue('armor')),
                    if (scalingAbbrev != null)
                      MapEntry(t('scales_with_label'), scalingAbbrev),
                    if (requirementText != null && requirementText.isNotEmpty)
                      MapEntry(t('stat_requirement_label'), requirementText),
                    if (uniqueText != null)
                      MapEntry(t('unique_label'), uniqueText),
                    if (set != null) ...[
                      MapEntry(
                          t('set_label'),
                          '${set.nameFor(language)} '
                          '($setPiecesWorn/${set.itemIds.length})'),
                      for (final tier in set.tiers)
                        MapEntry(
                          '${tier.pieces} ${t('set_pieces_label')}'
                          '${tier.pieces <= setPiecesWorn ? ' ✓' : ''}',
                          tier.descriptionFor(language),
                        ),
                    ],
                    for (final entry in {
                      'fireDmgBonus': t('fire_dmg_label'),
                      'windDmgBonus': t('wind_dmg_label'),
                      'earthDmgBonus': t('earth_dmg_label'),
                      'waterDmgBonus': t('water_dmg_label'),
                      'elecDmgBonus': t('elec_dmg_label'),
                    }.entries)
                      if (((item?[entry.key] as num?) ?? 0) != 0 ||
                          ((comparisonItem?[entry.key] as num?) ?? 0) != 0)
                        MapEntry(entry.value, _statValue(entry.key)),
                    for (final entry in {
                      'fireResist': t('fire_resist_label'),
                      'windResist': t('wind_resist_label'),
                      'earthResist': t('earth_resist_label'),
                      'waterResist': t('water_resist_label'),
                      'elecResist': t('elec_resist_label'),
                    }.entries)
                      if (((item?[entry.key] as num?) ?? 0) != 0 ||
                          ((comparisonItem?[entry.key] as num?) ?? 0) != 0)
                        MapEntry(entry.value, _statValue(entry.key)),
                    if (count != null && count! > 1)
                      MapEntry(t('owned_label'), '$count'),
                  ],
                ),
      ),
    );
  }
}
