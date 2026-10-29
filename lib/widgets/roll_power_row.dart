// The camp's roll houses on a choice sheet (docs/proposals/camp-roll-
// buildings.md, camp_rolls.dart): a row of up to three buttons under the
// cards, one per power whose house stands -- "Reroll (3)", "Banish (2)",
// "Raise (1)". Banish and Raise act on the selected card; Banish asks how
// long (5, 10 or 15 draws, 1 to 3 charges). Core's minimal row, for UX to
// restyle: each power is a small card with its icon, its name and
// its charges as pips, and Raise shows how near its next charge is; the stat
// pick and the clans' offer both use it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_rolls.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart' show wardTargetsProvider;
import '../theme/stitched_ink.dart';
import 'ward_sheet.dart';

class RollPowerRow extends ConsumerWidget {
  const RollPowerRow({
    super.key,
    required this.keyPrefix,
    required this.rolls,
    required this.onReroll,
    required this.onBanish,
    required this.onRaise,
    this.canBanish = false,
    this.canRaise = false,
    this.warnRaised = false,
  });

  /// The keys' prefix: `<prefix>_roll_reroll`, `_banish`, `_raise`.
  final String keyPrefix;
  final CampRolls rolls;
  final Future<void> Function() onReroll;
  final Future<void> Function(int draws) onBanish;
  final Future<void> Function() onRaise;

  /// A card is selected that may be warded / raised.
  final bool canBanish;
  final bool canRaise;

  /// A raised card is on the table: a reroll takes it too (warned once).
  final bool warnRaised;

  Future<void> _reroll(BuildContext context, WidgetRef ref) async {
    if (warnRaised) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(tr(ref, 'roll_reroll_warning')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(ref, 'offer_confirm_back')),
            ),
            FilledButton(
              key: Key('${keyPrefix}_roll_reroll_confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(ref, 'roll_reroll')
                  .replaceAll('{left}', '${rolls.reroll ?? 0}')),
            ),
          ],
        ),
      );
      if (go != true) return;
    }
    await onReroll();
  }

  /// What a Banish dialog answers when the player chose to ward the road.
  static const _ward = -1;

  Future<void> _banish(BuildContext context, WidgetRef ref) async {
    final charges = rolls.banish ?? 0;
    final canWard = ref.read(wardTargetsProvider).isNotEmpty;
    // No card to banish: only the road can be warded.
    if (!canBanish) {
      if (canWard) await showWardSheet(context);
      return;
    }
    final draws = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr(ref, 'roll_banish').replaceAll('{left}', '$charges')),
        children: [
          for (final length in banishLengths)
            SimpleDialogOption(
              key: Key('${keyPrefix}_roll_banish_$length'),
              onPressed: banishCostOf(length) <= charges
                  ? () => Navigator.pop(context, length)
                  : null,
              child: Opacity(
                opacity: banishCostOf(length) <= charges ? 1 : 0.4,
                child: Text(tr(ref, 'roll_banish_length')
                    .replaceAll('{draws}', '$length')
                    .replaceAll('{cost}', '${banishCostOf(length)}')),
              ),
            ),
          // The Warding Cairn's other use: keep a hunting clan off the trail.
          if (canWard) ...[
            const Divider(),
            SimpleDialogOption(
              key: Key('${keyPrefix}_roll_ward'),
              onPressed: () => Navigator.pop(context, _ward),
              child: Text(tr(ref, 'ward_choice')),
            ),
          ],
        ],
      ),
    );
    if (draws == _ward) {
      if (context.mounted) await showWardSheet(context);
    } else if (draws != null) {
      await onBanish(draws);
    }
  }

  /// A power's name without its count ("Reroll ({left})" says "Reroll").
  static String _nameOf(String text) =>
      text.replaceAll(RegExp(r'\s*\(?\{left\}\)?'), '').trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!rolls.any) return const SizedBox.shrink();
    Widget button(String key, IconData icon, int left, VoidCallback? onTap,
            {double? progress}) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PowerButton(
              key: Key('${keyPrefix}_roll_$key'),
              icon: icon,
              name: _nameOf(tr(ref, 'roll_$key')),
              left: left,
              onTap: left > 0 ? onTap : null,
              progress: progress,
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      // The powers stand as tall as the tallest (Raise carries a bar).
      child: IntrinsicHeight(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rolls.reroll case final left?)
            button('reroll', Icons.casino_outlined, left,
                () => _reroll(context, ref)),
          if (rolls.banish case final left?)
            button(
                'banish',
                Icons.block,
                left,
                canBanish || ref.watch(wardTargetsProvider).isNotEmpty
                    ? () => _banish(context, ref)
                    : null),
          if (rolls.raise case final left?)
            button('raise', Icons.keyboard_double_arrow_up, left,
                canRaise ? onRaise : null,
                progress: rolls.raiseProgress / raiseChargeEvery),
        ],
      )),
    );
  }
}

/// One power of the camp's roll houses: its icon, its name and its charges as
/// pips (up to six, then a count); dim when it cannot act now (no charge
/// left, or no card picked for the powers that act on one). The Raise button
/// also shows how near the next charge is as a thin bar.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    super.key,
    required this.icon,
    required this.name,
    required this.left,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String name;
  final int left;
  final VoidCallback? onTap;
  final double? progress;

  static const int _maxPips = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final on = onTap != null;
    final colour = on ? ink.gold : ink.ash;
    return Material(
      color: on
          ? ink.gold.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: on ? ink.gold : ink.seam),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Opacity(
            opacity: on ? 1 : 0.55,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: colour),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(name,
                      maxLines: 1,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: on ? null : ink.ash)),
                ),
                const SizedBox(height: 3),
                if (left <= _maxPips)
                  Row(
                    key: const Key('roll_pips'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < left; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: colour),
                        ),
                      if (left == 0)
                        Text('0',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.ash)),
                    ],
                  )
                else
                  Text('×$left',
                      key: const Key('roll_pips'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: colour)),
                if (progress != null) ...[
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1.5),
                    child: LinearProgressIndicator(
                      key: const Key('roll_progress'),
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 3,
                      color: ink.gold,
                      backgroundColor: ink.seam,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
