// The drawing of the Skills styles mock (ux_skills_styles_mock_test.dart):
// three more ways to draw version A of the Skills tab, all keeping the tree
// as the main thing. Built from the real skills model, the real icons and the
// app's own theme, reusing the pieces of ux_skills_mock_parts.dart. Mock
// only; nothing here ships.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/dice_faces.dart'
    show skillDisplayName;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart' show skillIndexCapFor;
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skill_tree_view.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'ux_skills_mock_parts.dart';

/// The three tabs of today's screen, the first on.
Widget tabsRow(BuildContext context, int mySkills, bool showSpells) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  Widget tab(String label, bool on) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: on ? ink.gold : Colors.transparent, width: 2)),
          ),
          child: Center(
            child: Text(label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: on ? ink.gold : ink.ash)),
          ),
        ),
      );
  return Row(children: [
    tab('Tree', true),
    tab('My skills $mySkills', false),
    if (showSpells) tab('Spells', false),
  ]);
}

/// The folded heritage and reputation rows, as in A.
List<Widget> foldRows(SkillsModel model) => [
      for (final b in model.heritageBranches)
        FoldRow(
            title: b.name, count: '${model.knownOn(b)}/${b.skillIds.length}'),
      if (model.reputationIds.isNotEmpty)
        FoldRow(
            title: 'Earned by reputation',
            count: '${model.reputationIds.length}'),
    ];

/// The clan that sponsors [branch] for the character, from its first skill
/// not yet known (a known skill carries no sponsors); null for a branch all
/// learned.
String? clanOfBranch(SkillsModel model, SkillBranch branch) {
  for (final id in branch.skillIds) {
    final e = model[id];
    if (e != null && e.sponsors.isNotEmpty) return e.sponsors.first;
  }
  return null;
}

/// Four small marks for a branch's four skills: gold filled when known,
/// a lit ring for the next, a dim ring for the rest.
class Beads extends StatelessWidget {
  const Beads({super.key, required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final next = nextOn(model, branch);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final id in branch.skillIds)
        Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(left: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: model[id]?.known == true ? ink.gold : null,
            border: Border.all(
                color: model[id]?.known == true
                    ? ink.gold
                    : next?.id == id
                        ? ink.gold
                        : ink.seam,
                width: next?.id == id ? 2.2 : 1.5),
            boxShadow: next?.id == id
                ? [
                    BoxShadow(
                        color: ink.gold.withValues(alpha: 0.4), blurRadius: 6)
                  ]
                : null,
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// A2: one branch open at a time; the others as one-line rails.
// ---------------------------------------------------------------------------

class A2Tree extends StatelessWidget {
  const A2Tree({
    super.key,
    required this.openIndex,
    required this.tabCounts,
    this.showSpells = false,
  });
  final int openIndex;
  final int tabCounts;
  final bool showSpells;

  @override
  Widget build(BuildContext context) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final branches = model.classBranches;
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, showSpells),
        const SizedBox(height: 12),
        for (var i = 0; i < branches.length; i++)
          i == openIndex
              ? _OpenBranch(model: model, branch: branches[i])
              : _Rail(model: model, branch: branches[i]),
        const SizedBox(height: 6),
        ...foldRows(model),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text('Tap a branch to open it, a skill for its sheet.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        Expanded(
          child: Text(branch.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall),
        ),
        Beads(model: model, branch: branch),
        const SizedBox(width: 6),
        Icon(Icons.expand_more, size: 20, color: ink.ash),
      ]),
    );
  }
}

class _OpenBranch extends ConsumerWidget {
  const _OpenBranch({required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final next = nextOn(model, branch);
    final rows = <Widget>[];
    for (var i = 0; i < branch.skillIds.length; i++) {
      final e = model[branch.skillIds[i]];
      if (e == null) continue;
      final isNext = next?.id == e.id;
      final deep = !e.known && !isNext;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          RingIcon(e, size: 42, lit: isNext),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deep ? 'Further on' : skillDisplayName(e.id),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: deep ? ink.ash : null)),
                if (e.known)
                  Text(effectOf(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash))
                else if (isNext)
                  offerLine(context, ref, e, withBranch: false)
                else
                  Text('Offered from ${standingNeeded[e.index.clamp(0, 3)]}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
          if (e.known && e.tier > 0)
            Text('T${e.tier}',
                style: theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
        ]),
      ));
      if (i < branch.skillIds.length - 1) {
        rows.add(Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
                width: 2, height: 6, color: e.known ? ink.gold : ink.seam),
          ),
        ));
      }
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ink.gold.withValues(alpha: 0.05),
        border: Border.all(color: ink.gold.withValues(alpha: 0.7)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(branch.name, style: theme.textTheme.titleSmall)),
          Text('${model.knownOn(branch)}/${branch.skillIds.length}',
              style: theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
          const SizedBox(width: 6),
          Icon(Icons.expand_less, size: 20, color: ink.ash),
        ]),
        const SizedBox(height: 6),
        ...rows,
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// A3: one scroll, a bar that stays, depth as silhouettes.
// ---------------------------------------------------------------------------

