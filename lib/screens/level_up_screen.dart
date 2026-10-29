// Level up, in Stitched Ink (v1.201): the level and its road to the next
// in a panel, the points to spend in gold, the stat picks they buy
// (stat-picks.md), and the stats in their four groups.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/help_hint.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/level_up_stats.dart';
import '../widgets/stat_pick_picker.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);

    final xpRatio = session.xpToNextLevel == 0
        ? 0.0
        : (session.currentXP / session.xpToNextLevel).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'level_up')), actions: const [
        TourInfoButton(topic: TutorialTopic.levelUp),
      ]),
      body: TutorialTrigger(
        topic: TutorialTopic.levelUp,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // The level and the road to the next.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ink.seam),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tr(ref, 'level_field_label')} ${session.level}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontFamily: InkFonts.display),
                      ),
                      const Spacer(),
                      Text(
                        '${tr(ref, 'xp_label')} ${session.currentXP} / ${session.xpToNextLevel}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: ink.ash),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: xpRatio,
                      minHeight: 8,
                      color: ink.gold,
                      backgroundColor: ink.seam,
                    ),
                  ),
                  // With more than one pick waiting, a quiet count; with one,
                  // nothing (the tour's first line still points here).
                  TutorialTarget(
                    id: 'levelUp.points',
                    child: session.pendingStatPicks > 1
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              tr(ref, 'stat_picks_count').replaceAll(
                                  '{n}', '${session.pendingStatPicks}'),
                              key: const Key('level_up_points'),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const StatPickPicker(),
            const SizedBox(height: 12),
            const LevelUpStats(tutorialTargets: true),
          ],
        ),
      ),
    );
  }
}
