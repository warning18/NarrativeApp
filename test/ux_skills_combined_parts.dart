// The combined Skills picture (docs/proposals/skills-combined.md): A4's standing
// grid joined with A2's rails. Each branch is a rail with its clan and the
// standing you have with it; the open one is a short list down the standing
// each depth asks, the rows its clan can offer now lit. Built from the real
// skills model, icons and theme. Mock only; nothing here ships.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/dice_faces.dart'
    show skillDisplayName;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart' show skillIndexCapFor;
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'ux_skills_mock_parts.dart';
import 'ux_skills_styles_parts.dart';

/// Where the character stands with a branch's clan, the depth that allows
/// (the index of the deepest skill the clan can offer; -1: no clan), and the
/// clan's id.
({String? clan, StandingTier tier, int cap}) standingOnBranch(
  SkillsModel model,
  SkillBranch branch,
  PlayerSession session,
  ClanData data,
) {
  final clan = clanOfBranch(model, branch);
  if (clan == null) {
    return (
      clan: null,
      tier: StandingTier.sworn,
      cap: model.isComplete(branch) ? 3 : -1
    );
  }
  final tier = session.politics.tierOf(clan, data);
  return (clan: clan, tier: tier, cap: skillIndexCapFor(tier));
}

class A42Tree extends ConsumerWidget {
  const A42Tree({
    super.key,
    required this.openIndex,
    required this.tabCounts,
    this.showSpells = false,
  });
  final int openIndex;
  final int tabCounts;
  final bool showSpells;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final session = ref.watch(playerSessionProvider);
      final data = ref.watch(clanDataProvider);
      final branches = model.classBranches;
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, showSpells),
        const SizedBox(height: 12),
        for (var i = 0; i < branches.length; i++)
          _Branch(
            model: model,
            branch: branches[i],
            open: i == openIndex,
            standing: standingOnBranch(model, branches[i], session, data),
          ),
        const SizedBox(height: 6),
        ...foldRows(model),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
              'A clan offers a skill once you stand this high with it. The lit rows are the ones it can offer now.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

/// A branch's header row, shared by the rail and the open panel: its name,
/// its clan and the standing you have with it, the four beads or the count.
class _Head extends ConsumerWidget {
  const _Head({
    required this.model,
    required this.branch,
    required this.standing,
    required this.open,
  });
  final SkillsModel model;
  final SkillBranch branch;
  final ({String? clan, StandingTier tier, int cap}) standing;
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(branch.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          if (standing.clan case final clan?)
            Row(children: [
              ClanFlag(factionId: clan, height: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${ref.watch(clanDataProvider).faction(clan)?.shortFor(AppLanguage.en) ?? clan} · ${standingWord(standing.tier)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.gold, fontWeight: FontWeight.w600),
                ),
              ),
            ])
          else
            Text(model.isComplete(branch) ? 'learned' : 'no clan',
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
        ]),
      ),
      if (open)
        Text('${model.knownOn(branch)}/${branch.skillIds.length}',
            style: theme.textTheme.labelMedium?.copyWith(color: ink.ash))
      else
        Beads(model: model, branch: branch),
      const SizedBox(width: 6),
      Icon(open ? Icons.expand_less : Icons.expand_more,
          size: 20, color: ink.ash),
    ]);
  }
}

class _Branch extends ConsumerWidget {
  const _Branch({
    required this.model,
    required this.branch,
    required this.open,
    required this.standing,
  });
  final SkillsModel model;
  final SkillBranch branch;
  final bool open;
  final ({String? clan, StandingTier tier, int cap}) standing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final head =
        _Head(model: model, branch: branch, standing: standing, open: open);
    if (!open) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ink.seam),
        ),
        child: head,
      );
    }
    final next = nextOn(model, branch);
    final rows = <Widget>[];
    for (var i = 0; i < branch.skillIds.length; i++) {
      final e = model[branch.skillIds[i]];
      if (e == null) continue;
      final reachable = i <= standing.cap;
      final isNext = next?.id == e.id;
      final known = e.known;
      final need = standingNeeded[i.clamp(0, 3)];
      rows.add(Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: reachable ? ink.gold.withValues(alpha: 0.09) : null,
          border: Border.all(
              color: reachable ? ink.gold.withValues(alpha: 0.45) : ink.seam),
        ),
        child: Row(children: [
          SizedBox(
            width: 54,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(need,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: reachable ? ink.gold : ink.ash,
                      fontWeight:
                          reachable ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
          Opacity(
            opacity: known || isNext || reachable ? 1 : 0.5,
            child: RingIcon(e, size: 38, lit: isNext && reachable),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(known || isNext ? skillDisplayName(e.id) : 'Further on',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: known || isNext ? null : ink.ash)),
                if (known)
                  Text(effectOf(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash))
                else if (isNext && reachable)
                  Text('The clan can offer it now',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: ink.gold, fontWeight: FontWeight.w600))
                else
                  Text(
                      isNext
                          ? 'Next, at "${need.toLowerCase()}"'
                          : 'Needs "${need.toLowerCase()}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
          if (known && e.tier > 0)
            Text('T${e.tier}',
                style: theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
        ]),
      ));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ink.gold.withValues(alpha: 0.04),
        border: Border.all(color: ink.gold.withValues(alpha: 0.7)),
      ),
      child: Column(children: [head, ...rows]),
    );
  }
}
