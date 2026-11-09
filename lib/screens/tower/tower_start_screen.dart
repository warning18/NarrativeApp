// The Tower's door and start screen (v1.847, docs/proposals/
// the-tower-designs.md, direction A): the marks and the best floor, a run
// to continue, and the pick of a people, a calling and a clan for a new
// one (the ones not bought yet lie locked), then Climb.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import '../race_profession_screen.dart';
import 'tower_floor_screen.dart';
import 'tower_marks_screen.dart';
import 'tower_providers.dart';
import '../../widgets/ink_panel.dart';

class TowerStartScreen extends ConsumerStatefulWidget {
  const TowerStartScreen({super.key});

  @override
  ConsumerState<TowerStartScreen> createState() => _TowerStartScreenState();
}

class _TowerStartScreenState extends ConsumerState<TowerStartScreen> {
  bool _starting = false;

  String _fill(String text, Map<String, Object> values) {
    var out = text;
    values.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }

  /// The callings not yet bought lie padlocked on the creation screen, with
  /// what they cost.
  Map<String, String> _locks(Set<String> open) => {
        for (final u in towerUnlocks)
          if (u.kind == TowerUnlockKind.profession && !open.contains(u.value))
            u.value: _fill(tr(ref, 'tower_bought_with_marks'), {'n': u.cost}),
      };

  /// The main game's Race & Profession screen picks the hero; the run starts
  /// when it hands the pick back, and takes its place.
  Future<void> _create() async {
    final progress = ref.read(towerProvider).value?.progress;
    final locks = _locks(progress?.professions ?? towerStartProfessions);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RaceProfessionScreen(
        locks: locks,
        onChosen: _begin,
      ),
    ));
  }

  Future<void> _begin(String race, String profession) async {
    if (_starting) return;
    setState(() => _starting = true);
    final data = await ref.read(towerDataProvider.future);
    await ref
        .read(towerProvider.notifier)
        .start(data: data, raceId: race, professionId: profession);
    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TowerFloorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final state = ref.watch(towerProvider).value ?? const TowerState();
    final progress = state.progress;
    final run = state.run;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'tower_name'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(tr(ref, 'tower_tagline'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            InkPanel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${progress.marks} ${tr(ref, 'tower_marks_name')}',
                            key: const Key('tower_marks_total'),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: ink.gold)),
                        Text(
                            [
                              _fill(tr(ref, 'tower_best'),
                                  {'n': progress.bestFloor}),
                              _fill(tr(ref, 'tower_runs_line'),
                                  {'r': progress.runs, 'w': progress.wins}),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('tower_marks_button'),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TowerMarksScreen())),
                    child: Text(tr(ref, 'tower_marks_button')),
                  ),
                ],
              ),
            ),
            if (run != null && !run.isOver) ...[
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('tower_continue'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TowerFloorScreen())),
                child: Text(
                    '${tr(ref, 'tower_continue')} · ${_fill(tr(ref, 'tower_floor_of'), {
                      'n': run.floor
                    })}'),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('tower_climb'),
              onPressed: _starting ? null : _create,
              child: Text(tr(ref, 'tower_climb')),
            ),
            const SizedBox(height: 8),
            Text(tr(ref, 'tower_save_note'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
