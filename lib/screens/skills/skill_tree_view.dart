// The Tree tab: the class's branches side by side, learned from the top
// down and crowned by a mastery, the race's heritage under them, then the
// skills a reputation earns. A gold ring is known (its tier in dots), a lit
// ring is ready to learn, grey with a lock comes later; every skill not yet
// known says what it costs. Tapping one opens its sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/combat_engine.dart';
import '../../combat/dice_faces.dart';
import '../../data/skill_tree.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/face_style.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/detail_dialog.dart';
import 'skill_sheet.dart';
import 'skills_view_model.dart';

class SkillTreeView extends ConsumerWidget {
  const SkillTreeView({super.key, required this.model});

  final SkillsModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final ready = model.readyCount;
    final mastered = model.classBranches
        .where((b) => b.id == model.masteredBranchId)
        .map((b) => b.name)
        .firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        // The rules, in a line; the full text a tap away.
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: ready > 0
                  ? tr(ref, 'skills_ready').replaceAll('{n}', '$ready')
                  : tr(ref, 'skills_none_ready'),
              style: TextStyle(color: ready > 0 ? ink.gold : ink.ash),
            ),
            TextSpan(text: ' · ${tr(ref, 'skills_rules_short')} · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                key: const Key('skills_how'),
                onTap: () => showDetailDialog(
                  context,
                  title: tr(ref, 'skills_how_it_works'),
                  description: mastered == null
                      ? tr(ref, 'skill_tree_intro')
                      : '${tr(ref, 'skill_tree_intro')}\n\n'
                          '${tr(ref, 'skill_tree_mastered').replaceAll('{branch}', mastered)}',
                  closeLabel: tr(ref, 'close_button'),
                ),
                child: Text(tr(ref, 'skills_how_it_works'),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: ink.tide,
                        decoration: TextDecoration.underline,
                        decorationColor: ink.tide)),
              ),
            ),
          ]),
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
        const SizedBox(height: 14),
        if (model.classBranches.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final branch in model.classBranches)
                Expanded(child: _BranchColumn(model: model, branch: branch)),
            ],
          ),
        for (final branch in model.heritageBranches) ...[
          const Divider(height: 28),
          _SectionTitle(
              title: branch.name,
              count: '${model.knownOn(branch)}/${branch.skillIds.length}'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final id in branch.skillIds)
                if (model[id] != null)
                  Expanded(child: SkillNode(entry: model[id]!)),
            ],
          ),
        ],
        if (model.reputationIds.isNotEmpty) ...[
          const Divider(height: 28),
          _SectionTitle(title: tr(ref, 'skills_reputation_section')),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 10,
            children: [
              for (final id in model.reputationIds)
                SizedBox(width: 110, child: SkillNode(entry: model[id]!)),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});

  final String title;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(TextSpan(children: [
      TextSpan(text: title, style: theme.textTheme.titleSmall),
      if (count != null)
        TextSpan(
            text: '  $count',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: InkColors.of(context).ash)),
    ]));
  }
}

class _BranchColumn extends ConsumerWidget {
  const _BranchColumn({required this.model, required this.branch});

  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final isMastered = branch.id == model.masteredBranchId;
    final ids = [
      for (final id in branch.skillIds)
        if (model[id] != null) id
    ];
    return Column(
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: branch.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: isMastered ? ink.gold : null)),
            TextSpan(
                text: ' ${model.knownOn(branch)}/${branch.skillIds.length}',
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ]),
          key: Key('branch_${branch.id}'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // What the branch is about, under its name (no tooltip to find).
        SizedBox(
          height: 30,
          child: Text(
            branch.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: ink.ash, fontSize: 10.5, height: 1.2),
          ),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < ids.length; i++) ...[
          if (i > 0) _Link(lit: model[ids[i]]!.known),
          SkillNode(entry: model[ids[i]]!),
        ],
        _Link(lit: isMastered),
        _MasteryNode(model: model, branch: branch),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return Container(
      width: 2,
      height: 10,
      margin: const EdgeInsets.symmetric(vertical: 1),
      color: lit ? ink.gold : ink.seam,
    );
  }
}

/// A skill on the tree: its ring says where it stands, the corner what it
/// does (or a lock), the line under its name its cost or its tier.
class SkillNode extends ConsumerWidget {
  const SkillNode({super.key, required this.entry});

  final SkillEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final id = entry.id;
    final kind = entry.kind;
    final locked = entry.status == SkillStatus.locked;
    final Color ring;
    final double width;
    if (entry.known) {
      (ring, width) = (ink.gold, 2.5);
    } else if (entry.readyNow) {
      (ring, width) = (ink.gold, 2);
    } else if (entry.status == SkillStatus.ready) {
      (ring, width) = (ink.gold.withValues(alpha: 0.45), 1.5);
    } else {
      (ring, width) = (ink.seam, 1.5);
    }
    return InkWell(
      key: Key('tree_node_$id'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => showSkillSheet(context, id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.known
                        ? ink.gold.withValues(alpha: 0.16)
                        : theme.colorScheme.surface,
                    border: Border.all(color: ring, width: width),
                    boxShadow: entry.readyNow
                        ? [
                            BoxShadow(
                                color: ink.gold.withValues(alpha: 0.35),
                                blurRadius: 10)
                          ]
                        : null,
                  ),
                  child: Opacity(
                    opacity: locked ? 0.4 : 1,
                    child: SkillPixelIcon(id, size: 26),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(locked ? Icons.lock : kind.icon,
                        size: 11, color: locked ? ink.ash : kind.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Fixed heights, so the branches' nodes stay level.
            SizedBox(
              height: 16,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  skillDisplayName(id, language: lang),
                  maxLines: 1,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: locked ? ink.ash : null),
                ),
              ),
            ),
            SizedBox(
              height: 16,
              child: Center(
                child: entry.known
                    ? (entry.tierable
                        ? TierPips(tier: entry.tier)
                        : const SizedBox.shrink())
                    : Text(
                        costLabel(ref, entry.cost),
                        key: Key('tree_cost_$id'),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: entry.readyNow ? ink.gold : ink.ash,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skill's tier as filled dots out of [maxSkillTier].
class TierPips extends StatelessWidget {
  const TierPips({super.key, required this.tier, this.size = 6});

  final int tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gold = InkColors.of(context).gold;
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxSkillTier; i++)
            Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < tier ? gold : null,
                border: Border.all(color: gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasteryNode extends ConsumerWidget {
  const _MasteryNode({required this.model, required this.branch});

  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final isMastered = branch.id == model.masteredBranchId;
    final closed = model.masteredBranchId.isNotEmpty && !isMastered;
    final ready = model.canMaster(branch);
    final colour = isMastered || ready ? ink.gold : ink.seam;
    return InkWell(
      key: Key('mastery_${branch.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => showMasterySheet(context, ref, branch),
      child: Opacity(
        opacity: closed ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMastered ? ink.gold.withValues(alpha: 0.2) : null,
                  border: Border.all(color: colour, width: 2),
                ),
                child: Icon(closed ? Icons.block : Icons.star,
                    color: isMastered || ready ? ink.gold : ink.ash, size: 20),
              ),
              const SizedBox(height: 3),
              Text(
                isMastered
                    ? tr(ref, 'mastery_label')
                    : tr(ref, 'mastery_cost_label')
                        .replaceAll('{n}', '$branchMasteryCost'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: isMastered || ready ? ink.gold : ink.ash),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
