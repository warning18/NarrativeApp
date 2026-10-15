// The camp's building tray (v1.350): two tabs, Houses and Additions, and
// under them the filters that cut the list down: what is ready, what the
// purse and the pack can pay for, what already stands, and (for houses) the
// category. Each card carries a "built / limit" slot. The tray holds no
// state of its own; the town section owns the tab and the filters.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_works.dart';
import '../data/cliff_town.dart' show TownAddition;
import '../l10n/app_strings.dart';
import '../providers/camp_works_provider.dart';
import '../theme/stitched_ink.dart';

/// What the filter row keeps: the works ready to go up, those the gold and
/// the pack can pay for (whatever else they wait on), or those that stand.
enum BuildFilter { ready, affordable, built }

/// Whether [work] can be paid for now: not up, not locked, short of neither
/// gold nor materials (a flag or a chapter may still stand in the way).
bool workAffordable(CampWork work) =>
    work.state != WorkState.built &&
    work.state != WorkState.locked &&
    !work.needs.any(
        (n) => n.kind == WorkNeedKind.gold || n.kind == WorkNeedKind.material);

/// Whether [work] passes [filter] (null: all) and [category] (null: all).
bool workPasses(CampWork work, {BuildFilter? filter, WorkCategory? category}) {
  if (category != null && work.category != category) return false;
  return switch (filter) {
    null => true,
    BuildFilter.ready => work.state == WorkState.buildable,
    BuildFilter.affordable => workAffordable(work),
    BuildFilter.built => work.state == WorkState.built,
  };
}

/// [works] cut down to what passes, the empty categories dropped.
Map<WorkCategory, List<CampWork>> filteredWorks(
  Map<WorkCategory, List<CampWork>> works, {
  BuildFilter? filter,
  WorkCategory? category,
}) =>
    {
      for (final MapEntry(:key, :value) in works.entries)
        if (value.any((w) => workPasses(w, filter: filter, category: category)))
          key: [
            for (final w in value)
              if (workPasses(w, filter: filter, category: category)) w
          ],
    };

/// One town addition as the tray lists it: how many stand, how many the
/// town may hold ([limit] null: no limit), and whether the purse can pay.
class AdditionStatus {
  const AdditionStatus({
    required this.addition,
    required this.built,
    required this.limit,
    required this.gold,
  });

  final TownAddition addition;
  final int built;
  final int? limit;
  final int gold;

  bool get atLimit => limit != null && built >= limit!;
  bool get goldEnough => gold >= addition.cost;
  bool get ready => goldEnough && !atLimit;

  bool passes(BuildFilter? filter) => switch (filter) {
        null => true,
        BuildFilter.ready || BuildFilter.affordable => ready,
        BuildFilter.built => built > 0,
      };
}

/// The "built / limit" slot of a card ("1/1", "2/3"; "×2" with no limit,
/// nothing for a work with none standing and no limit). Null when there is
/// nothing to say.
String? slotText(int built, int? limit) {
  if (limit != null) return '$built/$limit';
  return built > 0 ? '×$built' : null;
}

class CampBuildTray extends ConsumerWidget {
  const CampBuildTray({
    super.key,
    required this.showAdditions,
    required this.onShowAdditions,
    required this.filter,
    required this.onFilter,
    required this.category,
    required this.onCategory,
    required this.gold,
    required this.houseList,
    required this.additions,
    required this.selectedId,
    required this.onSelectAddition,
    required this.onBuildAddition,
    this.busy = false,
  });

  final bool showAdditions;
  final ValueChanged<bool> onShowAdditions;
  final BuildFilter? filter;
  final ValueChanged<BuildFilter?> onFilter;
  final WorkCategory? category;
  final ValueChanged<WorkCategory?> onCategory;
  final int gold;

  /// The houses' list, given the works to show (see [filteredWorks]).
  final Widget Function(Map<WorkCategory, List<CampWork>> works) houseList;
  final List<AdditionStatus> additions;
  final String? selectedId;
  final void Function(String id) onSelectAddition;
  final void Function(String id) onBuildAddition;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final works = ref.watch(campWorksProvider);
    final allWorks = [for (final list in works.values) ...list];
    final housesBuilt =
        allWorks.where((w) => w.state == WorkState.built).length;

    // What each filter would keep, counted under the others' choices.
    int countOf(BuildFilter f) => showAdditions
        ? additions.where((a) => a.passes(f)).length
        : allWorks
            .where((w) => workPasses(w, filter: f, category: category))
            .length;
    final readyCount = showAdditions
        ? additions.where((a) => a.ready).length
        : allWorks.where((w) => w.state == WorkState.buildable).length;

    final shownWorks = filteredWorks(works, filter: filter, category: category);
    final shownAdditions = [
      for (final a in additions)
        if (a.passes(filter)) a
    ];
    final empty = showAdditions ? shownAdditions.isEmpty : shownWorks.isEmpty;

