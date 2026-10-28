// The drawing of the Skills mock (ux_skills_mock_test.dart): the pieces the
// three versions share, and the versions themselves, built from the real
// skills model, the real icons and the app's own theme. Mock only; nothing
// here ships.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/dice_faces.dart'
    show skillDisplayName;
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skill_sheet.dart';
import 'package:narrative_data_app/screens/skills/skill_tree_view.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

/// The standing a clan needs to offer the skill at [index] on a branch
/// (offers.dart, skillIndexCapFor).
const List<String> standingNeeded = ['Unknown', 'Known', 'Trusted', 'Sworn'];

/// A phone: the app bar, the body, at [width] logical pixels.
class Phone extends StatelessWidget {
  const Phone({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.title = 'Skills',
    this.bare = false,
  });

  /// True for a child that brings its own app bar (the real screen).
  final bool bare;

  final double width;
  final double height;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: const Color(0xFF3A3642), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: bare
            ? child
            : Column(children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: InkColors.of(context).seam)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.display)),
                    ),
                    Icon(Icons.info_outline,
                        size: 22, color: theme.colorScheme.onSurface),
                  ]),
                ),
                Expanded(child: ClipRect(child: child)),
              ]),
      ),
    );
  }
}

/// [builder] with the real skills model of the scene's session.
class WithModel extends ConsumerWidget {
  const WithModel(this.builder, {super.key});
  final Widget Function(BuildContext, WidgetRef, SkillsModel) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = watchSkillsModel(ref, null);
    if (model == null) return const SizedBox.shrink();
    return builder(context, ref, model);
  }
}

/// The clan that offers [entry]'s skill, its short name and colour.
({String name, Color colour, String id})? sponsorOf(
    WidgetRef ref, SkillEntry entry) {
  final data = ref.watch(clanDataProvider);
  for (final id in entry.sponsors) {
    final faction = data.faction(id);
    if (faction != null) {
      return (
        name: faction.shortFor(AppLanguage.en),
        colour: Color(faction.color),
        id: id
      );
    }
  }
  return null;
}

/// The skill after the last known one on [branch] (the one a clan can offer
/// next), or null when the branch is learned.
SkillEntry? nextOn(SkillsModel model, SkillBranch branch) {
  for (final id in branch.skillIds) {
    final e = model[id];
    if (e != null && !e.known) return e;
  }
  return null;
}

Widget pill(BuildContext context, String text, Color colour,
    {IconData? icon, bool filled = false}) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: filled ? colour.withValues(alpha: 0.14) : null,
      border: Border.all(color: colour),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: colour),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: colour)),
      ),
    ]),
  );
}

/// A small caption in the screen's small caps.
Widget caption(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: InkColors.of(context).ash, letterSpacing: 1.2)),
    );

// ---------------------------------------------------------------------------
// A: today's tab, with less on it.
// ---------------------------------------------------------------------------

/// One line for what waits and what can be raised; nothing at all while both
/// are empty.
class AStrip extends ConsumerWidget {
  const AStrip({super.key, required this.model});
  final SkillsModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    final offers =
        ref.watch(playerSessionProvider.select((s) => s.pendingOffers.length));
    final next = model.nextUpgradeCost;
    if (offers == 0 && model.essence == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(children: [
        if (offers > 0)
          Expanded(
            child: pill(context, '$offers offer waiting', ink.gold,
                icon: Icons.mail_outline, filled: true),
          ),
        if (offers > 0 && model.essence > 0) const SizedBox(width: 8),
        if (model.essence > 0)
          Expanded(
            child: pill(
                context,
                next == null ? '${model.essence}' : '${model.essence} / $next',
                ink.voidColor,
                icon: Icons.auto_awesome,
                filled: next != null && model.essence >= next),
          ),
      ]),
    );
  }
}

/// A branch column of A: its name and count; what is known and the next
/// skill drawn in full; the rest as dots; the Mastery star only a hint
/// until the branch is learned.
class AColumn extends ConsumerWidget {
  const AColumn({super.key, required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final next = nextOn(model, branch);
    final complete = model.isComplete(branch);
    final children = <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(branch.name, style: theme.textTheme.titleSmall),
      ),
      Text('${model.knownOn(branch)}/${branch.skillIds.length}',
          style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
      const SizedBox(height: 8),
    ];
    var drewNext = false;
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
      if (e.known || (next != null && e.id == next.id && !drewNext)) {
        if (!e.known) drewNext = true;
        children.add(SkillNode(entry: e));
      } else {
        children.add(Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink.seam, width: 1.5),
          ),
        ));
      }
    }
    children.add(Container(
        width: 2,
        height: 8,
        color: complete ? ink.gold : ink.seam,
        margin: const EdgeInsets.symmetric(vertical: 1)));
    children.add(Icon(Icons.star,
        size: complete ? 22 : 14, color: complete ? ink.gold : ink.seam));
    if (complete) {
      children.add(Text('2000',
          style: theme.textTheme.labelSmall?.copyWith(color: ink.gold)));
    }
    return Column(children: children);
  }
}

