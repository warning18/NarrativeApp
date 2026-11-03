import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/help_hint.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../combat/dice_faces.dart';
import '../combat/gear_effects.dart';
import '../models/ally_state.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../theme/stitched_ink.dart';
import '../widgets/clan_die_gift.dart';
import '../widgets/compare_dialog.dart';
import '../widgets/item_detail_view.dart';
import '../widgets/inventory_parts.dart';
import '../widgets/item_lore.dart';
import '../widgets/item_stats.dart';
import 'dice_loadout_screen.dart';

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

  /// A long press on a piece: the manual compare, with it as the first.
  void _startCompareFrom(String itemId) {
    setState(() {
      _compareMode = true;
      _firstCompareId = itemId;
    });
  }

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
      rows: _itemCompareRows(itemA, itemB),
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
        title: Text('${tr(ref, 'inv_title')}$titleSuffix'),
        actions: [
          const TourInfoButton(topic: TutorialTopic.inventory),
          TutorialTarget(
            id: 'inventory.compare',
            child: IconButton(
              icon: Icon(_compareMode
                  ? Icons.compare_arrows
                  : Icons.compare_arrows_outlined),
              tooltip: tr(ref, 'compare_button'),
              onPressed: _toggleCompareMode,
            ),
          ),
        ],
      ),
      body: TutorialTrigger(
        topic: TutorialTopic.inventory,
        child: Column(
          children: [
            if (_compareMode)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _firstCompareId == null
                      ? tr(ref, 'compare_hint_items')
                      : tr(ref, 'compare_first_selected'),
                ),
              ),
            Expanded(
              child: TutorialTarget(
                id: 'inventory.body',
                child: itemsAsync.when(
                  data: (items) => diceAsync.when(
                    data: (dice) => _InventoryBody(
                      items: items,
                      itemSets: parseItemSets(ref
                              .watch(localizedDbProvider(itemSetsSchema))
                              .value ??
                          const {}),
                      dice: dice,
                      allyId: widget.allyId,
                      companion: companion,
                      compareMode: _compareMode,
                      firstCompareId: _firstCompareId,
                      onCompareTap: (itemId) =>
                          _onCompareTap(context, items, itemId),
                      onCompareStart: _startCompareFrom,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                        child:
                            Text('${tr(ref, 'failed_to_load_dice')}: $error')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                      child:
                          Text('${tr(ref, 'failed_to_load_items')}: $error')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat rows shared by the manual item-vs-item compare dialog and the
/// automatic item-vs-currently-equipped delta shown in item details.
List<CompareRow> _itemCompareRows(
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

class _InventoryBody extends ConsumerStatefulWidget {
  const _InventoryBody({
    required this.items,
    required this.dice,
    required this.allyId,
    required this.companion,
    required this.compareMode,
    required this.firstCompareId,
    required this.onCompareTap,
    required this.onCompareStart,
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

  /// A long press on a row: starts a manual compare from it.
  final ValueChanged<String> onCompareStart;

  @override
  ConsumerState<_InventoryBody> createState() => _InventoryBodyState();
}

class _InventoryBodyState extends ConsumerState<_InventoryBody> {
  InventoryTab _tab = InventoryTab.all;
  InventorySort _sort = InventorySort.newest;

  /// The pieces the bag held at the last visit (a piece not in it is new);
  /// null on the first visit, and for a companion's gear.
  Set<String>? _seenAtOpen;

  @override
  void initState() {
    super.initState();
    InventoryMemory.load().then((m) {
      if (!mounted) return;
      setState(() {
        _tab = m.tab ?? _tab;
        _sort = m.sort ?? _sort;
        _seenAtOpen = widget.allyId == null ? m.seen : null;
      });
      _rememberSeen();
    });
  }

  void _rememberSeen() {
    if (widget.allyId != null) return;
    InventoryMemory.saveSeen(ref.read(playerSessionProvider).inventoryItemIds);
  }

  void _setTab(InventoryTab tab) {
    setState(() => _tab = tab);
    InventoryMemory.saveView(tab, _sort);
    _rememberSeen();
  }

  void _setSort(InventorySort sort) {
    setState(() => _sort = sort);
    InventoryMemory.saveView(_tab, sort);
  }

  String? _equippedInSlot(List<String> equippedIds, String slot) {
    for (final id in equippedIds) {
      final item = widget.items[id] as Map<String, dynamic>?;
      if ((item?['equipSlot']?.toString() ?? '') == slot) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final dice = widget.dice;
    final allyId = widget.allyId;
    final companion = widget.companion;
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final geography = ref.watch(geographyProvider);
    final ally = allyId != null
        ? session.recruitedAllies.firstWhere(
            (a) => a.companionId == allyId,
            orElse: () => AllyState(companionId: allyId, currentHealth: 0),
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

    final void Function(String itemId, {String? slot}) equipFn = allyId != null
        ? (itemId, {slot}) => ref
            .read(playerSessionProvider.notifier)
            .equipAllyItem(allyId, itemId, slot: slot, items: items)
        : (itemId, {slot}) => ref
            .read(playerSessionProvider.notifier)
            .equipItem(itemId, slot: slot, items: items);
    final void Function(String itemId) unequipFn = allyId != null
        ? (itemId) => ref
            .read(playerSessionProvider.notifier)
            .unequipAllyItem(allyId, itemId)
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
    // The Dice tab: only when the bag holds more than the die in hand.
    final showDiceTab = allyId == null && ownedDiceIds.length > 1;

    // The tabs: only the kinds the bag holds, each with its count.
    final kindCounts = <InventoryTab, int>{};
    for (final id in ownedIds) {
      final kind = inventoryKindOf(items[id] as Map<String, dynamic>?);
      if (kind != null) kindCounts[kind] = (kindCounts[kind] ?? 0) + 1;
    }
    final tabs = <(InventoryTab, int)>[
      if (ownedIds.isNotEmpty) (InventoryTab.all, ownedIds.length),
      for (final kind in InventoryTab.values)
        if ((kindCounts[kind] ?? 0) > 0) (kind, kindCounts[kind]!),
      if (showDiceTab) (InventoryTab.dice, ownedDiceIds.length),
    ];
    final tab = tabs.any((t) => t.$1 == _tab) ? _tab : InventoryTab.all;

    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    Widget caption(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
        );

    // An empty slot a piece in the bag could go to is lit.
    List<String> candidatesFor(String slot) => ownedIds.where((id) {
          final item = items[id] as Map<String, dynamic>?;
          return (item?['isEquippable'] as bool? ?? false) &&
              (item?['equipSlot']?.toString() ?? '') == slot &&
              hasFreeCopy(id);
        }).toList();

    final slotTiles = <Widget>[
      // An ally's signature die is fixed at recruitment and never
      // player-swappable, so no choosing in that case.
      InventorySlotTile(
        key: const Key('slot_Dice'),
        slotLabel: tr(ref, 'dice_label'),
        icon: equippedDiceId != null && equippedDie != null
            ? SizedBox(
                width: 26,
                height: 26,
                child: InventoryDieTile(
                    dieId: equippedDiceId,
                    faces: (equippedDie['numberOfFaces'] as num?)?.toInt() ??
                        (equippedDie['faces'] as List?)?.length ??
                        6,
                    size: 26))
            : Icon(Icons.casino, size: 24, color: ink.gold),
        worn: equippedDiceId != null && equippedDie != null
            ? dieDisplayName(equippedDiceId, language: lang)
            : null,
        tip: tr(ref, 'choose_die'),
        onTap: allyId != null || ownedDiceIds.isEmpty
            ? null
            : showDiceTab
                ? () => _setTab(InventoryTab.dice)
                : () => _openDice(context, equippedDiceId),
      ),
      for (final slot in equipSlotOptions)
        () {
          final equippedId = _equippedInSlot(equippedIds, slot);
          final equippedItem = equippedId != null
              ? items[equippedId] as Map<String, dynamic>?
              : null;
          final candidates = candidatesFor(slot);
          return InventorySlotTile(
            key: Key('slot_$slot'),
            slotLabel: inventorySlotName(lang, slot),
            icon: equippedId != null
                ? ItemPixelIcon(
                    equippedId, equippedItem?['itemType']?.toString(),
                    size: 24)
                : Icon(inventorySlotIcon(slot), size: 24, color: ink.ash),
            worn: equippedItem?['itemName']?.toString(),
            lit: equippedId == null && candidates.isNotEmpty,
            tip: tr(ref, 'choose_item'),
            clearTip: tr(ref, 'unequip'),
            onTap: candidates.isEmpty
                ? null
                : () => _pickForSlot(context, ref, slot, candidates, equippedId,
                    equipFn, canEquip),
            onClear: equippedId == null ? null : () => unequipFn(equippedId),
          );
        }(),
    ];

    final shown = tab == InventoryTab.dice
        ? const <String>[]
        : sortInventoryIds([
            for (final id in ownedIds)
              if (tab == InventoryTab.all ||
                  inventoryKindOf(items[id] as Map<String, dynamic>?) == tab)
                id
          ], items, _sort, session.inventoryItemIds);

    Widget row(String id) {
      final item = items[id] as Map<String, dynamic>?;
      final isEquipped = equippedIds.contains(id);
      final gear = isGear(item);
      final equipSlot = item?['equipSlot']?.toString() ?? '';
      final comparisonId =
          gear && !isEquipped ? _equippedInSlot(equippedIds, equipSlot) : null;
      final comparisonItem = comparisonId != null
          ? items[comparisonId] as Map<String, dynamic>?
          : null;
      final set = setForItem(id, item, widget.itemSets);
      final setPiecesWorn = set?.piecesWornIn(equippedIds) ?? 0;
      final requirementUnmet = gear && !isEquipped && !canEquip(id);
      final requirementText =
          requirementUnmet ? requirementSummary(item, lang) : null;
      final wornBy = gear && !isEquipped ? wornByOthers(id) : null;
      final onEquip = (gear && !isEquipped && canEquip(id) && hasFreeCopy(id))
          ? () => equipFn(id, slot: equipSlot)
          : null;
      final onUnequip = isEquipped ? () => unequipFn(id) : null;
      final onRead = item?['itemType']?.toString() == 'Tome'
          ? () => ref.read(playerSessionProvider.notifier).readTome(id, item)
          : null;
      final rarityWord = inventoryRarityWord(lang, item);
      final slotName = inventorySlotName(lang, equipSlot);
      String t(String key) => trFor(lang, key);
      final unique = uniqueEffectOf(item);
      final String detail;
      if (gear) {
        if (requirementUnmet) {
          detail = (requirementText ?? '').isNotEmpty
              ? '${t('stat_requirement_label')}: $requirementText'
              : t('alignment_rejects_label');
        } else if (wornBy != null) {
          detail = '${t('worn_by_prefix')}: $wornBy';
        } else {
          detail = t(isEquipped ? 'inv_worn_on' : 'inv_goes_on')
              .replaceAll('{slot}', slotName);
        }
      } else {
        detail = [
          inventoryTypeName(lang, item?['itemType']?.toString()),
          if (unique != null)
            t(uniqueEffectDescriptionKey(unique))
                .replaceAll('{v}', '${uniqueValueOf(item)}'),
        ].where((p) => p.isNotEmpty).join(' · ');
      }
      final fresh =
          _seenAtOpen != null && !_seenAtOpen!.contains(id) && allyId == null;
      return InventoryRow(
        key: Key('inv_row_$id'),
        itemId: id,
        item: item,
        language: lang,
        line: [if (rarityWord.isNotEmpty) rarityWord, detail].join(' · '),
        slot: gear ? equipSlot : null,
        worn: comparisonItem,
        isWorn: isEquipped,
        fresh: fresh,
        count: counts[id],
        locked: requirementUnmet || wornBy != null,
        selected: widget.firstCompareId == id,
        actionLabel: widget.compareMode
            ? null
            : onRead != null
                ? t('read_button')
                : isEquipped
                    ? t('inv_take_off')
                    : onEquip != null
                        ? t('equip_button')
                        : null,
        onAction: widget.compareMode ? null : (onRead ?? onUnequip ?? onEquip),
        onLongPress: widget.compareMode || !gear
            ? null
            : () => widget.onCompareStart(id),
        onTap: widget.compareMode
            ? () => widget.onCompareTap(id)
            : () => showItemDetailsSheet(
                  context,
                  itemId: id,
                  item: item,
                  language: lang,
                  equipped: comparisonItem,
                  equippedId: comparisonId,
                  equippedName:
                      comparisonItem?['itemName']?.toString() ?? comparisonId,
                  priceLine: '${t('cost_label')}: ${item?['cost'] ?? 0}',
                  unmetRequirement: requirementText,
                  itemSet: set,
                  setPiecesWorn: setPiecesWorn,
                  originLine: itemOriginLineFor(
                      session.itemOrigins[id], geography, lang),
                  count: counts[id],
                  wornBy: wornBy,
                  isWorn: isEquipped,
                  actionLabel: onUnequip != null
                      ? t('inv_take_off')
                      : onEquip != null
                          ? t('equip_button')
                          : null,
                  onAction: onUnequip ?? onEquip,
                ),
      );
    }

    Widget diceRows() {
      final professions =
          ref.watch(localizedDbProvider(professionsSchema)).value ?? const {};
      final races =
          ref.watch(localizedDbProvider(racesSchema)).value ?? const {};
      Widget dieRow(String id, {required bool inHand}) {
        final die = dice[id] as Map<String, dynamic>?;
        final usable = dieUsableBy(die,
            professionId: session.professionId, raceId: session.raceId);
        return InventoryDieRow(
          key: Key('inv_die_$id'),
          dieId: id,
          name: dieDisplayName(id, language: lang),
          faces: (die?['numberOfFaces'] as num?)?.toInt() ??
              (die?['faces'] as List?)?.length ??
              6,
          language: lang,
          inHand: inHand,
          locked: !usable,
          madeFor: dieMadeForLabel(die, professions, races),
          gift: ClanDieGift(dieId: id),
          onOpen: () => _openDice(context, id),
          onEquip: usable && !inHand
              ? () => ref.read(playerSessionProvider.notifier).equipDice(id)
              : null,
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (equippedDiceId != null &&
            ownedDiceIds.contains(equippedDiceId)) ...[
          caption(tr(ref, 'inv_in_hand')),
          dieRow(equippedDiceId, inHand: true),
        ],
        const SizedBox(height: 6),
        caption(tr(ref, 'inv_in_bag')),
        for (final id in ownedDiceIds)
          if (id != equippedDiceId) dieRow(id, inHand: false),
      ]);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        caption(tr(ref, 'equipment_section')),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: slotTiles,
        ),
        const SizedBox(height: 16),
        if (ownedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(tr(ref, 'inventory_empty')),
          )
        else ...[
          InventoryTabBar(
            counts: tabs,
            selected: tab,
            onSelect: _setTab,
            language: lang,
          ),
          if (tab != InventoryTab.dice)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(children: [
                Expanded(
                  child: tab == InventoryTab.gear || tab == InventoryTab.all
                      ? Text(tr(ref, 'inv_compare_hold'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: ink.ash, fontStyle: FontStyle.italic))
                      : const SizedBox.shrink(),
                ),
                InventorySortButton(
                    sort: _sort, onChanged: _setSort, language: lang),
              ]),
            )
          else
            const SizedBox(height: 10),
          if (tab == InventoryTab.dice)
            diceRows()
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(tr(ref, 'inv_empty_tab')),
            )
          else
            for (final id in shown) row(id),
        ],
      ],
    );
  }

  /// The dice screen, opened on [dieId].
  void _openDice(BuildContext context, String? dieId) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DiceLoadoutScreen(initialDieId: dieId)));
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
            final item = widget.items[id] as Map<String, dynamic>?;
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
