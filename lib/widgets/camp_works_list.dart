import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_works.dart';
import '../data/materials.dart';
import '../data/skill_craft.dart' show skillCraftOpen;
import '../l10n/app_strings.dart';
import '../providers/camp_works_provider.dart';
import '../screens/skills/skill_sheet.dart' show openCraft;
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart' show ItemPixelIcon;
import 'camp_build_tray.dart' show SlotChip, slotText;
import 'sheet_kit.dart';

/// The building screen's list of houses (docs/proposals/building-screen.md):
/// four sections read from [campWorksProvider], each house a card by state
/// (built, ready, missing something, or a silhouette that has not come yet).
/// A tap on a card selects it (the town outlines where it would go) and
/// opens a sheet that says everything the card says, with where each
/// missing thing is found.
class CampWorksList extends ConsumerWidget {
  const CampWorksList({
    super.key,
    required this.houses,
    required this.shops,
    required this.zones,
    required this.itemNames,
    required this.companionNames,
    required this.selectedId,
    required this.detailOf,
    required this.onSelect,
    required this.onBuild,
    this.works,
    this.busy = false,
  });

  /// The works to list (the tray's filtered ones); null lists them all.
  final Map<WorkCategory, List<CampWork>>? works;

  /// The localised houses, every one (the locked included).
  final Map<String, dynamic> houses;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> zones;
  final Map<String, String> itemNames;
  final Map<String, String> companionNames;
  final String? selectedId;

  /// What a house gives, in a line.
  final String Function(String houseId) detailOf;
  final void Function(String houseId) onSelect;
  final void Function(String houseId) onBuild;

  /// True while something else is being raised: Build waits.
  final bool busy;

  String _nameOf(String id) =>
      (houses[id] as Map?)?['houseName']?.toString() ?? id;

  String _zoneName(String id) =>
      (zones[id] as Map?)?['zoneName']?.toString() ?? id;

  String _shopName(String id) =>
      (shops[id] as Map?)?['shopName']?.toString() ?? id;

  String _itemName(String id) => itemNames[id] ?? id;

  List<String> _zoneNames(WorkNeed need) =>
      [for (final id in need.zoneIds) _zoneName(id)];

