// The My skills tab: what the character knows, grouped by branch, one row
// each -- what it does now, its tier in dots and what the next tier costs
// -- with one row of filters and the way to craft. A companion's screen is
// this list alone: their class's skills, learned one point each.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/face_style.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import 'skill_sheet.dart';
import 'skill_tree_view.dart' show TierPips;
import 'skills_view_model.dart';

/// What the filter row picks by.
enum SkillFilter { all, attack, heal, mana, status }

bool _passes(SkillFilter filter, FaceKind kind) => switch (filter) {
      SkillFilter.all => true,
      SkillFilter.attack => kind == FaceKind.attack,
      SkillFilter.heal => kind == FaceKind.heal,
      SkillFilter.mana => kind == FaceKind.mana,
      SkillFilter.status => kind == FaceKind.poison ||
          kind == FaceKind.stun ||
          kind == FaceKind.weaken,
    };

class MySkillsView extends ConsumerStatefulWidget {
  const MySkillsView({super.key, required this.model, this.allyId, this.note});

  final SkillsModel model;

  /// The companion whose list this is (their class's skills, learnable).
  final String? allyId;

  /// A line over a companion's list.
  final String? note;

  @override
  ConsumerState<MySkillsView> createState() => _MySkillsViewState();
}

class _MySkillsViewState extends ConsumerState<MySkillsView> {
  SkillFilter _filter = SkillFilter.all;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    // A companion's list shows what they can learn too; the player's only
    // what they know (learning is the tree's).
    final shown = model.isPlayer
        ? [for (final id in model.knownIds) model[id]!]
        : model.entries.values.toList();
    int count(SkillFilter f) => shown.where((e) => _passes(f, e.kind)).length;
    final visible = shown.where((e) => _passes(_filter, e.kind)).toList();

    // The player's in branch order: each branch, the heritage, the rest.
    final groups = <(String?, List<SkillEntry>)>[];
    if (model.isPlayer) {
      for (final branch in model.branches) {
        final onIt = [
          for (final id in branch.skillIds)
            if (visible.any((e) => e.id == id)) model[id]!
        ];
        if (onIt.isNotEmpty) groups.add((branch.name, onIt));
      }
      final rest = visible.where((e) => e.branch == null).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (rest.isNotEmpty) groups.add((tr(ref, 'skills_group_other'), rest));
    } else {
      groups.add((null, visible));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        if (widget.note != null) ...[
          Text(widget.note!,
              style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (f, key, kind) in [
                (SkillFilter.all, 'skill_filter_all', null),
                (SkillFilter.attack, 'filter_attack', FaceKind.attack),
                (SkillFilter.heal, 'filter_heal', FaceKind.heal),
                (SkillFilter.mana, 'filter_mana', FaceKind.mana),
                (SkillFilter.status, 'filter_status', FaceKind.poison),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: Key('skill_filter_${f.name}'),
                    avatar: kind == null
                        ? null
                        : Icon(kind.icon, size: 15, color: kind.color),
                    label: Text('${tr(ref, key)} ${count(f)}'),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                shown.isEmpty
                    ? tr(ref, 'mine_empty')
                    : tr(ref, 'filter_nothing'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: ink.ash),
              ),
            ),
          ),
        for (final (title, entries) in groups) ...[
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              child: Text(title.toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, letterSpacing: 1)),
            ),
          for (final entry in entries)
            _SkillRow(entry: entry, model: model, allyId: widget.allyId),
        ],
        if (model.isPlayer) ...[
          const SizedBox(height: 16),
          _CraftCard(onTap: () => openCraft(context, ref)),
        ],
      ],
    );
  }
}

class _SkillRow extends ConsumerWidget {
  const _SkillRow({required this.entry, required this.model, this.allyId});

  final SkillEntry entry;
  final SkillsModel model;
  final String? allyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final kind = entry.kind;
    final summary =
        skillSummary(entry.record, entry.fightTier, (key) => tr(ref, key));

    Widget? trailing;
    if (!entry.known) {
      // A companion's skill still to learn: the button is right here.
      trailing = FilledButton.tonal(
        key: Key('learn_${entry.id}'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: entry.affordable
            ? () => learnSkill(context, ref, entry.id,
                allyId: allyId, cost: entry.cost)
            : null,
        child: Text(tr(ref, 'unlock_button')),
      );
    } else if (model.isPlayer) {
      final cost = entry.upgradeCost;
      trailing = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entry.tierable) TierPips(tier: entry.tier, size: 7),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (cost != null)
              Icon(Icons.arrow_upward,
                  size: 11,
                  color: model.essence >= cost ? ink.voidColor : ink.ash),
            Text(
              !entry.tierable
                  ? tr(ref, 'no_tiers_label')
                  : cost == null
                      ? tr(ref, 'tier_max_label')
                      : '$cost',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: cost != null && model.essence >= cost
                      ? ink.voidColor
                      : ink.ash),
            ),
          ]),
        ],
      );
    }

    return InkWell(
      key: Key('skill_row_${entry.id}'),
      onTap: () => showSkillSheet(context, entry.id, allyId: allyId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: ink.seam))),
        child: Row(
          children: [
            SkillPixelIcon(entry.id, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(skillDisplayName(entry.id, language: lang),
                          style: theme.textTheme.bodyLarge),
                    ),
                    const SizedBox(width: 6),
                    Icon(kind.icon, size: 13, color: kind.color),
                  ]),
                  if (summary.isNotEmpty)
                    Text(summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: ink.ash),
          ],
        ),
      ),
    );
  }
}

class _CraftCard extends ConsumerWidget {
  const _CraftCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return InkWell(
      key: const Key('skills_craft'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ink.tide),
        ),
        child: Row(children: [
          Icon(Icons.auto_fix_high, color: ink.tide),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(ref, 'craft_skill_button'),
                    style:
                        theme.textTheme.titleSmall?.copyWith(color: ink.tide)),
                Text(tr(ref, 'craft_card_body'),
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ink.tide),
        ]),
      ),
    );
  }
}
