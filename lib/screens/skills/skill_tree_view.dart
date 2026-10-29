// The Tree tab: the class's branches as constellations on one night sky
// (star_chart.dart), the race's heritage under them, then the skills a
// reputation earns. A gold ring is known (its tier in dots), a lit ring is
// ready to learn, grey with a lock comes later. Tapping one opens its sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/combat_engine.dart';
import '../../combat/dice_faces.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/face_style.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/detail_dialog.dart';
import '../../widgets/pixel_banner.dart';
import 'skill_sheet.dart';
import 'star_chart.dart';
import 'skills_view_model.dart';

class SkillTreeView extends ConsumerWidget {
  const SkillTreeView({super.key, required this.model});

  final SkillsModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
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
            TextSpan(text: '${tr(ref, 'skills_rules_short')} · '),
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
        if (model.classBranches.isNotEmpty) StarChart(model: model),
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
                // The clan that offers it hangs from the ring's upper left.
                if (!entry.known && entry.sponsors.isNotEmpty)
                  Positioned(
                    left: -7,
                    top: -9,
                    child: Opacity(
                      opacity: locked ? 0.45 : 1,
                      child: ClanFlag(
                        key: Key('tree_flag_$id'),
                        factionId: entry.sponsors.first,
                        height: 24,
                      ),
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
                    : _SponsorLabel(entry: entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who offers a skill not yet known, under its name: the first sponsoring
/// clan's short name in its colour (see offers.dart), "—" for none.
class _SponsorLabel extends ConsumerWidget {
  const _SponsorLabel({required this.entry});

  final SkillEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final data = ref.watch(clanDataProvider);
    final lang = ref.watch(appLanguageProvider);
    final faction = [
      for (final id in entry.sponsors)
        if (data.faction(id) case final faction?) faction,
    ].firstOrNull;
    final locked = entry.status == SkillStatus.locked;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        faction == null ? '\u2014' : faction.shortFor(lang),
        key: Key('tree_sponsor_${entry.id}'),
        maxLines: 1,
        style: theme.textTheme.labelSmall?.copyWith(
            color: faction == null || locked ? ink.ash : Color(faction.color),
            fontWeight: FontWeight.w600),
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
