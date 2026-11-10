// The end of a run of the Tower (v1.847, the-tower-designs.md screen 6):
// where it ended, the marks it earned and the total, and the way on (the
// marks, another climb, the menu).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_progress.dart';
import '../../data/tower/tower_run.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import 'tower_marks_screen.dart';
import 'tower_start_screen.dart';
import '../../widgets/ink_panel.dart';

class TowerEndScreen extends ConsumerWidget {
  const TowerEndScreen({super.key, required this.run, required this.progress});

  /// The run that ended (dead, won or left).
  final TowerRun run;

  /// The Tower's record with this run's marks banked.
  final TowerProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
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
        title: Text(tr(ref, 'tower_name')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            InkPanel(
              lit: won,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      tr(ref, 'tower_floor_of')
                          .replaceAll('{n}', '${run.floorReached}'),
                      key: const Key('tower_end_floor'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: won ? ink.gold : ink.blood)),
                  const SizedBox(height: 8),
                  Text(line,
                      key: const Key('tower_end_line'),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      tr(ref, 'tower_earned').replaceAll('{n}', '${run.marks}'),
                      key: const Key('tower_end_earned'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: ink.gold)),
                  const SizedBox(height: 4),
                  Text(
                      '${progress.marks} ${tr(ref, 'tower_marks_name')} · '
                      '${tr(ref, 'tower_best').replaceAll('{n}', '${progress.bestFloor}')}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('tower_end_again'),
              onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const TowerStartScreen())),
              child: Text(tr(ref, 'tower_climb_again')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('tower_end_marks'),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TowerMarksScreen())),
              child: Text(tr(ref, 'tower_marks_button')),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('tower_end_back'),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(tr(ref, 'tower_back')),
            ),
          ],
        ),
      ),
    );
  }
}