/// A folded section: its name and count, a chevron to open it.
class FoldRow extends StatelessWidget {
  const FoldRow({super.key, required this.title, required this.count});
  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
        Text(count,
            style: theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
        const SizedBox(width: 6),
        Icon(Icons.expand_more, size: 20, color: ink.ash),
      ]),
    );
  }
}

/// The Tree tab of A: the three tabs as today, the strip, the branches, the
/// folded sections.
class ATree extends StatelessWidget {
  const ATree({super.key, required this.tabCounts, required this.showSpells});

  /// "My skills" count.
  final int tabCounts;
  final bool showSpells;

  @override
  Widget build(BuildContext context) {
    return WithModel((context, ref, model) {
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
      final heritage = model.heritageBranches;
      return ListView(padding: EdgeInsets.zero, children: [
        AStrip(model: model),
        const SizedBox(height: 6),
        Row(children: [
          tab('Tree', true),
          tab('My skills $tabCounts', false),
          if (showSpells) tab('Spells', false),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in model.classBranches)
                Expanded(child: AColumn(model: model, branch: b)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final b in heritage)
          FoldRow(
              title: b.name, count: '${model.knownOn(b)}/${b.skillIds.length}'),
        if (model.reputationIds.isNotEmpty)
          FoldRow(
              title: 'Earned by reputation',
              count: '${model.reputationIds.length}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text('Tap a skill: who offers it, what it does, its tiers.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        ),
      ]);
    });
  }
}

// ---------------------------------------------------------------------------
// Shared by B and C
// ---------------------------------------------------------------------------

/// The one-line effect of [e]'s skill now.
String effectOf(SkillEntry e) => skillSummary(e.record, e.fightTier, (key) {
      return switch (key) {
        'summary_damage' => '+{n} damage',
        'summary_heal' => 'heals {n}',
        'summary_mana' => '+{n} mana',
        _ => key,
      };
    });

/// A round skill icon: gold when known, lit when next, dim otherwise.
class RingIcon extends StatelessWidget {
  const RingIcon(this.entry, {super.key, this.size = 44, this.lit = false});
  final SkillEntry entry;
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final known = entry.known;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: known
            ? ink.gold.withValues(alpha: 0.16)
            : theme.colorScheme.surface,
        border: Border.all(
            color: known
                ? ink.gold
                : lit
                    ? ink.gold.withValues(alpha: 0.7)
                    : ink.seam,
            width: known ? 2.5 : 1.8),
        boxShadow: lit
            ? [
                BoxShadow(
                    color: ink.gold.withValues(alpha: 0.3), blurRadius: 10)
              ]
            : null,
      ),
      child: Opacity(
        opacity: known || lit ? 1 : 0.45,
        child: SkillPixelIcon(entry.id, size: size * 0.58),
      ),
    );
  }
}

/// "Bulwark · the Compact, from Unknown": where [e] comes from.
Widget offerLine(BuildContext context, WidgetRef ref, SkillEntry e,
    {bool withBranch = true}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  final sponsor = sponsorOf(ref, e);
  final tier = standingNeeded[e.index.clamp(0, 3)];
  return Row(children: [
    if (sponsor != null) ...[
      ClanFlag(factionId: sponsor.id, height: 18),
      const SizedBox(width: 5),
    ],
    Flexible(
      child: Text(
        [
          if (withBranch && e.branch != null) e.branch!.name,
          if (sponsor != null) '${sponsor.name} · $tier',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
            color: sponsor?.colour ?? ink.ash, fontWeight: FontWeight.w600),
      ),
    ),
  ]);
}

Widget quietButton(BuildContext context, String label, {IconData? icon}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ink.seam),
    ),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 18, color: ink.ash),
        const SizedBox(width: 8),
      ],
      Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
      Icon(Icons.chevron_right, size: 20, color: ink.ash),
    ]),
  );
}

// ---------------------------------------------------------------------------
// B: a first-time page that grows with the hero.
// ---------------------------------------------------------------------------