class A3Tree extends ConsumerWidget {
  const A3Tree({super.key, required this.tabCounts, this.showSpells = false});
  final int tabCounts;
  final bool showSpells;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final offers = ref
          .watch(playerSessionProvider.select((s) => s.pendingOffers.length));
      final firstNext = [
        for (final b in model.classBranches)
          if (nextOn(model, b) case final e?) e,
      ].firstOrNull;
      final cheapest = model.nextUpgradeCost;
      final lit = cheapest != null && model.essence >= cheapest;
      return Column(children: [
        // The bar that stays while the tree scrolls.
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: ink.seam)),
          ),
          child: Row(children: [
            Expanded(
              child: offers > 0
                  ? Row(children: [
                      Icon(Icons.mail_outline, size: 18, color: ink.gold),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('An offer is waiting',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: ink.gold)),
                      ),
                    ])
                  : firstNext == null
                      ? Text('Every branch learned',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: ink.ash))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next offer',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: ink.ash)),
                            offerLine(context, ref, firstNext),
                          ],
                        ),
            ),
            if (model.essence > 0) ...[
              const SizedBox(width: 8),
              pill(
                  context,
                  cheapest == null
                      ? '${model.essence}'
                      : '${model.essence} / $cheapest',
                  ink.voidColor,
                  icon: Icons.auto_awesome,
                  filled: lit),
            ],
          ]),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            tabsRow(context, tabCounts, showSpells),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in model.classBranches)
                    Expanded(child: _SilhouetteColumn(model: model, branch: b)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...foldRows(model),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                  'A grey shape fills in when a clan will offer it: the name under it is the standing it asks.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
      ]);
    });
  }
}

class _SilhouetteColumn extends StatelessWidget {
  const _SilhouetteColumn({required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final next = nextOn(model, branch);
    final children = <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(branch.name, style: theme.textTheme.titleSmall),
      ),
      Text('${model.knownOn(branch)}/${branch.skillIds.length}',
          style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
      const SizedBox(height: 8),
    ];
    for (var i = 0; i < branch.skillIds.length; i++) {
      final e = model[branch.skillIds[i]];
      if (e == null) continue;
      if (i > 0) {
        children.add(Container(
            width: 2,
            height: 8,
            color: e.known ? ink.gold : ink.seam,
            margin: const EdgeInsets.symmetric(vertical: 1)));
      }
      if (e.known || next?.id == e.id) {
        children.add(SkillNode(entry: e));
      } else {
        children.add(Column(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink.seam.withValues(alpha: 0.18),
              border: Border.all(color: ink.seam.withValues(alpha: 0.6)),
            ),
            // The skill itself, only its shape: no colour, no name.
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                  ink.seam.withValues(alpha: 0.9), BlendMode.srcIn),
              child: SkillPixelIcon(e.id, size: 26),
            ),
          ),
          const SizedBox(height: 2),
          Text(standingNeeded[e.index.clamp(0, 3)],
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
        ]));
      }
    }
    return Column(children: children);
  }
}

// ---------------------------------------------------------------------------
// A4 (mine): the standing grid. Branches across, the standing each depth asks
// down the side, and the standing you have drawn on each column.
// ---------------------------------------------------------------------------

class A4Tree extends ConsumerWidget {
  const A4Tree({super.key, required this.tabCounts, this.showSpells = false});
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
      final depth = branches
          .map((b) => b.skillIds.length)
          .fold<int>(0, (a, b) => a > b ? a : b);

      StandingTier tierOf(SkillBranch b) {
        final clan = clanOfBranch(model, b);
        return clan == null
            ? StandingTier.sworn
            : session.politics.tierOf(clan, data);
      }

      // A branch no clan sponsors (and not yet learned) offers nothing.
      final cap = [
        for (final b in branches)
          clanOfBranch(model, b) != null
              ? skillIndexCapFor(tierOf(b))
              : (model.isComplete(b) ? 3 : -1),
      ];
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        tabsRow(context, tabCounts, showSpells),
        const SizedBox(height: 12),
        // The clan above each column, and where you stand with it.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 56),
            for (var c = 0; c < branches.length; c++)
              Expanded(
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(branches[c].name,
                        style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(height: 4),
                  if (clanOfBranch(model, branches[c]) case final clan?)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ClanFlag(factionId: clan, height: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          standingWord(tierOf(branches[c])),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: ink.gold, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ])
                  else
                    Text(model.isComplete(branches[c]) ? 'learned' : 'no clan',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < depth; row++)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: 56,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(standingNeeded[row.clamp(0, 3)],
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ),
              ),
              for (var c = 0; c < branches.length; c++)
                Expanded(
                  child: _GridCell(
                    model: model,
                    branch: branches[c],
                    row: row,
                    reachable: row <= cap[c],
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 10),
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

/// "Known", "Trusted"...: the tier's word.
String standingWord(StandingTier tier) {
  final n = tier.name;
  return n[0].toUpperCase() + n.substring(1);
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.model,
    required this.branch,
    required this.row,
    required this.reachable,
  });
  final SkillsModel model;
  final SkillBranch branch;
  final int row;
  final bool reachable;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    if (row >= branch.skillIds.length) return const SizedBox(height: 62);
    final e = model[branch.skillIds[row]];
    if (e == null) return const SizedBox(height: 62);
    final next = nextOn(model, branch)?.id == e.id;
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: reachable ? ink.gold.withValues(alpha: 0.08) : null,
        border: Border.all(
            color: reachable ? ink.gold.withValues(alpha: 0.4) : ink.seam),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        e.known || next
            ? RingIcon(e, size: 34, lit: next)
            : Opacity(
                opacity: reachable ? 0.7 : 0.35,
                child: RingIcon(e, size: 34),
              ),
        const SizedBox(height: 2),
        if (e.known || next)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(skillDisplayName(e.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall),
          ),
      ]),
    );
  }
}
