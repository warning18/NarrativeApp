import 'dart:math';

import 'package:flutter/material.dart';

import '../combat/loot_box.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';
import 'item_stats.dart';

/// What the player chose to do with the spoils before closing the chest:
/// gear to put on at once and healing potions to drink on the spot.
class SpoilsChoices {
  const SpoilsChoices(
      {this.equipItemIds = const [], this.drinkItemIds = const []});
  final List<String> equipItemIds;
  final List<String> drinkItemIds;
  static const none = SpoilsChoices();
}

/// The post-fight spoils chest (see loot_box.dart): a closed chest the
/// player taps to open, then one face-down slot per drop to flip, plus
/// the visible fortune-roll breakdown that explains the tier. Once items
/// are revealed, each can be looked at in full, gear the player can wear
/// can be equipped straight away, and a healing potion can be drunk.
/// Resolves with those choices once the player takes everything; the
/// caller applies the rewards and then the choices.
Future<SpoilsChoices> showSpoilsChestDialog(
  BuildContext context, {
  required LootBoxResult result,
  required Map<String, dynamic> items,
  required bool autoOpen,
  required AppLanguage language,
  List<String> equippedItemIds = const [],
  bool Function(String itemId)? canEquip,
  int currentHealth = 0,
  int maxHealth = 0,
}) async {
  final choices = await showDialog<SpoilsChoices>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SpoilsChestDialog(
      result: result,
      items: items,
      autoOpen: autoOpen,
      language: language,
      equippedItemIds: equippedItemIds,
      canEquip: canEquip,
      currentHealth: currentHealth,
      maxHealth: maxHealth,
    ),
  );
  return choices ?? SpoilsChoices.none;
}

Color chestTierColor(ChestTier tier) => switch (tier) {
      ChestTier.wooden => const Color(0xFF9A6A3C),
      ChestTier.iron => const Color(0xFF7B7F86),
      ChestTier.silver => const Color(0xFFB0B6C2),
      ChestTier.gold => const Color(0xFFE0B030),
      ChestTier.voidTier => const Color(0xFF8A4AD0),
    };

String chestAssetPath(ChestTier tier, {required bool open}) =>
    'assets/icons/chests/${chestTierAssetName(tier)}_${open ? 'open' : 'closed'}.png';

class SpoilsChestDialog extends StatefulWidget {
  const SpoilsChestDialog({
    super.key,
    required this.result,
    required this.items,
    required this.autoOpen,
    required this.language,
    this.equippedItemIds = const [],
    this.canEquip,
    this.currentHealth = 0,
    this.maxHealth = 0,
  });

  final LootBoxResult result;
  final Map<String, dynamic> items;
  final bool autoOpen;
  final AppLanguage language;

  /// What the player wears now, to compare each drop against.
  final List<String> equippedItemIds;

  /// Whether the player may wear an item (stat and alignment gates). Null
  /// means no drop can be equipped from the chest.
  final bool Function(String itemId)? canEquip;

  /// The player's health after the fight, so a potion is only offered
  /// when it would heal something.
  final int currentHealth;
  final int maxHealth;

  @override
  State<SpoilsChestDialog> createState() => _SpoilsChestDialogState();
}

