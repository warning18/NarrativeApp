import 'package:flutter/material.dart';

import '../combat/gear_effects.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';

/// Gear stats in display order, each with its label key.
const List<(String, String)> gearStatKeys = [
  ('attackDamage', 'atk_abbrev'),
  ('armor', 'arm_abbrev'),
  ('fireDmgBonus', 'fire_dmg_label'),
  ('iceDmgBonus', 'ice_dmg_label'),
  ('waterDmgBonus', 'water_dmg_label'),
  ('windDmgBonus', 'wind_dmg_label'),
  ('earthDmgBonus', 'earth_dmg_label'),
  ('elecDmgBonus', 'elec_dmg_label'),
  ('lightDmgBonus', 'light_dmg_label'),
  ('voidDmgBonus', 'void_dmg_label'),
  ('fireResist', 'fire_resist_label'),
  ('iceResist', 'ice_resist_label'),
  ('waterResist', 'water_resist_label'),
  ('windResist', 'wind_resist_label'),
  ('earthResist', 'earth_resist_label'),
  ('elecResist', 'elec_resist_label'),
  ('lightResist', 'light_resist_label'),
  ('voidResist', 'void_resist_label'),
];

num _stat(Map<String, dynamic>? item, String key) => (item?[key] as num?) ?? 0;

/// Whether [item] is gear worn in a slot.
bool isGear(Map<String, dynamic>? item) =>
    (item?['isEquippable'] as bool? ?? false) &&
    (item?['equipSlot']?.toString() ?? '').isNotEmpty;

/// The id of the item worn in [slot] among [equippedIds], or null.
String? equippedInSlot(
    List<String> equippedIds, Map<String, dynamic> items, String slot) {
  for (final id in equippedIds) {
    final item = items[id] as Map<String, dynamic>?;
    if ((item?['equipSlot']?.toString() ?? '') == slot) return id;
  }
  return null;
}

/// The item worn in [item]'s own slot among [equippedIds] (null for an
/// item that is not gear, the same item, or an empty slot).
String? equippedCounterpart(String itemId, Map<String, dynamic>? item,
    List<String> equippedIds, Map<String, dynamic> items) {
  if (!isGear(item)) return null;
  final worn =
      equippedInSlot(equippedIds, items, item!['equipSlot'].toString());
  return worn == itemId ? null : worn;
}

/// One stat of [item] against the one worn in its slot: its value, the
/// worn item's, and the difference. Only stats either of them has.
class GearStatLine {
  const GearStatLine(this.label, this.value, this.equipped);
  final String label;
  final num value;
  final num equipped;
  num get delta => value - equipped;
}

List<GearStatLine> gearStatLines(Map<String, dynamic>? item,
    Map<String, dynamic>? equipped, AppLanguage lang) {
  return [
    for (final (key, labelKey) in gearStatKeys)
      if (_stat(item, key) != 0 || _stat(equipped, key) != 0)
        GearStatLine(
            trFor(lang, labelKey), _stat(item, key), _stat(equipped, key)),
  ];
}

String _fmt(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);

/// The short text a list row shows about [item] besides its stats: the
/// stat it scales with, its unique effect, its alignment, a requirement it
/// does not meet.
List<String> itemTraitNotes(Map<String, dynamic>? item, AppLanguage lang,
    {String? unmetRequirement}) {
  String t(String key) => trFor(lang, key);
  final scaling = switch (item?['scalingStat']?.toString() ?? '') {
    'strength' => t('str_abbrev'),
    'dexterity' => t('dex_abbrev'),
    'constitution' => t('con_abbrev'),
    'intelligence' => t('int_abbrev'),
    _ => null,
  };
  final unique = uniqueEffectOf(item);
  final alignment = item?['alignment']?.toString() ?? '';
  final alignedAttack = (item?['alignedAttackBonus'] as num?)?.toInt() ?? 0;
  final alignedArmor = (item?['alignedArmorBonus'] as num?)?.toInt() ?? 0;
  final alignedParts = [
    if (alignedAttack > 0) '${t('atk_abbrev')} +$alignedAttack',
    if (alignedArmor > 0) '${t('arm_abbrev')} +$alignedArmor',
  ];
  return [
    if (scaling != null) '${t('scales_with_label')}: $scaling',
    if (unique != null)
      '${t('unique_label')}: ${t(uniqueEffectDescriptionKey(unique)).replaceAll('{v}', '${uniqueValueOf(item)}')}',
    if (alignment.isNotEmpty)
      '${t('aligned_gear_label')} '
          '(${alignment == 'Good' ? t('alignment_good') : t('alignment_evil')})'
          '${alignedParts.isEmpty ? '' : ': ${alignedParts.join(', ')}'}',
    if (unmetRequirement != null && unmetRequirement.isNotEmpty)
      '${t('stat_requirement_label')}: $unmetRequirement',
  ];
}

/// What a consumable does when used, in plain words: a potion's heal, an
/// antidote's cure, a charm's effect for one fight, a tome's points. Null
/// for anything that is not used up.
String? consumableNote(
    String itemId, Map<String, dynamic>? item, AppLanguage lang) {
  String t(String key) => trFor(lang, key);
  switch (item?['itemType']?.toString() ?? '') {
    case 'Potion':
      if (itemId == 'antidote') return t('antidote_use_desc');
      final draughts = itemId == 'potion_major' ? 2 : 1;
      return t(draughts > 1 ? 'potion_major_use_desc' : 'potion_use_desc')
          .replaceAll('{hp}', '$potionHealAmount');
    case 'Charm':
      final key = '${itemId}_desc';
      final text = t(key);
      return text == key ? null : '${t('charm_use_prefix')} $text';
    case 'Tome':
      return t(itemId == 'tome_of_mastery'
          ? 'tome_skill_point_desc'
          : 'tome_stat_point_desc');
  }
  return null;
}

