import 'dart:math';

import 'package:flutter/material.dart';

import '../combat/loot_box.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';

/// The post-fight spoils chest (see loot_box.dart): a closed chest the
/// player taps to open, then one face-down slot per drop to flip, plus
/// the visible fortune-roll breakdown that explains the tier. Resolves
/// once the player takes everything; the caller applies the rewards.
Future<void> showSpoilsChestDialog(
  BuildContext context, {
  required LootBoxResult result,
  required Map<String, dynamic> items,
  required bool autoOpen,
  required AppLanguage language,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SpoilsChestDialog(
      result: result,
      items: items,
      autoOpen: autoOpen,
      language: language,
    ),
  );
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
  });

  final LootBoxResult result;
  final Map<String, dynamic> items;
  final bool autoOpen;
  final AppLanguage language;

  @override
  State<SpoilsChestDialog> createState() => _SpoilsChestDialogState();
}

class _SpoilsChestDialogState extends State<SpoilsChestDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  bool _opened = false;
  bool _opening = false;
  final Set<int> _revealed = {};

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
          onPressed: _allRevealed ? () => Navigator.of(context).pop() : null,
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
      onTap: revealed ? null : () => _reveal(index),
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