class _SpoilsChestDialogState extends State<SpoilsChestDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  bool _opened = false;
  bool _opening = false;
  final Set<int> _revealed = {};

  /// Drop slot index -> chosen action. Keyed by slot so two copies of the
  /// same item are separate choices.
  final Set<int> _equipSlots = {};
  final Set<int> _drinkSlots = {};

  int get _slotCount => 1 + widget.result.itemIds.length;
  bool get _allRevealed => _revealed.length >= _slotCount;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    if (widget.autoOpen) {
      _opened = true;
      _revealed.addAll(List.generate(_slotCount, (i) => i));
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opened || _opening) return;
    setState(() => _opening = true);
    await _shake.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _opened = true;
      _opening = false;
    });
  }

  void _reveal(int index) {
    if (!_opened) return;
    setState(() => _revealed.add(index));
  }

  void _revealAll() {
    setState(() {
      _opened = true;
      _revealed.addAll(List.generate(_slotCount, (i) => i));
    });
  }

  String _t(String key) => trFor(widget.language, key);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final tierColor = chestTierColor(result.tier);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(_t('spoils_title'))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.2),
              border: Border.all(color: tierColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _t(chestTierLabelKey(result.tier)),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: tierColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _opened ? null : _open,
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final t = _shake.value;
                    final dx = sin(t * pi * 10) * (1 - t) * 6;
                    final scale = 1 + sin(t * pi) * 0.08;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: Center(
                    child: PixelIcon(
                      chestAssetPath(result.tier, open: _opened),
                      size: 112,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _opened
                    ? (_allRevealed
                        ? _t('chest_all_revealed_hint')
                        : _t('chest_slot_hint'))
                    : _t('chest_tap_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (_opened) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _slotCount; i++) _buildSlot(i),
                  ],
                ),
                if (result.extraSlot) ...[
                  const SizedBox(height: 8),
                  Text(
                    _t('chest_extra_slot_note'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.tertiary),
                  ),
                ],
                ..._buildSpoilsList(theme),
              ],
              const SizedBox(height: 12),
              _buildFortune(theme),
            ],
          ),
        ),
      ),
      actions: [
        if (!_allRevealed)
          TextButton(
            onPressed: _revealAll,
            child: Text(_t('chest_take_all_button')),
          ),
        FilledButton(
          onPressed: _allRevealed
              ? () => Navigator.of(context).pop(SpoilsChoices(
                    equipItemIds: [
                      for (final i in _equipSlots) widget.result.itemIds[i - 1],
                    ],
                    drinkItemIds: [
                      for (final i in _drinkSlots) widget.result.itemIds[i - 1],
                    ],
                  ))
              : null,
          child: Text(_t('chest_take_button')),
        ),
      ],
    );
  }

  Widget _buildSlot(int index) {
    final theme = Theme.of(context);
    final revealed = _revealed.contains(index);
    final tierColor = chestTierColor(widget.result.tier);
    Widget face;
    String label;
    if (index == 0) {
      face =
          Icon(Icons.monetization_on, size: 36, color: Colors.amber.shade700);
      label = '+${widget.result.gold} ${_t('gold_label')}';
    } else {
      final itemId = widget.result.itemIds[index - 1];
      final item = widget.items[itemId] as Map<String, dynamic>?;
      face = ItemPixelIcon(itemId, item?['itemType']?.toString(), size: 40);
      label = item?['itemName']?.toString() ?? itemId;
    }
    return GestureDetector(
      onTap: revealed
          ? (index == 0 ? null : () => _showDetails(index))
          : () => _reveal(index),
      onLongPress: revealed && index > 0 ? () => _showDetails(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 96,
        height: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: revealed
              ? tierColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
              color: revealed ? tierColor : theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: revealed
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  face,
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              )
            : Center(
                child: Icon(Icons.help_outline,
                    size: 32, color: theme.colorScheme.outline),
              ),
      ),
    );
  }

  String _itemIdAt(int slot) => widget.result.itemIds[slot - 1];

  Map<String, dynamic>? _itemAt(int slot) =>
      widget.items[_itemIdAt(slot)] as Map<String, dynamic>?;

  bool _isHealingPotion(int slot) =>
      _itemAt(slot)?['itemType']?.toString() == 'Potion' &&
      _itemIdAt(slot) != 'antidote';

  bool _canEquipSlot(int slot) =>
      isGear(_itemAt(slot)) &&
      (widget.canEquip?.call(_itemIdAt(slot)) ?? false);

  /// Health still missing once the potions already picked are drunk.
  int get _missingHealth =>
      widget.maxHealth -
      widget.currentHealth -
      _drinkSlots.length * potionHealAmount;

  /// The item worn in this drop's slot -- or the drop already picked to be
  /// equipped in that slot, which is what it would really replace.
  String? _wornFor(int slot) {
    final item = _itemAt(slot);
    if (!isGear(item)) return null;
    final equipSlot = item!['equipSlot'].toString();
    for (final other in _equipSlots) {
      if (other != slot &&
          _itemAt(other)?['equipSlot']?.toString() == equipSlot) {
        return _itemIdAt(other);
      }
    }
    return equippedCounterpart(
        _itemIdAt(slot), item, widget.equippedItemIds, widget.items);
  }

  void _toggleEquip(int slot) {
    setState(() {
      if (!_equipSlots.remove(slot)) {
        final equipSlot = _itemAt(slot)?['equipSlot']?.toString();
        // One piece per body slot: picking a second one replaces the first.
        _equipSlots.removeWhere(
            (other) => _itemAt(other)?['equipSlot']?.toString() == equipSlot);
        _equipSlots.add(slot);
      }
    });
  }

  void _toggleDrink(int slot) {
    setState(() {
      if (!_drinkSlots.remove(slot)) _drinkSlots.add(slot);
    });
  }

  /// The action this drop offers, if any: its label, whether it is picked,
  /// and the toggle (null when it can't be picked right now).
  (String, bool, VoidCallback?)? _actionFor(int slot) {
    if (_canEquipSlot(slot)) {
      return (
        _t('equip_button'),
        _equipSlots.contains(slot),
        () => _toggleEquip(slot)
      );
    }
    if (_isHealingPotion(slot)) {
      final picked = _drinkSlots.contains(slot);
      return (
        _t('drink_now_button'),
        picked,
        picked || _missingHealth > 0 ? () => _toggleDrink(slot) : null,
      );
    }
    return null;
  }

  void _showDetails(int slot) {
    final itemId = _itemIdAt(slot);
    final item = _itemAt(slot);
    final wornId = _wornFor(slot);
    final worn =
        wornId == null ? null : widget.items[wornId] as Map<String, dynamic>?;
    final action = _actionFor(slot);
    final type = item?['itemType']?.toString() ?? '';
    showItemDetailsSheet(
      context,
      itemId: itemId,
      item: item,
      language: widget.language,
      equipped: worn,
      equippedName: worn?['itemName']?.toString() ?? wornId,
      unmetRequirement: isGear(item) && !_canEquipSlot(slot)
          ? _t('loot_cannot_wear_note')
          : null,
      extraNote: [
        if (consumableNote(itemId, item, widget.language) case final note?)
          note,
        if (type == 'Tome' || type == 'Spellbook') _t('loot_auto_read_note'),
      ].join('\n').ifEmptyNull,
      actionLabel: action == null
          ? null
          : (action.$2 ? _t('loot_undo_button') : action.$1),
      onAction: action?.$3,
    );
  }

  List<Widget> _buildSpoilsList(ThemeData theme) {
    final slots = [
      for (var i = 1; i < _slotCount; i++)
        if (_revealed.contains(i)) i,
    ];
    if (slots.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Text(_t('loot_use_now_title'), style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      for (final slot in slots) _buildSpoilsRow(theme, slot),
    ];
  }

  Widget _buildSpoilsRow(ThemeData theme, int slot) {
    final itemId = _itemIdAt(slot);
    final item = _itemAt(slot);
    final wornId = _wornFor(slot);
    final worn =
        wornId == null ? null : widget.items[wornId] as Map<String, dynamic>?;
    final type = item?['itemType']?.toString() ?? '';
    final action = _actionFor(slot);
    final note = consumableNote(itemId, item, widget.language) ??
        (type == 'Tome' || type == 'Spellbook'
            ? _t('loot_auto_read_note')
            : isGear(item) && !_canEquipSlot(slot)
                ? _t('loot_cannot_wear_note')
                : null);
    return InkWell(
      onTap: () => _showDetails(slot),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemPixelIcon(itemId, type, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item?['itemName']?.toString() ?? itemId,
                      style: theme.textTheme.bodyMedium),
                  ItemStatChips(
                    item: item,
                    equipped: worn,
                    language: widget.language,
                    compact: true,
                  ),
                  if (note != null)
                    Text(note,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 6),
              FilterChip(
                label: Text(action.$1),
                selected: action.$2,
                onSelected: action.$3 == null ? null : (_) => action.$3!(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFortune(ThemeData theme) {
    final result = widget.result;
    final parts = <String>[
      for (final mod in result.modifiers)
        '${_t(mod.labelKey)} ${mod.value >= 0 ? '+' : ''}${mod.value}',
    ];
    final floor = result.floorApplied;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_t('fortune_roll_label')}: ${result.roll}',
          style: theme.textTheme.labelMedium,
        ),
        if (parts.isNotEmpty)
          Text(parts.join(' · '), style: theme.textTheme.bodySmall),
        if (floor != null)
          Text(
            '${_t('fortune_floor_label')}: ${_t(chestTierLabelKey(floor))}',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
