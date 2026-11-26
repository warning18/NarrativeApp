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
import '../screens/tower/ink/ink_palette.dart';
import '../data/stat_pick_text.dart' show StatPickPreview;
import '../widgets/fight_sprites.dart' show heroWalkName;
import '../widgets/level_up_art.dart';
import '../widgets/level_up_stats.dart';
import '../widgets/stat_pick_picker.dart';

class LevelUpScreen extends ConsumerStatefulWidget {
  const LevelUpScreen({
    super.key,
    this.doneLabelKey = 'level_up_done',
    this.tower = false,
  });

  /// The Tower hero's level-up: the preview reads the Tower's checks.
  final bool tower;

  /// The string key of the button that closes the screen once no pick is
  /// waiting (v1.910, the user's report from the Tower: after the pick the
  /// only way on was the back arrow). The Tower passes its own
  /// ('tower_continue', "Continue the climb").
  final String doneLabelKey;

  @override
  ConsumerState<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends ConsumerState<LevelUpScreen> {
  /// What the Take button does while an offer is picked (null: nothing yet).
  final ValueNotifier<VoidCallback?> _take = ValueNotifier(null);

  /// What the picked offer changes, for the stats under the panel.
  final ValueNotifier<StatPickPreview?> _preview = ValueNotifier(null);

  @override
  void dispose() {
    _take.dispose();
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final xpRatio = session.xpToNextLevel == 0
        ? 0.0
        : (session.currentXP / session.xpToNextLevel).clamp(0.0, 1.0);

    final picksDone = session.pendingStatPicks == 0;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'level_up')), actions: const [
        TourInfoButton(topic: TutorialTopic.levelUp),
      ]),
      // Once every pick is taken, a clear way on (the back arrow still
      // works, before and after).
      bottomNavigationBar: picksDone
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                key: const Key('level_up_done'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(tr(ref, widget.doneLabelKey)),
              ),
            )
          // While a pick waits, its red Take button stays at the foot.
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: ValueListenableBuilder<VoidCallback?>(
                valueListenable: _take,
                builder: (context, take, _) => LevelUpTakeButton(
                    label: tr(ref, 'stat_pick_take'), onPressed: take),
              ),
            ),
      body: TutorialTrigger(
        topic: TutorialTopic.levelUp,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Art's plate (one of three by level), the ribbon, the hero.
            LevelUpStage(
              level: session.level,
              heroName: heroWalkName(session.raceId, session.professionId),
              levelLabel: tr(ref, 'level_field_label'),
            ),
            // The pick, on paper in an ink frame.
            Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: inkPaper,
                border: Border.all(color: inkDeep, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tr(ref, 'xp_label')} ${session.currentXP} / ${session.xpToNextLevel}',
                        style: const TextStyle(
                            fontFamily: InkFonts.prose,
                            fontSize: 12,
                            color: inkSlate,
                            fontFeatures: [FontFeature.liningFigures()]),
                      ),
                      const Spacer(),
                      // With more than one pick waiting, a quiet count; with
                      // one, nothing (the tour's first line still points
                      // here).
                      TutorialTarget(
                        id: 'levelUp.points',
                        child: session.pendingStatPicks > 1
                            ? Text(
                                tr(ref, 'stat_picks_count').replaceAll(
                                    '{n}', '${session.pendingStatPicks}'),
                                key: const Key('level_up_points'),
                                style: const TextStyle(
                                    fontFamily: InkFonts.prose,
                                    fontSize: 12,
                                    color: inkSlate),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    child: LinearProgressIndicator(
                      value: xpRatio,
                      minHeight: 6,
                      color: inkRed,
                      backgroundColor: inkSlate.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatPickPicker(
                      art: true,
                      tower: widget.tower,
                      takeSlot: _take,
                      previewSlot: _preview),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LevelUpStats(tutorialTargets: true, preview: _preview),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