  /// One short line for [need], as a card shows it.
  String _needLine(WidgetRef ref, WorkNeed need) {
    switch (need.kind) {
      case WorkNeedKind.chapter:
        return tr(ref, 'works_need_chapter').replaceAll('{n}', need.id);
      case WorkNeedKind.ally:
        return tr(ref, 'works_need_ally')
            .replaceAll('{name}', companionNames[need.id] ?? need.id);
      case WorkNeedKind.flag:
        final names = _zoneNames(need);
        return names.isEmpty
            ? tr(ref, 'works_need_flag_other')
            : tr(ref, 'works_need_flag').replaceAll('{zones}', names.first);
      case WorkNeedKind.gold:
        return tr(ref, 'works_need_gold')
            .replaceAll('{have}', '${need.have}')
            .replaceAll('{need}', '${need.need}');
      case WorkNeedKind.material:
        return tr(ref, 'works_need_item')
            .replaceAll('{item}', _itemName(need.id))
            .replaceAll('{have}', '${need.have}')
            .replaceAll('{need}', '${need.need}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<WorkCategory, List<CampWork>> works =
        this.works ?? ref.watch(campWorksProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in WorkCategory.values)
          if ((works[category] ?? const []).isNotEmpty) ...[
            _SectionHeader(
              key: Key('works_section_${category.name}'),
              title: tr(ref, 'works_category_${category.name}'),
              blurb: tr(ref, 'works_category_${category.name}_blurb'),
              count:
                  '${works[category]!.where((w) => w.state == WorkState.built).length}'
                  '/${works[category]!.length}',
              theme: theme,
              ink: ink,
            ),
            for (final work in works[category]!) _card(context, ref, work),
          ],
      ],
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, CampWork work) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final id = work.houseId;
    final house = (houses[id] as Map?)?.cast<String, dynamic>() ?? const {};
    final locked = work.state == WorkState.locked;
    final built = work.state == WorkState.built;
    final ready = work.state == WorkState.buildable;
    final selected = id == selectedId && !built;
    final (String tag, Color tagColour) = switch (work.state) {
      WorkState.built => (tr(ref, 'house_built_prefix'), ink.heal),
      WorkState.buildable => (tr(ref, 'town_ready'), ink.gold),
      WorkState.shown => (tr(ref, 'works_tag_missing'), ink.ember),
      WorkState.locked => (_needLine(ref, work.needs.first), ink.ash),
    };
    final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
    final materials = materialCountsOf(house, 'materialCost');
    final short = {
      for (final need in work.needs)
        if (need.kind == WorkNeedKind.material) need.id: need.need - need.have,
    };
    final goldShort = work.needs.any((n) => n.kind == WorkNeedKind.gold);
    final showCost = !built && !locked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('town_card_$id'),
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          onSelect(id);
          _showSheet(context, ref, work);
        },
        child: Opacity(
          opacity: locked ? 0.7 : 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: locked
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: selected ? theme.colorScheme.primary : ink.seam),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (locked) ...[
                      Container(
                        key: Key('works_silhouette_$id'),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink.seam.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('?',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: ink.ash)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(_nameOf(id),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: locked ? ink.ash : null)),
                    ),
                    if (slotText(work.limit.built, work.limit.limit)
                        case final slot?) ...[
                      const SizedBox(width: 8),
                      SlotChip(key: Key('town_slot_$id'), text: slot),
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
                // A house that has not come carries no word of what it
                // gives: no spoiler.
                if (!locked) ...[
                  const SizedBox(height: 4),
                  Text(detailOf(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: ink.ash, height: 1.3)),
                ],
                if (showCost) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    key: Key('town_materials_$id'),
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      for (final e in materials.entries)
                        _CostChip(
                          key: Key('town_material_${e.key}'),
                          icon: ItemPixelIcon(e.key, 'Material', size: 18),
                          tooltip: _itemName(e.key),
                          text: short.containsKey(e.key)
                              ? '${e.value - short[e.key]!}/${e.value}'
                              : '${e.value}',
                          short: short.containsKey(e.key),
                        ),
                      _CostChip(
                        key: Key('town_gold_$id'),
                        icon: Text('G',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: ink.gold)),
                        text: '$cost',
                        short: goldShort,
                      ),
                    ],
                  ),
                ],
                if (work.state == WorkState.shown) ...[
                  const SizedBox(height: 6),
                  Text(_needLine(ref, work.needs.first),
                      key: Key('works_first_need_$id'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.ember)),
                ],
                if (ready) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    key: Key('town_build_$id'),
                    onPressed: busy ? null : () => onBuild(id),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text('${tr(ref, 'build_button')} · $cost G'),
                  ),
                ],
                // The Skillwright, once up, is where skills are crafted.
                if (built && skillCraftOpen([id])) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: Key('works_craft_$id'),
                    onPressed: () => openCraft(context, ref),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: Text(tr(ref, 'craft_skill_button')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Everything the card says, in full, with where each missing thing comes
  /// from: the expeditions that pay a material or set a flag, the shops that
  /// stock it. Sources are plain names.
  void _showSheet(BuildContext context, WidgetRef ref, CampWork work) {
    if (work.state == WorkState.built) return;
    final id = work.houseId;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final ink = InkColors.of(sheetContext);
        final locked = work.state == WorkState.locked;
        final ready = work.state == WorkState.buildable;
        final house = (houses[id] as Map?)?.cast<String, dynamic>() ?? const {};
        final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
        Widget row(Widget key, Widget body) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 92, child: key),
                  const SizedBox(width: 8),
                  Expanded(child: body),
                ],
              ),
            );
        Widget sources(String label, List<String> names) => Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: names.join(', ')),
              ]),
              style: theme.textTheme.bodySmall,
            );
        return SafeArea(
          child: SingleChildScrollView(
            key: const Key('works_sheet'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(title: _nameOf(id), padding: EdgeInsets.zero),
                if (!locked) ...[
                  const SizedBox(height: 4),
                  Text(detailOf(id),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: ink.ash, height: 1.3)),
                ],
                // A house that can be built has no missing need to list:
                // say what it costs, as its card does.
                if (ready) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    key: Key('works_sheet_cost_$id'),
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      for (final e
                          in materialCountsOf(house, 'materialCost').entries)
                        _CostChip(
                          icon: ItemPixelIcon(e.key, 'Material', size: 18),
                          tooltip: _itemName(e.key),
                          text: '${e.value}',
                          short: false,
                        ),
                      PriceChip(cost),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                for (final need in work.needs)
                  row(
                    switch (need.kind) {
                      WorkNeedKind.material => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ItemPixelIcon(need.id, 'Material', size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                  '${_itemName(need.id)}\n'
                                  '${need.have}/${need.need}',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(color: ink.ember)),
                            ),
                          ],
                        ),
                      // The name and the count on one line, scaled down
                      // rather than stacked on a 320 px phone.
                      WorkNeedKind.gold => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${tr(ref, 'gold_field_label')} '
                              '${need.have}/${need.need}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: ink.ember)),
                        ),
                      _ => Text(tr(ref, 'works_sheet_needs'),
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: ink.ember)),
                    },
                    switch (need.kind) {
                      WorkNeedKind.chapter || WorkNeedKind.ally => Text(
                          _needLine(ref, need),
                          style: theme.textTheme.bodySmall),
                      WorkNeedKind.flag => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _zoneNames(need).isEmpty
                                    ? tr(ref, 'works_need_flag_other')
                                    : tr(ref, 'works_need_flag').replaceAll(
                                        '{zones}', _zoneNames(need).join(', ')),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      WorkNeedKind.gold => Text(
                          tr(ref, 'works_sheet_gold_more')
                              .replaceAll('{n}', '${need.need - need.have}'),
                          style: theme.textTheme.bodySmall),
                      WorkNeedKind.material => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (need.zoneIds.isNotEmpty)
                              sources(tr(ref, 'works_sheet_expeditions'),
                                  _zoneNames(need)),
                            if (need.shopIds.isNotEmpty)
                              sources(tr(ref, 'works_sheet_shops'),
                                  [for (final s in need.shopIds) _shopName(s)])
                            else
                              Text(tr(ref, 'works_sheet_no_shop'),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: ink.ash)),
                          ],
                        ),
                    },
                  ),
                const SizedBox(height: 8),
                if (!locked)
                  SheetButtons(
                    primaryKey: const Key('works_sheet_build'),
                    primaryLabel: tr(ref, 'build_button'),
                    price: ready ? cost : null,
                    onPrimary: ready && !busy
                        ? () {
                            Navigator.of(sheetContext).pop();
                            onBuild(id);
                          }
                        : null,
                    closeKey: const Key('works_sheet_close'),
                    closeLabel: tr(ref, 'close_button'),
                    onClose: () => Navigator.of(sheetContext).pop(),
                  )
                else
                  OutlinedButton(
                    key: const Key('works_sheet_close'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(tr(ref, 'close_button')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.blurb,
    required this.count,
    required this.theme,
    required this.ink,
  });

  final String title;
  final String blurb;
  final String count;
  final ThemeData theme;
  final InkColors ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(letterSpacing: 1.2, color: ink.gold)),
              ),
              Text(count,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
          const SizedBox(height: 2),
          Text(blurb,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

/// One cost on a card: its icon and the count, in the ember colour while
/// short ("1/3").
class _CostChip extends StatelessWidget {
  const _CostChip({
    super.key,
    required this.icon,
    required this.text,
    required this.short,
    this.tooltip,
  });

  final Widget icon;
  final String text;
  final bool short;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Text(text,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: short ? ink.ember : ink.ash)),
      ],
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }
}
