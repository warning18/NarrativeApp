// Level up, in Stitched Ink (v1.201): the level and its road to the next
// in a panel, the points to spend in gold, and the stats in their four
// groups, each a seam-bordered row with its value and a "+1 Point".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/level_up_stats.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final canSpend = session.statPoints > 0;

    final xpRatio = session.xpToNextLevel == 0
        ? 0.0
        : (session.currentXP / session.xpToNextLevel).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'level_up'))),
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
                  const SizedBox(height: 12),
                  TutorialTarget(
                    id: 'levelUp.points',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline,
                            size: 18, color: canSpend ? ink.gold : ink.ash),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${tr(ref, 'stat_points_available')}: ${session.statPoints}',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: canSpend ? ink.gold : null),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(ref, 'hold_stat_for_details_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const LevelUpStats(tutorialTargets: true),
          ],
        ),
      ),
    );
  }
}
