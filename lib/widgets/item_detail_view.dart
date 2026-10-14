import 'package:flutter/material.dart';

import '../combat/gear_effects.dart' show ItemSet;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'item_lore.dart';
import 'item_stats.dart';

num _stat(Map<String, dynamic>? item, String key) => (item?[key] as num?) ?? 0;

String _fmt(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);

/// A full look at one item, in this order: its art on a rarity-coloured
/// tile with its name and tags, the two numbers that matter (attack and
/// armor) as bars against the item worn in the same slot, its elements,
/// what it scales with and does, its set, and last its lore.
class ItemDetailView extends StatelessWidget {
  const ItemDetailView({
    super.key,
    required this.itemId,
    required this.item,
    required this.language,
    this.equipped,
    this.equippedId,
    this.equippedName,
    this.priceLine,
    this.unmetRequirement,
    this.itemSet,
    this.setPiecesWorn = 0,
    this.setLine,
    this.extraNote,
    this.originLine,
    this.count,
    this.wornBy,
    this.isWorn = false,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final AppLanguage language;

  /// The item worn in this item's slot, if any (and not this one).
  final Map<String, dynamic>? equipped;
  final String? equippedId;
  final String? equippedName;

  /// "Cost: 120", or the shop's price.
  final String? priceLine;
  final String? unmetRequirement;
  final ItemSet? itemSet;
  final int setPiecesWorn;

  /// A set named in a line, for callers with no [ItemSet] at hand.
  final String? setLine;
  final String? extraNote;
  final String? originLine;
  final int? count;
  final String? wornBy;

  /// This very item is the one worn: nothing to compare it with.
  final bool isWorn;

  @override
  Widget build(BuildContext context) {
    String t(String key) => trFor(language, key);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final scheme = theme.colorScheme;
    final type = item?['itemType']?.toString() ?? '';
    final slot = item?['equipSlot']?.toString() ?? '';
    final rarity = item?['rarity']?.toString() ?? '';
    final rarityLabel = itemRarityLabelFor(language, rarity);
    final rarityColor = itemRarityColor(scheme, rarity);
    final name = item?['itemName']?.toString() ?? itemId;
    final lore = itemLoreOf(item);
    final gear = isGear(item);
    final against = gear && !isWorn ? equipped : null;
    final heroKeys = [
      for (final k in const ['attackDamage', 'armor'])
        if (_stat(item, k) != 0 || _stat(against, k) != 0) k,
    ];
    final elements = [
      for (final line in gearStatLines(item, equipped, language))
        if (line.label != t('atk_abbrev') && line.label != t('arm_abbrev'))
          if (line.value != 0 || (gear && line.equipped != 0)) line,
    ];
    final traits =
        itemTraits(item, language, unmetRequirement: unmetRequirement);
    final tag = theme.textTheme.bodySmall?.copyWith(color: ink.ash);

    final Widget art = Container(
      key: const Key('item_art'),
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: rarityColor, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withValues(alpha: 0.30),
            rarityColor.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: rarity == 'Relic'
            ? [
                BoxShadow(
                    color: rarityColor.withValues(alpha: 0.35), blurRadius: 12)
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: ItemPixelIcon(itemId, type, size: 52),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            art,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontFamily: InkFonts.display)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    if (rarityLabel.isNotEmpty)
                      InkTag(
                          key: const Key('item_rarity_tag'),
                          label: rarityLabel,
                          color: rarityColor),
                    if (type.isNotEmpty) InkTag(label: type, color: ink.ash),
                    if (slot.isNotEmpty && slot != type)
                      InkTag(label: slot, color: ink.ash),
                    if (count != null && count! > 1)
                      InkTag(label: 'x$count', color: ink.ash),
                  ]),
                  if (priceLine != null) ...[
                    const SizedBox(height: 6),
                    Text(priceLine!, style: tag),
                  ],
                  if (wornBy != null) ...[
                    const SizedBox(height: 4),
                    Text('${t('worn_by_prefix')}: $wornBy', style: tag),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (heroKeys.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < heroKeys.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _HeroStat(
                    key: Key('item_hero_${heroKeys[i]}'),
                    label: t(heroKeys[i] == 'attackDamage'
                        ? 'attack_damage_label'
                        : 'armor_label'),
                    value: _stat(item, heroKeys[i]),
                    other: against == null ? null : _stat(against, heroKeys[i]),
                    color: heroKeys[i] == 'attackDamage' ? ink.ember : ink.tide,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (gear) ...[
          const SizedBox(height: 6),
          Row(
            key: const Key('item_compare_line'),
            children: [
              if (against != null) ...[
                ItemPixelIcon(equippedId, against['itemType']?.toString(),
                    size: 16),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  isWorn
                      ? t('equipped_prefix')
                      : against == null
                          ? t('slot_empty_compare_note')
                          : '${t('compare_vs_label')} ${equippedName ?? against['itemName'] ?? ''}',
                  style: tag,
                ),
              ),
            ],
          ),
        ],
        if (elements.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final line in elements)
              _ElementChip(line: line, compare: gear && against != null),
          ]),
        ],
        if (traits.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final trait in traits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(trait.icon,
                      size: 16, color: trait.warn ? scheme.error : ink.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: trait.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (trait.value.isNotEmpty)
                          TextSpan(text: '  ${trait.value}'),
                      ]),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: trait.warn ? scheme.error : null),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (itemSet != null)
          _SetBlock(set: itemSet!, worn: setPiecesWorn, language: language)
        else if (setLine != null) ...[
          const SizedBox(height: 4),
          Text(setLine!, style: theme.textTheme.bodyMedium),
        ],
        if (extraNote != null && extraNote!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(extraNote!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic)),
        ],
        if (lore.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: rarityColor, width: 3)),
            ),
            child: Text(lore,
                key: const Key('item_lore'),
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    color: ink.ash,
                    height: 1.45)),
          ),
        ],
        if (originLine != null && originLine!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(originLine!, key: const Key('item_origin'), style: tag),
        ],
      ],
    );
  }
}

