// The marks screen's Perks and Looks (v2.10.1, UX-2): the three tabs, the
// eight perks (owned, worn in a slot, bought for marks once the tree is
// full) and the five banner trims. Prices, slots and words are Core's and
// Narrative's (towerPerks, towerTrims, TowerProgress); this file draws them.
// Marks are a pale square; a perk's picture is its letter until Art draws it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_coins.dart';
import '../../data/tower/tower_tables.dart' show towerRulesLive;
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../utils/pixel_icons/item_icons.dart' show ItemIcons;
import '../../utils/pixel_icons/pixel_icon.dart' show PixelIcon;
import '../../theme/stitched_ink.dart';
import 'ink/ink_palette.dart';
import 'tower_heat_view.dart' show towerSeamRadius;
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
                    borderRadius: BorderRadius.circular(towerSeamRadius),
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
        PixelIcon(ItemIcons.pathFor('marks'), size: IconSize.s16),
        const SizedBox(width: 4),
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
                borderRadius: BorderRadius.circular(towerSeamRadius),
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
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(towerSeamRadius),
          border: Border.all(color: inkPaper, width: 1.2)),
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
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(towerSeamRadius),
                  border: Border.all(color: inkPaper, width: 1)),
              child: Text(name.substring(0, 1),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: InkFonts.display, color: inkPaper)),
            ),
            name: name,
            line: tr(ref, perk.lineKeyFor(towerRulesLive)),
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
                    // One slot: just "Worn"; more: "Worn 1", "Worn 2".
                    towerPerkSlots == 1
                        ? tr(ref, 'tower_perk_worn')
                        : tr(ref, 'tower_perk_worn_n')
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

/// The door's perk slots (hidden while no perk is owned): one box a slot,
/// the perk worn there or "Slot n: choose"; a tap picks among the owned ones.
class TowerDoorPerks extends ConsumerWidget {
  const TowerDoorPerks({super.key});

  Future<void> _pick(
      BuildContext context, WidgetRef ref, int slot, List<String> worn) async {
    final progress = ref.read(towerProvider).value!.progress;
    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: inkBlack,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(towerSeamRadius),
            side: const BorderSide(color: inkPaper, width: 1.2)),
        children: [
          for (final id in progress.perks)
            SimpleDialogOption(
              key: Key('tower_door_pick_$id'),
              onPressed: () => Navigator.of(ctx).pop(id),
              child: Text(tr(ref, 'tower_perk_$id'),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: inkPaper)),
            ),
          SimpleDialogOption(
            key: const Key('tower_door_pick_none'),
            onPressed: () => Navigator.of(ctx).pop(''),
            child: Text(tr(ref, 'tower_back'),
                style: Theme.of(ctx)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: inkGrey)),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    final next = [...worn];
    while (next.length < towerPerkSlots) {
      next.add('');
    }
    next[slot] = chosen;
    await ref.read(towerProvider.notifier).wearPerks([
      for (final id in next)
        if (id.isNotEmpty) id
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(towerProvider).value!.progress;
    if (progress.perks.isEmpty) return const SizedBox.shrink();
    final worn = progress.wornPerks;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr(ref, 'tower_door_perks'),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontFamily: InkFonts.display, color: inkPaper)),
      const SizedBox(height: 6),
      Row(children: [
        for (var i = 0; i < towerPerkSlots; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              key: Key('tower_door_slot_$i'),
              onTap: () => _pick(context, ref, i, worn),
              child: Container(
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(towerSeamRadius),
                    color: inkBlack,
                    border: Border.all(
                        color: i < worn.length ? inkPaper : inkGrey,
                        width: i < worn.length ? 2.5 : 1)),
                child: Text(
                    i < worn.length
                        ? tr(ref, 'tower_perk_${worn[i]}')
                        : tr(ref, 'tower_door_slot')
                            .replaceAll('{n}', '${i + 1}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: i < worn.length ? inkPaper : inkGrey)),
              ),
            ),
          ),
        ],
      ]),
    ]);
  }
}