/// HP a healing potion restores (the fight screen reads the same value).
const int potionHealAmount = 30;

/// A row's stats at a glance: each stat as a chip, with a green or red
/// difference against the item worn in the same slot, so an item can be
/// picked without opening it.
class ItemStatChips extends StatelessWidget {
  const ItemStatChips({
    super.key,
    required this.item,
    required this.language,
    this.equipped,
    this.equippedName,
    this.compact = false,
  });

  final Map<String, dynamic>? item;
  final Map<String, dynamic>? equipped;
  final String? equippedName;
  final AppLanguage language;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lines = gearStatLines(item, equipped, language)
        .where((l) => l.value != 0 || equipped != null)
        .toList();
    final theme = Theme.of(context);
    final gear = isGear(item);
    final chips = <Widget>[
      for (final line in lines)
        if (line.value != 0 || line.delta != 0)
          _chip(context, line.label, _fmt(line.value),
              equipped == null && !gear ? null : line.delta),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(spacing: 4, runSpacing: 4, children: chips),
        if (!compact && gear) ...[
          const SizedBox(height: 2),
          Text(
            equipped == null
                ? trFor(language, 'slot_empty_compare_note')
                : '${trFor(language, 'compare_vs_label')} ${equippedName ?? ''}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String label, String value, num? delta) {
    final theme = Theme.of(context);
    final deltaColor = delta == null || delta == 0
        ? theme.colorScheme.onSurfaceVariant
        : delta > 0
            ? Colors.green.shade600
            : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label $value'),
          if (delta != null && delta != 0)
            TextSpan(
              text: ' ${delta > 0 ? '+' : ''}${_fmt(delta)}',
              style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold),
            ),
        ]),
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

/// A full look at one item: what it is, every stat beside the item worn in
/// the same slot with the difference, what it scales with, its unique
/// effect, set, alignment and requirement, and an action (buy, equip).
Future<void> showItemDetailsSheet(
  BuildContext context, {
  required String itemId,
  required Map<String, dynamic>? item,
  required AppLanguage language,
  Map<String, dynamic>? equipped,
  String? equippedName,
  String? priceLine,
  String? unmetRequirement,
  String? setLine,
  String? extraNote,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  String t(String key) => trFor(language, key);
  final name = item?['itemName']?.toString() ?? itemId;
  final type = item?['itemType']?.toString() ?? '';
  final slot = item?['equipSlot']?.toString() ?? '';
  final rarity = item?['rarity']?.toString() ?? '';
  final lines = gearStatLines(item, equipped, language);
  final notes =
      itemTraitNotes(item, language, unmetRequirement: unmetRequirement);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final gear = isGear(item);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ItemPixelIcon(itemId, type, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.titleMedium),
                          Text(
                            [
                              if (type.isNotEmpty) type,
                              if (slot.isNotEmpty) slot,
                              if (rarity.isNotEmpty) rarity,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (priceLine != null)
                            Text(priceLine, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _StatTable(
                    lines: lines,
                    showEquipped: gear,
                    equippedHeader: equipped == null
                        ? t('slot_empty_label')
                        : (equippedName ?? t('equipped_prefix')),
                    thisHeader: t('this_item_header'),
                  ),
                ],
                for (final note in notes) ...[
                  const SizedBox(height: 6),
                  Text(note, style: theme.textTheme.bodyMedium),
                ],
                if (setLine != null) ...[
                  const SizedBox(height: 6),
                  Text(setLine, style: theme.textTheme.bodyMedium),
                ],
                if (extraNote != null) ...[
                  const SizedBox(height: 6),
                  Text(extraNote,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(t('close_button')),
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
    },
  );
}

class _StatTable extends StatelessWidget {
  const _StatTable({
    required this.lines,
    required this.showEquipped,
    required this.equippedHeader,
    required this.thisHeader,
  });

  final List<GearStatLine> lines;
  final bool showEquipped;
  final String equippedHeader;
  final String thisHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final head =
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
    Widget cell(String text, {TextStyle? style, TextAlign? align}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Text(text,
              style: style ?? theme.textTheme.bodyMedium,
              textAlign: align ?? TextAlign.center),
        );
    return Table(
      columnWidths: showEquipped
          ? const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.6),
              3: FlexColumnWidth(1),
            }
          : const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.2)},
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          children: [
            cell('', align: TextAlign.left),
            cell(thisHeader, style: head),
            if (showEquipped) ...[
              cell(equippedHeader, style: head),
              cell('±', style: head),
            ],
          ],
        ),
        for (final line in lines)
          TableRow(children: [
            cell(line.label, align: TextAlign.left),
            cell(_fmt(line.value)),
            if (showEquipped) ...[
              cell(_fmt(line.equipped)),
              cell(
                line.delta == 0
                    ? '='
                    : '${line.delta > 0 ? '+' : ''}${_fmt(line.delta)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: line.delta == 0
                      ? null
                      : line.delta > 0
                          ? Colors.green.shade600
                          : theme.colorScheme.error,
                ),
              ),
            ],
          ]),
      ],
    );
  }
}