    Widget tab(String key, String label, String count, bool selected,
        VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          key: Key(key),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: selected ? ink.gold : ink.seam,
                    width: selected ? 2.5 : 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: selected ? ink.gold : ink.ash,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400)),
                ),
                const SizedBox(width: 6),
                Text(count,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: selected ? ink.gold : ink.ash)),
              ],
            ),
          ),
        ),
      );
    }

    Widget chip(String key, String label, bool selected, VoidCallback onTap,
        {Color? color}) {
      final tone = color ?? ink.gold;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          key: Key(key),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          labelStyle: theme.textTheme.labelMedium
              ?.copyWith(color: selected ? tone : null),
          selectedColor: tone.withValues(alpha: 0.2),
          side: BorderSide(color: selected ? tone : ink.seam),
          onSelected: (_) => onTap(),
        ),
      );
    }

    final filters = SingleChildScrollView(
      key: const Key('town_filters'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in BuildFilter.values)
            chip(
              'town_filter_${f.name}',
              '${tr(ref, 'town_filter_${f.name}')} ${countOf(f)}',
              filter == f,
              () => onFilter(filter == f ? null : f),
              color: switch (f) {
                BuildFilter.ready => ink.gold,
                BuildFilter.affordable => ink.tide,
                BuildFilter.built => ink.heal,
              },
            ),
          if (!showAdditions) ...[
            Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.only(right: 6),
                color: ink.seam),
            for (final c in WorkCategory.values)
              chip(
                'town_category_${c.name}',
                tr(ref, 'works_chip_${c.name}'),
                category == c,
                () => onCategory(category == c ? null : c),
                color: ink.ash,
              ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            tab(
                'town_tab_houses',
                tr(ref, 'houses_section'),
                '$housesBuilt/${allWorks.length}',
                !showAdditions,
                () => onShowAdditions(false)),
            tab(
                'town_tab_additions',
                tr(ref, 'town_additions_tab'),
                '${additions.fold<int>(0, (n, a) => n + a.built)}',
                showAdditions,
                () => onShowAdditions(true)),
          ],
        ),
        const SizedBox(height: 8),
        // The purse and what it can raise now.
        Text(
          '$gold G · '
          '${tr(ref, 'town_ready_count').replaceAll('{n}', '$readyCount')}',
          key: const Key('town_purse'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: readyCount > 0 ? ink.gold : ink.ash),
        ),
        const SizedBox(height: 6),
        filters,
        const SizedBox(height: 8),
        if (empty)
          _Empty(
            onClear: () {
              onFilter(null);
              onCategory(null);
            },
          )
        else if (showAdditions)
          for (final a in shownAdditions)
            _AdditionCard(
              status: a,
              selected: a.addition.id == selectedId,
              onSelect: () => onSelectAddition(a.addition.id),
              onBuild: busy ? null : () => onBuildAddition(a.addition.id),
            )
        else
          houseList(shownWorks),
      ],
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      key: const Key('town_filter_empty'),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: ink.seam),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(tr(ref, 'town_filter_empty'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('town_filter_clear'),
            onPressed: onClear,
            child: Text(tr(ref, 'town_filter_clear')),
          ),
        ],
      ),
    );
  }
}

/// A town addition as a card in the same style as a house's: its state, what
/// it gives, its price, the "built / limit" slot and the Build button.
class _AdditionCard extends ConsumerWidget {
  const _AdditionCard({
    required this.status,
    required this.selected,
    required this.onSelect,
    required this.onBuild,
  });

  final AdditionStatus status;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final a = status.addition;
    final (String tag, Color tagColour) = status.atLimit
        ? (
            tr(ref, 'town_limit_short'),
            ink.ash,
          )
        : status.goldEnough
            ? (tr(ref, 'town_ready'), ink.gold)
            : (
                '${tr(ref, 'town_need')} ${a.cost - status.gold} G',
                ink.ember,
              );
    final slot = slotText(status.built, status.limit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('town_card_${a.id}'),
        borderRadius: BorderRadius.circular(4),
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: selected ? theme.colorScheme.primary : ink.seam),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tr(ref, '${a.id}_name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  if (slot != null) ...[
                    const SizedBox(width: 8),
                    SlotChip(key: Key('town_slot_${a.id}'), text: slot),
                  ],
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: InkTag(label: tag, color: tagColour),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(tr(ref, '${a.id}_desc'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: ink.ash, height: 1.3)),
              const SizedBox(height: 6),
              Text('${a.cost} G',
                  key: Key('town_gold_${a.id}'),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: status.goldEnough ? ink.ash : ink.ember)),
              if (status.atLimit) ...[
                const SizedBox(height: 6),
                Text(
                    tr(ref, 'town_limit_reached')
                        .replaceAll('{built}', '${status.built}')
                        .replaceAll('{limit}', '${status.limit}'),
                    style:
                        theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
              ] else ...[
                const SizedBox(height: 8),
                FilledButton(
                  key: Key('town_build_${a.id}'),
                  onPressed: status.goldEnough ? onBuild : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(status.goldEnough
                      ? '${tr(ref, 'build_button')} · ${a.cost} G'
                      : '${a.cost} G'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The small "built / limit" figure on a card.
class SlotChip extends ConsumerWidget {
  const SlotChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Tooltip(
      message: tr(ref, 'town_slot_hint'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: ink.seam),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
      ),
    );
  }
}