class BPage extends StatelessWidget {
  const BPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final offers = ref
          .watch(playerSessionProvider.select((s) => s.pendingOffers.length));
      final known = [for (final id in model.knownIds) model[id]!];
      final next = [
        for (final b in model.classBranches)
          if (nextOn(model, b) case final e?) e,
      ];
      final cheapest = model.nextUpgradeCost;
      final raiseable = cheapest != null && model.essence >= cheapest;
      // The page opens up as the hero grows: the essence line once a skill
      // can have tiers; the merge card with the Skillwright.
      final hasTiered = known.any((e) => e.tierable);
      final skillwright = ref.watch(playerSessionProvider
          .select((s) => s.builtHouseIds.contains('skillwright')));
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        children: [
          if (offers > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: ink.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ink.gold),
              ),
              child: Row(children: [
                Icon(Icons.mail_outline, color: ink.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('A clan has an offer for you',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: ink.gold)),
                ),
                Icon(Icons.chevron_right, color: ink.gold),
              ]),
            ),
          caption(context, 'Your skills · ${known.length}'),
          for (final e in known.take(4)) BKnownRow(entry: e, model: model),
          if (known.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text('+${known.length - 4} more',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ),
          if (hasTiered && model.essence > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: raiseable
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: ink.voidColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ink.voidColor),
                      ),
                      child: Row(children: [
                        Icon(Icons.auto_awesome,
                            size: 18, color: ink.voidColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Raise a tier · ${model.essence} essence',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(color: ink.voidColor)),
                        ),
                        Icon(Icons.chevron_right, color: ink.voidColor),
                      ]),
                    )
                  : Row(children: [
                      Icon(Icons.auto_awesome, size: 16, color: ink.ash),
                      const SizedBox(width: 6),
                      Text('${model.essence} essence · next tier $cheapest',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: ink.ash)),
                    ]),
            ),
          const SizedBox(height: 18),
          caption(context, 'Next from the clans'),
          Text(
            known.length <= 2
                ? 'A clan can offer you one of these as you rise.'
                : 'Next in each branch.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          for (final e in next)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                RingIcon(e, size: 42, lit: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skillDisplayName(e.id),
                          style: theme.textTheme.bodyLarge),
                      offerLine(context, ref, e),
                    ],
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 10),
          if (skillwright) ...[
            quietButton(context, 'Merge two skills into one',
                icon: Icons.auto_fix_high),
            const SizedBox(height: 8),
          ],
          quietButton(context, 'See the whole tree', icon: Icons.account_tree),
        ],
      );
    });
  }
}

class BKnownRow extends StatelessWidget {
  const BKnownRow({super.key, required this.entry, required this.model});
  final SkillEntry entry;
  final SkillsModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: ink.seam))),
      child: Row(children: [
        RingIcon(entry, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skillDisplayName(entry.id),
                  style: theme.textTheme.bodyLarge),
              Text(effectOf(entry),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
        ),
        if (entry.tierable) TierPips(tier: entry.tier, size: 7),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// C: your next skill, three paths, and the map behind a button.
// ---------------------------------------------------------------------------

class CPage extends StatelessWidget {
  const CPage({super.key, this.dimmed = false});
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final offers = ref
          .watch(playerSessionProvider.select((s) => s.pendingOffers.length));
      final known = [for (final id in model.knownIds) model[id]!];
      final heroes = [
        for (final b in model.classBranches)
          if (nextOn(model, b) case final e?) e,
      ];
      final hero = heroes.isEmpty ? null : heroes.first;
      final skillwright = ref.watch(playerSessionProvider
          .select((s) => s.builtHouseIds.contains('skillwright')));
      final next = model.nextUpgradeCost;
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        children: [
          if (hero != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ink.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ink.gold.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offers > 0 ? 'AN OFFER IS WAITING' : 'NEXT SKILL',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(children: [
                    RingIcon(hero, size: 58, lit: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(skillDisplayName(hero.id),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontFamily: InkFonts.display)),
                          Text(effectOf(hero),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash)),
                          const SizedBox(height: 4),
                          offerLine(context, ref, hero),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          const SizedBox(height: 16),
          caption(context, 'Your paths'),
          for (final b in model.classBranches) CRail(model: model, branch: b),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: caption(context, 'Your skills · ${known.length}')),
            if (model.essence > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.auto_awesome, size: 14, color: ink.voidColor),
                  const SizedBox(width: 4),
                  Text(
                      next == null
                          ? '${model.essence}'
                          : '${model.essence} / $next',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.voidColor)),
                ]),
              ),
          ]),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in known)
              SizedBox(
                width: 64,
                child: Column(children: [
                  RingIcon(e, size: 44),
                  const SizedBox(height: 3),
                  if (e.tierable)
                    TierPips(tier: e.tier, size: 5)
                  else
                    const SizedBox(height: 5),
                ]),
              ),
          ]),
          const SizedBox(height: 16),
          quietButton(context, 'Map of the whole tree',
              icon: Icons.account_tree),
          if (skillwright) ...[
            const SizedBox(height: 8),
            quietButton(context, 'Merge two skills', icon: Icons.auto_fix_high),
          ],
        ],
      );
    });
  }
}

