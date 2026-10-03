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
import '../widgets/detail_dialog.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final notifier = ref.read(playerSessionProvider.notifier);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final canSpend = session.statPoints > 0;

    Widget caption(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
        );

    Widget statRow(String label, IconData icon, String valueText,
        String statKey, String description) {
      void showExplanation() => showDetailDialog(
            context,
            title: label,
            description: description,
            icon: icon,
            closeLabel: tr(ref, 'close_button'),
          );
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: ink.seam),
          ),
          child: InkWell(
            key: Key('stat_row_$statKey'),
            borderRadius: BorderRadius.circular(4),
            onTap: showExplanation,
            onLongPress: showExplanation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ink.seam),
                    ),
                    child: Icon(icon, size: 18, color: ink.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontFamily: InkFonts.system)),
                  ),
                  Text(valueText,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: InkFonts.display, color: ink.gold)),
                  const SizedBox(width: 10),
                  FilledButton(
                    // The value on the row goes up; no message on top of it.
                    onPressed: canSpend
                        ? () => notifier.spendStatPoint(stat: statKey)
                        : null,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(tr(ref, 'plus_one_point')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            caption(tr(ref, 'level_group_fighting')),
            TutorialTarget(
              id: 'levelUp.stats',
              child: statRow(
                  tr(ref, 'base_damage_label'),
                  Icons.gavel,
                  '${session.baseDamage}',
                  'damage',
                  tr(ref, 'base_damage_desc')),
            ),
            statRow(tr(ref, 'base_armor_label'), Icons.shield,
                '${session.baseArmor}', 'armor', tr(ref, 'base_armor_desc')),
            statRow(
              tr(ref, 'max_health_label'),
              Icons.favorite,
              '${session.currentHealth} / ${session.maxHealth}',
              'health',
              tr(ref, 'max_health_desc'),
            ),
            caption(tr(ref, 'level_group_body')),
            statRow(tr(ref, 'strength_label'), Icons.fitness_center,
                '${session.strength}', 'strength', tr(ref, 'strength_desc')),
            statRow(tr(ref, 'dexterity_label'), Icons.directions_run,
                '${session.dexterity}', 'dexterity', tr(ref, 'dexterity_desc')),
            statRow(
                tr(ref, 'constitution_label'),
                Icons.health_and_safety,
                '${session.constitution}',
                'constitution',
                tr(ref, 'constitution_desc')),
            caption(tr(ref, 'level_group_mind')),
            statRow(
                tr(ref, 'intelligence_label'),
                Icons.psychology,
                '${session.intelligence}',
                'intelligence',
                tr(ref, 'intelligence_desc')),
            statRow(tr(ref, 'wisdom_label'), Icons.visibility,
                '${session.wisdom}', 'wisdom', tr(ref, 'wisdom_desc')),
            statRow(
                tr(ref, 'perception_label'),
                Icons.radar,
                '${session.perception}',
                'perception',
                tr(ref, 'perception_desc')),
            caption(tr(ref, 'level_group_fortune')),
            statRow(tr(ref, 'luck_label'), Icons.auto_awesome,
                '${session.luck}', 'luck', tr(ref, 'luck_desc')),
            statRow(tr(ref, 'charisma_label'), Icons.forum,
                '${session.charisma}', 'charisma', tr(ref, 'charisma_desc')),
          ],
        ),
      ),
    );
  }
}
