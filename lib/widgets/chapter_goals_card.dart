// A chapter's goals as a card (v2.5.0, UX): its three goals with their ticks,
// how many are met, and the four chests with the one the count has earned lit.
// A goal's words are Narrative's (chapter_goals.dart); a goal met is ticked
// and struck through. Nothing counts per goal: it is met or it is not.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/loot_box.dart' show ChestTier;
import '../data/chapter_goals.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/icon_sizes.dart';
import '../theme/stitched_ink.dart';
import 'ink_panel.dart';

/// The path of a chest's picture, closed or open.
String chapterChestAsset(ChestTier tier, {bool open = false}) =>
    'assets/icons/chests/${tier.name}_${open ? 'open' : 'closed'}.png';

/// One tick: green and checked when met, an empty box when not.
class GoalTick extends StatelessWidget {
  const GoalTick({super.key, required this.met, this.fresh = false});

  final bool met;

  /// Just met: a soft glow.
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final colour = met ? ink.heal : ink.ash;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: met ? colour : null,
        border: Border.all(color: colour, width: 1.6),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          if (fresh)
            BoxShadow(color: colour.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
      child: met
          ? const Icon(Icons.check, size: IconSize.s16, color: Colors.white)
          : null,
    );
  }
}

/// The goals of [chapter] (nothing for a chapter without any).
class ChapterGoalsCard extends ConsumerWidget {
  const ChapterGoalsCard(
      {super.key, required this.chapter, this.showChests = true, this.fresh});

  final int chapter;

  /// The row of four chests under the goals.
  final bool showChests;

  /// A goal id just met (its tick glows).
  final String? fresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = chapterGoalTable[chapter];
    if (goals == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final met = session.chapterGoalsMet['$chapter'] ?? const <String>[];
    final count = [
      for (final g in goals)
        if (met.contains(g.id)) g
    ].length;
    return InkPanel(
      key: Key('chapter_goals_$chapter'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
                trFor(lang, 'chapter_goals_title')
                    .replaceAll('{n}', '$chapter'),
                style: theme.textTheme.titleSmall),
          ),
          Text('$count/3',
              key: const Key('chapter_goals_count'),
              style: theme.textTheme.labelLarge),
        ]),
        const SizedBox(height: 8),
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GoalTick(
                  key: Key('goal_tick_${g.id}'),
                  met: met.contains(g.id),
                  fresh: fresh == g.id),
              const SizedBox(width: 10),
              Expanded(
                child: Text(chapterGoalLine(lang, chapter, g),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: met.contains(g.id)
                            ? TextDecoration.lineThrough
                            : null)),
              ),
            ]),
          ),
        if (showChests)
          Row(children: [
            for (final tier in const [
              ChestTier.wooden,
              ChestTier.iron,
              ChestTier.silver,
              ChestTier.gold,
            ])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Opacity(
                  opacity: tier == chapterChestTier(count) ? 1 : 0.35,
                  child: Image.asset(chapterChestAsset(tier),
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none),
                ),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(trFor(lang, 'chapter_goals_hint'),
                  style: theme.textTheme.bodySmall),
            ),
          ]),
      ]),
    );
  }
}

/// At a fight's setup: the chapter's goals this fight can still settle, one
/// line each, with an empty tick (a first-try goal only for its boss; none
/// once the chapter's chest was given). Nothing when there is none.
class ChapterGoalSetupLine extends ConsumerWidget {
  const ChapterGoalSetupLine(
      {super.key, required this.chapter, required this.enemyIds});

  final int chapter;
  final List<String> enemyIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = chapterGoalTable[chapter];
    if (goals == null) return const SizedBox.shrink();
    final session = ref.watch(playerSessionProvider);
    if (session.chapterChestsGiven.contains(chapter)) {
      return const SizedBox.shrink();
    }
    final met = session.chapterGoalsMet['$chapter'] ?? const <String>[];
    final open = [
      for (final g in goals)
        if (!met.contains(g.id) &&
            (g.kind != ChapterGoalKind.firstTry ||
                enemyIds.any(g.bossIds.contains)))
          g,
    ];
    if (open.isEmpty) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    return Padding(
      key: Key('chapter_goal_setup_$chapter'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final g in open)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const GoalTick(met: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    trFor(lang, 'chapter_goal_setup').replaceAll(
                        '{goal}', chapterGoalLine(lang, chapter, g)),
                    style: theme.textTheme.bodyMedium),
              ),
            ]),
          ),
      ]),
    );
  }
}