/// A path: its name, four beads on a rail, the Mastery star, the count.
class CRail extends StatelessWidget {
  const CRail({super.key, required this.model, required this.branch});
  final SkillsModel model;
  final SkillBranch branch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final next = nextOn(model, branch);
    final complete = model.isComplete(branch);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        SizedBox(
          width: 74,
          child: Text(branch.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall),
        ),
        Expanded(
          child: Row(children: [
            for (var i = 0; i < branch.skillIds.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                      height: 2,
                      color: (model[branch.skillIds[i]]?.known ?? false)
                          ? ink.gold
                          : ink.seam),
                ),
              _Bead(
                  entry: model[branch.skillIds[i]],
                  isNext: next?.id == branch.skillIds[i]),
            ],
            Expanded(
                child: Container(
                    height: 2, color: complete ? ink.gold : ink.seam)),
            Icon(Icons.star, size: 16, color: complete ? ink.gold : ink.seam),
          ]),
        ),
        const SizedBox(width: 6),
        Text('${model.knownOn(branch)}/${branch.skillIds.length}',
            style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
        Icon(Icons.chevron_right, size: 18, color: ink.ash),
      ]),
    );
  }
}

class _Bead extends StatelessWidget {
  const _Bead({required this.entry, required this.isNext});
  final SkillEntry? entry;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final known = entry?.known ?? false;
    if (known) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ink.gold,
            border: Border.all(color: ink.gold)),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: isNext ? 22 : 14,
      height: isNext ? 22 : 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isNext ? ink.gold : ink.seam, width: 2),
        boxShadow: isNext
            ? [
                BoxShadow(
                    color: ink.gold.withValues(alpha: 0.35), blurRadius: 8)
              ]
            : null,
      ),
    );
  }
}

/// What a tap on a path opens: its four skills, the Mastery under them.
class CBranchSheet extends StatelessWidget {
  const CBranchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return WithModel((context, ref, model) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      // The trees load a moment after the skills: nothing until they have.
      if (model.classBranches.isEmpty) return const SizedBox.shrink();
      final branch = model.classBranches.first;
      final next = nextOn(model, branch);
      return Stack(children: [
        const Positioned.fill(child: CPage()),
        Positioned.fill(child: Container(color: const Color(0x88000000))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: ink.seam),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: ink.seam,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 10),
                Text(
                    '${branch.name}  ${model.knownOn(branch)}/${branch.skillIds.length}',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontFamily: InkFonts.display)),
                Text(branch.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
                const SizedBox(height: 10),
                for (final id in branch.skillIds)
                  if (model[id] case final e?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        RingIcon(e, size: 40, lit: next?.id == e.id),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skillDisplayName(e.id),
                                  style: theme.textTheme.bodyLarge),
                              if (e.known)
                                Text(effectOf(e),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: ink.ash))
                              else if (next?.id == e.id)
                                offerLine(context, ref, e, withBranch: false)
                              else
                                Text('After ${skillDisplayName(e.after ?? '')}',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: ink.ash)),
                            ],
                          ),
                        ),
                        if (e.known && e.tierable)
                          TierPips(tier: e.tier, size: 7),
                        if (!e.known && next?.id != e.id)
                          Icon(Icons.lock_outline, size: 18, color: ink.ash),
                      ]),
                    ),
                const Divider(height: 18),
                Row(children: [
                  Icon(Icons.star_outline, color: ink.ash),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Master the branch · 2000 essence · its skills fight a tier higher',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]);
    });
  }
}

/// A column of notes beside the phones: a heading and a few lines each.
class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.title, required this.sections});
  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFFEDE6DC);
    const ash = Color(0xFFA9A2B3);
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'IMFellEnglishSC', fontSize: 22, color: text)),
          const SizedBox(height: 12),
          for (final (head, body) in sections) ...[
            Text(head.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: Color(0xFFE2B890))),
            const SizedBox(height: 3),
            Text(body,
                style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 13.5,
                    height: 1.3,
                    color: ash)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
