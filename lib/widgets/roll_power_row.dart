// The camp's roll houses on a choice sheet (docs/proposals/camp-roll-
// buildings.md, camp_rolls.dart): a row of up to three buttons under the
// cards, one per power whose house stands -- "Reroll (3)", "Banish (2)",
// "Raise (1)". Banish and Raise act on the selected card; Banish asks how
// long (5, 10 or 15 draws, 1 to 3 charges). Core's minimal row, for UX to
// restyle; the stat pick and the clans' offer both use it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_rolls.dart';
import '../l10n/app_strings.dart';

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

  Future<void> _banish(BuildContext context, WidgetRef ref) async {
    final charges = rolls.banish ?? 0;
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
        ],
      ),
    );
    if (draws != null) await onBanish(draws);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!rolls.any) return const SizedBox.shrink();
    Widget button(String key, int left, VoidCallback? onTap) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: OutlinedButton(
              key: Key('${keyPrefix}_roll_$key'),
              onPressed: left > 0 ? onTap : null,
              child: FittedBox(
                child: Text(tr(ref, 'roll_$key').replaceAll('{left}', '$left')),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (rolls.reroll case final left?)
            button('reroll', left, () => _reroll(context, ref)),
          if (rolls.banish case final left?)
            button(
                'banish', left, canBanish ? () => _banish(context, ref) : null),
          if (rolls.raise case final left?)
            button('raise', left, canRaise ? onRaise : null),
        ],
      ),
    );
  }
}
