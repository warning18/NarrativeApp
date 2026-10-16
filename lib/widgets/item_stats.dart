import 'package:flutter/material.dart';

import '../combat/gear_effects.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

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

/// One trait of an item besides its numbers: the stat it scales with, its
/// unique effect, its alignment, a requirement it does not meet.
class ItemTrait {
  const ItemTrait(this.icon, this.label, this.value, {this.warn = false});
  final IconData icon;
  final String label;

  /// The part after the label ('' when the label says it all).
  final String value;

  /// A requirement the player does not meet.
  final bool warn;

  String note(AppLanguage lang) {
    // French typography: a no-break space before the colon.
    final colon = lang == AppLanguage.fr ? '\u00a0: ' : ': ';
    return value.isEmpty ? label : '$label$colon$value';
  }
}

List<ItemTrait> itemTraits(Map<String, dynamic>? item, AppLanguage lang,
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
    if (scaling != null)
      ItemTrait(Icons.trending_up, t('scales_with_label'), scaling),
    if (unique != null)
      ItemTrait(
          Icons.auto_awesome,
          t('unique_label'),
          t(uniqueEffectDescriptionKey(unique))
              .replaceAll('{v}', '${uniqueValueOf(item)}')),
    if (alignment.isNotEmpty)
      ItemTrait(
          Icons.balance,
          '${t('aligned_gear_label')} '
          '(${alignment == 'Good' ? t('alignment_good') : t('alignment_evil')})',
          alignedParts.join(', ')),
    if (unmetRequirement != null && unmetRequirement.isNotEmpty)
      ItemTrait(
          Icons.lock_outline, t('stat_requirement_label'), unmetRequirement,
          warn: true),
  ];
}

/// The short text a list row shows about [item] besides its stats: the
/// stat it scales with, its unique effect, its alignment, a requirement it
/// does not meet.
List<String> itemTraitNotes(Map<String, dynamic>? item, AppLanguage lang,
        {String? unmetRequirement}) =>
    [
      for (final trait
          in itemTraits(item, lang, unmetRequirement: unmetRequirement))
        trait.note(lang),
    ];

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
const int potionHealAmount = 6;

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