/// One headline number: big, with its change against the worn item and a
/// bar that has a tick where the worn item sits.
class _HeroStat extends StatelessWidget {
  const _HeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.other,
    required this.color,
  });

  final String label;
  final num value;

  /// The worn item's value, or null when there is nothing to compare.
  final num? other;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final delta = other == null ? null : value - other!;
    final scale = [value, other ?? 0, 1].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_fmt(value),
                  style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 28,
                      height: 1.1,
                      color: color)),
              if (delta != null && delta != 0) ...[
                const SizedBox(width: 8),
                Text('${delta > 0 ? '+' : ''}${_fmt(delta)}',
                    key: const Key('item_hero_delta'),
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 15,
                        color: delta > 0 ? ink.heal : ink.blood)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: ink.seam,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Container(
                    width: w * (value / scale).clamp(0.0, 1.0).toDouble(),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                  if (other != null && other! > 0)
                    Positioned(
                      left:
                          (w * (other! / scale).clamp(0.0, 1.0).toDouble() - 1)
                              .clamp(0.0, w - 2)
                              .toDouble(),
                      top: -3,
                      bottom: -3,
                      child: Container(
                          width: 2,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ElementChip extends StatelessWidget {
  const _ElementChip({required this.line, required this.compare});

  final GearStatLine line;
  final bool compare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final delta = compare ? line.delta : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '${line.label} ${_fmt(line.value)}'),
          if (delta != 0)
            TextSpan(
                text: ' ${delta > 0 ? '+' : ''}${_fmt(delta)}',
                style: TextStyle(
                    color: delta > 0 ? ink.heal : ink.blood,
                    fontWeight: FontWeight.bold)),
        ]),
        style: theme.textTheme.labelMedium,
      ),
    );
  }
}

class _SetBlock extends StatelessWidget {
  const _SetBlock(
      {required this.set, required this.worn, required this.language});

  final ItemSet set;
  final int worn;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      key: const Key('item_set'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ink.seam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.layers_outlined, size: 16, color: ink.gold),
            const SizedBox(width: 6),
            Expanded(
              child: Text(set.nameFor(language),
                  style: theme.textTheme.titleSmall),
            ),
            Text('$worn/${set.itemIds.length}',
                style: TextStyle(fontFamily: InkFonts.system, color: ink.gold)),
          ]),
          for (final tier in set.tiers)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                      tier.pieces <= worn
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: tier.pieces <= worn ? ink.heal : ink.ash),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tier.descriptionFor(language),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: tier.pieces <= worn ? null : ink.ash),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The detail sheet for one item (inventory, shop, spoils): see
/// [ItemDetailView], then Close and an optional action (buy, equip).
Future<void> showItemDetailsSheet(
  BuildContext context, {
  required String itemId,
  required Map<String, dynamic>? item,
  required AppLanguage language,
  Map<String, dynamic>? equipped,
  String? equippedId,
  String? equippedName,
  String? priceLine,
  String? unmetRequirement,
  ItemSet? itemSet,
  int setPiecesWorn = 0,
  String? setLine,
  String? extraNote,
  String? originLine,
  int? count,
  String? wornBy,
  bool isWorn = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: ItemDetailView(
                  itemId: itemId,
                  item: item,
                  language: language,
                  equipped: equipped,
                  equippedId: equippedId,
                  equippedName: equippedName,
                  priceLine: priceLine,
                  unmetRequirement: unmetRequirement,
                  itemSet: itemSet,
                  setPiecesWorn: setPiecesWorn,
                  setLine: setLine,
                  extraNote: extraNote,
                  originLine: originLine,
                  count: count,
                  wornBy: wornBy,
                  isWorn: isWorn,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(trFor(language, 'close_button')),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAction == null
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              onAction();
                            },
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
