import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/pixel_icon.dart';

/// One line of "what the spoils change": [label] (Gold, Dice, Bag...) going
/// from [before] to [after], with the picture of what changes. The engine
/// says it (see the loot changes function); the sheet only draws it.
class LootSheetLine {
  const LootSheetLine({
    required this.label,
    required this.before,
    required this.after,
    required this.icon,
    this.tone,
  });

  final String label;
  final String before;
  final String after;
  final Widget icon;

  /// The colour of the new value (the reward's own); the ink gold when null.
  final Color? tone;
}

/// One reward of the chest, as the sheet lists it under "Details".
class LootReward {
  const LootReward({
    required this.id,
    required this.name,
    required this.text,
    required this.icon,
    this.canUseNow = false,
    this.useLabel,
    this.useEnabled = true,
    this.detail,
    this.onTap,
  });

  final String id;
  final String name;
  final String text;
  final Widget icon;

  /// Whether it can be used on the spot (a piece of gear to put on, a healing
  /// potion to drink): the sheet then offers its switch.
  final bool canUseNow;

  /// What the switch says ("Equip", "Drink"); "Use right away" when null.
  final String? useLabel;

  /// False when the switch stands dim (nothing to heal for a potion).
  final bool useEnabled;

  /// What tells the choice under the text (a piece of gear's stats against
  /// the one worn), when there is one.
  final Widget? detail;

  /// Opens the reward in full (its sheet, with the same switch's action).
  final VoidCallback? onTap;
}

/// The spoils as a full-height sheet (design C, docs/proposals/
/// loot-dialog-designs.md): the chest and its rarity, what the spoils change
/// (before and after), each reward's text with its "Use right away" switch,
/// and one "Take" button that stays at the bottom. Scrolls when it is longer
/// than the phone.
class LootSheet extends StatelessWidget {
  const LootSheet({
    super.key,
    required this.language,
    required this.title,
    required this.chestAsset,
    required this.tierLabel,
    required this.changes,
    required this.rewards,
    required this.useNow,
    required this.onUseNow,
    required this.onTake,
    this.tierColor,
    this.footer,
    this.showHandle = true,
  });

  final AppLanguage language;
  final String title;
  final String chestAsset;
  final String tierLabel;
  final Color? tierColor;
  final List<LootSheetLine> changes;
  final List<LootReward> rewards;

  /// The rewards the player wants to use right away.
  final Set<String> useNow;
  final void Function(String id, bool on) onUseNow;
  final VoidCallback onTake;

  /// Under the details (the chest's fortune roll), when there is one.
  final Widget? footer;

  /// The grip of a sheet pulled up from the bottom; off when it sits in a
  /// page (the Tower's).
  final bool showHandle;

  String _t(String key) => trFor(language, key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final scheme = theme.colorScheme;
    final tier = tierColor ?? ink.ash;
    final label = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant, fontFamily: InkFonts.system);
    return Material(
      key: const Key('loot_sheet'),
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(children: [
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              children: [
                Row(children: [
                  PixelIcon(chestAsset, size: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          Text(tierLabel,
                              key: const Key('loot_sheet_tier'),
                              style: label?.copyWith(color: tier)),
                        ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(_t('loot_sheet_changes'), style: label),
                const SizedBox(height: 8),
                for (final c in changes) _changeRow(theme, ink, c, label),
                const SizedBox(height: 6),
                Text(_t('loot_sheet_details'), style: label),
                const SizedBox(height: 6),
                for (final r in rewards) _rewardRow(theme, ink, r),
                if (footer != null) ...[const SizedBox(height: 6), footer!],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('loot_sheet_take'),
                onPressed: onTake,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_t('chest_take_button')),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _changeRow(
      ThemeData theme, InkColors ink, LootSheetLine c, TextStyle? label) {
    final scheme = theme.colorScheme;
    final tone = c.tone ?? ink.gold;
    return Container(
      key: Key('loot_change_${c.label}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        SizedBox(width: 36, child: Center(child: c.icon)),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.label, style: label),
            const SizedBox(height: 2),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Text(c.before,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: InkFonts.system,
                        color: scheme.onSurfaceVariant)),
                Icon(Icons.arrow_forward,
                    size: 14, color: scheme.onSurfaceVariant),
                Text(c.after,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: InkFonts.system,
                        color: tone,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _rewardRow(ThemeData theme, InkColors ink, LootReward r) {
    final scheme = theme.colorScheme;
    final row = Padding(
      key: Key('loot_reward_${r.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 32, child: Center(child: r.icon)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: theme.textTheme.titleSmall),
            Text(r.text,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            if (r.detail != null) r.detail!,
            if (r.canUseNow)
              Row(children: [
                Icon(Icons.bolt, size: 16, color: ink.heal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(r.useLabel ?? _t('loot_use_now'),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: ink.heal, fontFamily: InkFonts.system)),
                ),
                Switch(
                  key: Key('loot_use_${r.id}'),
                  value: useNow.contains(r.id),
                  onChanged: r.useEnabled ? (on) => onUseNow(r.id, on) : null,
                ),
              ]),
          ]),
        ),
      ]),
    );
    if (r.onTap == null) return row;
    return InkWell(
      key: Key('loot_open_${r.id}'),
      onTap: r.onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}
