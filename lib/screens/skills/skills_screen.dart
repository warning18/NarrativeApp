// The Skills screen: the purse (points to learn, essence to raise tiers)
// over three tabs with one job each -- the Tree to learn, My skills to
// raise tiers and craft, Spells for magic. Every skill opens the same
// sheet (skill_sheet.dart); what each shows comes from SkillsModel
// (skills_view_model.dart). A companion's screen is their purse and their
// class's list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gamedata/db_schema.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/player_session_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../tutorial/guide_tour.dart';
import '../../tutorial/tutorial_topics.dart';
import '../../widgets/offer_dialog.dart';
import 'my_skills_view.dart';
import 'skill_sheet.dart';
import 'skill_tree_view.dart';
import 'skills_view_model.dart';
import 'spells_view.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key, this.allyId});

  /// When set, the screen is this companion's: their class's skills,
  /// learned with their own points.
  final String? allyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(localizedDbProvider(skillsSchema));
    final model = watchSkillsModel(ref, allyId);
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    final companion =
        allyId == null ? null : companions[allyId] as Map<String, dynamic>?;
    final title = allyId == null
        ? tr(ref, 'skills')
        : '${tr(ref, 'skills')} — '
            '${companion?['companionName']?.toString() ?? allyId}';

    Widget body;
    if (skillsAsync.hasError) {
      body = Center(
          child: Text('${tr(ref, 'failed_to_load_skills')}: '
              '${skillsAsync.error}'));
    } else if (model == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (allyId != null) {
      final professions =
          ref.watch(localizedDbProvider(professionsSchema)).value ?? const {};
      final professionId = companion?['professionId']?.toString() ?? '';
      body = Column(children: [
        _Purse(model: model),
        Expanded(
          child: MySkillsView(
            model: model,
            allyId: allyId,
            note: tr(ref, 'ally_skills_note').replaceAll(
                '{class}',
                (professions[professionId]
                            as Map<String, dynamic>?)?['professionName']
                        ?.toString() ??
                    professionId),
          ),
        ),
      ]);
    } else {
      body = Column(children: [
        TutorialTarget(id: 'skills.points', child: _Purse(model: model)),
        const SizedBox(height: 4),
        TutorialTarget(
          id: 'skills.views',
          child: TabBar(tabs: [
            Tab(
                key: const Key('skills_tab_tree'),
                text: tr(ref, 'skills_tab_tree')),
            TutorialTarget(
              id: 'skills.mine',
              child: Tab(
                key: const Key('skills_tab_mine'),
                text: '${tr(ref, 'skills_tab_mine')} ${model.knownIds.length}',
              ),
            ),
            Tab(
                key: const Key('skills_tab_spells'),
                text: tr(ref, 'skills_tab_spells')),
          ]),
        ),
        Expanded(
          child: TutorialTarget(
            id: 'skills.list',
            child: TabBarView(children: [
              SkillTreeView(model: model),
              MySkillsView(model: model),
              const SpellsView(),
            ]),
          ),
        ),
      ]);
    }

    final scaffold = Scaffold(
      appBar: AppBar(title: Text(title)),
      // The tour is the player's screen's; a companion's has none of it.
      body: allyId == null
          ? TutorialTrigger(topic: TutorialTopic.skills, child: body)
          : body,
    );
    return allyId == null
        ? DefaultTabController(length: 3, child: scaffold)
        : scaffold;
  }
}

/// What grows the skills, each saying where it comes from: a companion's
/// points to learn with; the player's offers waiting (the clans bring
/// skills now, see offers.dart) and essence to raise tiers, with a bar to
/// the cheapest next tier.
class _Purse extends ConsumerWidget {
  const _Purse({required this.model});

  final SkillsModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final points = model.skillPoints;
    final offers = model.isPlayer
        ? ref.watch(playerSessionProvider.select((s) => s.pendingOffers.length))
        : 0;
    final next = model.nextUpgradeCost;

    Widget box({
      required Key key,
      required Color colour,
      required bool lit,
      required List<Widget> children,
    }) =>
        Expanded(
          child: Container(
            key: key,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lit ? colour : ink.seam),
              color: lit ? colour.withValues(alpha: 0.08) : null,
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!model.isPlayer)
              box(
                key: const Key('purse_points'),
                colour: ink.gold,
                lit: points > 0,
                children: [
                  Text(
                    points == 1
                        ? tr(ref, 'purse_points_one')
                        : tr(ref, 'purse_points_many')
                            .replaceAll('{n}', '$points'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: points > 0 ? ink.gold : null),
                  ),
                  Text(tr(ref, 'purse_points_note'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ],
              )
            else
              Expanded(
                child: InkWell(
                  key: const Key('purse_offers'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: offers > 0
                      ? () =>
                          showOfferIfWaiting(context, ref, sayWhenNone: true)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: offers > 0 ? ink.gold : ink.seam),
                      color:
                          offers > 0 ? ink.gold.withValues(alpha: 0.08) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'offer_pending').replaceAll('{n}', '$offers'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: offers > 0 ? ink.gold : null),
                        ),
                        Text(tr(ref, 'purse_offers_note'),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.ash)),
                      ],
                    ),
                  ),
                ),
              ),
            if (model.isPlayer) ...[
              const SizedBox(width: 8),
              box(
                key: const Key('purse_essence'),
                colour: ink.voidColor,
                lit: next != null && model.essence >= next,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '${model.essence}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: ink.voidColor)),
                    TextSpan(
                        text: next == null
                            ? ' ${tr(ref, 'purse_essence')}'
                            : ' / $next ${tr(ref, 'purse_essence')}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  ])),
                  if (next != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (model.essence / next).clamp(0.0, 1.0),
                          minHeight: 4,
                          color: ink.voidColor,
                          backgroundColor: ink.seam,
                        ),
                      ),
                    ),
                  Text(tr(ref, 'purse_essence_note'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
