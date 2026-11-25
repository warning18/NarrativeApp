// The end of a run of the Tower (v1.847, the-tower-designs.md screen 6):
// where it ended, the marks it earned and the total, and the way on (the
// marks, another climb, the menu).
import '../../widgets/fit_title.dart';
import '../../widgets/tower_cut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_progress.dart';
import '../../data/tower/tower_run.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import 'tower_backdrop.dart';
import 'tower_look.dart';
import 'tower_marks_screen.dart';
import 'tower_start_screen.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';

/// The end of a run, in the Tower's night theme (its body below).
class TowerEndScreen extends StatelessWidget {
  const TowerEndScreen({super.key, required this.run, required this.progress});

  /// The run that ended (dead, won or left).
  final TowerRun run;

  /// The Tower's record with this run's marks banked.
  final TowerProgress progress;

  @override
  Widget build(BuildContext context) => TowerNight(
      floor: run.floor, child: _TowerEndBody(run: run, progress: progress));
}

class _TowerEndBody extends ConsumerWidget {
  const _TowerEndBody({required this.run, required this.progress});

  final TowerRun run;
  final TowerProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paper =
        theme.textTheme.apply(bodyColor: inkOnPaper, displayColor: inkOnPaper);
    final won = run.status == TowerStatus.won;
    final line = switch (run.status) {
      TowerStatus.won => tr(ref, 'tower_victory'),
      TowerStatus.dead => tr(ref, 'tower_death'),
      _ => tr(ref, 'tower_left'),
    }
        .replaceAll('{n}', '${run.floorReached}');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FitTitle(tr(ref, 'tower_name')),
      ),
      body: TowerBackdrop(
        floor: run.floorReached,
        asset: run.status == TowerStatus.abandoned
            ? null
            : towerEndPlate(won: won),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Where it ended and what it earned, on paper (Art's wide frame).
              InkPaperPanel(
                padding: const EdgeInsets.fromLTRB(46, 20, 22, 16),
                // The climb's trace beside the words (Maps: tower_cut.dart).
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            tr(ref, 'tower_floor_of')
                                .replaceAll('{n}', '${run.floorReached}'),
                            key: const Key('tower_end_floor'),
                            style: paper.headlineSmall?.copyWith(
                                fontFamily: InkFonts.display,
                                color: won ? inkOnPaper : inkRed)),
                        const SizedBox(height: 8),
                        Text(line,
                            key: const Key('tower_end_line'),
                            style: paper.bodyLarge
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    )),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      child: TowerCut(
                        key: const Key('tower_end_trace'),
                        view: TowerCutView.of(run),
                        rowHeight: 4.5,
                        compact: true,
                        onPaper: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkPaperPanel(
                title: tr(ref, 'tower_marks_name'),
                padding: const EdgeInsets.fromLTRB(46, 22, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(ref, 'tower_earned')
                            .replaceAll('{n}', '${run.marks}'),
                        key: const Key('tower_end_earned'),
                        style: paper.titleMedium?.copyWith(color: inkRed)),
                    const SizedBox(height: 4),
                    Text(
                        '${progress.marks} ${tr(ref, 'tower_marks_name')} · '
                        '${tr(ref, 'tower_best').replaceAll('{n}', '${progress.bestFloor}')}',
                        style: paper.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkButton(
                buttonKey: const Key('tower_end_again'),
                primary: true,
                height: 46,
                label: tr(ref, 'tower_climb_again'),
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const TowerStartScreen())),
              ),
              const SizedBox(height: 8),
              InkButton(
                buttonKey: const Key('tower_end_marks'),
                label: tr(ref, 'tower_marks_button'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TowerMarksScreen())),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('tower_end_back'),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(tr(ref, 'tower_back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
