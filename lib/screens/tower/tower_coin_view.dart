// The Tower's coins on its screens (v2.10.1, UX-2): the chip under the floor's
// number and the card table's Reroll and Banish. Prices, rules and words are
// Core's and Narrative's (tower_coins.dart, tower_* strings); this file draws
// them. Coins are a gold disc, marks a pale square, so the two never read
// alike; numbers are in the prose face (the pixel face reads a 5 like an S).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_coins.dart';
import '../../data/tower/tower_run.dart';
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';

/// The coin's gold: the one warm spot of the coin chip and the spoils line.
const Color _gold = Color(0xFFD9B44A);

/// A gold disc: the coin.
class TowerCoinDisc extends StatelessWidget {
  const TowerCoinDisc({super.key, this.size = IconSize.s16});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold,
            border: Border.all(color: inkBlack, width: 1.5)),
      );
}

/// The run's coins, from the first floor: the disc and the number.
class TowerCoinChip extends ConsumerWidget {
  const TowerCoinChip({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        key: const Key('tower_coin_chip'),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: inkBlack, border: Border.all(color: inkGrey, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const TowerCoinDisc(),
          const SizedBox(width: 6),
          Text(tr(ref, 'tower_coins_chip').replaceAll('{n}', '$coins'),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontFamily: InkFonts.prose, color: inkPaper)),
        ]),
      );
}

/// The table's Reroll button with its price (grey when the coins fall short),
/// and Banish for the card in hand (asks first).
class TowerTableCoinRow extends ConsumerWidget {
  const TowerTableCoinRow(
      {super.key,
      required this.run,
      required this.held,
      required this.onReroll,
      required this.onBanish});

  final TowerRun run;

  /// The card in hand.
  final int held;
  final VoidCallback onReroll;
  final ValueChanged<int> onBanish;

  Future<void> _ask(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: inkBlack,
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: inkPaper, width: 1.2)),
        content: Text(tr(ref, 'tower_banish_confirm'),
            style:
                Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: inkPaper)),
        actions: [
          TextButton(
              key: const Key('tower_banish_no'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(tr(ref, 'tower_back'))),
          InkButton(
              buttonKey: const Key('tower_banish_yes'),
              primary: true,
              label: tr(ref, 'tower_banish'),
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (yes ?? false) onBanish(held);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReroll = towerCanReroll(run);
    final price = towerRerollPriceOf(run);
    final canBanish = towerCanBanish(run, held);
    final left = towerBanishesPerRun - run.banished.length;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 10, runSpacing: 8, children: [
        if (canReroll)
          InkButton(
            buttonKey: const Key('tower_reroll'),
            label: price == 0
                ? tr(ref, 'tower_reroll')
                : tr(ref, 'tower_reroll_price').replaceAll('{n}', '$price'),
            onPressed: price <= run.coins ? onReroll : null,
          ),
        if (canBanish && left > 0)
          InkButton(
            buttonKey: const Key('tower_banish'),
            label: '${tr(ref, 'tower_banish')} · $towerBanishPrice',
            onPressed: () => _ask(context, ref),
          ),
      ]),
    );
  }
}
