// The marks screen's Perks and Looks (v2.10.1, UX-2): the three tabs, the
// eight perks (owned, worn in a slot, bought for marks once the tree is
// full) and the five banner trims. Prices, slots and words are Core's and
// Narrative's (towerPerks, towerTrims, TowerProgress); this file draws them.
// Marks are a pale square; a perk's picture is its letter until Art draws it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_coins.dart';
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import 'ink/ink_palette.dart';
import 'tower_providers.dart';

/// Unlocks | Perks | Looks.
class TowerMarksTabs extends ConsumerWidget {
  const TowerMarksTabs({super.key, required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const keys = [
      'tower_marks_tab_unlocks',
      'tower_marks_tab_perks',
      'tower_marks_tab_looks',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              key: Key('tower_marks_tab_$i'),
              onTap: () => onTab(i),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: i == tab ? inkPaper : inkBlack,
                    border: Border.all(color: inkPaper, width: 1.2)),
                child: Text(tr(ref, keys[i]),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: InkFonts.display,
                        color: i == tab ? inkOnPaper : inkPaper)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// A pale square and the number: marks.
class _MarksCost extends StatelessWidget {
  const _MarksCost(this.n);

  final int n;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
            width: 10, height: 10, child: ColoredBox(color: inkGrey)),
        const SizedBox(width: 5),
        Text('$n',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontFamily: InkFonts.prose, color: inkPaper)),
      ]);
}

/// One row: [lead], a name, a line, and what stands on the right.
class _ShopRow extends StatelessWidget {
  const _ShopRow(
      {super.key,
      required this.lead,
      required this.name,
      required this.line,
      required this.trailing,
      this.on = false,
      this.dim = false,
      this.onTap});

  final Widget lead;
  final String name;
  final String line;
  final Widget trailing;
  final bool on;
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: dim ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: inkBlack,
                border: Border.all(
                    color: on ? inkPaper : inkGrey, width: on ? 2.5 : 1)),
            child: Row(children: [
              lead,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontFamily: InkFonts.display, color: inkPaper)),
                      if (line.isNotEmpty)
                        Text(line,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: inkPaper)),
                    ]),
              ),
              const SizedBox(width: 8),
              trailing,
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _status(BuildContext context, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(border: Border.all(color: inkPaper, width: 1.2)),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontFamily: InkFonts.prose, color: inkPaper)),
    );

/// The eight perks: a worn one says its slot, an owned one can be put on or
/// off with a tap, one not owned is bought with its marks.
class TowerPerksTab extends ConsumerWidget {
  const TowerPerksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(towerProvider).value!.progress;
    final notifier = ref.read(towerProvider.notifier);
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr(ref, 'tower_perks_hint'),
          style: theme.textTheme.bodySmall?.copyWith(color: inkGrey)),
      const SizedBox(height: 8),
      for (final perk in towerPerks)
        () {
          final owned = progress.perks.contains(perk.id);
          final slot = progress.worn.indexOf(perk.id);
          final name = tr(ref, perk.nameKey);
          return _ShopRow(
            key: Key('tower_perk_${perk.id}'),
            lead: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(border: Border.all(color: inkPaper, width: 1)),
              child: Text(name.substring(0, 1),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: InkFonts.display, color: inkPaper)),
            ),
            name: name,
            line: tr(ref, perk.lineKey),
            on: slot >= 0,
            dim: !owned && !progress.canBuyPerk(perk.id),
            onTap: owned
                ? () => notifier.toggleWorn(perk.id)
                : progress.canBuyPerk(perk.id)
                    ? () => notifier.buyPerk(perk.id)
                    : null,
            trailing: slot >= 0
                ? _status(
                    context,
                    tr(ref, 'tower_perk_worn_n')
                        .replaceAll('{n}', '${slot + 1}'))
                : owned
                    ? _status(context, tr(ref, 'tower_perk_owned'))
                    : _MarksCost(perk.cost),
          );
        }(),
    ]);
  }
}

/// The banner trims: five sold for marks, the Ash trim earned at Ash. An
/// owned one is shown with a tap (a second tap shows none).
class TowerLooksTab extends ConsumerWidget {
  const TowerLooksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(towerProvider).value!.progress;
    final notifier = ref.read(towerProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final trim in [...towerTrims, towerAshTrim])
        () {
          final owned = progress.trimsOwned.contains(trim.id);
          final shown = progress.trim == trim.id;
          final ash = trim.id == towerAshTrim.id;
          return _ShopRow(
            key: Key('tower_trim_${trim.id}'),
            lead: SizedBox(
                width: 38,
                height: 18,
                child: ColoredBox(color: ash ? inkPaper : inkSlate)),
            name: tr(ref, trim.nameKey),
            line: '',
            on: shown,
            dim: !owned && !ash && !progress.canBuyTrim(trim.id),
            onTap: owned
                ? () => notifier.showTrim(shown ? null : trim.id)
                : !ash && progress.canBuyTrim(trim.id)
                    ? () => notifier.buyTrim(trim.id)
                    : null,
            trailing: shown
                ? _status(context, tr(ref, 'tower_perk_worn'))
                : owned
                    ? _status(context, tr(ref, 'tower_perk_owned'))
                    : ash
                        ? const SizedBox(width: IconSize.s16)
                        : _MarksCost(trim.cost),
          );
        }(),
    ]);
  }
}
